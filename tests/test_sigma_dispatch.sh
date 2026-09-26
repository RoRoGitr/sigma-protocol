#!/usr/bin/env bash
# tests/test_sigma_dispatch.sh — bash unit tests for scripts/sigma-dispatch.sh
#
# Run: bash tests/test_sigma_dispatch.sh
# All 6 tests must pass; any failure exits with non-zero summary.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISPATCH="$SCRIPT_DIR/scripts/sigma-dispatch.sh"
TESTS_PASS=0
TESTS_FAIL=0

# ---------------------------------------------------------------------------
# Test harness — use += not (( )) to avoid exit-code-1-on-zero trap
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Test 1: unknown CLI refuses with exit 1 + helpful error message
# ---------------------------------------------------------------------------
test_unknown_cli_refuses() {
  local output exit_code

  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" bash "$DISPATCH" F01.001 2>&1)
  exit_code=$?
  set -e

  if [[ $exit_code -eq 1 ]]; then
    _pass "unknown CLI exits 1"
  else
    _fail "unknown CLI exits 1" "Got exit code: $exit_code"
  fi

  if echo "$output" | grep -qi "cannot detect\|unknown\|CLAUDECODE_ENTRYPOINT\|CODEX_EXEC\|DROID_SESSION_ID"; then
    _pass "unknown CLI prints helpful error with env var hints"
  else
    _fail "unknown CLI prints helpful error with env var hints" "Output was: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 2: auggie CLI refuses with 'not supported' message
# ---------------------------------------------------------------------------
test_auggie_refuses() {
  local output exit_code

  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" AUGMENT_SESSION_AUTH=fake123 bash "$DISPATCH" F01.001 2>&1)
  exit_code=$?
  set -e

  if [[ $exit_code -eq 1 ]]; then
    _pass "auggie CLI exits 1"
  else
    _fail "auggie CLI exits 1" "Got exit code: $exit_code"
  fi

  if echo "$output" | grep -qi "auggie\|manual dispatch\|not supported"; then
    _pass "auggie prints 'manual dispatch only' message"
  else
    _fail "auggie prints 'manual dispatch only' message" "Output was: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 3: invalid PRD ID prints helpful error with docs/prds reference
# ---------------------------------------------------------------------------
test_missing_prd_helpful_error() {
  local output exit_code

  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" CLAUDECODE_ENTRYPOINT=1 bash "$DISPATCH" NONEXISTENT-PRD-ZZQQ --dry-run 2>&1)
  exit_code=$?
  set -e

  if [[ $exit_code -eq 1 ]]; then
    _pass "missing PRD exits 1"
  else
    _fail "missing PRD exits 1" "Got exit code: $exit_code"
  fi

  if echo "$output" | grep -qi "not found\|did you mean\|docs/prds"; then
    _pass "missing PRD prints helpful error with docs/prds reference"
  else
    _fail "missing PRD prints helpful error with docs/prds reference" "Output was: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 4: PRD exists but bundle missing → suggests emit command
# F01.001 exists, but we use codex env where bundle may not exist.
# Also create a guaranteed no-bundle PRD to make this deterministic.
# ---------------------------------------------------------------------------
test_missing_bundle_suggests_emit() {
  local output exit_code

  # Create a temporary PRD with no dispatch bundle. The fixture dir may not
  # exist in a clean checkout — create it and remember whether we made it.
  local tmp_prd_dir="$SCRIPT_DIR/docs/prds/wave-1"
  local made_dir=0
  if [[ ! -d "$tmp_prd_dir" ]]; then
    mkdir -p "$tmp_prd_dir"
    made_dir=1
  fi
  local tmp_prd="$tmp_prd_dir/TESTONLY-NOBUNDLE-001.md"
  echo "# TESTONLY-NOBUNDLE-001: No bundle test fixture" > "$tmp_prd"

  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" CLAUDECODE_ENTRYPOINT=1 bash "$DISPATCH" TESTONLY-NOBUNDLE-001 --dry-run 2>&1)
  exit_code=$?
  set -e

  # Clean up fixture (and the dir if this test created it)
  rm -f "$tmp_prd"
  if [[ $made_dir -eq 1 ]]; then rmdir "$tmp_prd_dir" 2>/dev/null || true; fi

  if [[ $exit_code -eq 1 ]]; then
    _pass "missing bundle exits 1"
  else
    _fail "missing bundle exits 1" "Got exit code: $exit_code output=$output"
  fi

  if echo "$output" | grep -qi "emit\|emitter\|emit_claude\|bundle"; then
    _pass "missing bundle suggests emit command"
  else
    _fail "missing bundle suggests emit command" "Output was: $output"
  fi
}

# ---------------------------------------------------------------------------
# Test 5: --dry-run prints command marker but does NOT fire real CLI
# Self-sufficient: creates its own PRD + claude bundle fixture, then tears down.
# ---------------------------------------------------------------------------
test_dry_run_no_execution() {
  local output exit_code

  local tmp_prd_dir="$SCRIPT_DIR/docs/prds/wave-1"
  local made_dir=0
  if [[ ! -d "$tmp_prd_dir" ]]; then
    mkdir -p "$tmp_prd_dir"
    made_dir=1
  fi
  local tmp_prd="$tmp_prd_dir/TESTONLY.002-dry-run-fixture.md"
  echo "# TESTONLY.002: dry-run test fixture" > "$tmp_prd"
  local bundle_dir="$SCRIPT_DIR/.sigma/dispatch/claude"
  mkdir -p "$bundle_dir"
  local tmp_bundle="$bundle_dir/TESTONLY.002.goal.md"
  printf '# goal\nTest-only dry-run bundle fixture.\n' > "$tmp_bundle"

  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" CLAUDECODE_ENTRYPOINT=1 bash "$DISPATCH" TESTONLY.002 --dry-run 2>&1)
  exit_code=$?
  set -e

  rm -f "$tmp_prd" "$tmp_bundle"
  if [[ $made_dir -eq 1 ]]; then rmdir "$tmp_prd_dir" 2>/dev/null || true; fi

  if [[ $exit_code -eq 0 ]]; then
    _pass "--dry-run exits 0"
  else
    _fail "--dry-run exits 0" "Got exit code: $exit_code — output: $output"
  fi

  if echo "$output" | grep -qi "dry-run\|would execute"; then
    _pass "--dry-run prints DRY-RUN marker"
  else
    _fail "--dry-run prints DRY-RUN marker" "Output was: $output"
  fi

  # The real-execution marker '[sigma-dispatch] Executing:' must NOT be present
  if ! echo "$output" | grep -q "^\[sigma-dispatch\] Executing:"; then
    _pass "--dry-run does NOT print real-execution marker"
  else
    _fail "--dry-run does NOT print real-execution marker" "Found 'Executing:' in dry-run output"
  fi
}

# ---------------------------------------------------------------------------
# Test 6: Malicious PRD-ID patterns are rejected with exit 1
# ---------------------------------------------------------------------------
test_prd_id_injection_blocked() {
  local malicious_ids=(
    "F01;rm -rf /"
    'F01$(echo pwned)'
    "F01|cat /etc/passwd"
    "../../../etc/passwd"
    "F01 --extra"
    "f01.001"
    "123BAD"
  )
  # Note: empty string tested separately to avoid bash array issues

  local all_blocked=true

  for id in "${malicious_ids[@]}"; do
    local exit_code
    set +e
    env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" CLAUDECODE_ENTRYPOINT=1 \
      bash "$DISPATCH" "$id" --dry-run > /dev/null 2>&1
    exit_code=$?
    set -e
    if [[ $exit_code -ne 1 ]]; then
      _fail "injection blocked for: '$id'" "Got exit code: $exit_code (expected 1)"
      all_blocked=false
    fi
  done

  # Test empty string separately
  local exit_code
  set +e
  env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" CLAUDECODE_ENTRYPOINT=1 \
    bash "$DISPATCH" "" --dry-run > /dev/null 2>&1
  exit_code=$?
  set -e
  if [[ $exit_code -ne 1 ]]; then
    _fail "injection blocked for empty string" "Got exit code: $exit_code (expected 1)"
    all_blocked=false
  fi

  if [[ "$all_blocked" == true ]]; then
    _pass "all 8 injection PRD-ID patterns rejected with exit 1"
  fi
}

# ---------------------------------------------------------------------------
# Test 7 (P1 REGRESSION): Droid resolves bundle by PRD slug field, not PRD-ID-kebab
#
# Reproduces Phase 5c gate 7 defect: dispatcher assumed droid bundle dir = PRD-ID
# lowercased to kebab (e.g. "f99-001"), but emit_droid_mission.py writes to the
# slug field (e.g. "my-custom-slug"). The fallback find -path "*F99.001*" also
# misses because the directory name contains no PRD-ID substring.
# ---------------------------------------------------------------------------
test_droid_resolves_bundle_by_slug() {
  local output exit_code

  # Fixture PRD JSON: prd_id F99.001, slug my-custom-slug
  local fixture_json="$SCRIPT_DIR/schemas/fixtures/F99.001-custom-slug-test.json"
  cat > "$fixture_json" <<'FIXTURE'
{
  "$schema": "../sigma-prd-canonical.schema.json",
  "prd_id": "F99.001",
  "title": "Custom slug regression test fixture",
  "slug": "my-custom-slug",
  "version": "1.0.0",
  "status": "ready",
  "wave": 99,
  "dependencies": [],
  "goal": {
    "objective": "Regression test: dispatcher must resolve Droid bundle by slug, not PRD-ID kebab.",
    "stopping_condition": "Dry-run prints path containing my-custom-slug.",
    "files_to_read_first": [],
    "proof_commands": ["echo ok"],
    "out_of_scope": []
  },
  "mission": {
    "milestone": "M99",
    "preconditions": [],
    "expected_behavior": "Given the dispatcher runs, when slug differs from PRD-ID kebab, then the correct bundle dir is used.",
    "verification_steps": ["VC-SLUG-001"],
    "fulfills": ["VC-SLUG-001"],
    "skill_name": "backend-engineer",
    "estimated_complexity": "small"
  }
}
FIXTURE

  # Stub PRD markdown so resolve_prd() finds it (create the fixture dir in a
  # clean checkout; remember whether we made it for teardown).
  local tmp_prd_dir="$SCRIPT_DIR/docs/prds/wave-1"
  local made_prd_dir=0
  if [[ ! -d "$tmp_prd_dir" ]]; then
    mkdir -p "$tmp_prd_dir"
    made_prd_dir=1
  fi
  local tmp_prd="$tmp_prd_dir/F99.001-custom-slug-test.md"
  echo "# F99.001: Custom slug regression test fixture" > "$tmp_prd"

  # Emit the droid bundle so the bundle dir is my-custom-slug/
  python3 "$SCRIPT_DIR/scripts/emitters/emit_droid_mission.py" \
    --output-dir "$SCRIPT_DIR/.sigma/dispatch/droid" \
    "$fixture_json" > /dev/null 2>&1

  # Verify the bundle was emitted to the slug-named dir (not f99-001)
  if [[ ! -f "$SCRIPT_DIR/.sigma/dispatch/droid/my-custom-slug/mission.md" ]]; then
    _fail "droid slug bundle exists at my-custom-slug/" "emitter did not create the bundle — check emit_droid_mission.py"
    rm -f "$tmp_prd" "$fixture_json"
    if [[ ${made_prd_dir:-0} -eq 1 ]]; then rmdir "$tmp_prd_dir" 2>/dev/null || true; fi
    return
  fi
  _pass "emitter wrote bundle to my-custom-slug/ (slug-named dir)"

  # Run dispatcher with DROID_SESSION_ID — this is the failing code path
  set +e
  output=$(env -i HOME="$HOME" PATH="$PATH" TMPDIR="${TMPDIR:-/tmp}" \
    DROID_SESSION_ID=test \
    bash "$DISPATCH" F99.001 --dry-run 2>&1)
  exit_code=$?
  set -e

  # Clean up all fixtures
  rm -f "$tmp_prd" "$fixture_json"
  if [[ ${made_prd_dir:-0} -eq 1 ]]; then rmdir "$tmp_prd_dir" 2>/dev/null || true; fi
  rm -rf "$SCRIPT_DIR/.sigma/dispatch/droid/my-custom-slug"

  if [[ $exit_code -eq 0 ]]; then
    _pass "droid dispatch with custom slug exits 0"
  else
    _fail "droid dispatch with custom slug exits 0" "Got exit $exit_code — output: $output"
  fi

  if echo "$output" | grep -q "my-custom-slug"; then
    _pass "droid dispatch output references my-custom-slug path"
  else
    _fail "droid dispatch output references my-custom-slug path" "Output was: $output"
  fi
}

# ---------------------------------------------------------------------------
# Run all tests from repo root
# ---------------------------------------------------------------------------
cd "$SCRIPT_DIR"

echo "=============================="
echo " sigma-dispatch.sh test suite "
echo "=============================="

run_test "test_unknown_cli_refuses"          test_unknown_cli_refuses
run_test "test_auggie_refuses"               test_auggie_refuses
run_test "test_missing_prd_helpful_error"    test_missing_prd_helpful_error
run_test "test_missing_bundle_suggests_emit" test_missing_bundle_suggests_emit
run_test "test_dry_run_no_execution"         test_dry_run_no_execution
run_test "test_prd_id_injection_blocked"     test_prd_id_injection_blocked
run_test "test_droid_resolves_bundle_by_slug" test_droid_resolves_bundle_by_slug

echo ""
echo "=============================="
echo " Results: $TESTS_PASS passed, $TESTS_FAIL failed"
echo "=============================="

if [[ $TESTS_FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
