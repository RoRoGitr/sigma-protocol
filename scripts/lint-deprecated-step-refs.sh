#!/usr/bin/env bash
# lint-deprecated-step-refs.sh
# Fails when active workflow surfaces reintroduce removed workflow-step aliases
# or Ralph-era wording outside archive/migration/deprecation zones.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE
Usage: $(basename "$0")

Checks active workflow surfaces only. Archive/migration/deprecation zones such as
docs/archive/ and scripts/migrate-legacy-backlogs.sh are intentionally excluded.
USAGE
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
esac

ACTIVE_ROOTS=(
  "$PROJECT_ROOT/AGENTS.md"
  "$PROJECT_ROOT/README.md"
  "$PROJECT_ROOT/CLAUDE.md"
  "$PROJECT_ROOT/docs/COMMANDS.md"
  "$PROJECT_ROOT/docs/WORKFLOW-OVERVIEW.md"
  "$PROJECT_ROOT/docs/PLATFORMS.md"
  "$PROJECT_ROOT/docs/FILE-PATH-REFERENCE.md"
  "$PROJECT_ROOT/steps"
  "$PROJECT_ROOT/steps/validate-methodology"
  "$PROJECT_ROOT/steps/dev-loop"
  "$PROJECT_ROOT/commands"
)

# Step pointer stubs only — not the full methodology pool
shopt -s nullglob
for step_skill in "$PROJECT_ROOT"/.agents/skills/step-*; do
  ACTIVE_ROOTS+=("$step_skill")
done
shopt -u nullglob

# Workflow skills with cross-step references
for workflow_skill in continue prd-orchestrate retrofit-sync status; do
  skill_path="$PROJECT_ROOT/.agents/skills/$workflow_skill"
  [[ -d "$skill_path" ]] && ACTIVE_ROOTS+=("$skill_path")
done

collect_active_files() {
  local root
  for root in "${ACTIVE_ROOTS[@]}"; do
    if [[ -d "$root" ]]; then
      find "$root" -type f \( -name '*.md' -o -name '*.mdc' -o -name '*.txt' \)
    elif [[ -f "$root" ]]; then
      echo "$root"
    fi
  done | sort -u
}

ACTIVE_FILES=()
while IFS= read -r active_file; do
  [[ -z "$active_file" ]] && continue
  ACTIVE_FILES+=("$active_file")
done < <(collect_active_files)

if [[ "${#ACTIVE_FILES[@]}" -eq 0 ]]; then
  echo "No active workflow files found to lint."
  exit 0
fi

LEGACY_STEP_LABEL_PATTERN='Step[[:space:]]+3\.5|^3\.5:|Step[[:space:]]+5\.5|^5\.5:|[[:space:]]5\.5[[:space:]]*->|Step[[:space:]]+11\.25|^11\.25:|[[:space:]]11\.25[[:space:]]*->|Step[[:space:]]+11b|^11b:|[[:space:]]11b[[:space:]]*->'
LEGACY_STEP_ALIAS_PATTERN='step-5a|step-5b|step-11a|step-11b'
RALPH_PATTERN='\bRalph\b|docs/ralph|\.sigma/ralph|sigma ralph|--ralph|skip-ralph'
PLATFORM_MIRROR_PATTERN='platforms/[a-z-]+/(commands|skills|droids)'
# Cursor is a restored, supported platform: .cursor/ paths are allowed in active
# surfaces. Only the removed in-Cursor *workflow* phrasing (custom dispatch /
# legacy .cursorrules) stays banned.
CURSOR_ERA_PATTERN="In-Cursor|Cursor's web browsing|\\.cursorrules"

issues=0

run_check() {
  local label="$1"
  local pattern="$2"

  echo "--- $label ---"
  if rg -n -e "$pattern" "${ACTIVE_FILES[@]}"; then
    echo
    echo "[FAIL] $label"
    ((issues+=1))
  else
    echo "[OK] $label"
  fi
  echo
}

echo "=== Legacy Workflow Drift Lint ==="
echo "Scanning ${#ACTIVE_FILES[@]} active workflow file(s)"
echo "Excluded zones: docs/archive/, scripts/migrate-legacy-backlogs.sh, deprecated stubs outside active roots"
echo

run_check "Removed workflow step labels (5.5 / 11.25 / 11b)" "$LEGACY_STEP_LABEL_PATTERN"
run_check "Removed step-style aliases (step-5a / step-5b / step-11a / step-11b)" "$LEGACY_STEP_ALIAS_PATTERN"
run_check "Ralph-era wording outside archive/migration zones" "$RALPH_PATTERN"
run_check "Legacy platforms/* mirror paths in active surfaces" "$PLATFORM_MIRROR_PATTERN"
run_check "Removed in-Cursor workflow phrasing (legacy dispatch / .cursorrules)" "$CURSOR_ERA_PATTERN"

if (( issues > 0 )); then
  echo "Legacy workflow drift lint failed with $issues issue(s)."
  exit 1
fi

echo "Legacy workflow drift lint passed."
