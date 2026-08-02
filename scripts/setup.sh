#!/bin/zsh
# One-time setup. Creates config.yml, the output folders and a blank matrix,
# then renders scheduling files you can install if you want it to run by itself.

export PATH="$HOME/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

say() { print -P "%F{blue}$1%f"; }
warn() { print -P "%F{yellow}$1%f"; }

if [ ! -f config.yml ]; then
  cp config.example.yml config.yml
  say "Created config.yml from the example."
  warn "Open it and set: company name, internal email domains, your name, the team roster,"
  warn "and where your transcripts come from. Then run this script again."
  exit 0
fi

source "$REPO_ROOT/scripts/lib.sh"

command -v claude >/dev/null 2>&1 || warn "Claude Code CLI ('claude') not found on PATH — the runners need it."
python3 -c "import openpyxl" 2>/dev/null || warn "Python package 'openpyxl' missing — install with: pip3 install openpyxl"

OUT_DIR="$(cd "$CONFIG_DIR" && python3 -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "$(cfg output dir)")"
mkdir -p "$OUT_DIR"/{logs,"Daily briefing","Weekly digest","Opportunity briefs",snapshots}
MATRIX="$OUT_DIR/$(cfg output matrix_filename)"
if [ -f "$MATRIX" ]; then
  say "Matrix already exists — leaving it alone (it is your accumulated evidence)."
else
  python3 tools/create_matrix.py --config "$CONFIG" --out "$MATRIX"
fi

# Render scheduling files with real paths, so they can be installed as-is.
mkdir -p "$OUT_DIR/scheduling"
for job in daily weekly; do
  if [ "$job" = "daily" ]; then
    HOUR="$(cfg schedule daily_hour)"; MIN="$(cfg schedule daily_minute)"; DOW=""
  else
    HOUR="$(cfg schedule weekly_hour)"; MIN="$(cfg schedule weekly_minute)"; DOW="$(cfg schedule weekly_weekday)"
  fi
  sed -e "s|{{LABEL}}|com.productdiscovery.$job|g" \
      -e "s|{{SCRIPT}}|$REPO_ROOT/scripts/run_$job.sh|g" \
      -e "s|{{CONFIG}}|$CONFIG|g" \
      -e "s|{{LOGDIR}}|$OUT_DIR/logs|g" \
      -e "s|{{HOUR}}|$HOUR|g" -e "s|{{MINUTE}}|$MIN|g" \
      templates/launchd/job.plist.template > "$OUT_DIR/scheduling/com.productdiscovery.$job.plist"
  if [ -n "$DOW" ]; then
    python3 - "$OUT_DIR/scheduling/com.productdiscovery.$job.plist" "$DOW" <<'PY'
import sys
p, dow = sys.argv[1], sys.argv[2]
t = open(p).read().replace("<!--WEEKDAY-->",
    f"<key>Weekday</key>\n        <integer>{dow}</integer>")
open(p, "w").write(t)
PY
  else
    python3 - "$OUT_DIR/scheduling/com.productdiscovery.$job.plist" <<'PY'
import sys
p = sys.argv[1]
text = open(p).read().replace("<!--WEEKDAY-->", "")   # read fully before opening for write
open(p, "w").write(text)
PY
  fi
done

say ""
say "Setup complete."
print "  Matrix:      $MATRIX"
print "  Outputs:     $OUT_DIR"
print ""
print "Try it once by hand before scheduling anything:"
print "  ./scripts/run_daily.sh"
print ""
print "To run it automatically (macOS):"
print "  cp \"$OUT_DIR/scheduling/\"*.plist ~/Library/LaunchAgents/"
print "  launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.productdiscovery.daily.plist"
print "  launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.productdiscovery.weekly.plist"
print ""
print "On Linux, see templates/cron.md."
warn "If your output folder is in Google Drive/Dropbox/iCloud, read the disk-access note in the README"
warn "before scheduling — a scheduler that cannot read the folder fails silently every morning."
