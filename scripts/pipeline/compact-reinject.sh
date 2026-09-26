#!/bin/bash
set -e

# Compact Reinject — SessionStart hook that re-injects sprint position after compaction.
# Reads .sprint-state.json and outputs sprint context for Claude Code.

# Check for jq — fail gracefully
if ! command -v jq &>/dev/null; then
  echo "{}"
  exit 0
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "{}"
  exit 0
fi

STATE_FILE="${REPO_ROOT}/.sprint-state.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Auto-create .sprint-state.json if missing (fail-closed enforcement requires it)
if [[ ! -f "$STATE_FILE" ]]; then
  "$SCRIPT_DIR/sprint-init.sh" 2>/dev/null || true
fi

# Auto-create .pipeline-state.json if missing
PIPELINE_FILE="${REPO_ROOT}/.pipeline-state.json"
if [[ ! -f "$PIPELINE_FILE" ]]; then
  "$SCRIPT_DIR/pipeline-init.sh" 2>/dev/null || true
fi

# Auto-install git pre-commit hook if not present
# Respect core.hooksPath if configured (git ignores .git/hooks/ when this is set)
HOOK_DIR="$(git config core.hooksPath 2>/dev/null || echo "${REPO_ROOT}/.git/hooks")"
# Expand ~ if present
HOOK_DIR="${HOOK_DIR/#\~/$HOME}"
HOOK_FILE="${HOOK_DIR}/pre-commit"
if [[ -d "$HOOK_DIR" ]] && { [[ ! -f "$HOOK_FILE" ]] || ! grep -q "pipeline-state.json" "$HOOK_FILE" 2>/dev/null; }; then
  cp "$SCRIPT_DIR/git-pre-commit-hook.sh" "$HOOK_FILE" 2>/dev/null || true
  chmod +x "$HOOK_FILE" 2>/dev/null || true
fi

# If sprint state still doesn't exist after init attempt, output empty context
if [[ ! -f "$STATE_FILE" ]]; then
  echo "{}"
  exit 0
fi

CURRENT_STEP=$(jq -r '.current_step // 0' "$STATE_FILE" 2>/dev/null || echo "0")
SPRINT_ID=$(jq -r '.sprint_id // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_ID=$(jq -r '.task_id // ""' "$STATE_FILE" 2>/dev/null || echo "")

# Sprint complete
if [[ "$CURRENT_STEP" -ge 7 ]]; then
  jq -n '{additionalContext: "Sprint complete. All 7/7 steps done. Run sprint-init.sh to start a new sprint."}'
  exit 0
fi

# Build step status summary
build_status() {
  local output=""
  for i in 1 2 3 4 5 6 7; do
    local name
    name=$(jq -r ".steps.\"${i}\".name // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown")
    local status
    status=$(jq -r ".steps.\"${i}\".status // \"pending\"" "$STATE_FILE" 2>/dev/null || echo "pending")

    local marker="[ ]"
    case "$status" in
      completed) marker="[x]" ;;
      in_progress) marker="[~]" ;;
      pending) marker="[ ]" ;;
    esac

    local extra=""
    if [[ "$i" == "4" ]]; then
      local clean_rounds
      clean_rounds=$(jq -r '.steps."4".clean_rounds_completed // 0' "$STATE_FILE" 2>/dev/null || echo "0")
      local required
      required=$(jq -r '.steps."4".required_clean_rounds // 2' "$STATE_FILE" 2>/dev/null || echo "2")
      extra=" (${clean_rounds}/${required} clean rounds)"
    fi

    output="${output}${marker} Step ${i}: ${name} — ${status}${extra}\n"
  done
  echo -e "$output"
}

STATUS=$(build_status)

# Determine next action
NEXT_STEP=$((CURRENT_STEP + 1))
NEXT_NAME=$(jq -r ".steps.\"${NEXT_STEP}\".name // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown")

INSTRUCTION=""
case "$NEXT_NAME" in
  devils_advocate) INSTRUCTION="Run the devils_advocate gate via pipeline-gate.sh." ;;
  qa_verification) INSTRUCTION="Run QA verification gate." ;;
  cross_model_review) INSTRUCTION="Run cross-model review via codex exec." ;;
  gap_analysis) INSTRUCTION="Run gap_analysis gate. Needs 2 clean rounds (score >= 8)." ;;
  anti_slop) INSTRUCTION="Run anti_slop gate." ;;
  commit) INSTRUCTION="All gates passed. You may now git commit." ;;
  push) INSTRUCTION="Commit complete. You may now git push." ;;
  *) INSTRUCTION="Check sprint state." ;;
esac

TASK_LINE=""
if [[ -n "$TASK_ID" ]]; then
  TASK_LINE=" Task: ${TASK_ID}."
fi

CTX="SPRINT POSITION: ${SPRINT_ID}.${TASK_LINE} Step ${CURRENT_STEP}/7.
${STATUS}Next action: Step ${NEXT_STEP} (${NEXT_NAME}) — ${INSTRUCTION}"

printf '%s' "$CTX" | jq -Rs '{additionalContext: .}'
