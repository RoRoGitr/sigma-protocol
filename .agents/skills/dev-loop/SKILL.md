---
name: dev-loop
description: "Execute all unbuilt PRDs in dependency order via /sigma-dispatch --all. Thin wrapper around the CLI-native primitive."
---

# @dev-loop v5.0.0 — Thin wrapper around /sigma-dispatch

## What it does

Resolves the unbuilt PRD set (or a range), then invokes `/sigma-dispatch --all` to fire them sequentially via the active CLI's native primitive.

State tracked in `.sigma/orchestration/dev-loop-state.json` so Ctrl-C survives + resume works.

## Usage

```bash
@dev-loop                              # implement all unbuilt PRDs in dependency order
@dev-loop --from F01 --to F05          # range
@dev-loop --batch auth-sprint          # named batch (from Step 11.5 PRD swarm output)
@dev-loop --dry-run                    # show plan, don't execute
@dev-loop --status                     # show current orchestration state
@dev-loop --reset                      # clear state file (restart from scratch)
@dev-loop --help                       # this
```

## Execution flow

1. Read all PRDs in `docs/prds/*.md` (skip `flows/` — those are Step 5 prototypes)
2. Filter to unbuilt (status != `done` per `docs/prds/.prd-status.json`)
3. Apply range / batch filters if supplied
4. Topological-sort by `mission.preconditions` dependency graph (canonical schema field)
5. Verify all 3 dispatch bundles exist for each PRD (claude/codex/droid). If missing, emit them via the 3 emitter scripts first.
6. Write `.sigma/orchestration/dev-loop-state.json` with the planned order + start timestamp
7. Invoke `bash scripts/sigma-dispatch.sh --all`
8. On each PRD completion, update the state file
9. On Ctrl-C: state file preserved — `@dev-loop` next invocation resumes from where it left off

## State file shape

```json
{
  "started_at": "2026-05-23T20:45:00Z",
  "active_cli": "claude",
  "planned_order": ["F01.001", "F01.002", "F02.001"],
  "completed": ["F01.001"],
  "failed": [],
  "in_progress": "F01.002",
  "last_update": "2026-05-23T21:12:00Z"
}
```

## Failure handling

- Per-PRD failure -> log + mark in state.failed + CONTINUE (don't halt the whole loop)
- 3+ consecutive failures -> halt + write summary + exit non-zero (something systemic is broken)
- Pipeline gate failures inside individual PRD dispatches -> handled by /sigma-dispatch, not @dev-loop

## When NOT to use @dev-loop

- Single PRD work -> use `/sigma-dispatch <prd-id>` directly
- Diagnostic / debugging -> `@dev-loop --dry-run` to see the plan, then run PRDs individually
- Sprint planning -> use `/ops:sprint-plan`, not @dev-loop

## What was removed in v5

- Custom 11-phase verify-prd inner loop (now handled by 8 pipeline gates per commit)
- Per-PRD @implement-prd -> @verify-prd -> fix-gap dispatch (now handled by /sigma-dispatch + emitter bundles)
- Custom Opus orchestrator + Sonnet worker dispatch (now handled by each CLI's internal subagents)
- ~24KB of orchestration scaffolding (replaced by ~50 lines of state tracking + a /sigma-dispatch --all invocation)
