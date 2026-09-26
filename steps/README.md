# Sigma Protocol — Steps

The core product development methodology: Steps `0-15` plus conditional Steps `1.5` and `11.5`. Each step is a self-contained prompt injection that guides an AI coding assistant through a structured phase sequence with human-in-the-loop checkpoints.

## Step Files

| Step | File | Description | Lines |
|------|------|-------------|-------|
| 0 | `step-0-environment-setup` | Environment validation & setup | ~1,500 |
| 1 | `step-1-ideation` | Discovery-first PRD and problem framing | ~1,150 |
| 1.5 | `step-1.5-offer-architecture` | Monetization and offer architecture (if monetized) | ~720 |
| 2 | `step-2-architecture` | System Architecture | ~1,250 |
| 3 | `step-3-ux-design` | UX/UI Design & User Flows | ~1,590 |
| 4 | `step-4-flow-tree` | Navigation Flow & Screen Inventory | ~1,860 |
| 5 | `step-5-wireframe-prototypes` | Wireframe Prototypes | ~2,980 |
| 6 | `step-6-design-system` | Design System & Tokens | ~1,650 |
| 7 | `step-7-interface-states` | Full State Coverage, Recovery & Accessibility | ~1,320 |
| 8 | `step-8-technical-spec` | Technical Specification | ~1,210 |
| 9 | `step-9-landing-page` | Landing Page (optional) | ~1,670 |
| 10 | `step-10-feature-breakdown` | Feature Breakdown | ~1,160 |
| 11 | `step-11-prd-generation` | PRD Generation | ~2,940 |
| 11.5 | `step-11.5-task-handoff` | Task handoff manifest (TASKS.md / `/next-task`) | ~400 |
| 12 | `step-12-context-engine` | Context Engine | ~1,270 |
| 13 | `step-13-skillpack-generator` | Skillpack Generator | ~950 |
| 14 | `step-14-agent-runtime-bootstrap` | Agent Runtime Bootstrap | ~780 |
| 15 | `step-15-observability-contract` | Observability Contract | ~345 |

**Utility files:** `dev-loop` and `validate-methodology`

## Run Track (Growth Operations)

Parallel to Build Track — market, sell, and operate while you build. See [`docs/run-track/README.md`](../docs/run-track/README.md) and [`docs/run-track/RUN-TRACK-ROADMAP.md`](../docs/run-track/RUN-TRACK-ROADMAP.md).

| Entry | Steps | Backlog |
|-------|-------|---------|
| `/run-marketing` | M1–M10 | `.sigma/backlogs/marketing/prd.json` |
| `/run-sales` | S1–S8 | `.sigma/backlogs/sales/prd.json` |
| `/run-content` | C1–C8 | `.sigma/backlogs/content/prd.json` |
| `/run-growth` | G1–G8 | `.sigma/backlogs/growth/prd.json` |
| `/run-community` | Co1–Co6 | `.sigma/backlogs/community/prd.json` |
| `/run-ops` | O1–O8 | `.sigma/backlogs/ops/prd.json` |
| `/run-finance` | Fn1–Fn7 | `.sigma/backlogs/finance/prd.json` |
| `/run-legal` | L0–L8 | `.sigma/backlogs/legal/prd.json` |

**64** numbered step files under `steps/run-*` + **8** orchestrators.

(64 department steps + 8 orchestrators = 72 generated files; step count excludes orchestrators.)

Verify: `node scripts/verify-run-track.mjs --wave=4`

## After Steps 0–15

See **[`docs/AFTER-STEP-15.md`](../docs/AFTER-STEP-15.md)** — plain-English guide: Run Track, `@dev-loop`, `@gap-analysis`, and ship.

## Active Workflow Contract

Sigma's active workflow is limited to Steps `0-15` plus conditional Steps `1.5` and `11.5`.

After the numbered steps:
1. Run `/prd-json --mode prototype` after Step 5 to write `.sigma/backlogs/prototype/prd.json`.
2. Run `/prd-json --mode implementation` after Step 11 to write `.sigma/backlogs/implementation/prd.json`.
3. Optionally run `/prd-orchestrate` to write dependency-aware planning artifacts under `.sigma/orchestration/`.
4. Run `step-14-agent-runtime-bootstrap` after Step 13 to generate the runtime contract, memory scaffolds, and graph/runtime overlays.
5. Run `step-15-observability-contract` after Step 14 (or before first staging deploy) to write per-feature instrumentation contracts.

Removed pseudo-step labels and legacy step-style aliases are not part of the active workflow vocabulary.

## Structure

Every step follows a consistent structure:

1. **YAML Frontmatter** — Version, allowed tools, parameters
2. **Mission** — Role and objective
3. **`<goal>` Block** — Phase roadmap table, execution order, quality gate threshold
4. **Frameworks** — Domain-specific reference material (inline, not extracted)
5. **Phases A-N** — Sequential execution with `>>> CHECKPOINT` markers
6. **Final Review Gate** — Output checklist and blocking approval
7. **`<verification>` Block** — 100-point scoring rubric

## Platform Support

Steps are authored once under `steps/` and rendered to `commands/` via `scripts/sync-steps-to-platforms.sh`.

- **Canonical surfaces:** `steps/` → `commands/`, `src/skills/`, `AGENTS.md` (Step 12), `.sigma/runtime/` (Step 14)
- **Operator CLIs:** any agent harness that reads `commands/` and invokes skills from `src/skills/` or `.agents/skills/`
- **Do not maintain** `.claude/`, `.codex/`, `.cursor/`, `.factory/`, or `platforms/*` mirror trees as part of the OSS install

## Related

- [WORKFLOW-OVERVIEW.md](../docs/WORKFLOW-OVERVIEW.md)
- [FILE-PATH-REFERENCE.md](../docs/FILE-PATH-REFERENCE.md)
- [COMMANDS.md](../docs/COMMANDS.md)
