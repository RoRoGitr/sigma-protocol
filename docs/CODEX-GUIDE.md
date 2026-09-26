# Codex User Guide

**Platform:** OpenAI Codex CLI and Desktop App
**Status:** Primary Sigma runtime
**Last Updated:** 2026-09-19

---

## Codex-First Baseline

Sigma now treats Codex as the default runtime surface.

That means:
- active workflow docs are written Codex-first
- backlog generation and orchestration guidance points to `.sigma/backlogs/*` and `.sigma/orchestration/*`
- Codex skill installation uses nested categories by default
- Claude Code is aligned in a second pass rather than driving the baseline

## Install Codex and Sigma

### 1. Install Codex

```bash
npm install -g @openai/codex
```

### 2. Prepare a Sigma checkout for Codex

```bash
git clone https://github.com/Dallionking/sigma-protocol-public sigma-protocol-v2
cd sigma-protocol-v2
bash scripts/sync-steps-to-platforms.sh
node scripts/verify/validate-step-wiring.mjs
```

Codex does not require `scripts/install-claude-code.sh`, `sigma install --platform codex`, or `sigma install-skills --platform codex`. Those are not Codex setup commands in this repository. Use the canonical checkout surfaces below; add local Codex configuration only when your installed CLI requires it.

### 3. Start Codex

```bash
codex --profile sigma-dev
```

## Skill Layout

Codex loads Sigma skills from:

```text
.agents/skills/<skill>/SKILL.md
```

Sigma may also generate a compatibility adapter at:

```text
.codex/skills/<skill>/SKILL.md
```

Authored source bundles live in:

```text
src/skills/<category>/<skill>/SKILL.md
src/agents/<category>/<agent>.md
```

The 12 `src/agents/` definitions are project-agent examples. They are separate from the 62-file bundled Claude runtime roster in `.claude/agents/`; neither is automatically a cross-CLI agent roster.

Sigma also publishes machine-readable indexes under:
- `.sigma/indexes/commands-index.json`
- `.sigma/indexes/skills-index.json`
- `.sigma/indexes/agents-index.json`

## Execution Modes

Use Codex in three explicit modes:

| Mode | When to use it | Sigma surfaces |
|------|----------------|----------------|
| Interactive | Human-in-the-loop step execution, reviews, and local implementation | `codex --profile sigma-dev`, Step skills, `/prd-json` |
| Deterministic orchestration | Planned multi-PRD or multi-agent execution with reproducible inputs | `/prd-orchestrate`, `.sigma/orchestration/*`, worktree-per-stream flows |
| Background / cloud | Long-running or remote execution where Codex is not attached to your live terminal | `codex app-server`, Codex cloud tasks, GitHub Action automation |

Do not mix these modes casually. Choose the mode first, then generate or consume the matching Sigma artifacts.

## Core Workflow in Codex

Use the numbered workflow exactly as written:

1. Run Steps `0-15` plus conditional Steps `1.5` and `11.5`.
2. After Step 5, run `/prd-json --mode prototype`.
3. After Step 11, run `/prd-json --mode implementation`.
4. Use `/prd-orchestrate` only when you need dependency-aware planning.

Canonical outputs:
- `.sigma/backlogs/prototype/prd.json`
- `.sigma/backlogs/implementation/prd.json`
- `.sigma/orchestration/*`

Removed pseudo-step labels and legacy step-style aliases are not part of the active Codex workflow vocabulary.

## Running Step Skills

Inside Codex, invoke Sigma steps and utility skills directly:

```text
$step-1-ideation
$step-5-wireframe-prototypes
$gap-analysis
$implement-prd
```

You can also prompt naturally:

```text
Run step 1 ideation for a B2B invoicing product.
Convert the approved Step 11 PRDs into an implementation backlog.
Plan orchestration for the current execution backlog.
```

## Cross-Project Runtime Baseline

Use two config layers on purpose:

- `~/.codex/config.toml` for your personal Codex defaults across all repos
- `.codex/config.toml` inside a repo only for repo-specific overrides

Do not copy a model, context-window, approval, or sandbox setting from this guide into every repository. Those choices depend on the installed Codex release, account access, and the task’s risk.

### Model selection

[GPT-6 Astra](https://developers.openai.com/api/docs/models/gpt-6-astra) is OpenAI’s most capable model for difficult end-to-end work and supports `low` through `max` reasoning effort. Use it selectively for hard reasoning, review, investigation, or long-running work. Keep routine and mechanical work on an available lower-cost model, then verify the result. The [latest-model guide](https://developers.openai.com/api/docs/guides/latest-model) recommends preserving a reasoning setting that already works and only raising it when the task warrants it.

Prompt with the task outcome, constraints, file or system boundary, acceptance evidence, and permission to make routine decisions. Specify how much delegation is useful when parallel work is genuinely independent. Astra is particularly sensitive to instructions in `AGENTS.md`, skills, and other loaded files, so keep those instructions concrete and internally consistent.

## Project-Local Override Pattern

Project overrides should stay narrow. Do not duplicate your whole home config in every repo.

Keep project overrides narrow and verify their syntax against the installed Codex version. Keep personal model and tool defaults in `~/.codex/config.toml` unless a repository has a clear reason to diverge. Do not represent a Codex approval or sandbox setting as portable Claude Code behavior.

## Config and Runtime Surfaces

Project-level Codex runtime context lives in:
- `.codex/config.toml`
- `AGENTS.md`

User defaults live in:
- `~/.codex/config.toml`

Optional repo or user execution-policy files may still live in:
- `.codex/rules/*.rules`
- `~/.codex/rules/*.rules`

Those files are optional repo policy layers. They are not Step 12 outputs.

## Validation and Smoke Tests

Use these terminal checks after changing your Codex config.

### 1. Config sanity

```bash
codex --version
codex --help
```

Expected result:

- Codex starts without a config parse error
- the commands shown by the installed release match the local configuration you intend to use

### 2. Multi-agent smoke test

Run this inside a real repo:

```bash
codex "Spawn one agent to map the repo entrypoints, one agent to list the best verification commands, and one agent to identify the highest-risk directories. Wait for all agents and return one merged summary with a section for each agent."
```

Expected result:

- Codex shows agent-thread activity
- the final answer is a merged summary instead of one monolithic exploration pass

## Desktop App Workflow

Use the Codex Desktop App when you want:
- parallel feature or PRD execution in separate panes
- worktree isolation per pane
- review queues before applying changes
- scheduled automations for repeated audits or checks

Recommended pattern:
1. Generate or refresh the relevant backlog with `/prd-json`.
2. Create one pane per independent feature or PRD.
3. Use separate worktrees when the panes may touch overlapping files.
4. Keep `sigma-dev` for implementation and `sigma-strict` for review panes.

## Background and CI Work

Codex is the primary Sigma path for:
- long-running code generation
- automated review
- background/cloud execution
- GitHub Action based CI workflows
- app-server mediated remote orchestration

For production-style orchestration, prefer `codex app-server` or Codex-managed cloud tasks over ad hoc shell wrappers when you need durable progress tracking across clients.

Minimal example:

```yaml
- uses: openai/codex-action@v1
  with:
    openai-api-key: ${{ secrets.OPENAI_API_KEY }}
    task: "Review this PR for correctness, security issues, and test coverage gaps."
    profile: sigma-strict
```

## MCP Setup

Sigma's Codex config typically includes:
- Firecrawl
- EXA
- Ref
- Context7
- Task Master AI

Add or adjust servers in `.codex/config.toml` under `mcp_servers`.

## Codex and Claude Code

The following is legacy SigmaHQ compatibility guidance, not a required Codex installation or the active Linear task board. Use it only when the operator deliberately retains and verifies this extension. Its shared layer is the `hq` CLI backed by `SIGMAHQ_HOME`, which defaults to `~/.commandboard`.

```bash
hq health
hq today
hq sync --no-open
hq done products/my-project 12
```

Codex uses the SigmaHQ skill and the shared `hq` command. Claude Code keeps its slash commands and SessionStart hooks, but those hooks resolve `SIGMAHQ_HOME` first and keep `CLAUDE_CODE_COMMANDBOARD` as a compatibility alias.

Use Codex when you need:
- the default Sigma workflow experience
- the default execution backlog path
- desktop parallel panes
- GitHub Action or cloud-oriented automation

Use Claude Code when you specifically need:
- Claude-native worktree or hook behavior
- Claude-specific slash-command flows such as `/batch`
- mission slash-command flows such as `/mission new`

## Troubleshooting

| Issue | Check |
|-------|-------|
| Skills not loading | Confirm `.agents/skills/<skill>/SKILL.md` exists |
| Old flat mirror still expected | Confirm whether `SIGMA_CODEX_LEGACY_SKILLS=1` is actually needed |
| Config ignored | Confirm `.codex/config.toml` exists and uses `model_reasoning_effort` |
| Optional exec-policy rules not firing | Confirm `.codex/rules/*.rules` exist and validate with `codex execpolicy check` |
| Backlog path confusion | Use only `.sigma/backlogs/*` and `.sigma/orchestration/*` |

## Related Documentation

- [PLATFORMS.md](./PLATFORMS.md)
- [COMMANDS.md](./COMMANDS.md)
- [WORKFLOW-OVERVIEW.md](./WORKFLOW-OVERVIEW.md)
- [Skill layout](#skill-layout) (this guide)
- [Execution modes](#execution-modes) (this guide)
