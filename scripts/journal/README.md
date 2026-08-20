# scripts/journal — the ComeHomeAlabama journal pipeline

Deterministic half of the Mandy content machine. The LLM producer
(`/mandy-journal`, lives in the operator's `~/.claude/skills/`) writes
artifacts; these scripts verify and publish them. No LLM in any land step.

| Script | Role |
|---|---|
| `mandy-journal-daily.sh` | Cron driver (Mon/Wed/Fri 04:30). Producer chain claude → codex → grok → minimax with a read-only git guard, then invokes the lander. `--market-note` auto-passes on the 1st. |
| `mandy-land.sh` | The only committer on the journal path. Verifies sentinel → re-runs both lints → `pnpm build` → commits the MDX to main → push → verifies the live URL. Quarantines on any gate failure. |
| `lint-post-voice.py` | Voice contract: denylist, call-or-text CTA, em-dash budget, tier word bands (deterministic downgrade backstop). |
| `lint-fair-housing.py` | Fair-housing language gate. HARD list blocks publication with no override path; WARN list prints for review. |
| `mandy-posting-packet.sh` | `--sweep`: per-post syndication packet email (Substack / Medium-canonical / ActiveRain / Nextdoor / GBP / Pinterest + Mandy's own LinkedIn/Facebook section), sent only after the +24h site-first stagger. `--digest`: Friday Substack digest + GBP week post. |

State lives outside the repo: syndication ledger + run logs in
`~/.local/state/mandy-journal/`, private calibration data (decisions.jsonl,
topic queue, voice profile) in the operator's private ops repo. Recipient
addresses come from a private `packet.env` — never committed here.

Staging/quarantine dirs (`.journal-staging/`, `.journal-quarantine/`) are
git-ignored producer workspace.
