# Sigma Protocol Versioning

**Version source of truth:** `package.json`
**Current version:** `1.0.0-alpha.1`
**Last updated:** `2026-03-05`

## Policy

Sigma uses semantic versioning, but methodology changes are treated as public interface changes.

- `MAJOR`: breaking workflow or platform contract changes
- `MINOR`: new backward-compatible commands, docs, generators, or platform support
- `PATCH`: fixes, parity repairs, and documentation corrections

## Active Workflow Registry

The active Sigma workflow is:

`0 -> 1 -> 1.5 (conditional) -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 10 -> 11 -> 12 -> 13`

Standalone commands remain outside the numbered methodology:

| Surface | Role | Output |
|---|---|---|
| `/prd-json --mode prototype` | Convert Step 5 flow PRDs | `.sigma/backlogs/prototype/prd.json` |
| `/prd-json --mode implementation` | Convert Step 11 PRDs | `.sigma/backlogs/implementation/prd.json` |
| `/prd-orchestrate` | Build orchestration plans from PRDs/backlogs | `.sigma/orchestration/*` |

## Compatibility-Only Aliases

These remain for one release cycle and must not be documented as workflow steps:

| Alias | Canonical target |
|---|---|
| `step-5b-prd-to-json` | `/prd-json --mode prototype` |
| `step-11a-prd-to-json` | `/prd-json --mode implementation` |
| `step-11b-prd-swarm` | `/prd-orchestrate` |
| `the retired legacy dispatcher` | Deprecated informational stub |

## Breaking Baseline Decisions Locked On 2026-03-05

1. Codex is the primary platform driver.
2. Claude Code is aligned in a second pass, not used as the default design source.
3. Cursor is compatibility-only.
4. Ralph is deprecated and removed from the active workflow model.
5. `.sigma/backlogs/*` replaces `docs/ralph/*` as the canonical machine backlog namespace.
6. `.agents/skills/<skill>/SKILL.md` is the official Codex skill path. `.codex/skills/<skill>/SKILL.md` is compatibility-only.

## Versioning Guidance For Future Changes

Treat any of the following as versioned public-interface changes:

- numbered step ordering or naming
- command names or alias retirement
- machine backlog path changes
- orchestration state path changes
- platform runtime folder conventions
- schema filenames consumed by generators or validators

## Related Docs

- `docs/WORKFLOW-OVERVIEW.md`
- `docs/COMMANDS.md`
- `docs/PLATFORMS.md`
- `docs/archive/RALPH-LEGACY.md`
