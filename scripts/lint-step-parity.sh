#!/usr/bin/env bash
# scripts/lint-step-parity.sh — full rendered step parity lint
#
# Checks skill blocks and the complete recursively expanded command body.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STEPS_DIR="$REPO_ROOT/steps"
SCRIPT_DIR="$REPO_ROOT/scripts"
FAILURES=0
source "$SCRIPT_DIR/lib/step-partials.sh"

extract_block() {
  awk '/<!-- SKILLS-INVOKE:start -->/{inb=1} inb{print} /<!-- SKILLS-INVOKE:end -->/{inb=0}' "$1"
}

fail() {
  echo "MISMATCH: $*"
  FAILURES=$((FAILURES + 1))
}

RENDER_TMP="$(mktemp)"
trap 'rm -f "$RENDER_TMP"' EXIT

shopt -s nullglob
canonical_files=(steps/step-*)
shopt -u nullglob

for canon in "${canonical_files[@]}"; do
  name="$(basename "$canon")"
  cmd="commands/${name}.md"
  if ! expand_step_partials "$canon" "$RENDER_TMP" "$STEPS_DIR"; then
    fail "$name — failed to expand canonical partials"
    continue
  fi
  canon_block="$(extract_block "$RENDER_TMP")"

  if [[ -z "$canon_block" ]]; then
    fail "$name — canonical steps/$name has NO SKILLS-INVOKE block"
    continue
  fi

  if [[ ! -f "$cmd" ]]; then
    fail "$name — missing rendered command file $cmd"
    continue
  fi

  if grep -qE '^[[:space:]]*<!--[[:space:]]*include:[[:space:]]*_partials/[A-Za-z0-9._/-]+[[:space:]]*-->[[:space:]]*$' "$cmd"; then
    fail "$name — $cmd has unresolved partial include(s)"
    continue
  fi

  cmd_block="$(extract_block "$cmd")"
  if [[ -z "$cmd_block" ]]; then
    fail "$name — $cmd has NO SKILLS-INVOKE block"
    continue
  fi
  if [[ "$canon_block" != "$cmd_block" ]]; then
    fail "$name — SKILLS-INVOKE block in $cmd differs from rendered steps/$name"
    diff <(printf '%s\n' "$canon_block") <(printf '%s\n' "$cmd_block") | sed 's/^/    /' || true
  elif ! cmp -s "$RENDER_TMP" "$cmd"; then
    fail "$name — rendered command body differs from canonical source"
  fi
  adapter=".agents/skills/$name/SKILL.md"
  if [[ -f "$adapter" ]] && grep -Fq "canonical_source: \"steps/$name\"" "$adapter"; then
    reference=".agents/skills/$name/references/step.md"
    if [[ ! -f "$reference" ]] || ! cmp -s "$RENDER_TMP" "$reference"; then
      fail "$name — bundled step reference is missing or stale"
    fi
  fi
done

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "lint-step-parity: FAIL — $FAILURES mismatch(es) across ${#canonical_files[@]} canonical step files"
  exit 1
fi
echo "lint-step-parity: PASS — ${#canonical_files[@]} canonical step files match commands/"
exit 0
