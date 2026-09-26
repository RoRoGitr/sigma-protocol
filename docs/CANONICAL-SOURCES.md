# Canonical Sources

Sigma Protocol has one rule: **author in canon, generate only what the OSS install needs.**

The OSS install ships a single surface — no per-vendor mirror trees.

## What is authored by hand

| Canonical source | Holds |
|------------------|-------|
| `steps/` (0–15, plus 1.5 and 11.5) | Methodology step contracts — phases, HARD-GATEs, `<!-- SKILLS-INVOKE -->` |
| `steps/_partials/` | Shared blocks inlined into steps at sync time |
| `src/skills/<category>/<skill>/SKILL.md` | Authored skill bundles (Step 13 and methodology pool) |
| `src/agents/<category>/<agent>.md` | Authored project-agent examples (Step 13); not the source for the bundled Claude runtime roster |
| `.agents/skills/<skill>/SKILL.md` | Bundled methodology skill pool (includes step pointer stubs) |
| `.claude/agents/` | Bundled Claude runtime roster; a Claude-specific runtime package, not a generated mirror of `src/agents/` |
| `AGENTS.md` | Step 12 project brain — cross-agent context for any CLI |

Claude Code reads the tracked `CLAUDE.md`, which imports `@AGENTS.md`. Codex reads `AGENTS.md` and its own native adapters. Operators may add local CLI config (hooks, MCP, permissions); those are not portable policy between CLIs.

## What is generated (never hand-edit)

| Generated surface | Built from | By |
|-------------------|-----------|-----|
| `commands/` | `steps/` + `steps/_partials/` | `scripts/sync-steps-to-platforms.sh` |
| `.sigma/indexes/commands-index.json` | `commands/`, `steps/` | `scripts/generate-sigma-indexes.mjs` |
| `.sigma/indexes/skills-index.json` | `src/skills/`, `.agents/skills/` | `scripts/generate-sigma-indexes.mjs` |
| `.sigma/indexes/agents-index.json` | `src/agents/` | `scripts/generate-sigma-indexes.mjs` |
| `.agents/skills/step-*` pointer stubs | `steps/` | `scripts/sync-agents-step-pointers.py` |

Editing a generated file is a bug. The next sync overwrites it. Fix the canonical source and re-run sync.

## Sync commands

```bash
# Render steps → commands/
bash scripts/sync-steps-to-platforms.sh --prune

# Regenerate step skill pointer stubs in .agents/skills/
python3 scripts/sync-agents-step-pointers.py

# Rebuild machine-readable indexes
node scripts/generate-sigma-indexes.mjs

# Validate wiring
node scripts/verify/validate-step-wiring.mjs
bash scripts/audit-platform-parity.sh
```

## Partials

A step inlines a shared block with a single line:

```
<!-- include: _partials/writing-standards.md -->
```

At sync time the inliner replaces that line with the partial's contents. The canonical `steps/` file keeps the short include marker; `commands/` gets the full expanded text. Triplicated prose (writing standards, SigmaHQ tracking, holes gate) lives in exactly one place.

## Skill layout

| Path | Role |
|------|------|
| `src/skills/<category>/<skill>/SKILL.md` | Authored project skills (Step 13 output) |
| `.agents/skills/<skill>/SKILL.md` | Bundled methodology pool + step pointers |
| `.codex/skills/<skill>/SKILL.md` | Optional Codex compatibility adapter only — not canonical |

When a step lists skills in `<!-- SKILLS-INVOKE -->`, read `src/skills/<skill>/SKILL.md` at the listed phase. If missing locally, check `.agents/skills/` or promote from `templates/skills/`.

## Invocation split (user- vs model-invoked)

- **User-invoked (orchestrator surfaces).** Slash commands under `commands/` (rendered from `steps/`) and ops workflow commands. A human runs them; the model does not auto-fire them.
- **Model-invoked (reusable knowledge).** Skills under `src/skills/` and `.agents/skills/`. Loaded when a step's `SKILLS-INVOKE` block or agent binding references them.

## Legacy mirrors (deprecated)

Directories such as `platforms/`, `.claude/commands/`, `.cursor/commands/`, `.factory/commands/`, and per-vendor skill mirrors may still exist in older checkouts. They are **not** updated by sync scripts anymore. See [PLATFORMS.md](./PLATFORMS.md) for cleanup commands.

Do not edit mirror files — change `steps/` or `src/skills/` and re-run sync.

## Related docs

- [PLATFORMS.md](./PLATFORMS.md) — platform-agnostic reference
- [FOUNDATION-SKILLS.md](./FOUNDATION-SKILLS.md) — bundled skill catalog
- [EXTERNAL-SKILLS.md](./EXTERNAL-SKILLS.md) — external skill integration
