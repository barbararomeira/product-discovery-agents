#!/bin/zsh
# Daily product-discovery run. Reads config.yml, renders prompts/daily.md, runs Claude Code
# headless. Safe to run by hand at any time — the ledger prevents double-counting.

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib.sh"

OUT_DIR="$(cd "$CONFIG_DIR" && python3 -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "$(cfg output dir)")"
MATRIX="$OUT_DIR/$(cfg output matrix_filename)"
LOGDIR="$OUT_DIR/logs"
mkdir -p "$LOGDIR" "$OUT_DIR/Daily briefing"
LOG="$LOGDIR/run-$(date +%F).log"

# The output directory may live in a synced folder (Drive, Dropbox, iCloud) that is not
# mounted yet, or that a scheduler cannot read without disk-access permission. Verify a
# REAL read — an existence test can succeed where reading fails. Wait up to 10 minutes.
if [ -f "$MATRIX" ]; then
  for _ in $(seq 1 60); do
    head -c 1 "$MATRIX" >/dev/null 2>&1 && break
    sleep 10
  done
  if ! head -c 1 "$MATRIX" >/dev/null 2>&1; then
    echo "$(date '+%F %T') ABORT: cannot read $MATRIX (folder not mounted, or the scheduler lacks disk access). Run skipped — the ledger will catch these calls up next time." >> "$LOGDIR/failures.log"
    "$REPO_ROOT/scripts/notify_failure.sh" "Daily discovery" "cannot read the matrix — see failures.log" 2>/dev/null
    exit 1
  fi
else
  echo "No matrix yet — creating one." | tee -a "$LOG"
  python3 "$REPO_ROOT/tools/create_matrix.py" --config "$CONFIG" --out "$MATRIX" | tee -a "$LOG"
fi

echo "=== Run started $(date '+%F %T') ===" >> "$LOG"
cd "$OUT_DIR" || exit 1

ALLOWED_TOOLS="Read,Write,Edit,Glob,Grep,Bash,Task,Agent"
[ -n "$EXTRA_ALLOWED_TOOLS" ] && ALLOWED_TOOLS="$ALLOWED_TOOLS,$EXTRA_ALLOWED_TOOLS"

# A run can stall indefinitely on an unresponsive MCP server, and a silent stall is
# worse than a crash: nothing is produced and nothing complains. Cap it.
MAX_RUN_SECONDS=${MAX_RUN_SECONDS:-3600}

render_prompt "$REPO_ROOT/prompts/daily.md" | claude -p "$(cat)" \
  --model "$(cfg models coordinator)" \
  --allowedTools "$ALLOWED_TOOLS" \
  --output-format text >> "$LOG" 2>&1 &
CLAUDE_PID=$!
# Wall-clock deadline, NOT `sleep N`: macOS (and any machine that suspends) pauses sleep
# timers while asleep, so a plain `sleep 3600` can let a hung run survive overnight —
# in one case 29 hours against a 1-hour cap. Polling the clock kills it promptly on wake.
RUN_DEADLINE=$(( $(date +%s) + MAX_RUN_SECONDS ))
( while kill -0 $CLAUDE_PID 2>/dev/null; do
    if [ "$(date +%s)" -ge "$RUN_DEADLINE" ]; then kill -TERM $CLAUDE_PID 2>/dev/null; break; fi
    sleep 30
  done ) &
WATCHDOG_PID=$!
wait $CLAUDE_PID
STATUS=$?
kill $WATCHDOG_PID 2>/dev/null
if [ $STATUS -eq 143 ]; then
  echo "TIMED OUT after ${MAX_RUN_SECONDS}s — killed. The ledger will catch these calls up next run." >> "$LOG"
fi

if [ $STATUS -eq 0 ]; then
  python3 "$REPO_ROOT/tools/metrics.py" --config "$CONFIG" --matrix "$MATRIX" \
    --scope run --write >> "$LOG" 2>&1
else
  "$REPO_ROOT/scripts/notify_failure.sh" "Daily discovery" "$(tail -n 3 "$LOG" | tr '\n' ' ' | cut -c1-300)" 2>/dev/null
fi

echo "=== Run finished $(date '+%F %T') exit=$STATUS ===" >> "$LOG"
ls -t "$LOGDIR"/run-*.log 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null
exit $STATUS
