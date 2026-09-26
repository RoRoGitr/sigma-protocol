---
name: run-community
description: "Run Track orchestrator: Run Track — Community (Co1–Co6) — sequential steps with daily task emission"
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

# /run-community — Run Track — Community (Co1–Co6)

**On start, announce:** "Starting Run Track for community. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **community**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-co-1-platform-audit` | Co1 Platform Health Audit |
| 2 | `/run-co-2-welcome-flow` | Co2 Welcome + First Value |
| 3 | `/run-co-3-content-rhythm` | Co3 Community Content Rhythm |
| 4 | `/run-co-4-moderation` | Co4 Moderation + Escalation |
| 5 | `/run-co-5-feedback-loop` | Co5 Product Feedback Loop |
| 6 | `/run-co-6-advocacy` | Co6 Retention + Advocacy |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-community` resume on next session
</goal>

---

## Trigger

- Default: After M2 or M8 for launch-heavy products (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.community` in `.sigma/run-track.json`. Next step = first missing in: ['Co1', 'Co2', 'Co3', 'Co4', 'Co5', 'Co6']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['Co1', 'Co2', 'Co3', 'Co4', 'Co5', 'Co6'] is in `completed_steps.community`:

1. Announce: "Community Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
