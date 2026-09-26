---
name: run-marketing
description: "Run Track orchestrator: Run Track — Marketing (M1–M10) — sequential steps with daily task emission"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

**Host interaction contract:** Resolve listed skills through the installed catalog before project-local paths. `AskUserQuestion` means the host's supported question mechanism; if unavailable, ask in a normal response and stop for an actual answer. Explicit unattended authorization for this run permits delegated local phases, with assumptions recorded; silence is never approval and this does not authorize publishing, spending, or production changes. Tool names in examples must be mapped to available host capabilities.

# /run-marketing — Run Track — Marketing (M1–M10)

**On start, announce:** "Starting Run Track for marketing. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **marketing**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-m-1-gtm-audit` | M1 GTM Audit |
| 2 | `/run-m-2-avatar-positioning` | M2 Avatar + Positioning |
| 3 | `/run-m-3-stack-tracking` | M3 Stack + Tracking |
| 4 | `/run-m-4-messaging-system` | M4 Messaging System |
| 5 | `/run-m-5-channel-plan` | M5 Channel Plan |
| 6 | `/run-m-6-content-engine` | M6 Content Engine |
| 7 | `/run-m-7-lifecycle-email` | M7 Lifecycle Email |
| 8 | `/run-m-8-launch-runbook` | M8 Launch Runbook |
| 9 | `/run-m-9-optimize-cadence` | M9 Optimize Cadence |
| 10 | `/run-m-10-retention-loop` | M10 Retention Loop |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-marketing` resume on next session
</goal>

---

## Trigger

- Default: After Step 11 PRDs approved OR Step 1 complete (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.marketing` in `.sigma/run-track.json`. Next step = first missing in: ['M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8', 'M9', 'M10']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8', 'M9', 'M10'] is in `completed_steps.marketing`:

1. Announce: "Marketing Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
