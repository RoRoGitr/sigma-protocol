# Platform Reference Guide

**Last Updated:** 2026-06-29

---

## Overview

Sigma Protocol is **platform-agnostic**. The OSS install ships canonical sources only — no per-vendor mirror trees.

| Layer | Path | Role |
|-------|------|------|
| Steps (source) | `steps/` | Canonical step contracts with phases, HARD-GATEs, SKILLS-INVOKE |
| Commands (rendered) | `commands/` | Partials expanded; import as slash commands in any agent CLI |
| Skills | `src/skills/<skill>/SKILL.md` | Invoke at the phase listed in each step |
| Agent examples | `src/agents/<category>/<agent>.md` | Project-authored Step 13 examples; currently not a source mirror of the Claude runtime roster |
| Claude runtime roster | `.claude/agents/` | Bundled Claude-specific agents; installable for Claude Code, not a portable runtime contract |
| Project brain | `AGENTS.md` | Step 12 cross-agent context |
| Runtime | `.sigma/runtime/`, `.sigma/memory/`, `.sigma/tools/` | Step 14 scaffold |

**SigmaHQ** is legacy optional compatibility tooling, not the active task board. Do not require it for a Claude/Codex install. If a project deliberately retains it, verify that operator extension separately; see [SIGMAHQ.md](SIGMAHQ.md).

### What we removed from the install contract

- Claude Code, Cursor, and Codex **mirror directories** are no longer generated or validated.
- Operator-local paths (external SSDs, personal component vaults) are **not** referenced in canon.
- Exa / Firecrawl MCP requirements are **not** part of research phases — use built-in web search.

Operators may still add their own CLI config locally (hooks, MCP, permissions). Claude Code reads `CLAUDE.md`, which imports `@AGENTS.md`; Codex reads `AGENTS.md` and uses native adapters for skills and tools. Local hooks and permissions are CLI-specific and are not portable Sigma policy.

---

## Quick start (any agent CLI)

```bash
# Render steps → commands/
bash scripts/sync-steps-to-platforms.sh --prune

# Validate wiring
node scripts/verify/validate-step-wiring.mjs
bash scripts/audit-platform-parity.sh

# Run a step (example)
# Import commands/step-1-ideation.md as a slash command, then invoke /step-1-ideation
```

---

## Active workflow

Steps `0-15` plus conditional `1.5` and `11.5`. Canonical backlog:

```text
.sigma/backlogs/prototype/prd.json
.sigma/backlogs/implementation/prd.json
.sigma/orchestration/*
```

See [WORKFLOW-OVERVIEW.md](WORKFLOW-OVERVIEW.md) and root `AGENTS.md` for the full chain.

---

## Skill invocation

When a step lists skills in `<!-- SKILLS-INVOKE -->`:

1. Read `src/skills/<skill>/SKILL.md` at the listed phase.
2. If the skill is missing locally, check `.agents/skills/` (bundled methodology pool) or promote from `templates/skills/`.
3. Never silently skip — state the gap and continue with reduced confidence.

Step 13 emits project-specific skills under `src/skills/` and indexes them in `.sigma/indexes/skills-index.json`, including the **component-library bundle** (`shadcn`, `rn-component-library`, `agentic-ui`, `companion-system`, `motion-landing-design` when stack profile matches).

---

## Validation gates

| Script | Purpose |
|--------|---------|
| `scripts/sync-steps-to-platforms.sh` | Render `steps/` → `commands/` |
| `scripts/lint-step-parity.sh` | SKILLS-INVOKE parity |
| `scripts/verify/validate-step-wiring.mjs` | Partials, skills, forbidden patterns |
| `scripts/audit-platform-parity.sh` | Full canonical parity audit |
| `scripts/lint-deprecated-step-refs.sh` | Forbidden step aliases + legacy execution wording |
| `scripts/audit-oss-drift.sh` | OSS single-surface drift (no `platforms/*` resurrection) |
| `scripts/sync-agents-step-pointers.py` | Refresh `.agents/skills/step-*` + `.codex/skills/step-*` pointers |

---

## Legacy mirrors (deprecated)

Directories such as `platforms/`, `.claude/commands/`, `.cursor/commands/`, `.factory/commands/`, and `.codex/skills/` may still exist in older checkouts. They are **not** updated by the sync script anymore. Delete them locally if you want a clean tree:

```bash
rm -rf platforms/
```

Do not edit mirror files — change `steps/` or `src/skills/` and re-run sync.

### Instruction loading check

Claude Code 2.1.277+ can load AGENTS.md directly under its documented project-instruction setting; earlier or restricted sessions can use the CLAUDE.md import. Keep the import when both files exist. Verify what actually loaded rather than assuming it from the filename. In the September 19 probe, the root import loaded, while a restricted nested launch needed an explicit read of the repository-root AGENTS.md. Launch from the project root or perform that read before acting. See [Claude memory documentation](https://code.claude.com/docs/en/memory) and the [audit receipts](audits/protocol-refresh-2026-09-19/LEDGER.md).
