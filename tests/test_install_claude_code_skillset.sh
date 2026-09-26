#!/usr/bin/env bash
# tests/test_install_claude_code_skillset.sh
# Regression guard for scripts/install-claude-code.sh skill/agent MERGE behavior.
#
# CONTRACT UNDER TEST:
#   The installer must install the FULL legacy base (.claude/skills) PLUS the
#   canonical overlay (src/skills) — never one OR the other. The pre-change
#   logic was exclusive (src wins, legacy dropped), which silently reduced the
#   installed skill set the moment src/skills appeared. This test asserts the
#   install set is NOT reduced: the dry-run install count is >= the legacy base
#   count, and an overlay-only skill (present only in src/skills) is installed.
#
# Run: bash tests/test_install_claude_code_skillset.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$SCRIPT_DIR/scripts/install-claude-code.sh"
TESTS_PASS=0
TESTS_FAIL=0

# ── Harness ────────────────────────────────────────────────────
_pass() {
  echo "  PASS: $1"
  TESTS_PASS=$((TESTS_PASS + 1))
}
_fail() {
  echo "  FAIL: $1"
  echo "       $2"
  TESTS_FAIL=$((TESTS_FAIL + 1))
}

run_test() {
  local name="$1"
  local fn="$2"
  echo ""
  echo "[$name]"
  "$fn"
}

# ── Fixture ────────────────────────────────────────────────────
# Build a synthetic source repo with legacy, bundled, and canonical skill roots.
# LEGACY_BASE_COUNT distinct legacy skills; BUNDLED adds one; canonical redefines one.
LEGACY_BASE_COUNT=12

make_fixture() {
  local root
  root="$(mktemp -d)"
  mkdir -p "$root/scripts"
  mkdir -p "$root/steps" "$root/commands"
  cp "$INSTALLER" "$root/scripts/install-claude-code.sh"
  chmod +x "$root/scripts/install-claude-code.sh"
  mkdir -p "$root/src/agents"
  printf 'bundled agent\n' > "$root/src/agents/example.md"

  # Legacy base: .claude/skills/<name>/SKILL.md (categorized layout, like the real repo)
  mkdir -p "$root/.claude/skills/core"
  local i
  for i in $(seq 1 "$LEGACY_BASE_COUNT"); do
    mkdir -p "$root/.claude/skills/core/legacy-skill-$i"
    printf -- '---\nname: legacy-skill-%s\n---\nlegacy body %s\n' "$i" "$i" \
      > "$root/.claude/skills/core/legacy-skill-$i/SKILL.md"
  done

  # Bundled methodology pool: available on a clean install even when absent
  # from src/skills. A nested support document must not become a skill itself.
  mkdir -p "$root/.agents/skills/bundled-only/references"
  printf -- '---\nname: bundled-only\n---\nbundled body\n' > "$root/.agents/skills/bundled-only/SKILL.md"
  printf -- 'support document\n' > "$root/.agents/skills/bundled-only/references/guide.md"
  mkdir -p "$root/.agents/skills/legacy-skill-2"
  printf -- '---\nname: legacy-skill-2\n---\nBUNDLED WINS marker\n' > "$root/.agents/skills/legacy-skill-2/SKILL.md"
  mkdir -p "$root/.agents/skills/overlay-only-1/references"
  printf -- '---\nname: overlay-only-1\n---\nbundled overlay\n' > "$root/.agents/skills/overlay-only-1/SKILL.md"
  printf 'bundled support\n' > "$root/.agents/skills/overlay-only-1/references/guide.md"
  mkdir -p "$root/.agents/skills/step-1-ideation/references"
  printf -- '---\nname: step-1-ideation\n---\nRead references/step.md\n' > "$root/.agents/skills/step-1-ideation/SKILL.md"
  printf '## Phase A\n<HARD-GATE>\n' > "$root/.agents/skills/step-1-ideation/references/step.md"

  # Canonical overlay: src/skills/<name>/SKILL.md
  #   - 3 brand-new overlay-only skills
  #   - 1 name collision with a legacy skill (overlay must WIN)
  mkdir -p "$root/src/skills"
  printf -- '---\nname: canonical-flat\n---\nflat body\n' > "$root/src/skills/canonical-flat.md"
  for i in 1 2 3; do
    mkdir -p "$root/src/skills/overlay-only-$i"
    printf -- '---\nname: overlay-only-%s\n---\noverlay body %s\n' "$i" "$i" \
      > "$root/src/skills/overlay-only-$i/SKILL.md"
  done
  mkdir -p "$root/src/skills/overlay-only-1/references"
  printf 'canonical support\n' > "$root/src/skills/overlay-only-1/references/guide.md"
  mkdir -p "$root/src/skills/legacy-skill-1"
  printf -- '---\nname: legacy-skill-1\n---\nOVERLAY WINS marker\n' \
    > "$root/src/skills/legacy-skill-1/SKILL.md"

  echo "$root"
}

# Run the installer dry-run against a fixture with an isolated HOME, capture stdout.
run_installer_dry() {
  local root="$1"
  local fake_home
  fake_home="$(mktemp -d)"
  HOME="$fake_home" bash "$root/scripts/install-claude-code.sh" --dry-run 2>&1
}

run_installer() {
  local root="$1" fake_home="$2" force="${3:-}"
  SIGMA_SKIP_BRAIN=1 HOME="$fake_home" bash "$root/scripts/install-claude-code.sh" $force 2>&1
}

# Count installed skills from installer dry-run output.
count_skill_lines() {
  grep -c "Skill:" || true
}

# ── Tests ──────────────────────────────────────────────────────

# 1. Install set is NOT reduced: dry-run skill count >= legacy base count.
test_install_set_not_reduced() {
  local root out count
  root="$(make_fixture)"
  out="$(run_installer_dry "$root")"
  count="$(printf '%s\n' "$out" | count_skill_lines)"

  if [ "$count" -ge "$LEGACY_BASE_COUNT" ]; then
    _pass "install count ($count) >= legacy base ($LEGACY_BASE_COUNT) — set not reduced"
  else
    _fail "install set REDUCED" "got $count skills, legacy base is $LEGACY_BASE_COUNT"
  fi
  rm -rf "$root"
}

# 2. Overlay layers ON TOP: overlay-only skills are installed alongside legacy.
test_overlay_skills_present() {
  local root out
  root="$(make_fixture)"
  out="$(run_installer_dry "$root")"

  local missing=0 name
  for name in overlay-only-1 overlay-only-2 overlay-only-3; do
    printf '%s\n' "$out" | grep -q "Skill: $name" || missing=1
  done

  if [ "$missing" -eq 0 ]; then
    _pass "all 3 overlay-only skills installed (merge, not replace)"
  else
    _fail "overlay skill missing" "expected overlay-only-{1,2,3} in install output"
  fi
  rm -rf "$root"
}

# 3. Merge count = legacy base + new overlay skills (collision de-duped to one).
#    12 legacy + 3 new overlay = 15 distinct installed names.
test_merge_count_exact() {
  local root out count expected
  root="$(make_fixture)"
  expected=$((LEGACY_BASE_COUNT + 6))
  out="$(run_installer_dry "$root")"
  # Distinct skill names across the dry-run (collision name appears once installed,
  # once skipped — count distinct names instead).
  count="$(printf '%s\n' "$out" | grep -oE 'Skill: [a-z0-9-]+' | sort -u | wc -l | tr -d ' ')"

  if [ "$count" -eq "$expected" ]; then
    _pass "distinct installed skills ($count) == legacy + overlay ($expected)"
  else
    _fail "merge count mismatch" "got $count distinct, expected $expected"
  fi
  rm -rf "$root"
}

# 4. Tracked bundled skills install even when they have no src/ counterpart.
test_bundled_only_skill_present() {
  local root out
  root="$(make_fixture)"
  out="$(run_installer_dry "$root")"
  if printf '%s\n' "$out" | grep -q 'Skill: bundled-only'; then
    _pass "bundled-only skill installed from .agents/skills"
  else
    _fail "bundled-only skill missing" "clean install must include .agents/skills"
  fi
  rm -rf "$root"
}

# 5. Only SKILL.md roots are skills, and their complete support tree is copied.
test_skill_root_and_support_copy() {
  local root fake_home out
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  out="$(run_installer "$root" "$fake_home")"
  if printf '%s\n' "$out" | grep -q 'Skill: guide'; then
    _fail "nested support file became a skill" "references/guide.md must stay support content"
  elif [ ! -f "$fake_home/.claude/skills/bundled-only/references/guide.md" ]; then
    _fail "support file missing" "skill support tree was not copied"
  else
    _pass "only SKILL.md roots install and support files are preserved"
  fi
  rm -rf "$root" "$fake_home"
}

# 6. The documented precedence is legacy, then bundled, then canonical.
test_source_precedence() {
  local root fake_home
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  run_installer "$root" "$fake_home" >/dev/null
  if grep -q 'OVERLAY WINS marker' "$fake_home/.claude/skills/legacy-skill-1/SKILL.md" \
    && grep -q 'BUNDLED WINS marker' "$fake_home/.claude/skills/legacy-skill-2/SKILL.md"; then
    _pass "bundled overrides legacy and src overrides both"
  else
    _fail "source precedence failed" "expected bundled and canonical markers in installed skills"
  fi
  rm -rf "$root" "$fake_home"
}

# 7. Bundled skills preserve a pre-existing user target unless --force is set.
test_bundled_preserves_user_target_unless_forced() {
  local root fake_home target
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  target="$fake_home/.claude/skills/bundled-only/SKILL.md"
  mkdir -p "$(dirname "$target")"
  printf 'USER MARKER\n' > "$target"
  run_installer "$root" "$fake_home" >/dev/null
  if ! grep -q 'USER MARKER' "$target"; then
    _fail "bundled overwrote user target" "expected user skill to remain without --force"
  elif ! run_installer "$root" "$fake_home" --force >/dev/null || ! grep -q 'bundled body' "$target"; then
    _fail "force did not overwrite user target" "expected bundled skill after --force"
  else
    _pass "bundled skill preserves user target and --force overrides it"
  fi
  rm -rf "$root" "$fake_home"
}

# 8. Root-level canonical Markdown remains an explicit legacy skill shape.
test_canonical_flat_skill_present() {
  local root fake_home
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  run_installer "$root" "$fake_home" >/dev/null
  if [ -f "$fake_home/.claude/skills/canonical-flat/SKILL.md" ]; then
    _pass "root-level src legacy flat skill installs"
  else
    _fail "canonical flat skill missing" "expected src/skills/canonical-flat.md to install"
  fi
  rm -rf "$root" "$fake_home"
}

# 9. Duplicate names in one source pool fail before the installer writes HOME.
test_duplicate_source_names_fail_before_writes() {
  local root fake_home
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  mkdir -p "$root/src/skills/dev/shared" "$root/src/skills/ops/shared"
  printf 'dev\n' > "$root/src/skills/dev/shared/SKILL.md"
  printf 'ops\n' > "$root/src/skills/ops/shared/SKILL.md"
  if run_installer "$root" "$fake_home" >/dev/null 2>&1; then
    _fail "duplicate source names succeeded" "same-pool duplicate must fail"
  elif [ -e "$fake_home/.claude" ]; then
    _fail "duplicate source names wrote target" "installer must fail before HOME writes"
  else
    _pass "duplicate source names fail before target writes"
  fi
  rm -rf "$root" "$fake_home"
}

# 10. Portable bundled step adapters retain their local reference tree.
test_step_adapter_preserves_references() {
  local root fake_home target
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  target="$fake_home/.claude/skills/step-1-ideation/SKILL.md"
  run_installer "$root" "$fake_home" >/dev/null
  if grep -q 'Read references/step.md' "$target" && grep -q '<HARD-GATE>' "$(dirname "$target")/references/step.md"; then
    _pass "bundled step adapter retains portable reference"
  else
    _fail "step adapter lost reference" "expected installed adapter and step reference"
  fi
  rm -rf "$root" "$fake_home"
}

# 11. Canonical entrypoints update without replacing user-customized support.
test_canonical_preserves_existing_support() {
  local root fake_home target
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  target="$fake_home/.claude/skills/overlay-only-1"
  mkdir -p "$target/references"
  printf 'USER ENTRYPOINT\n' > "$target/SKILL.md"
  printf 'USER SUPPORT\n' > "$target/references/guide.md"
  run_installer "$root" "$fake_home" >/dev/null
  if grep -q 'USER ENTRYPOINT' "$target/SKILL.md" && grep -q 'USER SUPPORT' "$target/references/guide.md"; then
    _pass "canonical skill preserves existing entrypoint and support"
  else
    _fail "canonical user-skill preservation failed" "expected user SKILL.md and guide"
  fi
  rm -rf "$root" "$fake_home"
}

# 12. Canonical support overrides an earlier bundled copy from this same run.
test_canonical_support_overrides_lower_priority_source() {
  local root fake_home target
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  target="$fake_home/.claude/skills/overlay-only-1/references/guide.md"
  run_installer "$root" "$fake_home" >/dev/null
  if grep -q 'canonical support' "$target"; then
    _pass "canonical support overrides bundled support in same run"
  else
    _fail "canonical support precedence failed" "expected canonical reference after fresh install"
  fi
  rm -rf "$root" "$fake_home"
}

# 13. Never follow a symlinked skill target, even with --force.
test_symlinked_target_is_refused() {
  local root fake_home outside
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  outside="$(mktemp -d)"
  printf 'OUTSIDE USER MARKER\n' > "$outside/SKILL.md"
  mkdir -p "$fake_home/.claude/skills"
  ln -s "$outside" "$fake_home/.claude/skills/bundled-only"
  run_installer "$root" "$fake_home" --force >/dev/null
  if grep -q 'OUTSIDE USER MARKER' "$outside/SKILL.md"; then
    _pass "symlinked target is never followed"
  else
    _fail "symlinked target was overwritten" "installer wrote outside CLAUDE_HOME"
  fi
  rm -rf "$root" "$fake_home" "$outside"
}

# 14. Nested target symlinks are also refused so support copies stay contained.
test_nested_symlink_target_is_refused() {
  local root fake_home outside target
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  outside="$(mktemp -d)"
  target="$fake_home/.claude/skills/overlay-only-1"
  printf 'OUTSIDE SUPPORT MARKER\n' > "$outside/guide.md"
  mkdir -p "$target"
  printf 'USER ENTRYPOINT\n' > "$target/SKILL.md"
  ln -s "$outside" "$target/references"
  run_installer "$root" "$fake_home" --force >/dev/null
  if grep -q 'OUTSIDE SUPPORT MARKER' "$outside/guide.md"; then
    _pass "nested symlink target is never followed"
  else
    _fail "nested symlink target was overwritten" "installer wrote outside CLAUDE_HOME"
  fi
  rm -rf "$root" "$fake_home" "$outside"
}

# 15. Agent targets follow the same no-symlink rule under --force.
test_symlinked_agent_target_is_refused() {
  local root fake_home outside
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  outside="$(mktemp -d)"
  printf 'OUTSIDE AGENT MARKER\n' > "$outside/example.md"
  mkdir -p "$fake_home/.claude/agents"
  ln -s "$outside/example.md" "$fake_home/.claude/agents/example.md"
  run_installer "$root" "$fake_home" --force >/dev/null
  if grep -q 'OUTSIDE AGENT MARKER' "$outside/example.md"; then
    _pass "symlinked agent target is never followed"
  else
    _fail "symlinked agent target was overwritten" "installer wrote outside CLAUDE_HOME"
  fi
  rm -rf "$root" "$fake_home" "$outside"
}

test_preserved_hook_is_verified_and_wired() {
  local root fake_home out
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  mkdir -p "$root/.claude/hooks" "$fake_home/.claude/hooks"
  printf 'process.exit(0);\n' > "$root/.claude/hooks/step-skill-gate.cjs"
  printf '// USER HOOK\nprocess.exit(0);\n' > "$fake_home/.claude/hooks/step-skill-gate.cjs"
  printf '{}\n' > "$fake_home/.claude/settings.json"
  out="$(run_installer "$root" "$fake_home")"
  if grep -q 'USER HOOK' "$fake_home/.claude/hooks/step-skill-gate.cjs" && \
      grep -q 'step-skill-gate.cjs' "$fake_home/.claude/settings.json" && \
      [[ "$out" == *"differs from source"* ]]; then
    _pass "preserved hook is checked, difference reported, and wiring repaired"
  else
    _fail "preserved hook wiring" "existing hook or idempotent wiring was lost"
  fi
  rm -rf "$root" "$fake_home"
}

test_bad_hook_does_not_replace_existing() {
  local root fake_home
  root="$(make_fixture)"
  fake_home="$(mktemp -d)"
  mkdir -p "$root/.claude/hooks" "$fake_home/.claude/hooks"
  printf 'process.exit(7);\n' > "$root/.claude/hooks/step-skill-gate.cjs"
  printf '// GOOD ORIGINAL\nprocess.exit(0);\n' > "$fake_home/.claude/hooks/step-skill-gate.cjs"
  run_installer "$root" "$fake_home" --force >/dev/null
  if grep -q 'GOOD ORIGINAL' "$fake_home/.claude/hooks/step-skill-gate.cjs"; then
    _pass "failed hook candidate cannot replace an existing hook"
  else
    _fail "bad hook replacement" "failed candidate replaced a working hook"
  fi
  rm -rf "$root" "$fake_home"
}

# ── Run ────────────────────────────────────────────────────────
echo "=== install-claude-code.sh skill-set MERGE regression ==="
run_test "install set not reduced"      test_install_set_not_reduced
run_test "overlay skills present"        test_overlay_skills_present
run_test "merge count exact"             test_merge_count_exact
run_test "bundled-only skill present"     test_bundled_only_skill_present
run_test "skill root and support copy"    test_skill_root_and_support_copy
run_test "source precedence"              test_source_precedence
run_test "bundled user target preservation" test_bundled_preserves_user_target_unless_forced
run_test "canonical flat skill"           test_canonical_flat_skill_present
run_test "duplicate source names"          test_duplicate_source_names_fail_before_writes
run_test "step adapter references"          test_step_adapter_preserves_references
run_test "canonical support preservation"   test_canonical_preserves_existing_support
run_test "canonical support precedence"     test_canonical_support_overrides_lower_priority_source
run_test "symlink target refusal"           test_symlinked_target_is_refused
run_test "nested symlink refusal"           test_nested_symlink_target_is_refused
run_test "agent symlink refusal"            test_symlinked_agent_target_is_refused
run_test "preserved hook wiring"             test_preserved_hook_is_verified_and_wired
run_test "failed hook candidate"             test_bad_hook_does_not_replace_existing

echo ""
echo "──────────────────────────────────────────────"
echo "PASS: $TESTS_PASS   FAIL: $TESTS_FAIL"
if [ "$TESTS_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
