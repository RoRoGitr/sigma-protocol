#!/usr/bin/env bash
# autoresearch-gated.sh - safe daily wrapper for autoresearch.sh.
#
# Gates:
# - 24h cooldown by default
# - optional agent-spawn-guard battery check
# - generic long-running-job process check
# - atomic compile lock so flush and daily research do not race

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPTS_DIR")"
CONFIG_FILE="$ROOT_DIR/.brain-config.yaml"
LOG_FILE="$SCRIPTS_DIR/autoresearch-gated.log"
STATE_FILE="$SCRIPTS_DIR/autoresearch-gated-state.json"
FORCE=false

case "${1:-}" in
  --force) FORCE=true ;;
  "") ;;
  *) echo "Usage: autoresearch-gated.sh [--force]" >&2; exit 2 ;;
esac

log() {
  mkdir -p "$(dirname "$LOG_FILE")"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] GATE: $1" >> "$LOG_FILE"
}

config_value() {
  local key="$1"
  local default="$2"
  python3 - "$CONFIG_FILE" "$key" "$default" <<'PY' 2>/dev/null || printf '%s\n' "$default"
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
default = sys.argv[3]
if not path.exists():
    print(default)
    raise SystemExit(0)
try:
    import yaml  # type: ignore
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    print(data.get(key, default))
except Exception:
    value = default
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith(key + ":"):
            value = line.split(":", 1)[1].strip().strip("\"'")
            break
    print(value)
PY
}

COOLDOWN_HOURS="${BRAIN_AUTORESEARCH_COOLDOWN_HOURS:-$(config_value autoresearch_cooldown_hours 24)}"
MIN_BATTERY="${BRAIN_SPAWN_MIN_BATTERY:-$(config_value spawn_min_battery 15)}"

log "=== gated autoresearch start force=$FORCE cooldown=${COOLDOWN_HOURS}h ==="

if ! $FORCE && [[ -f "$STATE_FILE" ]]; then
  last_epoch="$(python3 - "$STATE_FILE" <<'PY' 2>/dev/null || echo 0
import json
import sys
try:
    print(int(json.load(open(sys.argv[1], "r", encoding="utf-8")).get("last_success_epoch", 0)))
except Exception:
    print(0)
PY
)"
  now_epoch="$(date +%s)"
  min_age=$(( COOLDOWN_HOURS * 3600 ))
  age=$(( now_epoch - last_epoch ))
  if [[ "$last_epoch" -gt 0 && "$age" -lt "$min_age" ]]; then
    log "Skipping: last success ${age}s ago (< ${min_age}s cooldown)"
    exit 0
  fi
fi

guard="${BRAIN_SPAWN_GUARD:-$HOME/.local/bin/agent-spawn-guard}"
if [[ -x "$guard" ]]; then
  if ! "$guard" --name brain-autoresearch --min-battery "$MIN_BATTERY" --quiet; then
    log "Skipping: spawn guard rejected brain-autoresearch"
    exit 0
  fi
fi

patterns="${BRAIN_LONG_RUNNING_JOB_PATTERNS:-npm run build|pnpm build|pytest|vitest|playwright|cargo test|go test|xcodebuild|gradle|mvn test}"
if [[ -n "$patterns" ]] && pgrep -f "$patterns" >/dev/null 2>&1; then
  log "Skipping: generic long-running job matched pattern"
  exit 0
fi

if pgrep -f "$SCRIPTS_DIR/autoresearch.sh" >/dev/null 2>&1; then
  log "Skipping: autoresearch.sh already running"
  exit 0
fi

lock_dir="${TMPDIR:-/tmp}/ai-brain-compile-${UID:-user}.lock.d"
cleanup_lock() {
  rmdir "$lock_dir" 2>/dev/null || true
}

if ! mkdir "$lock_dir" 2>/dev/null; then
  now_epoch="$(date +%s)"
  if stat -f %m "$lock_dir" >/dev/null 2>&1; then
    lock_epoch="$(stat -f %m "$lock_dir")"
  else
    lock_epoch="$(stat -c %Y "$lock_dir" 2>/dev/null || echo "$now_epoch")"
  fi
  lock_age=$(( (now_epoch - lock_epoch) / 60 ))
  if [[ "$lock_age" -gt 30 ]]; then
    log "Reclaiming stale compile lock age=${lock_age}m"
    rmdir "$lock_dir" 2>/dev/null || true
    mkdir "$lock_dir" 2>/dev/null || {
      log "Skipping: could not reclaim stale lock"
      exit 0
    }
  else
    log "Skipping: compile lock held age=${lock_age}m"
    exit 0
  fi
fi
trap cleanup_lock EXIT

log "Running autoresearch.sh"
bash "$SCRIPTS_DIR/autoresearch.sh" >> "$LOG_FILE" 2>&1 || {
  code=$?
  log "ERROR: autoresearch.sh exited with $code"
  exit "$code"
}

python3 - "$STATE_FILE" <<'PY'
import json
import sys
import time
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(json.dumps({"last_success_epoch": int(time.time())}, indent=2), encoding="utf-8")
PY

log "=== gated autoresearch complete ==="
exit 0
