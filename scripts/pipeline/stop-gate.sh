#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "{}"
  exit 0
fi

# Read stdin (Stop hook input)
HOOK_INPUT=$(cat 2>/dev/null || true)

# Skip if we're in a stop-hook continuation loop
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  echo "{}"
  exit 0
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "{}"
  exit 0
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

# If no checkpoint exists, nothing to check
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  echo "{}"
  exit 0
fi

# If commit is already allowed, no warning needed
COMMIT_ALLOWED=$(jq -r '.commit_allowed' "$CHECKPOINT_FILE" 2>/dev/null || echo "false")
if [[ "$COMMIT_ALLOWED" == "true" ]]; then
  echo "{}"
  exit 0
fi

# Loop prevention: check if we already warned this session
SESSION_ID=$(jq -r '.session_id // ""' "$CHECKPOINT_FILE" 2>/dev/null || echo "")
WARN_MARKER="/tmp/pipeline-stop-warned-${SESSION_ID}"

if [[ -n "$SESSION_ID" ]] && [[ -f "$WARN_MARKER" ]]; then
  echo "{}"
  exit 0
fi

# Create the warn marker
if [[ -n "$SESSION_ID" ]]; then
  touch "$WARN_MARKER"
fi

# Build the gate status summary
HAS_FRONTEND=$(jq -r '.has_frontend_changes' "$CHECKPOINT_FILE" 2>/dev/null || echo "false")
STATUS_LINES=""

ANTI_SLOP=$(jq -r '.gates.anti_slop.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- anti_slop: ${ANTI_SLOP}"

if [[ "$HAS_FRONTEND" == "true" ]]; then
  UI_VAL=$(jq -r '.gates.ui_validation.status // "NOT RUN"' "$CHECKPOINT_FILE")
  STATUS_LINES="${STATUS_LINES}\n- ui_validation: ${UI_VAL}"
fi

DA=$(jq -r '.gates.devils_advocate.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- devils_advocate: ${DA}"

GA=$(jq -r '.gates.gap_analysis.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- gap_analysis: ${GA}"

QA=$(jq -r '.gates.qa_verification.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- qa_verification: ${QA}"

CMR=$(jq -r '.gates.cross_model_review.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- cross_model_review: ${CMR}"

GREP=$(jq -r '.gates.greptile_score.status // "NOT RUN"' "$CHECKPOINT_FILE")
STATUS_LINES="${STATUS_LINES}\n- greptile_score: ${GREP}"

WARNING="WARNING: You have uncommitted code changes with incomplete pipeline gates. Gates status:${STATUS_LINES}\n\nConsider running the required gates before ending this session."

printf '%s' "$WARNING" | jq -Rs '{additionalContext: .}'
