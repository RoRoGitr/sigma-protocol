#!/usr/bin/env bash
# Stop/SessionEnd hook: capture context, refresh hot cache, and trigger gated research.

set -uo pipefail

[[ -n "${CLAUDE_INVOKED_BY:-}" ]] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
TRANSCRIPT_PATH="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)"

[[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$(dirname "$SCRIPT_DIR")/scripts"
CONTEXT_FILE="$(mktemp "${TMPDIR:-/tmp}/brain-flush-stop-${SESSION_ID}.XXXXXX.md")"

python3 - "$TRANSCRIPT_PATH" > "$CONTEXT_FILE" 2>/dev/null <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
turns = []
for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
    if not line.strip():
        continue
    try:
        entry = json.loads(line)
    except Exception:
        continue
    msg = entry.get("message", {})
    role = msg.get("role", "") if isinstance(msg, dict) else entry.get("role", "")
    content = msg.get("content", "") if isinstance(msg, dict) else entry.get("content", "")
    if role not in ("user", "assistant"):
        continue
    if isinstance(content, list):
        content = " ".join(
            block.get("text", "")
            for block in content
            if isinstance(block, dict) and block.get("type") == "text"
        )
    if isinstance(content, str) and content.strip():
        label = "User" if role == "user" else "Assistant"
        turns.append(f"**{label}:** {content.strip()}")
recent = turns[-30:]
text = "\n\n".join(recent)
if len(text) > 15000:
    text = text[-15000:]
    idx = text.find("\n**")
    if idx > 0:
        text = text[idx + 1 :]
print(text)
PY

guard="${BRAIN_SPAWN_GUARD:-$HOME/.local/bin/agent-spawn-guard}"
min_battery="${BRAIN_SPAWN_MIN_BATTERY:-15}"

if [[ -s "$CONTEXT_FILE" ]]; then
  if [[ ! -x "$guard" ]] || "$guard" --name brain-flush --min-battery "$min_battery" --quiet; then
    CLAUDE_INVOKED_BY=memory_flush nohup bash -c '
      scripts_dir="$1"
      context_file="$2"
      session_id="$3"
      if command -v uv >/dev/null 2>&1; then
        exec env CLAUDE_INVOKED_BY=memory_flush uv run --directory "$(dirname "$scripts_dir")" python "$scripts_dir/flush.py" "$context_file" "$session_id"
      fi
      exec env CLAUDE_INVOKED_BY=memory_flush python3 "$scripts_dir/flush.py" "$context_file" "$session_id"
    ' _ "$SCRIPTS_DIR" "$CONTEXT_FILE" "$SESSION_ID" >> "$SCRIPTS_DIR/flush.log" 2>&1 &
  else
    rm -f "$CONTEXT_FILE"
  fi
else
  rm -f "$CONTEXT_FILE"
fi

bash "$SCRIPTS_DIR/update-hot-cache.sh" >> "$SCRIPTS_DIR/hot-cache.log" 2>&1 || true

if [[ ! -x "$guard" ]] || "$guard" --name brain-autoresearch --min-battery "$min_battery" --quiet; then
  nohup bash "$SCRIPTS_DIR/autoresearch-gated.sh" >> "$SCRIPTS_DIR/autoresearch-gated.log" 2>&1 &
fi

exit 0
