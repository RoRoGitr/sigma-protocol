# Mission System Specification

**Status:** Draft v1.0
**Date:** 2026-04-20
**Authors:** Operator + Claude
**Applies to:** Sigma Protocol Steps 0-15 + SigmaHQ command board

---

## 1. Purpose

The Mission System adds a persistent **outcome layer** above Steps 0-15. It answers "what are we trying to accomplish, and when are we done?" — the question neither MASTER_PRD.md, backlogs, nor kanban tasks persist across compactions and sessions.

Before this spec, `/dev-loop` terminated when "backlog empty." After this spec, it terminates on **mission-complete OR backlog-empty, whichever comes first**.

## 2. Lifecycle

```
draft → active → (paused ↔ active) → completed
                                   ↘ abandoned
```

- **Draft** — authored but not adopted. Can be edited freely.
- **Active** — loop drivers honor it. Symlink `missions/active/{workspace}` points here.
- **Paused** — loop suspended, ledger preserved, re-enterable.
- **Completed** — halt oracle fired AND human signed off. Moved to `missions/archive/`.
- **Abandoned** — mission retired without completion for historical record.

## 3. Storage

Canonical location: `~/.commandboard/missions/{slug}/` on SigmaHQ.

```
{slug}/
├── mission.json         # Machine-readable, matches mission.schema.json
├── mission.md           # Human-readable, matches mission-template.md
├── ledger.jsonl         # Append-only OODA log
└── research-findings.jsonl   # mission-autoresearch output (if enabled)
```

Active pointer: `~/.commandboard/missions/active/{workspace-slug}` — symlink to `{slug}/`.

Mirrors (read-only, automated):
- Obsidian vault: concept doc at `<operator knowledge vault>/concepts/mission-system.md (operator-local, optional)`
- Snapshot mirrors: an operator-local snapshot vault (optional)

## 4. Schema

See `~/.commandboard/missions/_schema/mission.schema.json` for the authoritative JSON Schema. Key fields:

| Field | Type | Purpose |
|---|---|---|
| `id` | slug | Unique per workspace |
| `title` | string | Human outcome statement |
| `workspace` | `category/project` | SigmaHQ workspace path |
| `parent_id` | string \| null | Stacking (parent pointer) |
| `children[]` | string[] | Stacking (child pointers) |
| `status` | enum | Lifecycle state |
| `deadline` | date | Soft deadline |
| `budget` | { usd, tokens, hours } | Resource caps |
| `constraints.do_not_touch[]` | path[] | Never-modify paths |
| `machine_checks[]` | predicate[] | Runnable deterministic checks |
| `soft_criteria[]` | LLM-assessed[] | Human-signoff-required criteria |
| `halt_on[]` | enum[] | Conditions that end the loop |
| `auto_research` | config | Exa-powered background research |

## 5. Halt Oracle

**Hybrid.** Mission is "done" when **all** hold:

1. Every `machine_checks[]` entry evaluates true
2. Every `soft_criteria[]` entry has `last_answer == "yes"` and `last_check` within 24h
3. Human has run `/mission complete {slug}` with confirmation

The system **never** auto-completes. Machine-pass without human signoff keeps the mission active.

## 6. Stacking Rules

- Missions form a DAG per workspace via `parent_id` + `children[]`
- Exactly one active leaf per workspace (`missions/active/{workspace}` symlink)
- Halting a parent halts all active descendants (cascade)
- Halting a child returns control to parent if no other child is active
- Cycles rejected at write time by `mission-stack.py --validate`
- Cross-workspace missions live under `missions/missions/{slug}` (workspace category = "missions")

## 7. Integration with Steps 0-15

### Step 0.5 (new) — Mission Articulation

Inserted between Step 0 (Environment Setup) and Step 1 (Ideation).

- Purpose: elicit the north-star outcome before ideation diverges
- Output: `~/.commandboard/missions/{slug}/mission.{json,md}` + active symlink
- Hard gate: human approval of mission statement + success criteria
- Skip condition: explicit user opt-out or mission pre-authored

### Step 1 (modified) — Phase F: Mission linkage

Adds a Phase F at end of Step 1 that:
1. Reads the active mission (if any)
2. Annotates MASTER_PRD.md with `mission_id` frontmatter
3. Confirms ideation scope falls within mission constraints (`do_not_touch`, tier gate)

### Dev-loop (modified) — Mission-exit gate

Loop terminates on:
- `backlog_empty` (existing) — all kanban tasks complete
- `mission_halted` (new) — halt oracle fires AND human signs off
- Whichever comes first

Before each iteration, loop checks:
- Active mission exists?
- Halt oracle status?
- Budget remaining?

Emits structured log: `.sigma/orchestration/mission-progress.jsonl`.

### /continue (modified) — Mission-aware preflight

Before resuming:
1. Detect workspace from CWD
2. Read active mission
3. Offer: "Resume mission {id} ({progress}%), or switch to different work?"
4. If no mission, fall through to legacy /continue behavior

### /next (modified) — Mission-weighted task selection

Task scoring priority:
1. Tasks referencing active mission (mission_id match) — highest
2. Tasks in workspace with active mission but no reference — medium
3. Tasks unrelated to mission — low
4. Out-of-scope tasks (violates constraints.do_not_touch) — flagged, never auto-picked

## 8. Session Hooks

### `~/.claude/hooks/mission-session-start.sh` (new)

Runs on SessionStart **before** `vault-context-loader.sh`. Flow:

1. Detect workspace from CWD
2. Read `missions/active/{workspace-slug}` symlink
3. If absent → exit silently
4. If present → read mission.json, compute progress + stale status
5. Branch:
   - **Desktop + fresh (<24h since last check)** → silent status banner
   - **Desktop + stale (≥24h)** → emit banner + flag for interactive check-in on first assistant turn
   - **SSH/print mode** → silent banner + append deferred check-in to `~/.claude/.ssh-pending.md`

Hook timeout: 5 seconds.

### `autoresearch-gated.sh` (updated)

Tail of autoresearch invokes `mission-autoresearch.py` to run per-mission Exa queries.

## 9. Command Surface

| Command | Purpose |
|---|---|
| `/mission new` | Interactive wizard: author mission.{json,md}, set active symlink |
| `/mission list` | All missions across workspaces |
| `/mission status` | Active mission for CWD workspace + progress |
| `/mission resume` | Re-inject context, run reconcile, offer to execute |
| `/mission switch {slug}` | Change active mission (updates symlink) |
| `/mission complete` | Run halt oracle, require human signoff, archive |
| `/mission archive {slug}` | Move to archive with reason |
| `/mission reconcile` | Scan kanban + PRDs, output gap report |
| `/mission edit` | Edit mission.json (opens in $EDITOR, validates schema on save) |
| `/mission pause` / `/mission resume` | Toggle loop execution without archiving |

## 10. Dashboard

`sync-dashboard.sh` scans `missions/` and aggregates into `briefing.json.missions[]`:

```json
{
  "missions": [
    {
      "slug": "ship-my-product-v1",
      "workspace": "products/my-product",
      "title": "...",
      "status": "active",
      "progress_pct": 42,
      "machine_checks_passing": "3/5",
      "soft_criteria_answered": "2/4",
      "last_ledger_entry": "2026-04-20T19:30:00Z",
      "days_to_deadline": 42,
      "budget_usd_remaining": 1450.23
    }
  ]
}
```

`dashboard.html` renders an "Active Missions" widget at the top of the kanban view. Read-only.

## 11. Backwards Compatibility

- **Step 0.5 is optional.** Existing projects without a mission continue to work unchanged.
- **Dev-loop mission-exit gate is additive.** With no mission, behavior is unchanged (terminates on backlog-empty).
- **/continue and /next fall through** to legacy behavior when no mission is active.
- **Kanban schema is unchanged.** Mission linkage is via `mission_id` field added to task YAML frontmatter — optional, ignored by kanban-md CLI.

## 12. Security & Privacy

- Missions live in `~/.commandboard/missions/` (local, not cloud-synced)
- `constraints.do_not_touch[]` enforced by reconciliation scan + orchestrator guidance
- `auto_research.keywords[]` sent to Exa — avoid PII/confidential terms. Warnings at authoring time.
- Tier gate references link to `ecosystem-monetization-map.md` for boundary enforcement

## 13. Acceptance Criteria

1. `mission.schema.json` validates a sample mission with all fields
2. `/mission new` wizard produces valid mission.{json,md}
3. SessionStart hook injects banner for active mission, silent for none
4. `/dev-loop` halts on mission-complete (tested with toy machine_check)
5. Dashboard shows active missions in new widget
6. Global CLAUDE.md references mission concept
7. Step 0.5 command authors a valid mission

## 14. Migration

Projects with existing MASTER_PRD.md:

1. Run `/mission new --from-prd docs/specs/MASTER_PRD.md`
2. Wizard extracts outcome statement + constraints from PRD
3. Human approves / edits
4. mission.{json,md} written, active symlink set
5. Optionally: `/mission reconcile` to retrofit `mission_id` into existing kanban tasks

## 15. Out of Scope (for v1)

- Cross-project missions spanning multiple workspaces as equals (v1 uses `missions/missions/` category for these)
- Template-per-project-type missions (v1 uses the generic template)
- Mission-driven agent DNA evolution (out of scope; `evolve.py` stays skill/agent-focused)
- Real-time web dashboard for missions (static briefing.json + dashboard.html sufficient)
- Gamification / streak tracking for mission progress (v2)

## 16. References

- SigmaHQ contract: `~/.commandboard/missions/_schema/README.md`
- Obsidian concept: `<operator knowledge vault>/concepts/mission-system.md (operator-local, optional)`
- Plan of record: `~/.claude/plans/so-it-d-be-both-optimized-shannon.md`
- Karpathy autoresearch pattern: `<operator knowledge vault>/research/ (operator-local, optional)`
