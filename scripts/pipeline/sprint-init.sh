#!/bin/bash
set -e

# Sprint Init — Creates .sprint-state.json in the current git repo root.
# Usage: sprint-init.sh [--task-id TASK_ID]

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

STATE_FILE="${REPO_ROOT}/.sprint-state.json"

# Parse args
TASK_ID=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    *)
      echo "Usage: sprint-init.sh [--task-id TASK_ID]" >&2
      exit 1
      ;;
  esac
done

# Idempotent: if file exists AND current_step > 0, do nothing
if [[ -f "$STATE_FILE" ]]; then
  CURRENT_STEP=$(jq -r '.current_step // 0' "$STATE_FILE" 2>/dev/null || echo "0")
  if [[ "$CURRENT_STEP" -gt 0 ]]; then
    echo "Sprint already in progress (step ${CURRENT_STEP}/7). Skipping init."
    exit 0
  fi
  # current_step == 0 means stale — re-initialize below
fi

# Generate sprint ID and timestamp
SPRINT_ID="sprint-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 12 || true)"
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Create the sprint state file
jq -n \
  --arg sprint_id "$SPRINT_ID" \
  --arg task_id "$TASK_ID" \
  --arg started_at "$TIMESTAMP" \
  '{
    sprint_id: $sprint_id,
    task_id: $task_id,
    current_step: 0,
    started_at: $started_at,
    steps: {
      "1": { name: "devils_advocate", status: "pending", started_at: null, completed_at: null, evidence: null },
      "2": { name: "qa_verification", status: "pending", started_at: null, completed_at: null, evidence: null },
      "3": { name: "cross_model_review", status: "pending", started_at: null, completed_at: null, evidence: null },
      "4": { name: "gap_analysis", status: "pending", started_at: null, completed_at: null, evidence: null,
        required_clean_rounds: 2, clean_rounds_completed: 0, rounds: [] },
      "5": { name: "anti_slop", status: "pending", started_at: null, completed_at: null, evidence: null },
      "6": { name: "commit", status: "pending", started_at: null, completed_at: null, evidence: null },
      "7": { name: "push", status: "pending", started_at: null, completed_at: null, evidence: null }
    }
  }' > "$STATE_FILE"

echo "Sprint initialized: ${STATE_FILE}"
echo "  Sprint ID: ${SPRINT_ID}"
echo "  Task ID: ${TASK_ID:-<none>}"
echo "  Steps: 7 (current_step: 0)"
