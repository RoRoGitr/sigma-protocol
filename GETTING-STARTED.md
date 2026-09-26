# Getting Started with Sigma Protocol

> Steps 0–15 (plus conditional 1.5 and 11.5). From idea to production. With AI doing the heavy lifting.

---

## What Was Just Installed

| Asset | Count | Description |
|-------|-------|-------------|
| Steps | 0–15 + conditional 1.5 / 11.5 | End-to-end product development workflow |
| Commands | `commands/*.md` | Rendered slash commands (from `steps/` via sync script) |
| Claude runtime agents | 60+ | Bundled specialist roster across 13 departments (`.claude/agents/`) |
| Step 13 agent examples | 12 | Authored project-agent examples (`src/agents/`); not a source mirror of the Claude roster |
| Skills | Generated catalog | `.agents/skills/` methodology pool + Step 13 `src/skills/` overlays; see `.sigma/indexes/skills-index.json` |
| Schemas | 17+ | JSON validation for workflow artifacts |
| Hooks | 7 | Optional quality gates (Claude Code via `install-sigmahq.sh`) |
| Boilerplates | 7+ | Pre-configured project scaffolds |
| Run Track | 8 tracks / 64 steps | Post-ship operating departments (`/run-marketing` … `/run-legal`) — see [docs/run-track/README.md](docs/run-track/README.md) |
| SigmaHQ | legacy | Optional compatibility extension; not the active task board |

**Canonical paths (OSS):** `steps/` → `commands/` · `.agents/skills/` · `src/skills/` · `src/agents/` · `AGENTS.md` · `.sigma/backlogs/`

There is **no** `platforms/*` or `.claude/commands/` mirror tree in the install contract. If you see those from an old checkout, delete them — see [docs/PLATFORMS.md](docs/PLATFORMS.md).

---

## Prerequisites

`git`, `node` >= 20, `python3` (3.12+ recommended; the optional brain layer requires it), and `jq` (recommended — installers fall back to python3 where possible). Everything else ships in the repo.

One-command install: `bash scripts/install.sh`. The steps below cover manual setup. The legacy `--all` option includes SigmaHQ compatibility tooling and is not needed for the current task-tracking workflow.

## First-Time Repo Setup

From the repo root:

```bash
# Render steps into importable commands
bash scripts/sync-steps-to-platforms.sh --prune

# Refresh step-* skill pointers (.agents + .codex compatibility)
python3 scripts/sync-agents-step-pointers.py

# Validate wiring (must pass before you trust the install)
node scripts/verify/validate-step-wiring.mjs
bash scripts/audit-platform-parity.sh
```

Import files under `commands/` into your agent CLI (slash commands). Claude Code reads the repository's `CLAUDE.md`, which imports `@AGENTS.md`; Codex reads `AGENTS.md` and uses its native skill/tool adapters. Neither CLI inherits the other CLI's local permissions or hooks.

---

## Verify Your Install

```bash
bash scripts/doctor.sh    # runs every validation gate, one PASS/FAIL summary
```

Green across the board = canonical surfaces are aligned. (The doctor wraps `validate-cascade`, `validate-skills`, step parity, wiring, run-track, and the drift lints — run any of them individually for details.)

---

## Legacy SigmaHQ compatibility (optional)

SigmaHQ is a legacy operator extension installed under `~/.commandboard/`. This repository tracks tasks in Linear; a consuming project records its own supported tracker. SigmaHQ is not required to run the protocol or to use Claude Code and Codex.

```bash
./scripts/install-sigmahq.sh
```

See [docs/SIGMAHQ.md](docs/SIGMAHQ.md) for missions, troubleshooting, and `--force` upgrades.

---

## Your First Move — the guided-tour prompt

**Open your agent CLI in the repo and paste this.** It makes the agent read the rules, then walk you through every step and teach you as you go:

```text
I'm new to Sigma Protocol. Be my guide and my teacher.

1. Read GETTING-STARTED.md, AGENTS.md, and docs/WORKFLOW-OVERVIEW.md in this repo.
2. Explain to me, in plain words, what Sigma Protocol is and how the steps work.
3. Ask me what I want to build. Then start Step 0 (environment setup) and Step 1 (ideation).
4. Walk me through EVERY step in order — 0 through 15, plus 1.5 and 11.5 when they apply.
   For each step:
   - First tell me what this step is for and what we will make, in one short paragraph.
   - Work one phase at a time.
   - STOP at every gate and ask me the gate question. Wait for my real answer.
     Never skip ahead, never answer for me. If I go quiet, pause until I am back.
   - When the step is done, run its verification and show me the score before moving on.
5. After each step, give me a two-sentence recap: what we made, and why it matters.
6. When Step 15 is approved, ask if I am ready for go-to-market, then hand off to /gtm.
```

Already know the ropes? Jump straight in:

```
/step-0-environment-setup   # validate your environment
/step-1-ideation            # start product discovery
```

### Expect questions — that's the design

Every step is split into phases, and every phase ends with a **gate**: a question only you can answer. The agent must stop, ask, and wait. If it ever races ahead without asking, point it at the **HITL Gate Contract** at the top of the step file — skipping gates is a bug, not a feature. The only way to turn gates off is telling the agent, up front, "run without stopping."

---

## The Step Path (0–15)

| Phase | Steps | What Gets Built |
|-------|-------|-----------------|
| **Planning** | 0 – 4 | Environment, ideation, offer (if monetized), architecture, UX, flows |
| **Design** | 5 – 8 | Wireframes, design system, interface states, technical spec |
| **Shape** | 9 – 11.5 | Landing page (optional), feature breakdown, PRDs, task handoff |
| **Runtime** | 12 – 15 | Context engine, skillpack, agent runtime, observability contract |
| **Go-to-market** | after 15 | `/gtm` conducts the 8 Run Tracks (`/run-legal` … `/run-marketing`), 64 business steps |

Each step produces a locked artifact. Later steps read from earlier ones.

**Backlog commands (after Steps 5 and 11):**

```bash
/prd-json --mode prototype        # after Step 5 wireframes
/prd-json --mode implementation   # after Step 11 PRDs
/prd-orchestrate                  # optional parallel plan
```

**Pre-built loops (iterate-until-done, bounded, evidence-out):**

```bash
/step-loop --step=N   # verify → fix → re-verify a step until it passes
/gap-loop             # gap analysis until 2 consecutive clean rounds
@dev-loop             # build every approved PRD in dependency order
/run-loop             # the GTM daily cadence (post-Step-15)
```

Loops never answer gate questions for you — decisions still stop and wait.

---

## Jumping Back In

```
/status
```

Shows current step, completed artifacts, and suggested next command.

```
/continue
```

Resumes from the strongest unfinished backlog or PRD source.

---

## Agent CLI Notes

Sigma ships **one canonical tree**. Any CLI can consume it:

| Surface | Path |
|---------|------|
| Step sources | `steps/` |
| Slash commands | `commands/` |
| Skill pool | `.agents/skills/` |
| Project brain | `AGENTS.md` (Claude Code reaches it through `CLAUDE.md` → `@AGENTS.md`) |
| Machine backlogs | `.sigma/backlogs/` |

Platform-specific folders (`.claude/`, `.codex/`, `.cursor/`, `.factory/`) are **operator-local optional config**, not generated mirrors. Details: [docs/PLATFORMS.md](docs/PLATFORMS.md).

---

## Questions

- Full docs: `docs/` in this repo
- Command index: [docs/COMMANDS.md](docs/COMMANDS.md)
- Upgrades: [docs/UPGRADING.md](docs/UPGRADING.md)
- Issues: GitHub Issues on this repo
