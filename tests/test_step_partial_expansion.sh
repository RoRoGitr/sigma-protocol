#!/usr/bin/env bash
# Hermetic regression coverage for recursive step partial rendering.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1" >&2; fail=$((fail + 1)); }

mkdir -p "$FIXTURE/scripts/lib" "$FIXTURE/steps/_partials" "$FIXTURE/commands"
cp "$REPO_ROOT/scripts/sync-steps-to-platforms.sh" "$FIXTURE/scripts/"
cp "$REPO_ROOT/scripts/lint-step-parity.sh" "$FIXTURE/scripts/"
cp "$REPO_ROOT/scripts/lib/step-partials.sh" "$FIXTURE/scripts/lib/"

# Nested partials render fully, including the current Step 12 handoff chain.
actual_render="$(mktemp)"
trap 'rm -rf "$FIXTURE" "$actual_render"' EXIT
source "$REPO_ROOT/scripts/lib/step-partials.sh"
expand_step_partials "$REPO_ROOT/steps/step-12-context-engine" "$actual_render" "$REPO_ROOT/steps"
if grep -q 'step-verify-handoff.md' "$actual_render"; then
  bad "actual Step 12 leaves a nested partial unresolved"
else
  ok "actual Step 12 recursively expands step-verify handoff"
fi

cat > "$FIXTURE/steps/step-one" <<'EOF'
<!-- include: _partials/outer.md -->
EOF
cat > "$FIXTURE/steps/_partials/outer.md" <<'EOF'
<!-- include: _partials/inner.md -->
EOF
cat > "$FIXTURE/steps/_partials/inner.md" <<'EOF'
<!-- SKILLS-INVOKE:start -->
skill: test
<!-- SKILLS-INVOKE:end -->
EOF
mkdir -p "$FIXTURE/.agents/skills/step-one"
printf '%s\n' '---' 'name: step-one' 'canonical_source: "steps/step-one"' '---' 'Read references/step.md.' > "$FIXTURE/.agents/skills/step-one/SKILL.md"

bash "$FIXTURE/scripts/sync-steps-to-platforms.sh" >/dev/null
if cmp -s "$FIXTURE/commands/step-one.md" "$FIXTURE/.agents/skills/step-one/references/step.md"; then
  ok "step bundle carries the full rendered contract for installation elsewhere"
else
  bad "step bundle is missing its rendered contract"
fi
if grep -qE '^[[:space:]]*<!--[[:space:]]*include:' "$FIXTURE/commands/step-one.md"; then
  bad "sync leaves nested include unresolved"
else
  ok "sync recursively expands nested partials"
fi

printf '\nbody drift\n' >> "$FIXTURE/commands/step-one.md"
if bash "$FIXTURE/scripts/lint-step-parity.sh" >"$FIXTURE/lint.log" 2>&1; then
  bad "parity lint accepted drift outside the skill block"
else
  if grep -q 'command body differs' "$FIXTURE/lint.log"; then
    ok "parity lint rejects body drift outside the skill block"
  else
    bad "parity lint failed for an unexpected reason"
  fi
fi

printf '%s\n' '<!-- include: _partials/inner.md -->' > "$FIXTURE/commands/step-one.md"
set +e
lint_output="$(bash "$FIXTURE/scripts/lint-step-parity.sh" 2>&1)"
lint_status=$?
set -e
if [[ "$lint_status" -ne 0 && "$lint_output" == *"unresolved partial include"* ]]; then
  ok "parity lint rejects unresolved command includes"
else
  bad "parity lint did not reject unresolved command include"
fi

printf '%s\n' '<!-- include: _partials/missing.md -->' > "$FIXTURE/steps/step-missing"
printf '%s\n' 'existing command' > "$FIXTURE/commands/step-missing.md"
set +e
missing_output="$(bash "$FIXTURE/scripts/sync-steps-to-platforms.sh" 2>&1)"
missing_status=$?
set -e
if [[ "$missing_status" -ne 0 && "$missing_output" == *"missing partial"* && "$(<"$FIXTURE/commands/step-missing.md")" == 'existing command' ]]; then
  ok "missing partial fails without overwriting its command"
else
  bad "missing partial did not fail safely"
fi

rm -f "$FIXTURE/steps/step-missing" "$FIXTURE/commands/step-missing.md"
printf '%s\n' '<!-- include: _partials/cycle-b.md -->' > "$FIXTURE/steps/_partials/cycle-a.md"
printf '%s\n' '<!-- include: _partials/cycle-a.md -->' > "$FIXTURE/steps/_partials/cycle-b.md"
printf '%s\n' '<!-- include: _partials/cycle-a.md -->' > "$FIXTURE/steps/step-cycle"
set +e
cycle_output="$(bash "$FIXTURE/scripts/sync-steps-to-platforms.sh" 2>&1)"
cycle_status=$?
set -e
if [[ "$cycle_status" -ne 0 && "$cycle_output" == *"partial include cycle"* ]]; then
  ok "partial cycle fails clearly"
else
  bad "partial cycle did not fail clearly"
fi

rm -f "$FIXTURE/steps/step-cycle"
printf '%s\n' '<!-- include: _partials/./outer.md -->' > "$FIXTURE/steps/step-alias"
if bash "$FIXTURE/scripts/sync-steps-to-platforms.sh" >"$FIXTURE/alias.log" 2>&1; then
  bad "renderer accepted an ambiguous partial path"
elif grep -q 'invalid partial path' "$FIXTURE/alias.log"; then
  ok "renderer rejects dot-segment partial paths"
else
  bad "ambiguous partial path failed for an unexpected reason"
fi

echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
