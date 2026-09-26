#!/usr/bin/env bash
# Hermetic tests for the tier-1 feature-branch path added to
# scripts/pipeline/pipeline-check.sh (+ pre-commit-gate.sh's pass-through).
#
# Proves:
#   (a) feature branch, clean staged diff  -> tier-1 pass, exit 0, no
#       .pipeline-state.json ever written.
#   (b) feature branch, banned marker in staged diff -> tier-1 block, exit 2.
#   (c) main branch, no .pipeline-state.json -> STILL fail-closed, exit 2
#       (unchanged main/master behavior).
#   (d) main branch, .pipeline-state.json present but gates incomplete ->
#       STILL blocked, exit 2 (unchanged).
#
# Each case runs in its own throwaway git repo so the real repo's
# .pipeline-state.json is never touched.

set -u
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$REPO_ROOT/scripts/pipeline/pipeline-check.sh"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  ok: $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

new_repo() {
  local dir
  dir="$(mktemp -d)"
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Test"
  echo "$dir"
}

echo "== pipeline-check.sh tier-1 feature-branch path =="

# (a) feature branch, clean diff -> pass, no state file written
W="$(new_repo)"
git -C "$W" checkout -q -b feature/tier1-clean
echo "console.log('hello')" > "$W/file.js"
git -C "$W" add file.js
OUT_A="$(cd "$W" && bash "$CHECK" 2>&1)"; EXIT_A=$?
if [[ "$EXIT_A" -eq 0 ]] && [[ ! -f "$W/.pipeline-state.json" ]]; then
  ok "(a) clean feature-branch commit passes tier-1, no state file written"
else
  bad "(a) exit=$EXIT_A state_file_exists=$([[ -f "$W/.pipeline-state.json" ]] && echo yes || echo no) out=$OUT_A"
fi
rm -rf "$W"

# (b) feature branch, banned marker in staged diff -> blocked
W="$(new_repo)"
git -C "$W" checkout -q -b feature/tier1-banned
echo "// TODO: fix this later" > "$W/file.js"
git -C "$W" add file.js
OUT_B="$(cd "$W" && bash "$CHECK" 2>&1)"; EXIT_B=$?
if [[ "$EXIT_B" -eq 2 ]] && echo "$OUT_B" | grep -q "banned marker"; then
  ok "(b) banned marker (TODO) in staged diff blocks tier-1 commit"
else
  bad "(b) exit=$EXIT_B out=$OUT_B"
fi
rm -rf "$W"

# (c) main branch, no .pipeline-state.json -> still fail-closed
W="$(new_repo)"
git -C "$W" checkout -q -b main
echo "console.log('hello')" > "$W/file.js"
git -C "$W" add file.js
OUT_C="$(cd "$W" && bash "$CHECK" 2>&1)"; EXIT_C=$?
if [[ "$EXIT_C" -eq 2 ]] && echo "$OUT_C" | grep -qi "No .pipeline-state.json found"; then
  ok "(c) main branch with no checkpoint file still fails closed"
else
  bad "(c) exit=$EXIT_C out=$OUT_C"
fi
rm -rf "$W"

# (d) main branch, checkpoint present but gates incomplete -> still blocked
W="$(new_repo)"
git -C "$W" checkout -q -b main
echo "console.log('hello')" > "$W/file.js"
git -C "$W" add file.js
printf '{"change_counter":0,"worktree_fingerprint":"","has_frontend_changes":false,"commit_allowed":false,"gates":{}}\n' > "$W/.pipeline-state.json"
OUT_D="$(cd "$W" && bash "$CHECK" 2>&1)"; EXIT_D=$?
if [[ "$EXIT_D" -eq 2 ]] && echo "$OUT_D" | grep -q "anti_slop gate"; then
  ok "(d) main branch with incomplete gates still blocked (unchanged 7-gate behavior)"
else
  bad "(d) exit=$EXIT_D out=$OUT_D"
fi
rm -rf "$W"

echo ""
echo "passed: $PASS  failed: $FAIL"
[[ "$FAIL" -eq 0 ]] && echo "All tests passed." || exit 1
