# Swarm-First Architecture

**Status:** active baseline
**Last updated:** `2026-03-05`

## Goal

Sigma supports multi-agent execution, but the orchestration model now sits on top of a clean baseline workflow instead of introducing extra pseudo-steps or Ralph-only branches.

## Canonical Ownership

| Surface | Owner |
|---|---|
| numbered methodology steps | `steps/` |
| rendered slash commands | `commands/` |
| human-facing utility commands | `ops/`, `audit/`, `dev/`, `deploy/`, `marketing/` |
| reusable skill source | `src/skills/`, `.agents/skills/` |
| reusable agent source | `src/agents/` |
| project brain | `AGENTS.md` |
| runtime scaffold | `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` |

## Active Workflow Contract

1. Run Steps `0-15` plus conditional `1.5` and `11.5`.
2. After Step 5, use `/prd-json --mode prototype`.
3. After Step 11, use `/prd-json --mode implementation`.
4. Use `/prd-orchestrate` only as a standalone orchestration command.
5. Store machine state under `.sigma/backlogs/*` and `.sigma/orchestration/*`.

## Orchestration Modes

| Mode | Purpose | Canonical surfaces |
|---|---|---|
| interactive | human-in-the-loop execution with visible checkpoints | numbered steps, `sigma status`, `sigma continue` |
| deterministic | repeatable backlog/orchestration generation | `/prd-json`, `/prd-orchestrate` |
| parallel | multi-agent or multi-terminal execution | platform-native orchestration plus `.sigma/orchestration/*` |

## Platform Priority

1. Codex
2. Claude Code
4. Cursor compatibility only

## Review Roles

Every non-trivial implementation flow should include:

- Devil's Advocate review
- Gap Analysis review
- Testing review

These are workflow requirements, not optional polish.

## Drift Prevention

The repository enforces the baseline by syncing and auditing canonical surfaces.

Current expectations:

- no `5.5`, `11.25`, or `11b` in active workflow language
- no deprecated pseudo-steps (`step-5a`, `step-5b`, `step-11a`, `step-11b`) in active workflow
- machine backlogs live under `.sigma/backlogs/*` and `.sigma/orchestration/*` only
- commands render to `commands/` via `scripts/sync-steps-to-platforms.sh`

## Compatibility Boundary

Deprecated aliases may remain callable for one release cycle, but they must stay hidden from the active workflow model and forward to canonical commands.

## Related Docs

- `docs/WORKFLOW-OVERVIEW.md`
- `docs/COMMANDS.md`
- `docs/PLATFORMS.md`
- `docs/archive/RALPH-LEGACY.md`
