#!/usr/bin/env bash
# Hermetic regression test for --sync-pool skill-root detection.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

pass=0
fail=0

ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1" >&2; fail=$((fail + 1)); }

assert_file() {
  if [[ -f "$1" ]]; then ok "$2"; else bad "$2 ($1 missing)"; fi
}

assert_absent() {
  if [[ ! -e "$1" ]]; then ok "$2"; else bad "$2 ($1 exists)"; fi
}

mkdir -p "$FIXTURE/scripts" "$FIXTURE/src/skills/real-skill/references" \
  "$FIXTURE/src/skills/real-skill/templates" "$FIXTURE/src/skills/support-only"
cp "$REPO_ROOT/scripts/sync-skills-to-platforms.sh" "$FIXTURE/scripts/"
printf '%s\n' '# Real skill' > "$FIXTURE/src/skills/real-skill/SKILL.md"
printf '%s\n' 'linked reference' > "$FIXTURE/src/skills/real-skill/references/guide.md"
printf '%s\n' 'template' > "$FIXTURE/src/skills/real-skill/templates/input.txt"
printf '%s\n' 'support document only' > "$FIXTURE/src/skills/support-only/notes.md"
printf '%s\n' '# Legacy skill' > "$FIXTURE/src/skills/legacy-flat.md"

dry_run="$(bash "$FIXTURE/scripts/sync-skills-to-platforms.sh" --sync-pool --dry-run)"
assert_absent "$FIXTURE/.agents" "dry-run leaves the pool untouched"
if [[ "$dry_run" == *"real-skill"* && "$dry_run" == *"legacy-flat.md"* && "$dry_run" != *"support-only"* ]]; then
  ok "dry-run lists only skill roots and legacy flat skills"
else
  bad "dry-run promoted a support document or omitted a source skill"
fi

bash "$FIXTURE/scripts/sync-skills-to-platforms.sh" --sync-pool >/dev/null
assert_file "$FIXTURE/.agents/skills/real-skill/SKILL.md" "copies the skill entrypoint"
assert_file "$FIXTURE/.agents/skills/real-skill/references/guide.md" "preserves nested references"
assert_file "$FIXTURE/.agents/skills/real-skill/templates/input.txt" "preserves non-Markdown support files"
assert_file "$FIXTURE/.agents/skills/legacy-flat/SKILL.md" "preserves explicit legacy flat skill"
assert_absent "$FIXTURE/.agents/skills/support-only" "does not promote support-only directories"

before="$(find "$FIXTURE/.agents/skills" -type f -exec shasum {} \; | sort)"
bash "$FIXTURE/scripts/sync-skills-to-platforms.sh" --sync-pool >/dev/null
after="$(find "$FIXTURE/.agents/skills" -type f -exec shasum {} \; | sort)"
if [[ "$before" == "$after" ]]; then
  ok "second sync is idempotent"
else
  bad "second sync changed the pool"
fi

COLLISION_FIXTURE="$(mktemp -d)"
mkdir -p "$COLLISION_FIXTURE/scripts" "$COLLISION_FIXTURE/src/skills/dev/shared" "$COLLISION_FIXTURE/src/skills/ops/shared"
cp "$REPO_ROOT/scripts/sync-skills-to-platforms.sh" "$COLLISION_FIXTURE/scripts/"
printf '%s\n' '# dev' > "$COLLISION_FIXTURE/src/skills/dev/shared/SKILL.md"
printf '%s\n' '# ops' > "$COLLISION_FIXTURE/src/skills/ops/shared/SKILL.md"
if bash "$COLLISION_FIXTURE/scripts/sync-skills-to-platforms.sh" --sync-pool >/dev/null 2>&1; then
  bad "duplicate skill roots fail before sync"
elif [[ -e "$COLLISION_FIXTURE/.agents" ]]; then
  bad "duplicate skill roots leave no pool writes"
else
  ok "duplicate skill roots fail before pool writes"
fi
rm -rf "$COLLISION_FIXTURE"

echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
