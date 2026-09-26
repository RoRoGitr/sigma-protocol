---
version: "3.1.0"
last_updated: "2026-09-19"
description: "Step 11: PRD Generation → implementation-ready feature PRDs that autonomous AI agents can execute overnight with zero clarification needed"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --feature-id
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
- `bdd-scenarios`
- `audit-verify-prd`
- `karpathy-guidelines`
- `ponytail`
- `shadcn`
- `rn-component-library`
- `react-native-patterns`
- `mobile-app-security`
- `platform-design-guidelines`
- `mobile-ui-testing`
- `expo`
- `frontend-design`
- `react`
- `tauri-patterns`
- `electron`
- `apple-native`
- `companion-system`
- `billing-patterns`
- `supabase-patterns` — only when `docs/stack-profile.json` selects Supabase

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-11-prd-generation — Implementation-Ready Feature PRDs

**On start, announce:** "Running Step 11: PRD Generation. I'll write implementation-ready PRDs for each Step 10 feature marked 'PRD Required: Yes' — detailed enough that an autonomous agent can execute overnight with zero clarification."

<goal>
You are the Feature PRD Lead. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Validation & PRD Target Selection | Confirmed feature list from Step 10 |
| B | PRD Framing | Metadata, environment contract, problem/outcome, scope |
| C | Feature Vertical Slice | Stories, BDD scenarios, data/API/UI/state contracts |
| D | Security, Testing & Rollout | Auth/ownership, acceptance criteria, deployment notes |
| E | Agentic Notes, Status & Hardening | File paths, agent instructions, $holes pass, status sync |

Required Outputs:
- `docs/prds/F01.001-<slug>.md` (one per PRD-eligible feature; ID = canonical `F<wave:02d>.<feature:03d>`)
- Linear updates — PRD Document + wave-labeled issue per PRD (when configured) OR `docs/prds/.prd-status.json` (fallback)

Quality gate: 95+/100 on verification schema.

**Core principle:** These PRDs are consumed by AI coding agents, not read in conference rooms. Every section must be structured, testable, and explicit. "If you didn't write it down, the AI will guess — and it will guess confidently."

**The overnight test:** A well-written Step 11 PRD should be executable by an autonomous agent with zero clarification needed. If the agent would need to ask a question, the PRD is incomplete.
</goal>

---

## Step Boundary

- **Step 11 owns:** one implementation PRD per shaped feature, feature-level problem/value/scope, environment/data contract, user stories + BDD scenarios, functional requirements, per-feature data/API/UI/state contracts, security/auth/ownership, testing/acceptance, rollout notes, agentic implementation notes.
- **Step 11 does NOT own:** architecture rationale (Step 2), implementation blueprint (Step 8), feature eligibility (Step 10), runtime scaffolding (Step 14).
- **Do NOT** re-decide architecture or reshape features. Import upstream decisions and make them executable.

---

## AI-Native PRD Principles

### The PRD Is an Executable Spec (Spec-Driven Development)
A Sigma PRD is a Spec-Driven Development artifact: the spec — not the chat transcript — is the source of truth, and every acceptance criterion is a verifiable gate. In 2026 this paradigm converged across tooling (GitHub Spec-Kit, BMAD, OpenSpec). Sigma's PRD goes further than those formats on three axes, and the PRD must preserve all three:
- **Executable goal/mission/slices** (Sigma 3.0 schema) so the PRD drives `/goal`, `/loop`, and `/next-task` directly — not just a human-readable plan.
- **An Eval Contract with judge ≠ generator** (Section 13) so "done" is decided by an independent verifier, not the implementing agent's say-so.
- **A Verifier Gate before `approved: true`** so no PRD ships until a separate pass confirms the spec is testable and complete.
Benchmark intent: anything Spec-Kit/BMAD/OpenSpec do (structured requirements, acceptance criteria, file-scoping) a Sigma PRD must also do; the eval contract + verifier gate are Sigma's additions on top.

### Size the Spec to the Agent's Context Budget
A spec the agent cannot hold in context is a spec it will silently partially ignore (Addy Osmani, "How to write a good spec for AI agents"). Keep each PRD self-contained and reference upstream artifacts by path rather than inlining them. One PRD = one shaped feature an agent can implement in a single focused session without re-deriving architecture or design decisions.

### Structure Beats Prose
When 20 agents implement the same feature, structured specs produce agreement. Prose specs produce different "reasonable" assumptions. Use tables, predicates, code blocks — not paragraphs.

### Predictable Section Headings
Use numbered sections (Section 0, 1, 2...) so agents can reference "per Section 5" when implementing. Consistent headings across all PRDs enable agent tooling.

### BDD Scenarios Are Machine-Executable
Write Given-When-Then scenarios that are:
- **Declarative** — describe what should happen, not how
- **Bounded** — each scenario tests ONE behavior path
- **Independent** — no scenario depends on another's outcome
- **Specific** — observable states AI can validate, not vague assertions

```gherkin
# ✅ Machine-executable
Given a registered user with verified email
When they submit the login form with valid credentials
Then they are redirected to the dashboard
And the session cookie is set with httpOnly flag

# ❌ Too vague for AI
Given the user is set up
When they log in
Then it should work
```

### Negative Requirements Are Mandatory
Every PRD must include explicit "Do NOT" items — things the agent should avoid building. Without these, agents build unwanted features confidently.

### File Paths Are Required
The agentic notes section must name specific files to create or modify. Agents without file path guidance create random file structures.

### EARS Acceptance Criteria (mandatory)

All acceptance criteria in Section 10 **must be written as EARS patterns** (inherited from Step 8's EARS requirement). EARS criteria are machine-parseable and auto-generate test stubs.

| Pattern | Template |
|---------|----------|
| Event-driven | `WHEN [event] THE SYSTEM SHALL [response]` |
| State-triggered | `WHILE [state] THE SYSTEM SHALL [behavior]` |
| Conditional | `IF [precondition] THE SYSTEM SHALL [response]` |

Each criterion maps to a test case in the project's installed test runner. An agent reads the SHALL clause → writes the assertion before implementing when the behavior is automatable. Prose predicates ("should be fast", "must work correctly") are not acceptable — rewrite as EARS before the PRD is approved.

### Files NOT to Modify (mandatory section)

Every PRD must include a **"Files NOT to Modify"** section in Section 12 (Agentic Implementation Notes). Explicit negative scope prevents agents from treating adjacent modules as implied work and reduces unintended regressions.

Format:
```
### Files NOT to Modify
- `src/billing/` — owned by F05-billing; any billing change requires a separate PRD
- `src/admin/` — owned by F08-admin-dashboard; not in scope for this feature
- `AGENTS.md` — runtime config; never modified by feature PRDs
```

At minimum: list every directory or module this feature does NOT touch. If the PRD has zero exclusions to list, that is a scoping problem — revisit Section 2.

### Karpathy Implementation Discipline (advisory for downstream agents)
PRDs are read by implementation agents. Reference `src/skills/karpathy-guidelines/SKILL.md` (and `ponytail` for YAGNI) in the PRD's agentic notes section when the feature is at risk of overcomplication. Key rules the agent should apply when implementing:
- **Simplicity first** — write the minimum code that satisfies the BDD scenarios; do not build unrequested abstractions or configurability
- **Surgical changes** — modify only files listed in the PRD; flag adjacent dead code, do not delete it
- **Surface assumptions** — when the PRD is ambiguous, state assumptions in the completion report instead of guessing
- **Goal-driven execution** — convert each acceptance criterion into a failing test, then make it pass

This is not a duplicate of "Negative Requirements" — those bound *what* gets built. Karpathy guidelines bound *how* it gets built.

---

## PRD Section Set

Every `docs/prds/F<wave:02d>.<feature:03d>-<slug>.md` must include:

### Section 0: Shape Metadata
Import directly from Step 10 — do NOT reshape:
- Feature ID, appetite (the approved fixed time budget), priority (P0/P1/P2)
- PRD Required basis, dependencies, vertical-slice note
- Sequencing position, rabbit holes / open risks

### Section 0.5: Environment & Data Mode Contract
Every PRD must make clear:
- Local vs staging vs production behavior
- Mock-to-real replacement rules (what's fake in prototype → what's real in production)
- First real user behavior (what a brand-new account sees)
- Ownership and visibility constraints (who can see/edit what)
- Demo/seed policy (what seed data exists, what doesn't)

### Section 1: Problem & Outcome
- User problem (specific, not generic)
- Desired outcome (measurable transformation)
- Business or user value (why this feature exists now)
- Value Equation check: does this increase Dream Outcome or Perceived Likelihood, or decrease Time Delay or Effort?

### Section 2: Scope, Boundaries & Dependencies
- **In scope** (P0 items — must ship)
- **Out of scope** (explicit exclusions)
- **Do NOT build** (negative requirements — things agent must avoid)
- Upstream dependencies inherited from Step 8
- Reusable contracts inherited from prior steps

### Section 3: User Stories & BDD Scenarios
- Key user stories (As a [role], I want [action], so that [benefit])
- Happy-path BDD scenarios (Given-When-Then)
- Edge-case scenarios
- Error/recovery scenarios
- Each scenario = one behavior path, machine-executable

### Section 4: Functional Requirements
Structured as a requirements table:

| Req ID | Description | Priority | Acceptance Predicate |
|--------|------------|----------|---------------------|
| F1 | [requirement] | P0 | [testable predicate] |

### Section 5: Data Model & Persistence Delta
- New entities/tables/fields this feature adds
- Relationships and constraints
- Migration requirements
- Indexes needed
- What changes vs what's inherited from Step 8 schema

### Section 6: API / Server Action / Integration Contract
- New endpoints or Server Actions this feature requires
- Request/response shapes (TypeScript types or JSON examples)
- Auth requirements per action
- Error contract (using the standard ActionResult shape from Step 8)
- External integrations triggered

### Section 7: UI & Component Contract
- Screens/routes this feature touches (reference Step 4 screen IDs)
- **Visual source of truth:**
  - If Step 5 Canvas: `docs/prds/flows/[NN]-[flow-slug]/visual-artifact/` — read `VISUAL-ARTIFACT.md`, the committed source (such as `.pen` when used), and actual export(s).
  - If Step 5 Direct: `docs/prds/flows/[NN]-[flow-slug]/screens/[screen-id].{html,tsx,swift}` — use the stack-native artifact; direct mobile/native work is not HTML-only.
  - If landing page feature: reference `docs/landing-page/visual-source/` with `VISUAL-BRIEF.md` for Canvas/Hybrid, or `docs/landing-page/landing-page.html` for Direct.
  - Legacy imported bundles may be read only when their existing path is recorded in the flow/landing artifact; they are not a default for new work.
- New components needed (reference Step 6 component families and the approved visual artifact when available)
- shadcn components used (if applicable — reference specific components by name)
- Layout behavior (responsive rules, DNA emphasis)
- Realistic content examples — inherit from the approved visual artifact, direct screen, or brief. Do NOT re-author approved content upstream.

**Per-platform dependency install & component scaffold (mandatory for every UI PRD):**

Read `platform` from `docs/stack-profile.json` and `docs/technical/TECHNICAL-SPEC.md` (Platform Component Scaffold Matrix). Include the applicable block below verbatim in the PRD so the implementing agent runs the exact commands before touching source files.

> **MOBILE (Expo / React Native):**
>
> Skills to invoke: `react-native-patterns`, `rn-component-library`, `mobile-app-security`, `platform-design-guidelines`, `mobile-ui-testing`
>
> Install any missing component packages (idempotent — safe to re-run):
> ```bash
> # Add only the components this PRD needs:
> npx @react-native-reusables/cli@latest add [component-names-from-tech-spec-matrix]
> # Example for a form screen:
> npx @react-native-reusables/cli@latest add button card input label text
> ```
>
> All new screen-level components follow this shape:
> ```tsx
> // components/[feature]/[ScreenName].tsx
> import { View } from 'react-native';
> import { Button } from '~/components/ui/button';
> import { Card, CardContent, CardHeader, CardTitle } from '~/components/ui/card';
> import { Input } from '~/components/ui/input';
>
> // View model (MVVM — no business logic in the component)
> import { use[FeatureName]ViewModel } from '~/lib/[feature]/view-model';
>
> export function [ScreenName]() {
>   const vm = use[FeatureName]ViewModel();
>   return (
>     <View className="flex-1 bg-background p-4">
>       {/* map vm.state to ui */}
>     </View>
>   );
> }
> ```
>
> Lists use `FlashList` from `@shopify/flash-list` — never `FlatList`. Images use `expo-image` — never `<Image>` from react-native. Animations run via Reanimated worklets on the UI thread — never on the JS thread.
>
> **Charts (when `stack-profile.chartsLibrary` is `@bklit/charts` or feature includes analytics/trading visuals):**
> ```bash
> npm install @bklit/charts react-native-skia
> ```
> Invoke `rn-component-library` §3. Use `LineChart`, `BarChart`, `RingChart` from `@bklit/charts` — not `react-native-chart-kit`.
>
> Secure storage rules (MASVS): secrets/tokens → `expo-secure-store`; fast KV → `react-native-mmkv` (non-sensitive only).

> **WEB (Next.js):**
>
> Skills to invoke: `frontend-design`, `shadcn`, `react`
>
> Install any missing shadcn components:
> ```bash
> npx shadcn@latest add [component-names-from-tech-spec-matrix]
> # Example:
> npx shadcn@latest add button card input dialog sheet
> ```
>
> Components live in `src/components/ui/` (auto-generated by shadcn). Feature-specific compositions go in `src/components/[feature]/`.

> **DESKTOP — Tauri:**
>
> Skills to invoke: `tauri-patterns`
>
> Install shadcn web components (shared with web if monorepo):
> ```bash
> npx shadcn@latest add [component-names-from-tech-spec-matrix]
> ```
>
> IPC calls always go through typed wrapper functions in `src/lib/commands/[domain].ts`. Never call `invoke()` directly from component code.

> **DESKTOP — Electron:**
>
> Skills to invoke: `electron`
>
> Install shadcn web components:
> ```bash
> npx shadcn@latest add [component-names-from-tech-spec-matrix]
> ```
>
> All privileged work runs in the main process. The renderer calls typed `contextBridge` wrappers only. Confirm `contextIsolation: true` and `nodeIntegration: false` before any renderer code ships.

### Section 8: State & Recovery Contract
- States this feature introduces (reference Step 7 state taxonomy)
- Loading, error, empty, success behavior per screen
- Optimistic update patterns (if applicable)
- Recovery paths for each failure mode
- Announcement/focus rules (from Step 7)

### Section 9: Security, Auth & Ownership
- Auth rules for this feature
- Authorization/ownership (who can create/read/update/delete)
- RLS or data-ownership rules
- Permission handling (what unauthorized users see)
- Sensitive actions requiring confirmation

### Section 10: Testing & Acceptance
Concrete, testable criteria:

| Test Type | What to Test | Expected Result |
|-----------|-------------|-----------------|
| Unit | [function/validator] | [predicate] |
| Integration | [API/action] | [predicate] |
| E2E | [user journey] | [predicate] |
| Accessibility | [a11y check] | [predicate] |
| **Visual review (when an approved visual source exists)** | **Rendered scaffold vs approved source/export at agreed viewports** | **Same font and viewport baseline; UI Contract sets a bounded threshold plus component, token, interaction, and visual-review evidence** |

**Visual-review conditional rule:** include the row only when the feature has an approved `visual-artifact/`, `visual-source/`, or Direct screen artifact. The UI Contract defines the same-font and viewport baseline plus its bounded threshold. Backend-only features have no visual row.

BDD scenarios from Section 3 should be directly convertible to test cases.

### Section 11: Rollout, Metrics & Risks
- Feature flag strategy (if applicable)
- Rollout plan (all-at-once, staged, percentage)
- Success metrics (what to measure post-launch)
- Risks and mitigations

### Section 12: Agentic Implementation Notes
This is what makes the PRD AI-executable:
- **File paths** — specific files to create or modify
- **Implementation order** — which files first, what depends on what
- **Key contracts** — upstream contracts that must NOT be violated
- **Conditional artifacts** — what to inspect before coding
- **Testing command** — exact command to verify (e.g., `vitest run src/features/[feature]/` for web; `npx maestro test .maestro/[feature]-flow.yaml` for mobile)
- **Do NOT** — explicit agent constraints
- **Observability Contract:** `docs/observability/INSTRUMENTATION-CONTRACT.md#[F-ID]-[FEATURE-NAME]` (added by Step 15; implementing agent MUST wire all trace points listed there before opening a PR)

**Platform install commands (copy from Section 7 — run BEFORE writing any source file):**

```
Platform: [mobile | web | desktop-tauri | desktop-electron]
Skills to invoke: [list from Section 7]
Pre-code installs:
  [paste exact install commands from Section 7 for this feature's components]
Verification after install:
  [mobile]: npx expo-doctor && npx tsc --noEmit
  [web/desktop]: npx tsc --noEmit && npx eslint src/[feature]
```

**Mobile-specific implementation rules (when platform = mobile):**
- All list rendering uses `FlashList` with `estimatedItemSize` and `getItemType` for heterogeneous items.
- All images use `expo-image` with a `placeholder` (blurhash or thumbhash).
- All animations run as Reanimated worklets on the UI thread (`useAnimatedStyle`, `useSharedValue`).
- State management uses Zustand; no `useState` for cross-screen state.
- Navigation uses `expo-router` typed params — no `navigation.navigate('ScreenName', {})` string-based calls.
- Every screen view model is an `@observable`-equivalent Zustand store or hook — no business logic in the component body.
- E2E test file: `.maestro/[feature-id]-[scenario].yaml` (Maestro YAML, not Detox unless project-wide decision says otherwise).

**Desktop-specific implementation rules (when platform = desktop):**
- Tauri: every `invoke()` call is wrapped in a typed function in `src/lib/commands/[domain].ts`.
- Electron: every `ipcRenderer` call goes through the `contextBridge` preload surface — no direct `ipcRenderer` in renderer code.
- Both: secrets never stored in plain files; use OS keychain (Tauri `tauri-plugin-stronghold` / Electron `safeStorage`).

### Files NOT to Modify
- `src/billing/` — owned by F05-billing; any billing change requires a separate PRD
- `src/admin/` — owned by F08-admin-dashboard; not in scope for this feature
- `AGENTS.md` — runtime config; never modified by feature PRDs
[Add all directories this feature does NOT touch. Zero exclusions = scoping problem — revisit Section 2.]

### Section 13: Eval Contract (mandatory PRD section)

Every PRD must include an Eval Contract. Evals are written **before** implementation begins. The evaluator model must differ from the generator model (self-grading is unreliable).

**Required fields:**

| Field | Description |
|-------|-------------|
| `golden_tasks` | 5–10 representative input/output pairs that define correct behavior |
| `generator_model_snapshot` | Model/version that authored the fixture; pin when the host supports it |
| `expected_behavior` | For each golden task: exact expected output or output predicate |
| `scoring_rubric` | Criteria applied by the judge model (correctness, faithfulness, relevance) |
| `ci_gate_thresholds` | Minimum scores required for the eval suite to pass in CI |
| `judge_model` | Which model evaluates the outputs (must differ from generator) |
| `tool_schema_versions` | Applicable tool or remote-agent schemas and versions |
| `fixture_version` | Version or date of the golden-task fixture |
| `eval_file` | Path to the eval harness: `docs/evals/[feature-id]-golden.json` |

**Golden task format:**

```json
{
  "id": "eval-[feature-id]-[N]",
  "description": "[one line: what behavior this tests]",
  "input": { "[field]": "[value]" },
  "expected_output": "[exact value or predicate]",
  "scoring_criteria": ["correctness", "faithfulness", "relevance"],
  "pass_threshold": { "correctness": 0.9, "faithfulness": 0.85, "relevance": 0.8 }
}
```

**Scoring rubric (apply these three dimensions for every golden task):**

| Dimension | Definition | Scale |
|-----------|-----------|-------|
| **Correctness** | Does the output match the expected behavior per the PRD's EARS criteria? | 0.0 – 1.0 |
| **Faithfulness** | Is the output grounded in the input without hallucinating new facts? | 0.0 – 1.0 |
| **Relevance** | Does the output address the user's actual need (per PRD Section 1)? | 0.0 – 1.0 |

**CI gate thresholds (defaults — override in PRD when feature risk warrants stricter gates):**

```json
{
  "correctness": 0.90,
  "faithfulness": 0.85,
  "relevance": 0.80,
  "pass_k": 1,
  "min_passing_tasks": "80%"
}
```

`pass_k = 1` means a single eval run must pass (no retry budget in CI). For stochastic features, set `pass_k = 3` and require 2-of-3 passing runs.

**Authoring rules:**
- Golden tasks cover: (a) happy path, (b) at least one edge case, (c) at least one adversarial / malformed input.
- Golden tasks are written by the PRD author — NOT by the implementing agent.
- The eval harness script lives at `.sigma/tools/eval-runner.sh` (generated by Step 13) and reads `docs/evals/*.json`.
- Step 13 emits an eval-harness skill per department agent that automates golden task execution.
- For a tool-using or durable-workflow feature, include deterministic schema/permission checks plus fixtures for expected side effect, approval pause, and interruption/resume or cancellation. Include an unauthorized-tenant or prompt-injection attempt when untrusted inputs can reach tools.
- A model judge is not the only evidence: deterministic contract checks must run without a model where the feature exposes schemas, permissions, or side effects.

Eval method reference checked 2026-09-19: [OpenAI evaluations guidance](https://platform.openai.com/docs/guides/evals).

---

## Phase A — Import Validation & PRD Target Selection

### Upstream Requirements

| Artifact | Source Step | Required |
|----------|-----------|----------|
| `docs/implementation/FEATURE-BREAKDOWN.md` | Step 10 | **Yes** — PRD Eligibility Table is the sole input |
| `docs/implementation/FEATURE-DEPENDENCIES.md` | Step 10 | Conditional — only if declared in FEATURE-BREAKDOWN.md |
| `docs/implementation/PRD-ROADMAP.md` | Step 10 | Conditional — only if declared in FEATURE-BREAKDOWN.md |
| `docs/technical/TECHNICAL-SPEC.md` | Step 8 | **Yes** — contracts, schema, API shapes |
| `docs/design/DESIGN-SYSTEM.md` | Step 6 | **Yes** — component families, tokens |
| `docs/states/STATE-SPEC.md` | Step 7 | **Yes** — state taxonomy |
| `docs/prds/flows/*/FLOW-*.md` | Step 5 | **Yes** — prototype PRDs for hardening |
| `docs/prds/flows/*/visual-artifact/` + `VISUAL-ARTIFACT.md` | Step 5 Canvas | Conditional — committed source (such as `.pen` when used), actual export(s), tool/version, and approval evidence. This is the visual source for UI Contract sections. |
| `docs/prds/flows/*/screens/*` | Step 5 Direct | Conditional — direct HTML for web/desktop or native `.tsx`/`.swift` scaffolds for mobile/native. Reference as visual spec. |
| `docs/landing-page/LANDING-PAGE.md` | Step 9 | Conditional — present when product has a landing page. Features that touch the landing page must reconcile with this. |
| `docs/landing-page/visual-source/` + `VISUAL-BRIEF.md` | Step 9 Canvas / Hybrid | Conditional — approved source/export and brief. Landing-page PRDs reference this visual source. |
| `docs/landing-page/landing-page.html` | Step 9 Track B | Conditional — present when Step 9 used direct HTML. Reference as visual spec. |

**Fallback:** If `FEATURE-BREAKDOWN.md` is missing, halt and notify the user: "Step 11 requires the PRD Eligibility Table from Step 10. Run Step 10 first." If other upstream artifacts are missing, note the gap in each PRD's Section 0 and label affected sections as assumptions.

### Track Detection

During Preflight, detect actual registered visual artifacts regardless of provider:
- `docs/prds/flows/*/visual-artifact/VISUAL-ARTIFACT.md` plus its source/export → **Step 5 Canvas**
- `docs/prds/flows/*/screens/*` → **Step 5 Direct**
- `docs/landing-page/visual-source/` plus `VISUAL-BRIEF.md` → **Step 9 Canvas or Hybrid**
- `docs/landing-page/landing-page.html` → **Step 9 Direct**
- A legacy imported bundle path is migration-read only when recorded by an existing artifact. Record found source kinds and paths in each PRD's Section 0.

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `docs/implementation/FEATURE-BREAKDOWN.md` (Step 10) — if missing, halt per fallback rule above.
3. Read Step 10 support artifacts if declared (`FEATURE-DEPENDENCIES.md`, `PRD-ROADMAP.md`).
4. Read `docs/technical/TECHNICAL-SPEC.md` (Step 8), `docs/design/DESIGN-SYSTEM.md` (Step 6), `docs/states/STATE-SPEC.md` (Step 7).
5. Read Step 5 flow PRDs: `docs/prds/flows/*/FLOW-*.md`.
6. **Detect Step 5 artifacts:** inspect `visual-artifact/VISUAL-ARTIFACT.md` with its actual source/export, and `screens/*` for Direct artifacts. Record source kind and path per flow.
7. **Detect Step 9 outputs if present:** read `docs/landing-page/LANDING-PAGE.md`, `visual-source/` with `VISUAL-BRIEF.md`, and `landing-page.html`. If landing page is in scope, features that touch it must reference the actual approved artifact.
8. If `research_mode = blocked` → stop. If `reduced` → label assumptions.

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

### Linear Status Tracker Detection (2026-07-11 — Linear replaced the SigmaHQ kanban)

Linear is configured when BOTH hold:
- `security find-generic-password -s LINEAR_API_KEY -w` returns a key (GraphQL endpoint `https://api.linear.app/graphql`, header `Authorization: <key>`, no Bearer prefix)
- `runtime-baseline.json` shows `linear.project: "<Linear project name>"` (each repo maps to exactly one Linear project; team is derived from the project)

When configured:
- Discover PRD-eligible feature issues (created by Step 10) via GraphQL: issues in `linear.project` with label `feature`, state `Todo`
- Match issues by title to the PRD Eligibility Table features
- These become the status tracker — update issues as PRDs are written
- `.prd-status.json` is not required when Linear is active

If Linear is not configured:
- `.prd-status.json` remains the primary status tracker (legacy behavior)

Track tasks in Linear when it's configured, otherwise as wave-labeled GitHub Issues in the project repo. Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop; when Linear is connected its issues two-way-sync once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

### Constitution Check Gate (mandatory)

Before writing any PRD, verify that `docs/specs/constitution.md` exists (produced by Step 1). If it exists, every PRD must be checked against it before acceptance.

**Constitution Check procedure (per PRD):**
1. Read `docs/specs/constitution.md`.
2. For each immutable principle in the constitution, confirm the PRD does not violate it.
3. Record the check result in Section 0 Shape Metadata:
   ```
   Constitution Check: PASS | FAIL | SKIPPED (no constitution.md)
   Violations: [none | list of violated principles]
   ```
4. A PRD with a `FAIL` status may not advance to implementation until the violation is resolved — either by revising the PRD or by escalating to the operator to amend the constitution.

This gate applies to all PRDs regardless of priority (P0 through P2). No PRD bypasses the constitution check.

### Confirm PRD targets

From Step 10's PRD Eligibility Table, list all features with `PRD Required: Yes`:

| Feature | Priority | Appetite | Dependencies | Status |
|---------|----------|----------|-------------|--------|
| [feature] | P0/P1/P2 | approved time budget | [deps] | pending |

Use AskUserQuestion: "These features need PRDs. Which should I write first?"
Options: [Write P0 features first (recommended), Write all in sequence order, Pick specific feature, Write all at once]

<HARD-GATE>
Do NOT proceed to Phase B until user approves PRD target list.
Use AskUserQuestion: "PRD targets confirmed. Approve?"
Options: [Approve — start writing PRDs, Adjust feature list, Go back to Step 10]
</HARD-GATE>

---

## Phase B — PRD Framing (per feature)

For each PRD-eligible feature, write these sections first:
- **Section 0: Shape Metadata** — import directly from Step 10's PRD Eligibility Table (feature ID, appetite, priority, dependencies, rabbit holes). Do NOT reshape.
- **Section 0.5: Environment & Data Contract** — define local/staging/production behavior, mock-to-real rules, first-user behavior, ownership constraints.
- **Section 1: Problem & Outcome** — user problem, desired outcome, value equation check.
- **Section 2: Scope, Boundaries & Dependencies** — in-scope P0 items, explicit exclusions, "Do NOT build" list, upstream dependencies from Step 8.

## Phase C — Feature Vertical Slice (per feature)

Write the implementation contracts:
- **Section 3: User Stories & BDD Scenarios** — happy-path, edge-case, and error/recovery scenarios. Each scenario = one behavior path, machine-executable Given-When-Then.
- **Section 4: Functional Requirements** — structured requirements table with testable acceptance predicates.
- **Section 5: Data Model Delta** — new entities, relationships, migrations, indexes.
- **Section 6: API / Server Action Contract** — endpoints, request/response shapes, auth per action, error contract.
- **Section 7: UI & Component Contract** — screens, components, layout behavior, realistic content.
- **Section 8: State & Recovery Contract** — states introduced, loading/error/empty/success behavior, recovery paths.

## Phase D — Security, Testing & Rollout (per feature)

Write the hardening sections:
- **Section 9: Security, Auth & Ownership** — auth rules, authorization/ownership, RLS, permission handling.
- **Section 10: Testing & Acceptance** — unit/integration/E2E/accessibility test table with testable predicates.
- **Section 11: Rollout, Metrics & Risks** — feature flag strategy, rollout plan, success metrics, risk mitigations.
- **Section 12: Agentic Implementation Notes** — file paths, implementation order, key contracts, testing command, explicit "Do NOT" constraints.
- **Section 13: Eval Contract** — golden tasks, scoring rubric, CI gate thresholds, generator snapshot, fixture/tool versions, and the `judge_model` (which MUST differ from the implementing/generator model). For agent features, include deterministic side-effect, authorization, approval, and resume evidence. Authored now, before implementation begins.

### Per-feature checkpoint

After completing each PRD (Sections 0-13, including the Section 13 Eval Contract):

<HARD-GATE>
Use AskUserQuestion: "PRD for [feature name] complete. Review?"
Options: [Approve — continue to next feature, Revise — adjust this PRD, Skip — defer this feature]
</HARD-GATE>

---

## Phase E — Agentic Notes, Status & Hardening

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` for each PRD to find:
- Sections with vague requirements an agent would need to clarify
- Missing BDD scenarios for edge cases
- File paths missing from agentic notes
- Acceptance criteria that aren't machine-verifiable
- Contradictions with Step 8 blueprint

Fix findings before presenting.

### Mandatory: Verifier Gate (judge ≠ generator) — required before `approved: true`

A PRD is not "approved" because its author says so. Before any PRD is marked `approved: true` (or its Linear feature issue moved to `Done`), an **independent verifier** must confirm the PRD's own Eval Contract is sound and self-consistent. This is the judge-model discipline applied to the spec, not just the implementation.

**Procedure (per PRD):**
1. The verifier model MUST differ from the model that authored the PRD. Self-grading is not accepted — use cross-model review when available.
2. The verifier runs the Eval Contract's own check command against the PRD's golden tasks:
   ```bash
   .sigma/tools/eval-runner.sh docs/evals/<feature-id>-golden.json --dry-run
   ```
   `--dry-run` validates that every golden task is well-formed (input + expected_output + scoring_criteria present), the `judge_model` is set and differs from the generator, and `ci_gate_thresholds` are present. (The harness is generated by Step 13; if it does not exist yet, the verifier performs the same checks by reading Section 13 directly and records `eval_harness: pending`.)
3. The verifier confirms, against the diff/spec — not the author's summary:
   - Every Section 10 acceptance criterion is an EARS predicate with a matching golden task or test row.
   - `goal.stopping_condition` is agent-observable (names a test/command/diff), not prose.
   - `judge_model` ≠ the model that will implement the feature (`mission.skill_name`'s default model).
   - Golden tasks cover happy path + ≥1 edge + ≥1 adversarial input.
   - Agent features also cover tool arguments, authorization decision, approval pause, expected side effect, and interruption/resume or cancellation; deterministic schema/permission checks are named.
4. Record the verifier result in Section 0 Shape Metadata:
   ```
   Verifier Gate: PASS | FAIL
   Verifier model: [model id, must differ from author]
   Evidence: [command output or the specific checks performed]
   ```

A PRD with `Verifier Gate: FAIL` may NOT be set `approved: true`. Fix the PRD and re-verify. Evidence over assertion: a verifier that returns "looks good" with no command output or per-check trace does not satisfy this gate.

### Update PRD Status

**When Linear is configured (primary):**

Each approved PRD produces THREE writes (the PRD markdown in-repo is unchanged):
1. The PRD file `docs/prds/F<wave>.<feature>-<slug>.md` (as always).
2. A Linear **Document** in the repo's Linear project, created from the workspace "Step-11 PRD" document template, linking the in-repo PRD path.
3. A **wave-labeled issue** per PRD via GraphQL `issueCreate` (label `wave:W<n>` from the PRD's wave — an issue with no wave label is a defect).

As each PRD is written / approved, move its feature issue via `issueUpdate` (state `In Progress` when writing starts, `Done` when the PRD is approved).

After all PRDs are complete, parse each PRD into engineering sub-tasks as **child issues** of the feature issue:
```graphql
mutation($i: IssueCreateInput!) { issueCreate(input: $i) { success issue { identifier url } } }
# input: { teamId, projectId, parentId: <feature issue>, title: "{PRD-ID}: {section name}",
#          description: "Acceptance: {criteria}\nFiles: {file paths}\nAgent: {suggested assignment}",
#          labelIds: [<eng-task>, <wave:W{n}>], priority: {inherited} }
```

This creates the engineering ticket layer that Steps 13-14 consume for agent assignment and dispatch.

**Pipeline continuity:** Step 13 discovers these engineering sub-tasks via GraphQL — issues in the repo's Linear project with label `eng-task`, state `Todo`. Use the `eng-task` label consistently — Step 13 depends on it for agent assignment.

**When Linear is NOT configured (fallback):**

Update `docs/prds/.prd-status.json`:
PRD IDs use the canonical `F<wave:02d>.<feature:03d>` format from `schemas/sigma-prd-canonical.schema.json` (e.g. `F01.001`). The markdown filename mirrors the ID: `docs/prds/F01.001-<slug>.md`. Use the same ID in the `.md` filename, the `.prd-status.json` entry, and the PRD JSON `prd_id` — no `F1` / `F01.001` drift.

```json
{
  "features": [
    {
      "id": "F01.001",
      "name": "[feature]",
      "file": "docs/prds/F01.001-[slug].md",
      "status": "draft",
      "approved": false,
      "verifier_gate": "pending",
      "priority": "P0",
      "appetite": "[approved fixed time budget from Step 10]",
      "dependencies": [],
      "approvedAt": null
    }
  ]
}
```

Set `approved: true` only after BOTH the Verifier Gate (judge ≠ generator) passes AND the operator approves at the final checkpoint. The verifier gate is a precondition, not a substitute, for human approval.

### The Overnight Test

Before marking any PRD complete, ask: "Could an autonomous agent execute this PRD overnight with zero clarification?" If the answer is no — the PRD needs more specificity.

### Writing Standards (embedded)

- No stock AI phrases: "Comprehensive", "Robust", "Seamless integration", "End-to-end"
- Requirements are specific predicates, not descriptions: "Response time < 200ms" not "should be fast"
- BDD scenarios use concrete values: "Given user with email 'test@example.com'" not "Given a user"
- File paths are exact: `src/features/auth/login.ts` not "the login module"
- Write like a staff engineer handing a spec to an autonomous agent, not a PM writing a feature brief

### Success Criteria

- [ ] One PRD per Step 10 PRD-eligible feature
- [ ] All 14 sections present in each PRD (0-13, including Section 13 Eval Contract)
- [ ] BDD scenarios are machine-executable (Given-When-Then, one behavior per scenario)
- [ ] Acceptance criteria are testable predicates
- [ ] Negative requirements ("Do NOT") present
- [ ] File paths in agentic notes
- [ ] Environment/data contract explicit
- [ ] Step 8 contracts inherited, not duplicated
- [ ] Section 13 Eval Contract records generator snapshot, fixture/tool versions, and `judge_model` ≠ generator
- [ ] Agent features include deterministic authorization/side-effect checks and interruption handling evidence
- [ ] Linear updated — PRD Documents + wave-labeled issues + `eng-task` child issues (when configured), OR .prd-status.json updated (fallback)
- [ ] $holes pass completed per PRD
- [ ] Verifier Gate passed (judge ≠ generator) before any `approved: true`
- [ ] User approved each PRD

### Downstream Handoff

Step 11 produces artifacts consumed by later steps:

| Artifact | Consumed By | Purpose |
|----------|-------------|---------|
| `docs/prds/F01.001-<slug>.md` | Step 11.5 (TASKS.md), Step 12 (context synthesis), Step 13 (skill domain mapping), Step 14 (agent dispatch) |
| `.sigma/dispatch/<cli>/<prd-id>.goal.md` (optional) | Step 14 runtime / `/goal` + `/loop` dispatch when goal bundles are emitted |
| Linear child issues labeled `eng-task` | Step 13 (engineering sub-task assignment) |
| `.sigma/backlogs/<mode>/TASKS.md` + `exec-task` cards | Step 11.5 + `/next-task` pull-based execution |
| `.prd-status.json` (fallback) | Step 11.5, Step 12, Step 13 (when Linear not configured) |

Next step: run `/step-11.5-task-handoff` to generate the `/next-task` execution manifest from the approved PRDs.

---

## Canonical Schema Compliance

Every PRD generated by Step 11 must comply with `schemas/sigma-prd-canonical.schema.json`. The schema is platform-agnostic — it is the single source for dispatch bundles under `.sigma/dispatch/`.

### Required blocks (schema-enforced)

| Block | Required fields | Purpose |
|-------|----------------|---------|
| `goal` | `objective`, `stopping_condition`, `files_to_read_first`, `proof_commands` | Agent goal / dispatch contract |
| `mission` | `milestone`, `expected_behavior`, `verification_steps`, `fulfills`, `skill_name`, `estimated_complexity` | Structured mission metadata for orchestration |
| `slices[]` | `id`, `title`, `proof` (per slice) | Optional: splits large PRDs across multiple `/goal` turn budgets |

### Field constraints (keep these in mind when authoring)

- `goal.objective` — single sentence, ≤400 chars. State the measurable end state.
- `goal.stopping_condition` — agent-observable proof of done (test name, command exit code, file diff). ≤400 chars.
- `goal.out_of_scope[]` — explicit guardrails; prevents agent overreach.
- `goal.max_turns` — integer, default 20. Set higher (up to 200) for large features.
- `mission.verification_steps[]` — `VC-*` pattern IDs that map to validation-contract.md assertions.
- `mission.estimated_complexity` — `"small"` | `"medium"` | `"large"`. Drives swarm sizing per swarm-orchestration.md.
- `slices[].id` — parent prd_id + `.letter` suffix, e.g. `F01.001.a`.

### Schema validation command

Run this from the repo root to validate any generated PRD JSON:

```bash
# Node (preferred — requires: npm install ajv)
node -e "
const Ajv=require('ajv').default;
const ajv=new Ajv({strict:false});
const s=require('./schemas/sigma-prd-canonical.schema.json');
const d=require('./<generated-prd>.json');
console.log(ajv.compile(s)(d)?'VALID':JSON.stringify(ajv.compile(s).errors,null,2))
"

# Python fallback
python3 -c "
import json, jsonschema
schema=json.load(open('schemas/sigma-prd-canonical.schema.json'))
data=json.load(open('<generated-prd>.json'))
try:
  jsonschema.validate(data, schema); print('VALID')
except jsonschema.ValidationError as e:
  print('INVALID:', e.message)
"
```

### Reference fixtures

- `schemas/fixtures/F01.001-sample-valid.json` — canonical example (auth endpoints feature)
- Schema source: `schemas/sigma-prd-canonical.schema.json`

### Example PRD JSON template

The following example validates against the canonical schema. Use it as the structural template when authoring a new PRD JSON alongside each `docs/prds/F[N]-[FEATURE-NAME].md`:

```json
{
  "$schema": "../../schemas/sigma-prd-canonical.schema.json",
  "prd_id": "F01.001",
  "title": "User authentication with email + password",
  "slug": "user-authentication",
  "version": "1.0.0",
  "status": "ready",
  "wave": 1,
  "dependencies": ["F01.000"],
  "goal": {
    "objective": "Ship POST /auth/login + POST /auth/register endpoints with JWT issuance, Argon2 hashing, and rate limiting (5 req/min/IP).",
    "stopping_condition": "All tests in tests/auth/*.test.ts pass, npm run typecheck exits 0, and curl POST /auth/login with valid creds returns 200 with a JWT in the response body.",
    "files_to_read_first": [
      "src/auth/index.ts",
      "src/db/schema/users.ts",
      "docs/architecture/auth.md"
    ],
    "proof_commands": [
      "npm test -- src/auth",
      "npm run typecheck",
      "npm run lint -- src/auth"
    ],
    "max_turns": 25,
    "out_of_scope": [
      "OAuth/social login providers",
      "Password reset flow (separate PRD F01.002)",
      "Changes to src/billing/ or src/admin/"
    ]
  },
  "mission": {
    "milestone": "M1: Auth foundation",
    "preconditions": [
      "PRD F01.000 (User model + DB schema) complete and merged to main",
      "JWT_SECRET set in .env.example and documented"
    ],
    "expected_behavior": "Given a user submits valid email and password to POST /auth/login, when the credentials match a stored Argon2 hash, then the response is 200 with {token, user} JSON and the token verifies against JWT_SECRET. Given invalid credentials, the response is 401 with {error: 'invalid_credentials'}. Given more than 5 requests in 60 seconds from the same IP, the response is 429 with Retry-After header.",
    "verification_steps": ["VC-AUTH-001", "VC-AUTH-002", "VC-AUTH-003", "VC-AUTH-RATE-001"],
    "fulfills": ["VC-AUTH-001", "VC-AUTH-002", "VC-AUTH-003"],
    "skill_name": "backend-engineer",
    "estimated_complexity": "medium"
  },
  "slices": [
    {
      "id": "F01.001.a",
      "title": "DB migration + user_credentials table",
      "proof": "npx prisma migrate dev exits 0 and user_credentials table exists"
    },
    {
      "id": "F01.001.b",
      "title": "POST /auth/register with Argon2 hashing",
      "proof": "tests/auth/register.test.ts passes including hash-strength assertion"
    }
  ]
}
```

**Validation result for this example:** VALID against `schemas/sigma-prd-canonical.schema.json` (structurally identical to `schemas/fixtures/F01.001-sample-valid.json`).

### When to include `slices`

Include `slices[]` when:
- The feature's `goal.max_turns` estimate exceeds 40 turns
- The feature touches 3+ distinct subsystems (DB + API + UI)
- `mission.estimated_complexity` is `"large"`

Each slice becomes its own `/goal` dispatch. The parent PRD's `goal.stopping_condition` remains the overall success criterion.

### Step 11 checklist addition (schema compliance)

Add to your Step 11 quality gate checklist:

- [ ] PRD JSON file exists alongside the `.md` (or Section 0 metadata block includes all schema-required fields inline)
- [ ] `goal.objective` is a single sentence ≤400 chars with a measurable end state
- [ ] `goal.stopping_condition` is agent-observable (references a test name, command, or file diff)
- [ ] `goal.files_to_read_first` lists at least the primary implementation file
- [ ] `goal.out_of_scope` lists at least 2 explicit exclusions
- [ ] `mission.verification_steps` references at least one `VC-*` assertion ID
- [ ] `mission.skill_name` matches the agent this PRD targets
- [ ] Schema validation command returns `VALID`

## Final Step: Emit Dispatch Bundles (optional)

After authoring and validating the PRD against `schemas/sigma-prd-canonical.schema.json`, generate machine backlogs and optional goal bundles for autonomous dispatch.

See the [Canonical Schema Compliance](#canonical-schema-compliance) section above for the `goal` and `mission` blocks that feed dispatch.

### Emission (optional — when using sigma-dispatch)

```bash
sigma prd-json --mode implementation
sigma prd-orchestrate   # when dependency ordering needed
```

Optional goal bundle (when your runtime consumes `.sigma/dispatch/*` artifacts):

```bash
# Generic goal bundle emitter (legacy script name — output is CLI-agnostic XML goal block)
python3 scripts/emitters/emit_claude_bundle.py docs/prds/<feature>.json
```

Per-vendor mirror emitters (`emit_codex_bundle.py`, `emit_droid_mission.py`) are **deprecated** — use `commands/` + `src/skills/` invocation and `AGENTS.md` as the single runtime brain.

### Verification

Schema validation and bundle emitters exit non-zero on failure. Goal blocks enforce the 4000-char limit with intelligent truncation.

If optional goal bundles are missing, `/goal` dispatch may refuse to fire — run `sigma prd-json --mode implementation` and re-emit before dispatch.

### Idempotency

Emitters are byte-deterministic. Re-running on the same PRD produces identical output. Safe to re-run after PRD edits — just re-emit before dispatching.

---

## How Agents Ingest These PRDs (`/goal`, `/loop`, `/next-task`)

A Step 11 PRD is the spec; the agent runtime turns it into autonomous work via each CLI's native primitive. The `goal` block is authored precisely so it drops straight into a `/goal` run with no rewriting.

| Mechanism | When to use | What it consumes |
|-----------|-------------|------------------|
| `/goal` (condition loop) | One feature, runs until a verifiable stopping condition is met | `goal.objective` + `goal.stopping_condition` + `goal.proof_commands` from the emitted bundle (`.sigma/dispatch/<cli>/<prd-id>.goal.md`) |
| `/loop` (cadence loop) | Repeated passes over a backlog at a set cadence (e.g. "pick the next ready PRD, implement, verify, repeat") | The implementation backlog + per-PRD `goal` blocks |
| `/next-task` (TASKS.md loop) | Pull-based execution from Step 11.5 manifest | `.sigma/backlogs/<mode>/TASKS.md` + approved PRDs (`exec-task` issues when Linear is configured) |

**Ingestion contract — what makes a PRD `/goal`-ready:**
- `goal.stopping_condition` is the loop's exit check. It MUST be externally verifiable (a test name, a command exit code, a file diff) — never "the agent believes it is done." Loops exit on the external check, not the agent's say-so.
- `goal.proof_commands` are the commands the loop runs to prove the stopping condition. The agent pastes their real output as evidence.
- `goal.out_of_scope` are the loop's guardrails; they prevent the autonomous run from wandering into adjacent files (reinforced by Section 12 "Files NOT to Modify").
- `goal.max_turns` bounds the run. Large features use `slices[]` so each slice is its own bounded `/goal`.

**Let agents author your `/goal` + `/loop` prompts.** You do not hand-write dispatch prompts. The emitters above generate the `/goal` bundle from the PRD; for `/loop` and `/next-task`, the runtime (Step 14) composes the cadence prompt from the same `goal`/`mission` blocks. Your job in Step 11 is to make the `goal` block airtight — a precise, verifiable stopping condition is worth more than any prompt wording, because every downstream loop inherits it.

**Step 11.5 handoff:** After PRDs are approved, Step 11.5 converts approved PRDs into an ordered, dependency-aware `.sigma/backlogs/<mode>/TASKS.md` — a vendor-neutral manifest with claim fields and the `/next-task` autonomous-loop contract. The implementation loops in Step 14 pull from that queue. See `/step-11.5-task-handoff`.

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 11.5, backlog conversion, or Step 12 without explicit approval **after** Canonical Schema Compliance and optional emission are complete for every PRD.
Use AskUserQuestion: "All Step 11 PRDs complete (schema-valid, optional bundles emitted). Ready to proceed?"
Options: [Proceed to Step 11.5 — Task Handoff, Run sigma prd-json for backlog conversion, Revise PRDs]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 11 Verification Schema

### Required Outputs (25 points)

| Item | Path | Points |
|------|------|--------|
| At least one feature PRD | docs/prds/F*-*.md | 15 |
| PRD Status | Linear — PRD Document + wave-labeled issue (when configured) OR docs/prds/.prd-status.json | 10 |

### Required Sections per PRD (40 points)

| Section | Points |
|---------|--------|
| Section 0: Shape Metadata | 3 |
| Section 0.5: Environment & Data Contract | 4 |
| Section 1: Problem & Outcome | 3 |
| Section 2: Scope + Do NOT Build | 4 |
| Section 3: User Stories + BDD Scenarios | 5 |
| Section 4: Functional Requirements (table) | 3 |
| Section 5: Data Model Delta | 3 |
| Section 6: API/Action Contract | 4 |
| Section 7: UI & Component Contract | 3 |
| Section 8: State & Recovery Contract | 3 |
| Section 10: Testing & Acceptance (predicates) | 3 |
| Section 12: Agentic Notes (file paths) | 2 |

### Quality Indicators (25 points)

| Check | Points |
|-------|--------|
| BDD scenarios are machine-executable (concrete Given-When-Then) | 6 |
| Acceptance criteria are testable predicates | 5 |
| Negative requirements ("Do NOT") present | 4 |
| File paths in agentic implementation notes | 4 |
| PRD passes "overnight test" — zero clarification needed | 4 |
| Upstream decisions inherited, not duplicated | 2 |

### Handoff & Boundary (10 points)

| Check | Points |
|-------|--------|
| PRD status updated (Linear issue/Document or .prd-status.json) with approval flag | 2 |
| Verifier Gate passed (judge ≠ generator) before `approved: true`, evidence in Section 0 | 2 |
| Step 8 contracts respected | 2 |
| Step 10 shaping preserved | 2 |
| $holes pass completed per PRD | 2 |

**Passing score:** 95/100
</verification>

$END$
