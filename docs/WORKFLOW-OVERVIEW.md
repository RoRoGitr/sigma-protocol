# Sigma Development Workflow: Complete Guide (Steps 0-15 + Conditional 1.5 and 11.5)

**Last Updated:** 2026-06-29
**Version:** 1.0.0-alpha.1

---

## 🎯 Overview

The Sigma (Sigma Software Solutions) workflow is a comprehensive process across Steps `0-15` plus conditional Steps `1.5` and `11.5` that takes you from initial idea to production-ready code with complete documentation. Think of it as building a house - you don't start with the roof, you follow a specific order.

**Workflow Order:** `0 → 1 → 1.5 (conditional) → 2 → 3 → 4 → 5 → /prd-json --mode prototype → 6 → 7 → 8 → 9 → 10 → 11 → 11.5 → /prd-json --mode implementation → /prd-orchestrate (optional) → 12 → 13 → 14 → 15`

For brownfield repos, use this setup path first:

```text
existing repo
  -> $map-codebase
  -> Step 0
  -> $discuss-phase (when scope or constraints are still soft)
  -> continue through the numbered workflow
```

**Key Principles:**

- **Sequential:** Steps must be done in order (no skipping)
- **Cumulative:** Each step builds on previous steps
- **Conditional Steps:** Step 1.5 is required only for monetized projects
- **Comprehensive:** 100-1000+ lines of documentation per step
- **Human-in-the-Loop (HITL):** AI stops at checkpoints for your approval
- **Tool-assisted:** Uses built-in web search and optional MCP tools for research and validation
- **Bulletproof Gates:** Steps 4 and 5 produce traceability artifacts ensuring 100% screen coverage
- **Self-Contained:** Works for new projects without legacy dependencies
- **Agentic Layer:** Grade 4 self-correcting loops with project-local tools

**Source of Truth:** `steps/` is canonical (extensionless files). Rendered slash commands live at `commands/` via `scripts/sync-steps-to-platforms.sh`. Skills live at `src/skills/` (Step 13) with `.agents/skills/` as the bundled methodology pool. The legacy `templates/steps/` directory is deprecated as of 2026-04-19 — see `templates/steps/DEPRECATED.md`.

See `docs/SIGMA-VERSIONING.md` for the canonical step registry.

---

## 🎯 Foundation Skills System (v1.0.0-alpha.1)

Sigma includes a **three-tier skill system** that provides AI capabilities at different levels:

### Tier 1: Foundation Skills

**Foundation skills** form the reusable baseline capability layer. They power the Step 0-15 Sigma workflow, and Step 13 adds project-authored overlays on top. Combined with the external skill library, Sigma ships **230+ total skills** (live catalog: `.sigma/indexes/skills-index.json`).

| Category               | Skills                                                                                        | Purpose                      |
| ---------------------- | --------------------------------------------------------------------------------------------- | ---------------------------- |
| **Sigma Core** (6)       | research, verification, bdd-scenarios, hormozi-frameworks, output-generation, frontend-design | Power the Step 0-15 workflow  |
| **Design & Dev** (4)   | ux-designer, architecture-patterns, api-design-principles, web-artifacts-builder              | Architecture and UI patterns |
| **Quality** (5)        | brainstorming, systematic-debugging, quality-gates, senior-qa, senior-architect               | Testing and code quality     |
| **Productivity** (5)   | prompt-engineering-patterns, xlsx, pptx, applying-brand-guidelines, remembering-conversations | Documents and productivity   |
| **Platform Tools** (4) | skill-creator, agent-development, opencode-agent-generator, creating-opencode-plugins         | Create custom skills/agents  |

### Tier 2: External Skills

**120+ specialized skills** from the [skills.sh](https://skills.sh) ecosystem:

- **Security & Fuzzing:** 42 skills (semgrep, codeql, fuzzing tools)
- **Mobile Development:** 19 skills (Expo, React Native)
- **3D Graphics:** 10 skills (Three.js)
- **Marketing & CRO:** 24 skills (conversion, ads, SEO)
- **And more:** Authentication, payments, video production

See [EXTERNAL-SKILLS.md](./EXTERNAL-SKILLS.md) for the complete external skills reference.

### Tier 3: Project Overlays (Step 13)

**Project-specific skill bundles and agent adapters** generated at Step 13 that inject your project context:

- `frontend-aesthetics` — Your design tokens, component patterns, Tailwind config
- `backend-engineering` — Your API conventions, auth patterns, error shapes
- `database-modeling` — Your schema patterns, RLS policies, migrations

### Tier 4: Runtime Bootstrap (Step 14)

**Runtime-specific overlays** generated at Step 14 that make the repo act like a live operating layer:

- runtime manifest and delegation policy under `.sigma/runtime/`
- project and local memory scaffolds under `.sigma/memory/`
- coordinator-first Codex and Claude runtime guidance
- local graph-engine routing with optional semantic enrichment

### OSS Install Surfaces

| Layer | Path | Role |
| ----- | ---- | ---- |
| Steps (source) | `steps/` | Canonical step contracts |
| Commands (rendered) | `commands/` | Import as slash commands in any agent CLI |
| Skills (authored) | `src/skills/<skill>/SKILL.md` | Step 13 project skills |
| Skills (bundled pool) | `.agents/skills/<skill>/SKILL.md` | Methodology compatibility pool |
| Project brain | `AGENTS.md` | Step 12 cross-agent context |
| Runtime | `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` | Step 14 scaffold |

See [PLATFORMS.md](./PLATFORMS.md) for the full single-surface contract.

### How They Work Together

```
┌─────────────────────────────────────────────────────────┐
│           PROJECT-SPECIFIC OVERLAYS (Step 13)          │
│  Injects: Your PRD, design system, stack, conventions  │
├─────────────────────────────────────────────────────────┤
│           EXTERNAL SKILLS (Step 0, 120+ skills)        │
│  Provides: Security, mobile, 3D, marketing, payments   │
├─────────────────────────────────────────────────────────┤
│       FOUNDATION SKILLS (Step 0, baseline skills)     │
│  Provides: Universal best practices, patterns, tools   │
└─────────────────────────────────────────────────────────┘
```

Foundation skills provide the **base capabilities**. External skills add **domain-specific expertise**. Project overlays add **your specific context**. Combined, the AI gets expert-level knowledge of YOUR codebase.

**Total Skills Available:** 230+ (Foundation + External + Project Overlays)

See:
- [FOUNDATION-SKILLS.md](./FOUNDATION-SKILLS.md) - Foundation skills
- [EXTERNAL-SKILLS.md](./EXTERNAL-SKILLS.md) - 120+ specialized skills
- [PLATFORMS.md](./PLATFORMS.md) - Platform-specific configuration

---

## 🤖 Agentic Layer (v4.0)

Sigma now includes a **Grade 4 Agentic Layer** that enables AI agents to operate, maintain, and self-correct implementations autonomously.

### The Agentic Layer Framework

Based on the "Building Agentic Layers" methodology, Sigma separates:

| Layer                 | Location                      | Purpose                           |
| --------------------- | ----------------------------- | --------------------------------- |
| **Application Layer** | `app/`, `components/`, `lib/` | The actual product code           |
| **Agentic Layer**     | `.sigma/`                       | AI agent tools, memory, and state |

### Agentic Layer Structure

```
.sigma/
├── tools/                    # Grade 3: Project-local scripts
│   ├── typecheck.sh         # Run TypeScript compiler
│   ├── lint.sh              # Run linter
│   ├── test.sh              # Run test suite
│   ├── build.sh             # Production build
│   └── format-check.sh      # Check formatting
│
├── runtime/                  # Runtime manifests and delegation policy
│   ├── runtime.manifest.json
│   ├── graph.config.json
│   └── delegation-policy.json
│
└── memory/                   # Session and durable memory
    ├── active_task.md
    ├── project/
    └── local/
```

### Agentic Maturity Grades

| Grade       | Feature               | Sigma Implementation                               |
| ----------- | --------------------- | ------------------------------------------------ |
| **Grade 1** | Prime Prompt + Native Runtime Context | `AGENTS.md` + `CLAUDE.md` (which imports it) + runtime config surfaces |
| **Grade 2** | Specialized Agents    | `@implement-prd`, `@verify-prd`, `@gap-analysis` |
| **Grade 3** | Custom Tools          | `.sigma/tools/` scripts (generated by Step 14)     |
| **Grade 4** | Closed Loops          | `@dev-loop` with auto-fix via `@gap-analysis`    |

### Self-Correcting Implementation Loop

The `@dev-loop` command now operates in Grade 4 mode:

```
┌─────────────────────────────────────────┐
│  @implement-prd                         │
│  Build the feature from PRD             │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  @verify-prd                            │
│  11-phase validation                    │
│  + .sigma/tools/ verification             │
└─────────────┬───────────────────────────┘
              │
        ┌─────┴─────┐
       PASS       FAIL
        │          │
        │          ▼
        │  ┌────────────────────────┐
        │  │  🔧 AUTO-FIX           │
        │  │  @gap-analysis --fix   │
        │  │  (up to 3 iterations)  │
        │  └────────────┬───────────┘
        │               │
        │               ▼
        │         Re-verify
        │               │
        ▼               │
┌─────────────────────────────────────────┐
│  ✅ Commit and proceed to next PRD      │
│  (Only after all checks pass)           │
└─────────────────────────────────────────┘
```

### Active Task Memory

For multi-session continuity, Sigma maintains `.sigma/memory/active_task.md`:

```markdown
# Active Task

## PRD

F03-dashboard

## Phase

implementing

## Completed Steps

- [x] Database schema
- [x] Server actions
- [ ] UI components
- [ ] Tests

## Last Updated

2025-12-29T10:30:00Z
```

This enables the AI to resume work after context window resets.

### Using the Agentic Layer

1. **Generate tools**: Run `@step-14-agent-runtime-bootstrap` to create `.sigma/tools/`
2. **Implement with memory**: `@implement-prd` writes to `active_task.md`
3. **Self-correct**: `@dev-loop` uses `@gap-analysis` when verification fails
4. **Resume**: Use `--resume` flag to continue from active task state

### Commands with Agentic Integration

| Command                   | Agentic Feature                        |
| ------------------------- | -------------------------------------- |
| `@step-12-context-engine` | Updates native runtime context surfaces  |
| `@implement-prd`          | Writes to `.sigma/memory/active_task.md` |
| `@verify-prd`             | Uses `.sigma/tools/` for verification    |
| `@dev-loop`               | Auto-fix loop + active task memory     |
| `@gap-analysis`           | Called by dev-loop for self-correction |
| `@step-14-agent-runtime-bootstrap` | Creates `.sigma/tools/`, runtime manifest, memory tiers, and coordinator policy |

---

## 🧵 Thread-Based Engineering

Sigma integrates **Thread-Based Engineering** - a framework for measuring and scaling your agentic engineering capabilities.

### What is a Thread?

A **Thread** is a unit of engineering work bookended by human actions:

```
┌─────────┐     ┌──────────────┐     ┌─────────┐
│ PROMPT  │ ──► │  AGENT WORK  │ ──► │ REVIEW  │
│ or PLAN │     │ (Tool Calls) │     │ VALIDATE│
└─────────┘     └──────────────┘     └─────────┘
     ▲                                    ▲
    YOU                                  YOU
```

### Thread Types in SSS

| Type | Symbol | Sigma Implementation |
|------|--------|-------------------|
| **Base Thread** | B | Any `@step-X` command |
| **P-Thread** | P | `sigma orchestrate` - multi-agent streams |
| **C-Thread** | C | The Step 0-15 workflow (phases with HITL) |
| **F-Thread** | F | `sigma f-thread` - same prompt, multiple agents |
| **B-Thread** | B+ | Machine-readable backlog execution with coordinating agents |
| **L-Thread** | L | Long-running `@dev-loop` sessions |

### How Sigma Uses Threads

1. **Base Threads**: Every individual command (`@implement-prd F03`)
2. **C-Threads**: The Step 0-15 workflow is one long chained thread
3. **P-Threads**: `sigma orchestrate --tui mprocs` for parallel PRD work
4. **B-Threads**: Machine-readable backlog runtimes coordinate multiple sub-agents
5. **L-Threads**: Extended `@dev-loop` sessions with stop hooks

### Commands

| Command | Description |
|---------|-------------|
| `sigma thread` | Thread type wizard |
| `sigma thread status` | View active threads |
| `sigma thread metrics` | Track your improvement |
| `sigma f-thread` | Fusion thread (multi-agent) |
| `sigma orchestrate` | P-Thread orchestration |

### 4 Dimensions of Improvement

Track your growth by measuring:

1. **More Threads** - How many agents in parallel?
2. **Longer Threads** - How long do sessions run?
3. **Thicker Threads** - Do agents prompt other agents?
4. **Fewer Checkpoints** - How often do you review?

---

## 🔍 Step Verification System

### Why Step Verification?

Before proceeding to the next step (or starting `@dev-loop`), you should verify that the current step is **100% complete**. The `@step-verify` command performs deep gap analysis with a 100-point scoring system.

### Using @step-verify

```bash
# Verify a single step
@step-verify --step=1

# Verify a range of steps
@step-verify --step=1-11

# Verify and auto-fix gaps (up to 5 iterations)
@step-verify --step=1 --fix

# Verbose output with detailed checks
@step-verify --step=1 --verbose
```

### 100-Point Scoring System

Each step is scored across 5 dimensions:

| Category                 | Points | What It Checks                                           |
| ------------------------ | ------ | -------------------------------------------------------- |
| **File Existence**       | 20     | Required output files exist and meet minimum size        |
| **Section Completeness** | 30     | Required sections present in documents                   |
| **Content Quality**      | 30     | Content meets quality standards (tables, diagrams, code) |
| **Checkpoints**          | 10     | HITL checkpoints were completed                          |
| **Success Criteria**     | 10     | Step-specific success criteria met                       |

### Score Thresholds

| Score   | Grade | Status        | Action                       |
| ------- | ----- | ------------- | ---------------------------- |
| 100/100 | A+    | ✅ COMPLETE   | Ready for next step          |
| 90-99   | A     | ✅ PASSING    | Minor improvements optional  |
| 80-89   | B+    | ⚠️ ACCEPTABLE | Should fix before proceeding |
| 70-79   | B     | ⚠️ NEEDS WORK | Fix gaps before proceeding   |
| <70     | C/F   | ❌ INCOMPLETE | Re-run the step or use --fix |

### Iterative Fix Loop (--fix mode)

When you run `@step-verify --step=1 --fix`:

1. **Verify** → Calculate current score (e.g., 72/100)
2. **List gaps** → Show what's missing
3. **Auto-fix** → Create missing files, add missing sections
4. **Re-verify** → Check new score (e.g., 88/100)
5. **Repeat** → Continue until 100/100 or max 5 iterations

### Verification Schema

Each step command file contains a `<verification>` block that defines:

- Required files with paths and minimum sizes
- Required sections in documents
- Content quality checks (patterns, tables, diagrams)
- Checkpoint evidence requirements
- Success criteria

### When to Use @step-verify

| Situation                  | Command                           |
| -------------------------- | --------------------------------- |
| Before starting next step  | `@step-verify --step=N`           |
| Before running @dev-loop   | `@step-verify --step=1-11 --fix`  |
| After completing a step    | `@step-verify --step=N --verbose` |
| Diagnosing missing outputs | `@step-verify --step=N`           |
| Quick health check         | `@step-verify --step=0-15`        |

### Integration with @validate-methodology

- `@validate-methodology` → High-level check (files exist? yes/no)
- `@step-verify` → Deep analysis (100-point scoring, quality checks, auto-fix)

Use `@step-verify` for detailed gap analysis and `@validate-methodology` for quick compliance checks.

---

## 📋 Step Overview (0-15 + Conditional 1.5 and 11.5)

| Step     | Name                            | Purpose                                                        | Key Output                                                                                    |
| -------- | ------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **0**    | Environment Setup               | Prepare workspace, tools, MCP config                           | `docs/ops/ENVIRONMENT-SETUP.md`, folder structure                                             |
| **1**    | Ideation                        | Capture vision, market research, Master PRD                    | `docs/specs/MASTER_PRD.md`, `docs/stack-profile.json`                                         |
| **1.5**  | Offer Architecture              | _(Conditional - monetized projects)_ Positioning, pricing, packaging, and monetization sync | `docs/specs/OFFER_ARCHITECTURE.md`, optional `docs/specs/pricing-config.json` for structured monetization |
| **2**    | Architecture                    | System design, tech stack, ADRs                                | `docs/architecture/ARCHITECTURE.md`                                                           |
| **3**    | UX Design                       | Experience goals, journeys, design DNA, IA, accessibility, and UI profile direction | `docs/ux/UX-DESIGN.md`, `DESIGN.md`, `docs/design/ui-profile.json`           |
| **4**    | Flow Tree & Screen Architecture | **Mobbin-style comprehensive screen mapping**                  | `docs/flows/FLOW-TREE.md`, `SCREEN-INVENTORY.md`, `TRANSITION-MAP.md` + **Bulletproof Gates** |
| **5**    | Wireframe Prototypes            | Generate per-flow prototype PRDs for buildable UI prototyping  | `docs/prds/flows/[NN]-[flow-slug]/FLOW-[ID].md`, `docs/prds/flows/WIREFRAME-TRACKER.md`, `docs/prds/flows/PRD-SUMMARY.md` |
| **6**    | Design System                   | Tokens, themes, component styling logic, motion, and accessibility foundations | `docs/design/DESIGN-SYSTEM.md`, `docs/tokens/design-tokens.json`                              |
| **7**    | Interface States                | Full state catalog, recovery patterns, announcements, and focus behavior | `docs/states/STATE-SPEC.md`                                                                   |
| **8**    | Technical Specification         | Implementation blueprint covering frontend, backend, API, data, security, testing, and delivery | `docs/technical/TECHNICAL-SPEC.md`                                                            |
| **9**    | Landing Page                    | _(Optional)_ Offer-aware landing-page strategy, conversion copy, and template mapping | `docs/landing-page/LANDING-PAGE.md`, avatar/diary/research docs                              |
| **10**   | Feature Breakdown               | Feature shaping, PRD eligibility, appetites, dependency logic, and sequencing | `docs/implementation/FEATURE-BREAKDOWN.md`                                                    |
| **11**   | PRD Generation                  | Implementation-ready feature PRDs with BDD, data contracts, and backlog readiness | `docs/prds/F01.001-<slug>.md` (ID = F<wave:02d>.<feature:03d>), `docs/prds/.prd-status.json`                              |
| **11.5** | Task Handoff                    | Vendor-neutral execution handoff: priority, claims, files-to-touch, `/next-task` contract | `.sigma/backlogs/<mode>/TASKS.md` (primary), optional `.sigma/backlogs/<mode>/TASKS.json` mirror |
| **12**   | Context Engine                  | Native runtime context synthesis (platform-agnostic)           | `AGENTS.md`, `CLAUDE.md` (imports `@AGENTS.md`), optional local CLI config |
| **13**   | Skillpack Generator             | Authored skill bundles and agents plus generated indexes       | `src/skills/<category>/<skill>/SKILL.md`, `src/agents/<category>/<agent>.md`, `.sigma/indexes/*`                             |
| **14**   | Agent Runtime Bootstrap         | Live runtime wiring, generated helper tools, memory scaffolds, and coordinator behavior  | `docs/specs/AGENT-RUNTIME.md`, `.sigma/tools/*`, `.sigma/runtime/*`, `.sigma/memory/*`                           |
| **15**   | Observability Contract          | Per-feature instrumentation contract before ship               | `docs/observability/INSTRUMENTATION-CONTRACT.md`, `docs/observability/CI-WIRE-UP.md` |

### Standalone Backlog and Orchestration Commands

| When | Command | Output |
|------|---------|--------|
| Before deeper planning on an existing repo | `$map-codebase` | `docs/ops/CODEBASE-MAP.md`, `docs/ops/codebase-map.json` |
| Before `plan`, Step 10, or Step 11 when decisions are still soft | `$discuss-phase --topic="..."` | `docs/plans/PHASE-BRIEF-<slug>.md` |
| During implementation planning when you want a specific brief loaded | `$plan --phase-brief=<path>` | `docs/plans/PLAN-*.md` with phase context embedded |
| After Step 5 | `/prd-json --mode prototype` | `.sigma/backlogs/prototype/prd.json` |
| After Step 11 | `/prd-json --mode implementation` | `.sigma/backlogs/implementation/prd.json` |
| Optional, after backlog generation | `/prd-orchestrate` | `.sigma/orchestration/*` |
| After Step 0 / 10 / 11 or when recovering sync | `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` | `.sigma/integrations/sigmahq/events/*.json` + SigmaHQ workspace/task updates |

### Review Slice Rule

The heavy review steps now use a smaller checkpoint pattern instead of dumping full documents at every approval gate.

Affected steps:
- Step 1
- Step 2
- Step 3
- Step 8
- Step 10
- Step 11
- Step 12
- Step 14

Each checkpoint should show:
- what was decided
- what changed
- what remains open
- a clear approve / revise question for just that slice

### Bulletproof Gate Files (Steps 4 & 5)

These artifacts ensure 100% screen coverage:

| File                                      | Step | Purpose                              |
| ----------------------------------------- | ---- | ------------------------------------ |
| `docs/flows/TRACEABILITY-MATRIX.md`       | 4    | PRD feature-to-screen mapping        |
| `docs/flows/ZERO-OMISSION-CERTIFICATE.md` | 4/5  | Mathematical proof no screens missed |
| `docs/prds/flows/WIREFRAME-TRACKER.md`    | 5    | Prototype coverage tracker           |

### Step 1.5 Conditional Rules

Step 1.5 is **required when monetization is detected**:

- `docs/specs/OFFER_ARCHITECTURE.md` exists
- `MASTER_PRD.md` mentions payment/billing/subscription
- `stack-profile.json` has billing provider config (stripe, paddle, etc.)
- `docs/specs/pricing-config.json` is additionally required when Step 1.5 defines structured tiers, credits, seats, quotas, usage billing, or entitlements

### PRD Orchestration Optional Rules

`/prd-orchestrate` is suggested when:

- `docs/prds/` contains 5+ PRD files
- User has access to multiple terminal instances (Claude Code, Codex)
- Project complexity warrants parallel development

**What PRD orchestration does:**

1. Scans all PRDs and extracts dependency information
2. Builds a dependency graph (DAG)
3. Detects circular dependencies (fails if found)
4. Groups PRDs into independent "swarms"
5. Creates machine-readable orchestration artifacts under `.sigma/orchestration/`
6. Generates execution order per swarm
7. Produces coordination output for multi-terminal execution

### SigmaHQ Execution Bridge

Sigma Protocol stays the planning layer. SigmaHQ is the execution companion.

```text
Step 10 -> feature cards
Step 11 -> engineering tasks
orchestration inbox -> execution telemetry
```

Use `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` when:

- a step completed but the board needs to catch up
- Step 10 changed and feature cards need refreshing
- Step 11 regenerated PRDs and engineering tasks need refreshing
- the event queue was missed and you want to backfill from current repo artifacts

**Swarm workflow:**

```
Terminal 1: execute the first assigned backlog group from `.sigma/orchestration/`
Terminal 2: execute the second assigned backlog group from `.sigma/orchestration/`
Terminal 3: execute the third assigned backlog group from `.sigma/orchestration/`
Terminal 4: execute the fourth assigned backlog group from `.sigma/orchestration/`
```

**Skip PRD orchestration If:**

- Fewer than 5 PRDs (sequential is fine)
- All PRDs have linear dependencies (can't parallelize)
- Single developer working sequentially

### New in Step 4: Flow Tree & Screen Architecture

**Step 4** is a new dedicated step for creating a **Mobbin-style Flow Tree** that comprehensively maps every screen in your application. This ensures:

- ✅ **No lazy screens** - Every flow (login, onboarding, settings) is mapped
- ✅ **90% app visibility** - You know what your app looks like before building
- ✅ **Screen inventory** - Complete list with names, complexity, priorities
- ✅ **Transition map** - How screens connect and flow to each other

**Example Output:**

```
📱 App Flow Tree
├── 🔐 Authentication (8 screens)
│   ├── Login (3 screens)
│   ├── Registration (3 screens)
│   └── Password Recovery (2 screens)
├── 🏠 Main Navigation (4 screens)
│   ├── Home (1 screen)
│   ├── Search (1 screen)
│   └── Profile (2 screens)
├── ⚙️ Settings (12 screens)
│   ├── Account (4 screens)
│   ├── Preferences (3 screens)
│   └── Support (5 screens)
└── Total: 24 screens mapped
```

[Additional workflow details, troubleshooting, and best practices available in individual step files]

---

## After Steps 0–15 (Execution Phase)

Planning ends at Step 15. Execution starts next.

See **[AFTER-STEP-15.md](./AFTER-STEP-15.md)** for the plain-English sequence: `/gtm` (the go-to-market conductor) sequencing the Run Tracks, `@dev-loop`, per-PRD `@gap-analysis`, 8-gate pipeline, and ship.

---

**Last Updated:** 2026-06-29
**Version:** 1.0.0-alpha.1 (with Agentic Layer, Grade 4 Self-Correcting Loops, .sigma/tools/ Integration)
**Status:** ✅ Production Ready

See `docs/SIGMA-VERSIONING.md` for the canonical step registry and cascade rules.
