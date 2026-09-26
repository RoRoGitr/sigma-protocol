---
version: "3.2.0"
last_updated: "2026-04-19"
description: "Validate compliance with the active Steps 0-15 methodology (plus conditional Steps 1.5 and 11.5) and report missing authored, planning, backlog, and runtime artifacts"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
parameters:
  - --detailed
  - --fix
---

# @validate-methodology

**Comprehensive methodology compliance checker**

## Purpose

Validate that a project follows the active Sigma workflow:
- Steps `0-15`
- conditional Steps `1.5` and `11.5`
- standalone backlog conversion commands after Step 5 and Step 11
- optional standalone orchestration after Step 11

This command checks required artifacts, reports completion percentage, and tells the user what to run next.

## Command Usage

### Basic Validation
```bash
@validate-methodology
```

### Detailed Report
```bash
@validate-methodology --detailed
```

### Auto-Fix Guidance
```bash
@validate-methodology --fix
```

## Related Commands

- Use `@step-verify --step=N` for a deep 100-point review of a specific step.
- Use `@analyze` for broader repo health after methodology validation.

<goal>
You are the Methodology Compliance Auditor ensuring projects follow the active Steps 0-15 workflow (plus conditional Steps 1.5 and 11.5).

## Core Principles
1. Check the active workflow only; do not require archived legacy outputs.
2. Accept reasonable legacy aliases where Sigma already declares them as compatibility paths.
3. Report clearly what is complete, missing, optional, or skipped.
4. Treat Step 12, Step 13, and Step 14 as canonical-first outputs.
5. Treat `sigma prd-json` and `sigma prd-orchestrate` as standalone commands, not numbered steps.
</goal>

---

## Validation Checklist

### Step 0 — Environment Setup
Required:
- `docs/ops/ENVIRONMENT-SETUP.md`
- `.sigma/runtime-baseline.json`
- `docs/ops/`
- `docs/prds/`
- `docs/analysis/`
- `.sigma/backlogs/prototype/`
- `.sigma/backlogs/implementation/`
- `.sigma/orchestration/`

### Step 1 — Ideation
Required:
- `docs/specs/MASTER_PRD.md`
- `docs/specs/constitution.md`
- `docs/stack-profile.json`
- `docs/research/market-analysis-*.md`
- `docs/prds/.prd-status.json`

### Step 1.5 — Offer Architecture (conditional)
Required when monetization is detected:
- `docs/specs/OFFER_ARCHITECTURE.md`

Required when structured monetization is detected:
- `docs/specs/pricing-config.json`

### Step 2 — Architecture
Required:
- `docs/architecture/ARCHITECTURE.md`

### Step 3 — UX Design
Required:
- `docs/ux/UX-DESIGN.md`
- `/DESIGN.md`
- `docs/design/ui-profile.json`
- `docs/design/DNA-REFERENCES.md`
- `.sigma/standards.json` (machine-readable DNA invariants; consumed by step-verify-gate in Steps 4-9)

### Step 4 — Flow Tree
Required:
- `docs/flows/FLOW-TREE.md`
- `docs/flows/SCREEN-INVENTORY.md`
- `docs/flows/TRACEABILITY-MATRIX.md`
- `docs/flows/ZERO-OMISSION-CERTIFICATE.md`
- `docs/flows/TRANSITION-MAP.md` or `docs/flows/STATE-TRANSITIONS.md`
- `/product/flows/flow-tree.json`

### Step 5 — Wireframe Prototypes
Required:
- `docs/prds/flows/`
- `docs/prds/flows/WIREFRAME-TRACKER.md`
- at least one `FLOW-*.md` file under `docs/prds/flows/*/`
- `docs/prds/flows/PRD-SUMMARY.md`
- `docs/prds/flows/ZERO-OMISSION-CERTIFICATE.md`

Track-specific conditional (detect per flow from the tracker and artifact receipt):
- **Canvas:** `docs/prds/flows/*/visual-artifact/` with editable source (`.pen` when Pen is used), at least one actual reviewable export, and `VISUAL-ARTIFACT.md` recording tool/version, viewport/state evidence and approval.
- **Direct:** `docs/prds/flows/*/screens/` with stack-native prototype artifacts and render/interaction evidence. Web HTML is one supported format; do not demand HTML for native platforms.

Boundary rule: the declared source and evidence must exist. Missing source, export or receipt leaves Canvas incomplete; missing platform-appropriate artifact/evidence leaves Direct incomplete. Legacy imported bundles may be read at their recorded paths during retrofit; do not require a retired design tool or delete them. A screenshot alone does not prove interactions.

### Prototype backlog conversion (standalone)
Optional but strongly recommended after Step 5:
- `.sigma/backlogs/prototype/prd.json`

### Step 6 — Design System
Required:
- `docs/design/DESIGN-SYSTEM.md`
- `docs/tokens/design-tokens.json`

### Step 7 — Interface States
Required:
- `docs/states/STATE-SPEC.md`

### Step 8 — Technical Spec
Required:
- `docs/technical/TECHNICAL-SPEC.md`

Conditional:
- `docs/api/OPENAPI-SPEC.yaml` when Step 8 defines `Custom HTTP API Surface: Yes`
- `docs/database/SCHEMA-COMPLETE.sql` when Step 8 defines `Custom Schema Extensions: Yes`

### Step 9 — Landing Page (optional)
If the project includes a landing-page workflow, require:
- `docs/landing-page/LANDING-PAGE.md`
- `docs/avatars/PROBLEM-AWARE-AVATAR.md`
- `docs/avatars/DIARY-ENTRIES.md`
- `docs/research/LANDING-SOURCES.md`

Track-specific conditional (read LANDING-PAGE.md and its recorded source path):
- **Canvas (Track A):** `docs/landing-page/VISUAL-BRIEF.md`, `docs/landing-page/visual-source/` with editable source and actual exports/evidence.
- **Direct/template (Track B):** template mapping when using a template; `docs/landing-page/landing-page.html` or the selected stack-native preview when generating directly.
- **Hybrid:** Canvas artifacts plus `docs/landing-page/TEMPLATE-MAPPING.md` identifying what is implemented from the source.

Legacy imported visual bundles are accepted only when explicitly recorded and reviewed; new runs use neutral paths. Do not infer readiness from a directory name.

Other conditional:
- `docs/landing-page/CTA-VARIANTS.md` when the landing-page blueprint marks CTA variant testing as `Yes`

Boundary rule: if LANDING-PAGE.md declares a track, the corresponding artifacts must exist. Missing Canvas evidence or an actually-required template mapping counts as incomplete. A Direct path without a template does not require template mapping.

### Step 10 — Feature Breakdown
Required:
- `docs/implementation/FEATURE-BREAKDOWN.md`

Conditional:
- `docs/implementation/BETTING-TABLE.md` when the main feature-breakdown file marks `Betting Table Artifact: Yes`
- `docs/implementation/FEATURE-DEPENDENCIES.md` when the main feature-breakdown file marks `Dependency Artifact: Yes`
- `docs/implementation/PRD-ROADMAP.md` when the main feature-breakdown file marks `PRD Roadmap Artifact: Yes`

### Step 11 — PRD Generation
Required:
- `docs/prds/`
- `docs/prds/.prd-status.json`
- at least one `docs/prds/F*-*.md` implementation PRD
- at least one implementation PRD outside `docs/prds/flows/`

### Implementation backlog conversion (standalone)
Optional but strongly recommended after Step 11:
- `.sigma/backlogs/implementation/prd.json`

### Step 11.5 — Task Handoff (conditional)
Required when a multi-agent execution handoff is generated from accepted PRDs:
- `.sigma/backlogs/implementation/TASKS.md` (or `.sigma/backlogs/prototype/TASKS.md` in prototype mode)

Optional:
- `.sigma/backlogs/<mode>/TASKS.json` (machine-parseable mirror, written with `--json` or when Linear is configured)

### Optional orchestration
Optional after Step 11:
- `.sigma/orchestration/`

### Step 12 — Context Engine
Required:
- `/AGENTS.md`
- `.sigma/memory/project/README.md`
- `.sigma/memory/local/.gitkeep`
- `.sigma/memory/agents/README.md`

Optional (operator-local CLI config — do not require for OSS compliance):
- `/CLAUDE.md`
- `/.claude/settings.json`
- `/.codex/config.toml`

### Step 13 — Skillpack Generator
Required:
- `/src/skills/`
- `/src/agents/`
- `.sigma/indexes/skills-index.json`
- `.sigma/indexes/agents-index.json`

Optional (operator-local mirrors — not generated by Step 13):
- `/.claude/skills/`
- `/.claude/agents/`
- `/.agents/skills/` (compatibility pool)
- `/.codex/skills/` (compatibility adapter only)

### Step 14 — Agent Runtime Bootstrap
Required:
- `docs/specs/AGENT-RUNTIME.md`
- `.sigma/tools/`
- `.sigma/runtime/runtime.manifest.json`
- `.sigma/runtime/graph.config.json`
- `.sigma/runtime/delegation-policy.json`
- `.sigma/memory/project/`
- `.sigma/memory/local/`
- `.sigma/memory/agents/README.md`

Notes:
- `CLAUDE.md` is the tracked source template from Step 12; local `CLAUDE.md` and optional `CLAUDE.local.md` are live runtime files
- `.sigma/tools/` is Step 14-owned; Step 13 writes only `.sigma/tools/eval-runner.sh` into it
- `.sigma/tools/`, `.sigma/runtime/*`, and `.sigma/memory/*` are generated local runtime state, not tracked source artifacts
- Step 12 is checked against tracked instruction/config surfaces, not against Step 14-owned generated `.sigma/` outputs

### Step 15 — Observability Contract
Required when features carry an Eval Contract (Section 13) and instrumentation is contracted:
- `docs/observability/INSTRUMENTATION-CONTRACT.md`

Optional:
- `docs/observability/CI-WIRE-UP.md` (pre-deploy instrumentation checklist)

---

## Reporting Rules

### Completion states
- `✅ Complete`
- `❌ Missing`
- `⏭️ Skipped`
- `⚠️ Optional / recommended`

### Auto-fix guidance
If `--fix` is passed, do not silently mutate the project. Instead:
1. identify the missing step or command output
2. suggest the exact command to run
3. tell the user what it will create
4. recommend the next validation pass

---

## Quality Gates

Before reporting complete:
1. ✅ All active steps checked (0-15, including conditional 1.5 and 11.5)
2. ✅ Optional standalone backlog/orchestration outputs reported separately from numbered steps
3. ✅ Flow Tree and wireframe gate artifacts checked
4. ✅ Step 12 checked against tracked instruction and config surfaces
5. ✅ Step 13 checked against `src/` authored source and indexes only; vendor mirrors reported as optional if present
6. ✅ Step 14 checked against the runtime spec and runtime scaffold outputs
7. ✅ Archived legacy outputs are not treated as required
8. ✅ Next steps suggested with exact commands

---

## Final Review Gate

**All outputs for this command:**
- [ ] Active workflow checked across Steps 0-15 plus conditional 1.5 and 11.5
- [ ] Compliance percentage calculated
- [ ] Missing artifacts identified clearly
- [ ] Optional backlog/orchestration outputs reported separately
- [ ] Exact next commands suggested
- [ ] Detailed report generated (if `--detailed`)
- [ ] Auto-fix guidance generated (if `--fix`)

**>>> FINAL CHECKPOINT: VALIDATION COMPLETE <<<**
**Do NOT proceed to the next step without explicit approval.**
