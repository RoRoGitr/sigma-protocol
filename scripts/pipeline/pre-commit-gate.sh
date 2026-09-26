#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Skip in Codex cross-model review sessions (read-only, never commits)
if [[ "${CODEX_EXEC:-}" == "1" ]]; then
  echo "{}"
  exit 0
fi

# Check for jq
if ! command -v jq &>/dev/null; then
  printf '{"decision":"deny","reason":"PIPELINE BLOCK: jq is required but not installed. Install with: brew install jq"}'
  exit 0
fi

# Read stdin (hook JSON with tool_input.command)
HOOK_INPUT=$(cat)

# Extract the command from the hook input
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# Check if this is a git commit command
# Match "git commit" but not "git commit --allow-empty"
IS_GIT_COMMIT=false
if echo "$COMMAND" | grep -qE '(^|\s|&&|\|)\s*(rtk\s+)?git\s+commit(\s|$)'; then
  # Check it's not --allow-empty
  if ! echo "$COMMAND" | grep -qE '\-\-allow-empty'; then
    # Block --no-verify attempts
    if echo "$COMMAND" | grep -qE '\-\-no-verify|-n\b'; then
      printf '{"decision":"deny","reason":"PIPELINE BLOCK: --no-verify is prohibited. Pipeline hooks must run."}'
      exit 0
    fi
    IS_GIT_COMMIT=true
  fi
fi

# If not a git commit command, allow it
if [[ "$IS_GIT_COMMIT" != "true" ]]; then
  echo "{}"
  exit 0
fi

# Check for override
if [[ "${SKIP_PIPELINE_CHECK:-}" == "1" ]]; then
  echo "{}"
  exit 0
fi

# ── Tiered gating (tiered-gates 2026-06-10, v2 gate set 2026-07-20) ─────────
# Feature branches get TIER-1 (deterministic gates: the banned-marker-gate hook
# runs separately on every commit). The full v2 4-gate pipeline (mechanical,
# gap_analysis, cross_model_review, greptile_score) runs at WAVE completion,
# gated on the trust boundary = main/master. So: on a feature branch, allow the
# commit WITHOUT pipeline state. On main/master, require the full pipeline
# state (current behavior, unchanged below).
BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo '')"
if [[ -z "$BRANCH" ]]; then
  # Detached HEAD → treat as a feature branch (never main/master).
  BRANCH="(detached)"
fi
if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
  echo "[pre-commit-gate] tier-1 commit on ${BRANCH} — full gates run at wave completion" >&2
  echo "{}"
  exit 0
fi
# ── main/master: TIER-1 BY DEFAULT (ship-mode 2026-06-19) ────────────────────
# Main-only ship-mode means routine work commits straight to main; requiring the
# full LLM pipeline on EVERY main commit would defeat /goal steamrolling.
# So on main/master, allow TIER-1 (the deterministic gates — banned-marker-gate +
# the repo's gitleaks pre-commit hook — run independently) UNLESS this is a
# WAVE/RELEASE commit, which still demands the full v2 4-gate pipeline. Wave detection
# mirrors task-completed-gate.sh's message pattern. Coincidental "wave" in a message
# errs toward MORE gating (safe). Override anytime with SKIP_PIPELINE_CHECK=1.
if ! echo "$COMMAND" | grep -iqE '\bWAVE\b|\bwave[- ]complete\b|\bplan[- ]complete\b|\brelease[- ]complete\b'; then
  echo "[pre-commit-gate] tier-1 commit on ${BRANCH} (ship-mode) — deterministic gates enforced; full v2 4-gate runs on WAVE/RELEASE commits" >&2
  echo "{}"
  exit 0
fi
echo "[pre-commit-gate] WAVE/RELEASE commit on ${BRANCH} — enforcing full v2 4-gate pipeline" >&2
# WAVE/RELEASE commit on main/master → full pipeline check below.

# Run pipeline-check.sh and capture the result
"$SCRIPT_DIR/sync-worktree-state.sh" >/dev/null 2>&1 || true
CHECK_OUTPUT=$("$SCRIPT_DIR/pipeline-check.sh" 2>&1) && CHECK_EXIT=0 || CHECK_EXIT=$?

# If check passed, allow commit
if [[ "$CHECK_EXIT" -eq 0 ]]; then
  echo "{}"
  exit 0
fi

# Check failed — build the deny response with gate details
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "{}"
  exit 0
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

# Build missing gates list
MISSING_LINES=""
HAS_FRONTEND="false"

# GLOBAL FIX: Check git staged files directly for frontend changes.
# This catches subagent edits that bypass PostToolUse hooks.
# The pipeline-state.json flag is a supplement, not the source of truth.
if git diff --cached --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
  HAS_FRONTEND="true"
elif git diff --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
  HAS_FRONTEND="true"
fi

if [[ -f "$CHECKPOINT_FILE" ]]; then
  # Also check pipeline-state.json (belt + suspenders)
  PIPELINE_FRONTEND=$(jq -r '.has_frontend_changes' "$CHECKPOINT_FILE" 2>/dev/null || echo "false")
  if [[ "$PIPELINE_FRONTEND" == "true" ]]; then
    HAS_FRONTEND="true"
  fi

  # Update pipeline-state.json if we detected frontend from git but it wasn't flagged
  if [[ "$HAS_FRONTEND" == "true" ]] && [[ "$PIPELINE_FRONTEND" != "true" ]]; then
    jq '.has_frontend_changes = true' "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp" && mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE" 2>/dev/null || true
  fi

  MECH=$(jq -r '.gates.mechanical.status // "NOT RUN"' "$CHECKPOINT_FILE")
  if [[ "$MECH" != "passed" ]]; then
    MISSING_LINES="${MISSING_LINES}\n- mechanical: ${MECH} (run scripts/pipeline/mechanical-gate.sh)"
  fi

  GA=$(jq -r '.gates.gap_analysis.status // "NOT RUN"' "$CHECKPOINT_FILE")
  GA_SCORE=$(jq -r '.gates.gap_analysis.score // 0' "$CHECKPOINT_FILE")
  GA_ROUND=$(jq -r '.gates.gap_analysis.round // 0' "$CHECKPOINT_FILE")
  if [[ "$GA" != "completed" ]] \
     || ! jq -e '((.gates.gap_analysis.score // 0) >= 8) and ((.gates.gap_analysis.round // 0) >= 2)' "$CHECKPOINT_FILE" >/dev/null 2>&1; then
    MISSING_LINES="${MISSING_LINES}\n- gap_analysis: ${GA} score=${GA_SCORE} round=${GA_ROUND} (needs completed + score>=8 + 2 clean rounds)"
  elif [[ "$HAS_FRONTEND" == "true" ]] \
       && ! jq -e '.gates.gap_analysis.ui_validated == true' "$CHECKPOINT_FILE" >/dev/null 2>&1; then
    MISSING_LINES="${MISSING_LINES}\n- gap_analysis: missing ui-validated stamp (frontend changes detected)"
  fi

  CMR=$(jq -r '.gates.cross_model_review.status // "NOT RUN"' "$CHECKPOINT_FILE")
  if [[ "$CMR" != "completed" ]]; then
    MISSING_LINES="${MISSING_LINES}\n- cross_model_review: ${CMR}"
  fi

  GREP=$(jq -r '.gates.greptile_score.status // "NOT RUN"' "$CHECKPOINT_FILE")
  if [[ "$GREP" != "skipped" ]] \
     && ! { [[ "$GREP" == "completed" ]] && jq -e '(.gates.greptile_score.score // 0) >= 4' "$CHECKPOINT_FILE" >/dev/null 2>&1; }; then
    MISSING_LINES="${MISSING_LINES}\n- greptile_score: ${GREP} (needs completed score>=4, or skipped pre-PR)"
  fi
else
  MISSING_LINES="\n- mechanical: NOT RUN\n- gap_analysis: NOT RUN\n- cross_model_review: NOT RUN\n- greptile_score: NOT RUN"
fi

REASON="PIPELINE GATE BLOCKED: Cannot commit without completing required gates.\n\nMissing gates:${MISSING_LINES}\n\nRun these agents before committing."

printf '%s' "$REASON" | jq -Rs '{decision: "deny", reason: .}'
