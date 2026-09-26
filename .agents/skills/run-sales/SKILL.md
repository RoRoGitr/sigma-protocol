---
name: run-sales
description: "Run Track orchestrator: Run Track — Sales (S1–S8) — sequential steps with daily task emission"
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

# /run-sales — Run Track — Sales (S1–S8)

**On start, announce:** "Starting Run Track for sales. We'll walk steps in order with plain-language daily tasks."

<goal>
Orchestrate Run Track steps in order. Department: **sales**.

| # | Command | Step |
|---|---------|------|
| 1 | `/run-s-1-icp-accounts` | S1 ICP + Named Accounts |
| 2 | `/run-s-2-crm-pipeline` | S2 CRM + Pipeline |
| 3 | `/run-s-3-outbound-playbook` | S3 Outbound Playbook |
| 4 | `/run-s-4-discovery-sop` | S4 Discovery SOP |
| 5 | `/run-s-5-proposal-system` | S5 Proposal System |
| 6 | `/run-s-6-inbound-dm` | S6 Inbound + DM |
| 7 | `/run-s-7-followup-system` | S7 Follow-up System |
| 8 | `/run-s-8-pipeline-ops` | S8 Pipeline Ops |

**Config:** `.sigma/run-track.json`  
**Research:** `docs/run-track/README.md`

Phase A: Confirm business model in `docs/run-track/BUSINESS-MODEL.json`  
Phase B: Run each step command in order (or resume from last incomplete in config)  
Phase C: Print **today's tasks** (max 3 founder items across active step)  
Phase D: Offer `/run-sales` resume on next session
</goal>

---

## Trigger

- Default: After M2 (shared ICP) or Step 1.5 (see `.sigma/run-track.json`)

## Resume logic

Read `completed_steps.sales` in `.sigma/run-track.json`. Next step = first missing in: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8']

## Parallel execution

Run Track may run in parallel with `@dev-loop` when `.sigma/run-track.json` allows.

Invoke child steps via their slash commands — do NOT inline their full playbooks.

## Phase E — Department complete → `@continue`

When every step in ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'] is in `completed_steps.sales`:

1. Announce: "Sales Run Track complete."
2. Run `python3 scripts/run-track-continue.py` and present the prompt.
3. **HITL:** Ask if founder wants the **next** department (see `steps/_partials/run-track-continuation.md`).
4. Do **not** auto-invoke the next `/run-*` without explicit approval.

<!-- include: _partials/run-track-continuation.md -->
