#!/usr/bin/env bash
# test_validate_mirrors.sh — hermetic test suite for scripts/verify/validate-mirrors.mjs
#
# Strategy: build a minimal fake repo tree under a temp dir; use --root <dir> to
# point the script at it. No real repo state is read or written.
#
# Assertions:
#   1. Clean tree (no corruption, no drift) → exit 0
#   2. Planted ResultMessage( corruption in a mirror → exit 1 + names the file
#   3. Planted ToolUseBlock( corruption → exit 1
#   4. Drift (mirror sha differs from src) → non-strict = exit 0 with WARN;
#      strict = exit 1
#   5. Missing mirror (skill in src but not in surface) → exit 0 (superset rule)
#   6. --json flag → parseable JSON with corruption/drift/missing keys
#   7. Absent mirror surface (dir doesn't exist) → skipped gracefully, exit 0
#
# Usage: bash tests/test_validate_mirrors.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/verify/validate-mirrors.mjs"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { echo "  FAIL: $1" >&2; FAIL=$(( FAIL + 1 )); }

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label (exit $actual)"
  else
    fail "$label — expected exit $expected, got $actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label (contains '$needle')"
  else
    fail "$label — output does not contain '$needle'"$'\n'"  Got: $haystack"
  fi
}

if ! command -v node &>/dev/null; then
  echo "FAIL: node not on PATH" >&2; exit 1
fi

echo ""
echo "validate-mirrors test suite"
echo "---------------------------"

# ── Helper: build a minimal fake repo ────────────────────────────────────────

# mk_skill <root> <surface> <name> <content>
mk_skill() {
  local root="$1" surface="$2" name="$3" content="$4"
  local dir="$root/$surface/$name"
  mkdir -p "$dir"
  printf '%s' "$content" > "$dir/SKILL.md"
}

CLEAN_SKILL_CONTENT='---
name: test-skill
version: "1.0.0"
---

# Test Skill

This is a clean skill file with no corruption signatures.
'

# ── Test 1: clean tree → exit 0 ─────────────────────────────────────────────

echo ""
echo "Test 1: clean tree exits 0"

T1_ROOT="$(mktemp -d)"
trap 'rm -rf "$T1_ROOT"' EXIT

mk_skill "$T1_ROOT" "src/skills" "test-skill" "$CLEAN_SKILL_CONTENT"
mk_skill "$T1_ROOT" ".claude/skills" "test-skill" "$CLEAN_SKILL_CONTENT"

set +e
T1_OUT="$(node "$SCRIPT" --root "$T1_ROOT" 2>&1)"
T1_EXIT=$?
set -e

assert_exit "clean tree" 0 "$T1_EXIT"

# ── Test 2: ResultMessage( corruption → exit 1 ───────────────────────────────

echo ""
echo "Test 2: ResultMessage( corruption in mirror → exit 1"

T2_ROOT="$(mktemp -d)"
trap 'rm -rf "$T2_ROOT"' EXIT

mk_skill "$T2_ROOT" "src/skills" "my-skill" "$CLEAN_SKILL_CONTENT"

CORRUPTED='---
name: my-skill
version: "1.0.0"
---

ResultMessage(id=msg_01, content=[TextBlock(text=hello, type=text)], stop_reason=end_turn)
'
mk_skill "$T2_ROOT" ".claude/skills" "my-skill" "$CORRUPTED"

set +e
T2_OUT="$(node "$SCRIPT" --root "$T2_ROOT" 2>&1)"
T2_EXIT=$?
set -e

assert_exit "ResultMessage corruption → exit 1" 1 "$T2_EXIT"
assert_contains "names the corrupted file" "my-skill" "$T2_OUT"
assert_contains "names ResultMessage signature" "ResultMessage(" "$T2_OUT"

# ── Test 3: ToolUseBlock( corruption → exit 1 ────────────────────────────────

echo ""
echo "Test 3: ToolUseBlock( corruption in mirror → exit 1"

T3_ROOT="$(mktemp -d)"
trap 'rm -rf "$T3_ROOT"' EXIT

mk_skill "$T3_ROOT" "src/skills" "skill-b" "$CLEAN_SKILL_CONTENT"

CORRUPTED_B='---
name: skill-b
---

ToolUseBlock(id=toolu_01, input={}, name=Read, type=tool_use)
'
mk_skill "$T3_ROOT" ".claude/skills" "skill-b" "$CORRUPTED_B"

set +e
T3_OUT="$(node "$SCRIPT" --root "$T3_ROOT" 2>&1)"
T3_EXIT=$?
set -e

assert_exit "ToolUseBlock corruption → exit 1" 1 "$T3_EXIT"
assert_contains "names ToolUseBlock signature" "ToolUseBlock(" "$T3_OUT"

# ── Test 4: drift — non-strict exits 0, strict exits 1 ──────────────────────

echo ""
echo "Test 4a: drift with non-strict → exit 0 (WARN)"

T4_ROOT="$(mktemp -d)"
trap 'rm -rf "$T4_ROOT"' EXIT

mk_skill "$T4_ROOT" "src/skills" "drifted-skill" "$CLEAN_SKILL_CONTENT"

DRIFTED_CONTENT='---
name: drifted-skill
version: "0.9.0"
---

# Test Skill (old version)

This mirror has different content.
'
mk_skill "$T4_ROOT" ".claude/skills" "drifted-skill" "$DRIFTED_CONTENT"

set +e
T4A_OUT="$(node "$SCRIPT" --root "$T4_ROOT" 2>&1)"
T4A_EXIT=$?
set -e

assert_exit "drift non-strict → exit 0" 0 "$T4A_EXIT"
# Should print WARN (not FAIL) for drift
assert_contains "non-strict shows WARN for drift" "WARN" "$T4A_OUT"

echo ""
echo "Test 4b: drift with --strict → exit 1"

set +e
T4B_OUT="$(node "$SCRIPT" --root "$T4_ROOT" --strict 2>&1)"
T4B_EXIT=$?
set -e

assert_exit "drift strict → exit 1" 1 "$T4B_EXIT"

# ── Test 5: missing mirror (superset rule) → exit 0 ─────────────────────────

echo ""
echo "Test 5: skill in src but absent from mirror surface → exit 0 (superset rule)"

T5_ROOT="$(mktemp -d)"
trap 'rm -rf "$T5_ROOT"' EXIT

mk_skill "$T5_ROOT" "src/skills" "only-in-src" "$CLEAN_SKILL_CONTENT"
# Create the .claude/skills surface dir but WITHOUT the skill in it
mkdir -p "$T5_ROOT/.claude/skills"

set +e
T5_OUT="$(node "$SCRIPT" --root "$T5_ROOT" 2>&1)"
T5_EXIT=$?
set -e

assert_exit "missing mirror → exit 0 (superset rule)" 0 "$T5_EXIT"
assert_contains "reports MISSING as INFO not error" "MISSING" "$T5_OUT"

# ── Test 6: --json flag → parseable JSON ────────────────────────────────────

echo ""
echo "Test 6: --json produces parseable JSON with corruption/drift/missing keys"

T6_ROOT="$(mktemp -d)"
trap 'rm -rf "$T6_ROOT"' EXIT

mk_skill "$T6_ROOT" "src/skills" "json-skill" "$CLEAN_SKILL_CONTENT"
mk_skill "$T6_ROOT" ".claude/skills" "json-skill" "$CLEAN_SKILL_CONTENT"

set +e
T6_JSON="$(node "$SCRIPT" --root "$T6_ROOT" --json 2>/dev/null)"
T6_EXIT=$?
set -e

assert_exit "--json clean tree exits 0" 0 "$T6_EXIT"

T6_PARSE="$(node -e "
  const j = JSON.parse(process.argv[1]);
  const req = ['ok','corruption','drift','missing'];
  const miss = req.filter(k => !(k in j));
  if (miss.length) { console.error('missing keys: ' + miss.join(', ')); process.exit(1); }
  if (!('findings' in j.corruption)) { console.error('corruption.findings missing'); process.exit(1); }
  if (!('findings' in j.drift)) { console.error('drift.findings missing'); process.exit(1); }
  console.log('ok=' + j.ok + ' corruption=' + j.corruption.count + ' drift=' + j.drift.count);
" "$T6_JSON" 2>&1)"
T6_PARSE_EXIT=$?

if [ "$T6_PARSE_EXIT" -eq 0 ]; then
  pass "--json parseable with correct structure ($T6_PARSE)"
else
  fail "--json structure: $T6_PARSE"
fi

# ── Test 7: absent mirror surface → skip gracefully ─────────────────────────

echo ""
echo "Test 7: absent mirror surface (.codex/skills doesn't exist) → skip gracefully, exit 0"

T7_ROOT="$(mktemp -d)"
trap 'rm -rf "$T7_ROOT"' EXIT

mk_skill "$T7_ROOT" "src/skills" "skill-x" "$CLEAN_SKILL_CONTENT"
# Only create .claude/skills — no .codex/skills, no .factory/skills, no .agents/skills
mk_skill "$T7_ROOT" ".claude/skills" "skill-x" "$CLEAN_SKILL_CONTENT"

set +e
T7_OUT="$(node "$SCRIPT" --root "$T7_ROOT" 2>&1)"
T7_EXIT=$?
set -e

assert_exit "absent mirror surface → exit 0" 0 "$T7_EXIT"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "---------------------------"
echo "Results: $PASS passed, $FAIL failed"
echo ""

[ "$FAIL" -gt 0 ] && exit 1 || exit 0
