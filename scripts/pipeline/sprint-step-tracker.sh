#!/bin/bash
set -e

# Sprint Step Tracker — PostToolUse hook that detects completion signals and advances sprint state.
# Reads hook JSON from stdin with tool_name, tool_input, tool_result fields.

# Drain stdin upfront so any early exit below cannot strand the hook runner
# with "failed to write hook stdin: Broken pipe (os error 32)".
HOOK_INPUT=""
if [[ ! -t 0 ]]; then
  HOOK_INPUT=$(cat 2>/dev/null || true)
fi

# Skip in Codex cross-model review sessions (read-only, never commits)
if [[ "${CODEX_EXEC:-}" == "1" ]]; then
  echo "{}"
  exit 0
fi

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

# No sprint state — no-op
if [[ ! -f "$STATE_FILE" ]]; then
  echo "{}"
  exit 0
fi

# HOOK_INPUT was drained at script start; fall through with whatever we captured.

# Extract fields
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
TOOL_RESULT=$(echo "$HOOK_INPUT" | jq -r '.tool_result // ""' 2>/dev/null || echo "")
EXIT_CODE=$(echo "$HOOK_INPUT" | jq -r '.tool_result_exit_code // ""' 2>/dev/null || echo "")
COMBINED="${COMMAND} ${TOOL_RESULT}"

TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Read current step
CURRENT_STEP=$(jq -r '.current_step // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# Helper: advance a step
advance_step() {
  local step_num="$1"
  local evidence="$2"

  # Update the step to completed
  jq \
    --arg ts "$TIMESTAMP" \
    --arg ev "$evidence" \
    --argjson step "$step_num" \
    '.steps[($step | tostring)].status = "completed" |
     .steps[($step | tostring)].completed_at = $ts |
     .steps[($step | tostring)].evidence = $ev |
     .current_step = $step' \
    "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  # Build response with next step info
  local next=$((step_num + 1))
  local step_name
  step_name=$(jq -r ".steps.\"${step_num}\".name // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown")

  if [[ "$next" -le 7 ]]; then
    local next_name
    next_name=$(jq -r ".steps.\"${next}\".name // \"done\"" "$STATE_FILE" 2>/dev/null || echo "done")

    local instruction=""
    case "$next_name" in
      devils_advocate) instruction="Run the devils_advocate gate via pipeline-gate.sh." ;;
      qa_verification) instruction="Run QA verification gate." ;;
      cross_model_review) instruction="Run cross-model review via codex exec." ;;
      gap_analysis) instruction="Run gap_analysis gate. Needs 2 clean rounds (score >= 8)." ;;
      anti_slop) instruction="Run anti_slop gate." ;;
      commit) instruction="All gates passed. You may now git commit." ;;
      push) instruction="Commit complete. You may now git push." ;;
      *) instruction="Sprint complete." ;;
    esac

    jq -n --arg ctx "SPRINT PROGRESS: Step ${step_num}/7 (${step_name}) complete. NEXT: Step ${next} (${next_name}). ${instruction}" \
      '{additionalContext: $ctx}'
  else
    jq -n '{additionalContext: "SPRINT COMPLETE: All 7/7 steps done. Ready for next sprint."}'
  fi
  exit 0
}

# Detection: Step 1 — devils_advocate
if echo "$COMBINED" | grep -qE "Gate 'devils_advocate' recorded|pipeline-gate\.sh.*devils_advocate"; then
  if [[ "$CURRENT_STEP" -lt 1 ]]; then
    advance_step 1 "devils_advocate gate passed"
  fi
fi

# Detection: Step 2 — qa_verification
if echo "$COMBINED" | grep -qE "Gate 'qa_verification' recorded|pipeline-gate\.sh.*qa_verification"; then
  if [[ "$CURRENT_STEP" -lt 2 ]]; then
    advance_step 2 "qa_verification gate passed"
  fi
fi

# Detection: Step 3 — cross_model_review (codex completed successfully)
if echo "$COMMAND" | grep -qE '^\s*codex\s+exec(\s|$)'; then
  if [[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]] && [[ -n "$TOOL_RESULT" ]]; then
    if [[ "$CURRENT_STEP" -lt 3 ]]; then
      advance_step 3 "cross-model review via codex exec"
    fi
  fi
fi

# Detection: Step 4 — gap_analysis (needs 2 clean rounds with score >= 8)
if echo "$COMBINED" | grep -qE "Gate 'gap_analysis' recorded"; then
  # Try to parse score from output
  SCORE=$(echo "$TOOL_RESULT" | grep -oE 'score[=: ]*([0-9]+(\.[0-9]+)?)' | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "")

  if [[ -n "$SCORE" ]]; then
    # Record the round
    ROUND_NUM=$(jq -r '.steps."4".rounds | length' "$STATE_FILE" 2>/dev/null || echo "0")
    ROUND_NUM=$((ROUND_NUM + 1))

    # Check if score >= 8
    IS_CLEAN=$(echo "$SCORE >= 8" | bc -l 2>/dev/null || echo "0")

    if [[ "$IS_CLEAN" == "1" ]]; then
      jq \
        --arg ts "$TIMESTAMP" \
        --argjson score "$SCORE" \
        --argjson round "$ROUND_NUM" \
        '.steps."4".rounds += [{ round_number: $round, score: $score, timestamp: $ts }] |
         .steps."4".clean_rounds_completed += 1' \
        "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    else
      jq \
        --arg ts "$TIMESTAMP" \
        --argjson score "$SCORE" \
        --argjson round "$ROUND_NUM" \
        '.steps."4".rounds += [{ round_number: $round, score: $score, timestamp: $ts }]' \
        "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi

    # Check if we now have enough clean rounds
    CLEAN_ROUNDS=$(jq -r '.steps."4".clean_rounds_completed // 0' "$STATE_FILE" 2>/dev/null || echo "0")
    REQUIRED=$(jq -r '.steps."4".required_clean_rounds // 2' "$STATE_FILE" 2>/dev/null || echo "2")

    if [[ "$CLEAN_ROUNDS" -ge "$REQUIRED" ]] && [[ "$CURRENT_STEP" -lt 4 ]]; then
      advance_step 4 "gap_analysis: ${CLEAN_ROUNDS} clean rounds (scores >= 8)"
    else
      REMAINING=$((REQUIRED - CLEAN_ROUNDS))
      jq -n --arg ctx "SPRINT: gap_analysis round ${ROUND_NUM} (score: ${SCORE}). Clean rounds: ${CLEAN_ROUNDS}/${REQUIRED}. Need ${REMAINING} more clean round(s)." \
        '{additionalContext: $ctx}'
      exit 0
    fi
  fi
fi

# Detection: Step 5 — anti_slop
if echo "$COMBINED" | grep -qE "Gate 'anti_slop' recorded.*status=passed|Gate 'anti_slop' recorded: status=passed"; then
  if [[ "$CURRENT_STEP" -lt 5 ]]; then
    advance_step 5 "anti_slop gate passed"
  fi
fi

# Detection: Step 6 — git commit succeeded
if echo "$COMMAND" | grep -qE '^\s*(rtk\s+)?git\s+commit(\s|$)'; then
  if ! echo "$COMMAND" | grep -qE '\-\-allow-empty'; then
    if echo "$TOOL_RESULT" | grep -qE '\b[0-9a-f]{7,40}\b.*\b(file|insertion|deletion|changed)'; then
      if [[ "$CURRENT_STEP" -lt 6 ]]; then
        COMMIT_HASH=$(echo "$TOOL_RESULT" | grep -oE '\b[0-9a-f]{7,40}\b' | head -1 || echo "unknown")
        advance_step 6 "commit: ${COMMIT_HASH}"
      fi
    fi
  fi
fi

# Detection: Step 7 — git push succeeded
if echo "$COMMAND" | grep -qE '^\s*(rtk\s+)?git\s+push(\s|$)'; then
  if [[ "$EXIT_CODE" == "0" || -z "$EXIT_CODE" ]]; then
    if echo "$TOOL_RESULT" | grep -qiE 'To (https?://|git@)|->|Everything up-to-date'; then
      if [[ "$CURRENT_STEP" -lt 7 ]]; then
        # Archive current sprint to history
        HISTORY_FILE="${REPO_ROOT}/.sprint-history.jsonl"
        cat "$STATE_FILE" >> "$HISTORY_FILE"
        echo "" >> "$HISTORY_FILE"

        # Detect workspace for kanban
        WORKSPACE="${KANBAN_WORKSPACE:-}"
        if [[ -z "$WORKSPACE" ]]; then
          # Try to detect from commandboard
          DIRNAME="$(basename "$REPO_ROOT")"
          for dir in ~/.commandboard/workspaces/*/*/; do
            if [[ "$(basename "$dir")" == "$DIRNAME" ]] || [[ "$(basename "$dir")" == "$(echo "$DIRNAME" | tr '[:upper:]' '[:lower:]')" ]]; then
              WORKSPACE="$dir"
              break
            fi
          done
        fi

        # Try to pick next task from kanban
        NEXT_TASK=""
        NEXT_TITLE=""
        if [[ -n "$WORKSPACE" ]] && command -v kanban-md &>/dev/null; then
          PICK_OUTPUT=$(kanban-md pick --dir "$WORKSPACE" 2>/dev/null || echo "")
          if [[ -n "$PICK_OUTPUT" ]]; then
            NEXT_TASK=$(echo "$PICK_OUTPUT" | grep -oE '#[0-9]+' | head -1 | tr -d '#' || echo "")
            NEXT_TITLE=$(echo "$PICK_OUTPUT" | sed 's/#[0-9]* *//' | head -1 || echo "")
          fi
        fi

        if [[ -n "$NEXT_TASK" ]]; then
          # Initialize next sprint
          SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
          if [[ -x "${SCRIPT_DIR}/sprint-init.sh" ]]; then
            "${SCRIPT_DIR}/sprint-init.sh" --task-id "$NEXT_TASK" 2>/dev/null || true
          fi

          # Update step 7 and output chaining context
          jq \
            --arg ts "$TIMESTAMP" \
            --arg ev "pushed to remote" \
            '.steps."7".status = "completed" |
             .steps."7".completed_at = $ts |
             .steps."7".evidence = $ev |
             .current_step = 7' \
            "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

          jq -n --arg ctx "Sprint complete. Archived to .sprint-history.jsonl. Next task: #${NEXT_TASK} — ${NEXT_TITLE}. New sprint initialized." \
            '{additionalContext: $ctx}'
          exit 0
        else
          # No next task — just complete step 7
          jq \
            --arg ts "$TIMESTAMP" \
            --arg ev "pushed to remote" \
            '.steps."7".status = "completed" |
             .steps."7".completed_at = $ts |
             .steps."7".evidence = $ev |
             .current_step = 7' \
            "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

          jq -n '{additionalContext: "Sprint complete. No more tasks in kanban. Run `kanban-md list` to check."}'
          exit 0
        fi
      fi
    fi
  fi
fi

# No match — pass through
echo "{}"
