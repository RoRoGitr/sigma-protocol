#!/usr/bin/env bash
# Compatibility filename. Hermetic visual-artifact contract checks, not live UI validation.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$ROOT/templates/demos/claude-design-e2e-fixture"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
passed=0
failed=0
check() { if "$@"; then passed=$((passed+1)); else echo "FAIL: $*"; failed=$((failed+1)); fi; }
nonempty_dir() { [[ -d "$1" && -n "$(find "$1" -type f -print -quit)" ]]; }
canvas_ready() {
  [[ -s "$1/source.pen" && -s "$1/preview.png" && -s "$1/VISUAL-ARTIFACT.md" ]]
}
# Existing imported fixtures remain readable; there is no requirement to recreate them.
check test -d "$FIXTURE"
check nonempty_dir "$FIXTURE/docs/prds/flows/01-auth/claude-design"
check nonempty_dir "$FIXTURE/docs/prds/flows/02-dashboard/screens"
check test -f "$FIXTURE/docs/landing-page/TEMPLATE-MAPPING.md"

# Synthetic fixture files exercise presence rules only. They are never render receipts.
mkdir -p "$TMP/flow/visual-artifact" "$TMP/flow/screens"
printf '{"fixture":true}\n' > "$TMP/flow/visual-artifact/source.pen"
printf 'SYNTHETIC EXPORT FIXTURE\n' > "$TMP/flow/visual-artifact/preview.png"
printf 'Synthetic receipt for filesystem test only.\n' > "$TMP/flow/visual-artifact/VISUAL-ARTIFACT.md"
printf '// Synthetic native prototype\n' > "$TMP/flow/screens/Screen.swift"
check canvas_ready "$TMP/flow/visual-artifact"
check nonempty_dir "$TMP/flow/screens"
for file in source.pen preview.png VISUAL-ARTIFACT.md; do
  mv "$TMP/flow/visual-artifact/$file" "$TMP/$file"
  if canvas_ready "$TMP/flow/visual-artifact"; then
    echo "FAIL: missing $file accepted"; failed=$((failed+1))
  else
    passed=$((passed+1))
  fi
  mv "$TMP/$file" "$TMP/flow/visual-artifact/$file"
done
mkdir "$TMP/empty"
if nonempty_dir "$TMP/empty"; then failed=$((failed+1)); else passed=$((passed+1)); fi
printf 'Visual artifact fixture checks: %s passed, %s failed\n' "$passed" "$failed"
echo 'No Pen export, browser interaction, screenshot match or live E2E has been claimed by this fixture suite.'
[[ "$failed" -eq 0 ]]
