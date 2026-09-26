---
version: "1.1.0"
last_updated: "2026-09-19"
description: "Step 0: Sigma Bootloader — detect project mode, validate runtime + research stack, create minimal baseline, persist state"
allowed-tools:
  - Read
  - Write
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
parameters:
  - --runtime
  - --mode
  - --skip-validation
  - --reduced-research
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

- `sigma-protocol-guide` — all phases (methodology contract, artifact paths)
- `expo` — Phase C.1 when platform is mobile / Expo
- `rn-component-library` — Phase C.1 mobile scaffold (Reusables + Bklit reference)
- `shadcn` — Phase C.1 web/desktop scaffold
- `react-native-patterns` — Phase C.1 mobile navigation, lists, performance
- `mobile-app-security` — Phase C.1 mobile (MASVS baseline)
- `platform-design-guidelines` — Phase C.1 platform UX baseline (mobile + web)
- `mobile-ui-testing` — Phase C.1 mobile simulator smoke
- `frontend-design` — Phase C.1 web/desktop UI baseline
- `react` — Phase C.1 web scaffold
- `tauri-patterns` — Phase C.1 Tauri desktop scaffold
- `electron` — Phase C.1 Electron desktop scaffold

- `shadcn` — curated preflight (web/desktop React)
- `rn-component-library` — curated preflight (mobile Expo)
- `react-native-patterns` — curated preflight (mobile Expo)
- `companion-system` — curated preflight (gamification / collectibles)

Also read (not skills): `docs/references/CURATED-COMPONENT-LIBRARIES.md`, `templates/boilerplates/catalog.json`, `docs/references/integration-packs-catalog.md` when mode is `custom-project` or greenfield.

If a skill is unavailable on this surface, state that and continue; never silently skip it.
<!-- SKILLS-INVOKE:end -->


# /step-0-environment-setup — Sigma Bootloader

**On start, announce:** "Running Step 0: Environment Bootloader. I'll walk you through 5 phases with approval gates before Step 1 can begin."

<goal>
You are the Sigma Bootloader Engineer. Execute ALL phases (A through E) in order.
Do NOT skip any phase. Do NOT combine phases.
Each phase ends with a HARD-GATE — halt, present results, and use AskUserQuestion for approval before proceeding.

| Phase | Purpose | Output |
|-------|---------|--------|
| A | Detect project mode + validate runtime | Mode + runtime status |
| B | Validate research stack | `full` / `reduced` / `blocked` research mode |
| C | Validate stack integrations | Integration findings |
| D | Create minimal baseline | Shared directories |
| E | Persist state | `docs/ops/ENVIRONMENT-SETUP.md` + `.sigma/runtime-baseline.json` |

Quality gate: 95+/100 on verification schema. Step 1 blocked until pass.
</goal>

---

## Phase A — Mode Detection & Runtime Health

**Goal:** Detect the consuming-project mode, select the active runtime, and record a baseline before any scaffold, install, or repair action.

### Preflight (auto, no user interaction)

1. Run `date +"%Y-%m-%d"` for timestamps.
2. Detect repo root.
3. Load existing `docs/ops/ENVIRONMENT-SETUP.md` and `.sigma/runtime-baseline.json` if present.
4. Check for: `.sigma/boilerplate.json`, `docs/stack-profile.json`, `.claude/`, `.codex/`, `docs/ops/CODEBASE-MAP.md`.
5. Detect OS and shell.
6. Record a project baseline before any mutation: repository root, branch/HEAD, dirty-state summary, applicable instruction files, existing generated artifacts, package manager, lockfile, and runtime versions. Record the command, timestamp, and result for each observed value; mark unavailable values `unknown` rather than inferring them from directory names.

### Mode detection (pick exactly one)

**`protocol-dev`** — The Sigma authoring repo itself.
Requires ALL of: `steps/` + `templates/steps/` + at least one of `packages/sigma-protocol-core/` or `src/module.yaml`.
Do not infer from generic folders like `ops/` or `dev/`.

**`boilerplate-project`** — `.sigma/boilerplate.json` exists and this is NOT the Sigma authoring repo.
Boilerplate metadata is source of truth for stack integrations.

**`custom-project`** — Neither condition above. Record the predicate that selected this mode.
If the repo has meaningful code but no codebase map, recommend `sigma map-codebase` before deeper planning.

### Agent runtime validation (platform-agnostic)

Sigma does not require a specific vendor CLI. Validate the **canonical surfaces** this repo ships:

1. `steps/` exists with Step 0–15 sources
2. `bash scripts/sync-steps-to-platforms.sh --dry-run` succeeds (partials resolve)
3. `src/skills/` is readable (methodology skills available)
4. `node scripts/verify/validate-step-wiring.mjs` passes (or record failures to fix)

Optional operator-local CLI config (`.claude/`, `.codex/`, etc.) may exist — note presence in `ENVIRONMENT-SETUP.md` but **do not block** on a specific vendor.

Record in `.sigma/runtime-baseline.json`:
```json
"runtime_selection": "platform-agnostic",
"commands_surface": "commands/",
"skills_surface": "src/skills/"
```

Produce a runtime status summary: canonical surfaces health, research mode, pass/warn/fail, action needed, and baseline evidence. A healthy Sigma renderer does not prove a consuming project's runtime is healthy.

**Blocking:** If canonical steps/skills/validators fail, Step 1 is blocked until fixed.

<HARD-GATE>
Do NOT proceed to Phase B until user approves.
Use AskUserQuestion: "Mode detection and runtime health complete. Approve?"
Options: [Approve — proceed to research stack, Revise — something needs fixing]
</HARD-GATE>

---

## Phase B — Research Stack

**Goal:** Classify research capability as `full`, `reduced`, or `blocked`.

### Research mode rules

| Mode | Requirements |
|------|-------------|
| `full` | A path exists to verify decision-relevant claims with official docs, owner repositories, standards, or research |
| `reduced` | At least one research path exists, but missing source classes and held claims are recorded |
| `blocked` | No viable research path — Step 1 blocked |

### Provider priority

- **Web research:** Use the agent's built-in **web search** (or equivalent). Do not require Exa, Firecrawl, or paid MCP search APIs.
- **Documentation:** Library docs via web search or official doc URLs.
- **Code context:** Read repo files directly; use web search for API patterns when needed.

For every downstream framework claim, record source class, URL, verification date, version/ref when available, and confidence. Treat search results and practitioner material as leads until verified with an authoritative source.

### Design & component tools (detect availability)

Check and record these in `runtime-baseline.json` under `design_tools`:
- **shadcn CLI** — `npx shadcn@latest` on PATH or documented install path. Enables block scaffolding in Steps 5–9.
- **`clone` / reference extraction** — optional skill if present in the operator's global skill pack. Enables reference-driven wireframes in Step 5.
- **Pen, Taste, Designscape, and host-native preview/rendering** — optional adapters only when a local capability probe succeeds. Record the owner source and supported capability; do not name a canonical renderer.

These are development tools, not stack decisions.

**Wireframe generation:** Step 5 generates wireframes as self-contained HTML or native scaffolds directly — no external SDK required.

### Output / token optimizer (optional)

A CLI-output optimizer compresses verbose command output before it enters the AI context window. Optional and tool-agnostic.

If one is configured, record it in `runtime-baseline.json` under `token_optimizer: { configured: true/false, tool: "<name-or-none>" }`.

### Research capability summary

Produce a tool summary: category, available capability, configured status, action needed. **Do not block** on missing Exa/Firecrawl.

<HARD-GATE>
Do NOT proceed to Phase C until user approves.
Use AskUserQuestion: "Research stack validated. Approve research mode?"
Options: [Approve — proceed to stack integrations, Continue in reduced mode, Block — no research path]
</HARD-GATE>

---

## Phase B.2 — Cross-Model Fusion Providers (optional)

**Goal:** Decide which model "voices" the cross-model `fusion` primitive may use (panel → synthesizer) and record the choice. Fusion powers the C2 panel-judge, gap-analysis verdicts, and divergence synthesis. OPTIONAL — skip if this project will not use cross-model fusion.

**CLI-first — no keys required.** A voice is available if its CLI is on PATH (reached through that CLI's own auth) OR its API key env var is set. Installed CLIs (`claude`, `codex`, `gitnexus`) work with zero keys. OpenRouter / MiniMax / GLM keys are opt-in EXTRA voices.

### Detect what is available

```bash
node scripts/fusion/detect-providers.mjs --json
```

Lists available voices `{id, family, via, cost_tier}` and caches them to `.sigma/providers.json`. Present the table to the user.

### Choose (AskUserQuestion — skip entirely if the user opts out of fusion)

1. **Which voices to enable?** Default: all detected CLI voices. A cross-family panel (≥2 families) is the default — it is the self-preference-bias mitigation.
2. **Add any API-key voices?** OpenRouter / MiniMax / GLM. If yes, the user stores the key in their LOCAL env (never a committed file); only the env-var NAME is recorded.
3. **Which synthesizer?** Default: `claude`. The synthesizer is ~75% of fusion's quality lift; ideally a different family from the bulk implementer.

### Persist (env-var NAMES only — never keys)

```bash
node scripts/fusion/setup-providers.mjs --enable <ids> --synthesizer <id> [--api-keys <ids>]
```

Writes `.sigma/providers.config.json` (gitignored, per-machine): enabled voices, synthesizer, and which API-key ENV-VAR NAMES to expect — never a secret value (SECURITY.md). The script REFUSES any input that is not a known provider id, so a key cannot be stored even by accident. `fusion.mjs` reads this file to scope its panel and pick the synthesizer.

<HARD-GATE>
Do NOT proceed to Phase C until the user approves (or explicitly skips fusion).
Use AskUserQuestion: "Cross-model fusion providers configured. Approve?"
Options: [Approve — proceed, Skip fusion for this project, Add an API key first]
</HARD-GATE>

---

## Phase C — Stack Integrations

**Goal:** Validate stack integrations implied by the project. Do not ask about stacks the project doesn't use.

### If `boilerplate-project`

Read `.sigma/boilerplate.json` then `docs/stack-profile.json`. Read `docs/references/integration-packs-catalog.md` for module/integration summaries. Treat boilerplate metadata as a proposal to verify against manifests, lockfiles, deployment configuration, environment names, and imports. Do NOT ask generic questions the boilerplate already answers.

Known mappings:
- `nextjs-saas` → Supabase, Stripe, Vercel
- `nextjs-ai` → Convex
- `expo-mobile` → Supabase, RevenueCat, Expo
- `nextjs-portable` → Drizzle/Postgres
- `tanstack-saas` → Supabase

### If `custom-project`

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

When greenfield (no root package manifest), recommend `@new-project` using the catalog-ranked template before Step 2. Read `docs/references/CURATED-COMPONENT-LIBRARIES.md` and seed `docs/stack-profile.json` with platform + `componentLibrary` hints.

### If `custom-project` (integrations)

Use `docs/stack-profile.json` if it exists. Else scan for obvious markers: `supabase/`, `convex/`, `docker-compose.yml`, `vercel.json`, Expo config. If stack is unclear, defer to Step 2.

Stack integrations are recommended, not blocking, unless the project clearly depends on them for basic operation. Mark each as `configured`, `present-but-unused`, `planned`, or `unknown`; do not install a dependency during detection.

<HARD-GATE>
Do NOT proceed to Phase D until user approves.
Use AskUserQuestion: "Stack integration review complete. Approve?"
Options: [Approve — create baseline directories, Revise — need to add/remove integrations]
</HARD-GATE>

### Linear Detection (2026-07-11 — Linear replaced the SigmaHQ kanban)

Linear is configured when BOTH hold:
- `security find-generic-password -s LINEAR_API_KEY -w` returns a key (GraphQL endpoint `https://api.linear.app/graphql`, header `Authorization: <key>`, no Bearer prefix)
- the operator names the Linear project this repo maps to (each repo maps to exactly one Linear project; team is derived from the project)

Detection logic:
1. Run the Keychain lookup. If it returns a key, ask the user which Linear project this repo maps to (or reuse an existing `linear.project` from a prior baseline)
2. Record the result in `runtime-baseline.json` under `linear` (`{ "configured": true, "project": "<name>" }`)
3. If the key is missing, record `linear.configured: false` — steps will use file-based status tracking only

This is detection only — no issues are created. Steps 1-15 use this to decide whether to mirror progress to Linear.

Track tasks in Linear when it's configured, otherwise as wave-labeled GitHub Issues in the project repo. Never write task tracking to the retired SigmaHQ kanban (`~/.commandboard`, frozen 2026-07-11) — that board is dead for everyone. GitHub always owns the PR/branch/review/merge loop; when Linear is connected its issues two-way-sync once the operator enables per-repo issue sync in the GitHub<->Linear integration (PR-linkback only today).

### Linear Operations Reference (for downstream steps)

When Linear is configured, these patterns apply to all Linear operations in Steps 1-15:

**Reading the key + project:**
```bash
LINEAR_API_KEY=$(security find-generic-password -s LINEAR_API_KEY -w)
linear_project=$(jq -r '.linear.project' .sigma/runtime-baseline.json)
```

**GraphQL call shape (all reads and writes):**
```bash
curl -s https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"query": "<query-or-mutation>", "variables": { ... }}'
```

**Discovering issues (filter by project + label + state):**
```graphql
query { issues(filter: {
  project: { name: { eq: "<linear.project>" } },
  labels: { name: { eq: "flow-card" } },
  state: { name: { eq: "Todo" } }
}) { nodes { id identifier title state { name } labels { nodes { name } } } } }
```
Swap the label filter for `feature`, `eng-task`, or `exec-task` to find the other issue types.

**Creating issues (capture `id` + `identifier` from the response):**
```graphql
mutation { issueCreate(input: {
  teamId: "<team-id>", projectId: "<project-id>",
  title: "...", description: "...",
  labelIds: ["<wave-label-id>", "<type-label-id>"]
}) { success issue { id identifier url } } }
```

**Updating issues (status moves, label changes):**
```graphql
mutation { issueUpdate(id: "<issue-id>", input: { stateId: "<state-id>" }) { success } }
```

**Label conventions (a `wave:W*` label is MANDATORY on every created issue — an unlabeled issue is a defect):**
- Every issue: a `wave:W<n>` label — `wave:W0` for planning/status issues (Steps 0-10, Run Track), the build-sequence wave (`wave:W1`, `wave:W2`, ...) for execution issues
- Step 4 flow issues: `flow-card`
- Step 10 feature issues: `feature`, `prd-eligible`
- Step 11 engineering issues: `eng-task`
- Step 11.5 execution tasks: `exec-task`
- Work sitting at a review gate: `needs-verification`

**Error handling:** If any Linear call fails, log the error and continue with file-based tracking. Do not block the step's primary work on Linear sync failures.

---

---

## Phase C.1 — Platform Scaffold & Dependency Install (NEW PROJECT ONLY)

Scaffold here only when the project already has an explicit, approved stack choice. If product needs or architecture are still unsettled, prepare the workspace and defer framework installation to Step 2. A provisional starter is not architecture approval; do not silently make Next.js or any agent framework mandatory.

**Goal:** For a confirmed new project, prepare a reviewed base platform scaffold before feature work. Preserve an existing manifest, lockfile, and chosen stack; skip for existing projects unless the owner authorizes an integration change.

**When to run:** Execute Phase C.1 immediately after Phase C approval when BOTH of these conditions hold:
1. No `package.json`, `Cargo.toml`, `pubspec.yaml`, or equivalent manifest exists at the repo root.
2. The project is NOT `protocol-dev` mode.

Before proposing any command, detect the package manager and lockfile, resolve exact requested versions, check the chosen framework's current official compatibility matrix, and show the expected manifest/lockfile diff. Record separately: `PREPARED` (commands and diff reviewed), `EXECUTED` (install ran), and `SMOKE_TESTED` (the recorded check passed). If compatibility cannot be verified, remain `PREPARED`.

**Platform detection order:**
1. Read `docs/stack-profile.json` → use `platform` field if present.
2. Read `.sigma/boilerplate.json` → derive platform from boilerplate type.
3. If neither exists → ask (see Decision: Platform below).

### Decision: Platform (when not yet in stack-profile.json)

<HARD-GATE>
Use AskUserQuestion: "What is the target platform for this project?"
Options: [Mobile — Expo / React Native, Web — Next.js, Desktop — Tauri (Rust backend), Desktop — Electron (Node backend), Cross-platform — Expo (mobile) + Next.js (web), Defer scaffold — existing project or architecture choice still open]
</HARD-GATE>

When a platform is selected, record it in `docs/stack-profile.json` under `"platform"`. If deferred, leave the platform unset and record the open decision and deferral reason in ENVIRONMENT-SETUP.md; do not invent a platform value.

---

### MOBILE — Expo / React Native scaffold

**Invoke skills:** `react-native-patterns`, `rn-component-library`, `mobile-app-security`, `platform-design-guidelines`, `mobile-ui-testing`, `expo`

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

**Step 1 — Create the Expo app (run once, in the repo root or a named subdirectory):**

```bash
# New architecture is the default as of Expo SDK 53+.
npx create-expo-app@latest . --template blank-typescript
# If the project lives in a subdirectory:
# npx create-expo-app@latest my-app --template blank-typescript && cd my-app
```

**Step 2 — Install required platform libraries:**

```bash
npx expo install \
  nativewind \
  tailwindcss \
  react-native-reanimated \
  react-native-gesture-handler \
  react-native-safe-area-context \
  react-native-screens \
  expo-router \
  @shopify/flash-list \
  expo-image \
  react-native-mmkv \
  expo-secure-store \
  @react-native-async-storage/async-storage
```

**Step 3 — Install React Native Reusables (shadcn for RN):**

React Native Reusables (`@rn-primitives/`) is the component library standard for NativeWind-based apps — the mobile equivalent of shadcn/ui. Copy-paste components give full ownership.

```bash
# Initialize rn-reusables in the project
npx @react-native-reusables/cli@latest init

# Add the components this project needs (add per PRD, not all at once):
# npx @react-native-reusables/cli@latest add button
# npx @react-native-reusables/cli@latest add card
# npx @react-native-reusables/cli@latest add input
# npx @react-native-reusables/cli@latest add dialog
# npx @react-native-reusables/cli@latest add sheet
```

**Step 4 — Configure NativeWind v4:**

`babel.config.js`:
```js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ['babel-preset-expo', { jsxImportSource: 'nativewind' }],
      'nativewind/babel',   // NativeWind is a PRESET, not a plugin
    ],
  };
};
```

`metro.config.js`:
```js
const { getDefaultConfig } = require('expo/metro-config');
const { withNativeWind } = require('nativewind/metro');

const config = getDefaultConfig(__dirname);
module.exports = withNativeWind(config, { input: './global.css' });
```

`global.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

`tailwind.config.js`:
```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  presets: [require('nativewind/preset')],
  theme: { extend: {} },
  plugins: [],
};
```

**Step 5 — Configure Expo Router file layout:**

```
app/
  _layout.tsx       ← root layout with SafeAreaProvider + gesture handler
  index.tsx         ← home route
  (tabs)/
    _layout.tsx     ← tab navigator
components/
  ui/               ← rn-reusables components live here
lib/
  utils.ts          ← cn() helper from rn-reusables init
assets/
global.css
```

**Step 6 — Record in `docs/stack-profile.json`:**

```json
{
  "platform": "mobile",
  "framework": "expo",
  "navigation": "expo-router",
  "styling": "nativewind@4",
  "componentLibrary": "react-native-reusables",
  "animation": "react-native-reanimated",
  "list": "@shopify/flash-list",
  "storage": "react-native-mmkv",
  "secureStorage": "expo-secure-store",
  "imageComponent": "expo-image",
  "architecture": "new-arch"
}
```

**Install verification:**

```bash
npx expo-doctor         # all checks must pass
npx tsc --noEmit        # type-check clean
```

---

### WEB — Next.js scaffold

**Invoke skills:** `frontend-design`, `shadcn`, `react`

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

**Step 1 — Create the Next.js app:**

```bash
npx create-next-app@latest . \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*"
```

**Step 2 — Install Tailwind v4 + shadcn/ui + Motion:**

```bash
# Tailwind v4 (if not already using the Next.js template's v4)
npm install tailwindcss@^4 @tailwindcss/vite

# shadcn/ui
npx shadcn@latest init

# Motion (Framer Motion successor — same API, lighter bundle)
npm install motion
```

**Step 3 — Initialize shadcn component library:**

```bash
# Add components as PRDs are written — do not add all at once.
# Core set for most projects:
npx shadcn@latest add button card input dialog sheet toast
```

**Step 4 — Record in `docs/stack-profile.json`:**

```json
{
  "platform": "web",
  "framework": "nextjs",
  "styling": "tailwind@4",
  "componentLibrary": "shadcn/ui",
  "motion": "motion"
}
```

---

### DESKTOP — Tauri scaffold

**Invoke skills:** `tauri-patterns`

**Step 1 — Scaffold the Tauri app (Vite + React frontend):**

```bash
npm create tauri-app@latest . -- --template react-ts
cd src-tauri
# Review tauri.conf.json — set identifier and productName
```

**Step 2 — Install Tauri plugins as needed:**

```bash
# Add plugins after Step 8 defines what the app needs:
npm install @tauri-apps/plugin-fs @tauri-apps/plugin-shell @tauri-apps/plugin-updater
cargo add tauri-plugin-fs tauri-plugin-shell tauri-plugin-updater
```

**Step 3 — Record in `docs/stack-profile.json`:**

```json
{
  "platform": "desktop",
  "framework": "tauri",
  "backendLanguage": "rust",
  "frontendFramework": "react-ts",
  "ipcPattern": "typed-command-wrappers"
}
```

---

### DESKTOP — Electron scaffold

**Invoke skills:** `electron`

**Step 1 — Scaffold the Electron app:**

```bash
# Recommended: electron-vite (includes React, TypeScript, contextIsolation on by default)
npm create @quick-start/electron@latest . -- --template react-ts
```

**Step 2 — Verify security baseline (non-negotiable):**

Confirm these are set in the generated `BrowserWindow` options — fix immediately if not:
```js
new BrowserWindow({
  webPreferences: {
    contextIsolation: true,   // MUST be true
    nodeIntegration: false,   // MUST be false
    sandbox: true,
    preload: path.join(__dirname, 'preload.js'),
  },
})
```

**Step 3 — Record in `docs/stack-profile.json`:**

```json
{
  "platform": "desktop",
  "framework": "electron",
  "frontendFramework": "react-ts",
  "ipcPattern": "contextBridge-typed-wrappers"
}
```

---

### CROSS-PLATFORM — Expo + Next.js monorepo

For projects that ship both a mobile app and a web app from the same repo:

```bash
# Use a pnpm workspace (recommended) or Turborepo template:
npx create-turbo@latest . --example with-expo-next-app
```

Follow both the MOBILE scaffold (under `apps/mobile/`) and the WEB scaffold (under `apps/web/`) from above. Share components via a `packages/ui/` workspace package.

---

### Phase C.1 output: update `docs/ops/ENVIRONMENT-SETUP.md`

Add a **Platform Scaffold** section:

```
## Platform Scaffold

Platform: [mobile | web | desktop-tauri | desktop-electron | cross-platform]
Scaffolded at: [ISO 8601 timestamp recorded during Phase A]
Framework: [expo | nextjs | tauri | electron]
Component library: [react-native-reusables | shadcn/ui | n/a]
Key packages installed: [list from the chosen scaffold above]
stack-profile.json: updated
Verification: expo-doctor / tsc --noEmit — [PASS | FAIL | SKIPPED (existing project)]
```

<HARD-GATE>
Do NOT proceed to Phase D until user approves scaffold.
Use AskUserQuestion: "Platform scaffold complete. All installs verified. Approve?"
Options: [Approve — create baseline directories, Fix install errors first, Skip/defer — no scaffold is needed yet; record why]
</HARD-GATE>

---

### Shared memory layer (optional, vendor-neutral)

A shared, cross-project memory layer makes agents better over time: knowledge distilled in one session is available in the next instead of being re-derived. Sigma supports one if you have one, but **does not require or install any specific product.** Detect what the operator already uses and wire to it; never assume a particular tool.

**Doctrine — single source, no per-project forks.** If a shared memory layer is in use, ALL projects and sessions read/write the same store. Never create a second store per project. Project-scoped knowledge lives in the project's `.sigma/memory/project/` (tracked in git, plain markdown); the shared layer aggregates and distills from there. This holds regardless of which tool backs the shared layer.

**What can back it (any one, or none):**
- A markdown knowledge vault (e.g. Obsidian, Logseq, or a plain notes directory) — the lowest-friction, fully portable option.
- A retrieval/memory service the operator already runs.
- Nothing — `.sigma/memory/project/` alone is a valid baseline. Steps 12 and 14 build the project-local memory bridge either way.

**Detection (do not install anything without approval):**
1. Check whether the operator has a shared memory/knowledge tool already configured (ask, or detect a known config). If none, default to "markdown vault or none" — do not block.
2. If a tool exists, point it at this project's `.sigma/memory/project/` so that directory is included on the next sync/compile cycle.
3. Record the result in `runtime-baseline.json` under `"memory_layer"`:

```json
{
  "memory_layer": {
    "configured": false,
    "backend": "none",
    "project_bridge": ".sigma/memory/project/"
  }
}
```

Set `"backend"` to a neutral label (`"markdown-vault"`, `"memory-service"`, or `"none"`); do not hardcode a product name. If a tool is genuinely useful and missing, recommend it in `ENVIRONMENT-SETUP.md` and install only after user approval — never write keys into committed files.

**What the shared memory layer is NOT:**
- Not a per-project second store. One store serves all projects.
- Not a replacement for `docs/` or `.sigma/memory/` — those are project-scoped files it consumes.
- Not a secret store. Secrets go in `.env` or a vault. The memory layer holds committed-safe context only.

---

## Phase D — Minimal Baseline

**Goal:** Create only the shared directories that Step 0 owns. Nothing else.

### Create if missing

- `docs/ops/`, `docs/prds/`, `docs/analysis/`
- `.sigma/backlogs/prototype/`, `.sigma/backlogs/implementation/`
- `.sigma/orchestration/`

### Create CONTEXT.md from template
If `CONTEXT.md` does not exist at the project root:
1. Copy from `docs/templates/CONTEXT.md` (in the Sigma Protocol repo) or use the embedded template structure
2. Fill in the Project Metadata section with detected values (project name, runtime, current date)
3. Leave the Decision Log, Assumptions, and Open Questions sections empty — downstream steps populate them

This file is the project's living decision log. Agents update it as they make architectural and integration decisions throughout Steps 1-13.

### Do NOT create

- Downstream docs subdirectories
- Protocol authoring surfaces in normal app projects
- Step-specific outputs (those belong to later steps)
- Step 12/14 runtime surfaces (`.sigma/tools/`, `.sigma/runtime/`, etc.)

If `protocol-dev` mode: validate protocol authoring surfaces exist, but do not create or rewrite them.

<HARD-GATE>
Do NOT proceed to Phase E until user approves.
Use AskUserQuestion: "Baseline directories created. Approve?"
Options: [Approve — persist state files, Revise — adjust baseline]
</HARD-GATE>

---

## Phase E — Persist State

**Goal:** Write durable human + machine state before Step 1.

### Write `docs/ops/ENVIRONMENT-SETUP.md`

Required sections: Step 0 Mode, Project Baseline Evidence, Runtime Selection & Health, Research Mode and Source Quality, Stack Integration Recommendations, Minimal Baseline Status, Install/Repair Actions, Blocking Issues, Next Steps.

### Write `.sigma/runtime-baseline.json`

```json
{
  "$schema": "https://sigma-protocol.dev/schemas/runtime-baseline.schema.json",
  "mode": "custom-project",
  "runtime_selection": "platform-agnostic",
  "runtime_status": { "selected": ["commands-surface"], "healthy": true },
  "research_mode": "full",
  "baseline_evidence": { "observed_at": "<execution-time ISO-8601 timestamp>", "repository": { "command": "git rev-parse --show-toplevel", "result": "<path-or-unknown>" }, "git": { "branch_head": "<command and result-or-unknown>", "dirty_state": "<command and result-or-unknown>" }, "runtime": { "command": "<command>", "result": "<result-or-unknown>" } },
  "research_tools": { "web_research": { "method": "builtin_web_search" }, "documentation_lookup": {}, "code_context_lookup": { "method": "repo_read" }, "source_quality": [] },
  "design_tools": { "shadcn_cli": false, "clone_skill": false },
  "memory_layer": { "configured": false, "backend": "none", "project_bridge": ".sigma/memory/project/" },
  "token_optimizer": { "configured": false, "tool": "none" },
  "linear": { "configured": false, "project": null },
  "boilerplate": null,
  "stack_integrations": [],
  "blocking_issues": [],
  "generated_at": "<execution-time ISO-8601 timestamp>",
  "status": "VERIFIED | WARN | PREPARED | BLOCKED"
}
```

### Write `.sigma/providers.config.json` (only if Phase B.2 ran)

If cross-model fusion was configured, `setup-providers.mjs` already wrote this file (enabled voices + synthesizer + API-key env-var NAMES, never values). If fusion was skipped, omit it. When present, add a short `## Cross-Model Providers` section to `ENVIRONMENT-SETUP.md` listing the enabled voices, the synthesizer, and which key env-vars are expected (NAMES only) so a teammate on another machine knows what to install or set.

### Writing Standards (embedded — apply to ENVIRONMENT-SETUP.md)

- No stock AI phrases: "Let's dive in", "Here's the thing", "In today's landscape", "At its core", "Robust", "Seamless", "Leverage", "Delve"
- Start with facts, not sweeping statements about the state of the industry
- Commit to findings or flag as uncertain — no "might/could potentially" hedging on every line
- No breathless enthusiasm — a runtime check is not "fascinating" or "transformative"
- No "Final thoughts" or "Key takeaways" headers
- Write like a concise engineering report, not a blog post

### Step 1 gate

Step 1 can proceed only when: selected runtime(s) healthy or accepted with warnings, research mode is not `blocked`, minimal baseline exists, blocking issues documented.

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 1 without explicit approval.
Use AskUserQuestion: "Step 0 complete. Ready for Step 1?"
Options: [Proceed to Step 1 — Ideation, Fix issues first, Review reports]
</HARD-GATE>

---

Before presenting the final human approval checkpoint, run `@step-verify --step=N` (replace N with this step's number). Use the current step's verification schema and pass threshold; when it defines none, scores below 80 are blockers. Fix gaps and re-run until that threshold passes or the user explicitly waives with recorded rationale.

<verification>
## Step 0 Verification Schema

### Required Files (30 points)

| File | Path | Min Size | Points |
|------|------|----------|--------|
| Environment Report | docs/ops/ENVIRONMENT-SETUP.md | 1KB | 10 |
| Runtime Baseline | .sigma/runtime-baseline.json | 200B | 10 |
| Ops Directory | docs/ops/ | exists | 2 |
| PRD Directory | docs/prds/ | exists | 2 |
| Analysis Directory | docs/analysis/ | exists | 2 |
| Prototype Backlog Dir | .sigma/backlogs/prototype/ | exists | 1 |
| Implementation Backlog Dir | .sigma/backlogs/implementation/ | exists | 1 |
| Orchestration Dir | .sigma/orchestration/ | exists | 1 |
| Decision Log | CONTEXT.md | exists | 1 |

### Required Sections (25 points)

| Section | Must Exist In | Points |
|---------|---------------|--------|
| Step 0 Mode | ENVIRONMENT-SETUP.md | 3 |
| Runtime Selection & Health | ENVIRONMENT-SETUP.md | 4 |
| Research Mode | ENVIRONMENT-SETUP.md | 4 |
| Stack Integration Recommendations | ENVIRONMENT-SETUP.md | 4 |
| Minimal Baseline Status | ENVIRONMENT-SETUP.md | 3 |
| Install / Repair Actions | ENVIRONMENT-SETUP.md | 3 |
| Blocking Issues | ENVIRONMENT-SETUP.md | 2 |
| Next Steps | ENVIRONMENT-SETUP.md | 2 |

### Runtime & Research Contract (25 points)

| Check | Points |
|-------|--------|
| Runtime selection recorded in baseline JSON | 5 |
| Research mode recorded in baseline JSON | 5 |
| Step 0 mode recorded in baseline JSON | 5 |
| Web search documented in ENVIRONMENT-SETUP.md | 4 |
| Integration findings recorded or deferred explicitly | 4 |
| Linear detection recorded in baseline JSON | 2 |

### Mode-Specific Quality (20 points)

| Check | Points |
|-------|--------|
| Valid mode in baseline JSON (`protocol-dev` / `boilerplate-project` / `custom-project`) | 5 |
| Valid runtime in baseline JSON (`platform-agnostic` + healthy `commands/` surface) | 5 |
| Valid research mode in baseline JSON (`full` / `reduced` / `blocked`) | 4 |
| Web search capability recorded in baseline JSON | 4 |
| Linear project recorded when configured | 2 |

### Pass Threshold
95/100 minimum. Any `blocked` research mode or missing selected runtime is a hard blocker regardless of score.
</verification>

$END$
