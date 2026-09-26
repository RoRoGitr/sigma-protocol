#!/usr/bin/env bash
set -euo pipefail

# Enforce a safe file budget so Greptile review never gets skipped for oversized PRs.
# Usage:
#   scripts/check-pr-file-budget.sh [BASE] [HEAD]
# Examples:
#   scripts/check-pr-file-budget.sh origin/main HEAD
#   MAX_CHANGED_FILES=90 scripts/check-pr-file-budget.sh   # tighten for focused review
#   Default is 9999 (effectively unlimited — guards only against catastrophic accidents).

MAX_CHANGED_FILES="${MAX_CHANGED_FILES:-9999}"
BASE_REF="${1:-origin/main}"
HEAD_REF="${2:-HEAD}"

if ! [[ "$MAX_CHANGED_FILES" =~ ^[0-9]+$ ]]; then
  echo "MAX_CHANGED_FILES must be an integer, got: $MAX_CHANGED_FILES" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a git repository." >&2
  exit 2
fi

changed_files=()
while IFS= read -r file; do
  changed_files+=("$file")
done < <(git diff --name-only "$BASE_REF...$HEAD_REF")

changed_count="${#changed_files[@]}"

echo "PR file budget check:"
echo "  Base:  $BASE_REF"
echo "  Head:  $HEAD_REF"
echo "  Files: $changed_count"
echo "  Limit: $MAX_CHANGED_FILES"

if (( changed_count > MAX_CHANGED_FILES )); then
  required_prs=$(( (changed_count + MAX_CHANGED_FILES - 1) / MAX_CHANGED_FILES ))
  echo
  echo "FAIL: changed files ($changed_count) exceed limit ($MAX_CHANGED_FILES)."
  echo "Split this work into approximately $required_prs stacked PRs."
  echo
  echo "Suggested split workflow:"
  echo "  1) Group by domain (e.g., orchestration, commands, docs/tests)."
  echo "  2) Create stacked branches from previous PR branch."
  echo "  3) Keep each PR <= $MAX_CHANGED_FILES files."
  echo
  echo "Top changed files:"
  printf '  - %s\n' "${changed_files[@]:0:25}"
  exit 1
fi

echo "PASS: file count is within budget."
