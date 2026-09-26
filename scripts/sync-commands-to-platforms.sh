#!/usr/bin/env bash
# sync-commands-to-platforms.sh
# OSS single-surface: delegates step render to sync-steps-to-platforms.sh.
# Non-step command mirrors under platforms/* were removed from the install contract.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--prune] [--allow-deprecated]

Delegates to scripts/sync-steps-to-platforms.sh (steps/ -> commands/).
Platform mirror trees are no longer generated.
USAGE
}

DRY_RUN=false
PRUNE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --prune) PRUNE=true ;;
    --allow-deprecated) ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

step_args=()
$DRY_RUN && step_args+=("--dry-run")
$PRUNE && step_args+=("--prune")

echo "=== Sigma Command Sync (single-surface) ==="
exec "$SCRIPT_DIR/sync-steps-to-platforms.sh" "${step_args[@]}"
