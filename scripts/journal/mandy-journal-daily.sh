#!/usr/bin/env bash
# mandy-journal-daily.sh — Mon/Wed/Fri producer+land driver for the
# ComeHomeAlabama journal. Mirrors blog-backfill-daily.sh architecture:
# the LLM PRODUCES artifacts, deterministic mandy-land.sh LANDS them.
#
# Producer fallback chain (all already-paid capacity, zero marginal cost):
#   1. claude  (Claude Max subscription — best voice fidelity, primary)
#   2. codex   (ChatGPT Pro subscription — codex exec headless)
#   3. grok    (X Premium+ — grok CLI headless)
#   4. minimax (MiniMax M3 $20/mo — minimax-agent.py harness)
# Override with MANDY_PRODUCER=claude|codex|grok|minimax|auto (default auto).
#
# Cadence: cron Mon/Wed/Fri 04:30 (3x/week on purpose — quality + believability
# for a realtor brand; scale later from calibration data). On the 1st of the
# month the driver passes --market-note so the producer writes the T1 monthly
# market note from fresh county data.
#
# Fail-loud: any abnormal exit emails Jeremy; liveness beat feeds the estate
# dead-man sweep (automation-liveness-sweep.sh).

set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/.bun/bin:${HOME}/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

TODAY=$(date +%Y-%m-%d)
REPO="${MANDY_REPO:-/home/jeremy/000-projects/comehomealabama}"
POSTS="$REPO/src/content/journal"
LAND="$REPO/scripts/journal/mandy-land.sh"
EMAIL_SCRIPT="$HOME/.claude/skills/email/scripts/send-email.cjs"
LOG_DIR="$HOME/.local/state/mandy-journal"
LOG="$LOG_DIR/run-${TODAY}.log"
TIMEOUT_SECS="${MANDY_TIMEOUT:-2400}"
PRODUCER_MODE="${MANDY_PRODUCER:-auto}"
mkdir -p "$LOG_DIR"

MARKET_NOTE=""
[ "$(date +%d)" = "01" ] && MARKET_NOTE=" --market-note"

log() { echo "[$(date -Is)] $*" | tee -a "$LOG"; }
log "=== mandy-journal daily start (target: $TODAY, mode: $PRODUCER_MODE${MARKET_NOTE:+, market-note}) ==="

# --- Liveness + fail-loud ----------------------------------------------------
mkdir -p "$HOME/.local/state/intent-os/liveness" 2>/dev/null || true
: > "$HOME/.local/state/intent-os/liveness/mandy-journal-daily.beat" 2>/dev/null || true
NOTIFIED=0
on_exit() {
  local rc=$?
  [ -n "${GUARD_DIR:-}" ] && rm -rf "$GUARD_DIR"
  [ "$rc" -eq 0 ] && : > "$HOME/.local/state/intent-os/liveness/mandy-journal-daily.ok" 2>/dev/null
  [ "$rc" -eq 0 ] && return
  [ "$NOTIFIED" -eq 1 ] && return
  log "ABNORMAL EXIT rc=$rc — fail-loud alert"
  node "$EMAIL_SCRIPT" --to jeremy@intentsolutions.io \
    --subject "🚨 mandy-journal aborted early: ${TODAY} (rc=${rc})" \
    --body "$(printf 'mandy-journal-daily exited abnormally (rc=%s).\nNo post landed for %s.\n\nLast 30 log lines:\n%s\n' "$rc" "$TODAY" "$(tail -30 "$LOG" 2>/dev/null)")" \
    >/dev/null 2>&1 || true
}
trap on_exit EXIT

# --- Lock + disk guard -------------------------------------------------------
exec 9>"/tmp/mandy-journal-pipeline.lock"
if ! flock -n 9; then log "another run holds the lock — benign exit"; NOTIFIED=1; exit 0; fi
export MANDY_PIPELINE_LOCK_HELD=1
free_mb=$(($(stat -f -c '%a*%S' "$REPO" | bc) / 1048576))
if [ "$free_mb" -lt "${MANDY_DISK_MIN_MB:-500}" ]; then log "FATAL: ${free_mb}MB free < floor"; exit 1; fi

# --- Idempotency: a tracked clean post for today means done ------------------
existing=$(/usr/bin/grep -l "^date: $TODAY" "$POSTS"/*.mdx 2>/dev/null | head -1 || true)
if [ -n "$existing" ]; then
  rel="${existing#"$REPO"/}"
  if git -C "$REPO" ls-files --error-unmatch "$rel" >/dev/null 2>&1 \
     && git -C "$REPO" diff --quiet HEAD -- "$rel" 2>/dev/null; then
    log "published post already covers $TODAY ($rel) — no-op"
    NOTIFIED=1; exit 0
  fi
fi

# --- Tree preflight: clean main, fast-forwarded ------------------------------
if [ -n "$(git -C "$REPO" status --porcelain -- ':!.journal-staging' ':!.journal-quarantine' 2>/dev/null)" ]; then
  log "FATAL: dirty tree in $REPO — refusing to generate into it"; exit 1
fi
git -C "$REPO" checkout -q main && git -C "$REPO" pull -q --rebase origin main || { log "FATAL: branch normalize failed"; exit 1; }

# --- Producer git guard: mutations rejected at the executable boundary -------
REAL_GIT_BIN=$(command -v git); export REAL_GIT_BIN
GUARD_DIR=$(mktemp -d)
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'args=("$@"); i=0' \
  'while [ "$i" -lt "${#args[@]}" ]; do' \
  '  case "${args[$i]}" in' \
  '    -C|-c|--git-dir|--work-tree) i=$((i + 2)); continue ;;' \
  '    -*) i=$((i + 1)); continue ;;' \
  '    *) command_name=${args[$i]}; break ;;' \
  '  esac' \
  'done' \
  'case "${command_name:-}" in' \
  '  add|am|apply|branch|checkout|cherry-pick|clean|commit|merge|mv|pull|push|rebase|reset|restore|rm|stash|switch|tag)' \
  '    echo "producer git guard: mutation rejected (${command_name})" >&2; exit 73 ;;' \
  'esac' \
  'exec "$REAL_GIT_BIN" "$@"' \
  > "$GUARD_DIR/git"
chmod 0755 "$GUARD_DIR/git"

PRODUCER_PROMPT="You are the /mandy-journal producer for comehomealabama.com. Target date: ${TODAY}.${MARKET_NOTE:+ Write the monthly market note (T1).}
Follow /home/jeremy/.claude/skills/mandy-journal/SKILL.md and its references/ fully.
Produce ONLY: src/content/journal/<slug>.mdx + append /home/jeremy/000-projects/coastal-realty-ops/content-machine/methodology/decisions.jsonl + write .journal-staging/${TODAY}.intent.json with ready:true only if every gate passed (python3 scripts/journal/lint-post-voice.py and python3 scripts/journal/lint-fair-housing.py on the new post — both must PASS).
Do NOT git add/commit/push and do NOT email. scripts/journal/mandy-land.sh is the only committer.
If a post for ${TODAY} already exists, stop."

post_exists_now() { /usr/bin/grep -l "^date: $TODAY" "$POSTS"/*.mdx >/dev/null 2>&1; }
PRODUCER_USED=""; PRODUCER_STATUS="NOT-RUN"

run_producer() { # name cmd...
  local name="$1"; shift
  local t0 exitc wall
  log "Invoking $name producer (timeout ${TIMEOUT_SECS}s)"
  t0=$(date +%s)
  if env PATH="$GUARD_DIR:$PATH" /usr/bin/timeout "$TIMEOUT_SECS" "$@" >>"$LOG" 2>&1; then
    wall=$(( $(date +%s) - t0 ))
    log "$name exited cleanly after ${wall}s"
    PRODUCER_USED="$name"; PRODUCER_STATUS="OK ($name)"
    return 0
  fi
  exitc=$?; wall=$(( $(date +%s) - t0 ))
  log "$name failed (exit $exitc) after ${wall}s"
  PRODUCER_STATUS="${PRODUCER_STATUS}; $name exit $exitc"
  return 1
}

claude_p()  { run_producer claude claude -p "/mandy-journal ${TODAY}${MARKET_NOTE}" --dangerously-skip-permissions; }
codex_p()   { command -v codex >/dev/null || return 1
              run_producer codex codex exec -C "$REPO" --sandbox danger-full-access --skip-git-repo-check "$PRODUCER_PROMPT"; }
grok_p()    { [ -x "$HOME/.grok/bin/grok" ] || return 1
              run_producer grok "$HOME/.grok/bin/grok" --cwd "$REPO" --permission-mode bypassPermissions --always-approve --max-turns 120 -p "$PRODUCER_PROMPT"; }
minimax_p() { [ -x "$HOME/.local/bin/minimax-agent.py" ] || return 1
              run_producer minimax "$HOME/.local/bin/minimax-agent.py" "$PRODUCER_PROMPT" --cwd "$REPO" --skill-dir "$HOME/.claude/skills/mandy-journal" --max-turns 120 --timeout "$TIMEOUT_SECS"; }

HEAD_BEFORE=$(git -C "$REPO" rev-parse HEAD)
case "$PRODUCER_MODE" in
  claude)  claude_p  || true ;;
  codex)   codex_p   || true ;;
  grok)    grok_p    || true ;;
  minimax) minimax_p || true ;;
  auto|*)
    for p in claude_p codex_p grok_p minimax_p; do
      if $p; then break; fi
      if post_exists_now; then
        log "producer failed but a post for $TODAY exists — stopping the chain"
        PRODUCER_STATUS="OK (post present after failure)"
        break
      fi
    done
    ;;
esac
if [ "$(git -C "$REPO" rev-parse HEAD)" != "$HEAD_BEFORE" ]; then
  log "FATAL: producer moved git HEAD — producer/lander boundary violated"; exit 1
fi
rm -rf "$GUARD_DIR"; GUARD_DIR=""

# --- Land (runs unconditionally: it also quarantines partial state) ----------
log "invoking mandy-land.sh $TODAY"
"$LAND" "$TODAY" >>"$LOG" 2>&1
LAND_RC=$?
LAND_RESULT=$(/usr/bin/grep -oE 'LAND-RESULT: .*' "$LOG" | tail -1 | sed 's/LAND-RESULT: //')
log "land rc=$LAND_RC (${LAND_RESULT:-unknown})"

case "$LAND_RC" in
  0)  STATUS="OK" ;;
  3)  STATUS="OK-WITH-WARNING (pushed, not verified live)" ;;
  10) STATUS="FAILED (QUARANTINED — gates failed)" ;;
  11) STATUS="FAILED (orphaned local commit — manual push needed)" ;;
  12) STATUS="FAILED (blocked before commit)" ;;
  20) case "$PRODUCER_STATUS" in
        OK*) STATUS="FAILED (producer OK but no post found)" ;;
        *)   STATUS="FAILED (${PRODUCER_STATUS}, no post produced)" ;;
      esac ;;
  21) STATUS="OK (already landed)" ;;
  *)  STATUS="FAILED (land rc=$LAND_RC)" ;;
esac
log "Overall STATUS: $STATUS [producer=${PRODUCER_USED:-none}]"

# --- Summary email -----------------------------------------------------------
node "$EMAIL_SCRIPT" --to jeremy@intentsolutions.io \
  --subject "Mandy journal: ${TODAY} — ${STATUS}" \
  --body "$(printf 'mandy-journal-daily for %s\nStatus: %s\nLand: %s (rc=%s)\nProducer: %s [used=%s]\n\nLast 40 log lines (%s):\n\n%s\n' \
    "$TODAY" "$STATUS" "${LAND_RESULT:-n/a}" "$LAND_RC" "$PRODUCER_STATUS" "${PRODUCER_USED:-none}" "$LOG" "$(tail -40 "$LOG")")" \
  >>"$LOG" 2>&1 || log "summary email failed"

NOTIFIED=1
log "=== mandy-journal daily end ==="
case "$STATUS" in OK*) : ;; *) exit 1 ;; esac
