---
name: run-growth
description: "Run Track orchestrator: Run Track — Growth (G1–G8) — sequential steps with daily task emission"
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

# /run-growth — Run Track — Growth (G1–G8)

**On start, announce:** "Starting Run Track for growth. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **growth**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-g-1-funnel-map` | G1 Funnel Map + Events |
| 2 | `/run-g-2-baseline-metrics` | G2 Baseline Metrics |
| 3 | `/run-g-3-hypothesis-backlog` | G3 Hypothesis Backlog |
| 4 | `/run-g-4-ab-test-spec` | G4 A/B Test Spec Pack |
| 5 | `/run-g-5-cro-sprint` | G5 CRO Sprint |
| 6 | `/run-g-6-retargeting-arch` | G6 Retargeting Architecture |
| 7 | `/run-g-7-activation-cohorts` | G7 Activation + Cohorts |
| 8 | `/run-g-8-seo-organic-loop` | G8 SEO + Organic Loop |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-growth` resume on next session
</goal>

---

## Trigger

- Default: After M3 (stack / analytics connected) (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.growth` in `.sigma/run-track.json`. Next step = first missing in: ['G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G8']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7', 'G8'] is in `completed_steps.growth`:

1. Announce: "Growth Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
