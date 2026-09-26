# Sigma Protocol Command Catalog

**Version:** 1.0.0-alpha.1
**Last Updated:** 2026-06-29

Complete index of all Sigma Protocol commands, organized by category.

---

## Quick Reference

| Category | Commands | Purpose |
|----------|----------|---------|
| **Utilities** | 8 | Install, validation, render, and dispatch scripts |
| **Steps** | 21 | Core Step 0-15 workflow + PRD backlog/orchestration utilities |
| **Audit** | 16 | Quality assurance + code simplification |
| **Dev** | 5 | Development workflow + compound engineering |
| **Ops** | 34 | Operations & management + orchestration |
| **Deploy** | 4 | Shipping & handoff |
| **Generators** | 15 | Code & doc generation |
| **Marketing** | 25 | GTM workflow + Content Creation Studio |
| **Loops** | 4 | Bounded iterate-until-done cycles (`/step-loop`, `/gap-loop`, `@dev-loop`, `/run-loop`) |
| **Deprecated** | 1 | Compatibility surfaces retained for a release window |
| **Skills** | Generated catalog | Foundation + external skills (live catalog: `.sigma/indexes/skills-index.json`) |
| **Agents** | 61 | Specialist agent personas across departments |

---

## Platform Support

Sigma OSS ships **canonical sources only** — no per-vendor mirror trees. Import `commands/*.md` as slash commands in any agent CLI.

| Surface | Path | Notes |
|---------|------|-------|
| Steps (source) | `steps/` | Edit here; never hand-edit `commands/` |
| Commands (rendered) | `commands/` | Produced by `scripts/sync-steps-to-platforms.sh` |
| Skills (bundled) | `.agents/skills/` | Methodology pool; step skills are thin pointers |
| Skills (authored) | `src/skills/` | Step 13 project output |
| Project brain | `AGENTS.md` | Step 12 output |

Operators may add local CLI config (hooks, MCP, permissions). Sigma tracks only the paths above. See [PLATFORMS.md](PLATFORMS.md).

**Install:**
```bash
git clone https://github.com/Dallionking/sigma-protocol-public sigma-protocol-v2
cd sigma-protocol-v2
bash scripts/install.sh        # add --all for the optional SigmaHQ board
```

---

## Utility Commands & Scripts

Repo-level utilities you run from the checkout (there is no separate `sigma` binary — everything runs through your agent CLI plus these scripts):

| Command | Description |
|---------|-------------|
| `bash scripts/install.sh [--all]` | One-command install (Claude Code surfaces + departments; `--all` adds SigmaHQ) |
| `bash scripts/doctor.sh` | One-command health check — runs every validation gate with a PASS/FAIL summary |
| `node scripts/validate-cascade.mjs` | System health check (departments, agents, skills, step bindings) |
| `bash scripts/lint-step-parity.sh` | Verify `steps/` ↔ `commands/` stay in sync |
| `bash scripts/sync-steps-to-platforms.sh` | Re-render `commands/` after editing `steps/` |
| `$map-codebase` | Write the tracked brownfield codebase map |
| `$discuss-phase` | Capture unresolved decisions before planning |
| `bash scripts/sigma-dispatch.sh <prd-id>` | Fire the active CLI's native primitive for a PRD bundle |
| `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` | Repair or backfill SigmaHQ integration events into the matching workspace |

---

## Loops (iterate-until-done)

Pre-built bounded loops. Each exits only on an external check, caps its rounds, reports a round-by-round evidence table, and never answers a `<HARD-GATE>` for the user.

| Command | Repeats | Exit condition |
|---------|---------|----------------|
| `/step-loop --step=N` | `@step-verify` → fix findings → re-verify | Step score ≥ its passing threshold (max 5 rounds) |
| `/gap-loop [--scope=F..]` | `@gap-analysis` → fix gaps → fresh re-run | 2 consecutive clean rounds (max 6 rounds, 2 fix attempts per finding) |
| `@dev-loop` | Implement unbuilt PRDs in dependency order | Backlog empty |
| `/run-loop [--dept=..]` | Run Track engine → today's step → record → next offer | User ends the session (HITL every round by design) |

---

## Steps Commands (`steps/`)

The core product methodology uses Steps `0-15` plus conditional Steps `1.5` and `11.5`.

| Command | Description | Key Output |
|---------|-------------|------------|
| `step-0-environment-setup` | Environment validation | `docs/ops/ENVIRONMENT-SETUP.md`, `.sigma/runtime-baseline.json` |
| `step-1-ideation` | Discovery-first PRD initialization | `MASTER_PRD.md`, `stack-profile.json` |
| `step-1.5-offer-architecture` | Monetization, positioning, and packaging design (if monetized) | `OFFER_ARCHITECTURE.md` (+ `pricing-config.json` when structured) |
| `step-2-architecture` | Architecture decisions, boundaries, and handoffs | `docs/architecture/ARCHITECTURE.md` |
| `step-3-ux-design` | UX strategy, journeys, design DNA, IA, and UI profile direction | `docs/ux/UX-DESIGN.md`, `DESIGN.md`, `docs/design/ui-profile.json` |
| `step-4-flow-tree` | Structural flow mapping and bulletproof screen coverage | `docs/flows/FLOW-TREE.md`, `docs/flows/SCREEN-INVENTORY.md`, `docs/flows/TRANSITION-MAP.md`, bulletproof gate docs, `product/flows/flow-tree.json` |
| `step-5-wireframe-prototypes` | Per-flow prototype PRDs — Track A (Claude Design visual validation) or Track B (direct HTML scaffolding, default). Track A adds `CLAUDE-DESIGN-PROMPT.md` + `claude-design/` bundle per flow; Track B adds `screens/*.html` per flow. | `docs/prds/flows/[NN]-[flow-slug]/FLOW-[ID].md`, `docs/prds/flows/WIREFRAME-TRACKER.md`, `docs/prds/flows/PRD-SUMMARY.md`, `docs/prds/flows/ZERO-OMISSION-CERTIFICATE.md` |
| `prd-json` | Convert prototype PRDs to execution backlog JSON | `.sigma/backlogs/prototype/prd.json` |
| | *Supports `--use-taskmaster=true` for AI-powered parsing* | |
| `step-6-design-system` | Design system, themes, motion, and tokens | `docs/design/DESIGN-SYSTEM.md`, `docs/tokens/design-tokens.json` |
| `step-7-interface-states` | Full state catalog, recovery, and announcement rules | `docs/states/STATE-SPEC.md` |
| `step-8-technical-spec` | Implementation blueprint and technical specification | `docs/technical/TECHNICAL-SPEC.md` + conditional API/schema artifacts |
| `step-9-landing-page` | Landing-page strategy, copy, and template mapping — Track A (Claude Design) / Track B (templates, default) / Hybrid (Claude Design → template seed). Track A/Hybrid adds `docs/landing-page/claude-design/` bundle. | `docs/landing-page/LANDING-PAGE.md`, avatar/diary/research docs, conditional mapping artifacts |
| `step-10-feature-breakdown` | Feature shaping, PRD eligibility, and sequencing | `docs/implementation/FEATURE-BREAKDOWN.md` + conditional shaping artifacts |
| `step-11-prd-generation` | Implementation-ready feature PRD generation. Ingests Step 5 Track A bundles + Step 9 landing page output as visual source of truth for UI Contract. Includes mandatory Section 13 Eval Contract (5–10 golden tasks, scoring rubric, CI gate thresholds). | `docs/prds/F01.001-<slug>.md` (ID = F<wave:02d>.<feature:03d>), `docs/prds/.prd-status.json` |
| `prd-json` | Convert implementation PRDs to execution backlog JSON | `.sigma/backlogs/implementation/prd.json` |
| | *Supports `--use-taskmaster=true` for AI-powered parsing* | |
| `prd-orchestrate` | Plan dependency-aware orchestration from active PRDs or backlogs | `.sigma/orchestration/*` |
| `step-11.5-task-handoff` | Vendor-neutral execution handoff from approved PRDs: P0-P3 priority, dependency graph, claim fields, Files-to-Touch + Files-NOT-to-Touch, EARS criteria refs, /next-task fleet loop contract | `.sigma/backlogs/<mode>/TASKS.md` (primary), optional `.sigma/backlogs/<mode>/TASKS.json` mirror |
| `step-12-context-engine` | Native runtime context synthesis | `AGENTS.md`, `CLAUDE.md` (thin pointer), `.claude/settings.json`, operator-local CLI config |
| `step-13-skillpack-generator` | Skillpack generation including eval-harness skills per department agent and eval-runner.sh | `src/skills/<category>/<skill>/SKILL.md`, `src/agents/<category>/<agent>.md`, runtime adapters, `.sigma/indexes/*`, `.sigma/tools/eval-runner.sh` |
| `step-14-agent-runtime-bootstrap` | Agent runtime bootstrap — includes security threat model (MAESTRO pass), proactive ops layer (crons, heartbeats, kanban loop), and compound loop engineering | `docs/specs/AGENT-RUNTIME.md`, `docs/security/threat-register.md`, generated `.sigma/tools/*`, `.sigma/runtime/*`, `.sigma/memory/*` |
| `step-15-observability-contract` | Per-feature Instrumentation Contract before ship: success metric, leading indicators, cost meter, eval set reference, trace points, dashboard URL, kill condition. Ship gate: no feature deploys without a completed contract. | `docs/observability/INSTRUMENTATION-CONTRACT.md`, `docs/observability/CI-WIRE-UP.md` |

Removed pseudo-step labels and legacy step-style aliases are not part of the active command model.

---

## Audit Commands (`audit/`)

Quality assurance and verification — **16 commands**.

| Command | Description | Score? |
|---------|-------------|--------|
| `holes` | Pre-implementation gap analysis | Yes |
| `gap-analysis` | Post-implementation verification | Yes |
| `verify-prd` | PRD implementation scoring | Yes |
| `step-verify` | Step completion verification | Yes |
| `ui-healer` | Browser UI testing with Agent Browser CLI-first validation | Yes |
| `security-audit` | Security vulnerability scan | Yes |
| `accessibility-audit` | WCAG compliance check | Yes |
| `performance-check` | Performance analysis | Yes |
| `code-quality-report` | Code quality metrics | Yes |
| `tech-debt-audit` | Technical debt analysis | Yes |
| `analyze` | General analysis | No |
| `license-check` | Dependency license audit | No |
| `load-test` | Load testing | Yes |
| `seo-audit` | SEO analysis | Yes |
| `simplify` | Code simplification (inspired by code-simplifier) | No |
| `sigma-simplify` | Sigma-specific code simplification | No |

### Audit Command Differentiation

These commands serve **different purposes** at different stages of development:

| Command | When to Use | Purpose |
|---------|-------------|---------|
| `@holes` | **BEFORE** coding | Analyze PLANS/PRDs for gaps and risks |
| `@gap-analysis` | **AFTER** coding | Verify CODE matches requirements, auto-fix issues |
| `@verify-prd` | After implementation | Score implementation quality against PRD |

**Workflow:**
1. **Pre-implementation**: Run `@holes` on your PRD to find missing requirements
2. **Post-implementation**: Run `@gap-analysis` to verify code completeness
3. **Quality check**: Run `@verify-prd` for a quality score

---

## Dev Commands (`dev/`)

Development workflow.

| Command | Description |
|---------|-------------|
| `implement-prd` | Implement a PRD feature |
| `discuss-phase` | Capture a tracked phase brief before planning or PRD work |
| `plan` | Create implementation plan |
| `db-migrate` | Database migration assistance |
| `compound-engineering` | Plan → Work → Review → Compound structured workflow |

---

## Execution Backlogs

Sigma converts approved PRDs into machine-readable backlogs with canonical commands. Successful step runs already auto-sync the matching board surfaces; `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` is the explicit repair/backfill path.

```bash
/prd-json --mode prototype
/prd-json --mode implementation
/prd-orchestrate
python3 scripts/sigmahq-sync-run-track.py --dept <dept>
```

Canonical output paths:
- `.sigma/backlogs/prototype/prd.json`
- `.sigma/backlogs/implementation/prd.json`
- `.sigma/orchestration/*`
- `.sigma/integrations/sigmahq/events/*.json`

SigmaHQ bridge rules:
- Step 10 uses `docs/implementation/FEATURE-BREAKDOWN.md` to create or update feature cards, but only for rows where `PRD Required` resolves to Yes
- Step 11 uses `docs/prds/F*-*.md` plus `docs/prds/.prd-status.json` to create or update engineering cards, but only when the matching status entry has `approved: true`
- `python3 scripts/sigmahq-sync-run-track.py --dept <dept>` is the repair command when you need to replay or backfill the board from current repo artifacts
- `SIGMAHQ_HOME` defaults to `~/.commandboard` and can be overridden when your SigmaHQ workspace lives somewhere else

### Brownfield and Pre-Plan Helpers

| When | Command | Output |
|------|---------|--------|
| Existing repo before Step 0 / Step 2 / Step 10 | `$map-codebase` | `docs/ops/CODEBASE-MAP.md`, `docs/ops/codebase-map.json` |
| Scope is still fuzzy before planning | `$discuss-phase --topic="..."` | `docs/plans/PHASE-BRIEF-<slug>.md` |
| You already have a brief and want it loaded explicitly | `$plan --phase-brief=<path>` | `docs/plans/PLAN-*.md` with the brief embedded in planning context |

---

## Thread-Based Engineering

Sigma Protocol implements **Thread-Based Engineering** - a framework for measuring and improving agentic engineering workflows.

### Thread Types

| Type | Symbol | Description | Entry point |
|------|--------|-------------|-------------|
| Base Thread | B | Single prompt → work → review | `@step-X`, any command |
| P-Thread | P | Parallel agents | `/prd-orchestrate` plan → `scripts/orchestrator/spawn-mprocs.sh` |
| C-Thread | C | Chained phases with checkpoints | Step 0-15 workflow |
| F-Thread | F | Fusion - same prompt, multiple agents | `bash scripts/fusion/fusion.sh` |
| B-Thread | B+ | Meta - agents prompting agents | `scripts/orchestrator/orchestrator.py` (full-auto) |
| L-Thread | L | Long duration, extended autonomy | Stop hooks + long sessions |
| Z-Thread | Z | Zero touch (goal) | Full automation |

---

## Orchestration (P-Thread)

Multi-agent parallel development - implements the **P-Thread** pattern. Plan with `/prd-orchestrate` (writes `.sigma/orchestration/*`), then launch stream workers with the orchestrator scripts below.

### TUI Options

| TUI | Install | Features |
|-----|---------|----------|
| **mprocs** (recommended) | `brew install mprocs` | Sidebar navigation, keyboard shortcuts, copy mode |
| **Overmind** | `brew install overmind` | Procfile-based, sidebar switching |
| **tmux** (default) | `brew install tmux` | Classic multiplexer, panes |

### Supporting Scripts

| Script | Description |
|--------|-------------|
| `scripts/orchestrator/spawn-mprocs.sh` | Create mprocs session (recommended) |
| `scripts/orchestrator/spawn-overmind.sh` | Create Overmind session |
| `scripts/orchestrator/spawn-streams.sh` | Create tmux session with panes |
| `scripts/orchestrator/orchestrator.py` | Main orchestrator logic |
| `scripts/orchestrator/stream-worker.py` | Stream worker implementation |
| `scripts/orchestrator/health-monitor.sh` | Crash detection and recovery |
| `scripts/orchestrator/merge-streams.sh` | Sequential merge strategy |
| `scripts/notify/voice.py` | ElevenLabs voice notifications |

### Configuration Files

| File | Purpose |
|------|---------|
| `.sigma/orchestration/streams.json` | Stream-to-PRD assignments |
| `.sigma/orchestration/state.json` | Current orchestration state |
| `.sigma/orchestration/progress.json` | PRD completion progress |
| `.sigma/orchestration/inbox/` | Inter-agent message queue |

---

## Ops Commands (`ops/`)

Operations and project management — **34 commands**.

### Tracking & Planning

| Command | Description |
|---------|-------------|
| `backlog-groom` | Create/update product backlog |
| `prd-orchestrate` | PRD swarm orchestration for parallel dev |
| `sprint-plan` | Plan and commit sprint |
| `daily-standup` | Daily standup with git awareness |
| `job-status` | Query PRD/sprint status |
| `status` | Project health overview |
| `continue` | Find and resume unfinished work |
| `sigma-continue` | Sigma-specific work continuation |

### Orchestration

| Command | Description |
|---------|-------------|
| `orchestrate` | Multi-agent orchestration setup |
| `sigma-orchestrate` | Sigma-specific orchestration |
| `stream` | Stream worker management |
| `sigma-stream` | Sigma stream operations |

### Quality Assurance

| Command | Description |
|---------|-------------|
| `qa-plan` | Generate QA test plan |
| `qa-run` | Execute QA tests |
| `qa-report` | Generate QA report |

### Code Reviews

| Command | Description |
|---------|-------------|
| `pr-review` | Code review with scoring |
| `test-review` | Test quality review |
| `release-review` | Final go/no-go decision |

### Maintenance

| Command | Description |
|---------|-------------|
| `dependency-update` | Update dependencies safely |
| `maintenance-plan` | Create maintenance schedule |
| `maid` | Repository maintenance wizard |
| `cleanup-repo` | Clean up repository files |
| `doctor-fix` | Auto-fix common installation issues |
| `lint-commands` | Lint Sigma command files |
| `docs-update` | Update documentation |
| `onboard` | Onboard new team member |
| `prompt-handoff` | Handoff context to another session |
| `repair-manifest` | Repair module manifests |
| `sync-workspace-commands` | Sync commands in workspace |
| `platform-sync` | Sync with platform changelogs |
| `system-health` | System health check |

### Retrofit

| Command | Description |
|---------|-------------|
| `retrofit-analyze` | Analyze existing codebase |
| `retrofit-enhance` | Enhance existing code |
| `retrofit-generate` | Generate from existing patterns |
| `map-codebase` | Map an existing repo into Sigma's planning model |

---

## Deploy Commands (`deploy/`)

Deployment and shipping.

| Command | Description |
|---------|-------------|
| `ship-check` | Pre-deployment validation |
| `ship-stage` | Deploy to staging |
| `ship-prod` | Deploy to production |
| `client-handoff` | Client delivery documentation |

---

## Generator Commands (`generators/`)

Code and document generation.

| Command | Description |
|---------|-------------|
| `scaffold` | Generate project scaffolding |
| `new-feature` | Create new feature structure |
| `new-project` | Initialize new Sigma project |
| `new-command` | Create new Sigma command |
| `test-gen` | Generate tests from PRD |
| `api-docs-gen` | Generate API documentation |
| `wireframe` | Generate wireframe spec |
| `changelog` | Generate changelog |
| `contract` | Generate contract template |
| `nda` | Generate NDA template |
| `proposal` | Generate project proposal |
| `prototype-proposal` | Generate prototype proposal |
| `estimation-engine` | Estimate project scope |
| `cost-optimizer` | Optimize project costs |
| `notebooklm-format` | Format for NotebookLM |

---

## Run Track Commands (Growth Operations)

Parallel GTM + ops workflows — **64 step commands** + **8 orchestrators**. See [`docs/run-track/HOW-TO-USE.md`](run-track/HOW-TO-USE.md).

| Command | Description |
|---------|-------------|
| `run-marketing` | Orchestrate M1–M10 |
| `run-m-1-gtm-audit` … `run-m-10-retention-loop` | Marketing Run Track steps |
| `run-sales` | Orchestrate S1–S8 |
| `run-s-1-icp-accounts` … `run-s-8-pipeline-ops` | Sales Run Track steps |
| `run-content` | Orchestrate C1–C8 |
| `run-c-1-brief-intake` … `run-c-8-publish-handoff` | Content production steps |
| `run-growth` | Orchestrate G1–G8 |
| `run-g-1-funnel-map` … `run-g-8-seo-organic-loop` | Growth / CRO steps |
| `run-community` | Orchestrate Co1–Co6 |
| `run-co-1-platform-audit` … `run-co-6-advocacy` | Community ops steps |
| `run-ops` | Orchestrate O1–O8 |
| `run-o-1-ops-baseline` … `run-o-8-contractor-onboarding` | Ops / COO steps |
| `run-finance` | Orchestrate Fn1–Fn7 |
| `run-fn-1-unit-economics` … `run-fn-7-data-room` | Finance steps |
| `run-legal` | Orchestrate L0–L8 (L0 = entity formation) |
| `run-l-1-intake-batna` … `run-l-8-demand-playbook` | Legal ops steps |

**Atom skills:** `gtm-stack-setup`, `crm-pipeline-setup`, `content-production-queue`, `funnel-instrumentation-setup`, `ab-test-spec`

**Verify:** `node scripts/verify-run-track.mjs --wave=4`

---

## Marketing Commands (`marketing/`)

Go-to-market workflow — **25 commands**.

### Research & Strategy

| Command | Description |
|---------|-------------|
| `01-market-research` | Market research analysis |
| `02-customer-avatar` | Customer persona creation |
| `03-brand-voice` | Brand voice guidelines |
| `04-offer-architect` | Offer design |
| `05-sales-strategy` | Sales strategy |

### Content & Copy

| Command | Description |
|---------|-------------|
| `06-email-sequences` | Email sequence creation |
| `07-landing-page-copy` | Landing page copywriting |
| `08-ads-strategy` | Advertising strategy |
| `09-retargeting-strategy` | Retargeting strategy |
| `10-launch-playbook` | Launch planning |

### Partnerships & Content

| Command | Description |
|---------|-------------|
| `11-partnership-outreach` | Partnership outreach |
| `12-content-ideation` | Content ideation |
| `13-content-matrix` | Content matrix |
| `14-video-script` | Video script writing |
| `15-thumbnail-prompts` | Thumbnail prompt generation |
| `16-seo-content` | SEO content creation |
| `17-community-update` | Community update posts |

### Content Creation Studio (NEW)

| Command | Description |
|---------|-------------|
| `18-youtube-script-writer` | Long-form YouTube scripts |
| `19-short-form-scripts` | TikTok/Reels/Shorts scripts |
| `20-linkedin-writer` | LinkedIn post writer |
| `21-twitter-threads` | Twitter thread generator |
| `22-video-research` | Video topic research |
| `23-story-posts` | Instagram/Facebook story posts |

### AI Asset Prompts

| Command | Description |
|---------|-------------|
| `ai-video-prompt` | AI video generation prompts |
| `ai-image-prompt` | AI image generation prompts |

---

## Foundation Skills (`src/skills/<category>/<skill>/SKILL.md`)

Skills provide reusable capabilities — **230+ skills** (Foundation + external). See [FOUNDATION-SKILLS.md](FOUNDATION-SKILLS.md) for the complete reference. The live catalog is `.sigma/indexes/skills-index.json` (regenerate with `node scripts/generate-sigma-indexes.mjs`).

### Sigma Core (6)

| Skill | Description |
|-------|-------------|
| `research` | MCP-orchestrated web research |
| `verification` | Step completion verification with scoring |
| `bdd-scenarios` | Given/When/Then scenario generation |
| `hormozi-frameworks` | Value equation and offer architecture |
| `output-generation` | Consistent document formatting |
| `frontend-design` | Distinctive UI creation |

### Design & Development (7)

| Skill | Description |
|-------|-------------|
| `ux-designer` | Wireframes, user flows, accessibility |
| `architecture-patterns` | Clean Architecture, Hexagonal, DDD |
| `api-design-principles` | REST and GraphQL best practices |
| `web-artifacts-builder` | Complex multi-component UIs |
| `react-performance` | React optimization patterns |
| `monorepo-architecture` | Monorepo setup and patterns |
| `superdesign-integration` | Superdesign AI integration |

### Quality & Process (6)

| Skill | Description |
|-------|-------------|
| `brainstorming` | Pre-implementation exploration |
| `systematic-debugging` | Structured root cause analysis |
| `quality-gates` | Git hooks, testing, CI/CD setup |
| `senior-qa` | Test strategies, automation, coverage |
| `senior-architect` | System design, tech decisions |
| `specialized-validation` | Domain-specific validation |

### Productivity (6)

| Skill | Description |
|-------|-------------|
| `prompt-engineering-patterns` | LLM prompt optimization |
| `xlsx` | Spreadsheet creation and analysis |
| `pptx` | Presentation creation and editing |
| `applying-brand-guidelines` | Consistent branding |
| `remembering-conversations` | Context recall |
| `memory-systems` | Persistent context systems |

### Platform Tools (5)

| Skill | Description |
|-------|-------------|
| `skill-creator` | Create Sigma skills for supported platforms |
| `agent-development` | Create agent definitions and platform-specific variants |
| `opencode-agent-generator` | Create OpenCode agents |
| `creating-opencode-plugins` | Create OpenCode plugins |
| `agentic-coding` | AI-assisted coding patterns |

### Content & Marketing (4)

| Skill | Description |
|-------|-------------|
| `brand-voice` | Consistent brand voice |
| `content-atomizer` | Content repurposing |
| `direct-response-copy` | Conversion copywriting |
| `video-hooks` | Video script patterns |

### Document Generation (2)

| Skill | Description |
|-------|-------------|
| `docx-generation` | Create Word documents |
| `pdf-manipulation` | PDF generation and manipulation |

### Multi-Agent (1)

| Skill | Description |
|-------|-------------|
| `browser-verification` | Platform-adaptive browser testing |

---

## Agents

Two surfaces:

- **The department roster** — **61 agents across 13 departments** in `.claude/agents/` (heads like `cmo`, `lead-architect`, `cso`, plus their specialist benches). The registry (`.claude/lib/agent-skill-registry.json`) wires each to its department, triggers, and skills. Tour: [DEPARTMENTS.md](DEPARTMENTS.md) · full roster: [AGENT-CAPABILITY-MATRIX.md](AGENT-CAPABILITY-MATRIX.md).
- **Authored samples** — **12 agents** in `src/agents/` produced by Step 13 as authoring references: `engineering/` (`client-engineer`, `design-lead`, `frontend-engineer`) and `sales/` (`aaron-ross`, `ari-gold`, `belfort`, `chris-voss`, `cole-gordon`, `cso`, `jeremy-miner`, `josh-braun`, `sheila-bella`).

---

## Installation

```bash
git clone https://github.com/Dallionking/sigma-protocol-public sigma-protocol-v2
cd sigma-protocol-v2
bash scripts/install.sh        # add --all for the optional SigmaHQ board
```

See [README.md](../README.md) and [GETTING-STARTED.md](../GETTING-STARTED.md) for platform-specific setup.

### Windows Support

Sigma Protocol includes Windows wrapper scripts for bash-based orchestration tools:

| Script | Purpose |
|--------|---------|
| `scripts/windows/spawn-streams.cmd` | Spawn parallel agent streams |
| `scripts/windows/health-monitor.cmd` | Monitor stream health |
| `scripts/windows/merge-streams.cmd` | Merge completed streams |

**Requirements (choose one):**
- **WSL (Recommended):** Full bash compatibility. Install with `wsl --install`
- **Git Bash:** Good compatibility. Download from https://git-scm.com/download/win
- **Node.js only:** Use the `scripts/orchestrator/` spawn scripts directly

See `scripts/windows/README.md` for detailed setup instructions.

---

## Recommended MCP Servers

These MCP servers enhance Sigma Protocol capabilities:

| MCP Server | Purpose | Used By |
|------------|---------|---------|
| **Taskmaster** | AI-powered PRD → backlog conversion | `prd-json` |
| **Playwright** | Browser automation for testing | `@ui-healer` |
| **Ref** | Documentation search | All commands |

Built-in web search covers research phases. Exa, Firecrawl, and Perplexity are optional operator additions — not required by the methodology.

### Taskmaster MCP (Highly Recommended)

[Taskmaster MCP](https://github.com/eyaltoledano/claude-task-master) provides intelligent PRD parsing for execution backlogs generated by `prd-json`.

**Usage:**
```bash
/prd-json --mode prototype --use-taskmaster=true
/prd-json --mode implementation --use-taskmaster=true
```

---

## Related Documentation

- [GETTING-STARTED.md](../GETTING-STARTED.md) - Quick start guide
- [WORKFLOW-OVERVIEW.md](WORKFLOW-OVERVIEW.md) - Complete workflow guide
- [FILE-PATH-REFERENCE.md](FILE-PATH-REFERENCE.md) - Output file locations
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Quick command reference
- [FOUNDATION-SKILLS.md](FOUNDATION-SKILLS.md) - Foundation skills reference
- [EXTERNAL-SKILLS.md](EXTERNAL-SKILLS.md) - External skills reference

## Game-development adaptation

Game projects use the existing numbered methodology. `/game-development` is a domain entry point; Step 1 also asks what is being built. Record `projectDomain: "game"` in `docs/stack-profile.json` to load the conditional method. Missing/general projects retain their current flow.

The canonical source is `domains/game-development/catalog.json`: all 18 Protocol entries, an explicit 20-stage Atlas mapping, 12 nested workflows and 93 planning phases. See [the game guide](GAME-DEVELOPMENT.md) and [step mapping](../domains/game-development/STEP-MAPPING.md). Solo is the default; team mode preserves independent idea packs and explicit synthesis. Company, ownership, business, GTM, operations, context and handoffs remain part of the same system.

Game skills and role definitions prepare decisions and bounded external experiment briefs. Atlas never executes Blender/engine work or activates an agent from these records. A reviewed plan is distinct from an executed/validated asset, playable build, performance measurement or target import.

Author the catalog once, run `python3 scripts/validate-game-method.py`, then `python3 scripts/render-game-method.py`; use the normal step render/index checks. Generated skill references are portable snapshots. This repository update does not install skills globally.
