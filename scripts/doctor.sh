#!/usr/bin/env bash
# doctor.sh — one-command health check for a Sigma Protocol checkout.
# Runs every validation gate and prints a single PASS/FAIL summary.
set -u
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0; FAIL=0
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  \033[32mPASS\033[0m  %s\n' "$label"; PASS=$((PASS+1))
  else
    printf '  \033[31mFAIL\033[0m  %s   (re-run: %s)\n' "$label" "$*"; FAIL=$((FAIL+1))
  fi
}

echo "Sigma Protocol doctor — $REPO_ROOT"
check "cascade + registry (departments, agents, skills, steps)" node scripts/validate-cascade.mjs
check "authored skills frontmatter + agent refs" node scripts/validate-skills.mjs
check "steps/ ↔ commands/ parity" bash scripts/lint-step-parity.sh
check "step wiring (18 steps)" node scripts/verify/validate-step-wiring.mjs
check "run track (8 orchestrators, 64 steps)" node scripts/verify-run-track.mjs
check "no deprecated step language" bash scripts/lint-deprecated-step-refs.sh
check "single-surface contract (no mirror drift)" bash scripts/audit-oss-drift.sh
check "platform parity" bash scripts/audit-platform-parity.sh

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "All $PASS checks green — the install is healthy."
else
  echo "$FAIL of $((PASS+FAIL)) checks failed — re-run the failing command above to see details."
  exit 1
fi
