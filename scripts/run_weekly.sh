#!/bin/zsh
# Weekly PM digest + opportunity briefs. Reads config.yml, renders prompts/weekly.md,
# runs Claude Code headless. Safe to run by hand at any time.

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib.sh"

OUT_DIR="$(cd "$CONFIG_DIR" && python3 -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "$(cfg output dir)")"
MATRIX="$OUT_DIR/$(cfg output matrix_filename)"
LOGDIR="$OUT_DIR/logs"
mkdir -p "$LOGDIR" "$OUT_DIR/Weekly digest" "$OUT_DIR/Opportunity briefs" "$OUT_DIR/snapshots"
LOG="$LOGDIR/weekly-$(date +%F).log"

# Verify a REAL read of the matrix — see the note in run_daily.sh.
if [ ! -f "$MATRIX" ]; then
  echo "No matrix at $MATRIX — run scripts/run_daily.sh first." | tee -a "$LOG"
  exit 1
fi
for _ in $(seq 1 60); do
  head -c 1 "$MATRIX" >/dev/null 2>&1 && break
  sleep 10
done
if ! head -c 1 "$MATRIX" >/dev/null 2>&1; then
  echo "$(date '+%F %T') ABORT: cannot read $MATRIX (folder not mounted, or the scheduler lacks disk access). Digest skipped." >> "$LOGDIR/failures.log"
  "$REPO_ROOT/scripts/notify_failure.sh" "Weekly digest" "cannot read the matrix — see failures.log" 2>/dev/null
  exit 1
fi

echo "=== Weekly run started $(date '+%F %T') ===" >> "$LOG"
cd "$OUT_DIR" || exit 1

ALLOWED_TOOLS="Read,Write,Edit,Glob,Grep,Bash"
[ -n "$EXTRA_ALLOWED_TOOLS" ] && ALLOWED_TOOLS="$ALLOWED_TOOLS,$EXTRA_ALLOWED_TOOLS"

# A run can stall indefinitely on an unresponsive MCP server, and a silent stall is
# worse than a crash: nothing is produced and nothing complains. Cap it.
MAX_RUN_SECONDS=${MAX_RUN_SECONDS:-3600}

render_prompt "$REPO_ROOT/prompts/weekly.md" | claude -p "$(cat)" \
  --model "$(cfg models weekly)" \
  --allowedTools "$ALLOWED_TOOLS" \
  --output-format text >> "$LOG" 2>&1 &
CLAUDE_PID=$!
( sleep "$MAX_RUN_SECONDS"; kill -TERM $CLAUDE_PID 2>/dev/null ) &
WATCHDOG_PID=$!
wait $CLAUDE_PID
STATUS=$?
kill $WATCHDOG_PID 2>/dev/null
if [ $STATUS -eq 143 ]; then
  echo "TIMED OUT after ${MAX_RUN_SECONDS}s — killed. The ledger will catch these calls up next run." >> "$LOG"
fi

if [ $STATUS -eq 0 ]; then
  python3 "$REPO_ROOT/tools/metrics.py" --config "$CONFIG" --matrix "$MATRIX" \
    --scope week --write >> "$LOG" 2>&1
else
  "$REPO_ROOT/scripts/notify_failure.sh" "Weekly digest" "$(tail -n 3 "$LOG" | tr '\n' ' ' | cut -c1-300)" 2>/dev/null
fi

echo "=== Weekly run finished $(date '+%F %T') exit=$STATUS ===" >> "$LOG"
ls -t "$LOGDIR"/weekly-*.log 2>/dev/null | tail -n +13 | xargs rm -f 2>/dev/null
exit $STATUS
