#!/usr/bin/env bash
# test_structural_verify.sh — hermetic test suite for scripts/verify/structural-verify.mjs
#
# Four assertions:
#   1. valid fixture   → exit 0
#   2. dangling fixture → exit 1 + stderr names the orphan screen
#   3. --json flag     → stdout is parseable JSON with ok/errors/warnings keys
#   4. missing file + --allow-missing → exit 0
#
# Exit 0 = all assertions passed. Exit 1 = first failure.
#
# Usage: bash tests/test_structural_verify.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFIER="$REPO_ROOT/scripts/verify/structural-verify.mjs"
VALID_FIXTURE="$REPO_ROOT/schemas/fixtures/flow-tree-valid.json"
DANGLING_FIXTURE="$REPO_ROOT/schemas/fixtures/flow-tree-dangling.json"

PASS=0
FAIL=0

# ── Assertion helpers ────────────────────────────────────────────────────────

pass() {
  echo "  PASS: $1"
  PASS=$(( PASS + 1 ))
}

fail() {
  echo "  FAIL: $1" >&2
  FAIL=$(( FAIL + 1 ))
}

assert_exit() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    pass "$label (exit $actual)"
  else
    fail "$label — expected exit $expected, got $actual"
  fi
}

assert_contains() {
  local label="$1"
  local needle="$2"
  local haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    pass "$label (contains '$needle')"
  else
    fail "$label — output does not contain '$needle'"$'\n'"  Output was:"$'\n'"$haystack"
  fi
}

# ── Guard: node must be present ──────────────────────────────────────────────

if ! command -v node &>/dev/null; then
  echo "FAIL: node is not on PATH — install Node.js 20+" >&2
  exit 1
fi

echo ""
echo "structural-verify test suite"
echo "----------------------------"

# ── Test 1: valid fixture → exit 0 ──────────────────────────────────────────

echo ""
echo "Test 1: valid fixture exits 0"
set +e
T1_OUT="$(node "$VERIFIER" --file "$VALID_FIXTURE" 2>&1)"
T1_EXIT=$?
set -e
assert_exit "valid fixture" 0 "$T1_EXIT"

# ── Test 2: dangling fixture → exit 1 + names the orphan ────────────────────

echo ""
echo "Test 2: dangling fixture exits 1 and names the orphan screen"
set +e
T2_OUT="$(node "$VERIFIER" --file "$DANGLING_FIXTURE" 2>&1)"
T2_EXIT=$?
set -e
assert_exit "dangling fixture" 1 "$T2_EXIT"
# The error must mention the screen id and the missing module id
assert_contains "dangling fixture names orphan screen 'home'" "home" "$T2_OUT"
assert_contains "dangling fixture names missing module 'nonexistent-module'" "nonexistent-module" "$T2_OUT"

# ── Test 3: --json flag emits parseable JSON ─────────────────────────────────

echo ""
echo "Test 3: --json flag emits parseable JSON with ok/errors/warnings keys"
set +e
T3_JSON="$(node "$VERIFIER" --file "$DANGLING_FIXTURE" --json 2>/dev/null)"
T3_EXIT=$?
set -e

# Verify JSON parses and has required structure (using node itself — zero-dep)
T3_PARSE="$(node -e "
  const j = JSON.parse(process.argv[1]);
  const keys = ['ok', 'errors', 'warnings'];
  const missing = keys.filter(k => !(k in j));
  if (missing.length) {
    console.error('missing keys: ' + missing.join(', '));
    process.exit(1);
  }
  if (!Array.isArray(j.errors)) { console.error('errors is not array'); process.exit(1); }
  if (!Array.isArray(j.warnings)) { console.error('warnings is not array'); process.exit(1); }
  if (typeof j.ok !== 'boolean') { console.error('ok is not boolean'); process.exit(1); }
  console.log('ok=' + j.ok + ' errors=' + j.errors.length + ' warnings=' + j.warnings.length);
" "$T3_JSON" 2>&1)"
T3_PARSE_EXIT=$?

if [ "$T3_PARSE_EXIT" -eq 0 ]; then
  pass "--json output is valid JSON with ok/errors/warnings ($T3_PARSE)"
else
  fail "--json output: $T3_PARSE"
fi

# dangling fixture should report ok:false
if echo "$T3_JSON" | node -e "
  const j = JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
  process.exit(j.ok === false ? 0 : 1);
" 2>/dev/null; then
  pass "--json ok:false for dangling fixture"
else
  fail "--json ok should be false for dangling fixture"
fi

# ── Test 4: missing file + --allow-missing → exit 0 ─────────────────────────

echo ""
echo "Test 4: missing file with --allow-missing exits 0"
MISSING_PATH="/tmp/structural-verify-nonexistent-$(date +%s).json"
set +e
T4_OUT="$(node "$VERIFIER" --file "$MISSING_PATH" --allow-missing 2>&1)"
T4_EXIT=$?
set -e
assert_exit "missing file + --allow-missing" 0 "$T4_EXIT"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "----------------------------"
echo "Results: $PASS passed, $FAIL failed"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
