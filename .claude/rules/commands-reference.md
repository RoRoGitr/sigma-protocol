# Sigma Protocol - Commands Reference

## Core Steps

| Command | Description |
|---------|-------------|
| `/step-0-environment-setup` | Environment validation and workspace bootstrap |
| `/step-1-ideation` | Product ideation with Hormozi value framing |
| `/step-2-architecture` | Architecture profile, boundaries, tradeoffs, and handoffs |
| `/step-3-ux-design` | UX and user-flow design |
| `/step-4-flow-tree` | Navigation flow and screen inventory |
| `/step-5-wireframe-prototypes` | Wireframe PRD generation — Track A (Claude Design) or Track B (direct, default) |
| `/step-6-design-system` | Design system and tokens |
| `/step-7-interface-states` | Interface state specifications |
| `/step-8-technical-spec` | Technical specifications |
| `/step-9-landing-page` | Landing page design — Track A (Claude Design) / Track B (templates, default) / Hybrid |
| `/step-10-feature-breakdown` | Feature breakdown |
| `/step-11-prd-generation` | Implementation-ready PRD generation |
| `/step-11.5-task-handoff` | Execution handoff — TASKS.json, claims, /next-task contract |
| `/step-12-context-engine` | Context engine setup |
| `/step-13-skillpack-generator` | Project skillpack generation |
| `/step-14-agent-runtime-bootstrap` | Agent runtime bootstrap |
| `/step-15-observability-contract` | Per-feature instrumentation contract |

## Standalone Workflow Commands

| Command | Description |
|---------|-------------|
| `/prd-json` | Convert Step 5 or Step 11 PRDs into canonical execution backlog JSON |
| `/prd-orchestrate` | Build dependency-aware orchestration plans under `.sigma/orchestration/*` |
| `/continue` | Resume from the highest-signal unfinished backlog or PRD source |
| `/status` | Show methodology and backlog status |
| `/platform-sync` | Review upstream platform capability drift |

## Active Workflow Contract

1. Steps `0-15` plus conditional `1.5` and `11.5` are the only numbered workflow steps.
2. After Step 5, run `/prd-json --mode prototype`.
3. After Step 11, run `/prd-json --mode implementation`.
4. Use `/prd-orchestrate` only when orchestration planning is needed.
5. Do not reintroduce legacy numbered substeps or archived execution guidance.
