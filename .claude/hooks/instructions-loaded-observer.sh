#!/usr/bin/env bash
# =============================================================================
# Instructions Loaded Observer — InstructionsLoaded
# =============================================================================
# Event:    InstructionsLoaded
# Trigger:  Fires after Claude Code loads and resolves all instruction sources
#           for the current task. This includes CLAUDE.md, .claude/rules/*.md,
#           managed instructions, and any dynamically resolved instructions.
#
# When it fires:
#   At the start of each task (not each turn), after Claude Code has
#   assembled the full instruction set. It reports which instruction
#   sources were loaded and their resolved priority order.
#
# Available environment variables:
#   CLAUDE_PROJECT_DIR          — root of the project
#   CLAUDE_SESSION_ID           — current session identifier
#   CLAUDE_HOOK_EVENT_NAME      — "InstructionsLoaded"
#   CLAUDE_INSTRUCTIONS_LOADED  — JSON array of loaded instruction sources
#                                  with paths, sizes, and precedence levels
#   CLAUDE_AGENT_ID             — agent that is receiving the instructions
#   CLAUDE_AGENT_TYPE           — "lead" | "teammate" | "subagent"
#   CLAUDE_PERMISSION_MODE      — "default" | "plan" | "autoApprove"
#
# Exit codes:
#   0  — success (proceed normally)
#   1  — block (abort the task — use sparingly)
#   2+ — ignored (hook treated as not present)
#
# Use cases:
#   - Audit trail: log which rules fired for each task/agent
#   - Compliance: verify mandatory rules are always loaded
#   - Debugging: diagnose why an agent is not following expected rules
#   - Metrics: track instruction set size and complexity over time
#   - Security: detect unexpected instruction sources (prompt injection)
#
# To activate, add to settings.json under "hooks":
#   "InstructionsLoaded": [{
#     "hooks": [{
#       "type": "command",
#       "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/instructions-loaded-observer.sh\""
#     }]
#   }]
# =============================================================================

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
AGENT_ID="${CLAUDE_AGENT_ID:-lead}"
AGENT_TYPE="${CLAUDE_AGENT_TYPE:-lead}"
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
INSTRUCTIONS="${CLAUDE_INSTRUCTIONS_LOADED:-[]}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Audit log directory
AUDIT_DIR="$PROJECT_DIR/.sigma/audit"
LOG_FILE="$AUDIT_DIR/instructions-loaded.log"

# ─────────────────────────────────────────────────────────────────────────────
# Log instruction loading event
# ─────────────────────────────────────────────────────────────────────────────
if [[ -d "$(dirname "$AUDIT_DIR")" ]]; then
    mkdir -p "$AUDIT_DIR"

    # Human-readable log
    printf '[%s] agent=%s type=%s session=%s\n' \
        "$TIMESTAMP" \
        "$AGENT_ID" \
        "$AGENT_TYPE" \
        "$SESSION_ID" >> "$LOG_FILE"

    # TODO: Machine-readable JSONL for downstream analysis
    # Uncomment when CLAUDE_INSTRUCTIONS_LOADED payload is available:
    # JSONL_FILE="$AUDIT_DIR/instructions-loaded.jsonl"
    # printf '{"timestamp":"%s","agent_id":"%s","agent_type":"%s","session_id":"%s","instructions":%s}\n' \
    #     "$TIMESTAMP" \
    #     "$AGENT_ID" \
    #     "$AGENT_TYPE" \
    #     "$SESSION_ID" \
    #     "$INSTRUCTIONS" >> "$JSONL_FILE"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Verify mandatory rules are loaded
# ─────────────────────────────────────────────────────────────────────────────

# TODO: Check that critical rule files are present in the loaded set
# Example:
#   REQUIRED_RULES=(
#       "swarm-orchestration.md"
#       "commands-reference.md"
#       "workflow.md"
#   )
#
#   for rule in "${REQUIRED_RULES[@]}"; do
#       if ! echo "$INSTRUCTIONS" | grep -q "$rule"; then
#           echo "WARNING: Required rule '$rule' was not loaded for agent $AGENT_ID" >&2
#       fi
#   done

# ─────────────────────────────────────────────────────────────────────────────
# Detect unexpected instruction sources
# ─────────────────────────────────────────────────────────────────────────────

# TODO: Flag instructions from outside the project directory
# Example:
#   EXTERNAL=$(echo "$INSTRUCTIONS" | jq -r '.[] | select(.path | startswith("'"$PROJECT_DIR"'") | not) | .path' 2>/dev/null)
#   if [[ -n "$EXTERNAL" ]]; then
#       echo "NOTICE: External instructions loaded:" >&2
#       echo "$EXTERNAL" >&2
#   fi

# ─────────────────────────────────────────────────────────────────────────────
# Track instruction set size (useful for context budget monitoring)
# ─────────────────────────────────────────────────────────────────────────────

# TODO: Warn if instruction set is unusually large
# Example:
#   TOTAL_SIZE=$(echo "$INSTRUCTIONS" | jq '[.[].size // 0] | add' 2>/dev/null || echo 0)
#   if [[ "$TOTAL_SIZE" -gt 50000 ]]; then
#       echo "WARNING: Instruction set is ${TOTAL_SIZE} bytes. Consider pruning rules to save context." >&2
#   fi

# ─────────────────────────────────────────────────────────────────────────────
# Agent-specific rule verification
# ─────────────────────────────────────────────────────────────────────────────

# TODO: Verify agent-specific rules are loaded for the correct agent type
# Example:
#   if [[ "$AGENT_TYPE" == "teammate" ]]; then
#       # Teammates should always have the swarm orchestration rules
#       if ! echo "$INSTRUCTIONS" | grep -q "swarm-orchestration"; then
#           echo "WARNING: Teammate $AGENT_ID is missing swarm-orchestration rules" >&2
#       fi
#   fi

exit 0
