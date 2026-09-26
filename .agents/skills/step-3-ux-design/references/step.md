---
version: "3.3.0"
last_updated: "2026-09-19"
description: "Step 3: UX Design → UX-DESIGN.md + DESIGN.md — experience goals, journeys, IA, interaction design, accessibility, Design DNA, and agentic UI patterns"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --research-depth
  - --ui-profile
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

- `ux-designer`
- `design-taste`
- `ux-psychology-pro`
- `web-design-guidelines`
- `platform-design-guidelines`
- `shadcn`
- `rn-component-library`
- `apple-native`
- `apple-platform-design`
- `macos-design`
- `motion-landing-design`
- `companion-system`
- `agentic-ui`
- `deep-research` — Phase E (Design DNA research)
- `react-native-patterns` — curated preflight (mobile Expo)

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

- `holes` — mandatory pre-approval gap pass (invoke via `$holes` or Skill tool at the step's final gate)

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-3-ux-design — UX Strategy, Journeys, and Interaction Direction

**On start, announce:** "Running Step 3: UX Design. I'll walk you through 6 phases — importing context, defining experience goals, mapping journeys and IA, designing interactions and accessibility, selecting Design DNA, and producing UX-DESIGN.md + DESIGN.md (the canonical design contract)."

<goal>
You are the UX Strategy Lead. Execute ALL phases (A through F) in order.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Import Context | Confirmed UX inputs + platform constraints |
| B | Experience Goals & UX Drivers | Goals, constraints, first-value strategy |
| C | Journey Model & Information Architecture | Journeys, IA, navigation, screen families |
| D | Interaction Design, Accessibility & Platform | Interaction rules, state intent, a11y, responsive strategy |
| E | Design DNA & DESIGN.md | DESIGN.md (canonical) + ui-profile.json (derived mirror) |
| F | Output, Hardening & Handoff | UX-DESIGN.md with Step 4/6/7 handoffs |

Final Outputs:
- `DESIGN.md` (repo root) — **the canonical design contract** in Google's open `design.md` format: YAML token frontmatter + Markdown prose. The named Design DNA (5 invariants, two amplitudes, anti-DNA, migration doctrine) lives in its prose layer. Lints with `npx @google/design.md lint DESIGN.md`.
- `docs/design/ui-profile.json` — a derived machine mirror of DESIGN.md's dials for Sigma's downstream steps.
- `docs/design/DNA-REFERENCES.md` — task-relevant reference observations and direction decisions.
- `docs/ux/UX-DESIGN.md` — UX strategy, journeys, IA, interaction, accessibility.

Quality gate: 95+/100 on verification schema.

**AI-native output rule:** UX-DESIGN.md and DESIGN.md are consumed by AI agents in Steps 4, 5, 6, 7, and 9. Bullet points, tables, and structured tokens — not narrative prose. Zero ambiguity.
</goal>

---

## Step Boundary

- **Trigger:** Run after Step 2. Requires `docs/architecture/ARCHITECTURE.md` and `docs/specs/MASTER_PRD.md`.
- **Step 3 owns:** experience goals, journeys, IA, navigation logic, interaction principles, accessibility commitments, responsive/platform strategy, Design DNA selection, visual direction, UI profile.
- **Step 3 does NOT own:** complete screen inventory (Step 4), visual tokens and component styling (Step 6), exhaustive state-by-state specs (Step 7), landing page CRO (Step 9).
- **Do NOT** create final wireframes, component specs, or design token values. Define direction, not implementation.
- **Fallback:** If ARCHITECTURE.md is missing, prompt user to run Step 2 first. If MASTER_PRD.md is missing, prompt for Step 1.

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
- Phase A start: create issue "Step 3: UX Design in progress" — labels `step-3`, `wave:W0`, state In Progress.
- After Phase C (journeys locked): create one issue per journey "Step 3: Journey — {journey} mapped" — labels `step-3`, `wave:W0`.
- On UX-DESIGN.md + DESIGN.md completion (Phase F): move the tracking issue to Done and create "Step 3: UX-DESIGN.md complete" — labels `step-3`, `milestone`, `wave:W0`.

---

## UX Framework Library

Use to drive decisions. Skip frameworks that don't apply. Each must end in a decision.

### Don Norman — Three Levels of Emotional Design
- **Visceral** — first impression, immediate trust
- **Behavioral** — usability, responsiveness, feedback quality
- **Reflective** — identity, pride, meaning, memory

Apply: define which level matters most for this product's competitive position.

### Journey-Centric Design (NN/g)
- Journeys are the organizing unit, not isolated screens
- Map cross-screen experiences end-to-end
- Identify where present-state friction threatens the desired future-state journey
- Define success moments, not just task completion

### Information Architecture (Baymard)
- Content and feature grouping by user mental model
- Navigation predictability — users should never feel lost
- Route and screen hierarchy that minimizes findability friction
- Search behavior when the product has enough depth to need it

### Complex Application UX (NN/g)
Apply when the product supports expert workflows, high-stakes tasks, or nonlinear flows:
- Research the work, not just the user label
- Support branching and nonlinear flows without overwhelming
- Layer complexity — progressive disclosure for depth

### Accessibility-First Design (WCAG 2.2 AA)
Not a later QA pass — part of the UX contract from Step 3:
- Keyboard behavior + focus management
- Touch targets: meet the applicable platform sizing rules; web pointer targets follow WCAG 2.2 AA (24 by 24 CSS pixels or a documented qualifying exception). Prefer larger touch targets and record the chosen size/spacing and input mode
- Reduced-motion support
- Screen reader semantic structure
- Contrast ratios (4.5:1 body text, 3:1 large text/UI components)
- Text alternatives for non-text content

### Agentic UI (when Decision 3 is Yes or Partially)

**Invoke skill:** `agentic-ui` — do not rely on the summary below.

Apply the six patterns from the skill (Intent Preview, Autonomy Dial, Explainable Rationale, Confidence Signal, Action Audit & Undo, Escalation Pathway). Record `agenticUi` block in `docs/design/ui-profile.json` per the skill.

### Design System as Agent Contract
When coding agents consume the design system, `DESIGN.md` serves both designers and agents. Record concrete component and visual constraints that either audience can apply. Runtime-generated interfaces are a separate product decision; do not add them solely because a trend report predicts them.
- Write the DNA invariants so an agent can enforce them mechanically (named fonts, named color logic, named motion physics) — not just adjectives a human interprets.
- Anything an agent could "reasonably" guess wrong (default font, accent hue, corner radius, density) must be stated explicitly. Ambiguity in `DESIGN.md` becomes slop at assembly time.
- Step 6 turns these invariants into machine-consumable tokens; Step 3's job is to make the DNA unambiguous enough that the token export and any agent-generated screen land on the same product.

### Platform-Specific Guidance
When platform differences matter, treat explicitly:
- Web, mobile web, native iOS (SwiftUI/HIG), native Android (Material 3), desktop
- For native Apple: apply Apple HIG where relevant
- For native Android: apply Material Design 3 where relevant
- For native macOS desktop apps (Electron, Tauri, native): invoke `macos-design` for traffic-light placement, sidebar layouts, vibrancy/blur, light/dark rules, and keyboard-first interaction patterns. Do NOT apply mobile HIG to desktop — they are different design surfaces.

### Cognitive & Behavioral Principles (advisory)

Invoke `ux-psychology-pro` to check experience goals against:
- **Hick's Law** — too many top-level choices increases decision time logarithmically
- **Fitts's Law** — frequently-used actions should be large and close to the user's pointer
- **Miller's Law** — navigation with >7 items overwhelms working memory
- **Jakob's Law** — users prefer interfaces that work like other apps they already use
- **Progressive Disclosure** — show only what's needed at each stage
- **Recognition over Recall** — show options rather than requiring memory

These inform Phase B (experience goals) and Phase D (interaction design). They do NOT replace the journey/IA/state work — they pressure-test it.

### Craft & Interaction Principles
Quality checks — not hype:
- Quality and consistency are strategic advantages
- Motion communicates, not decorates
- Users should feel in control
- The interface must not feel generic or randomly stylish
- Every aesthetic choice supports the product's purpose

---

## Design DNA Archetypes

Select one dominant archetype. This drives all downstream visual decisions.

| Archetype | Core Philosophy | Reference Products | Key Characteristics |
|-----------|----------------|-------------------|---------------------|
| **Professional/Craft** | Quality as strategy | Linear, Stripe, Figma, Vercel | Precision, polish, understated elegance |
| **Gamified/Engaging** | Make the mundane addictive | Duolingo, Superhuman | Rewards, streaks, progression, dopamine |
| **Wellbeing/Calming** | Mindful design | Headspace, Opal | Soft colors, gentle animations, breathing room |
| **Aggressive/High-Energy** | Create urgency | Sales apps, fitness apps | Bold colors, strong CTAs, momentum |
| **Delightful/Playful** | Spark joy | Notion, Arc Browser | Personality, whimsy, surprises |
| **Premium/Luxury** | Exclusivity | High-end fintech, VIP apps | Dark palettes, elevated restraint |
| **Social/Viral** | Sharing + connection | TikTok, Instagram | Share prompts, social proof, FOMO |
| **Health/Fitness** | Minimal friction, max results | Cal AI, Ladder | Photo-first, progress tracking, coaching |
| **Fintech/Trust** | Security meets usability | Cash App, Chime | Trust signals, confidence-building feedback |
| **Crypto/Trading** | Clarity at speed | Robinhood, Coinbase | Radical simplicity, real-time data |
| **Recovery/Transformation** | Deep personalization | Sobriety apps, QUITTR | Heavy personalization, quantified progress |
| **Open/Developer** | Transparent, infrastructure-like | Cal.com, OSS tools | Extensibility, visible system logic |

---

## Phase A — Import Context

### Preflight (auto)

1. Run `date +"%Y-%m-%d"`.
2. Read `.sigma/runtime-baseline.json`, `docs/specs/MASTER_PRD.md`, `docs/stack-profile.json`, `docs/architecture/ARCHITECTURE.md`.
3. Read `.sigma/boilerplate.json` if present — document extensions vs inherited UX baseline.
4. Read `docs/specs/OFFER_ARCHITECTURE.md` if Step 1.5 ran (monetization affects onboarding, paywalls, upgrade UX).
5. If `research_mode = blocked` → stop. If `reduced` → continue with assumption labels.

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

### Sequential Decisions

**Decision 1: Platform scope**
Use AskUserQuestion: "What platforms does the UX need to cover?"
Options: [Web only, Web + Mobile web, Web + Native mobile (React Native/Expo), Native iOS (SwiftUI), Cross-platform (web + mobile + desktop), Other]

**Decision 2: Product complexity**
Use AskUserQuestion: "How complex is the core user workflow?"
Options: [Simple — linear task flow, Moderate — multi-step with branching, Complex — expert workflows with nonlinear flows, Dashboard/data-heavy — analytics and monitoring]

**Decision 3: Agentic features**
Use AskUserQuestion: "Does this product include AI agent features users interact with?"
Options: [Yes — agents perform tasks for the user, Partially — AI assists but user drives, No — traditional software, Not sure yet]

<HARD-GATE>
Do NOT proceed to Phase B until user approves context imports.
Use AskUserQuestion: "UX context imported. Approve?"
Options: [Approve — define experience goals, Revise platform scope, Adjust complexity assessment]
</HARD-GATE>

---

## Phase B — Experience Goals & UX Drivers

### Required goal categories

1. **First-value goals** — what must the user understand/do immediately?
2. **Trust goals** — where is trust risk highest?
3. **Usability goals** — where is cognitive load risk highest?
4. **Emotional goals** — what should the user feel at key moments?
5. **Accessibility goals** — what WCAG commitments from the start?
6. **Platform constraints** — what platform differences materially change UX?
7. **Architecture constraints** — what architecture decisions limit or shape UX?
8. **Monetization constraints** — onboarding, paywall, upgrade, quota states (if Step 1.5)

### Research (directive queries)

1. Search `"[product domain] UX best practices 2026"` — current UX patterns
2. Search `"[primary user role] workflow UX"` — how target users expect to work
3. If agentic: Search `"agentic AI UX patterns 2026"` — agent interaction design

<HARD-GATE>
Do NOT proceed to Phase C until user approves goals.
Use AskUserQuestion: "Experience goals and UX drivers defined. Approve?"
Options: [Approve — map journeys and IA, Adjust goals, Research deeper]
</HARD-GATE>

---

## Phase C — Journey Model & Information Architecture

### Core User Contexts
- Primary user contexts, secondary users
- Expert vs novice needs when relevant
- Key jobs and usage modes

### Journey Model
For each major journey:

| Journey | Trigger | Goal | Key Stages | Friction Points | Success Moment | Emotional Intent |
|---------|---------|------|------------|----------------|----------------|-----------------|

### Information Architecture
- Top-level navigation model (tabs, sidebar, command palette, etc.)
- Hierarchy and grouping logic
- How users find core actions and information

### Screen Families (not final screens — Step 4 owns the inventory)
- Acquisition / onboarding
- Core work surfaces
- Management / settings
- Monetization / upgrade / billing (if applicable)
- Support / empty / fallback patterns

<HARD-GATE>
Do NOT proceed to Phase D until user approves journeys + IA.
Use AskUserQuestion: "Journeys and IA mapped. Approve?"
Options: [Approve — design interactions and accessibility, Revise journeys, Adjust navigation model]
</HARD-GATE>

---

## Phase D — Interaction Design, Accessibility & Platform

### Interaction Principles
- Primary interaction patterns (click, swipe, drag, keyboard shortcuts)
- Navigation behavior (routing, breadcrumbs, back behavior)
- Input and confirmation expectations
- Feedback expectations (loading, success, error)
- Error recovery (inline, toast, modal, retry)
- Speed vs explanation tradeoffs per context

### State Intent (Step 7 formalizes — Step 3 sets the direction)
Define UX intent for: empty states, loading states, error states, success states, permission/lock states, upgrade/quota states (if monetized).

### Accessibility Commitments
- Keyboard + focus: [expectations]
- Touch targets: meet the applicable platform sizing rules; web pointer targets follow WCAG 2.2 AA (24 by 24 CSS pixels or a documented qualifying exception). Prefer larger touch targets and record the chosen size/spacing and input mode
- Motion: respect `prefers-reduced-motion`
- Screen readers: semantic HTML, ARIA where needed
- Contrast: WCAG 2.2 AA (4.5:1 body, 3:1 large/UI)
- Text alternatives: all non-text content

### Responsive & Platform Strategy
- What's consistent across platforms
- What differs by platform
- Mobile constraints (thumb zones, viewport, performance)
- Desktop/expert differences
- Native platform conventions (HIG, Material 3) when applicable

### Agentic Interaction Design (if Decision 3 = Yes/Partially)
Map which of the 6 agentic patterns apply:
- Intent Preview needed? Where?
- Autonomy Dial — what's the default authorization level?
- Confidence signals — where does the agent need to show certainty?
- Audit trail — what actions need logging and undo?
- Escalation — where must the agent ask rather than guess?

<HARD-GATE>
Do NOT proceed to Phase E until user approves.
Use AskUserQuestion: "Interaction design + accessibility defined. Approve?"
Options: [Approve — select Design DNA, Adjust interaction patterns, Strengthen accessibility commitments]
</HARD-GATE>

---

## Phase E — Design DNA & DESIGN.md

> **Canonical output:** this phase produces `DESIGN.md` at the repo root in Google's open `design.md` format (YAML token frontmatter + Markdown prose). The Design DNA lives in its prose; `ui-profile.json` is a derived mirror. Do NOT write a separate `UI-PROFILE.md` or `<NAME>-DNA.md` — both fold into `DESIGN.md`.

### Design Thinking (embedded from frontend-design skill — apply before DNA selection)

Before selecting an archetype, answer these:
- **Purpose:** What problem does this interface solve? Who uses it daily?
- **Tone:** Choose a direction suited to this product category and task. A working desktop app may need quiet, familiar controls; expressive marketing or creative surfaces may justify a bolder treatment. Do not force an extreme.
- **Constraints:** Platform, framework, performance, accessibility requirements.
- **Distinction:** Which specific hierarchy, composition or behavior makes this product clear and recognizable? Familiarity and dependable interaction may be the intended qualities.

The answers to these questions refine which DNA archetype fits and HOW it gets applied.

### Mint a NAMED Design DNA (required — this is the product's design constitution)

The archetype table picks a *family*. This step mints a **named, product-specific Design DNA** that downstream steps treat as law. A named DNA is the difference between "another Professional/Craft SaaS" and a product with a recognizable, defensible visual identity.

**Give the direction a stable, descriptive name** that later steps can reference, such as the product name plus its workspace or site scope. A creative codename is optional; it does not establish design quality.

**Define the 5 invariants.** These are the load-bearing rules that do NOT change across any surface, breakpoint, or theme. Everything downstream (Step 5 wireframes, Step 6 tokens, Step 7 states, Step 9 landing page) must conform to them:

| # | Invariant | What it locks | Example questions it answers |
|---|-----------|---------------|------------------------------|
| 1 | **Material** | The physical substance the UI is "made of" | Matte or glossy? Paper, glass, metal, ink, fabric? Flat or layered depth? What is the surface's light behavior? |
| 2 | **Typography** | The voice of the type system | Chosen family or pairing, including system fonts, weight strategy and readable hierarchy |
| 3 | **Motion physics** | How things move — the easing personality | Snappy/instrument or fluid/cinematic? Mass and inertia? What motion is allowed where? (feeds the two-amplitude doctrine below) |
| 4 | **Surface stance** | The posture the UI takes toward the user | Calm/recessive or assertive/foreground? Dense or generous? Where it holds back vs. commands attention |
| 5 | **Truthfulness-as-visual-rule** | The honesty contract rendered in pixels | Loading shows real progress not theater; numbers never imply precision they don't have; empty/error states tell the truth; no decorative data, no fake density. A product earns trust by never lying with its UI. |

**Define the TWO amplitudes (same physics, different volume).** The DNA is one physics applied at two amplitudes — never two different DNAs:

- **Marketing amplitude:** acquisition/landing/launch surfaces. Use the expression and motion the brief warrants; cinematic motion, hero-scale type and scroll narrative are optional. Invoke `motion-landing-design` when that treatment is selected, not as a requirement for every marketing screen.
- **App amplitude (instrument scale):** the working product — dashboards, forms, settings, core flows. The DNA turned DOWN — restrained motion, functional density, speed over spectacle. **App surfaces confirm, they never perform.** Motion communicates state; it does not entertain.

**The rule:** marketing and app must read as obviously the same product (same material, type, motion personality, stance, truthfulness) at two different volumes. If a stranger can't tell they're siblings, the DNA failed. If the app feels like a billboard or the landing feels like a settings panel, the amplitude is wrong.

**Required artifact — write `DESIGN.md` at the repo root.** This is the design constitution, in Google's open `design.md` format. Its **prose layer (the `## Design DNA` section)** MUST contain:

1. **DNA name + one-line essence** — what this product feels like in a sentence.
2. **The 5 invariants** — each spelled out concretely (not "modern, clean"; say the actual material, the named fonts, the easing curves, the stance, the truthfulness rules).
3. **The two amplitudes** — marketing (cinematic) vs app (instrument): what changes between them and, critically, what stays identical. Include the "apps confirm, never perform" rule explicitly.
4. **Reference products** (3-5) that share this DNA's spirit — downstream designers and agents use these as evidence, not templates to copy.
5. **Anti-DNA (Do / Don't)** — what this product is NOT, so later steps don't drift toward the generic.
6. **Migration doctrine** — the fixed ordering for applying or evolving the DNA on any surface: **task hierarchy → material → type → states → motion-last.** Establish the task and composition first, then the surfaces and typography, then prove every state (loading/empty/error/success) honors the truthfulness invariant, and add motion ONLY last — motion is the polish layer, never the structure. Re-skins, theme changes, and new surfaces follow this same order. Motion-first is a defect.

`DESIGN.md`'s **YAML token frontmatter** carries the colors, typography families, spacing, and radius as `design.md` tokens (dotted-path references like `{colors.primary}`). `ui-profile.json` is a derived mirror that carries `"designDNA"` (the family archetype) AND `"dnaName"` (the minted name). Step 6 formalizes these decisions as tokens. Use a compatible exporter only after checking its actual availability and interface; otherwise author the token artifact directly and retain decision traceability.

### Reference contract (required in `DESIGN.md`)

Inspect the actual visual reference and its interaction before treating it as direction. In `DESIGN.md`, add a concise `## Reference Contract` with: observed pattern; reference URL or artifact identifier; viewport; observation date; layout density; type hierarchy; surface treatment; chosen components and key behaviors; what to preserve; what to change; and observable acceptance criteria. A list of adjectives or reference-product names alone is not a contract. If a reference cannot be inspected, state that limitation and do not claim its behavior was observed.

---

## Reference-led direction selection (before archetype lock)

Establish direction from the product task, platform, existing brand and inspected references. A working product can preserve its successful design system. Marketing or exploratory work may need a broader creative comparison; do not force award-site patterns onto a desktop workspace.

### Phase E.0 — Reference Research

**Invoke `deep-research` for the reference questions that need investigation.** Inspect a small set of relevant examples, including references the user supplied. Prefer the actual product surface and first-party interaction documentation; inspiration galleries can supplement marketing exploration. Check current behavior when it matters, rather than imposing a publication-year quota.

For each reference, capture:
- The specific layout, hierarchy, density and component behavior relevant to the task
- The observed viewport/states, source URL or artifact identifier, and observation date
- What the product will preserve or adapt, with reasons
- Which interaction details were observed and which remain inferred or inaccessible

Record the evidence in the existing `docs/design/DNA-REFERENCES.md` and summarize its decisions in `DESIGN.md`'s Reference Contract. Do not clone another product's assets or assume its runtime capabilities.

### Phase E.1 — Direction proposal

**Invoke `design-taste` now.** For an established or user-selected direction, propose a concrete adaptation of that direction. When the direction is genuinely open, compare two or three meaningfully different options. Use descriptive names; novelty quotas and invented codenames are not acceptance criteria.

| Field | Content |
| --- | --- |
| Direction | A stable name and a sentence explaining its fit to the user task |
| Hierarchy and density | Main task, supporting navigation, control grouping and content extremes |
| Surfaces and type | Specific surface roles, family or pairing, scale and contrast |
| Components | Compatible primitive/library choices and important interaction behavior |
| Motion | Frequency, purpose, platform constraints and reduced-motion behavior; immediate keyboard actions |
| Preserve/change | Existing brand and workflow constraints, with explicit changes |
| Acceptance | Rendered comparisons and behavioral checks that distinguish success from a superficial restyle |

Use `ux-psychology-pro` where relevant to assess the proposed journey and cognitive load. Familiar navigation and calm chrome can support fast work; do not infer a conflict merely because the product's business goal sounds energetic.

### Phase E.2 — Direction alignment (existing checkpoint)

<HARD-GATE>
Apply the active HITL Gate Contract. Without delegation, obtain the operator's direction decision before finalizing the Design DNA. With explicit unattended delegation, record the selected direction, evidence and assumptions and continue within that authority; do not invent a user answer.
Use AskUserQuestion: "Does this reference-backed direction fit the product and its main task?"
Options: [Approve the proposed direction, Adjust hierarchy or interactions, Compare another direction, Research an unresolved reference]
</HARD-GATE>

Carry the chosen direction into the five invariants and the applicable marketing/app expressions. Archetype labels describe the decision; they must not replace it or silently reset the reference-backed direction.

---

### Design DNA Selection

Reuse the direction already aligned above. If its archetype remains unresolved and checkpoints are not delegated, use AskUserQuestion: "Which Design DNA archetype describes the selected direction?"
Present the archetype table. Options: [Professional/Craft, Gamified/Engaging, Wellbeing/Calming, Aggressive/High-Energy, Delightful/Playful, Premium/Luxury, Other — describe]

**Note:** This archetype selection confirms the *family* for the selected direction from the reference-led comparison above. The named direction already contains the product-specific specifics — the archetype table provides the methodology taxonomy, not the visual identity. If the locked direction does not fit cleanly into any archetype family, use "Other — describe" and document why.

Then document:
- Selected archetype + rationale
- What user emotion it reinforces
- Key reference products (from DNA-REFERENCES.md — real ones, not generic)
- What visual patterns it favors (specific to the locked direction)
- What visual patterns it avoids (from the locked direction's anti-DNA)
- How it affects onboarding, core surfaces, monetization surfaces, trust-heavy screens
- **Product fit:** how this direction makes the primary task clear, preserves the brand, and addresses the inspected reference observations

### shadcn Theme Preset Mapping (when shadcn/ui is in the stack)

If `stack-profile.json` includes `"componentLibrary": "shadcn/ui"`, map the selected DNA archetype to the closest shadcn theme preset:

| DNA Archetype | Recommended Presets |
|--------------|-------------------|
| Professional/Craft | modern-minimal, graphite, mono, vercel, clean-slate |
| Gamified/Engaging | bubblegum, candyland, retro-arcade |
| Wellbeing/Calming | sage-garden, pastel-dreams, nature, ocean-breeze |
| Aggressive/High-Energy | bold-tech, cyberpunk, doom-64 |
| Delightful/Playful | soft-pop, tangerine, kodama-grove |
| Premium/Luxury | elegant-luxury, darkmatter, midnight-bloom, cosmic-night |
| Fintech/Trust | supabase, claude, perpetuity |
| Open/Developer | vercel, mono, clean-slate |

Use AskUserQuestion: "Map to a shadcn theme preset?"
Options: [Use recommended preset, Browse all 42 presets, Custom theme — skip preset, Not using shadcn]

If a preset is selected, use the shadcn MCP `apply_theme` tool to preview it. Record in `ui-profile.json` as `"shadcnPreset": "[preset-id]"`.

### UI Profile (the `## UI Profile` section of DESIGN.md)

Define in `DESIGN.md`'s prose:
- Design DNA archetype + rationale
- Design personality summary + differentiation factor
- Density and spacing direction
- Motion intensity and purpose
- Contrast posture
- Typography direction (families, scale, weight strategy)
- Iconography direction
- Layout behavior (grid, sidebar, single-column, etc.)
- Spatial composition direction (asymmetry, overlap, grid-breaking, or structured grid)
- Component tone (sharp/rounded, bordered/borderless, etc.)
- Background and atmosphere direction (textures, gradients, depth, or clean/flat)
- Platform notes

### Frontend design standards (apply for the selected surface)

**Typography:**
- Derive families, weights and hierarchy from the approved direction, audience and product constraints.
- A distinctive pairing can serve an expressive brief. A familiar or system font can serve an established brand, dense application or platform convention.
- Do not substitute a fashionable font for an approved brand or usability requirement.

**Color and surfaces:**
- Use semantic roles and clear emphasis. Neutral backgrounds and restrained accents are valid for workspaces.
- Use CSS variables or the platform's token mechanism for consistency.
- Borders, backgrounds and elevation should explain relationships; avoid a separate card around every item.

**Motion:**
- Frequent keyboard actions remain immediate; custom transitions need an orientation or feedback purpose.
- Staggered reveals are optional for an expressive marketing brief, never a prerequisite for access to work.
- Respect reduced motion and preserve focus, drafts and scroll intent through updates.

**Spatial composition:**
- Let the task and inspected references determine hierarchy, density and grouping.
- Structured grids, rows and inspectors are valid for workspaces; asymmetry or overlap needs a product-specific reason.
- Adapt to the actual host, supported window sizes and content lengths instead of imposing one universal layout.

**Backgrounds and atmosphere:**
- Flat white, gray or dark surfaces are valid when they support the chosen direction and legibility.
- Textures, gradients and transparencies are optional tools for an appropriate brief, not mandatory decoration.
- Compare the actual render with the Reference Contract before spreading the treatment across screens.

**Anti-slop design rules (canonical):**
- Do NOT default to: centered hero + proof strip + features + pricing + testimonials + CTA — break the pattern genuinely
- Do NOT use radial glows, blurred orbs, gradient text on H1, or frosted glass cards as lazy polish
- Do NOT default devtools to dark+cyan, healthcare to cream+blue, enterprise to "Talk to Sales"
- Do NOT use "Trusted by...", "Get Started", or "Simple honest pricing" as default copy
- Do NOT default pricing to three vertical cards with the middle one featured
- Do NOT hide thin content behind gradients, blur, shadows, and fade-up animation
- Do NOT swap one stock SaaS move for another — every screen must feel like THIS product, not a generic SaaS template
- Use realistic content — real labels, real messages, representative data (no "Lorem ipsum")

**The rule:** Bold maximalism and refined minimalism both work. The key is intentionality, not intensity. Match implementation complexity to the aesthetic vision.

### Portable design brief

`DESIGN.md` must be self-contained for people and agents: include the product context, reference rationale, anti-DNA, and named typography rather than relying on a vendor-specific onboarding flow. `ui-profile.json` remains its machine mirror.

Before the Phase E gate, record a short **design read**: product/page kind, representative audience and task, reference signals, chosen direction, rejected default direction, and why. Taste-informed controls are hypotheses derived from this read; they are not universal benchmarks or a reason to override established brand direction.

### Derived mirror: `docs/design/ui-profile.json`

This JSON is a derived mirror of `DESIGN.md`'s dials, written for Sigma's downstream steps that read JSON. `DESIGN.md` is canonical — if the two disagree, `DESIGN.md` wins and you regenerate this mirror.

```json
{
  "id": "[project-slug]",
  "name": "[Project Name]",
  "version": "1.0",
  "platform": "[web|mobile|both]",
  "designDNA": "[archetype family]",
  "dnaName": "[minted DNA name]",
  "dnaDoc": "DESIGN.md",
  "designContract": "DESIGN.md",
  "amplitudes": { "marketing": "cinematic", "app": "instrument" },
  "shadcnPreset": "[preset-id or null]",
  "dials": {
    "density": "[compact|comfortable|spacious]",
    "motion": "[minimal|moderate|expressive]",
    "contrast": "[standard|high|dark-mode-first]",
    "formality": "[casual|professional|premium]"
  },
  "typography": { "heading": "[family]", "body": "[family]", "mono": "[family]" },
  "layout": { "primary": "[sidebar|tabs|single-column|dashboard]", "responsive": "[mobile-first|desktop-first]" },
  "components": { "corners": "[sharp|rounded|pill]", "borders": "[visible|subtle|none]" },
  "motion": { "intensity": "[none|subtle|moderate|bold]", "purpose": "[feedback|delight|navigation]" },
  "guardrails": ["[list of anti-slop rules from above]"]
}
```

<HARD-GATE>
Do NOT proceed to Phase F until user approves Design DNA + UI Profile.
Use AskUserQuestion: "Design DNA and UI Profile defined. Approve?"
Options: [Approve — write final documents, Change archetype, Adjust UI profile dials]
</HARD-GATE>

---

## Phase F — Output, Hardening & Handoff

### Mandatory: Run $holes

Before final checkpoint, invoke `$holes` to find:
- Weak journeys or missing user contexts
- Shallow accessibility coverage
- Design DNA that contradicts UX goals
- Step 4/6/7 work improperly absorbed into Step 3
- Contradictions with ARCHITECTURE.md or MASTER_PRD
- A missing or adjective-only Reference Contract, or claimed reference interaction without inspection evidence

Fix findings before presenting.

### Lint DESIGN.md (advisory-first design gate)

When the project uses Google's DESIGN.md format, validate with its [documented linter](https://github.com/google-labs-code/design.md). Use the project's installed/pinned version where available:

```bash
npx -y @google/design.md lint DESIGN.md
```

Record the tool version and actual result. Its contrast warning is not a complete accessibility audit. The linter checks token structure, broken token references (`{colors.missing}`), duplicate sections, invalid color/dimension/typography values, and WCAG contrast (component text vs background against AA 4.5:1). Exit 1 = errors. Treat errors as blocking (fix them); treat WCAG warnings as advisory unless the DNA commits to AA. If `npx` cannot reach the registry on this surface, state that and continue — DESIGN.md remains the canonical artifact.

### Emit `.sigma/standards.json`

On Phase F completion (after $holes pass, before writing UX-DESIGN.md), write `.sigma/standards.json`
populated from the locked DNA decisions. This file is the machine-readable DNA context consumed by
`dna_conformance` assertions in `step-verify-gate` for all downstream design steps (4, 5, 6, 7, 9).

```json
{
  "version": 1,
  "awardStandard": true,
  "qualityBar": "95+/100 per step verification schema",
  "dnaName": "<the minted DNA name from Phase E — the two-word codename>",
  "designContract": "DESIGN.md",
  "dnaDoc": "DESIGN.md",
  "uiProfile": "docs/design/ui-profile.json",
  "antiSlopRules": [
    "<an explicit anti-DNA constraint chosen for this product, with a concrete detectable tell>",
    "<another explicit brand, platform or usability constraint when applicable>"
  ],
  "generatedAt": "<ISO 8601 timestamp from `date -u +%Y-%m-%dT%H:%M:%SZ`>"
}
```

**Rules:**
- `dnaName` is the exact codename minted in Phase E (e.g. "Machined Slate"), not the archetype family.
- `dnaDoc` and `designContract` both point at the repo-root `DESIGN.md` (the DNA lives in its prose).
- `antiSlopRules` contains only explicit, project-approved anti-DNA, brand, platform or usability constraints
  from the locked direction. Do not turn general taste preferences into universal prohibitions. Omit it when no
  machine-checkable constraint was approved; unfinished placeholder content is checked separately.
- Write this file even if some fields aren't final yet — downstream gates skip gracefully if the file exists
  but a rule doesn't match. Missing file → advisory skip for all downstream steps.
- Schema reference: `schemas/standards.schema.json`.

### Write `docs/ux/UX-DESIGN.md`

Required sections:
```
Executive UX Summary
Imported Inputs & Assumptions
Experience Goals & Success Signals
UX Drivers & Constraints
Core User Contexts
Journey Model
Information Architecture
Screen Families & Intent
Interaction Principles
State Intent Summary
Accessibility Commitments
Responsive & Platform Strategy
Agentic Interaction Design (if applicable)
Design DNA Summary
UI Profile Summary
Step 4 Handoff — what Step 4 turns into the full screen inventory
Step 6 Handoff — what Step 6 turns into tokens, components, visual system
Step 7 Handoff — what Step 7 formalizes into full state coverage
Do NOT Build in This Step
Open Risks & Deferrals
```

### Writing Standards (embedded)

- No stock AI phrases: "Intuitive", "Seamless", "Delightful" (unless quantified), "User-friendly", "Clean and modern"
- Start with concrete UX decisions, not commentary about UX trends
- Commit to design direction — no "we might explore" hedging
- Write like a UX lead with conviction, not a design blog post
- Every journey traces to a user context and product goal
- State intent is concrete (what happens, not "it should feel nice")

### Success Criteria

- [ ] Experience goals are explicit and traceable
- [ ] Journeys and IA align with architecture constraints
- [ ] Accessibility commitments are concrete (numbers, not aspirations)
- [ ] `docs/design/DNA-REFERENCES.md` records relevant inspected states, sources/dates and observed versus inferred behavior; inaccessible states remain unverified
- [ ] The chosen direction preserves approved constraints; compare 2–3 alternatives only when direction is genuinely open
- [ ] Existing direction checkpoint honored: record the user’s choice or explicitly delegated decision without inventing approval
- [ ] Design DNA is explicit and usable by later steps
- [ ] Named DNA minted in `DESIGN.md` with the 5 invariants, the two amplitudes (cinematic/marketing + instrument/app), and the task hierarchy→surfaces→type→states→motion-last migration doctrine
- [ ] "Apps confirm, never perform" rule stated; marketing and app amplitudes read as the same product at two volumes
- [ ] UI Profile JSON is machine-parseable and carries `dnaName` + `dnaDoc`
- [ ] `DESIGN.md` contains a concise Reference Contract with observed visual and interaction evidence, preserve/change decisions, and observable acceptance criteria
- [ ] Design guardrails record the approved direction and any explicit anti-DNA constraints
- [ ] Agentic patterns mapped (if applicable)
- [ ] Step 4, 6, 7 handoffs explicit
- [ ] No Step 4/6/7 scope absorbed
- [ ] $holes pass completed
- [ ] User approved
- [ ] Linear journey issues created (when configured)

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 4 without explicit approval.
Use AskUserQuestion: "Step 3 complete. Ready for Step 4 — Flow Tree?"
Options: [Proceed to Step 4, Revise UX design, Adjust Design DNA]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 3 Verification Schema

### Required Outputs (30 points)

| Item | Path | Points |
|------|------|--------|
| UX Document | docs/ux/UX-DESIGN.md | 12 |
| Canonical design contract (DNA in prose) | DESIGN.md | 12 |
| UI Profile JSON (derived mirror) | docs/design/ui-profile.json | 6 |

### Required Sections (36 points)

| Section | Points |
|---------|--------|
| Experience Goals & Success Signals | 5 |
| Journey Model | 5 |
| Information Architecture | 5 |
| Design DNA Summary | 4 |
| Interaction Principles | 4 |
| Accessibility Commitments (concrete) | 5 |
| UI Profile Summary | 4 |
| Step 4 Handoff | 2 |
| Step 6 Handoff | 1 |
| Step 7 Handoff | 1 |

### Quality Indicators (24 points)

| Check | Points |
|-------|--------|
| Goals tied to user value and product decisions | 4 |
| IA and journeys align with architecture constraints | 4 |
| Accessibility commitments state applicable target dimensions and contrast thresholds | 4 |
| Named DNA minted with 5 invariants + two amplitudes + migration doctrine | 4 |
| Relevant reference evidence and concrete Reference Contract recorded; direction preserves approved constraints; existing checkpoint or explicit delegation honored | 6 |
| Approved design guardrails and explicit anti-DNA constraints are recorded where applicable | 2 |

### Boundary Integrity (10 points)

| Check | Points |
|-------|--------|
| No Step 4 scope absorbed | 4 |
| No Step 6/7 scope absorbed | 4 |
| $holes pass completed | 2 |
| Linear journey issues created (when configured) | 1 |

**Passing score:** 95/100

## Reference evidence and output checks

The hook checks artifact presence and the Reference Contract heading. Reviewers must still verify the observations and decisions; these deterministic checks do not establish design quality.
<VERIFY-ASSERT>
file_exists DESIGN.md
craft_antislop DESIGN.md
file_exists docs/design/DNA-REFERENCES.md
section_has DESIGN.md Reference Contract
</VERIFY-ASSERT>
</verification>

$END$
