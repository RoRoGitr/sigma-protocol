---
description: "Step 10: Feature Breakdown → FEATURE-BREAKDOWN.md — shape features, set appetites, map dependencies, decide which work deserves Step 11 PRDs"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --min-complexity
  - --appetite
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

- `prd-patterns`
- `hormozi-frameworks`
- `companion-system`
- `rn-component-library`

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-10-feature-breakdown — Feature Shaping, Story Mapping & PRD Eligibility

**On start, announce:** "Running Step 10: Feature Breakdown. I'll shape features, set appetites, map dependencies, and decide which work deserves dedicated Step 11 PRDs."

<goal>
You are the Feature Shaping Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context & Outcome Mapping | Outcome-to-feature map + story backbone |
| B | Feature Shaping & PRD Eligibility | Shaped features + PRD eligibility table |
| C | Appetites, Boundaries & Rabbit Holes | Scope decisions + risk flags |
| D | Dependencies & Sequencing | Dependency map + implementation order |
| E | Output, Hardening & Handoff | FEATURE-BREAKDOWN.md + Step 11 handoff |

Required Output: `docs/implementation/FEATURE-BREAKDOWN.md`

Conditional (only when complexity warrants): `docs/implementation/BETTING-TABLE.md`, `docs/implementation/FEATURE-DEPENDENCIES.md`, `docs/implementation/PRD-ROADMAP.md`

Quality gate: 95+/100 on verification schema.

**Core rule:** Step 10 decides WHAT deserves a PRD. Step 11 writes the PRDs. Don't blur the boundary.

**AI-native output rule:** The PRD Eligibility Table is consumed by Step 11 agents to generate PRDs. It must be a structured table with explicit Yes/No decisions — not prose.
</goal>

---

## Step Boundary

- **Step 10 owns:** outcome-to-feature mapping, story map structure, appetites, boundaries, rabbit holes, dependency mapping, vertical-slice readiness, PRD eligibility decisions, feature sequencing.
- **Step 10 does NOT own:** technical blueprint (Step 8), feature-level PRD writing (Step 11), architecture re-decisions (Step 2).
- **Do NOT** write implementation PRDs. Decide what DESERVES a PRD, then hand off to Step 11.

---

## Shaping Principles

### Outcome Mapping
Every feature traces to a real outcome. If it doesn't serve a user or business outcome from the MASTER_PRD, it doesn't belong.

Keep the chains distinct: desired outcome → opportunity → candidate solution (continuous discovery), then user activity → story backbone → release slice (story mapping). An outcome map is not a task list.

### Story Mapping (Jeff Patton)
Group features by user journey and release slices, not technical layers. The walking skeleton comes first — the minimum path that proves the product works end-to-end.

### Shape Up Appetites (Basecamp)
Appetite = willingness-to-spend, not estimation theater.
Set a fixed, project-appropriate time budget and let scope vary within it. Record the no-go scope, rabbit holes, unresolved risk owner, and the condition that stops or reshapes the bet. Do not treat a fixed day range as a universal appetite scale.

### INVEST (user story quality gate)
A feature is PRD-worthy only when it passes:
- **I**ndependent — can be built without tangling with other features
- **N**egotiable — scope can flex within boundaries
- **V**aluable — delivers real user value, not just technical infrastructure
- **E**stimable — shaped enough to appetite
- **S**mall — fits in a batch
- **T**estable — acceptance criteria are clear

### Vertical Slices (Tech Lead Handbook)
Each user-facing PRD-eligible feature should be a coherent, releasable path through the layers it needs. A valid slice must be:
- **User-visible** — the user can see a change after it ships
- **User-valuable** — moves toward an outcome users care about
- **Complete enough to verify** — it may include UI, logic, and data, or it may be a bounded enabling slice with a named user-visible outcome and downstream integration owner

**Simplification strategy** for large features: start with a minimal "Hello World" slice (blank form, echoed response). Defer auth, validation, styling. Display unstyled data. Begin read-only before writes. Progressively refine.

**Anti-patterns:** horizontal slicing (UI form → API → database as separate tasks), disguised horizontal work (calling "set up database tables" a user story), features with no visible output.

### AI-Native Decomposition
When a PRD will be executed by agents, make the handoff concrete enough to verify. Add only the fields relevant to that execution lane:
- **Relevant context** — files, symbols, contracts, or source material needed to act
- **Allowed tools/runtime boundaries** — only where the task uses constrained tools or a specific environment
- **Clear acceptance predicates** — machine-verifiable "done" criteria
- **One vertical slice per task** — agent handles one complete slice, not a horizontal layer
- **No implicit context** — everything the agent needs is in the PRD, not assumed from prior conversation
- **Build order** — which slice first, what depends on what

The feature decision remains product-led. Agent-execution details make a selected slice actionable; they do not make every feature an agent task.

---

## Phase A — Import Context & Outcome Mapping

**Invoke `hormozi-frameworks`** to pressure-test outcome statements against the Value Equation before shaping features.

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `docs/specs/MASTER_PRD.md`, `docs/specs/OFFER_ARCHITECTURE.md` (if Step 1.5), `docs/architecture/ARCHITECTURE.md` (Step 2).
3. Read Step 4: `docs/flows/FLOW-TREE.md`, `docs/flows/SCREEN-INVENTORY.md`, `docs/flows/TRACEABILITY-MATRIX.md`.
4. Read Step 5: `docs/prds/flows/*/FLOW-*.md`, `docs/prds/flows/PRD-SUMMARY.md`.
5. Read Step 8: `docs/technical/TECHNICAL-SPEC.md`.
6. If `research_mode = blocked` → stop. If `reduced` → label assumptions.

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
#### Boilerplate module manifest (when `.sigma/boilerplate.json` exists)

1. **Read** `.sigma/modules.manifest.json` if present.
2. **Cross-check** Step 4 screen inventory / Step 10 features against enabled modules (`modules.*.enabled === true`).
3. **Record** inherited routes and module file paths in the step output — do not re-scaffold modules the boilerplate already ships.
4. **Module ID vocabulary** must match `templates/boilerplates/_shared/module-catalog.json` (see `docs/references/integration-packs-catalog.md`).

If manifest is missing but `boilerplate.json` exists → note as gap; do not invent module IDs.

### Outcome-to-Feature Map

For each product outcome from MASTER_PRD:

| Outcome | Candidate Features | Why Now | Why Later | Not a PRD |
|---------|-------------------|---------|-----------|-----------|

For each outcome, record the supporting opportunity, evidence source, candidate solution, and unresolved assumption before turning it into a story-map row.

### Story Map Backbone

Group features by user journey:
- **Walking skeleton** — minimum path proving the product works end-to-end
- **MVP** — minimum viable for first users
- **Enhancement** — improves the product after MVP
- **Deferred** — valuable but not now

<HARD-GATE>
Do NOT proceed to Phase B until user approves outcome map + story backbone.
Use AskUserQuestion: "Outcome map and story backbone complete. Approve?"
Options: [Approve — shape features, Adjust feature grouping, Add missing outcomes]
Approval means the user outcome, opportunity, release slice, and walking skeleton are explicit; candidate solutions and assumptions remain visible rather than being treated as facts.
</HARD-GATE>

---

## Phase B — Feature Shaping & PRD Eligibility

**Invoke `companion-system`** when any shaped feature includes gamification, trophies, collectibles, or achievement UX — flag PRD eligibility and dependencies explicitly.

### PRD Eligibility Table (the core deliverable of Step 10)

| Feature | User Outcome | Appetite | Dependencies | Vertical Slice? | PRD Required | Priority | Acceptance Evidence | Why |
|---------|-------------|----------|-------------|----------------|-------------|----------|---------------------|-----|
| [feature] | [outcome] | [fixed time budget] | [list] | Yes/No | **Yes/No** | P0/P1/P2 | [observable user outcome and verification] | [justification] |

### Rules

- `PRD Required: No` — work should fold into other implementation or platform work
- `PRD Required: Yes` — feature is shaped enough for Step 11 to write a full implementation PRD
- Every `Yes` feature must pass INVEST validation
- Every `Yes` feature must be expressible as a vertical slice
- Every `Yes` feature must state the meaningful user outcome and acceptance evidence; time logs alone do not prove completion
- P0 = walking skeleton / MVP must-have. P1 = should-have post-MVP. P2 = enhancement / deferred.

<HARD-GATE>
Do NOT proceed to Phase C until user approves PRD eligibility decisions.
Use AskUserQuestion: "PRD eligibility table complete. Approve?"
Options: [Approve — define appetites and boundaries, Change eligibility decisions, Add features]
Approval means each Yes/No is tied to a user outcome, appetite, dependencies, and observable acceptance evidence.
</HARD-GATE>

---

## Phase C — Appetites, Boundaries & Rabbit Holes

### For each PRD-eligible feature:

**Appetite:** A fixed time budget appropriate to the project and team. Scope flexes inside that budget.

**In-scope boundaries:** What this feature DOES (explicit, concrete)

**Out-of-scope boundaries:** What this feature does NOT do (explicit — prevents scope creep)

**Rabbit holes:** Known risks, unknowns, or complexity traps to watch for

**Unresolved risk owner:** Who resolves or accepts each material unknown before or during the bet

**Stop / reshape condition:** What evidence, boundary breach, or failed slice changes the plan

**No-go scope:** Things that LOOK related but are explicitly excluded

### Cross-Cutting Production Baseline

What rules from Step 8 apply to ALL features:
- Auth/ownership assumptions
- First-user/bootstrap behavior
- Seed/demo assumptions
- Testing expectations

<HARD-GATE>
Do NOT proceed to Phase D until user approves appetites + boundaries.
Use AskUserQuestion: "Appetites and boundaries defined. Approve?"
Options: [Approve — map dependencies, Adjust appetites, Flag rabbit holes]
Approval means the time budget, variable scope, no-go boundaries, rabbit holes, risk owner, and stop/reshape condition are explicit for every selected bet.
</HARD-GATE>

---

## Phase D — Dependencies & Sequencing

**Invoke `rn-component-library`** when mobile UI dependencies affect sequencing (shared Reusables primitives, chart packages, or navigation shells).

### Dependency Map

| Feature | Blocks | Blocked By | Can Parallelize With |
|---------|--------|-----------|---------------------|

When multiple agents will work in parallel, add handoff artifact, integration owner, conflict owner, and verification point. Omit agent fields when the work is not delegated.

### Implementation Sequence

1. **Foundation** — features with no dependencies (backbone/walking skeleton)
2. **Core** — P0 features in dependency order
3. **Enhancement** — P1 features after core is stable
4. **Deferred** — P2 features for later releases

### Conditional Artifacts

If complexity is high, generate separate files:
- `docs/implementation/FEATURE-DEPENDENCIES.md` — declare `Dependency Artifact: Yes` in main file
- `docs/implementation/PRD-ROADMAP.md` — declare `PRD Roadmap Artifact: Yes` in main file
- `docs/implementation/BETTING-TABLE.md` — declare `Betting Table Artifact: Yes` when competing bets need dedicated treatment

<HARD-GATE>
Do NOT proceed to Phase E until user approves dependencies + sequencing.
Use AskUserQuestion: "Dependencies and sequence mapped. Approve?"
Options: [Approve — finalize breakdown, Adjust sequence, Add dependencies]
Approval means the first vertical slice, integration ownership, and verification points are clear enough to sequence without hiding dependency risk.
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Features without clear outcomes
- PRD-eligible features that don't pass INVEST
- Missing dependencies or circular dependencies
- Appetite mismatches (Features that exceed their approved time budget and need reshaping)
- Step 11 handoff gaps

Fix findings before presenting.

### Write `docs/implementation/FEATURE-BREAKDOWN.md`

Required sections:
```
Outcome-to-Feature Map
Story Map Backbone (walking skeleton → MVP → enhancement → deferred)
Feature Shaping Rules Applied
PRD Eligibility Table (with P0/P1/P2 priorities)
Appetites & Boundaries (per PRD-eligible feature)
Rabbit Holes & Open Risks
Dependency Map
Implementation Sequence
Cross-Cutting Production Baseline
Step 11 Handoff
Do NOT Build in This Step
```

### Step 11 Handoff must state:
- Which features require PRDs (from eligibility table)
- In what order (from dependency map + sequence)
- What dependencies must be preserved
- What shaping assumptions must not be lost in PRD writing
- What cross-cutting baseline applies to all PRDs
- The user-visible outcome, acceptance evidence, unresolved-risk owner, and stop/reshape condition for every selected feature
- Agent execution context only where a delegated implementation lane needs it

### Linear Sync (when configured — Linear replaced the SigmaHQ kanban 2026-07-11)

When Linear is configured (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json — see Step 0 → Linear Operations Reference):

For each feature in the PRD Eligibility Table with `PRD Required: Yes`, create an issue via GraphQL `issueCreate`:
- title: `{feature name}`
- description: appetite (approved fixed time budget), priority (P0/P1/P2), dependencies, vertical-slice flag
- labels: `feature` + `prd-eligible` + the feature's build-sequence wave (`wave:W1` for the walking skeleton, incrementing per sequence batch). **Wave labels are MANDATORY on every created issue — an unlabeled issue is a defect.**
- priority: P0 → high, P1 → medium, P2 → low
- state: Todo

Establish blocking relationships between features that have dependencies via GraphQL `issueRelationCreate` (`type: blocks`), or record the dependency list in each issue's description when relations are impractical.

Linear becomes the source of truth for feature status when configured. Agents check Linear — not `.prd-status.json` — to know what needs PRDs.

**Pipeline continuity:** Step 11 discovers these issues by querying `linear.project` for label `feature`, state Todo, and updates them as PRDs are written. Use the `feature` + `prd-eligible` label pair consistently — Step 11 depends on it.

If Linear is not configured, track tasks as wave-labeled GitHub Issues in the project repo, or fall back to `.prd-status.json` for offline status. Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop; when Linear is connected its issues two-way-sync once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

If no features have `PRD Required: Yes`, skip issue creation.

### Downstream Handoff

Step 10 produces artifacts consumed by Step 11:

| Artifact | Consumed By | Purpose |
|----------|-------------|---------|
| `docs/implementation/FEATURE-BREAKDOWN.md` | Step 11 | PRD Eligibility Table, appetites, boundaries, sequence |
| `docs/implementation/FEATURE-DEPENDENCIES.md` | Step 11 | Dependency ordering for PRD writing sequence |
| `docs/implementation/PRD-ROADMAP.md` | Step 11 | Feature priority and batch planning |
| Linear issues labeled `feature` + `prd-eligible` | Step 11 | Status tracking during PRD writing |

Step 11 MUST be able to find all `PRD Required: Yes` features from the PRD Eligibility Table without re-running Step 10.

### Writing Standards (embedded)

- No stock AI phrases: "Comprehensive", "End-to-end", "Holistic approach"
- Feature names are concrete actions: "User can duplicate a timeline entry" not "Timeline Management"
- Appetite is a real fixed time budget with variable scope, not a generic size label or estimate
- Rabbit holes are real risks, not generic warnings
- Write like a product lead shaping work, not a PM filling a template

### Success Criteria

- [ ] Every feature traces to a MASTER_PRD outcome
- [ ] PRD Eligibility Table has explicit Yes/No per feature
- [ ] P0/P1/P2 priorities assigned
- [ ] Appetites are fixed time budgets with variable scope and explicit no-go boundaries
- [ ] Every PRD-eligible feature has observable user-outcome acceptance evidence
- [ ] Material rabbit holes have an owner and stop/reshape condition
- [ ] In/out scope boundaries explicit per feature
- [ ] Dependencies mapped with parallel opportunities identified
- [ ] Walking skeleton → MVP → enhancement sequence clear
- [ ] Cross-cutting baseline documented
- [ ] Step 11 handoff explicit
- [ ] $holes pass completed
- [ ] Linear feature issues created for PRD-eligible features (when configured)
- [ ] User approved

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 11 without explicit approval.
Use AskUserQuestion: "Step 10 complete. Ready for Step 11 — PRD Generation?"
Options: [Proceed to Step 11, Revise feature breakdown, Adjust priorities]
Approval means the selected work is outcome-led, bounded, and evidence-backed enough for Step 11; it does not substitute task activity for user-value acceptance.
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 10 Verification Schema

### Required Outputs (25 points)

| Item | Path | Points |
|------|------|--------|
| Feature Breakdown | docs/implementation/FEATURE-BREAKDOWN.md | 25 |

### Required Sections (35 points)

| Section | Points |
|---------|--------|
| Outcome-to-Feature Map | 5 |
| Story Map Backbone | 5 |
| PRD Eligibility Table (with P0/P1/P2) | 8 |
| Appetites & Boundaries | 5 |
| Rabbit Holes & Open Risks | 4 |
| Dependency Map | 4 |
| Implementation Sequence | 4 |

### Quality Indicators (30 points)

| Check | Points |
|-------|--------|
| Every feature traces to a real outcome | 6 |
| PRD Required = Yes features pass INVEST | 6 |
| Appetites are fixed time budgets with variable scope and no-go boundaries | 5 |
| Vertical slices identified (not horizontal layers) | 5 |
| Dependencies enable parallel work where possible | 4 |
| Walking skeleton is explicit | 4 |

### Handoff & Boundary (10 points)

| Check | Points |
|-------|--------|
| Step 11 handoff explicit | 3 |
| No Step 11 PRD writing absorbed | 3 |
| $holes pass completed | 3 |
| Linear feature issues created (when configured) | 1 |

**Passing score:** 95/100
</verification>

$END$
