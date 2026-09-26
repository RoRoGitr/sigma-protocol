#!/bin/bash
set -e

# Sprint Step Guard — PreToolUse hook that blocks out-of-order sprint operations.
# Reads hook JSON from stdin: {"tool_name": "Bash", "tool_input": {"command": "git commit ..."}}

# Override escape hatch
if [[ "${SKIP_SPRINT_GUARD:-}" == "1" ]]; then
  echo "{}"
  exit 0
fi

# Skip in Codex cross-model review sessions (read-only, never commits)
if [[ "${CODEX_EXEC:-}" == "1" ]]; then
  echo "{}"
  exit 0
fi

# Check for jq — fail gracefully
if ! command -v jq &>/dev/null; then
  printf '{"decision":"deny","reason":"SPRINT GUARD: jq is required but not installed."}'
  exit 0
fi

# Read stdin
HOOK_INPUT=$(cat)

# Extract command
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# If no command, pass through
if [[ -z "$COMMAND" ]]; then
  echo "{}"
  exit 0
fi

# Fast-path for read-only commands — sprint guard should not delay queries.
# Matches the command's FIRST token against a whitelist. Ignores leading
# pipeline wrappers (cd ... &&, env X=1 ...) by trimming common prefixes.
TRIMMED=$(echo "$COMMAND" | sed -E 's|^cd [^;&]+[;&]+[[:space:]]*||; s|^env [^ ]+[[:space:]]+||' | awk '{print $1}')
case "$TRIMMED" in
  ls|cat|head|tail|less|more|grep|rg|fd|find|wc|sort|uniq|awk|sed|cut|tr|echo|printf|which|whereis|type|stat|file|tree|bat|du|df|ps|top|htop|uptime|date|pwd|env|printenv|jq|yq|xmllint)
    echo "{}"
    exit 0
    ;;
  git)
    # git log/status/diff/show/branch/remote/stash list — all read-only
    SECOND=$(echo "$COMMAND" | awk '{print $2}')
    case "$SECOND" in
      log|status|diff|show|branch|remote|stash|blame|ls-files|ls-tree|rev-parse|describe|config|reflog|tag)
        echo "{}"
        exit 0
        ;;
    esac
    ;;
esac

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "{}"
  exit 0
fi

STATE_FILE="${REPO_ROOT}/.sprint-state.json"

# No sprint initialized != sprint violated — fail open. Step checks below still apply.
[[ -f "$STATE_FILE" ]] || exit 0

# Read current state
CURRENT_STEP=$(jq -r '.current_step // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# Helper: get step name by number
step_name() {
  jq -r ".steps.\"$1\".name // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown"
}

# Helper: build deny response
deny() {
  local action="$1"
  local required_step="$2"
  local required_name
  required_name=$(step_name "$required_step")
  local current_name
  current_name=$(step_name "$CURRENT_STEP")

  local reason="SPRINT GUARD: Cannot ${action} — step ${required_step} (${required_name}) not complete. Current step: ${CURRENT_STEP}/7 (${current_name}). Complete ${required_name} first."

  printf '%s' "$reason" | jq -Rs '{decision: "deny", reason: .}'
  exit 0
}

# Pattern: git commit (not --allow-empty)
if echo "$COMMAND" | grep -qE '(^|\s|&&|\|)\s*(rtk\s+)?git\s+commit(\s|$)'; then
  if ! echo "$COMMAND" | grep -qE '\-\-allow-empty'; then
    # Requires: current_step >= 5 AND gap_analysis clean_rounds >= 2
    GAP_ROUNDS=$(jq -r '.steps."4".clean_rounds_completed // 0' "$STATE_FILE" 2>/dev/null || echo "0")

    if [[ "$CURRENT_STEP" -lt 5 ]]; then
      BLOCKING_STEP=$((CURRENT_STEP + 1))
      if [[ "$BLOCKING_STEP" -gt 5 ]]; then
        BLOCKING_STEP=5
      fi
      deny "git commit" "$BLOCKING_STEP"
    fi

    if [[ "$GAP_ROUNDS" -lt 2 ]]; then
      deny "git commit (gap_analysis needs ${GAP_ROUNDS}/2 clean rounds)" "4"
    fi
  fi
fi

# Pattern: codex (cross-model review)
if echo "$COMMAND" | grep -qE '(^|\s|&&|\|)\s*codex\s+exec(\s|$)'; then
  if [[ "$CURRENT_STEP" -lt 2 ]]; then
    deny "codex exec (cross-model review)" "3"
  fi
fi

# Pattern: git push
if echo "$COMMAND" | grep -qE '(^|\s|&&|\|)\s*(rtk\s+)?git\s+push(\s|$)'; then
  if [[ "$CURRENT_STEP" -lt 6 ]]; then
    deny "git push" "6"
  fi
fi

# No match — pass through
echo "{}"
