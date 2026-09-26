#!/usr/bin/env bash
# test-detect-cli.sh — Unit tests for scripts/detect-cli.sh
#
# Pattern: each test runs detect-cli.sh in a clean subshell with specific env vars set.
# Asserts stdout equals expected token. Tallies PASS/FAIL and exits 1 if any FAIL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/../detect-cli.sh"

PASS=0
FAIL=0

assert_equal() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$actual" == "$expected" ]]; then
    echo "  PASS  $test_name"
    ((PASS++)) || true
  else
    echo "  FAIL  $test_name — expected='$expected' got='$actual'"
    ((FAIL++)) || true
  fi
}

# ---------------------------------------------------------------------------
# Case 1: Claude Code — CLAUDECODE_ENTRYPOINT
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      CLAUDECODE_ENTRYPOINT="/usr/local/bin/claude" \
      bash "$DETECT"
)
assert_equal "claude via CLAUDECODE_ENTRYPOINT" "claude" "$result"

# ---------------------------------------------------------------------------
# Case 2: Claude Code — CLAUDE_CODE_* prefix
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      CLAUDE_CODE_SESSION_ID="abc123" \
      bash "$DETECT"
)
assert_equal "claude via CLAUDE_CODE_* prefix" "claude" "$result"

# ---------------------------------------------------------------------------
# Case 3: Codex — CODEX_EXEC=1
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      CODEX_EXEC="1" \
      bash "$DETECT"
)
assert_equal "codex via CODEX_EXEC=1" "codex" "$result"

# ---------------------------------------------------------------------------
# Case 4: Droid — DROID_SESSION_ID
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      DROID_SESSION_ID="session-xyz" \
      bash "$DETECT"
)
assert_equal "droid via DROID_SESSION_ID" "droid" "$result"

# ---------------------------------------------------------------------------
# Case 4b: Droid — FACTORY_* prefix
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      FACTORY_MISSION_ID="mission-001" \
      bash "$DETECT"
)
assert_equal "droid via FACTORY_* prefix" "droid" "$result"

# ---------------------------------------------------------------------------
# Case 5: Auggie — AUGMENT_SESSION_AUTH
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      AUGMENT_SESSION_AUTH="token-abc" \
      bash "$DETECT"
)
assert_equal "auggie via AUGMENT_SESSION_AUTH" "auggie" "$result"

# ---------------------------------------------------------------------------
# Case 6: Unknown — no matching env vars
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      bash "$DETECT"
)
assert_equal "unknown — no matching vars" "unknown" "$result"

# ---------------------------------------------------------------------------
# Case 7: Priority — Claude beats Codex when both set
# ---------------------------------------------------------------------------
result=$(
  env -i HOME="$HOME" PATH="$PATH" \
      CLAUDECODE_ENTRYPOINT="/usr/local/bin/claude" \
      CODEX_EXEC="1" \
      bash "$DETECT"
)
assert_equal "priority: claude beats codex" "claude" "$result"

# ---------------------------------------------------------------------------
# Case 8: --check flag exits 0 on match
# ---------------------------------------------------------------------------
check_exit=0
env -i HOME="$HOME" PATH="$PATH" \
    CODEX_EXEC="1" \
    bash "$DETECT" --check=codex || check_exit=$?
if [[ $check_exit -eq 0 ]]; then
  echo "  PASS  --check=codex exits 0 on match"
  ((PASS++)) || true
else
  echo "  FAIL  --check=codex should exit 0 but got $check_exit"
  ((FAIL++)) || true
fi

# ---------------------------------------------------------------------------
# Case 9: --check flag exits 1 on mismatch
# ---------------------------------------------------------------------------
check_exit=0
env -i HOME="$HOME" PATH="$PATH" \
    CODEX_EXEC="1" \
    bash "$DETECT" --check=claude || check_exit=$?
if [[ $check_exit -eq 1 ]]; then
  echo "  PASS  --check=claude exits 1 on mismatch"
  ((PASS++)) || true
else
  echo "  FAIL  --check=claude should exit 1 but got $check_exit"
  ((FAIL++)) || true
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
