#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# Usage check
if [[ $# -lt 1 ]]; then
  echo "Usage: track-file-change.sh <file_path>" >&2
  exit 1
fi

FILE_PATH="$1"

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  # Not in a git repo — skip tracking
  exit 0
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

# Auto-initialize if checkpoint doesn't exist
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  "$SCRIPT_DIR/pipeline-init.sh"
fi

# Add file to changed_files (deduplicated)
UPDATED=$(jq \
  --arg file "$FILE_PATH" \
  'if (.changed_files | index($file)) then . else .changed_files += [$file] end' \
  "$CHECKPOINT_FILE")

# Check if this is a frontend file
IS_FRONTEND=false

# Check by extension
case "$FILE_PATH" in
  *.tsx|*.jsx|*.css|*.scss|*.vue|*.svelte|*.module.css)
    IS_FRONTEND=true
    ;;
esac

# Check by path pattern
if [[ "$FILE_PATH" == *"/components/"* ]] || \
   [[ "$FILE_PATH" == *"/app/"* ]] || \
   [[ "$FILE_PATH" == *"/pages/"* ]] || \
   [[ "$FILE_PATH" == *"/views/"* ]] || \
   [[ "$FILE_PATH" == *"/layouts/"* ]]; then
  case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.css|*.scss|*.vue|*.svelte|*.html)
      IS_FRONTEND=true
      ;;
  esac
fi

# Update has_frontend_changes if needed
if [[ "$IS_FRONTEND" == "true" ]]; then
  UPDATED=$(echo "$UPDATED" | jq '.has_frontend_changes = true')
fi

UPDATED=$(echo "$UPDATED" | jq \
  --arg updated_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  '.last_change_at = $updated_at
   | .commit_allowed = false')

echo "$UPDATED" > "$CHECKPOINT_FILE"

"$SCRIPT_DIR/sync-worktree-state.sh" >/dev/null 2>&1 || true
