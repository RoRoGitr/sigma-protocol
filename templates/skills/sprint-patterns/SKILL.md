---
name: sprint-patterns
description: Use when planning, dispatching, or executing a development sprint — including parallel agent dispatch, mock-data-first strategy, dependency unblocking, sprint breakdown format, reconciliation sprints, and multi-phase coordination. Triggers on: sprint, parallel dispatch, parallel agents, mock data, fan-out, phase breakdown, reconciliation sprint, curriculum migration, sprint execution, execution order.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Sprint Patterns

## When to Use

Use when breaking a large task into parallelizable work units, unblocking dependent agents with mock data contracts, sequencing a multi-phase migration sprint, or running a reconciliation sprint to close drift between methodology and reality.

## Core Methodology

Sprint breakdown follows one rule: identify what's actually blocked vs what only appears sequential. Most task lists have false sequencing — adjacent tasks that have no real dependency. Reorder to expose true parallelism before dispatching.

File ownership is sacred. Two agents must never edit the same file. Assign explicit file boundaries in every task description. Non-overlapping scope = zero merge conflicts.

Agents communicate through files, not memory. Handoffs use structured artifacts on disk. If a context loss occurs between phases, the file IS the handoff.

## Key Patterns

### Mock-Data Parallel Dispatch

When a project needs to show UI before APIs exist, use mock-data-first to enable parallel team dispatch:

1. Define data shapes in `mocks/` files (field names, types, edge case values). These files become the backend wiring checklist.
2. Each team builds against the same mock shapes — guarantees interface compatibility when real APIs replace mocks.
3. Teams own exclusive file paths — no two teams edit the same component.
4. Backend wiring sprint later: every `import from 'mocks/'` becomes an API call. The mock files are the conversion checklist.

Multi-feature parallel dispatch example (3 teams, 13 features in parallel):

| Team | Feature Cluster | File Scope |
|------|----------------|------------|
| Team 1 | Messaging + Social | Conversations, DMs, follow system |
| Team 2 | Travel History + Maps | Past trips, country tracking |
| Team 3 | Booking + Referral | Reservations, invite codes |

Backend wiring per feature: find all `import` from `mocks/`, replace with API calls, add loading/error states, wire real-time connections, remove mocks from production bundle.

### Sprint Dependency Analysis

Before creating a task list:
1. Map what each task actually depends on (not just what's listed before it).
2. Separate "depends on external API delivery" from "pure implementation, zero external deps."
3. Dispatch unblocked tasks immediately; explicitly queue blocked ones with their unblock condition.

Platform runtime sprint example — 4 of 6 tasks were unblocked despite linear numbering:

| Task | External Dependency | Can Start Now? |
|------|---------------------|----------------|
| #176 Trading Kit scaffold | None | Yes |
| #177 Data adapter | None | Yes |
| #178 Durable Task State | None | Yes |
| #179 Exchange list UI | None | Yes |
| #180 Credits client | Blocks on WEB-02 | No |
| #181 Binary + license | Blocks on WEB-03 | No |

### Multi-Phase Sprint with Disjoint Filesystems

For large migrations touching multiple repos/filesystems (e.g., curriculum migration across vault + web app + methodology repo):

1. Batch 1: tasks across disjoint filesystems. True parallelism — no conflicts possible.
2. Front-load audit phases before write phases. Catching stale data before writers embed it is cheaper than rewriting after recording.
3. Phase handoff: write slug inventory comment into the file being handed off. The receiving phase reads from the file, not from agent memory.

Three-layer gating sync pattern — three files must update atomically:
- `data.ts` — lesson definitions and module structure
- `pricing-config.ts` — tier gates
- `middleware.ts` — route mapping

A change to one without the others causes silent access failures.

### Reconciliation Sprint Format

Use when methodology and implementation have drifted. Entry condition: 4+ sources return different answers for the same question.

Steps:
1. 6-source consistency check — declare all sources and make them vote.
2. Identify which source is authoritative (usually the canonical data file).
3. Dispatch with 4-agent file ownership: vault-writer, frontend-worker, backend-worker, orchestrator/verification.
4. Scope pipeline gates to the sprint files only, not the full diff — prior uncommitted work dilutes review focus and produces false positives.
5. Follow with gap analysis (gap analysis loop, 2 clean rounds required) before declaring ship-ready.

Reconciliation sprint example: 6 data sources returning 4 different counts for the same entity (7, 11, 12, and a structural disagreement). 4-agent sprint resolved all sources to agree on the canonical count.

### Sprint Breakdown Format

```markdown
## Sprint: {name}
**Goal:** {what this sprint achieves}
**Entry condition:** {what must be true before starting}
**Exit condition:** {what must be true to declare done}

### Batch 1 (parallel)
- [ ] Task A — files: {owned files} — no deps
- [ ] Task B — files: {owned files} — no deps

### Batch 2 (after Batch 1)
- [ ] Task C — files: {owned files} — depends on Task A output

### Ship Gate
- [ ] All sources agree on {metric}
- [ ] Tests: N/N passing
- [ ] Migration run: {environment}
```

## Gotchas

- False sequencing is the most common sprint planning error. Always ask "what does this actually depend on?" before declaring a task blocked.
- File ownership violations cause merge conflicts that look like agent failures. Assign file boundaries in the task description.
- `MODULE_LESSON_COUNTS` in Convex mutations silently rejects progress writes for lessons beyond the old count — fails closed with no user-visible error. Update it whenever lesson counts change.
- Scope pipeline gates to the sprint diff, not the full workspace — prior uncommitted work dilutes review focus.
- If an agent fails 2 consecutive attempts: stop, diagnose, escalate. Do not retry the same approach.
- exFAT volumes: `zsh` `declare -A` unsupported. Use Python for batch operations. Two-pass rename (old → `__tmp__` → new) prevents collision.

## File Locations / Conventions

```
Sprint state:
  {repo}/.pipeline-state.json        — 8-gate pipeline status
  {repo}/.sprint-state.json          — 7-step sprint position

Application gating trio (update atomically):
  app/data/data.ts
  app/lib/pricing-config.ts
  middleware.ts

Agents communicate via:
  {repo}/.claude/handoff-{timestamp}.md  — cross-session handoffs
  {phase-output-file}.md                 — inter-phase artifacts
```

## Quality Gates

- [ ] Dependency analysis done — false sequencing removed before dispatch
- [ ] File ownership boundaries assigned to every agent, no overlaps
- [ ] Mock shapes defined before parallel dispatch (mock-data strategy)
- [ ] Phase handoffs written to files, not left in agent memory
- [ ] Three-layer gating sync (data/pricing-config/middleware) updated atomically
- [ ] Pipeline gates scoped to sprint diff, not full workspace
- [ ] Gap analysis loop: 2 consecutive clean rounds before ship

## Related

- Vault articles: `mock-data-parallel-dispatch.md`, `sprint-dependency-analysis.md`, `curriculum-reconciliation-sprint.md`
- Related skills: `prd-patterns` (PRD dispatch), `migration-patterns` (DB migration sprints)
