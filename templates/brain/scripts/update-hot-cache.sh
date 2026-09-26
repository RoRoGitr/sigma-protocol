#!/usr/bin/env bash
# update-hot-cache.sh - deterministic working-memory summary.
#
# Reads the latest sessions/YYYY-MM-DD.md file from the configured vault and
# writes hot.md. This is pure shell/Python stdlib: no network, no auth, no LLM.

set -uo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"
CONFIG_FILE="$ROOT_DIR/.brain-config.yaml"
VAULT_PATH="${BRAIN_VAULT_PATH:-${BRAIN_VAULT_DIR:-$HOME/Documents/AI Brain}}"
LOG="$SCRIPTS_DIR/hot-cache.log"

log() {
  mkdir -p "$(dirname "$LOG")"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" >> "$LOG"
}

resolve_vault_path() {
  if [[ -f "$CONFIG_FILE" ]]; then
    local configured
    configured="$(python3 - "$CONFIG_FILE" "$HOME" <<'PY' 2>/dev/null || true
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
home = sys.argv[2]
value = ""
try:
    import yaml  # type: ignore
    data = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    value = str(data.get("vault_path") or "")
except Exception:
    for line in config_path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith("vault_path:"):
            value = line.split(":", 1)[1].strip().strip("\"'")
            break
if value.startswith("~/"):
    value = home + value[1:]
print(value)
PY
)"
    [[ -n "$configured" ]] && VAULT_PATH="$configured"
  fi
}

mark_stale() {
  local since="$1"
  local hot_cache="$VAULT_PATH/hot.md"
  mkdir -p "$VAULT_PATH"
  if [[ -f "$hot_cache" ]]; then
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/brain-hot-stale.XXXXXX")"
    tail -n +2 "$hot_cache" > "$tmp" 2>/dev/null || true
    printf '[STALE since %s - regeneration skipped; see %s]\n' "$since" "$LOG" | cat - "$tmp" > "$hot_cache"
    rm -f "$tmp"
  else
    printf '[STALE since %s - not yet generated]\n## Hot cache - not generated\n- No session has been recorded yet.\n' "$since" > "$hot_cache"
  fi
}

resolve_vault_path

SESSIONS_DIR="$VAULT_PATH/sessions"
HOT_CACHE="$VAULT_PATH/hot.md"
UPDATED_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

log "=== update-hot-cache start ==="

LATEST_SESSION="$(ls -1 "$SESSIONS_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$' | sort | tail -1)"
if [[ -z "${LATEST_SESSION:-}" || ! -f "$LATEST_SESSION" ]]; then
  log "No session file found in $SESSIONS_DIR"
  mark_stale "$UPDATED_ISO"
  exit 0
fi

if [[ -f "$HOT_CACHE" ]]; then
  if stat -f %m "$HOT_CACHE" >/dev/null 2>&1; then
    age=$(( $(date +%s) - $(stat -f %m "$HOT_CACHE") ))
  else
    age=$(( $(date +%s) - $(stat -c %Y "$HOT_CACHE" 2>/dev/null || echo 0) ))
  fi
  if [[ "$age" -lt 300 ]]; then
    log "Skipping: hot.md updated ${age}s ago"
    exit 0
  fi
fi

if [[ ! -s "$LATEST_SESSION" ]]; then
  log "Latest session is empty: $LATEST_SESSION"
  mark_stale "$UPDATED_ISO"
  exit 0
fi

extract_tmp="$(mktemp "${TMPDIR:-/tmp}/brain-hot-extract.XXXXXX")"
stamped_tmp="$(mktemp "${TMPDIR:-/tmp}/brain-hot-stamped.XXXXXX")"

awk '
  BEGIN { in_section=0; found=0 }
  /^## |^### / {
    lower = tolower($0)
    if (lower ~ /decision|decided|shipped|changed|pending|blocked|next|active|scheduled|todo|handoff|proof|verified/) {
      in_section = 1
      found = 1
      print
      next
    } else if (in_section) {
      in_section = 0
    }
  }
  in_section { print }
  END { exit(found ? 0 : 1) }
' "$LATEST_SESSION" > "$extract_tmp" 2>/dev/null

if [[ $? -ne 0 || ! -s "$extract_tmp" ]]; then
  tail -60 "$LATEST_SESSION" > "$extract_tmp"
fi

session_date="$(basename "$LATEST_SESSION" .md)"
{
  printf 'updated: %s\n' "$UPDATED_ISO"
  printf '\n## Hot cache - last session (%s)\n\n' "$session_date"
  cat "$extract_tmp"
} > "$stamped_tmp"

if [[ $(wc -c < "$stamped_tmp") -gt 4096 ]]; then
  head -c 4096 "$stamped_tmp" > "${stamped_tmp}.cap"
  mv "${stamped_tmp}.cap" "$stamped_tmp"
fi

mkdir -p "$VAULT_PATH"
mv "$stamped_tmp" "$HOT_CACHE"
rm -f "$extract_tmp"

log "Updated hot.md from $(basename "$LATEST_SESSION")"
exit 0
