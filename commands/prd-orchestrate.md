---
description: "Build dependency-aware orchestration plans from the execution backlog under .sigma/orchestration/"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# /prd-orchestrate — Orchestration Planner

Invoke the `prd-orchestrate` skill (`.agents/skills/prd-orchestrate/SKILL.md`) and follow it exactly.

## Contract

- **Input:** `.sigma/backlogs/implementation/prd.json` (or `--mode prototype` for the prototype backlog).
- **Output:** dependency-aware wave/orchestration plans under `.sigma/orchestration/`.
- Run only when orchestration planning is needed — it is a standalone command, never a numbered step.
- HITL: present the generated plan for approval before any implementation begins.
