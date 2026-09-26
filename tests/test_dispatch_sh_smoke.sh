#!/usr/bin/env bash
# tests/test_dispatch_sh_smoke.sh
# Smoke tests for dispatch.sh + agent-scanner.py canonical copies.
# These tests do NOT require Terminal.app, cmux, or a live ~/.commandboard install.
# They verify syntax, compilation, and CLI surface only.
#
# Usage: bash tests/test_dispatch_sh_smoke.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISPATCH_SH="$REPO_ROOT/templates/commandboard/dispatch.sh"
AGENT_SCANNER_PY="$REPO_ROOT/templates/commandboard/agent-scanner.py"

PASS=0
FAIL=0

run_test() {
  local name="$1"
  local result="$2"   # "pass" or "fail"
  if [[ "$result" == "pass" ]]; then
    echo "  [PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "=== dispatch.sh + agent-scanner.py smoke tests ==="
echo ""

# ── Test 1: dispatch.sh exists and is executable ──
if [[ -x "$DISPATCH_SH" ]]; then
  run_test "dispatch.sh exists + is executable" pass
else
  run_test "dispatch.sh exists + is executable" fail
  echo "        Expected: $DISPATCH_SH"
fi

# ── Test 2: bash -n syntax check ──
if bash -n "$DISPATCH_SH" 2>/dev/null; then
  run_test "dispatch.sh bash -n syntax check" pass
else
  run_test "dispatch.sh bash -n syntax check" fail
fi

# ── Test 3: dispatch.sh --help exits 0 and prints usage ──
output=$(bash "$DISPATCH_SH" --help 2>&1)
exit_code=$?
if [[ $exit_code -eq 0 && "$output" == *"SigmaHQ Dispatch Engine"* ]]; then
  run_test "dispatch.sh --help exits 0 + prints usage" pass
else
  run_test "dispatch.sh --help exits 0 + prints usage" fail
  echo "        exit_code=$exit_code"
fi

# ── Test 4: dispatch.sh no-args exits 0 and prints usage ──
output=$(bash "$DISPATCH_SH" 2>&1)
exit_code=$?
if [[ $exit_code -eq 0 && "$output" == *"Usage:"* ]]; then
  run_test "dispatch.sh no-args exits 0 + prints usage" pass
else
  run_test "dispatch.sh no-args exits 0 + prints usage" fail
  echo "        exit_code=$exit_code"
fi

# ── Test 5: dispatch.sh contains all 8 expected subcommands in usage ──
usage_output=$(bash "$DISPATCH_SH" --help 2>&1)
all_cmds_present=1
for cmd in "all" "task" "status" "stop" "review" "approve" "reject"; do
  if ! echo "$usage_output" | grep -q "$cmd"; then
    all_cmds_present=0
    echo "        Missing subcommand in usage: $cmd"
  fi
done
if [[ $all_cmds_present -eq 1 ]]; then
  run_test "dispatch.sh usage lists all 8 subcommands (all/task/status/stop/review/approve/reject)" pass
else
  run_test "dispatch.sh usage lists all 8 subcommands (all/task/status/stop/review/approve/reject)" fail
fi

# ── Test 6: agent-scanner.py exists and is executable ──
if [[ -x "$AGENT_SCANNER_PY" ]]; then
  run_test "agent-scanner.py exists + is executable" pass
else
  run_test "agent-scanner.py exists + is executable" fail
  echo "        Expected: $AGENT_SCANNER_PY"
fi

# ── Test 7: python3 -m py_compile ──
if python3 -m py_compile "$AGENT_SCANNER_PY" 2>/dev/null; then
  run_test "agent-scanner.py py_compile passes" pass
else
  run_test "agent-scanner.py py_compile passes" fail
fi

# ── Test 8: No hardcoded /Users/ in dispatch.sh ──
if ! grep -q "/Users/" "$DISPATCH_SH"; then
  run_test "dispatch.sh has no hardcoded /Users/ paths" pass
else
  run_test "dispatch.sh has no hardcoded /Users/ paths" fail
  grep -n "/Users/" "$DISPATCH_SH" | head -5
fi

# ── Test 9: No hardcoded /Users/ in agent-scanner.py ──
if ! grep -q "/Users/" "$AGENT_SCANNER_PY"; then
  run_test "agent-scanner.py has no hardcoded /Users/ paths" pass
else
  run_test "agent-scanner.py has no hardcoded /Users/ paths" fail
  grep -n "/Users/" "$AGENT_SCANNER_PY" | head -5
fi

# ── Test 10: dispatch.sh file size is in expected range (>30KB) ──
file_size=$(wc -c < "$DISPATCH_SH" | tr -d ' ')
if [[ $file_size -gt 30000 ]]; then
  run_test "dispatch.sh file size >30KB ($file_size bytes)" pass
else
  run_test "dispatch.sh file size >30KB ($file_size bytes)" fail
fi

# ── Test 11: agent-scanner.py file size is in expected range (>10KB) ──
file_size=$(wc -c < "$AGENT_SCANNER_PY" | tr -d ' ')
if [[ $file_size -gt 10000 ]]; then
  run_test "agent-scanner.py file size >10KB ($file_size bytes)" pass
else
  run_test "agent-scanner.py file size >10KB ($file_size bytes)" fail
fi

# ── Test 12: dispatch.sh references osascript (PTY launch) ──
if grep -q "osascript" "$DISPATCH_SH"; then
  run_test "dispatch.sh references osascript (PTY launch present)" pass
else
  run_test "dispatch.sh references osascript (PTY launch present)" fail
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
