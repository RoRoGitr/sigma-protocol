---
version: "1.2.0"
last_updated: "2026-09-19"
description: "Step 8: Technical Spec → TECHNICAL-SPEC.md — implementation blueprint converting architecture, flows, design system, and states into engineering-ready contracts"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --depth
  - --api
  - --schema
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
- `api-design-principles`
- `shadcn`
- `rn-component-library`
- `react-native-patterns`
- `mobile-app-security`
- `billing-patterns`
- `supabase-patterns` — only when `docs/stack-profile.json` selects Supabase
- `karpathy-guidelines`
- `ponytail`
- `platform-design-guidelines`
- `mobile-ui-testing`
- `frontend-design`
- `react`
- `tauri-patterns`
- `electron`

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-8-technical-spec — Technical Specification & Implementation Blueprint

**On start, announce:** "Running Step 8: Technical Spec. I'll convert architecture, prototype flows, design system, and state behavior into an engineering blueprint that agents can build from."

<goal>
You are the Implementation Blueprint Architect. Execute ALL phases (A through E) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import All Prior Decisions | Locked preconditions from Steps 2-7 |
| B | Implementation Architecture | Module boundaries, runtime model, shared contracts |
| C | Frontend + Backend Blueprint | Route structure, component strategy, service patterns, API contracts, data model |
| D | Security, Testing & Operations | Auth rules, test strategy, deployment, state implementation |
| E | Output, Hardening & Handoff | TECHNICAL-SPEC.md + conditional artifacts + Step 11 handoff |

Required Output: `docs/technical/TECHNICAL-SPEC.md`

Conditional (only when project requires them):
- `docs/api/OPENAPI-SPEC.yaml` — when custom HTTP API surface exists
- `docs/database/SCHEMA-COMPLETE.sql` — when custom schema extensions exist

Quality gate: 95+/100 on verification schema.

**Core rule:** If engineers or coding agents would still have to guess, the section is not complete.

**AI-native output rule:** TECHNICAL-SPEC.md is the primary input for Step 11 PRD generation. Every section must be structured (tables, predicates, code blocks) — not narrative prose. Agents will parse this to generate implementation PRDs.
</goal>

---

## Trigger

**Run after Step 7 (Interface States) is approved.** Step 8 imports decisions from Steps 2-7. If Step 7 STATE-SPEC.md is missing, stop and inform the user.

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
- Step start: create issue "Step 8: Technical Spec" — labels `step-8`, `wave:W0`, state In Progress.
- Milestone issue as the blueprint lands: "Step 8: Blueprint defined" — labels `step-8`, `wave:W0`.
- On TECHNICAL-SPEC.md completion: move the tracking issue to Done.

---

## Step Boundary

- **Step 8 owns:** implementation blueprint, frontend/backend patterns, API contract strategy, data model, auth/security rules, testing strategy, delivery expectations, state implementation rules, Step 11 handoff.
- **Step 8 does NOT own:** architecture decisions (Step 2), design system (Step 6), state taxonomy/recovery design (Step 7), feature-level PRDs (Step 11).
- **Do NOT** re-decide architecture. Convert decisions into implementation guidance.

Step relationship: Step 2 (architecture) → Step 5 (prototype flows) → Step 6 (design system) → Step 7 (state behavior) → **Step 8 (implementation blueprint)** → Step 11 (feature PRDs).

---

## Implementation Principles

### Structure Beats Prose
When 20 agents implement the same feature, the ones with structured specs agree on behavior. The ones with prose specs each make different "reasonable" assumptions. Make decisions explicit, machine-readable, and verifiable.

### Clarity Beats Cleverness (Ousterhout)
If the spec leaves room for guessing, it's not done. Implementation guidance must be specific enough that an agent builds correctly on the first pass.

### Spec-Driven Development (the spec is an executable contract)
This blueprint and the Step 11 PRDs it feeds are not passive documentation — they are the **executable contract** that constrains what coding agents generate. This is the Spec-Driven Development (SDD) paradigm that converged across tooling in 2026 (Spec-Kit, BMAD, OpenSpec): the spec, not the chat, is the source of truth, and acceptance criteria are verifiable gates rather than prose intentions. Two consequences for this step:
- **EARS acceptance criteria are the contract surface.** Every requirement that crosses into Step 11 must be expressible as an EARS `SHALL` clause (see below) so it round-trips into a failing test before any code is written.
- **Size the spec to the agent's context budget.** A spec the agent cannot hold in context is a spec it will partially ignore (Addy Osmani, "How to write a good spec for AI agents"). Keep each blueprint section self-contained and reference-by-path rather than inlining upstream documents; the goal is a spec an agent reads once and implements without re-deriving prior decisions.

### API-First / Contract-First
Where the project exposes or consumes HTTP APIs, the contract is explicit BEFORE implementation. Auth, error contracts, versioning, and request/response shapes are defined — not discovered during coding.

### Conditional Outputs, Not Mandatory Doc Packs
Generate OpenAPI and SQL schema ONLY when the project has custom API surfaces or database entities. Don't create empty boilerplate artifacts.

---

## Phase A — Import All Prior Decisions

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read all prior step outputs:
   - `.sigma/runtime-baseline.json` (Step 0)
   - `docs/specs/MASTER_PRD.md` (Step 1)
   - `docs/specs/OFFER_ARCHITECTURE.md` + `docs/specs/pricing-config.json` (Step 1.5, if applicable)
   - `docs/architecture/ARCHITECTURE.md` (Step 2)
   - `docs/prds/flows/*/FLOW-*.md` + `docs/prds/flows/PRD-SUMMARY.md` (Step 5)
   - `docs/design/DESIGN-SYSTEM.md` + `docs/tokens/design-tokens.json` (Step 6)
   - `docs/states/STATE-SPEC.md` (Step 7)
3. **Detect approved visual sources (for frontend blueprint):** record each source as `kind`, `path`, `version or snapshot date`, `viewports`, and `approval status`. Supported kinds include Pen, Taste Code, Figma export, generated HTML, and repository-native prototype. Use only sources that exist; a source tool is not a runtime dependency.
4. Read `.sigma/boilerplate.json` and `docs/stack-profile.json` if present.
5. If `research_mode = blocked` → stop. If `reduced` → label assumptions.

### Document imported decisions

| Source | Key Decisions Imported | Open Questions |
|--------|----------------------|----------------|
| Step 2 | Architecture style, profile, boundaries, deployment | |
| Step 5 | Flow behavior, screen count, prototype data register, **approved visual source** (kind, path, snapshot, viewports, approval status) | |
| Step 6 | Token architecture, component families, motion tokens | |
| Step 7 | State taxonomy, recovery patterns, a11y rules, focus management | |
| Stack profile | Framework, database, hosting, auth provider | |

### Sequential Decisions

**Decision 1: Custom API surface**
Use AskUserQuestion: "Does this project have a custom HTTP API surface that needs an OpenAPI spec?"
Options: [Yes — generate OPENAPI-SPEC.yaml, No — no custom API surface, Already defined in Step 2 architecture]

**Decision 2: Custom schema**
Use AskUserQuestion: "Does this project have custom database entities that need a schema spec?"
Options: [Yes — generate SCHEMA-COMPLETE.sql, No — using inherited/managed schema, Already defined in Step 2 architecture]

<HARD-GATE>
Do NOT proceed to Phase B until user approves imported decisions.
Use AskUserQuestion: "All prior decisions imported. Approve?"
Options: [Approve — design implementation architecture, Revisit a prior step, Adjust API/schema decisions]
</HARD-GATE>

---

## Phase B — Implementation Architecture

### Implementation Discipline (advisory)

When this technical spec drives downstream PRDs (Step 11) and code (Step 14+), agents implementing it should invoke `karpathy-guidelines` and `ponytail`:
- **Simplicity first** — minimum code that solves the problem; no speculative features or "configurability" not asked for
- **Surgical changes** — touch only what the spec requires; do not "improve" adjacent code
- **Surface assumptions** — when a spec line is ambiguous, state assumptions explicitly in the PR or completion report; do not guess silently
- **Goal-driven execution** — tie every implementation task to a verifiable success criterion (failing test → passing test)

These are behavioral rules for the implementer, not architecture decisions. They reduce drift between this spec and the eventual code.

### Define the implementation shape (not re-deciding Step 2 — converting it)

**Runtime model:** How the system runs (monolith, serverless, service mesh, edge functions)

**Module boundaries:**
| Module | Responsibility | Dependencies | Boundary Type |
|--------|---------------|-------------|---------------|

**Shared contracts:** Types, interfaces, and schemas shared across modules

**Frontend/backend boundary:** Where the split happens, how they communicate

**External service boundaries:** How each integration connects (SDK, REST, webhook, queue)

### Chosen Stack — per-platform library manifest

Read `docs/stack-profile.json`. Based on the `platform` field, record the definitive library choices here. This section is the authoritative source for Step 11 PRDs — agents implementing PRDs read this to know exactly what to import and install.

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

Copy `chartsLibrary` and `gamification` blocks from `stack-profile.json` when set in Step 2. If charts are required but `chartsLibrary` is unset, default mobile → `@bklit/charts`, web dashboard → `tremor`.

**If `platform = "mobile"` (Expo / React Native):**

| Layer | Chosen Library | Install Command |
|-------|----------------|-----------------|
| Navigation | expo-router (file-based) | pre-installed via `npx create-expo-app` |
| Styling | NativeWind v4 + Tailwind | `npx expo install nativewind tailwindcss` |
| Components | React Native Reusables (`@rn-primitives/`) | `npx @react-native-reusables/cli@latest init` |
| Animation | react-native-reanimated (worklets on UI thread) | `npx expo install react-native-reanimated` |
| Gestures | react-native-gesture-handler | `npx expo install react-native-gesture-handler` |
| Lists | @shopify/flash-list (FlashList v2) — never FlatList | `npx expo install @shopify/flash-list` |
| Images | expo-image (memory+disk caching, blurhash) | `npx expo install expo-image` |
| Fast KV storage | react-native-mmkv | `npx expo install react-native-mmkv` |
| Secure storage | expo-secure-store (Keychain / Keystore) | `npx expo install expo-secure-store` |
| Area context | react-native-safe-area-context | `npx expo install react-native-safe-area-context` |
| Screens | react-native-screens | `npx expo install react-native-screens` |
| Charts | @bklit/charts (Skia) | `npm install @bklit/charts react-native-skia` |
| State management | Zustand (stores as view models) | `npm install zustand` |
| Server state | TanStack Query v5 | `npm install @tanstack/react-query` |
| Testing E2E | Maestro (YAML flows, cross-platform) | `curl -fsSL https://get.maestro.mobile.dev \| bash` |
| Testing unit/component | Jest + React Native Testing Library v14 | pre-installed via Expo template |

Skills to invoke in PRD agents: `react-native-patterns`, `rn-component-library`, `mobile-app-security`, `platform-design-guidelines`, `mobile-ui-testing`

**Security baseline for mobile (MASVS-enforced in every PRD):**
- Secrets → `expo-secure-store` (Keychain on iOS, Keystore on Android). Never MMKV for secrets.
- Network → HTTPS only; certificate pinning by SPKI hash for production APIs.
- Auth → biometric via `expo-local-authentication` for sensitive actions.
- No cleartext logging of tokens, PII, or credentials.
- Android: `cleartextTrafficPermitted="false"` in Network Security Config.
- iOS: `NSAllowsArbitraryLoads: false` in Info.plist.

---

**If `platform = "web"` (Next.js):**

| Layer | Chosen Library | Install Command |
|-------|----------------|-----------------|
| Framework | Next.js (App Router) | `npx create-next-app@latest` |
| Styling | Tailwind CSS v4 | included in Next.js template |
| Components | shadcn/ui | `npx shadcn@latest init` |
| Motion | Motion (Framer Motion successor) | `npm install motion` |
| State | Zustand | `npm install zustand` |
| Server state | TanStack Query v5 | `npm install @tanstack/react-query` |
| Testing unit | Vitest + React Testing Library | `npm install -D vitest @testing-library/react` |
| Testing E2E | Playwright | `npm install -D @playwright/test` |

Skills to invoke in PRD agents: `frontend-design`, `shadcn`, `react`

---

**If `platform = "desktop"` with `framework = "tauri"`:**

| Layer | Chosen Library | Install Command |
|-------|----------------|-----------------|
| Desktop shell | Tauri 2 | `npm create tauri-app@latest` |
| Frontend | React + TypeScript (Vite) | included in tauri template |
| Styling | Tailwind CSS v4 + shadcn/ui | `npx shadcn@latest init` |
| IPC | Typed command wrappers (never raw invoke) | — (pattern, no package) |
| Persistence | SQLite via tauri-plugin-sql | `cargo add tauri-plugin-sql` |
| Secrets | OS keychain via tauri-plugin-stronghold | `cargo add tauri-plugin-stronghold` |
| Auto-update | tauri-plugin-updater | `cargo add tauri-plugin-updater` |

Skills to invoke in PRD agents: `tauri-patterns`

---

**If `platform = "desktop"` with `framework = "electron"`:**

| Layer | Chosen Library | Install Command |
|-------|----------------|-----------------|
| Desktop shell | Electron (electron-vite scaffold) | `npm create @quick-start/electron@latest` |
| Frontend | React + TypeScript | included in electron-vite template |
| Styling | Tailwind CSS v4 + shadcn/ui | `npx shadcn@latest init` |
| IPC | contextBridge typed wrappers (`contextIsolation: true`, `nodeIntegration: false`) | — (pattern, no package) |
| Persistence | better-sqlite3 | `npm install better-sqlite3` |
| Secrets | safeStorage (built-in Electron API) | — (Electron built-in) |

Skills to invoke in PRD agents: `electron`

---

### Research (directive queries)

1. Search `"[framework from stack-profile] implementation patterns 2026"` — current framework patterns
2. Search `"[database] schema design [domain] best practices"` — data modeling
3. If API: Search `"[framework] API route design REST 2026"` — API patterns

<HARD-GATE>
Do NOT proceed to Phase C until user approves implementation architecture.
Use AskUserQuestion: "Implementation architecture defined. Approve?"
Options: [Approve — build frontend + backend blueprint, Adjust module boundaries, Revisit architecture]
</HARD-GATE>

---

## Phase C — Frontend + Backend Blueprint

### Frontend Implementation Blueprint

**Route/page structure:**
| Route | Page/Screen | Component Strategy | Step 5 Flow Reference |
|-------|-----------|-------------------|----------------------|

**Component composition:** How Step 6 tokens and component families are consumed in code

**Platform component scaffold matrix:**

The table below maps each flow from Step 5 to the specific component primitives that must be scaffolded, derived from the chosen-stack section above. Step 11 PRD agents use this table to know exactly what to install and generate — not to discover it during implementation.

| Screen / Route | Platform | Primitive Components | Install Commands (if not yet installed) | Source (bundle or wireframe) |
|---------------|----------|---------------------|----------------------------------------|------------------------------|
| [screen-id from Step 5] | mobile / web / desktop | e.g. `<Button>`, `<Card>`, `<Input>` from rn-reusables / shadcn | e.g. `npx @react-native-reusables/cli@latest add button card input` | docs/prds/flows/[flow]/… |

**Rules for completing this table:**
- MOBILE: component names come from `react-native-reusables`. Install command is `npx @react-native-reusables/cli@latest add [name]`. Do not use `react-native` built-in `<View>` as a final component for interactive surfaces — wrap with a typed reusable component.
- WEB: component names come from `shadcn/ui`. Install command is `npx shadcn@latest add [name]`.
- DESKTOP (Tauri/Electron): component names come from `shadcn/ui` (shared with web). Same install command.
- Every screen from Step 4 must appear in this table. If a screen has no UI components (e.g. a pure redirect), mark `n/a` explicitly.

**State implementation:** How Step 7 states are rendered (skeleton, error boundary, empty state components)

**Accessibility implementation:** How Step 7 announcement rules become ARIA attributes, focus traps, keyboard handlers — plus platform-specific rules:
- MOBILE: VoiceOver (iOS) / TalkBack (Android) labels on all interactive elements. Minimum 44pt touch targets. Dynamic Type via NativeWind `text-[size]` variants that respect system font scale.
- DESKTOP: keyboard shortcut per primary action, focus ring per platform convention, screen reader compatibility via ARIA roles on web renderer.

**Design system consumption:** How design-tokens.json maps to CSS variables / Tailwind theme / NativeWind `className` / component props

**Visual source contract:** For each UI feature, name the approved visual source by `kind`, repository `path`, snapshot/version date, target viewports, and acceptance status. Preserve its component boundaries where practical. Do not require or privilege a named design generator.

### Backend & Service Blueprint

**API paradigm decision:**
| Paradigm | Best For | When to Use |
|----------|---------|-------------|
| **Server Actions** | Next.js internal mutations, forms | Default for full-stack Next.js — no API route boilerplate |
| **tRPC** | Full-stack TypeScript monorepos | When types must cross client/server without codegen |
| **REST** | Public APIs, mobile clients, non-TS consumers | Universal default for external-facing APIs |
| **GraphQL** | Complex data graphs, multiple consumers with different needs | Only when clients genuinely need different data shapes |

**Safe Action Pattern** (when using Server Actions):
Every Server Action is a public HTTP POST endpoint. Production pattern:
1. Authenticate → 2. Parse → 3. Validate (Zod) → 4. Authorize → 5. Mutate
Use composable middleware (`next-safe-action` or equivalent). Never run business logic before auth + validation.

**Domain/service patterns:**
| Service/Action | Domain | Input Schema | Output Shape | Auth Level | Side Effects |
|---------------|--------|-------------|-------------|-----------|-------------|

**Validation architecture:**
- Schema validation is SERVER-SIDE with Zod (or equivalent). Client validation is UX only.
- Shared schemas between client and server (import from `lib/validators/`)
- `safeParse` → return field-level errors, not throw

**Error contract (standardized across all endpoints):**
```typescript
type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string; errors?: Record<string, string[]> }
```

**Background jobs:** When needed — what triggers, what they do, retry (exponential backoff), failure/dead-letter behavior

**Integration patterns:** For each external service — SDK, error handling, retry, circuit breaker

### Tool and workflow contract (only for AI/tool-using features)

State whether model work is inline, durable workflow, or sandboxed. For every tool or remote-agent call define input/output schema, side effect, authenticated subject and tenant context, authorization recheck at the effect boundary, approval mode, timeout, idempotency key, retry/cancellation behavior, durable-state location, and audit ID. A child or model identity never substitutes for user authorization.

Use MCP only for tool/resource exposure, ACP only at an editor-to-coding-agent boundary, and A2A only for independently deployed remote agents. Keep framework choice conditional on `docs/stack-profile.json` and the Step 2 runtime decision; no protocol or framework is required for an ordinary feature. Method references checked 2026-09-19: [MCP](https://modelcontextprotocol.io/specification/2025-06-18/server), [A2A](https://github.com/a2aproject/A2A/blob/main/docs/specification.md), [ACP](https://github.com/agentclientprotocol/agent-client-protocol/blob/main/docs/protocol/v2/overview.mdx), [Eve typed subagents](https://vercel.com/kb/guide/how-to-use-eve-subagents).

### API Contract Strategy (if Decision 1 = Yes)

**Route/resource strategy:**
| Method | Path | Purpose | Auth | Request Schema | Response Schema |
|--------|------|---------|------|---------------|----------------|

**Auth rules:** How auth is enforced per route (JWT, session, API key, public)

**Error contract:** Standardized error shape (see above) across all endpoints

**Versioning:** Strategy for breaking changes (URL versioning, header versioning, none)

**Cache strategy:** `revalidatePath` vs `revalidateTag` vs time-based cache. Document per-route.

Generate `docs/api/OPENAPI-SPEC.yaml` from these decisions.

### Data Model & Persistence Strategy (if Decision 2 = Yes)

**Entity definitions:**
| Entity | Fields | Relationships | Constraints | Indexes |
|--------|--------|--------------|-------------|---------|

**Persistence patterns:** ORM/query builder, migration strategy, seed data approach

**Security:** Row-level security, data access patterns, sensitive field handling

Generate `docs/database/SCHEMA-COMPLETE.sql` from these decisions.

<HARD-GATE>
Do NOT proceed to Phase D until user approves frontend + backend + contracts.
Use AskUserQuestion: "Frontend, backend, and contract blueprints complete. Approve?"
Options: [Approve — define security and testing, Revise frontend patterns, Adjust API contracts, Revise data model]
</HARD-GATE>

---

## Phase D — Security, Testing & Operations

### Security & Auth Implementation Rules

- Auth provider and flow (OAuth, email/password, MFA, API keys)
- Secret/key handling (env vars, vault, never in committed files)
- Request validation patterns (Zod, Valibot, custom)
- Permission enforcement (middleware, RLS, role checks)
- Rate limiting strategy
- CORS configuration
- Monetization/entitlement enforcement (if Step 1.5)
- Subject and tenant propagation from route → workflow → model/tool/remote agent, with authorization rechecked at each side effect

### State Implementation Rules (from Step 7)

How each state family becomes code:
- Empty → component with CTA + illustration
- Loading → skeleton component matching layout
- Error → error boundary + retry mechanism
- Offline → service worker / cache-first + queue
- Permission/locked → middleware guard + UI fallback

### EARS Acceptance Criteria Requirement

All acceptance criteria in this spec — and in every Step 11 PRD derived from it — **must be written as EARS patterns**. EARS (Easy Approach to Requirements Syntax) produces machine-parseable predicates that auto-generate test stubs.

The three required EARS forms:

| Pattern | Template | Use for |
|---------|----------|---------|
| Event-driven | `WHEN [event or trigger] THE SYSTEM SHALL [response]` | UI interactions, API calls, user actions |
| State-triggered | `WHILE [system state] THE SYSTEM SHALL [behavior]` | Ongoing conditions, background constraints |
| Conditional | `IF [precondition] THE SYSTEM SHALL [response]` | Guards, branching logic, optional behaviors |

**Examples:**
```
WHEN a user submits the login form with valid credentials THE SYSTEM SHALL redirect to the dashboard within 200ms.
WHILE a background job is running THE SYSTEM SHALL display a progress indicator.
IF the user's session token has expired THE SYSTEM SHALL redirect to /login and clear the session cookie.
```

**Test planning:** Each EARS criterion maps to a test case in the project's installed test runner — the WHEN/WHILE/IF becomes the test description and the SHALL clause becomes the assertion predicate. Step 11 PRD agents write the test before implementing when the criterion is automatable.

Write all acceptance predicates in Section 10 of each feature PRD using EARS form. Prose predicates ("should work fast") are not acceptable — rewrite as EARS before approving the PRD.

### Testing Strategy

| Test Type | Framework | Coverage Target | What It Validates |
|-----------|-----------|----------------|------------------|
| Unit | Installed unit runner (for example, Vitest) | Core business logic | Pure functions, validators, transformers, state transitions |
| Component | Installed component runner + Testing Library where applicable | Component behavior | Renders, interactions, and state changes |
| Integration | Installed runner + isolated test dependencies | API contracts + data flow | Server Actions, procedures, and database queries |
| E2E | Installed browser automation runner (for example, Playwright) | Critical user journeys | Full flow from UI to persistence |
| Accessibility | Accessibility checker + browser runner | Project accessibility target | Contrast, focus, ARIA, and keyboard behavior |
| State verification | Selected component or browser runner | Step 7 state coverage | Empty, loading, error, recovery, and permission states |
| Tool/workflow (when applicable) | Contract + integration runner | Schemas, authorization, approval, retry/resume | Rejects unknown or high-risk arguments; tenant isolation; cancellation or restart behavior follows policy |

**Server Action testing pattern:**
```typescript
// Mock auth, test as pure functions
vi.mock("@/lib/auth", () => ({ getSession: vi.fn() }));
it("rejects unauthenticated", async () => {
  vi.mocked(getSession).mockResolvedValue(null);
  const result = await createPost(null, formData);
  expect(result.success).toBe(false);
});
```

**Coverage merging:** Combine unit + component + E2E coverage into single report. Use V8 provider for consistent coverage across test types.

### Delivery & Operations

- Deployment strategy (Vercel, Render, Docker, etc.)
- Environment parity (dev/staging/production)
- CI/CD expectations (what runs on PR, what runs on merge)
- Monitoring/observability (error tracking, performance, uptime)
- Rollback strategy

<HARD-GATE>
Do NOT proceed to Phase E until user approves security + testing + ops.
Use AskUserQuestion: "Security, testing, and operations defined. Approve?"
Options: [Approve — write final spec, Strengthen security rules, Adjust testing strategy]
</HARD-GATE>

---

## Phase E — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Implementation guidance that leaves room for guessing
- Missing API contracts or undefined error shapes
- Security gaps (missing auth on routes, no rate limiting)
- State implementation rules that don't match Step 7
- Step 11 handoff that's vague or incomplete

Fix findings before presenting.

### Write `docs/technical/TECHNICAL-SPEC.md`

Required sections:
```
Executive Technical Summary
Imported Decisions & Preconditions
Implementation Architecture (module boundaries, runtime, shared contracts)
Frontend Implementation Blueprint
Backend & Service Blueprint
API Contract Strategy (explicit Yes/No + details if Yes)
Data Model & Persistence Strategy (explicit Yes/No + details if Yes)
Security & Auth Implementation Rules
State Implementation Rules (from Step 7)
Testing Strategy
Delivery & Operations Expectations
Step 11 Handoff
Do NOT Build in This Step
```

### Step 11 Handoff must explicitly state:

- What feature-level detail Step 11 must specify
- API contract decisions Step 11 PRDs must respect
- Schema decisions Step 11 must preserve
- Security patterns Step 11 must enforce
- State rules Step 11 must implement
- Testing requirements per feature PRD
- **Platform component library** — the exact component library (react-native-reusables / shadcn/ui / other) every PRD must use; any PRD that introduces a different component library must declare it explicitly and justify the deviation
- **Per-screen component install commands** — copied from the Platform Component Scaffold Matrix; Step 11 PRD agents run these before scaffolding each feature
- **Skills to invoke** — the platform-specific skill names that Step 11 PRD agents must invoke (see Chosen Stack section above)

### Writing Standards (embedded)

- No stock AI phrases: "Scalable", "Enterprise-grade", "Best-in-class", "Cutting-edge"
- Implementation guidance is specific: "Use Zod for request validation with shared schemas in `lib/validators/`" not "validate inputs appropriately"
- API contracts show actual shapes, not descriptions of shapes
- Data models show actual fields, not descriptions of what entities exist
- Write like a staff engineer handing a blueprint to the team, not a consultant writing a proposal

### Success Criteria

- [ ] All Steps 2-7 decisions imported and referenced
- [ ] Implementation architecture converts Step 2 decisions (doesn't re-decide)
- [ ] Frontend blueprint references Step 5 flows, Step 6 tokens, Step 7 states
- [ ] API Contract: explicit Yes/No with OpenAPI if Yes
- [ ] Schema: explicit Yes/No with SQL if Yes
- [ ] Security rules are implementation-specific (not "follow best practices")
- [ ] Testing strategy has concrete framework + coverage targets
- [ ] AI/tool-using features define typed tool/workflow contracts, subject/tenant propagation, authorization at side effects, and restart/cancel evidence
- [ ] Step 11 handoff is explicit and actionable
- [ ] $holes pass completed
- [ ] Linear tracking issues created (when configured)
- [ ] User approved

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 9 or Step 10 without explicit approval.
Use AskUserQuestion: "Step 8 complete. What's next?"
Options: [Proceed to Step 9 — Landing Page (optional), Skip to Step 10 — Feature Breakdown, Revise technical spec]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 8 Verification Schema

### Required Outputs (30 points)

| Item | Path | Points |
|------|------|--------|
| Technical Spec | docs/technical/TECHNICAL-SPEC.md | 20 |
| OpenAPI Spec | docs/api/OPENAPI-SPEC.yaml | 5 (only when API = Yes) |
| Schema SQL | docs/database/SCHEMA-COMPLETE.sql | 5 (only when Schema = Yes) |

### Required Sections (35 points)

| Section | Points |
|---------|--------|
| Executive Technical Summary | 3 |
| Imported Decisions & Preconditions | 4 |
| Implementation Architecture | 5 |
| Frontend Implementation Blueprint | 5 |
| Backend & Service Blueprint | 5 |
| API Contract Strategy (explicit Yes/No) | 4 |
| Data Model Strategy (explicit Yes/No) | 4 |
| Security & Auth Rules | 3 |
| Testing Strategy | 2 |

### Quality Indicators (25 points)

| Check | Points |
|-------|--------|
| Implementation guidance specific enough — no guessing needed | 6 |
| API contracts show actual request/response shapes | 5 |
| Data models show actual fields and relationships | 5 |
| State implementation rules match Step 7 spec | 4 |
| Testing has concrete framework + coverage targets | 3 |
| Security rules are implementation-specific | 2 |

### Handoff & Boundary (10 points)

| Check | Points |
|-------|--------|
| Step 11 handoff explicit and actionable | 4 |
| No Step 2 architecture re-decided | 2 |
| No Step 7 state taxonomy re-defined | 2 |
| $holes pass completed | 2 |
| Linear tracking issues created (when configured) | 1 |

**Passing score:** 95/100
</verification>

$END$
