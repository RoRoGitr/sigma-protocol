#!/usr/bin/env bash
# detect-cli.sh — Single source of truth for detecting which coding CLI is active.
#
# Usage:
#   detect-cli.sh              # prints one of: claude / codex / droid / auggie / unknown
#   detect-cli.sh --verbose    # also prints detection reason to stderr
#   detect-cli.sh --check=<cli> # exits 0 if active CLI matches <cli>, exits 1 otherwise
#   detect-cli.sh --help       # prints this help
#
# Detection priority (first match wins):
#   1. Claude Code: CLAUDECODE_ENTRYPOINT set OR any CLAUDE_CODE_* var present
#   2. Codex:       CODEX_EXEC=1            OR any CODEX_*          var present
#   3. Droid:       DROID_SESSION_ID set    OR any FACTORY_*        var present
#   4. Auggie:      AUGMENT_SESSION_AUTH set
#   5. Unknown:     nothing matched (exit 0 — caller decides what to do)
#
# Contract:
#   - Exit code 0 always
#   - Outputs exactly one lowercase token + newline (no trailing whitespace)
#   - Read-only: touches no files, no env mutations, no side effects

set -euo pipefail

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
if [[ "${1-}" == "--help" || "${1-}" == "-h" ]]; then
  grep '^#' "$0" | sed 's/^# \?//'
  exit 0
fi

# ---------------------------------------------------------------------------
# Parse flags
# ---------------------------------------------------------------------------
VERBOSE=false
CHECK_CLI=""

for arg in "$@"; do
  case "$arg" in
    --verbose) VERBOSE=true ;;
    --check=*) CHECK_CLI="${arg#--check=}" ;;
    --help|-h) ;; # already handled above
    *) echo "detect-cli.sh: unknown flag: $arg" >&2; exit 0 ;;
  esac
done

# ---------------------------------------------------------------------------
# Detection helpers
# ---------------------------------------------------------------------------

# Return true if any env var matching the prefix exists
_has_prefix() {
  local prefix="$1"
  # Use env + grep; safe because we own the prefix pattern
  env | grep -q "^${prefix}" 2>/dev/null
}

verbose() {
  if [[ "$VERBOSE" == true ]]; then
    echo "detect-cli: $*" >&2
  fi
}

# ---------------------------------------------------------------------------
# Detection logic (priority order)
# ---------------------------------------------------------------------------

detect_cli() {
  # 1. Claude Code
  if [[ -n "${CLAUDECODE_ENTRYPOINT-}" ]]; then
    verbose "matched CLAUDECODE_ENTRYPOINT=${CLAUDECODE_ENTRYPOINT}"
    echo "claude"
    return
  fi
  if _has_prefix "CLAUDE_CODE_"; then
    verbose "matched CLAUDE_CODE_* env var"
    echo "claude"
    return
  fi

  # 2. Codex
  if [[ "${CODEX_EXEC-}" == "1" ]]; then
    verbose "matched CODEX_EXEC=1"
    echo "codex"
    return
  fi
  if _has_prefix "CODEX_"; then
    verbose "matched CODEX_* env var"
    echo "codex"
    return
  fi

  # 3. Droid (Factory)
  if [[ -n "${DROID_SESSION_ID-}" ]]; then
    verbose "matched DROID_SESSION_ID=${DROID_SESSION_ID}"
    echo "droid"
    return
  fi
  if _has_prefix "FACTORY_"; then
    verbose "matched FACTORY_* env var"
    echo "droid"
    return
  fi

  # 4. Auggie
  if [[ -n "${AUGMENT_SESSION_AUTH-}" ]]; then
    verbose "matched AUGMENT_SESSION_AUTH (value redacted)"
    echo "auggie"
    return
  fi

  # 5. Unknown — not an error
  verbose "no matching env vars found"
  echo "unknown"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
DETECTED="$(detect_cli)"

# --check=<cli> mode: silent, exit code only
if [[ -n "$CHECK_CLI" ]]; then
  if [[ "$DETECTED" == "$CHECK_CLI" ]]; then
    exit 0
  else
    exit 1
  fi
fi

echo "$DETECTED"
exit 0
