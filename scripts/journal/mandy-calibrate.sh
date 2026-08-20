#!/usr/bin/env bash
# mandy-calibrate.sh — monthly deterministic tier-calibration report for the
# ComeHomeAlabama journal (blog-calibrate pattern, no LLM). Reads the private
# decisions log, summarizes the prior month's tier distribution, dimension
# averages, downgrades, and producer mix, and emails Jeremy a branded report.
# Cron: 1st of month, after the market-note run.

set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

DECISIONS="$HOME/000-projects/coastal-realty-ops/content-machine/methodology/decisions.jsonl"
EMAIL_SCRIPT="$HOME/.claude/skills/email/scripts/send-email.cjs"
OUT="$HOME/.local/state/mandy-journal/calibrate-$(date +%Y-%m).html"
mkdir -p "$(dirname "$OUT")"

[ -s "$DECISIONS" ] || { echo "no decisions yet — nothing to calibrate"; exit 0; }

python3 - "$DECISIONS" > "$OUT" <<'EOF'
import json, sys, datetime, collections, html
path = sys.argv[1]
today = datetime.date.today()
first_this = today.replace(day=1)
last_month_end = first_this - datetime.timedelta(days=1)
prefix = last_month_end.strftime("%Y-%m")
rows = []
for line in open(path):
    line = line.strip()
    if not line:
        continue
    d = json.loads(line)
    if str(d.get("date", "")).startswith(prefix):
        rows.append(d)
tiers = collections.Counter(r.get("tier") for r in rows)
producers = collections.Counter(r.get("producer", "?") for r in rows)
downgrades = sum(1 for r in rows if r.get("downgrades"))
dims = collections.defaultdict(list)
for r in rows:
    for k, v in (r.get("dimensions") or {}).items():
        dims[k].append(v)
INK, GULF, SAND, LINE = "#1c2530", "#1f4d59", "#f5efe6", "#d8cdb8"
def tr(k, v):
    return (f'<tr><td style="padding:6px 10px;border:1px solid {LINE}">{html.escape(str(k))}</td>'
            f'<td style="padding:6px 10px;border:1px solid {LINE}">{html.escape(str(v))}</td></tr>')
t3_flag = ("" if tiers.get("T3", 0) <= 3 else
           f'<p style="color:#b42318"><strong>Tier-inflation guard:</strong> {tiers["T3"]} T3s last month (guard is 3/10 rolling) — review scoring.</p>')
print(f"""<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;font-size:14px;color:{INK};max-width:680px;margin:0 auto">
<div style="background:{GULF};border-radius:10px 10px 0 0;padding:14px 22px">
 <div style="color:{SAND};font-size:18px;font-family:Georgia,serif">Mandy journal — tier calibration, {prefix}</div>
</div>
<div style="background:#fffdf9;border:1px solid {LINE};border-top:0;border-radius:0 0 10px 10px;padding:18px 22px">
<p>{len(rows)} post(s) recorded for {prefix}.</p>
<table style="border-collapse:collapse">
{tr("Tier distribution", ", ".join(f"{k}: {v}" for k, v in sorted(tiers.items())) or "none")}
{tr("Deterministic downgrades", downgrades)}
{tr("Producer mix", ", ".join(f"{k}: {v}" for k, v in producers.items()) or "none")}
{"".join(tr(f"avg {k}", f"{sum(v)/len(v):.1f}") for k, v in sorted(dims.items()))}
</table>
{t3_flag}
<p style="color:#4b5763;font-size:12px;margin-bottom:0">Deterministic report from content-machine/methodology/decisions.jsonl · no LLM involved.</p>
</div></div>""")
EOF

node "$EMAIL_SCRIPT" --to jeremy@intentsolutions.io \
  --subject "Mandy journal calibration: $(date -d 'last month' +%Y-%m 2>/dev/null || date +%Y-%m)" \
  --html "$OUT" >/dev/null 2>&1 && echo "calibration report emailed" || { echo "email failed"; exit 1; }
