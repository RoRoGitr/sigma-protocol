#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Handle --all flag (clears all pipeline state across all repos)
if [[ "${1:-}" == "--all" ]]; then
  echo "Clearing all pipeline state files..."
  # Clean up any legacy /tmp/ files
  rm -f /tmp/pipeline-state-*.json
  rm -f /tmp/pipeline-stop-warned-*
  # Also clean current repo if in one
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
  if [[ -n "$REPO_ROOT" ]]; then
    rm -f "${REPO_ROOT}/.pipeline-state.json"
  fi
  echo "Done."
  exit 0
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "Not inside a git repository — nothing to reset."
  exit 0
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

if [[ -f "$CHECKPOINT_FILE" ]]; then
  # Clean up the stop-warned marker too if it exists
  if command -v jq &>/dev/null; then
    SESSION_ID=$(jq -r '.session_id // ""' "$CHECKPOINT_FILE" 2>/dev/null || true)
    if [[ -n "$SESSION_ID" ]]; then
      rm -f "/tmp/pipeline-stop-warned-${SESSION_ID}"
    fi
  fi

  rm -f "$CHECKPOINT_FILE"
  BRANCH_RAW="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo "Pipeline checkpoint cleared for $(basename "$REPO_ROOT")/${BRANCH_RAW}"
else
  BRANCH_RAW="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
  echo "No pipeline checkpoint found for $(basename "$REPO_ROOT")/${BRANCH_RAW}"
fi
