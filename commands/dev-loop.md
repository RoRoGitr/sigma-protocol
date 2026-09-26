---
version: "5.0.0"
last_updated: "2026-06-28"
description: "@dev-loop — implement every unbuilt PRD in dependency order via /sigma-dispatch --all, the CLI-native autonomous primitive. The single command that runs after Steps 0-15 are complete."
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --from
  - --to
  - --batch
  - --dry-run
  - --status
  - --reset
---

# @dev-loop — PRD Execution Loop (v5, CLI-native)

**The single command that turns your approved PRDs into shipped code.**

`@dev-loop` is a thin wrapper around `/sigma-dispatch --all`. It resolves the set of unbuilt PRDs, topologically sorts them by dependency, and fires each one through the operator CLI's native autonomous primitive (`/goal`, `/missions`, or equivalent). Sigma does **not** maintain its own dispatch loop, custom orchestrator, or worker pool — the active CLI uses its own internal subagents.

> This replaced the pre-v5 Sprint Execution Factory (custom Opus-orchestrator + Sonnet-worker dispatch, ~24KB of scaffolding). That scaffolding is gone: per-commit quality is enforced by the 8-gate pipeline, and parallelism is handled by each CLI's native subagents.

## When to Use

Run AFTER Step 14 (Agent Runtime Bootstrap) completes. Requires:
- Approved PRDs in `docs/prds/*.md` with `docs/prds/.prd-status.json`
- Dispatch bundles emitted (Step 11 final step) — `@dev-loop` re-emits any that are missing
- `.sigma/` runtime config present
- Git repo on the `dev` branch (create it if missing)

## Usage

```bash
@dev-loop                       # implement all unbuilt PRDs in dependency order
@dev-loop --from F01 --to F05   # PRD range
@dev-loop --batch auth-sprint   # named batch from Step 11.5 output
@dev-loop --dry-run             # show the plan, execute nothing
@dev-loop --status              # show current orchestration state
@dev-loop --reset               # clear state file (restart from scratch)
```

The command shells out to `bash scripts/dev-loop.sh` with the same flags. See `.agents/skills/dev-loop/SKILL.md` for the canonical skill.

## Execution Flow

1. Read every PRD in `docs/prds/*.md` (skip `flows/` — those are Step 5 prototypes).
2. Filter to unbuilt (status != `done` in `docs/prds/.prd-status.json`); only PRDs with `approved: true` are eligible.
3. Apply `--from/--to` range or `--batch` filter if supplied.
4. Topologically sort by the `mission.preconditions` dependency graph (canonical schema field).
5. Verify all dispatch bundles exist per PRD; if missing, run the Step 11 emitters first.
6. Write `.sigma/orchestration/dev-loop-state.json` with the planned order + start timestamp.
7. Invoke `bash scripts/sigma-dispatch.sh --all`.
8. On each PRD completion, update the state file.
9. On Ctrl-C: the state file is preserved — the next `@dev-loop` resumes from where it stopped.

## State File

`.sigma/orchestration/dev-loop-state.json`:

```json
{
  "started_at": "2026-06-28T20:45:00Z",
  "active_cli": "<detected-operator-cli>",
  "planned_order": ["F01.001", "F01.002", "F02.001"],
  "completed": ["F01.001"],
  "failed": [],
  "in_progress": "F01.002",
  "last_update": "2026-06-28T21:12:00Z"
}
```

## What `/sigma-dispatch` Enforces (per PRD)

Each dispatched PRD runs to its `goal.stopping_condition` and exits on that external check — never on the agent's say-so. Per-PRD, the pipeline enforces the Sprint Protocol:

- **Branching:** sprint work branches off `dev`; `dev` merges to `main` only via a release PR. Sprint branches are deleted after merge.
- **Mandatory review gates:** every PRD's changes pass Devil's Advocate (adversarial review) and QA (acceptance-criteria verification) before merge. These run on every dispatch, even when cross-model review is also available.
- **8-gate pipeline per commit:** Anti-Slop, UI Validation, Expect/Browser, Devils Advocate, Gap Analysis, QA Verification, Cross-Model Review, Greptile. Greptile threshold: zero critical + zero high to pass.
- **Unrelated findings** discovered during review become new tracker issues (Linear when configured, else wave-labeled GitHub Issues — label `wave:W0`; TASKS.md entries for offline tracking), not in-scope sprint fixes.

## Failure Handling

| Scenario | Action |
|----------|--------|
| Per-PRD failure | Log, mark in `state.failed`, CONTINUE (don't halt the whole loop) |
| 3+ consecutive failures | Halt, write summary, exit non-zero (something systemic is broken) |
| Pipeline gate failure inside a PRD dispatch | Handled by `/sigma-dispatch`, not `@dev-loop` |

## When NOT to Use

- Single PRD → run `/sigma-dispatch <prd-id>` directly.
- Diagnostic → `@dev-loop --dry-run` to see the plan, then run PRDs individually.
- Sprint planning → use `/ops:sprint-plan`, not `@dev-loop`.

## Related Commands

| Command | Role |
|---------|------|
| `/sigma-dispatch <prd-id>` | Fire one PRD via the operator CLI's native primitive |
| `/next-task` | Pull-based single-task execution from Step 11.5 TASKS.md |
| `/continue` | Resume interrupted work from active-task memory |
| `/status` | Show execution progress across PRDs |
| `references/execution-loops.md` | The standing Orca-native loops (BUILD w/ base-check + task-still-real gates, ORCHESTRATOR TICK w/ artifact heartbeat, TIMER, PR-SWEEP, CLEANUP w/ ownership ledger) the coordinator runs around each dispatch |

$END$
