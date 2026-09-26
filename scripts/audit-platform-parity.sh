#!/usr/bin/env bash
# audit-platform-parity.sh
# Audits parity between canonical steps/ and rendered commands/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STEPS_DIR="$PROJECT_ROOT/steps"
COMMANDS_DIR="$PROJECT_ROOT/commands"

issues=0
report_issue() { echo "[FAIL] $1"; ((issues+=1)); }
report_ok() { echo "[OK]   $1"; }

echo "=== Canonical Parity Audit ==="
echo "Source: ${STEPS_DIR#$PROJECT_ROOT/}"
echo "Target: ${COMMANDS_DIR#$PROJECT_ROOT/}"
echo

if [[ ! -d "$COMMANDS_DIR" ]]; then
  report_issue "Missing commands directory — run scripts/sync-steps-to-platforms.sh"
fi

if ! "$PROJECT_ROOT/scripts/lint-step-parity.sh"; then
  report_issue "Rendered step parity failed (see lint-step-parity output)"
else
  report_ok "Full rendered steps match commands/"
fi

RENDER_TMP="$(mktemp)"
trap 'rm -f "$RENDER_TMP"' EXIT

source "$SCRIPT_DIR/lib/step-partials.sh"

for src in "$STEPS_DIR"/step-*; do
  [[ -f "$src" ]] || continue
  name="$(basename "$src")"
  dest="$COMMANDS_DIR/${name}.md"
  if [[ ! -f "$dest" ]]; then
    report_issue "Missing rendered command: commands/${name}.md"
    continue
  fi
  if ! expand_step_partials "$src" "$RENDER_TMP" "$STEPS_DIR"; then
    report_issue "Failed to expand $name"
    continue
  fi
  if ! cmp -s "$RENDER_TMP" "$dest"; then
    report_issue "commands/${name}.md drift — run scripts/sync-steps-to-platforms.sh"
  fi
done

if ! node "$PROJECT_ROOT/scripts/verify/validate-step-wiring.mjs"; then
  report_issue "validate-step-wiring failed"
else
  report_ok "validate-step-wiring passed"
fi

lint_output="$(mktemp)"
if ! "$PROJECT_ROOT/scripts/lint-deprecated-step-refs.sh" >"$lint_output" 2>&1; then
  report_issue "Active workflow surfaces still contain removed step terms"
  sed -n '1,40p' "$lint_output"
else
  report_ok "No deprecated step terms in active surfaces"
fi
rm -f "$lint_output"

if (( issues > 0 )); then
  echo
  echo "Parity audit failed with $issues issue(s)."
  exit 1
fi

echo
report_ok "Parity audit passed"
