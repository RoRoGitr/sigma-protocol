#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed. Install with: brew install jq" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside a git repository" >&2
  exit 1
fi

CHECKPOINT_FILE="${REPO_ROOT}/.pipeline-state.json"
if [[ ! -f "$CHECKPOINT_FILE" ]]; then
  "$SCRIPT_DIR/pipeline-init.sh" >/dev/null
fi

collect_changed_files() {
  # Fingerprint SOURCE changes only. Build/test artifacts (pycache, coverage,
  # .next, node_modules, logs, the pipeline's own state/bypass files) are
  # excluded — otherwise running a gate that executes tests creates artifacts,
  # bumps change_counter mid-run, and invalidates every earlier gate's stamp so
  # commit_allowed can NEVER become true (the unsatisfiable-gate bug, 28
  # bypasses/day, warroom 2026-07-20).
  {
    git diff --cached --name-only 2>/dev/null || true
    git diff --name-only 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null || true
  } | sed '/^$/d' \
    | grep -vE '^(\.pipeline-state\.json|\.pipeline-history\.jsonl|\.sprint-state\.json|\.gate-bypass-log|\.sprint-history\.jsonl)$' \
    | grep -vE '(^|/)(__pycache__|\.pytest_cache|\.ruff_cache|\.mypy_cache|\.next|node_modules|\.turbo|htmlcov|\.coverage|dist|build|coverage)(/|$)' \
    | grep -vE '\.(pyc|pyo|log|orig|rej)$' \
    | sort -u
}

build_changed_files_json() {
  local files
  files="$(collect_changed_files)"
  if [[ -z "$files" ]]; then
    printf '[]'
  else
    printf '%s\n' "$files" | jq -R . | jq -s .
  fi
}

detect_frontend_from_files() {
  local files
  files="$(collect_changed_files)"

  if printf '%s\n' "$files" | grep -qE '\.(tsx|jsx|css|scss|vue|svelte|module\.css)$'; then
    echo "true"
    return
  fi

  if printf '%s\n' "$files" | grep -qE '(/components/|/app/|/pages/|/views/|/layouts/).*\.(ts|tsx|js|jsx|css|scss|vue|svelte|html)$'; then
    echo "true"
    return
  fi

  echo "false"
}

# Fingerprint SOURCE paths only. Hashing every changed file meant a docs,
# brief, ledger, or .claude/ edit — including churn from OTHER agents in a
# shared tree — bumped change_counter and staleness-invalidated every gate, so
# commit_allowed could essentially never be true in an active repo (224 logged
# SKIP_PIPELINE_CHECK bypasses in Sigmavue-Mono by 2026-07-26). Gates guard
# CODE; docs and agent-workflow files must not reset them.
# Override with PIPELINE_FINGERPRINT_ALL=1.
#
# UNIFICATION NOTE (2026-07-26): this file MUST stay byte-identical between
# cross-model-agents (upstream) and sigma-protocol-v2 (bundled downstream).
# The two copies briefly diverged and alternately wrote DIFFERENT fingerprints
# into the same .pipeline-state.json, bumping change_counter on every
# alternation — the runaway-counter bug. If you edit one copy, sync the other
# in the same change (sync-from-community.sh --check).
is_source_path() {
  case "$1" in
    *.md|*.mdx|*.txt|docs/*|*/docs/*|.claude/*|*/.claude/*|.codex/*|*/.codex/*|\
    openwiki/*|*/openwiki/*|*.log|.gate-bypass-log|.pipeline-history.jsonl|.sprint-history.jsonl) return 1 ;;
    *) return 0 ;;
  esac
}

build_worktree_fingerprint() {
  files=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "${PIPELINE_FINGERPRINT_ALL:-0}" != "1" ]]; then
      is_source_path "$line" || continue
    fi
    files+=("$line")
  done < <(collect_changed_files)

  {
    printf '%s\n' '---STAGED---'
    if [[ ${#files[@]} -gt 0 ]]; then
      git diff --cached --binary --no-ext-diff -- "${files[@]}" 2>/dev/null || true
    fi
    printf '%s\n' '---UNSTAGED---'
    if [[ ${#files[@]} -gt 0 ]]; then
      git diff --binary --no-ext-diff -- "${files[@]}" 2>/dev/null || true
    fi
    printf '%s\n' '---UNTRACKED---'
    for file in "${files[@]}"; do
      if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
        continue
      fi
      printf 'FILE:%s\n' "$file"
      shasum -a 256 "$file" 2>/dev/null || true
    done
  } | shasum -a 256 | awk '{print $1}'
}

CHANGED_FILES_JSON="$(build_changed_files_json)"
HAS_FRONTEND="$(detect_frontend_from_files)"
CURRENT_FINGERPRINT="$(build_worktree_fingerprint)"
STORED_FINGERPRINT="$(jq -r '.worktree_fingerprint // ""' "$CHECKPOINT_FILE")"
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

if [[ "$CURRENT_FINGERPRINT" != "$STORED_FINGERPRINT" ]]; then
  UPDATED="$(jq \
    --argjson changed_files "$CHANGED_FILES_JSON" \
    --arg has_frontend "$HAS_FRONTEND" \
    --arg worktree_fingerprint "$CURRENT_FINGERPRINT" \
    --arg updated_at "$TIMESTAMP" \
    '.changed_files = $changed_files
     | .has_frontend_changes = ($has_frontend == "true")
     | .worktree_fingerprint = $worktree_fingerprint
     | .last_change_at = $updated_at
     | .change_counter = ((.change_counter // 0) + 1)
     | .commit_allowed = false' \
    "$CHECKPOINT_FILE")"
else
  UPDATED="$(jq \
    --argjson changed_files "$CHANGED_FILES_JSON" \
    --arg has_frontend "$HAS_FRONTEND" \
    --arg worktree_fingerprint "$CURRENT_FINGERPRINT" \
    '.changed_files = $changed_files
     | .has_frontend_changes = ($has_frontend == "true")
     | .worktree_fingerprint = $worktree_fingerprint' \
    "$CHECKPOINT_FILE")"
fi

echo "$UPDATED" > "$CHECKPOINT_FILE"
echo "$CURRENT_FINGERPRINT"
