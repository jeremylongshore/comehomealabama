#!/usr/bin/env bash
# mandy-land.sh — deterministic land step for the ComeHomeAlabama journal.
#
# The /mandy-journal producer (LLM) writes artifacts ONLY:
#   src/content/journal/<slug>.mdx
#   .journal-staging/<date>.intent.json        (readiness sentinel)
#   + appends the private decisions log in coastal-realty-ops
# This script is the ONLY thing that touches git. It verifies preconditions
# and, only if every gate passes, commits the post to main, pushes, waits for
# the Pages workflow, and verifies the post is live. On gate failure it
# QUARANTINES the stranded artifacts so the next run starts clean. Zero LLM.
#
# Usage: mandy-land.sh YYYY-MM-DD
#
# Exit codes (mirrors blog-land.sh semantics):
#   0  landed and verified live
#   3  pushed, deploy not verified live yet (warning)
#   10 preconditions failed — artifacts QUARANTINED, tree clean
#   11 land infra failure after commit (orphaned local commit, manual push)
#   12 blocked before commit — nothing orphaned, re-run after fixing
#   20 no post + no sentinel for the date (no-op)
#   21 already landed (tracked, unchanged post covers the date)

set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

DATE="${1:-}"
[[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "usage: mandy-land.sh YYYY-MM-DD"; exit 12; }

REPO="${MANDY_REPO:-/home/jeremy/000-projects/comehomealabama}"
POSTS="$REPO/src/content/journal"
STAGING="$REPO/.journal-staging"
QUARANTINE="$REPO/.journal-quarantine"
SENTINEL="$STAGING/$DATE.intent.json"
LEDGER_DIR="$HOME/.local/state/mandy-journal"
LEDGER="$LEDGER_DIR/mandy-syndication-ledger.json"
SITE="https://comehomealabama.com"
mkdir -p "$LEDGER_DIR"

log()  { echo "[$(date -Is)] [land] $*"; }
land_result() { echo "LAND-RESULT: $1"; }

# --- Serialize against a concurrent run (unless the driver already holds it) --
if [ -z "${MANDY_PIPELINE_LOCK_HELD:-}" ]; then
  exec 9>"/tmp/mandy-journal-pipeline.lock"
  flock -n 9 || { log "another pipeline run holds the lock — exiting"; land_result "locked"; exit 12; }
fi

# --- Locate the post for the date -------------------------------------------
# Sentinel names the slug; fall back to scanning frontmatter dates.
SLUG=""
if [ -f "$SENTINEL" ]; then
  SLUG=$(python3 -c "import json;print(json.load(open('$SENTINEL')).get('slug',''))" 2>/dev/null || true)
fi
POST=""
if [ -n "$SLUG" ] && [ -f "$POSTS/$SLUG.mdx" ]; then
  POST="$POSTS/$SLUG.mdx"
else
  POST=$(/usr/bin/grep -l "^date: $DATE" "$POSTS"/*.mdx 2>/dev/null | head -1 || true)
  [ -n "$POST" ] && SLUG=$(basename "$POST" .mdx)
fi

quarantine() {
  local reason="$1"
  mkdir -p "$QUARANTINE/$DATE"
  [ -n "$POST" ] && [ -f "$POST" ] && ! git -C "$REPO" ls-files --error-unmatch "${POST#"$REPO"/}" >/dev/null 2>&1 \
    && \mv "$POST" "$QUARANTINE/$DATE/" && log "quarantined $(basename "$POST")"
  [ -f "$SENTINEL" ] && \mv "$SENTINEL" "$QUARANTINE/$DATE/" && log "quarantined sentinel"
  log "QUARANTINE ($reason) → $QUARANTINE/$DATE/"
  land_result "quarantined: $reason"
}

# --- No-op / already-landed cases --------------------------------------------
if [ -z "$POST" ]; then
  log "no post and no usable sentinel for $DATE — nothing to land"
  land_result "no-post"
  exit 20
fi
REL="${POST#"$REPO"/}"
if git -C "$REPO" ls-files --error-unmatch "$REL" >/dev/null 2>&1 \
   && git -C "$REPO" diff --quiet HEAD -- "$REL" 2>/dev/null; then
  log "post already tracked and clean ($REL) — already landed"
  [ -f "$SENTINEL" ] && \rm -f "$SENTINEL"
  land_result "already-landed"
  exit 21
fi

# --- Gate 0: sentinel must exist and be ready:true ---------------------------
if [ ! -f "$SENTINEL" ]; then
  quarantine "post on disk but no sentinel (producer died mid-write)"
  exit 10
fi
READY=$(python3 -c "import json;print(json.load(open('$SENTINEL')).get('ready') is True)" 2>/dev/null || echo False)
if [ "$READY" != "True" ]; then
  quarantine "sentinel ready!=true (producer gates did not all pass)"
  exit 10
fi

# --- Gate 1+2: voice lint + fair-housing lint (re-run; never trust the LLM) --
if ! python3 "$REPO/scripts/journal/lint-post-voice.py" "$POST"; then
  quarantine "voice lint failed"
  exit 10
fi
if ! python3 "$REPO/scripts/journal/lint-fair-housing.py" "$POST"; then
  quarantine "FAIR-HOUSING lint failed"
  exit 10
fi

# --- Gate 3: the site must build with the new post (zod schema is in build) --
log "building site with new post..."
if ! (cd "$REPO" && pnpm build >/dev/null 2>&1); then
  quarantine "pnpm build failed with the new post"
  exit 10
fi

# --- Tree hygiene: only the post may be staged -------------------------------
if ! git -C "$REPO" diff --quiet HEAD -- ':!.journal-staging' ':!.journal-quarantine' ":!$REL" 2>/dev/null; then
  log "BLOCKED: repo has unrelated uncommitted changes — refusing to commit around them"
  land_result "blocked-dirty-tree"
  exit 12
fi
BRANCH=$(git -C "$REPO" rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ]; then
  log "BLOCKED: repo on '$BRANCH', journal lands only from main"
  land_result "blocked-wrong-branch"
  exit 12
fi
git -C "$REPO" pull --rebase -q origin main || { land_result "blocked-pull-failed"; exit 12; }

# --- Commit + push -----------------------------------------------------------
TITLE=$(python3 - "$POST" <<'EOF'
import re,sys
raw=open(sys.argv[1],encoding="utf-8").read()
m=re.search(r'^title:\s*["\']?(.+?)["\']?\s*$',raw.split('---')[1],re.M)
print(m.group(1) if m else "journal post")
EOF
)
git -C "$REPO" add "$REL"
git -C "$REPO" commit -q -m "post(journal): $TITLE

Automated land for $DATE by scripts/journal/mandy-land.sh after all gates
passed (voice lint, fair-housing lint, site build). Producer artifacts only;
this deterministic step is the sole committer on the journal path." \
  || { land_result "blocked-commit-failed"; exit 12; }
if ! git -C "$REPO" push -q origin main; then
  log "PUSH FAILED — local commit orphaned, manual push needed"
  land_result "orphaned-commit"
  exit 11
fi
log "pushed $REL to main"
\rm -f "$SENTINEL"

# --- Ledger entry (feeds the +24h posting-packet sweep) ----------------------
python3 - "$LEDGER" "$SLUG" "$DATE" "$TITLE" <<'EOF'
import json, sys, datetime
ledger_path, slug, date, title = sys.argv[1:5]
try:
    data = json.load(open(ledger_path))
except Exception:
    data = {"posts": []}
if not any(p["slug"] == slug for p in data["posts"]):
    data["posts"].append({
        "slug": slug, "date": date, "title": title,
        "url": f"https://comehomealabama.com/journal/{slug}/",
        "landed_at": datetime.datetime.now().astimezone().isoformat(),
        "packet_sent": False, "digest_sent": False,
    })
json.dump(data, open(ledger_path, "w"), indent=2)
EOF
log "ledger updated: $SLUG"

# --- Verify live (poll the Pages deploy, then the URL) -----------------------
DEPLOY_WAIT="${MANDY_DEPLOY_WAIT:-300}"
waited=0
while [ "$waited" -lt "$DEPLOY_WAIT" ]; do
  sleep 20; waited=$((waited + 20))
  code=$(curl -s -o /dev/null -w '%{http_code}' "$SITE/journal/$SLUG/" || true)
  if [ "$code" = "200" ]; then
    log "live: $SITE/journal/$SLUG/ (after ${waited}s)"
    land_result "landed-live"
    exit 0
  fi
done
log "pushed but not verified live after ${DEPLOY_WAIT}s — check the Pages workflow"
land_result "pushed-not-live"
exit 3
