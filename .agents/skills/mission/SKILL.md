---
name: mission
description: "Dispatcher for the /mission command family. Routes mission lifecycle operations to the appropriate subcommand. Explains what each subcommand does, when to use it, and how it relates to the halt oracle and stack resolver. Triggers: mission, /mission, start mission, switch mission, complete mission, list missions."
tags: [mission, lifecycle, dispatcher, sigmahq]
allowed-tools:
  - Read
  - Bash
---

# Mission Dispatcher

The mission system persists a declared north-star outcome across sessions and compactions. It answers "what are we trying to accomplish and when are we done?" — the ceiling above PRDs, sprints, and kanban tasks.

## When to Invoke

- User types `/mission` without a subcommand
- User says "start mission", "switch mission", "complete mission", "list missions"
- Any ambiguous mission-related request before routing to a specific subcommand

## Subcommand Reference

| Subcommand | Purpose | When to use |
|---|---|---|
| `/mission new` | Interactive wizard: author mission.json + mission.md | Starting a new project or outcome |
| `/mission list` | List all missions grouped by workspace | Getting an overview across all projects |
| `/mission status` | Show active mission for current workspace | Checking progress during a session |
| `/mission resume` | Re-inject context and offer next action | Starting work after a gap or compaction |
| `/mission switch {slug}` | Change active mission (updates symlink) | Pivoting to a different outcome |
| `/mission complete` | Run halt oracle, require human signoff, archive | Declaring a mission done |
| `/mission archive {slug}` | Move inactive mission to archive/ with reason | Retiring without completion |
| `/mission reconcile` | Scan kanban + PRDs, output gap report | Audit alignment before a sprint |

## Storage Contract

```
<configured-mission-store>/
├── active/{workspace-slug}    ← symlink to current mission dir
├── archive/{slug}/            ← completed/abandoned missions
└── {slug}/
    ├── mission.json           ← machine-readable (schema-validated)
    ├── mission.md             ← human-readable prose
    ├── ledger.jsonl           ← append-only OODA log
    └── research-findings.jsonl
```

**Single-writer rule:** use the configured mission store. If the private
`~/.commandboard/missions/` store and its helpers are absent, this command is a
Claude-local extension; do not create a universal store or pretend the helpers exist.

## Halt Oracle (key invariant)

The mission **never auto-completes**. `/mission complete` is the only path to completion. It requires:
1. All `machine_checks[]` pass (or are latched)
2. All `soft_criteria[]` answered `"yes"` by a human
3. Human confirmation through the host's available question mechanism

Machine check tri-state: `"pass" | "fail" | "unknown" | null`. Unknown ≠ fail if `latched_pass=true`.

## Stack Resolver

Missions form a DAG. When the local `mission-stack.py` helper is installed, it
validates and resolves halt cascades:
- Halting a parent halts all active descendants
- Halting a child returns control to parent or next sibling
- At most one active leaf per workspace at any time

```bash
~/.claude/scripts/mission-stack.py --list-tree {workspace-slug}
~/.claude/scripts/mission-stack.py --halt {slug} --reason complete
~/.claude/scripts/mission-stack.py --validate {slug}
```

## Lifecycle

```
draft → active ↔ paused → completed
                         ↘ abandoned
```

## Usage

When called without arguments, show the subcommand table above and ask:
"Which operation do you need: new, list, status, resume, switch, complete, archive, or reconcile?"
