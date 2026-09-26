---
name: run-ops
description: "Run Track orchestrator: Run Track — Ops (O1–O8) — sequential steps with daily task emission"
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

# /run-ops — Run Track — Ops (O1–O8)

**On start, announce:** "Starting Run Track for ops. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **ops**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-o-1-ops-baseline` | O1 Ops Baseline Audit |
| 2 | `/run-o-2-sprint-rhythm` | O2 Sprint + Backlog Rhythm |
| 3 | `/run-o-3-release-gates` | O3 Release + QA Gates |
| 4 | `/run-o-4-observability` | O4 Observability Minimum |
| 5 | `/run-o-5-incident-response` | O5 Incident Response |
| 6 | `/run-o-6-wbr` | O6 Weekly Business Review |
| 7 | `/run-o-7-sop-vendors` | O7 SOP + Vendor Registry |
| 8 | `/run-o-8-contractor-onboarding` | O8 Contractor Onboarding |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-ops` resume on next session
</goal>

---

## Trigger

- Default: After Step 11 or first @dev-loop sprint (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.ops` in `.sigma/run-track.json`. Next step = first missing in: ['O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7', 'O8']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['O1', 'O2', 'O3', 'O4', 'O5', 'O6', 'O7', 'O8'] is in `completed_steps.ops`:

1. Announce: "Ops Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
