# Foundation Skills Reference

**Version:** 1.0.0-alpha.1
**Last Updated:** 2026-02-04

Sigma Protocol includes **230+ skills total** (Foundation + External) in the bundled OSS skill pool. The live catalog is `.sigma/indexes/skills-index.json`.

> **Note:** In addition to Foundation Skills, Sigma Protocol includes **120+ External Skills** from the skills.sh ecosystem. See [EXTERNAL-SKILLS.md](./EXTERNAL-SKILLS.md) for the complete external skills reference.

---

## Overview

Foundation Skills are part of Sigma's reusable baseline capability layer. They are **universal** and **project-agnostic**. Step 13 then adds project-authored skill bundles on top of that baseline.

**External Skills** (Tier 2) provide domain-specific expertise for security, mobile development, 3D graphics, marketing, and more.

**Step 13** (Skillpack Generator) creates **project-specific overlays** that build on these skills with your project's:

- Design system and tokens
- Stack choices and patterns
- PRD context and requirements
- Custom conventions

---

## Platform Installation

Sigma ships skills on a single OSS surface. Import from these paths into your agent CLI:

### Bundled methodology pool

```bash
# Location
.agents/skills/{skill-name}/SKILL.md
```

### Authored project skills (Step 13)

```bash
# Location
src/skills/{category}/{skill-name}/SKILL.md
```

### Codex (optional adapter)

Codex loads project skills from `.agents/skills/` by default. An optional compatibility adapter may exist at:

```bash
.codex/skills/{skill-name}/SKILL.md
```

See [PLATFORMS.md](./PLATFORMS.md) for skill invocation and validation gates.

Operators may add local CLI-specific config (Cursor rules, Claude hooks). Those paths are operator-local — not part of the OSS install contract.

---

## Skill Categories

### Sigma Core (6 skills)

These skills power the Step 0-15 Sigma methodology.

| Skill                  | Description                                        | Auto-Triggers                               | Used In Steps |
| ---------------------- | -------------------------------------------------- | ------------------------------------------- | ------------- |
| **research**           | MCP-orchestrated web research with source curation | research, search, find, investigate, market | 1, 2, 3, 8    |
| **verification**       | Step completion verification with scoring          | verify, validate, check, score              | All steps     |
| **bdd-scenarios**      | Given/When/Then scenario generation                | bdd, scenario, given, when, then            | 10, 11        |
| **hormozi-frameworks** | Value equation and offer architecture              | value, offer, pricing, hormozi              | 1, 1.5        |
| **output-generation**  | Consistent document output formatting              | generate, output, document, format          | All steps     |
| **frontend-design**    | Distinctive UI creation avoiding AI slop           | ui, component, tailwind, shadcn, layout     | 5, 6, 9       |

---

### Design & Development (4 skills)

Architecture and UI pattern expertise.

| Skill                     | Description                                     | Auto-Triggers                            | Used In Steps |
| ------------------------- | ----------------------------------------------- | ---------------------------------------- | ------------- |
| **ux-designer**           | Wireframes, user flows, accessibility (WCAG)    | ux, wireframe, user flow, accessibility  | 3, 4, 5       |
| **architecture-patterns** | Clean Architecture, Hexagonal, DDD patterns     | architecture, structure, pattern, domain | 2, 8          |
| **api-design-principles** | REST and GraphQL API design best practices      | api, endpoint, rest, graphql, route      | 2, 8          |
| **web-artifacts-builder** | Complex multi-component UIs with React/Tailwind | dashboard, complex ui, multi-component   | 9, implement  |

---

### Quality & Process (5 skills)

Testing, debugging, and code quality.

| Skill                    | Description                                    | Auto-Triggers                              | Used In Steps        |
| ------------------------ | ---------------------------------------------- | ------------------------------------------ | -------------------- |
| **brainstorming**        | Pre-implementation exploration of requirements | brainstorm, ideate, explore, think through | 1, 3, 10             |
| **systematic-debugging** | Structured root cause analysis                 | bug, error, fail, debug, broken, crash     | implement, ui-healer |
| **quality-gates**        | Git hooks, testing, CI/CD setup                | test, ci, cd, hook, lint, coverage         | 0, implement         |
| **senior-qa**            | Test strategies, automation, coverage          | qa, coverage, e2e, unit, integration       | qa-plan, qa-run      |
| **senior-architect**     | System design, tech decisions, scalability     | system design, tech stack, scalability     | 2, 8                 |

---

### Productivity (5 skills)

Documents, presentations, and productivity tools.

| Skill                           | Description                               | Auto-Triggers                          | Used In Steps  |
| ------------------------------- | ----------------------------------------- | -------------------------------------- | -------------- |
| **prompt-engineering-patterns** | LLM prompt optimization for production    | prompt, llm, ai, gpt, claude           | AI features    |
| **xlsx**                        | Spreadsheet creation, editing, analysis   | spreadsheet, excel, csv, xlsx          | Data export    |
| **pptx**                        | Presentation creation and editing         | presentation, slides, pptx, pitch deck | Client handoff |
| **applying-brand-guidelines**   | Consistent branding across outputs        | brand, style, theme, guidelines        | 6, marketing   |
| **remembering-conversations**   | Search previous conversations for context | recall, previous, remember, context    | All steps      |

---

### Self-Learning (SLAS) (3 skills)

Session learning and preference capture.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|
| **session-distill** | Distill session history into preferences and patterns | slas, session, distill | All |
| **sigma-exit** | Capture session context before ending a session | slas, exit, session | All |
| **developer-preferences** | Auto-generated preferences overlay from SLAS | preferences, slas | All |

Claude Code hooks live in `.claude/hooks/slas/` (`session-start-context.sh`, `session-end-summary.sh`) and write to `docs/sessions/{logs,preferences,patterns}`. Codex installs include the SLAS skills and session scaffolding but do not run hooks.

---

### Platform Tools (5 skills)

Create custom skills and agents for each platform.

| Skill | Description | Platform | Auto-Triggers |
|-------|-------------|----------|---------------|
| **skill-creator** | Create Claude Code skills | Claude Code | create skill, new skill |
| **agent-development** | Create Claude Code agents | Claude Code | create agent, agent design |
| **opencode-agent-generator** | Create OpenCode agents | OpenCode | opencode agent, swarm agent |
| **creating-opencode-plugins** | Create OpenCode plugins | OpenCode | opencode plugin, event hook |
| **agentic-coding** | AI-assisted coding patterns | All | agentic, ai coding, copilot |

---

### Content & Marketing (4 skills)

Brand voice and content creation.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|
| **brand-voice** | Define, extract, apply consistent brand voice | brand, voice, tone | Marketing |
| **content-atomizer** | Transform pillar content into platform formats | atomize, repurpose, content | Marketing |
| **direct-response-copy** | Conversion-focused copywriting frameworks | copy, conversion, sales | Marketing, Landing |
| **video-hooks** | Video hook and script patterns | hook, video, script | Marketing |

---

### Document Generation (2 skills)

Create and manipulate office documents.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|
| **docx-generation** | Create Word documents programmatically | word, docx, document | Handoff |
| **pdf-manipulation** | Generate, merge, split, extract PDFs | pdf, merge, split | Handoff |

---

### Browser & Verification (1 skill)

Browser testing and UI verification.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|
| **browser-verification** | Platform-adaptive browser testing | browser, test, verify ui | UI-Healer |

---

### Multi-Agent (2 skills)

Orchestration and parallel execution.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|

---

### Additional Skills (6 skills)

Extended capabilities.

| Skill | Description | Auto-Triggers | Used In Steps |
|-------|-------------|---------------|---------------|
| **memory-systems** | Persistent context and recall | memory, context, recall | All |
| **react-performance** | React optimization patterns | react, performance, memo | Implementation |
| **monorepo-architecture** | Monorepo setup and patterns | monorepo, turborepo, nx | Architecture |
| **superdesign-integration** | Superdesign AI integration | superdesign, design ai | Design |
| **specialized-validation** | Domain-specific validation | validate, schema | All |
| **web-artifacts-builder** | Complex multi-component UIs | dashboard, complex ui | Implementation |

---

## Skill File Locations

### OSS surfaces

```
src/skills/                          # Authored project skills (Step 13)
├── {category}/{skill-name}/SKILL.md

.agents/skills/                      # Bundled methodology pool
├── {skill-name}/SKILL.md
├── step-*/SKILL.md                  # Pointer stubs → steps/

.sigma/indexes/
├── skills-index.json                # Generated catalog (canon → index map)
├── commands-index.json
└── agents-index.json
```

See [PLATFORMS.md](./PLATFORMS.md) and [CANONICAL-SOURCES.md](./CANONICAL-SOURCES.md) for sync and validation.

---

## Auto-Trigger Examples

### Cursor (.mdc)

```yaml
---
description: Use when designing system architecture, selecting patterns, or planning technical structure
globs: ["**/ARCHITECTURE.md", "**/docs/architecture/**/*"]
alwaysApply: false
---
```

### Claude Code (SKILL.md)

```yaml
---
name: architecture-patterns
description: "This skill provides system architecture patterns including Clean Architecture, Hexagonal, and DDD. Use when designing system structure."
version: "1.0.0"
---
```

---

## Customization

### Removing Unwanted Skills

Delete the skill from the authored or bundled pool:

```bash
# Bundled pool
rm -rf .agents/skills/pptx/

# Authored project skill
rm -rf src/skills/{category}/pptx/
```

### Adding Custom Skills

Create new skills under `src/skills/<category>/<skill-name>/SKILL.md`, then rebuild indexes:

```bash
node scripts/generate-sigma-indexes.mjs
```

---

## Relationship with Step 13

These Foundation Skills form the reusable baseline capability set.

**Step 13** (Skillpack Generator) creates **project-specific overlay skills**:

- `frontend-aesthetics` — Your design system, tokens, component patterns
- `backend-engineering` — Your API conventions, auth patterns, error shapes
- `database-modeling` — Your schema patterns, RLS policies, migrations

These overlays **reference** your project docs and **override** generic foundation guidance with your specific decisions.

---

## Global Behavioral & Design Reference Skills

These skills live at `~/.claude/skills/` (user-global, not bundled by Sigma Protocol). Sigma's numbered steps reference them — they are not installed by `npx sigma-protocol install-skills`. Use them as advisory inputs during Steps 3, 5, 6, 7, 8, 9, 11.

| Skill | Source | Purpose | Referenced By |
|-------|--------|---------|---------------|
| `ponytail` | DietrichGebert/ponytail | Lazy-senior YAGNI DNA — the best code is the code never written. 6-rung ladder (need it? → stdlib → native platform → installed dep → one line → minimum code), deletion over addition, boring over clever, `ponytail:` shortcut markers. NOT lazy about validation/security/a11y/error-handling | Implementation agents (backend/frontend/mobile/client/devops/lead-architect/observability/qa) — baked into their DNA |
| `karpathy-guidelines` | forrestchang/andrej-karpathy-skills | Behavioral guidelines to reduce LLM coding mistakes — simplicity first, surgical changes, surface assumptions, goal-driven execution | Steps 8, 10, 11 (implementation discipline) |
| `macos-design` | davepoon/buildwithclaude | Native-feeling macOS UI patterns — traffic lights, sidebar layouts, vibrancy/blur, light/dark rules, SF Pro typography. Distinct from `platform-design-guidelines` (which covers iOS HIG + Android Material 3 mobile) | Step 3 (when desktop), Step 6 (when desktop) |
| `ux-psychology` | community | Cognitive psychology principles — Hick's, Fitts's, Miller's, Jakob's Law, Gestalt, Progressive Disclosure, Recognition over Recall | Steps 3, 5, 7, 9 |

These complement (do not replace) Sigma's bundled `ux-designer`, `frontend-design`, and `platform-design-guidelines` skills:
- `ux-designer` owns wireframes, flows, and accessibility checklists
- `frontend-design` owns component composition and anti-slop aesthetics
- `platform-design-guidelines` owns iOS HIG + Material 3 (mobile)
- `macos-design` covers desktop macOS — fills the gap above
- `ux-psychology` covers cognitive principles that inform layout choices but aren't framework-specific
- `karpathy-guidelines` covers implementation behavior, not design
- `ponytail` covers YAGNI/minimalism discipline — its DNA is baked directly into the implementation/build agents Sigma generates (they also list it in `skills:`), so scaffolded projects ship it without an external plugin

Step 13 generators may reference these in authored project skills via documentation links, but should NOT duplicate their contents into the project skillpack.

---

## See Also

- [Step 0: Environment Setup](../steps/step-0-environment-setup) — Where foundation skills are installed
- [Step 13: Skillpack Generator](../steps/step-13-skillpack-generator) — Where project overlays are created
- [.sigma/indexes/skills-index.json](../.sigma/indexes/skills-index.json) — Generated skill manifest (canon → index map)
