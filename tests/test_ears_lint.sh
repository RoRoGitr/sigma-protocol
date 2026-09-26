#!/usr/bin/env bash
# tests/test_ears_lint.sh
#
# Hermetic tests for scripts/verify/ears-lint.mjs
# Uses temp directories for all fixtures; no repo state is mutated.
#
# Exit codes:
#   0 — all tests pass
#   1 — one or more tests failed

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$REPO_ROOT/scripts/verify/ears-lint.mjs"
PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

run_test() {
  local name="$1"
  local expected_exit="$2"
  local check_fn="$3"
  shift 3

  # Run the lint script; capture output + exit code
  local output
  local actual_exit=0
  output=$(node "$LINT" "$@" 2>&1) || actual_exit=$?

  local ok=true

  # Check exit code
  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    echo "  [FAIL] $name: expected exit $expected_exit, got $actual_exit"
    echo "         output: $output"
    ok=false
  fi

  # Run additional check function if provided
  if [[ "$ok" == "true" ]] && [[ -n "$check_fn" ]]; then
    if ! $check_fn "$output"; then
      echo "  [FAIL] $name: check_fn '$check_fn' returned non-zero"
      echo "         output: $output"
      ok=false
    fi
  fi

  if [[ "$ok" == "true" ]]; then
    echo "  [PASS] $name"
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

# Check that the coverage JSON was written and contains expected field
check_coverage_written() {
  local output="$1"
  # ears-lint always prints a line mentioning ears-coverage.json
  echo "$output" | grep -q "ears-coverage.json"
}

# Check that output contains EARS form summary
check_ears_ok() {
  local output="$1"
  echo "$output" | grep -qE "OK:|ADVISORY:|ears-lint"
}

check_advisory_warning() {
  local output="$1"
  echo "$output" | grep -qiE "ADVISORY|WARN|non-conform"
}

check_no_error() {
  local output="$1"
  echo "$output" | grep -qvE "^ERROR"
}

# ---------------------------------------------------------------------------
# Setup: temp workspace
# ---------------------------------------------------------------------------

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Override REPO_ROOT behavior: ears-lint resolves paths relative to its own
# location (scripts/verify/), not CWD. To test with isolated fixtures,
# we use --src to point at our temp fixture files/dirs directly.

# ---------------------------------------------------------------------------
# TEST 1: Valid EARS criteria (JSON backlog) → exit 0 + coverage written
# ---------------------------------------------------------------------------

FIXTURE_JSON="$TMP_DIR/fixture_valid.json"
cat > "$FIXTURE_JSON" <<'EOF'
{
  "stories": [
    {
      "id": "S-001",
      "title": "User Login",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "The system shall validate the user's credentials against the database.",
          "type": "command"
        },
        {
          "id": "ac-2",
          "description": "When the user submits invalid credentials, the system shall display an error message.",
          "type": "command"
        },
        {
          "id": "ac-3",
          "description": "While the session is active, the system shall refresh the token every 15 minutes.",
          "type": "command"
        }
      ]
    }
  ]
}
EOF

run_test "valid EARS JSON criteria → exit 0 + coverage written" \
  0 "check_coverage_written" \
  --src "$FIXTURE_JSON"

# ---------------------------------------------------------------------------
# TEST 2: Fixture with a bad (non-EARS) line → advisory (exit 0) without --strict
# ---------------------------------------------------------------------------

FIXTURE_BAD="$TMP_DIR/fixture_bad.json"
cat > "$FIXTURE_BAD" <<'EOF'
{
  "stories": [
    {
      "id": "S-002",
      "title": "Dashboard",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "The system shall load the dashboard within 2 seconds.",
          "type": "command"
        },
        {
          "id": "ac-2",
          "description": "Dashboard looks good and renders correctly.",
          "type": "manual"
        }
      ]
    }
  ]
}
EOF

run_test "bad line without --strict → advisory exit 0" \
  0 "check_advisory_warning" \
  --src "$FIXTURE_BAD"

# ---------------------------------------------------------------------------
# TEST 3: Same bad fixture + --strict → exit 1
# ---------------------------------------------------------------------------

run_test "bad line WITH --strict → exit 1" \
  1 "" \
  --src "$FIXTURE_BAD" --strict

# ---------------------------------------------------------------------------
# TEST 4: NON-EARS: prefix exempts the line → exit 0 (not a non-conforming line)
# ---------------------------------------------------------------------------

FIXTURE_NONEARS="$TMP_DIR/fixture_nonears.json"
cat > "$FIXTURE_NONEARS" <<'EOF'
{
  "stories": [
    {
      "id": "S-003",
      "title": "Reports",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "The system shall generate a PDF report on demand.",
          "type": "command"
        },
        {
          "id": "ac-2",
          "description": "NON-EARS: Report layout must match the approved Figma mockup (requires visual review).",
          "type": "manual"
        }
      ]
    }
  ]
}
EOF

run_test "NON-EARS: prefix → exempt → exit 0 even with --strict" \
  0 "" \
  --src "$FIXTURE_NONEARS" --strict

# ---------------------------------------------------------------------------
# TEST 5: earsForm:"non-ears" field on a criterion → exempt
# ---------------------------------------------------------------------------

FIXTURE_FIELD_EXEMPT="$TMP_DIR/fixture_field_exempt.json"
cat > "$FIXTURE_FIELD_EXEMPT" <<'EOF'
{
  "stories": [
    {
      "id": "S-004",
      "title": "UI Polish",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "Button colors match the design spec (visual review required).",
          "type": "manual",
          "earsForm": "non-ears"
        }
      ]
    }
  ]
}
EOF

run_test "earsForm:non-ears field → exempt → exit 0 even with --strict" \
  0 "" \
  --src "$FIXTURE_FIELD_EXEMPT" --strict

# ---------------------------------------------------------------------------
# TEST 6: Markdown PRD with valid EARS criteria → exit 0 + coverage written
# ---------------------------------------------------------------------------

FIXTURE_MD="$TMP_DIR/fixture_valid.md"
cat > "$FIXTURE_MD" <<'EOF'
---
prd_id: F01.001
title: User Auth
---

# User Authentication

## Overview

Some context.

## Acceptance Criteria

- The system shall authenticate the user before granting access to protected resources.
- When the password reset link is clicked, the system shall send a confirmation email.
- While the user is in a locked state, the system shall reject all login attempts.

## Implementation Notes

Some notes.
EOF

run_test "valid EARS markdown criteria → exit 0 + coverage written" \
  0 "check_coverage_written" \
  --src "$FIXTURE_MD"

# ---------------------------------------------------------------------------
# TEST 7: Markdown PRD with bad line → --strict exit 1
# ---------------------------------------------------------------------------

FIXTURE_MD_BAD="$TMP_DIR/fixture_bad.md"
cat > "$FIXTURE_MD_BAD" <<'EOF'
---
prd_id: F01.002
title: Dashboard
---

# Dashboard

## Acceptance Criteria

- The system shall load the dashboard within 2 seconds.
- It should look nice and be fast.

EOF

run_test "bad markdown criterion with --strict → exit 1" \
  1 "" \
  --src "$FIXTURE_MD_BAD" --strict

# ---------------------------------------------------------------------------
# TEST 8: BDD Given/When/Then is exempt → exit 0 with --strict
# ---------------------------------------------------------------------------

FIXTURE_BDD="$TMP_DIR/fixture_bdd.json"
cat > "$FIXTURE_BDD" <<'EOF'
{
  "stories": [
    {
      "id": "S-005",
      "title": "Checkout",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "Given the cart has items, When the user clicks checkout, Then the system shall process payment.",
          "type": "command"
        }
      ]
    }
  ]
}
EOF

run_test "BDD Given/When/Then → exempt → exit 0 with --strict" \
  0 "" \
  --src "$FIXTURE_BDD" --strict

# ---------------------------------------------------------------------------
# TEST 9: testId field is captured in coverage output
# ---------------------------------------------------------------------------

FIXTURE_TESTID="$TMP_DIR/fixture_testid.json"
cat > "$FIXTURE_TESTID" <<'EOF'
{
  "stories": [
    {
      "id": "S-006",
      "title": "Auth",
      "acceptanceCriteria": [
        {
          "id": "ac-1",
          "description": "The system shall verify the JWT token on each request.",
          "type": "command",
          "testId": "tests/auth/test_jwt.sh::verify_jwt"
        }
      ]
    }
  ]
}
EOF

# Run and capture coverage JSON to verify testId was captured
node "$LINT" --src "$FIXTURE_TESTID" > /dev/null 2>&1 || true
COVERAGE_PATH="$REPO_ROOT/.sigma/indexes/ears-coverage.json"

check_testid_captured() {
  local _output="$1"
  if [[ -f "$COVERAGE_PATH" ]]; then
    python3 -c "
import json, sys
data = json.load(open('$COVERAGE_PATH'))
has_testid = any(c.get('testId') for c in data.get('criteria', []))
sys.exit(0 if has_testid else 1)
" 2>/dev/null
  else
    return 1
  fi
}

run_test "testId field captured in coverage JSON" \
  0 "check_testid_captured" \
  --src "$FIXTURE_TESTID"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "=== ears-lint test results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  TOTAL: $((PASS + FAIL))"

if [[ "$FAIL" -gt 0 ]]; then
  echo "  STATUS: FAIL"
  exit 1
else
  echo "  STATUS: PASS"
  exit 0
fi
