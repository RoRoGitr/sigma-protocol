#!/usr/bin/env bash
# Run Track gap-analysis loop — regenerate, sync, patch registry, verify until 100%.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MAX="${1:-5}"
WAVE="${2:-4}"

for ((i=1; i<=MAX; i++)); do
  echo "=== Run Track gap loop iteration $i/$MAX (wave=$WAVE) ==="
  python3 scripts/generate-run-track-steps.py
  ./scripts/sync-steps-to-platforms.sh
  python3 scripts/patch-run-track-registry.py
  if node scripts/verify-run-track.mjs "--wave=$WAVE" --deep; then
    echo "=== Run Track gap loop PASSED at iteration $i ==="
    exit 0
  fi
  echo "=== Iteration $i failed — fix and retry ==="
done

echo "=== Run Track gap loop FAILED after $MAX iterations ==="
exit 1
