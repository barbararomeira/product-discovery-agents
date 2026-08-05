#!/bin/zsh
# Shared helpers: read config.yml, resolve {{PLACEHOLDERS}} in a prompt.
# Deliberately dependency-free — no yq, no PyYAML. The config is flat enough.

REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${(%):-%x}")/.." && pwd)}"
CONFIG="${CONFIG:-$REPO_ROOT/config.yml}"
# Relative paths inside config.yml resolve against the config file's own directory,
# so a config can live anywhere (see example-run/).
CONFIG_DIR="$(cd "$(dirname "$CONFIG")" && pwd)"

if [ ! -f "$CONFIG" ]; then
  echo "No config.yml found. Copy config.example.yml to config.yml and edit it." >&2
  exit 1
fi

# cfg <section> <key> — reads a scalar from a two-level YAML config.
cfg() {
  python3 - "$CONFIG" "$1" "$2" <<'PY'
import sys, re
path, section, key = sys.argv[1], sys.argv[2], sys.argv[3]
cur, depth_of_section = None, None
for raw in open(path, encoding="utf-8"):
    line = raw.rstrip("\n")
    if not line.strip() or line.strip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    stripped = line.strip()
    if indent == 0:
        cur = stripped.split(":", 1)[0]
        continue
    if cur != section:
        continue
    m = re.match(r"([\w_]+):\s*(.*)$", stripped)
    if m and m.group(1) == key:
        raw = m.group(2).strip()
        # A quoted value wins outright — that keeps '#3D5A80' from looking like a comment.
        q = re.match(r'^"([^"]*)"|^\'([^\']*)\'', raw)
        if q:
            val = q.group(1) if q.group(1) is not None else q.group(2)
        else:
            val = raw.split("#")[0].strip()
        print(val)
        break
PY
}

# cfg_list <section> <subkey> — reads a nested list as a comma-separated string.
cfg_list() {
  python3 - "$CONFIG" "$1" "$2" <<'PY'
import sys
path, section, key = sys.argv[1], sys.argv[2], sys.argv[3]
cur, sub, items, collecting = None, None, [], False
for raw in open(path, encoding="utf-8"):
    line = raw.rstrip("\n")
    if not line.strip() or line.strip().startswith("#"):
        continue
    indent = len(line) - len(line.lstrip())
    stripped = line.strip()
    if indent == 0:
        cur, collecting = stripped.split(":", 1)[0], False
        continue
    if stripped.startswith("- "):
        if collecting:
            items.append(stripped[2:].strip().strip('"\''))
        continue
    if cur == section:
        sub = stripped.split(":", 1)[0]
        collecting = (sub == key)
print(", ".join(items))
PY
}

# render_prompt <prompt-file> — substitutes every {{PLACEHOLDER}} and prints the result.
render_prompt() {
  local prompt_file="$1"
  local source_mode; source_mode="$(cfg transcripts mode)"
  local source_doc
  if [ "$source_mode" = "folder" ]; then
    source_doc="Read transcript files from the folder $(cfg folder path). Each file is one call; use the filename and the file's own header for the date, title, participants and their email domains. Treat the file path as the call's unique id."
  else
    source_doc="Use the connected call-recorder tools available to you (MCP tool prefix: $(cfg recorder mcp_prefix)) to list calls in the window and fetch each transcript. Use the recorder's recording id as the call's unique id, and keep its share link for source attribution."
  fi

  local knowledge_mode; knowledge_mode="$(cfg product_knowledge mode)"
  local knowledge_source
  if [ "$knowledge_mode" = "file" ]; then
    knowledge_source="the local file $(cfg product_knowledge file)"
  else
    knowledge_source="$(cfg remote description)"
  fi

  python3 - "$prompt_file" <<PY
import sys
text = open(sys.argv[1], encoding="utf-8").read()
subs = {
  "{{COMPANY_NAME}}": """$(cfg company name)""",
  "{{PM_NAME}}": """$(cfg pm name)""",
  "{{INTERNAL_EMAIL_DOMAINS}}": """$(cfg_list company internal_email_domains)""",
  "{{TEAM_SALES}}": """$(cfg_list team sales)""",
  "{{TEAM_POST_SALES}}": """$(cfg_list team post_sales)""",
  "{{TEAM_CUSTOMER_SUCCESS}}": """$(cfg_list team customer_success)""",
  "{{TEAM_PRODUCT}}": """$(cfg_list team product)""",
  "{{TRANSCRIPT_SOURCE_INSTRUCTIONS}}": """$source_doc""",
  "{{PRODUCT_KNOWLEDGE_SOURCE}}": """$knowledge_source""",
  "{{PRODUCT_KNOWLEDGE_CACHE}}": """$(cfg product_knowledge file)""",
  "{{KNOWLEDGE_REFRESH_DAYS}}": """$(cfg product_knowledge refresh_days)""",
  "{{OUTPUT_DIR}}": """$(cfg output dir)""",
  "{{MATRIX_FILENAME}}": """$(cfg output matrix_filename)""",
  "{{TIMEZONE}}": """$(cfg output timezone)""",
  "{{LANGUAGE}}": """$(cfg output language)""",
  "{{PRODUCT_NAME}}": """$(cfg branding product_name)""",
  "{{ACCENT}}": """$(cfg branding accent)""",
  "{{ACCENT_SECONDARY}}": """$(cfg branding accent_secondary)""",
  "{{CHROME_PATH}}": """$(cfg branding chrome_path)""",
  "{{BRIEF_THRESHOLD_CUSTOMERS}}": """$(cfg scoring brief_threshold_customers)""",
  "{{BRIEF_THRESHOLD_IMPORTANCE2}}": """$(cfg scoring brief_threshold_importance2)""",
  "{{TRANSCRIPT_HELPER_MODEL}}": """$(cfg models transcript_helper)""",
  "{{MAX_CONCURRENT_HELPERS}}": """$(cfg models max_concurrent_helpers)""",
}
for k, v in subs.items():
    text = text.replace(k, v)
left = [l for l in text.split() if l.startswith("{{")]
if left:
    sys.stderr.write("unresolved placeholders: " + ", ".join(sorted(set(left))) + "\n")
print(text)
PY
}
