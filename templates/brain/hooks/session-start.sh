#!/usr/bin/env bash
# SessionStart hook: inject compact brain context into a new CLI session.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$ROOT_DIR/.brain-config.yaml"
VAULT_PATH="${BRAIN_VAULT_PATH:-${BRAIN_VAULT_DIR:-$HOME/Documents/AI Brain}}"

resolve_context() {
  python3 - "$CONFIG_FILE" "$HOME" "$(pwd)" <<'PY' 2>/dev/null || true
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
home = sys.argv[2]
cwd = sys.argv[3]
vault = ""
project = ""
project_map = {}

if config_path.exists():
    text = config_path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore
        data = yaml.safe_load(text) or {}
        vault = str(data.get("vault_path") or "")
        project_map = data.get("project_map") or {}
    except Exception:
        current = None
        for raw in text.splitlines():
            line = raw.rstrip()
            if line.strip().startswith("vault_path:"):
                vault = line.split(":", 1)[1].strip().strip("\"'")
            elif line.strip() == "project_map:":
                current = "project_map"
            elif current == "project_map" and raw.startswith((" ", "\t")) and ":" in raw:
                key, value = raw.strip().split(":", 1)
                project_map[key.strip()] = value.strip().strip("\"'")

for pattern, slug in project_map.items():
    if pattern and pattern in cwd:
        project = str(slug)
        break

if vault.startswith("~/"):
    vault = home + vault[1:]
print(vault)
print(project)
PY
}

context="$(resolve_context)"
configured_vault="$(printf '%s\n' "$context" | sed -n '1p')"
PROJECT="$(printf '%s\n' "$context" | sed -n '2p')"
[[ -n "$configured_vault" ]] && VAULT_PATH="$configured_vault"

INDEX_FILE="$VAULT_PATH/memory/index.md"
HOT_FILE="$VAULT_PATH/hot.md"
SESSIONS_DIR="$VAULT_PATH/sessions"

if [[ -f "$HOT_FILE" ]]; then
  echo "--- BRAIN HOT CACHE ---"
  head -80 "$HOT_FILE"
fi

if [[ -f "$INDEX_FILE" ]]; then
  echo ""
  echo "--- BRAIN INDEX ---"
  head -50 "$INDEX_FILE"
fi

if [[ -n "${PROJECT:-}" ]]; then
  GOTCHAS="$VAULT_PATH/projects/$PROJECT/gotchas.md"
  if [[ -f "$GOTCHAS" ]]; then
    gotcha_count="$(grep -c "^- " "$GOTCHAS" 2>/dev/null || echo "0")"
    if [[ "$gotcha_count" -gt 0 ]]; then
      echo ""
      echo "--- PROJECT GOTCHAS ($PROJECT: $gotcha_count) ---"
      head -30 "$GOTCHAS"
    fi
  fi
fi

latest_session="$(ls -1 "$SESSIONS_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -1)"
if [[ -n "${latest_session:-}" && -f "$latest_session" ]]; then
  echo ""
  echo "--- RECENT SESSION ($(basename "$latest_session" .md)) ---"
  tail -30 "$latest_session"
fi

exit 0
