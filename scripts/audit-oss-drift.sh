#!/usr/bin/env bash
# audit-oss-drift.sh — fail if active OSS surfaces reintroduce removed mirror paths or legacy step aliases.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ACTIVE=(
  "$PROJECT_ROOT/steps"
  "$PROJECT_ROOT/commands"
  "$PROJECT_ROOT/docs"
  "$PROJECT_ROOT/AGENTS.md"
  "$PROJECT_ROOT/README.md"
  "$PROJECT_ROOT/CLAUDE.md"
  "$PROJECT_ROOT/.agents/skills"
  "$PROJECT_ROOT/src/skills"
  "$PROJECT_ROOT/src/agents"
  "$PROJECT_ROOT/scripts/sync-steps-to-platforms.sh"
  "$PROJECT_ROOT/scripts/sync-agents-step-pointers.py"
  "$PROJECT_ROOT/scripts/generate-sigma-indexes.mjs"
  "$PROJECT_ROOT/.claude/lib/agent-skill-registry.json"
)

EXCLUDE=(
  'docs/archive'
  'CHANGELOG.md'
  'templates/boilerplates'
  'docs/SIGMA-VERSIONING.md'
  'scripts/sync-steps-to-platforms.sh'
  'scripts/sync-agents-step-pointers.py'
  'scripts/generate-sigma-indexes.mjs'
  'scripts/lint-deprecated-step-refs.sh'
)

issues=0

should_scan() {
  local f="$1"
  for ex in "${EXCLUDE[@]}"; do
    [[ "$f" == *"$ex"* ]] && return 1
  done
  return 0
}

collect_files() {
  local root
  for root in "${ACTIVE[@]}"; do
    if [[ -d "$root" ]]; then
      find "$root" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.json' -o -name '*.sh' -o -name '*.mjs' -o -name '*.py' \)
    elif [[ -f "$root" ]]; then
      echo "$root"
    fi
  done | sort -u
}

check_pattern() {
  local label="$1"
  local pattern="$2"
  local -a files=()
  while IFS= read -r f; do
    should_scan "$f" || continue
    files+=("$f")
  done < <(collect_files)

  echo "--- $label ---"
  if rg -n -e "$pattern" "${files[@]}" 2>/dev/null; then
    echo "[FAIL] $label"
    ((issues+=1)) || true
  else
    echo "[OK] $label"
  fi
  echo
}

echo "=== OSS Drift Audit ==="

if [[ -d "$PROJECT_ROOT/platforms" ]]; then
  echo "[FAIL] platforms/ directory exists on disk — run: git rm -r platforms && rm -rf platforms"
  ((issues+=1)) || true
else
  echo "[OK] platforms/ absent"
fi

if git ls-files 'platforms/*' 2>/dev/null | grep -q .; then
  echo "[FAIL] platforms/* still tracked in git index"
  ((issues+=1)) || true
else
  echo "[OK] platforms/* not in git index"
fi

echo
check_pattern "Legacy step invocations (@step-5a/b/11a/b)" '@step-5a|@step-5b|@step-11a|@step-11b|/step-5a-|/step-5b-|/step-11a-|/step-11b-'
check_pattern "platforms/* mirror paths (not deprecation docs)" 'platforms/[a-z-]+/(commands|skills|droids)'
check_pattern "Canonical .claude/commands as install surface" '"\.claude/commands/|Canonical.*\.claude/commands'

if [[ "$issues" -gt 0 ]]; then
  echo "OSS drift audit failed with $issues issue(s)."
  exit 1
fi

echo "OSS drift audit passed."
