---
name: run-finance
description: "Run Track orchestrator: Run Track — Finance (Fn1–Fn7) — sequential steps with daily task emission"
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

# /run-finance — Run Track — Finance (Fn1–Fn7)

**On start, announce:** "Starting Run Track for finance. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **finance**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-fn-1-unit-economics` | Fn1 Unit Economics Baseline |
| 2 | `/run-fn-2-pricing-architecture` | Fn2 Pricing Architecture |
| 3 | `/run-fn-3-forecast` | Fn3 3-Scenario Forecast |
| 4 | `/run-fn-4-cost-audit` | Fn4 Monthly Cost Audit |
| 5 | `/run-fn-5-runway` | Fn5 Runway + Triggers |
| 6 | `/run-fn-6-spend-gates` | Fn6 Spend Approval Gates |
| 7 | `/run-fn-7-data-room` | Fn7 Fundraise Data Room |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-finance` resume on next session
</goal>

---

## Trigger

- Default: After Step 1.5 (offer architecture) (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.finance` in `.sigma/run-track.json`. Next step = first missing in: ['Fn1', 'Fn2', 'Fn3', 'Fn4', 'Fn5', 'Fn6', 'Fn7']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['Fn1', 'Fn2', 'Fn3', 'Fn4', 'Fn5', 'Fn6', 'Fn7'] is in `completed_steps.finance`:

1. Announce: "Finance Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
