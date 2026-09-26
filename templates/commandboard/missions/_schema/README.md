# SigmaHQ Missions — Contract

## What a mission is

A **mission** is a declared north-star outcome that survives across sessions and compactions. It answers "what are we trying to accomplish?" — the ceiling above PRDs, sprints, and kanban tasks.

```
MISSION (outcome)
  ↓
PRDs (features that serve the mission)
  ↓
Sprints (time-boxed work on PRDs)
  ↓
Tasks (kanban-md units inside a sprint)
  ↓
Code
```

Without a mission, every session starts with "remind me what we're trying to do." With a mission, `/continue`, `/dev-loop`, and `/mission status` all know.

## Directory layout

```
~/.commandboard/missions/
├── _schema/                          # Contract (this dir)
│   ├── mission.schema.json           # JSON Schema for mission.json
│   ├── mission-template.md           # Human template for mission.md
│   └── README.md                     # This file
├── active/                           # Symlinks → currently-active missions
│   └── {workspace-slug}              # One symlink per workspace's active leaf
├── archive/                          # Completed/abandoned missions
│   └── {slug}/                       # Frozen snapshot
└── {slug}/                           # Each mission gets its own directory
    ├── mission.json                  # Machine-readable (matches schema)
    ├── mission.md                    # Human-readable (matches template)
    ├── ledger.jsonl                  # Append-only OODA log
    └── research-findings.jsonl       # Auto-research outputs (if enabled)
```

## Write rules (who writes what)

| Artifact | Writer | Reader |
|---|---|---|
| `{slug}/mission.json` + `mission.md` | `/mission new`, `/mission edit`, `/mission complete` | Session-start hook, `/mission status`, `/dev-loop`, `/continue`, `/next`, reconcile skill |
| `{slug}/ledger.jsonl` | Any loop iteration (append only) | `/mission status`, halt oracle |
| `{slug}/research-findings.jsonl` | `mission-autoresearch.py` (append only) | `/mission status`, reconcile skill |
| `active/{workspace-slug}` symlink | `/mission switch`, `/mission complete` | Session-start hook |
| `archive/{slug}/` | `/mission archive`, `/mission complete` | `/mission list --archived` |

**Single-writer rule:** SigmaHQ (`~/.commandboard/missions/`) is the only place where mission data is *edited*. Everything else is a mirror or read.

## Stacking

Missions form a DAG per workspace:

```
ship-my-product              ← top-level
├── build-v1-mvp             ← sub-mission (parent_id: ship-my-product)
│   └── implement-auth       ← sub-sub-mission
└── launch-landing-page      ← parallel sub-mission
```

**Per-node state (explicit, not inferred):** every mission has one of these states:
- `draft` — authored but not adopted
- `runnable` — ready to become active but not currently the leaf
- `active` — current leaf; loop drivers honor this one
- `paused` — suspended; re-enterable via `/mission resume`
- `completed` — halt oracle fired + human signoff; latched
- `abandoned` — retired without completion

**Stack invariants enforced by `mission-stack.py --validate`:**
- `parent_id` + `children[]` form a DAG (no cycles)
- At most one node has status=`active` per workspace (the active leaf)
- `active_descendant_count` = count of children with status ∈ {active, runnable, paused} + their recursive descendants

**Halt-cascade rules (deterministic resolver):**
- **Completing a child:** if parent has `active_descendant_count > 0` after decrement → switch to next runnable sibling (deterministic: lowest ID first). If `active_descendant_count == 0` → parent becomes the active leaf.
- **Halting a parent (completion or abandonment):** cascade halts all descendants in state ∈ {active, runnable, paused}. They transition to the same terminal state as the parent.
- **Abandoning a child:** no cascade up. Parent re-evaluates next leaf as if child completed, but parent's `completed` status is NOT triggered.
- **Cycles are rejected** at write time by the validator.

The active symlink (`missions/active/{workspace-slug}`) always points to the node with status=`active`. If none, the symlink is removed.

## Lifecycle

1. **Draft** — `/mission new` creates mission.json + mission.md in `{slug}/`
2. **Active** — `/mission start {slug}` flips status, creates `active/{workspace-slug}` symlink
3. **Paused** — `/mission pause` stops the loop, preserves ledger; re-enterable
4. **Completed** — halt oracle fires OR `/mission complete` called with evidence; archived + symlink removed
5. **Abandoned** — `/mission archive --reason` preserves the mission for historical record without completion

## Halt oracle

Mission is "done" when **all** of these hold:

- Every `machine_checks[]` entry has `last_result == "pass"` OR `latched_pass == true`
- Every `soft_criteria[]` entry has `last_answer == "yes"` and `last_check` within 24h
- Human has run `/mission complete` with confirmation

**Tri-state machine checks:**
- `pass` — predicate evaluated true. On first pass, `latched_pass` flips to true and `latched_at` is recorded.
- `fail` — predicate evaluated false and not latched.
- `unknown` — source file missing, command errored, URL unreachable, etc. Does NOT flip latched_pass. Treated as fail for halt oracle purposes UNLESS latched_pass is already true.

**Latching rule:** Once a machine check passes, it stays passed even if the source disappears. This prevents mission oscillation (complete → incomplete → complete) when a completion artifact is renamed or archived. To un-latch, edit the mission file manually or run `/mission edit`.

**Evidence snapshots:** Every check evaluation writes `last_evidence` (observed value or error message). The halt oracle appends a snapshot entry to `ledger.jsonl` for replay.

The oracle is **never** auto-complete based on machine checks alone. Human sign-off is always required.

## Session-start integration

**Performance budget: hook must complete in <2 seconds.** The SessionStart pipeline cannot afford a heavy hook. Mission injection is **cached-read only**: no filesystem crawls, no kanban scans, no reconciliation.

The SessionStart hook (`~/.claude/hooks/mission-session-start.sh`) reads:

1. Current workspace from CWD (fast: string match against known workspace table)
2. `active/{workspace-slug}` symlink if it exists (single stat)
3. Mission JSON — parse one file, compute progress from cached `machine_checks[].last_result`

Injects either:
- **Silent status banner** (fresh <24h or SSH mode)
- **Flagged banner with `[ACTION REQUIRED]`** (desktop + >24h stale) — the flag surfaces an `AskUserQuestion` on the FIRST assistant turn, NOT in the hook itself
- **Nothing** (no active mission for this workspace)

**Reconciliation is NEVER auto-triggered from SessionStart.** It only runs via explicit `/mission reconcile`.

## Dashboard surface

`~/.commandboard/sync-dashboard.sh` scans this directory and writes `missions[]` into `briefing.json`. `dashboard-live.html` renders active missions in a dedicated widget.

## Related

- Spec: `sigma-protocol/docs/missions/MISSION-SYSTEM-SPEC.md`
- Install script: `sigma-protocol/scripts/install-sigmahq.sh`
