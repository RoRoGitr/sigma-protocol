# Sigma Protocol - Workflow

```
Step 0: Environment Setup
    |
Step 1: Ideation -> MASTER_PRD.md
    |
Step 1.5: Offer Architecture (if monetized)
    |
Step 2: Architecture -> docs/architecture/ARCHITECTURE.md
    |
Step 3: UX Design -> UX-DESIGN.md
    |
Step 4: Flow Tree -> Screen inventory, transitions, bulletproof gates
    |
Step 5: Wireframes -> docs/prds/flows/*.md
       Track A (Claude Design):   prompts -> human iterates in browser -> bundle imported -> PRDs
       Track B (Direct, default): HTML wireframes -> PRDs
    |
Command: /prd-json --mode prototype -> .sigma/backlogs/prototype/prd.json
    |
Step 6: Design System -> DESIGN-SYSTEM.md
    |
Step 7: Interface States -> STATE-SPEC.md
    |
Step 8: Technical Spec -> TECHNICAL-SPEC.md
    |
Step 9: Landing Page (optional)
    |
Step 10: Feature Breakdown -> FEATURE-BREAKDOWN.md
    |
Step 11: PRD Generation -> docs/prds/*.md
    |
Command: /prd-json --mode implementation -> .sigma/backlogs/implementation/prd.json
    |
Step 11.5: Task Handoff -> .sigma/backlogs/<mode>/TASKS.md
    |
Optional command: /prd-orchestrate -> .sigma/orchestration/*
    |
Step 12: Context Engine -> AGENTS.md + runtime config surfaces
    |
Step 13: Skillpack Generator -> project skills + agents
    |
Step 14: Agent Runtime Bootstrap -> .sigma/runtime/ + .sigma/memory/ + .sigma/tools/
    |
Step 15: Observability Contract -> docs/observability/INSTRUMENTATION-CONTRACT.md
```

## Active Workflow Rules

1. The numbered methodology is Steps `0-15` plus conditional `1.5` (Offer Architecture) and conditional `11.5` (Task Handoff).
2. PRD conversion is always a standalone command (`/prd-json`), never a numbered step.
3. Orchestration planning is always a standalone command (`/prd-orchestrate`), never a numbered step.
4. Machine backlogs live under `.sigma/backlogs/*`.
5. Orchestration state lives under `.sigma/orchestration/*`.

## Optional Claude Hooks

For orchestration observability, optional hook templates are available:

- `scripts/hooks/worktree-create.sh`
- `scripts/hooks/worktree-remove.sh`
- `scripts/hooks/config-change.sh`
