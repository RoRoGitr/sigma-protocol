#!/usr/bin/env bash
# tests/test_sigma_upgrade.sh — bash unit tests for scripts/sigma-upgrade.sh
#
# Run: bash tests/test_sigma_upgrade.sh
# All 6 tests must pass; any failure exits with non-zero summary.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPGRADE="$SCRIPT_DIR/scripts/sigma-upgrade.sh"
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

# ── Helpers ────────────────────────────────────────────────────

# Create a minimal git repo that mimics sigma-protocol layout.
# Sets TMPDIR_REPO in caller scope.
make_test_repo() {
  local tmpdir
  tmpdir="$(mktemp -d)"

  # Init git
  git -C "$tmpdir" init -q
  git -C "$tmpdir" config user.email "test@sigma.test"
  git -C "$tmpdir" config user.name "Test"

  # Minimal files the upgrade script needs
  echo "3.0.0" > "$tmpdir/VERSION"

  mkdir -p "$tmpdir/.sigma"
  mkdir -p "$tmpdir/scripts"

  # Minimal CHANGELOG.md
  cat > "$tmpdir/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased]

## [3.0.1] - 2026-05-24

### Added
- sigma-upgrade.sh

## [3.0.0] - 2026-05-23

### Added
- Initial 3.0 release
EOF

  # Stub installer (no-op — won't be called in dry-run tests)
  cat > "$tmpdir/scripts/install-sigmahq.sh" <<'INSTALLER'
#!/usr/bin/env bash
# Stub installer for tests
echo "stub-installer: called with args: $*"
exit 0
INSTALLER
  chmod +x "$tmpdir/scripts/install-sigmahq.sh"

  # Stub migration script
  cat > "$tmpdir/scripts/migrate-prds-to-3.0.py" <<'MIGRATOR'
#!/usr/bin/env python3
# Stub migration script for tests
import sys
args = sys.argv[1:]
if '--dry-run' in args:
    print("would_upgrade: 0")
sys.exit(0)
MIGRATOR
  chmod +x "$tmpdir/scripts/migrate-prds-to-3.0.py"

  # Copy the actual upgrade script into the test repo
  cp "$UPGRADE" "$tmpdir/scripts/sigma-upgrade.sh"
  chmod +x "$tmpdir/scripts/sigma-upgrade.sh"

  # Initial commit so git log works
  git -C "$tmpdir" add .
  git -C "$tmpdir" commit -q -m "initial"

  # Add a remote pointing at the repo itself (so fetch doesn't fail for tests
  # that don't need a real remote — tests that do need network are skipped or
  # mocked separately)
  git -C "$tmpdir" remote add origin "$tmpdir"

  TMPDIR_REPO="$tmpdir"
}

write_marker() {
  local repo="$1"
  local version="${2:-3.0.0}"
  local commit
  commit="$(git -C "$repo" rev-parse --short HEAD)"
  mkdir -p "$repo/.sigma"
  cat > "$repo/.sigma/installed-version" <<EOF
{
  "version": "$version",
  "installed_at": "2026-05-23T10:00:00Z",
  "commit": "$commit",
  "install_method": "fresh",
  "previous_version": null,
  "previous_commit": null,
  "pipeline_gates_installed": true,
  "settings_json_patched": true
}
EOF
}

# ── Test 1: --help exits 0 and mentions all flags ─────────────
test_help_prints_usage() {
  local output exit_code
  exit_code=0
  output="$(bash "$UPGRADE" --help 2>&1)" || exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    _fail "test_help_prints_usage" "--help exited $exit_code, expected 0"
    return
  fi

  local missing=()
  for flag in "--dry-run" "--yes" "--from" "--help"; do
    if ! echo "$output" | grep -q -- "$flag"; then
      missing+=("$flag")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    _fail "test_help_prints_usage" "--help output missing flags: ${missing[*]}"
    return
  fi

  _pass "test_help_prints_usage"
}

# ── Test 2: --dry-run does not apply git pull ─────────────────
test_dry_run_no_changes() {
  local TMPDIR_REPO=""
  make_test_repo
  local repo="$TMPDIR_REPO"

  write_marker "$repo"

  # Record HEAD before
  local head_before
  head_before="$(git -C "$repo" rev-parse HEAD)"

  local output exit_code
  exit_code=0
  output="$(cd "$repo" && bash scripts/sigma-upgrade.sh --dry-run --yes 2>&1)" || exit_code=$?

  # HEAD should not have changed
  local head_after
  head_after="$(git -C "$repo" rev-parse HEAD)"

  rm -rf "$repo"

  if [ "$exit_code" -ne 0 ]; then
    _fail "test_dry_run_no_changes" "--dry-run exited $exit_code (expected 0). output: $output"
    return
  fi

  if [ "$head_before" != "$head_after" ]; then
    _fail "test_dry_run_no_changes" "git HEAD changed during --dry-run (should not pull)"
    return
  fi

  if ! echo "$output" | grep -qi "dry.run"; then
    _fail "test_dry_run_no_changes" "--dry-run output did not mention dry-run mode"
    return
  fi

  _pass "test_dry_run_no_changes"
}

# ── Test 3: user declines → exit 0 + "No changes made." ───────
test_user_declines_exits_cleanly() {
  local TMPDIR_REPO=""
  make_test_repo
  local repo="$TMPDIR_REPO"

  write_marker "$repo"

  local output exit_code
  exit_code=0
  output="$(cd "$repo" && echo "n" | bash scripts/sigma-upgrade.sh 2>&1)" || exit_code=$?

  rm -rf "$repo"

  if [ "$exit_code" -ne 0 ]; then
    _fail "test_user_declines_exits_cleanly" "Expected exit 0 on decline, got $exit_code"
    return
  fi

  if ! echo "$output" | grep -qi "no changes made"; then
    _fail "test_user_declines_exits_cleanly" "Expected 'No changes made.' in output, got: $output"
    return
  fi

  _pass "test_user_declines_exits_cleanly"
}

# ── Test 4: missing marker treated as pre-3.0 ─────────────────
test_marker_missing_treated_as_pre30() {
  local TMPDIR_REPO=""
  make_test_repo
  local repo="$TMPDIR_REPO"

  # Deliberately do NOT write a marker
  rm -f "$repo/.sigma/installed-version"

  local output exit_code
  exit_code=0
  output="$(cd "$repo" && bash scripts/sigma-upgrade.sh --dry-run --yes 2>&1)" || exit_code=$?

  rm -rf "$repo"

  if [ "$exit_code" -ne 0 ]; then
    _fail "test_marker_missing_treated_as_pre30" "Exited $exit_code, expected 0. output: $output"
    return
  fi

  if ! echo "$output" | grep -qi "pre-3.0"; then
    _fail "test_marker_missing_treated_as_pre30" "Expected 'pre-3.0' in output when marker missing. got: $output"
    return
  fi

  _pass "test_marker_missing_treated_as_pre30"
}

# ── Test 5: --from overrides marker version in output ─────────
test_from_flag_overrides_marker() {
  local TMPDIR_REPO=""
  make_test_repo
  local repo="$TMPDIR_REPO"

  # Write marker with 3.0.0
  write_marker "$repo" "3.0.0"

  local output exit_code
  exit_code=0
  output="$(cd "$repo" && bash scripts/sigma-upgrade.sh --dry-run --yes --from 2.5.0 2>&1)" || exit_code=$?

  rm -rf "$repo"

  if [ "$exit_code" -ne 0 ]; then
    _fail "test_from_flag_overrides_marker" "Exited $exit_code, expected 0. output: $output"
    return
  fi

  if ! echo "$output" | grep -q "2.5.0"; then
    _fail "test_from_flag_overrides_marker" "Expected '2.5.0' in output when --from 2.5.0 passed. got: $output"
    return
  fi

  _pass "test_from_flag_overrides_marker"
}

# ── Test 6: unknown flag exits 2 with usage hint ──────────────
test_unknown_flag_exits_2() {
  local output exit_code
  exit_code=0
  output="$(bash "$UPGRADE" --bogus-flag 2>&1)" || exit_code=$?

  if [ "$exit_code" -ne 2 ]; then
    _fail "test_unknown_flag_exits_2" "Expected exit 2 for unknown flag, got $exit_code"
    return
  fi

  if ! echo "$output" | grep -qi "usage\|unknown\|invalid"; then
    _fail "test_unknown_flag_exits_2" "Expected usage hint in output, got: $output"
    return
  fi

  _pass "test_unknown_flag_exits_2"
}

# ── Runner ─────────────────────────────────────────────────────
echo ""
echo "sigma-upgrade.sh — unit tests"
echo "────────────────────────────────────────────────────────"

run_test "test_help_prints_usage"           test_help_prints_usage
run_test "test_dry_run_no_changes"          test_dry_run_no_changes
run_test "test_user_declines_exits_cleanly" test_user_declines_exits_cleanly
run_test "test_marker_missing_treated_as_pre30" test_marker_missing_treated_as_pre30
run_test "test_from_flag_overrides_marker"  test_from_flag_overrides_marker
run_test "test_unknown_flag_exits_2"        test_unknown_flag_exits_2

echo ""
echo "────────────────────────────────────────────────────────"
echo "Results: $TESTS_PASS passed, $TESTS_FAIL failed"

if [ "$TESTS_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
