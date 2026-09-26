---
description: "Step 2: Architecture → ARCHITECTURE.md — system design with C4, ADR, quality attributes, trust boundaries, and AI-native output formatting for downstream agent consumption"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --research-depth
  - --architecture-profile
---

<!-- HITL-GATE-POLICY:start -->
## ⛔ HITL Gate Contract (read before running any phase)

This step is **human-in-the-loop**. Every `<HARD-GATE>` below is a **hard stop**. Obey these rules exactly — they override any default to "keep going."

**Runtime adapter:** `AskUserQuestion` below means the host's supported user-question mechanism, not a required tool identifier. Use an available structured question tool only when it permits this kind of question. Otherwise ask in a normal response and end the turn at the gate. A tool that cannot collect approval is not an approval substitute. Frontmatter controls are host-specific: supported `allowed-tools` can preapprove tool access. Tool access does not authorize actions outside the user's scope or satisfy a phase, release or production approval.

1. **Ask, then wait.** At each `<HARD-GATE>` you MUST call `AskUserQuestion` and receive an **actual answer from the user** before starting the next phase. Producing the analysis for a phase is allowed; *advancing past its gate* is not, until the user answers.
2. **A non-answer is NOT approval.** If `AskUserQuestion` returns no response, times out, or says the user is away — **PAUSE the step and wait**. Do not "proceed on best judgment," do not draft the remaining phases, do not infer approval from silence. Save what you have, tell the user the step is paused at Phase _X_ awaiting their answer, and stop. Re-ask when they return.
3. **One gate per phase — never collapse them.** Ask each phase's gate at its own phase boundary (A, then B, then C…). Do not batch several phases into a single question, and do not run multiple phases and ask once at the end. The founder decides at every boundary.
4. **The only way to skip gates** is an explicit, up-front instruction from the user in *this* run — e.g. "run all phases without stopping," "autonomous mode," or "don't ask me, just draft it." Absent that explicit opt-in, gates are mandatory. Being mid-task, low on time, or unattended is never such an opt-in.
5. **Everything before an approval is a draft.** Nothing a gate guards is "locked" or "done" until the user has approved it at that gate.

**Explicit unattended runs:** Record the user's opt-in and its scope once. Complete authorized phases and local verification without repeatedly asking for the same permission. Mark decisions made under that delegation as assumptions or delegated decisions, not fabricated user answers. Unattended drafting does not grant release, spending, destructive-action or production authority. A genuine missing decision may block one part while independent authorized work continues.

> If you find yourself about to write the next phase without a user answer to the current gate, STOP — that is the exact failure this contract prevents.
<!-- HITL-GATE-POLICY:end -->

<!-- GAME-DOMAIN:start -->
## Conditional game-domain adaptation

Apply this section only when `docs/stack-profile.json` records `projectDomain: "game"`. A missing value means `general`; do not infer a game domain from product language. Keep this step's number, phases, outputs, gates, business functions, GTM, context, and handoff intact.

Read the selected entry from the canonical game-development catalog when it is available. Use only the workflows and questions applicable to the recorded game profile. If applicability is unknown, record it as unresolved; defer or skip work only with a reason. The catalog adapts this step. It does not create an alternate numbered sequence.

- Default to a solo creator. Contributor idea packs are separately authored, workspace-visible planning inputs; synthesis is an explicit creator decision that preserves selected revisions, attribution, disagreement, and rejected alternatives.
- Treat prototypes, art, audio, engine setup, imports, builds, performance measurements, multiplayer checks, and playtests as external execution. This Protocol step may prepare a decision, brief, checklist, or evidence requirement. Mark execution evidence `NOT-EXECUTED` until real evidence is attached and reviewed.
- Choose the smallest experiment that tests the current uncertainty. Do not require paper prototypes, outside testers, fixed art freezes, an engine, a team size, a schedule, or a downstream production method unless the creator records why it applies.
- Keep claims classified: source text, observed evidence, source claim, untested integration, or proposed adaptation. Preserve the catalog source IDs and linked research when creating game artifacts.

<!-- GAME-DOMAIN:end -->

<!-- SKILLS-INVOKE:start -->
## Required skills — invoke the live skills (do NOT rely on embedded summaries)

This step's output quality depends on these skills. **Invoke each via the host's installed Skill catalog by name at the relevant phase.** If the host cannot resolve that name, read the project source at `src/skills/<skill>/SKILL.md`, then the bundled `.agents/skills/<skill>/SKILL.md` when present. Do not rely on embedded summaries.

- `game-development` — conditional when `projectDomain: "game"`; select this step's catalog entry and applicable workflow

- `senior-architect`
- `architecture-patterns`
- `architecture-template`
- `api-design-principles`
- `deep-research`
- `decisions-patterns`
- `shadcn` — Decision 4 (web component library)
- `rn-component-library` — Decision 4b (mobile component library)
- `expo` — Decision 4b / mobile stack
- `react-native-patterns` — curated preflight (mobile Expo)

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-2-architecture — Deep Architecture Decisions and System Boundaries

**On start, announce:** "Running Step 2: Architecture. I'll walk you through 5 phases — importing context, identifying drivers, evaluating options, designing the target architecture, and producing the canonical ARCHITECTURE.md."

<goal>
You are the Architecture Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & Select Profile | Locked architecture profile + imported decisions |
| B | Architecture Drivers | Constraints, quality attributes, integration pressure |
| C | Options & Tradeoffs | 2-3 viable directions + ADR summary |
| D | Target Architecture | C4 views, boundaries, deployment, trust model |
| E | Output, Hardening & Handoff | ARCHITECTURE.md with Step 8/14 handoffs |

Final Output: `docs/architecture/ARCHITECTURE.md` (+ optional `docs/architecture/adrs/ADR-*.md`)

Quality gate: 95+/100 on verification schema.

**AI-native output rule:** ARCHITECTURE.md is consumed by AI agents in Steps 8, 10, 11, and 14. Every section must be structured (bullet points, tables, predicates) — not narrative prose. Agents cannot ask follow-up questions, so zero ambiguity.
</goal>

---

## Step Boundary

- **Trigger:** Run after Step 1 (or Step 1.5 if monetized). Requires `docs/specs/MASTER_PRD.md` and optionally `docs/specs/OFFER_ARCHITECTURE.md`.
- **Step 2 owns:** architecture drivers, profile, options, chosen structure, C4 views, domain/data boundaries, integrations, trust boundaries, quality attribute scenarios, ADR summary, handoffs.
- **Step 2 does NOT own:** full API specs, full schema packs, security runbooks, infrastructure runbooks, runtime scaffolding → **Step 8** and **Step 14**.
- **Do NOT** write implementation-level detail. Do NOT create runtime files. Do NOT absorb Step 8 or Step 14 work.
- **Fallback:** If MASTER_PRD.md is missing, prompt user to run Step 1 first. If Step 1.5 was expected but skipped, note monetization gaps as open risks.

---

## Linear Tracking (Conditional)

<!-- linear-tracking: canonical task-tracking block. Linear is primary when detected; GitHub Issues is the default fallback board (the SigmaHQ kanban was retired 2026-07-11). Included by steps under their own heading. -->

Task tracking has two supported boards — use whichever the user has:

**Linear (primary when detected).** Linear is configured when BOTH hold:
- `security find-generic-password -s LINEAR_API_KEY -w` returns a key (GraphQL endpoint `https://api.linear.app/graphql`, header `Authorization: <key>`, no Bearer prefix)
- `runtime-baseline.json` shows `linear.project: "<Linear project name>"` (each repo maps to exactly one Linear project; team is derived from the project)

When configured, mirror step progress as issues in `linear.project` via GraphQL `issueCreate` / `issueUpdate` (see Step 0 → Linear Operations Reference for the concrete queries): create a tracking issue when the step starts (state In Progress) and move it to Done when the step's primary output lands.

**GitHub Issues (default fallback).** When Linear is not configured, GitHub Issues is the task board — create wave-labeled issues in the project repo (`gh issue create --label "wave:W0" --title "…"`) and close them as work lands. This is a first-class path, not a degraded one: many protocol users run entirely on GitHub. File-based artifacts (`TASKS.md`, `.prd-status.json`) remain the offline fallback where a step defines one.

**Wave labels are MANDATORY on every created issue — an unlabeled issue is a defect** (same labels on either board). Planning/status issues (Steps 0–10, Run Track) carry `wave:W0`; execution issues carry their build-sequence wave (`wave:W1`, `wave:W2`, …) from Step 10 sequencing / Step 11.5 waves. Also label issues with the step name (e.g. `step-3`) so later steps can find them.

Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop regardless of which board you track on; when Linear is connected, its issues two-way-sync to GitHub once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

**Step-specific issues (when Linear is configured):**
- Phase A start: create issue "Step 2: Architecture Design in progress" — labels `step-2`, `wave:W0`, state In Progress.
- On direction lock (Phase C approved): create issue "Step 2: Architecture direction locked" — labels `step-2`, `wave:W0`.
- On ARCHITECTURE.md completion (Phase E): move the tracking issue to Done and create "Step 2: ARCHITECTURE.md complete" — labels `step-2`, `milestone`, `wave:W0`.

---

## Architecture Profile (select exactly one)

| Profile | When | Optimize for |
|---------|------|-------------|
| `bootstrap` | Early product, small team, fastest safe path | Clarity, low ops overhead, changeability. Prefer modular monolith unless evidence justifies more. |
| `growth` | Meaningful traffic, paid users, expanding team | Modularity, observability, evolution. Clear service boundaries without premature fragmentation. |
| `regulated` | Compliance, auditability, data handling drive the architecture | Traceability, trust boundaries, security controls, operational discipline. |
| `scale-critical` | Exceptional throughput, reliability, or global distribution | Capacity, isolation, resilience, failure containment. Justify with real signals — don't claim casually. |

---

## Multi-Layer Architecture Model

Reason through the system in layers, not just boxes and arrows:

1. **Experience** — web, mobile, admin, partner, CLI, API consumers
2. **Application** — routes, controllers, orchestration, workflows, use cases
3. **Domain** — entities, aggregates, bounded contexts, business rules
4. **Data** — databases, ledgers, caches, queues, search, files, analytics sinks
5. **Infrastructure** — hosting, compute, networking, secrets, CI/CD, observability
6. **Agent Runtime (when applicable)** — product/runtime workflows and their boundaries; coding-agent hosts remain an operator/development concern

If a decision in one layer creates consequences in another, document the dependency.

---

## Framework Library

Use to drive decisions. Skip frameworks that don't apply. Each must end in a decision, not commentary.

### Evolutionary Architecture — Ford, Parsons and Kua; Fowler's foreword
- Shared architectural understanding over rigid blueprints
- Enable safe evolution — resist big-design-up-front theater
- Align architecture to real system drivers, not hypothetical scale
- Use measurable architectural fitness functions where a quality attribute needs continuous protection. [Primary reference](https://martinfowler.com/articles/evo-arch-forward.html).

### Clean Architecture / Dependency Direction
- Dependencies point inward (domain knows nothing about delivery)
- Separable use-case logic, framework independence where it matters
- Don't apply dogmatically — monoliths with clean boundaries beat over-abstracted services

### Evans — DDD & Bounded Contexts
- Ubiquitous language per bounded context
- Aggregate boundaries define consistency lines
- Separate core domain from supporting domains and generic infrastructure
- Only apply when domain complexity justifies it — don't DDD a CRUD app

### Ousterhout — Complexity Reduction
- Deep modules over shallow, over-exposed interfaces
- Information hiding, cognitive load reduction
- If a decision adds complexity without solving a real problem, reject it

### Simon Brown — C4 Model
- **Required:** System Context + Containers
- **Optional:** Components (only when a container has enough internal complexity)
- Do NOT create component diagrams just because C4 has them

### ADR Discipline
Each major decision records: context, decision, consequences, alternatives considered.
If 3+ major decisions are substantial, create separate `docs/architecture/adrs/ADR-*.md` files.
ADRs are agent-readable decision records: every downstream agent (Step 8 blueprint, Step 11 PRDs, the runtime fleet) reads them to avoid re-litigating settled choices. Write each ADR so an agent can answer "was X already decided, and why?" from the file alone — this is the same `decisions.md` convention applied at the architecture layer. State the decision as a durable rule, not a meeting note.

### Quality Attribute Scenarios
For each quality attribute, write as machine-verifiable predicates:
- **Stimulus:** [what triggers the scenario]
- **Environment:** [under what conditions]
- **Response:** [measurable expected outcome]
- **Architectural implication:** [what this forces]

Address at minimum: performance, reliability, security, maintainability, observability, cost/operational simplicity.

### Threat Modeling & Trust Boundaries
- Identity boundaries, data sensitivity boundaries, external system boundaries
- Privileged/internal-only surfaces
- Monetization abuse paths when Step 1.5 is in play
- Rate limiting and quota enforcement at trust boundary crossings

---

## Phase A — Import Context & Select Profile

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json`, `docs/specs/MASTER_PRD.md`, `docs/stack-profile.json`.
3. Read `.sigma/boilerplate.json` if present — document extensions vs inherited baseline.
4. Read `docs/specs/OFFER_ARCHITECTURE.md` and `docs/specs/pricing-config.json` if Step 1.5 was run.
5. If `research_mode = blocked` → stop. If `reduced` → continue with assumption labels.
6. If `.sigma/boilerplate.json` is **absent** → run boilerplate catalog preflight (below).
7. Before component-library decisions → run curated libraries preflight (below).

#### Boilerplate catalog (required when no `.sigma/boilerplate.json`)

Do **not** guess template names. Read the machine catalog and rank options:

1. **Read** `templates/boilerplates/catalog.json` (framework + product templates).
2. **Read** `templates/boilerplates/_shared/module-catalog.json` for module IDs when discussing features.
3. **Read** `docs/references/integration-packs-catalog.md` for integration pack summaries.
4. **Map** platform + product type from `docs/stack-profile.json`, `MASTER_PRD.md`, or Phase A/C decisions:

| Signal | Prefer catalog entries |
|--------|------------------------|
| Mobile app, IAP | `expo-mobile`, `products/mobile/*` |
| Full SaaS web | `nextjs-saas`, `tanstack-saas` |
| AI-first / real-time | `nextjs-ai`, `products/ai-tools` |
| Self-host / portable | `nextjs-portable` |
| Courses / gamification | `products/mobile/learning-platform` |
| Trading / fintech | `products/mobile/fintech` |

5. **If** `.sigma/boilerplate.json` already exists → document inherited template in the environment/architecture report; **skip** AskUserQuestion picker.
6. **If** greenfield (no boilerplate, no root `package.json`) → present top 3 catalog matches via AskUserQuestion with `id`, `stack`, and `use_when`.
7. **On selection** → record `boilerplateCandidate` in `docs/stack-profile.json` and instruct user to run `@new-project --template=<id>` (or clone product path from catalog `path` field) before Step 2 locks architecture.
8. **Status gate** — omit catalog entries with `"status": "stub"` unless user explicitly wants a stub shell; prefer `"status": "ready"` or `"status": "built"`.

#### Curated component library reference (read before UI stack decisions)

Before offering component-library, chart, or gamification options:

1. **Read** `docs/references/CURATED-COMPONENT-LIBRARIES.md` (web, mobile, charts, trophies, boilerplate map).
2. **Map platform** → default library from the doc's tables; **do not** offer Tamagui as default on Expo + NativeWind stacks.
3. **Record** in `docs/stack-profile.json`:
   - `componentLibrary` — e.g. `shadcn/ui`, `react-native-reusables`
   - `chartsLibrary` — e.g. `@bklit/charts` (mobile), `tremor` or `recharts` (web)
   - `gamification.reference` — when PRD includes XP/achievements/trophies
4. **Invoke skills** at decision time (not from memory):
   - Web/desktop React → `shadcn`
   - Mobile Expo → `rn-component-library`, `react-native-patterns`
   - Gamification / collectibles → `companion-system` (in addition to learning-platform refs)

### Sequential Decisions

**Decision 1: Architecture Profile**
Use AskUserQuestion: "What architecture profile fits this product?"
Options: [Bootstrap — fastest safe path, Growth — modularity + observability, Regulated — compliance-first, Scale-critical — exceptional throughput/reliability]

**Decision 2: Monorepo vs Polyrepo** (if not already decided)
Use AskUserQuestion: "Repository structure?"
Options: [Monorepo (Turborepo/pnpm workspaces), Polyrepo (separate repos), Already decided in Step 1]

**Decision 3: Primary Stack Confirmation**
Present stack from `stack-profile.json`. Use AskUserQuestion: "Confirm or change the primary stack?"
Options: [Confirm stack as-is, Change frontend, Change backend, Change database, Full stack discussion needed]

**Decision 4: Component Library** (if the selected frontend needs one)
Select a library only when it fits the chosen stack and host. Before locking it, record framework compatibility, dependency availability or actual install result, host/browser constraints, and the native primitive fallback for any unavailable capability. Do not describe an absent package, registry, browser API, or host capability as installed.

For React web, shadcn/ui is one option, not a universal requirement. For native, desktop, or a stack that already provides suitable primitives, select the appropriate platform-native or installed library instead.

Use AskUserQuestion: "Which component approach fits the confirmed frontend and host?"
Options: [Existing or native primitives (Recommended when sufficient), shadcn/ui — compatible React web stack, Different compatible library, Not applicable — no component library needed]

If shadcn is selected, confirm a supported CLI or MCP route and the project prerequisites before initialization:
- Run `shadcn init` (or `shadcn init --preset [code]` if a preset is already chosen)
- Record in `stack-profile.json`: `"componentLibrary": "shadcn/ui"`
- This unlocks theme preset mapping in Step 3, block scaffolding in Step 5, and preset export in Step 6

Record the feasibility result with the decision. If a desired capability is blocked, name the native fallback and give it separate verification rather than treating the library choice as proof it works.

**Decision 4b: Mobile component library** (if platform is mobile or cross-platform includes Expo)
Use AskUserQuestion only after reading `docs/references/CURATED-COMPONENT-LIBRARIES.md`:
Options: [React Native Reusables + NativeWind (Recommended — Sigma default), Custom library — declare in stack-profile with ADR, Not applicable — not a mobile project]

If Reusables selected:
- Record `"componentLibrary": "react-native-reusables"` and `"styling": "nativewind"` in `stack-profile.json`
- Invoke `rn-component-library` for install patterns
- **Do not** offer Tamagui unless user explicitly rejects Reusables with documented reason (ADR)

**Decision 4c: Charts library** (if PRD includes analytics, trading, portfolio, or dashboard charts)
Options from curated doc only:
- Mobile → `@bklit/charts` (record `chartsLibrary` in stack-profile)
- Web dashboard → `tremor` or `recharts`
- None / defer to Step 8

**Decision 5: Boilerplate lock** (only when `.sigma/boilerplate.json` was absent at preflight)
If user picked a catalog template in preflight but has not run `@new-project` yet:
Use AskUserQuestion: "Apply boilerplate now or continue architecture on empty repo?"
Options: [Run @new-project with chosen template before Phase B, Continue — architecture only, defer scaffold, Already applied — confirm path]

### Import Summary Table

| Source | Key Decisions Imported | Open Questions |
|--------|----------------------|----------------|
| Step 0 | runtime, research mode | |
| Step 1 | users, scope, P0 features, build order | |
| Step 1.5 | pricing model, entitlements, billing | |
| stack-profile | framework, database, hosting | |

<HARD-GATE>
Do NOT proceed to Phase B until user approves profile + stack + imports.
Use AskUserQuestion: "Context imported, profile selected. Approve?"
Options: [Approve — identify architecture drivers, Change profile, Revisit stack decisions]
</HARD-GATE>

---

## Phase B — Architecture Drivers

### Required driver categories

Document each as: driver → why it matters → which layer(s) affected → what breaks if ignored.

1. **Functional drivers** — what the system must do (from MASTER_PRD P0 features)
2. **Quality attributes** — performance, reliability, security, observability targets
3. **Compliance / data constraints** — privacy, data residency, audit requirements
4. **Team / budget / timeline constraints** — what limits the architecture options
5. **Integration constraints** — external services, APIs, vendor lock-in risks
6. **Monetization constraints** — entitlements, billing, usage metering, credit systems (if Step 1.5)
7. **Agent runtime applicability** — record exactly one: `none`, `embedded feature`, `internal automation`, or `independently deployed agent system`. For a non-`none` choice, name the trigger, operator, data boundary, and kill condition. `none` defers Step 14 runtime design rather than inventing an agent layer.

### Architecture Pressure Questions (answer explicitly)

- What must scale first?
- What must remain simple first?
- What data must be protected differently?
- What integrations are hardest to replace?
- What product constraints push the architecture most?

If Step 1.5 exists:
- What monetization model changes the architecture?
- Do credits/quotas/seats create data model or API consequences?
- Do entitlements affect trust boundaries or abuse prevention?

### Research (directive queries)

1. Search `"[primary stack] [architecture pattern] best practices 2026"` — validate stack fit
2. Search `"[integration] API architecture patterns"` — for each critical integration
3. If regulated: Search `"[compliance framework] architecture requirements"` — compliance constraints

### Agent-runtime boundary method (when applicability is not `none`)

Keep these boundaries separate in the driver record and later C4 view:
- frontend/experience; backend/domain services; durable workflow/runtime; and model gateway;
- **MCP** for model/client access to tools and resources; **ACP** for an editor/client session with a coding agent; **A2A** only for independently deployed remote agents exchanging tasks and artifacts;
- a coding-agent host (for example, Claude Code or Codex) versus a product agent runtime. The former does not create the latter.

For every tool or remote agent, record caller subject, tenant, scopes, approval state, data touched, and audit correlation ID. Durable work also needs a resumable state, idempotency key, retry/cancellation policy, and a human approval resume point. Treat a framework or protocol as an option, not a default: its ADR records version/maturity, auth model, data residency, export path, lock-in, and replacement plan.

Method references checked 2026-09-19: [MCP authorization and tools](https://modelcontextprotocol.io/specification/2025-06-18/server), [A2A task exchange](https://github.com/a2aproject/A2A/blob/main/docs/specification.md), [ACP editor-agent sessions](https://github.com/agentclientprotocol/agent-client-protocol/blob/main/docs/protocol/v2/overview.mdx), [Eve durable-agent preview](https://vercel.com/blog/introducing-eve).

<HARD-GATE>
Do NOT proceed to Phase C until user approves drivers.
Use AskUserQuestion: "Architecture drivers mapped. Approve?"
Options: [Approve — evaluate architecture options, Add more drivers, Adjust priorities]
</HARD-GATE>

---

## Phase C — Options & Tradeoffs

Evaluate 2-3 realistic directions. Do NOT invent unrealistic options to pad.

### For each option, document:

| Dimension | Answer |
|-----------|--------|
| Architecture style | [modular monolith / service-oriented / serverless / event-driven / etc.] |
| Why it fits | [specific project reasons] |
| Why it may fail | [specific risks] |
| Operational cost | [hosting, DevOps complexity] |
| Team complexity | [learning curve, coordination overhead] |
| Evolution path | [how it grows with the product] |
| Profile fit | [bootstrap / growth / regulated / scale-critical] |
| Agent-runtime fit | [none / embedded feature / internal automation / independent system, with trigger and exit criteria] |

### ADR Summary

Record at least one ADR-style decision for:
- Architecture style decision
- Deployment/runtime shape decision
- Data/integration boundary decision
- Frontend component feasibility decision when a user-facing surface exists: chosen stack/host, compatible primitive or library, dependency/install evidence, constraints, and any native fallback.

Format: Context → Decision → Consequences → Alternatives Considered

<HARD-GATE>
Do NOT proceed to Phase D until user approves chosen direction.
Use AskUserQuestion: "Architecture direction selected. Approve?"
Options: [Approve [chosen option] — design target architecture, Choose different option, Need more research]
</HARD-GATE>

---

## Phase D — Target Architecture

Design the chosen architecture deeply enough that Steps 8, 10, 11, and 14 inherit the right shape.

### Required sections (all must be present):

**1. Executive Architecture Summary**
- Chosen style, profile, dominant drivers, dominant tradeoffs (3-5 sentences max)

**2. C4 System Context**
- Users/actors, your system, external systems, primary trust boundaries
- Use text-based diagram notation (Mermaid or ASCII)

**3. C4 Containers**
- Frontend surfaces, backend/services, data stores, queues/caches/search, external integrations
- For each container: responsibility, technology, communication pattern
- For each user-facing container: selected component approach, host/browser constraints, and any capability that must use a verified native fallback

**4. Domain & Data Boundaries**
- Bounded contexts or logical domains with ownership lines
- Consistency boundaries, aggregate roots
- Data sensitivity tiers
- Entitlement/ledger/usage implications when monetized

**5. Integration Inventory**

| Integration | Purpose | Criticality | Failure Mode | Replacement Difficulty | Trust Implications |
|-------------|---------|-------------|-------------|----------------------|-------------------|

**6. Deployment & Runtime Topology**
- Hosting shape, scaling strategy, observability posture (matched to profile)

**7. Trust Boundaries & Threat Model**
- Ingress, auth/identity, privileged surfaces, sensitive data flows
- Abuse risks from monetization, quotas, public APIs

**8. Quality Attribute Scenarios**
Write as predicates:
```
WHEN [stimulus] UNDER [environment] THEN [measurable response] BECAUSE [architectural mechanism]
```

**9. Boundary Tier System** (Addy Osmani pattern — for downstream agents)
```
✅ ALWAYS: [safe actions requiring no approval — e.g., "read any file in src/"]
⚠️ ASK FIRST: [high-impact changes needing review — e.g., "modify auth middleware"]
🚫 NEVER: [hard stops — e.g., "never commit secrets", "never bypass rate limiting"]
```

**10. Agent Runtime Decision**
- Applicability choice: `none`, `embedded feature`, `internal automation`, or `independently deployed agent system`; `none` records why Step 14 is deferred.
- A boundary diagram labels frontend, backend, durable workflow (if any), MCP, ACP, and A2A only where they apply.
- For each selected tool/remote agent: caller identity, tenant/scopes, approval requirement, data touched, audit ID, and side-effect boundary.
- For durable work: restart/resume, idempotency, retry/cancel, and human-approval resume behavior. For selected vendors (including Eve, Hermes, or OpenClaw), ADRs document beta/operational fit and exit criteria; no dependency is implied.

**11. File Structure** (for downstream agent consumption)
```
[Suggested directory layout matching the architecture]
```

<HARD-GATE>
Do NOT proceed to Phase E until user approves target architecture.
Use AskUserQuestion: "Target architecture designed. Approve?"
Options: [Approve — write final document, Revise boundaries, Adjust deployment topology, Need more detail on a section]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Missing boundaries or weak trust model
- Shallow quality attribute scenarios
- Step 8/14 work improperly absorbed into Step 2
- Architecture decisions without documented tradeoffs
- Contradictions with MASTER_PRD or OFFER_ARCHITECTURE
- Component-library claims that lack compatibility, dependency/install, or host-capability evidence

Fix findings before presenting.

### Write `docs/architecture/ARCHITECTURE.md`

Required sections (in order):
```
Executive Architecture Summary
Architecture Profile
Imported Inputs & Assumptions
Architecture Drivers
Frontend Component Feasibility
Evaluated Options & Tradeoffs
Chosen Direction
ADR Summary
C4 System Context
C4 Containers
Domain & Data Boundaries
Integration Inventory
Deployment & Runtime Topology
Trust Boundaries & Threat Model
Quality Attribute Scenarios
Boundary Tier System (Always / Ask First / Never)
Agent Runtime Decision
Suggested File Structure
Step 8 Handoff — what implementation detail Step 8 must elaborate
Step 11 Implications — what architecture constraints PRDs must respect
Step 14 Handoff — what runtime Step 14 must wire
Do NOT Build in This Step — what was intentionally deferred
Open Risks & Deferrals
```

### Writing Standards (embedded)

- No stock AI phrases: "Robust", "Seamless", "Leverage", "Ecosystem", "Scalable" (unless quantified), "Best-in-class"
- Start with decisions, not industry commentary about architecture trends
- Commit to choices — no "we might consider" hedging
- Write like a principal engineer, not a architecture blog post
- Every claim traces to a driver, constraint, or ADR
- Diagrams in text notation (Mermaid preferred) — no placeholder boxes

### Success Criteria

- [ ] Architecture profile is explicit and justified
- [ ] Drivers are explicit and traceable to product decisions
- [ ] Frontend component approach is feasible for the chosen stack and host; dependency/install evidence and any native fallback are explicit
- [ ] Options and rejected alternatives are documented with tradeoffs
- [ ] C4 context and container views present
- [ ] Trust boundaries documented
- [ ] Quality attribute scenarios as predicates
- [ ] Boundary tier system (Always/Ask/Never) present
- [ ] Step 8 handoff explicit
- [ ] Step 14 handoff explicit, including a documented `none` decision when no product runtime applies
- [ ] Non-`none` runtime decisions distinguish MCP, ACP, and A2A boundaries and map tool/agent identity, scope, approval, and audit evidence
- [ ] No Step 8/14 work absorbed into Step 2
- [ ] File structure suggested for downstream agents
- [ ] $holes pass completed
- [ ] User approved
- [ ] Linear tracking issues created (when configured)

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 3 without explicit approval.
Use AskUserQuestion: "Step 2 complete. Ready for Step 3 — UX Design?"
Options: [Proceed to Step 3, Revise architecture, Run additional research]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 2 Verification Schema

### Required Outputs (30 points)

| Item | Path | Points |
|------|------|--------|
| Architecture Document | docs/architecture/ARCHITECTURE.md | 30 |

### Required Sections (40 points)

| Section | Points |
|---------|--------|
| Architecture Profile (justified) | 6 |
| Architecture Drivers (traceable) | 6 |
| Chosen Direction + Tradeoffs + Rejected Alternatives | 6 |
| ADR Summary | 4 |
| C4 System Context | 5 |
| C4 Containers | 5 |
| Trust Boundaries & Threat Model | 4 |
| Quality Attribute Scenarios (as predicates) | 4 |

### Handoff Integrity (20 points)

| Check | Points |
|-------|--------|
| Step 8 Handoff explicit | 7 |
| Step 14 Handoff explicit | 7 |
| No Step 8/14 scope absorbed | 3 |
| Boundary Tier System present | 3 |

### Quality Indicators (10 points)

| Check | Points |
|-------|--------|
| Profile fit justified with real signals | 3 |
| Monetization effects integrated (when Step 1.5 ran) | 3 |
| File structure suggested for downstream agents | 2 |
| $holes pass completed | 2 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100
</verification>

$END$
