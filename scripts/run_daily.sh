#!/bin/zsh
# Daily product-discovery run. Reads config.yml, renders prompts/daily.md, runs Claude Code
# headless. Safe to run by hand at any time — the ledger prevents double-counting, and the
# lock below prevents a hand-run and a scheduled run from overlapping. The ledger alone is
# not enough: it stops a call being processed twice, not two runs writing at once.

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib.sh"

OUT_DIR="$(cd "$CONFIG_DIR" && python3 -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "$(cfg output dir)")"
MATRIX="$OUT_DIR/$(cfg output matrix_filename)"
LOGDIR="$OUT_DIR/logs"
mkdir -p "$LOGDIR" "$OUT_DIR/Daily briefing"
LOG="$LOGDIR/run-$(date +%F).log"

# --- single-run lock ---
# The ledger stops a call being counted twice. It does not stop two runs existing at once, and
# those are different problems: overlapping runs write the same workbook from two processes and
# can deliver the same message twice, both before either one reaches the ledger.
#
# This is not hypothetical. A hand-started catch-up run was still working when the scheduled run
# fired an hour later. Nothing stopped it — it happened to inspect the ledger, notice the day was
# already done and abort itself, which is judgement standing in for a lock.
#
# mkdir is atomic on every POSIX filesystem, which flock is not (absent on stock macOS, unreliable
# over network mounts). The PID inside lets us tell a live run from a crashed one.
LOCK="$LOGDIR/.run_daily.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  OTHER=$(cat "$LOCK/pid" 2>/dev/null)
  if [ -n "$OTHER" ] && kill -0 "$OTHER" 2>/dev/null; then
    echo "$(date '+%F %T') ABORT: run already in progress (pid $OTHER). Skipped — no writes made." >> "$LOGDIR/failures.log"
    exit 0
  fi
  # No live owner: the previous run died without cleaning up. Take the lock and say so, rather
  # than refusing forever on a stale directory — a lock that outlives its holder is an outage.
  echo "$(date '+%F %T') NOTE: stale lock from pid ${OTHER:-unknown} reclaimed." >> "$LOGDIR/failures.log"
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT INT TERM

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

# Snapshot the fields that belong to the PM, so the validator below can prove the run did not
# overwrite them. Cheap, and the only way to tell "the agent tidied a human's column" from
# "the human changed it themselves" after the fact.
MANUAL_SNAPSHOT="$LOGDIR/.manual-before.json"
python3 "$REPO_ROOT/tools/validate_matrix.py" "$MATRIX" --save-manual "$MANUAL_SNAPSHOT" \
  >> "$LOG" 2>&1 || echo "NOTE: could not snapshot manual fields; the overwrite check will be skipped." >> "$LOG"

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
  # The merge is a judgement and cannot be tested. Its OUTPUT can: importance inside the scale,
  # accounts counted once, priority equal to its own formula, ranks 1..n in priority order, every
  # row sourced, and the PM's columns untouched. A violation means the run produced a matrix that
  # looks finished and is wrong, which is the failure worth catching before anyone reads it.
  # Non-fatal for the run — the work is done and the briefing is worth having — but it notifies.
  if ! python3 "$REPO_ROOT/tools/validate_matrix.py" "$MATRIX" \
         --check-manual "$MANUAL_SNAPSHOT" >> "$LOG" 2>&1; then
    "$REPO_ROOT/scripts/notify_failure.sh" "Daily discovery" \
      "the matrix failed validation — see $LOG" 2>/dev/null
  fi
  rm -f "$MANUAL_SNAPSHOT"
  python3 "$REPO_ROOT/tools/metrics.py" --config "$CONFIG" --matrix "$MATRIX" \
    --scope run --write >> "$LOG" 2>&1
else
  "$REPO_ROOT/scripts/notify_failure.sh" "Daily discovery" "$(tail -n 3 "$LOG" | tr '\n' ' ' | cut -c1-300)" 2>/dev/null
fi

echo "=== Run finished $(date '+%F %T') exit=$STATUS ===" >> "$LOG"
ls -t "$LOGDIR"/run-*.log 2>/dev/null | tail -n +31 | xargs rm -f 2>/dev/null
exit $STATUS
