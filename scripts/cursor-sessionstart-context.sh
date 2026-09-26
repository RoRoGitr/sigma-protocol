#!/usr/bin/env bash
# cursor-sessionstart-context.sh
# Generate Cursor's sessionStart context injection: a single always-applied rule
# that carries the Sigma "router brain" (department keyword map + workflow spine).
#
# Cursor has no native SessionStart hook like Claude Code. Its equivalent is an
# alwaysApply:true rule that loads into every conversation. This is the ONE rule
# that defaults to always-on; every other .cursor/rules/sigma-*.mdc is
# agent-requested by description. The brain is derived from the canonical
# registry so it never drifts from Claude Code / Codex routing.
#
# Usage: bash scripts/cursor-sessionstart-context.sh [--check]
#   --check  print the rule to stdout instead of writing it (CI parity)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$PROJECT_ROOT/.claude/lib/agent-skill-registry.json"
OUT="$PROJECT_ROOT/.cursor/rules/sigma-router-brain.mdc"

CHECK=false
[[ "${1:-}" == "--check" ]] && CHECK=true

if [[ ! -f "$REGISTRY" ]]; then
  echo "cursor-sessionstart-context: registry not found: $REGISTRY" >&2
  exit 2
fi

# Render the rule body via node (registry is JSON; awk/sed on JSON is a trap).
BODY="$(node -e '
const fs = require("fs");
const reg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const depts = reg.departments || {};
const lines = [];
lines.push("# Sigma Router Brain (Cursor sessionStart)");
lines.push("");
lines.push("You are running the Sigma Protocol. `AGENTS.md` is your project brain. The numbered workflow is Steps 0-15 (plus 1.5 and 11.5); invoke a step with `/step-N-...`.");
lines.push("");
lines.push("**HITL:** use Plan mode for any multi-file or architectural change. Spawn subagents for parallel/independent work. There is no custom dispatch primitive — autonomous loops run via `/next-task` and Step 14 loop archetypes.");
lines.push("");
lines.push("**Department routing.** When a request matches a departments cue, adopt that department head and pull its bound skills (`.cursor/rules/sigma-<skill>.mdc`, agent-requested by description):");
lines.push("");
lines.push("| Department | Head | Routes on |");
lines.push("|---|---|---|");
for (const [name, d] of Object.entries(depts)) {
  const head = d.head || "-";
  // Pull a short human cue list out of the keyword regex (strip \b anchors + parens).
  let kw = (d.keywords || "").replace(/\\b/g, "").replace(/[()]/g, "");
  const cues = kw.split("|").map(s => s.trim()).filter(Boolean).slice(0, 8).join(", ");
  lines.push(`| ${name} | ${head} | ${cues} |`);
}
lines.push("");
lines.push("Match the most specific department. If none matches, stay general. Never invent a department — the canonical set is fixed.");
process.stdout.write(lines.join("\n"));
' "$REGISTRY")"

RULE="---
description: \"Sigma router brain: department routing map + workflow spine. Always loaded.\"
alwaysApply: true
---

$BODY
"

if "$CHECK"; then
  printf '%s\n' "$RULE"
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
printf '%s\n' "$RULE" > "$OUT"
echo "Wrote ${OUT#$PROJECT_ROOT/}"
