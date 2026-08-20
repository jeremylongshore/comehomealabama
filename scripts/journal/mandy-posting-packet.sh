#!/usr/bin/env bash
# mandy-posting-packet.sh — syndication packet email for the ComeHomeAlabama journal.
#
# Site-first, +24h stagger: the canonical post lands on comehomealabama.com first;
# this sweep emails the copy-paste packet only for posts landed >= STAGGER_HOURS
# ago, so search engines see the canonical URL before any syndicated copy exists.
#
# Modes:
#   --sweep   (default) one packet email per due post → Ezekiel, CC Mandy/Jeremy.
#             Ezekiel's sections: Substack, Medium (canonical!), ActiveRain,
#             Nextdoor, Google Business Profile, Pinterest.
#             Mandy's section: her own ready-to-paste LinkedIn + Facebook copy.
#   --digest  weekly Substack digest ("Notes from the Coast") + GBP week post
#             from the last 7 days of landed posts. Run Fridays.
#
# Recipients come from the PRIVATE config (never committed here):
#   ~/000-projects/coastal-realty-ops/content-machine/packet.env
#     PACKET_TO=...    PACKET_CC=...   (comma-separated CCs allowed)
# Fallback: jeremy@intentsolutions.io only (safe until Ezekiel is briefed).
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

send_mail() { # subject body
  local subject="$1" body="$2" rc=0
  local -a cc_args=()
  if [ -n "$PACKET_CC" ]; then
    IFS=',' read -ra ccs <<< "$PACKET_CC"
    for c in "${ccs[@]}"; do cc_args+=(--cc "$c"); done
  fi
  node "$EMAIL_SCRIPT" --to "$PACKET_TO" "${cc_args[@]}" --subject "$subject" --body "$body" || rc=$?
  return $rc
}

# Emit the full packet body for one slug (reads post + ledger row).
build_packet() { # slug
  python3 - "$1" "$REPO" "$LEDGER" <<'EOF'
import json, re, sys, textwrap
slug, repo, ledger_path = sys.argv[1:4]
row = next(p for p in json.load(open(ledger_path))["posts"] if p["slug"] == slug)
raw = open(f"{repo}/src/content/journal/{slug}.mdx", encoding="utf-8").read()
m = re.match(r"^---\n(.*?)\n---\n(.*)$", raw, re.DOTALL)
fm, body = m.group(1), m.group(2).strip()
def fmv(k, default=""):
    mm = re.search(rf'^{k}:\s*["\']?(.+?)["\']?\s*$', fm, re.M)
    return mm.group(1) if mm else default
title, desc = fmv("title"), fmv("description")
url = row["url"]
def utm(source):
    return f"{url}?utm_source={source}&utm_medium=syndication&utm_campaign=journal"
first_para = next(p for p in body.split("\n\n") if not p.startswith("#")).replace("\n", " ")

S = "=" * 72
print(f"""POSTING PACKET — ComeHomeAlabama journal
Post:      {title}
Canonical: {url}
Landed:    {row['landed_at'][:10]} (24h+ site-first stagger already satisfied)

Order: work top to bottom. Every pasted version must LINK BACK to the
canonical URL above (each section has its own tracking link — use that one).
Voice: paste as-is. Do not add emojis, hashtags beyond what a section says,
or any hype words. It should sound like Mandy, because it is.

{S}
1) SUBSTACK — "Notes from the Coast" (Ezekiel)
{S}
Title: {title}
Paste the full post body below, then add this closing line:

    Originally published on the journal: {utm("substack")}
    No pressure, just honest numbers. Call or text Mandy: (251) 597-5809.

{S}
2) MEDIUM (Ezekiel) — IMPORTANT: set the canonical URL
{S}
Use Medium's import tool with the canonical URL, or paste the body and set
Story settings → Advanced → canonical link to EXACTLY:
    {url}
Never publish on Medium without the canonical set. Tracking link for the
closing line: {utm("medium")}

{S}
3) ACTIVERAIN (Ezekiel)
{S}
Title: {title}
Paste the full body, then close with:

    Full version on the journal: {utm("activerain")}
    Mandy Longshore · RE/MAX of Gulf Shores · Licensed in AL & FL

{S}
4) NEXTDOOR (Ezekiel — Mandy's neighborhoods + business page)
{S}
{desc}

Full note here: {utm("nextdoor")}
Questions? Call or text Mandy: (251) 597-5809.

{S}
5) GOOGLE BUSINESS PROFILE post (Ezekiel — manual until Posts API approved)
{S}
{desc}
[Add post → button "Learn more" → {utm("gbp")}]

{S}
6) PINTEREST pin (Ezekiel — board: matching community/pillar)
{S}
Pin title: {title}
Pin description: {desc}
Destination link: {utm("pinterest")}

{S}
7) MANDY'S SECTION — paste these yourself (LinkedIn + Facebook)
{S}
LINKEDIN:
{first_para}

I wrote the whole thing up here: {utm("linkedin")}

FACEBOOK (page and/or groups per your call):
{first_para}

Full note: {utm("facebook")}
Call or text me anytime: (251) 597-5809.

{S}
FULL POST BODY (for sections 1-3)
{S}

{body}
""")
EOF
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
    body=$(build_packet "$slug") || { log "packet build failed for $slug"; rc=1; continue; }
    title=$(python3 -c "import json;print(next(p['title'] for p in json.load(open('$LEDGER'))['posts'] if p['slug']=='$slug'))")
    if send_mail "Mandy journal posting packet: $title" "$body"; then
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
  digest=$(python3 - "$LEDGER" <<'EOF'
import json, sys, datetime
data = json.load(open(sys.argv[1]))
now = datetime.datetime.now().astimezone()
week = [p for p in data["posts"]
        if (now - datetime.datetime.fromisoformat(p["landed_at"])).days < 7]
if not week:
    sys.exit(1)
print("SUBSTACK WEEKLY DIGEST — paste as this week's 'Notes from the Coast'\n")
print("Suggested subject: Notes from the coast, this week\n")
print("Intro (paste as-is):")
print("Here's what I wrote up this week. As always: no pressure, just honest numbers.\n")
for p in week:
    print(f"- {p['title']}")
    print(f"  {p['url']}?utm_source=substack&utm_medium=digest&utm_campaign=journal\n")
print("Closing: Call or text me anytime — (251) 597-5809. I answer my phone.")
print("\n" + "=" * 72)
print("GBP WEEK POST (one Google Business Profile post for the week):")
p = week[0]
print(f"New on the journal this week: {p['title']} — plus more honest numbers from the coast.")
print(f"[Learn more → {p['url']}?utm_source=gbp&utm_medium=digest&utm_campaign=journal]")
EOF
) || { log "no posts in the last 7 days — no digest"; exit 0; }
  if send_mail "Mandy journal weekly digest packet (Substack + GBP)" "$digest"; then
    log "digest packet sent"
    : > "$HOME/.local/state/intent-os/liveness/mandy-posting-packet.ok"
  else
    log "digest EMAIL FAILED"; exit 1
  fi
  ;;
*)
  echo "usage: mandy-posting-packet.sh [--sweep|--digest]"; exit 1 ;;
esac
