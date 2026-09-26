#!/bin/bash
# Git pre-commit hook — enforces pipeline gates for repos that use the pipeline
# Global install: core.hooksPath=~/.githooks (affects all repos)
# Per-repo install: cp this to .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
# Repos without .pipeline-state.json are not affected (opt-in enforcement)

REPO_ROOT="$(git rev-parse --show-toplevel)"
STATE_FILE="${REPO_ROOT}/.pipeline-state.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIPELINE_SCRIPT_DIR="${PIPELINE_SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# Allow override for non-pipeline commits (docs, configs)
if [[ "${SKIP_PIPELINE_CHECK:-}" == "1" ]]; then
  exit 0
fi

# Opt-in enforcement: only block repos that use the pipeline
# (Claude-level hooks handle fail-closed enforcement for missing state files)
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Banned-marker gate (execution doctrine) — block unfinished-work markers in staged CODE.
# Override: SKIP_MARKER_GATE=1 (disclose the stub under "STUBS SHIPPED:").
if [[ -x "$HOME/.local/bin/banned-marker-gate.sh" ]]; then
  "$HOME/.local/bin/banned-marker-gate.sh" || exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "COMMIT BLOCKED: jq not installed."
  exit 1
fi

"${PIPELINE_SCRIPT_DIR}/sync-worktree-state.sh" >/dev/null 2>&1 || true

# ── TIER-1 BY DEFAULT (ship-mode 2026-06-19, v2 gate set 2026-07-20) ─────────
# Full v2 4-gate commit_allowed check fires ONLY for explicit WAVE/RELEASE commits
# (PIPELINE_ENFORCE=1). Routine ship-mode commits flow on tier-1; deterministic gates
# (banned-marker) already ran above. A git pre-commit hook can't see the commit message,
# so WAVE detection lives in the message-aware Claude PreToolUse pre-commit-gate.sh.
if [[ "${PIPELINE_ENFORCE:-}" != "1" ]]; then
  echo "[pre-commit] tier-1 (ship-mode) — deterministic gates passed; set PIPELINE_ENFORCE=1 for the full v2 4-gate"
  exit 0
fi

COMMIT_ALLOWED=$(jq -r '.commit_allowed // false' "$STATE_FILE")
if [[ "$COMMIT_ALLOWED" != "true" ]]; then
  echo "COMMIT BLOCKED: Pipeline gates incomplete (v2: mechanical, gap_analysis, cross_model_review, greptile_score)."
  for gate in mechanical gap_analysis cross_model_review greptile_score; do
    STATUS=$(jq -r ".gates.${gate}.status // \"NOT_RUN\"" "$STATE_FILE")
    echo "  ${gate}: ${STATUS}"
  done
  echo ""
  echo "Complete all gates, then retry commit."
  exit 1
fi

echo "Pipeline gates: ALL PASSED"
