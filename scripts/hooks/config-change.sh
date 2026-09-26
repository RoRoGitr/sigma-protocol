#!/usr/bin/env bash
# Optional Claude hook template: ConfigChange
# Logs config mutations so orchestrator runs can be correlated with policy changes.

set -euo pipefail

PROJECT_ROOT="${SIGMA_PROJECT_ROOT:-$(pwd)}"
ORCH_DIR="$PROJECT_ROOT/.sigma/orchestration"
LOG_FILE="$ORCH_DIR/hooks.log"
CONFIG_PATH="${CONFIG_PATH:-${CLAUDE_CONFIG_PATH:-unknown}}"
CHANGE_KIND="${CHANGE_KIND:-${CLAUDE_CONFIG_CHANGE_KIND:-updated}}"

mkdir -p "$ORCH_DIR"
printf '[%s] [config-change] file=%s change=%s\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  "$CONFIG_PATH" \
  "$CHANGE_KIND" >> "$LOG_FILE"

exit 0
