# Sigma File Path Reference

**Version:** 2.0.0
**Last Updated:** 2026-06-29
**Purpose:** Canonical list of all file paths used across the Sigma workflow

---

## Overview

This document defines the **official file paths** for all outputs created by the Sigma workflow (Steps `0-15` plus conditional Steps `1.5` and `11.5`). Every path here is verified against the `Required Outputs` / `Final Outputs` block of its canonical step in `steps/`. All commands MUST reference these exact paths to ensure consistency and prevent broken references.

**Rule:** If a command references a file path not listed here, it's an error that needs to be fixed. If a step's output set changes, update its `steps/` block first, then mirror the change here.

**Legend:** ⭐ = primary output · *(conditional)* = only when the step's decision gate fires · *(optional)* = produced only when justified.

---

## Step Outputs (Canonical Paths)

### Step 0: Environment Setup
**Command:** `@step-0-environment-setup`
**Outputs:**
- `/docs/ops/ENVIRONMENT-SETUP.md` ⭐ PRIMARY
- `/.sigma/runtime-baseline.json` (machine-readable runtime/tooling baseline)

### Step 1: Ideation
**Command:** `@step-1-ideation`
**Outputs:**
- `/docs/specs/MASTER_PRD.md` ⭐ PRIMARY
- `/docs/specs/constitution.md` (immutable foundational principles; created once, checked by every later step)
- `/docs/stack-profile.json` ⭐ CRITICAL
- `/docs/research/market-analysis-{PROJECT}.md`
- `/docs/prds/.prd-status.json`

### Step 1.5: Offer Architecture (Conditional — monetized products)
**Command:** `@step-1.5-offer-architecture`
**Outputs:**
- `/docs/specs/OFFER_ARCHITECTURE.md` ⭐ PRIMARY
- `/docs/specs/pricing-config.json` *(conditional)*
- updated `/docs/specs/MASTER_PRD.md`
- updated `/docs/stack-profile.json`

### Step 2: Architecture
**Command:** `@step-2-architecture`
**Outputs:**
- `/docs/architecture/ARCHITECTURE.md` ⭐ PRIMARY
- `/docs/architecture/adrs/ADR-*.md` *(optional, only when the project has 3+ major architectural decisions worth separating)*

### Step 3: UX Design
**Command:** `@step-3-ux-design`
**Outputs:**
- `/DESIGN.md` ⭐ PRIMARY (repo root; Google `design.md` format — canonical design contract)
- `/docs/ux/UX-DESIGN.md`
- `/docs/design/ui-profile.json` (machine mirror of DESIGN.md dials)
- `/docs/design/DNA-REFERENCES.md` (award-tier references from the divergence protocol)
- `/.sigma/standards.json` (machine-readable DNA invariants; consumed by the step-verify gate in Steps 4-9)

### Step 4: Flow Tree & Screen Architecture
**Command:** `@step-4-flow-tree`
**Outputs:**
- `/docs/flows/FLOW-TREE.md` ⭐ PRIMARY
- `/docs/flows/SCREEN-INVENTORY.md`
- `/docs/flows/TRANSITION-MAP.md`
- `/docs/flows/TRACEABILITY-MATRIX.md`
- `/docs/flows/ZERO-OMISSION-CERTIFICATE.md`
- `/product/flows/flow-tree.json` (machine mirror; `docs/flows/*` is the human surface, `product/flows/flow-tree.json` is the agent surface — both are canonical)

### Step 5: Wireframe Prototypes
**Command:** `@step-5-wireframe-prototypes`
**Outputs:**
- `/docs/prds/flows/[NN]-[flow-slug]/FLOW-[ID].md` ⭐ PRIMARY (one scaffolding PRD per flow)
- `/docs/prds/flows/WIREFRAME-TRACKER.md`
- `/docs/prds/flows/PRD-SUMMARY.md`
- `/docs/prds/flows/ZERO-OMISSION-CERTIFICATE.md`

### Backlog conversion — prototype (standalone, after Step 5)
**Command:** `/prd-json --mode prototype`
**Outputs:**
- `/.sigma/backlogs/prototype/prd.json`

### Step 6: Design System
**Command:** `@step-6-design-system`
**Outputs:**
- `/docs/design/DESIGN-SYSTEM.md` ⭐ PRIMARY
- `/docs/tokens/design-tokens.json` (W3C DTCG 2025.10, Oklch/CSS Color 4)
- `/docs/tokens/style-dictionary.config.json` (Style Dictionary v4 build config)
- `/docs/tokens/css-variables.css` *(optional)*
- `/docs/tokens/react-native-tokens.ts` *(optional)*
- `/docs/tokens/swiftui-tokens.swift` *(optional)*
- `/docs/components/COMPONENT-LIBRARY.md` *(optional)*
- `/docs/design/MOTION.md` *(optional)*

### Step 7: Interface States
**Command:** `@step-7-interface-states`
**Outputs:**
- `/docs/states/STATE-SPEC.md` ⭐ PRIMARY
- `/docs/states/MICRO-INTERACTIONS.md` *(optional)*
- `/docs/states/MOBILE-STATES.md` *(optional)*
- `/docs/states/ACCESSIBILITY-STATES.md` *(optional)*

### Step 8: Technical Specification
**Command:** `@step-8-technical-spec`
**Outputs:**
- `/docs/technical/TECHNICAL-SPEC.md` ⭐ PRIMARY
- `/docs/api/OPENAPI-SPEC.yaml` *(conditional — custom HTTP API surface)*
- `/docs/database/SCHEMA-COMPLETE.sql` *(conditional — custom schema extensions)*

### Step 9: Landing Page (Optional)
**Command:** `@step-9-landing-page`
**Outputs:**
- `/docs/landing-page/LANDING-PAGE.md` ⭐ PRIMARY
- `/docs/avatars/PROBLEM-AWARE-AVATAR.md`
- `/docs/avatars/DIARY-ENTRIES.md`
- `/docs/research/LANDING-SOURCES.md`
- `/docs/landing-page/TEMPLATE-MAPPING.md` *(conditional)*
- `/docs/landing-page/CTA-VARIANTS.md` *(conditional)*

### Step 10: Feature Breakdown
**Command:** `@step-10-feature-breakdown`
**Outputs:**
- `/docs/implementation/FEATURE-BREAKDOWN.md` ⭐ PRIMARY
- `/docs/implementation/BETTING-TABLE.md` *(conditional)*
- `/docs/implementation/FEATURE-DEPENDENCIES.md` *(conditional)*
- `/docs/implementation/PRD-ROADMAP.md` *(conditional)*

### Step 11: PRD Generation
**Command:** `@step-11-prd-generation`
**Outputs:**
- `/docs/prds/F01.001-<slug>.md` ⭐ PRIMARY (one per PRD-eligible feature; ID = `F<wave:02d>.<feature:03d>`)
- `/docs/prds/.prd-status.json`
- `/docs/evals/<feature-id>-golden.json` (Section 13 Eval Contract golden tasks; authored here, appended by Step 14)

### Backlog conversion — implementation (standalone, after Step 11)
**Command:** `/prd-json --mode implementation`
**Outputs:**
- `/.sigma/backlogs/implementation/prd.json`

### Step 11.5: Task Handoff (Conditional)
**Command:** `@step-11.5-task-handoff`
**Outputs:**
- `/.sigma/backlogs/<mode>/TASKS.md` ⭐ PRIMARY (`<mode>` = `implementation` default, or `prototype`)
- `/.sigma/backlogs/<mode>/TASKS.json` *(optional machine-parseable mirror)*

### PRD Orchestration (Optional, after Step 11)
**Command:** `/prd-orchestrate`
**Outputs:**
- `/.sigma/orchestration/` ⭐ CANONICAL (`streams.json`, `state.json`, `progress.json`, `inbox/`, dependency plan)

> The legacy `docs/prds/swarm-*` / `docs/prds/SWARM-PLAN.md` location is **deprecated**. Orchestration output is `.sigma/orchestration/*` only.

### Step 12: Context Engine
**Command:** `@step-12-context-engine`
**Outputs:**
- `/AGENTS.md` (Step 12 methodology section, clearly labeled)
- `/CLAUDE.md` (tracked Claude Code entry point; imports `@AGENTS.md`)
- `/.sigma/memory/project/README.md`
- `/.sigma/memory/local/.gitkeep`
- `/.sigma/memory/agents/README.md`

Operators may optionally align local CLI surfaces (`.claude/settings.json`, `.codex/config.toml`) — these are not generated or validated by the OSS install.

### Step 13: Skillpack Generator
**Command:** `@step-13-skillpack-generator`
**Outputs:**
- `/src/skills/<category>/<skill>/SKILL.md` ⭐ authored source
- `/src/agents/<category>/<agent>.md` ⭐ authored source
- `/src/skills/<department>/eval-harness-<dept>/SKILL.md` (one eval-harness skill per department agent)
- `/.sigma/indexes/skills-index.json`, `/.sigma/indexes/agents-index.json`
- `/.sigma/tools/eval-runner.sh` (Step 13's only write into the Step-14-owned `.sigma/tools/`)

### Step 14: Agent Runtime Bootstrap
**Command:** `@step-14-agent-runtime-bootstrap`
**Outputs:**
- `/docs/specs/AGENT-RUNTIME.md` ⭐ PRIMARY
- `/.sigma/runtime/runtime.manifest.json`
- `/.sigma/runtime/graph.config.json`
- `/.sigma/runtime/delegation-policy.json`
- `/.sigma/memory/project/README.md`, `/.sigma/memory/local/.gitkeep`, `/.sigma/memory/agents/README.md`
- `/.sigma/tools/` (owns the directory: `lint.sh`, `test.sh`, `build.sh`, `typecheck.sh`)

### Step 15: Observability Contract
**Command:** `@step-15-observability-contract`
**Outputs:**
- `/docs/observability/INSTRUMENTATION-CONTRACT.md` ⭐ PRIMARY (master contract + per-feature entries)
- `/docs/observability/CI-WIRE-UP.md` *(optional pre-deploy instrumentation checklist)*

---

## Ownership Notes (drift guards)

- **`.sigma/tools/`** is owned by **Step 14** (creates the directory + `lint/test/build/typecheck.sh`). **Step 13** writes only `eval-runner.sh` into it. No other step writes here.
- **`CLAUDE.md`** is the tracked Claude Code entry point. It imports `@AGENTS.md`; Step 12 keeps the shared project context in `AGENTS.md`.
- **`docs/evals/<feature-id>-golden.json`** is authored by **Step 11** (PRD Section 13 Eval Contract) and appended by **Step 14** (failure traces promoted to new golden tasks).
- **`product/flows/flow-tree.json`** (agent surface) and **`docs/flows/*`** (human surface) are an intentional machine/human split — both canonical, not drift.
- **Mirrors** (`.codex/`, `.cursor/`, optional local CLI trees) may exist on operator machines but are **not** part of the OSS install contract. Canonical sources: `steps/`, `commands/`, `src/skills/`, `src/agents/`, `agent-skill-registry.json`. Never hand-edit rendered `commands/`.

---

## Audit Command Outputs

### @step-verify
**Command:** `@step-verify --step=N`
**Inputs:** Reads `<verification>` blocks from canonical step files at:
- `steps/step-[N]-*` and rendered `commands/step-[N]-*.md`

**Outputs:** 
- Console output with 100-point scoring
- Gap analysis with fix recommendations

**Related Paths:**
- Verification schemas embedded in each step command file

### @verify-prd
**Command:** `@verify-prd <F-ID>` (e.g. `@verify-prd F01.001`)
**Inputs:** PRD files at `/docs/prds/F*.md`
**Outputs:** Verification score (8+/10 required)

### @analyze
**Command:** `@analyze`
**Outputs:**
- `/docs/reports/ANALYSIS-[DATE].md`

---

## Tracking System Outputs ✨ NEW

> **Note:** The tracking database is stored at the **repository root** (`.tracking-db/`), not under `docs/`. This is machine-generated state that should be in `.gitignore` for most projects.

### /backlog-groom
**Command:** `/backlog-groom`
**Inputs:**
- `/docs/implementation/FEATURE-BREAKDOWN.md` (Step 10)
- `/docs/prds/**/*.md` (Step 11 PRDs)

**Outputs:**
- `/.tracking-db/prds/[ID].json` - One tracking file per PRD
- `/.tracking-db/config.json` - Backlog configuration
- `/.tracking-db/metrics.json` - Backlog metrics
- `/docs/tracking/BACKLOG.md` - Human-readable backlog board

### /sprint-plan
**Command:** `/sprint-plan`
**Inputs:**
- `/docs/tracking/BACKLOG.md`
- `/.tracking-db/prds/*.json`

**Outputs:**
- `/.tracking-db/sprints/sprint-[ID].json` - Sprint tracking
- `/docs/tracking/SPRINT-CURRENT.md` - Sprint board

### /daily-standup
**Command:** `/daily-standup`
**Inputs:**
- `/.tracking-db/sprints/[active-sprint].json`
- `/.tracking-db/prds/*.json`
- Git commit history

**Outputs:**
- `/docs/tracking/history/standups/YYYY-MM-DD.md` - Daily standup report
- Updated `/.tracking-db/sprints/*.json`
- Updated `/.tracking-db/prds/*.json`

### /job-status
**Command:** `/job-status`
**Inputs:** `/.tracking-db/prds/*.json`, `/.tracking-db/sprints/*.json`
**Outputs:** Console output only (read-only query)

---

## QA System Outputs ✨ NEW

### /qa-plan
**Command:** `/qa-plan --prd-id=[ID]`
**Inputs:**
- `/docs/prds/[ID].md` - PRD file
- `/docs/flows/FLOW-TREE.md` (Step 4)
- `/docs/states/STATE-SPEC.md` (Step 7)

**Outputs:**
- `/tests/e2e/[PRD-ID].spec.ts` - Playwright E2E tests
- `/tests/visual/[PRD-ID]-visual.spec.ts` - Visual regression tests
- `/docs/qa/checklists/[PRD-ID]-MANUAL-CHECKLIST.md` - Manual test checklist
- `/docs/qa/plans/[PRD-ID]-QA-PLAN.md` - Master QA plan
- `/tests/helpers/*.ts` - Test helper utilities
- `/tests/playwright.config.ts` - Playwright config (if not exists)

### /qa-run
**Command:** `/qa-run --prd-id=[ID]`
**Inputs:**
- `/tests/e2e/[PRD-ID].spec.ts`
- `/tests/visual/[PRD-ID]-visual.spec.ts`
- `/docs/qa/checklists/[PRD-ID]-MANUAL-CHECKLIST.md`

**Outputs:**
- `/tests/results/[PRD-ID]-e2e-results.json` - E2E test results
- `/tests/results/[PRD-ID]-visual-results.json` - Visual regression results
- `/tests/results/[PRD-ID]-manual-results.md` - Manual test log
- `/tests/visual/screenshots/[PRD-ID]-[screen]-actual.png`
- `/tests/visual/screenshots/[PRD-ID]-[screen]-diff.png`
- `/tests/logs/[PRD-ID]-qa-run.log` - Execution log
- Updated `/.tracking-db/prds/[ID].json` (QA status)

### /qa-report
**Command:** `/qa-report --prd-id=[ID]`
**Inputs:**
- `/tests/results/[PRD-ID]-*.json`
- `/.tracking-db/prds/[ID].json`

**Outputs:**
- `/docs/qa/reports/[PRD-ID]-QA-REPORT-YYYY-MM-DD.md`
- `/docs/qa/screenshots/[PRD-ID]/` - Screenshot gallery

---

## Review System Outputs ✨ NEW

### /pr-review
**Command:** `/pr-review --prd-id=[ID]`
**Inputs:**
- `/docs/prds/[ID].md` - PRD file
- `/docs/architecture/ARCHITECTURE.md` (Step 2)
- `/docs/design/DESIGN-SYSTEM.md` (Step 6)
- `/docs/states/STATE-SPEC.md` (Step 7)
- `/docs/technical/TECHNICAL-SPEC.md` (Step 8)
- Git diff for changed files

**Outputs:**
- `/docs/reviews/[PRD-ID]-PR-REVIEW-YYYY-MM-DD.md`
- Updated `/.tracking-db/prds/[ID].json` (review status)

### /test-review
**Command:** `/test-review --prd-id=[ID]`
**Inputs:**
- `/docs/prds/[ID].md` - PRD acceptance criteria
- `/tests/**/*[PRD-ID]*.test.ts` - Test files
- Coverage reports

**Outputs:**
- `/docs/reviews/[PRD-ID]-TEST-REVIEW-YYYY-MM-DD.md`
- Updated `/.tracking-db/prds/[ID].json` (test review status)

### /release-review
**Command:** `/release-review`
**Inputs:**
- `/.tracking-db/sprints/[active-sprint].json`
- `/.tracking-db/prds/*.json`
- All PR reviews, test reviews, QA reports

**Outputs:**
- `/docs/reviews/RELEASE-REVIEW-[sprint-id]-YYYY-MM-DD.md`
- `/docs/releases/RELEASE-NOTES-[sprint-id].md` (if approved)
- `/docs/migrations/ROLLBACK-PLAN-[sprint-id].md` (if migrations)

---

## Tracking DB Structure

```
.tracking-db/                     # Root-level tracking (machine state)
├── prds/                         # PRD tracking JSONs
│   ├── F1-auth.json
│   ├── F2-dashboard.json
│   └── ...
├── sprints/                      # Sprint tracking JSONs
│   ├── sprint-2025-01.json
│   └── ...
├── config.json                   # Backlog configuration
└── metrics.json                  # Overall metrics

docs/tracking/                    # Human-readable tracking outputs
├── BACKLOG.md
├── SPRINT-CURRENT.md
└── history/
    └── standups/
        ├── 2025-12-27.md
        └── 2025-12-28.md

docs/qa/                          # QA outputs
├── plans/
│   └── F1-QA-PLAN.md
├── checklists/
│   └── F1-MANUAL-CHECKLIST.md
├── reports/
│   └── F1-QA-REPORT-2025-12-28.md
└── screenshots/
    └── F1-auth/

docs/reviews/                     # Review outputs
├── F1-PR-REVIEW-2025-12-28.md
├── F1-TEST-REVIEW-2025-12-28.md
└── RELEASE-REVIEW-2025-01-2025-12-28.md

docs/releases/                    # Release outputs
└── RELEASE-NOTES-2025-01.md

docs/migrations/                  # Migration rollback plans
└── ROLLBACK-PLAN-2025-01.md
```

---

## Deprecated Paths (DO NOT USE)

❌ `/docs/specs/PRD.md` → Use `/docs/specs/MASTER_PRD.md`  
❌ `/docs/ux/UX-SPEC.md` → Use `/docs/ux/UX-DESIGN.md`  
❌ `/docs/design-system/DESIGN-SYSTEM.md` → Use `/docs/design/DESIGN-SYSTEM.md`  
❌ `/docs/interface-states/INTERFACE-STATES.md` → Use `/docs/states/STATE-SPEC.md`  
❌ `/docs/technical-spec/TECHNICAL-SPEC.md` → Use `/docs/technical/TECHNICAL-SPEC.md`  
❌ `/docs/feature-breakdown/FEATURE-BREAKDOWN.md` → Use `/docs/implementation/FEATURE-BREAKDOWN.md`  
❌ `/PRD/` → Use `/docs/prds/`  
❌ `/docs/prds/swarm-[N]/`, `/docs/prds/SWARM-PLAN.md`, `/docs/prds/DEPENDENCY-GRAPH.md` → Use `/.sigma/orchestration/*`  
❌ `/docs/specs/FEATURES.md`, `/docs/specs/USP.md`, `/docs/specs/NFRS.md`, `/docs/specs/DEV-READINESS.md`, `/docs/ops/SUCCESS-METRICS.md` → never produced; Step 1 emits `MASTER_PRD.md` + `constitution.md` only  
❌ `docs/prds/F[N]-[FEATURE-NAME].md` shorthand → Use `docs/prds/F01.001-<slug>.md` (`F<wave:02d>.<feature:03d>`)
