#!/bin/zsh
# Optional failure notification. No-ops cleanly when notifications aren't configured,
# so a silent scheduler failure still leaves a trail in failures.log either way.
#
# Usage: notify_failure.sh "<job name>" "<detail>"

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$REPO_ROOT/scripts/lib.sh"

JOB="${1:-Product discovery run}"
DETAIL="${2:-no detail}"
HANDLE="$(cfg pm slack_handle)"

# Always leave a local trail.
OUT_DIR="$(cd "$CONFIG_DIR" && python3 -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "$(cfg output dir)")"
mkdir -p "$OUT_DIR/logs"
echo "$(date '+%F %T') FAILED: $JOB — $DETAIL" >> "$OUT_DIR/logs/failures.log"

# Nothing configured? Local trail is all you get, and that is a valid setup.
if [ -z "$HANDLE" ]; then
  exit 0
fi

# A chat notification needs a messaging tool connected to your Claude Code (e.g. an MCP
# server for Slack, Teams or Discord). Set EXTRA_NOTIFY_TOOLS to that tool's names.
if [ -z "$EXTRA_NOTIFY_TOOLS" ]; then
  echo "slack_handle is set but EXTRA_NOTIFY_TOOLS is not — skipping the chat notification." \
    >> "$OUT_DIR/logs/failures.log"
  exit 0
fi

claude -p "Send a short direct message to ${HANDLE} saying: '${JOB} failed — ${DETAIL}'. Send exactly one message. Do not post to any channel." \
  --model "claude-haiku-4-5-20251001" \
  --allowedTools "$EXTRA_NOTIFY_TOOLS" \
  --output-format text >/dev/null 2>&1

exit 0
