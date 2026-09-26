#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

# Detect repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  # Not in a git repo — allow commit (no pipeline enforcement outside repos)
  exit 0
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"

# ── Tiered gating (sprint-protocol.md: Tier-1 vs Tier-2) ────────────────────
# Feature branches (anything that isn't main/master, including detached HEAD)
# get TIER-1: a deterministic banned-marker check on the staged diff. No
# .pipeline-state.json is read or required — this runs BEFORE the checkpoint
# file is touched or sync-worktree-state.sh is invoked, so a feature-branch
# commit never triggers silent state-file recreation and is never blocked by
# another branch's (or another worktree's) stale/foreign gate state.
# main/master keeps the fail-closed full-pipeline behavior below (the
# main-branch tier-1 ship-mode decision lives in pre-commit-gate.sh /
# git-pre-commit-hook.sh, which see the commit message; this script is the
# full-pipeline arbiter they call for WAVE/RELEASE commits).
# symbolic-ref (not rev-parse) so an unborn branch (repo with zero commits
# yet, e.g. a brand-new "main") still resolves correctly instead of failing.
BRANCH="$(git symbolic-ref --short -q HEAD 2>/dev/null || echo '')"
if [[ -z "$BRANCH" ]]; then
  # Detached HEAD → treat as a feature branch (never main/master).
  BRANCH="(detached)"
fi

if [[ "$BRANCH" != "main" && "$BRANCH" != "master" ]]; then
  BANNED_MARKER_PATTERN='TODO|FIXME|XXX|NotImplementedError|NotImplemented\b'  # stub-ok (pattern definition, not a stub)
  # Only scan ADDED lines (git diff `+` prefix) in the staged diff — a
  # pre-existing banned marker elsewhere in the file must not block an
  # unrelated commit.
  BANNED_HITS="$(git diff --cached -U0 -- . 2>/dev/null \
    | grep -E '^\+[^+]' \
    | grep -vE '^\+\+\+ ' \
    | grep -E "$BANNED_MARKER_PATTERN" || true)"

  if [[ -n "$BANNED_HITS" ]]; then
    echo "PIPELINE BLOCK (tier-1, branch=${BRANCH}): banned marker found in staged diff." >&2
    echo "" >&2
    echo "$BANNED_HITS" >&2
    echo "" >&2
    echo "Remove the marker (or ship it deliberately and list it under STUBS SHIPPED: in the PR/commit body) before committing." >&2
    exit 2
  fi

  echo "[pipeline-check] tier-1 commit on ${BRANCH} — banned-marker check clean, no .pipeline-state.json required (full gates run at wave completion)."
  exit 0
fi

# ── main/master: fail-closed, full v2 pipeline required ─────────────────────

# Fail-closed: no checkpoint = no commit allowed
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  echo "PIPELINE BLOCK: No .pipeline-state.json found. Run: pipeline-init.sh" >&2
  exit 2
fi

"$SCRIPT_DIR/sync-worktree-state.sh" >/dev/null 2>&1 || true

COMMIT_ALLOWED=$(jq -r '.commit_allowed' "$CHECKPOINT_FILE")

if [[ "$COMMIT_ALLOWED" == "true" ]]; then
  # Even with commit_allowed, verify the UI-validated fold if frontend files
  # are present. Catches commit_allowed set before frontend edits were added.
  # (v2: UI validation is folded into gap_analysis as the ui_validated stamp.)
  if git diff --cached --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$' || \
     git diff --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
    UI_VALIDATED=$(jq -r '.gates.gap_analysis.ui_validated // false' "$CHECKPOINT_FILE")
    if [[ "$UI_VALIDATED" != "true" ]]; then
      echo "PIPELINE BLOCK: commit_allowed is true but frontend files detected without the ui-validated gap_analysis stamp." >&2
      echo "  Re-run gap analysis with UI validation: pipeline-gate.sh gap_analysis completed <score> <round> ui-validated" >&2
      exit 2
    fi
  fi
  echo "All pipeline gates passed. Commit allowed."
  exit 0
fi

CURRENT_COUNTER=$(jq -r '.change_counter // 0' "$CHECKPOINT_FILE")

# Build a list of missing/failed gates
# GLOBAL FIX: Check git staged + unstaged files directly for frontend changes.
# Subagent edits bypass PostToolUse hooks, so pipeline-state.json may not reflect reality.
# Git diff is the source of truth for what's actually changed.
HAS_FRONTEND="false"
if git diff --cached --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
  HAS_FRONTEND="true"
elif git diff --name-only 2>/dev/null | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
  HAS_FRONTEND="true"
fi
# Also respect pipeline-state.json flag (belt + suspenders)
PIPELINE_FRONTEND=$(jq -r '.has_frontend_changes' "$CHECKPOINT_FILE")
if [[ "$PIPELINE_FRONTEND" == "true" ]]; then
  HAS_FRONTEND="true"
fi
# Sync: if git detected frontend but pipeline-state didn't, fix it
if [[ "$HAS_FRONTEND" == "true" ]] && [[ "$PIPELINE_FRONTEND" != "true" ]]; then
  jq '.has_frontend_changes = true' "$CHECKPOINT_FILE" > "${CHECKPOINT_FILE}.tmp" && mv "${CHECKPOINT_FILE}.tmp" "$CHECKPOINT_FILE" 2>/dev/null || true
fi

MISSING=()

# v2 gate 1: mechanical (auto, no LLM)
MECH_STATUS=$(jq -r '.gates.mechanical.status // "NOT RUN"' "$CHECKPOINT_FILE")
MECH_COUNTER=$(jq -r '.gates.mechanical.change_counter // -1' "$CHECKPOINT_FILE")
if [[ "$MECH_STATUS" != "passed" ]] || [[ "$MECH_COUNTER" != "$CURRENT_COUNTER" ]]; then
  MISSING+=("BLOCKED: mechanical gate ${MECH_STATUS}. Run: scripts/pipeline/mechanical-gate.sh")
fi

# v2 gate 2: gap_analysis — the veto. score>=8, round>=2, ui-validated when frontend.
GA_STATUS=$(jq -r '.gates.gap_analysis.status // "NOT RUN"' "$CHECKPOINT_FILE")
GA_SCORE=$(jq -r '.gates.gap_analysis.score // 0' "$CHECKPOINT_FILE")
GA_ROUND=$(jq -r '.gates.gap_analysis.round // 0' "$CHECKPOINT_FILE")
GA_COUNTER=$(jq -r '.gates.gap_analysis.change_counter // -1' "$CHECKPOINT_FILE")
if [[ "$GA_STATUS" != "completed" ]] || [[ "$GA_COUNTER" != "$CURRENT_COUNTER" ]] \
   || ! jq -e '((.gates.gap_analysis.score // 0) >= 8) and ((.gates.gap_analysis.round // 0) >= 2)' "$CHECKPOINT_FILE" >/dev/null; then
  MISSING+=("BLOCKED: gap_analysis gate ${GA_STATUS} (score=${GA_SCORE}, round=${GA_ROUND}). Needs completed + score>=8 + 2 clean rounds. FIND lane (grok/sonnet/k3) surfaces gaps in parallel; FIX lane (fable/sol) resolves them.")
elif [[ "$HAS_FRONTEND" == "true" ]] \
     && ! jq -e '.gates.gap_analysis.ui_validated == true' "$CHECKPOINT_FILE" >/dev/null; then
  MISSING+=("BLOCKED: gap_analysis lacks the ui-validated stamp (frontend changes detected). Re-run: pipeline-gate.sh gap_analysis completed <score> <round> ui-validated")
fi

# v2 gate 3: cross_model_review — one senior outside-family pass
CMR_STATUS=$(jq -r '.gates.cross_model_review.status // "NOT RUN"' "$CHECKPOINT_FILE")
CMR_COUNTER=$(jq -r '.gates.cross_model_review.change_counter // -1' "$CHECKPOINT_FILE")
if [[ "$CMR_STATUS" != "completed" ]] || [[ "$CMR_COUNTER" != "$CURRENT_COUNTER" ]]; then
  MISSING+=("BLOCKED: cross_model_review gate ${CMR_STATUS}. One senior outside-family pass (Sol reviews Fable's work / vice versa; K3 tiebreaker) via codex exec.")
fi

# v2 gate 4: greptile_score — completed with score>=4, or skipped pre-PR
GREP_STATUS=$(jq -r '.gates.greptile_score.status // "NOT RUN"' "$CHECKPOINT_FILE")
GREP_COUNTER=$(jq -r '.gates.greptile_score.change_counter // -1' "$CHECKPOINT_FILE")
GREP_OK=false
if [[ "$GREP_STATUS" == "skipped" ]]; then
  GREP_OK=true
elif [[ "$GREP_STATUS" == "completed" ]] \
     && jq -e '(.gates.greptile_score.score // 0) >= 4' "$CHECKPOINT_FILE" >/dev/null; then
  GREP_OK=true
fi
if [[ "$GREP_OK" != "true" ]] || [[ "$GREP_COUNTER" != "$CURRENT_COUNTER" ]]; then
  MISSING+=("BLOCKED: greptile_score gate ${GREP_STATUS}. Needs completed with score>=4, or skipped pre-PR (the PR loop enforces >=4/5 before merge).")
fi

echo "PIPELINE CHECK FAILED — commit not allowed."
echo ""
for msg in "${MISSING[@]}"; do
  echo "  $msg"
done
echo ""
echo "Complete the required gates before committing."

exit 2
