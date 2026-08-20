#!/usr/bin/env bash
# mandy-posting-packet.sh — syndication packet email for the ComeHomeAlabama journal.
#
# Site-first, +24h stagger: the canonical post lands on comehomealabama.com first;
# this sweep emails the copy-paste packet only for posts landed >= STAGGER_HOURS
# ago, so search engines see the canonical URL before any syndicated copy exists.
#
# Packets are BRANDED HTML rendered by mandy-packet-html.cjs (same layout
# language as the startaitools Ezekiel packets, CHA palette) — never plain text.
#
# Modes:
#   --sweep   (default) one packet email per due post.
#             Ezekiel's sections: Substack, Medium (canonical!), ActiveRain,
#             Nextdoor, Google Business Profile, Pinterest.
#             Mandy's section: her own ready-to-paste LinkedIn + Facebook copy.
#   --digest  weekly Substack digest ("Notes from the Coast") + GBP week post
#             from the last 7 days of landed posts. Run Fridays.
#
# Recipients come from the PRIVATE config (never committed here):
#   ~/000-projects/coastal-realty-ops/content-machine/packet.env
#     PACKET_TO=...    PACKET_CC=...   (comma-separated CCs allowed)
# Fallback: jeremy@intentsolutions.io only. Nothing reaches Ezekiel until
# Jeremy briefs him AND flips packet.env himself.
#
# State: ~/.local/state/mandy-journal/mandy-syndication-ledger.json
# Deterministic — no LLM anywhere in this script.

set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

MODE="${1:---sweep}"
REPO="${MANDY_REPO:-/home/jeremy/000-projects/comehomealabama}"
LEDGER="$HOME/.local/state/mandy-journal/mandy-syndication-ledger.json"
EMAIL_SCRIPT="$HOME/.claude/skills/email/scripts/send-email.cjs"
PACKET_ENV="$HOME/000-projects/coastal-realty-ops/content-machine/packet.env"
STAGGER_HOURS="${MANDY_STAGGER_HOURS:-24}"
LOG_DIR="$HOME/.local/state/mandy-journal"
mkdir -p "$LOG_DIR"

# Liveness beat for the estate dead-man sweep.
mkdir -p "$HOME/.local/state/intent-os/liveness" 2>/dev/null || true
: > "$HOME/.local/state/intent-os/liveness/mandy-posting-packet.beat" 2>/dev/null || true

log() { echo "[$(date -Is)] [packet] $*"; }

PACKET_TO="jeremy@intentsolutions.io"
PACKET_CC=""
# shellcheck disable=SC1090
[ -r "$PACKET_ENV" ] && source "$PACKET_ENV"

[ -f "$LEDGER" ] || { log "no ledger yet — nothing to do"; exit 0; }

send_mail_html() { # subject html_file
  local subject="$1" html_file="$2" rc=0
  local -a cc_args=()
  if [ -n "$PACKET_CC" ]; then
    IFS=',' read -ra ccs <<< "$PACKET_CC"
    for c in "${ccs[@]}"; do cc_args+=(--cc "$c"); done
  fi
  node "$EMAIL_SCRIPT" --to "$PACKET_TO" "${cc_args[@]}" --subject "$subject" --html "$html_file" || rc=$?
  return $rc
}

# Build the JSON payload for one slug and render the branded HTML packet.
# Echoes the html file path.
build_packet_html() { # slug
  local slug="$1" payload html
  payload="$LOG_DIR/packet-$slug.json"
  html="$LOG_DIR/packet-$slug.html"
  python3 - "$slug" "$REPO" "$LEDGER" > "$payload" <<'EOF'
import json, re, sys
slug, repo, ledger_path = sys.argv[1:4]
row = next(p for p in json.load(open(ledger_path))["posts"] if p["slug"] == slug)
raw = open(f"{repo}/src/content/journal/{slug}.mdx", encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n(.*)$", raw, re.DOTALL)
fm, body = m.group(1), m.group(2).strip()
def fmv(k, default=""):
    mm = re.search(rf'^{k}:\s*["\']?(.+?)["\']?\s*$', fm, re.M)
    return mm.group(1) if mm else default
url = row["url"]
utm = lambda s: f"{url}?utm_source={s}&utm_medium=syndication&utm_campaign=journal"
first_para = next(p for p in body.split("\n\n") if not p.startswith("#")).replace("\n", " ")
json.dump({
    "mode": "post",
    "post_title": fmv("title"),
    "description": fmv("description"),
    "tier": fmv("tier", "T2"),
    "date": row["date"],
    "canonical_url": url,
    "first_para": first_para,
    "body_md": body,
    "links": {s: utm(s) for s in
              ["substack", "medium", "activerain", "nextdoor", "gbp", "pinterest", "linkedin", "facebook"]},
}, sys.stdout)
EOF
  node "$REPO/scripts/journal/mandy-packet-html.cjs" --in "$payload" --out "$html" || return 1
  echo "$html"
}

case "$MODE" in
--sweep)
  due=$(python3 - "$LEDGER" "$STAGGER_HOURS" <<'EOF'
import json, sys, datetime
ledger, hours = sys.argv[1], int(sys.argv[2])
now = datetime.datetime.now().astimezone()
for p in json.load(open(ledger))["posts"]:
    if p.get("packet_sent"):
        continue
    landed = datetime.datetime.fromisoformat(p["landed_at"])
    if (now - landed).total_seconds() >= hours * 3600:
        print(p["slug"])
EOF
)
  [ -z "$due" ] && { log "no packets due"; exit 0; }
  rc=0
  for slug in $due; do
    log "building packet for $slug"
    html=$(build_packet_html "$slug") || { log "packet build failed for $slug"; rc=1; continue; }
    title=$(python3 -c "import json;print(next(p['title'] for p in json.load(open('$LEDGER'))['posts'] if p['slug']=='$slug'))")
    if send_mail_html "Mandy journal posting packet: $title" "$html"; then
      python3 - "$LEDGER" "$slug" <<'EOF'
import json, sys, datetime
ledger, slug = sys.argv[1:3]
data = json.load(open(ledger))
for p in data["posts"]:
    if p["slug"] == slug:
        p["packet_sent"] = True
        p["packet_sent_at"] = datetime.datetime.now().astimezone().isoformat()
json.dump(data, open(ledger, "w"), indent=2)
EOF
      log "packet sent + ledger marked: $slug"
    else
      log "EMAIL FAILED for $slug (ledger not marked — will retry next sweep)"
      rc=1
    fi
  done
  [ $rc -eq 0 ] && : > "$HOME/.local/state/intent-os/liveness/mandy-posting-packet.ok"
  exit $rc
  ;;
--digest)
  payload="$LOG_DIR/packet-digest.json"
  html="$LOG_DIR/packet-digest.html"
  python3 - "$LEDGER" > "$payload" <<'EOF'
import json, sys, datetime
data = json.load(open(sys.argv[1]))
now = datetime.datetime.now().astimezone()
week = [p for p in data["posts"]
        if (now - datetime.datetime.fromisoformat(p["landed_at"])).days < 7]
if not week:
    sys.exit(3)
u = lambda p, s, m: f"{p['url']}?utm_source={s}&utm_medium={m}&utm_campaign=journal"
json.dump({
    "mode": "digest",
    "digest": {
        "intro": "Here's what I wrote up this week. As always: no pressure, just honest numbers.",
        "items": [{"title": p["title"], "url": u(p, "substack", "digest")} for p in week],
        "gbp_text": (f"New on the journal this week: {week[0]['title']} — plus more honest "
                     f"numbers from the coast.\n\nLearn more → {u(week[0], 'gbp', 'digest')}"),
    },
}, sys.stdout)
EOF
  prc=$?
  [ "$prc" = "3" ] && { log "no posts in the last 7 days — no digest"; exit 0; }
  [ "$prc" != "0" ] && { log "digest payload build failed"; exit 1; }
  node "$REPO/scripts/journal/mandy-packet-html.cjs" --in "$payload" --out "$html" || { log "digest render failed"; exit 1; }
  if send_mail_html "Mandy journal weekly digest packet (Substack + GBP)" "$html"; then
    log "digest packet sent"
    : > "$HOME/.local/state/intent-os/liveness/mandy-posting-packet.ok"
  else
    log "digest EMAIL FAILED"; exit 1
  fi
  ;;
*)
  echo "usage: mandy-posting-packet.sh [--sweep|--digest]"; exit 1 ;;
esac
