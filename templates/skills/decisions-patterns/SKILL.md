---
name: decisions-patterns
description: META skill for the decisions.md convention used across all projects. Use when creating a new project's decisions log, recording an architectural decision, reviewing past decisions before changing direction, or locating where decisions are stored in any project. Triggers on: architectural decision, ADR, why did we choose, decisions.md, decision log, binding decision, accepted decision, rejected alternatives.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Decisions Patterns

## When to Use

Use whenever an architectural, tooling, or process decision is made that a future engineer (or agent) would need to understand before changing that system. Also use to find prior decisions before proposing a change — read the relevant `decisions.md` first.

This is a meta-skill: it documents the convention itself, not a domain-specific methodology.

## Core Methodology

Every project in your ecosystem maintains a `decisions.md` file. It is the binding record of why things are the way they are. Reading it before touching a system prevents re-litigating settled decisions and re-introducing rejected alternatives.

The file is authoritative for its project scope. Cross-project decisions live in `your-knowledge-base/memory/decisions.md`.

11+ projects across all categories follow this pattern — it is universal in this ecosystem.

## File Locations

```
Cross-project (binding across all repos):
  your-knowledge-base/memory/decisions.md

Per-project (check before touching any system):
  your-knowledge-base/projects/{project-name}/decisions.md

Examples confirmed:
  projects/my-courses/decisions.md
  projects/my-discord-bot/decisions.md
  projects/my-assistant/decisions.md
  projects/my-lifeos/decisions.md
  projects/my-community-platform/decisions.md  (if present — check)
  projects/my-trading-platform/decisions.md    (if present — check)
```

## Standard Format

Each entry follows this structure:

```markdown
## ADR-NNN: {Title}  (or DEC-NNN: for non-architectural)
**Date:** YYYY-MM-DD
**Status:** accepted | superseded | deprecated | proposed
**Context:** {Why this decision was needed. What problem it solves.}
**Decision:** {What was decided. Be specific.}
**Alternatives rejected:** {What was considered and why it lost.}
**Consequences:** {What this decision implies going forward. What it enables. What it constrains.}
```

The `Alternatives rejected` field is the most valuable part — it prevents future agents from re-proposing solutions that were already evaluated.

## Key Patterns

### Read Before Proposing

Before proposing any architectural change, technology swap, or naming convention change: grep the relevant `decisions.md`. If the system you're about to change has an ADR, your proposal must either:
- Accept the existing decision as a constraint, or
- Explicitly supersede it with a new ADR that documents why the old rationale no longer applies.

Examples from real decisions:
- Example ADR-001: Rust as service foundation (alternatives: Node sidecar, Python backend, pure TS gateway — all rejected). Any proposal to switch to Python means superseding this ADR.
- Example ADR-002: Drizzle + SQLite as data layer. OS Keychain for API keys (never plaintext). Any refactor that moves keys to .env violates this ADR.
- Example DEC-001: Specific tool for all slide decks (with companion DEC-002 for theme). Changes to slide tooling require updating both decisions.

### Cross-Project Decisions

`memory/decisions.md` holds decisions that span multiple repos:

- Private content vs public repository split (never publish internal content directly — extract and sanitize first)
- Platform architecture (agents ARE Claude Code teammates, Python daemon = infrastructure only)
- Cross-model pipeline gate formula and enforcement
- Project organization map (`$HOME/projects/` directory structure)

These are binding across all agents in all sessions. Check `memory/decisions.md` before any cross-project architecture work.

### New Project Bootstrap

When starting a new project, create `projects/{project-name}/decisions.md` at first session:

```markdown
---
type: decisions
project: {Project Name}
date: YYYY-MM-DD
status: active
tags: [project, decisions, {project-slug}]
---

# {Project Name} — Architectural Decisions

## ADR-001: {First major technology or architecture choice}
**Date:** YYYY-MM-DD
**Status:** accepted
**Context:** ...
**Decision:** ...
**Alternatives rejected:** ...
**Consequences:** ...
```

Create this at the first significant architecture decision, not retroactively after implementation.

### Status Lifecycle

- `proposed` → under discussion
- `accepted` → binding, do not violate without a new ADR
- `superseded` → replaced by a newer ADR (reference the replacement)
- `deprecated` → no longer applies (context changed), but not actively replaced

Supersede, don't delete. Deleted ADRs lose the "why we tried this and stopped" context.

### ADR vs Decision Log vs Project Memory

Three overlapping mechanisms — use the right one:

| Type | Location | Content |
|------|----------|---------|
| `decisions.md` | Per-project in your knowledge base | Binding architectural choices, technology selections, naming conventions |
| `memory/decisions.md` | Global knowledge base | Cross-project binding decisions |
| MEMORY.md hot entries | `~/.claude/projects/.../MEMORY.md` | Active session context (transient, not binding) |

Decisions in `decisions.md` should be things an agent needs to know before changing the system. If it's just session context, it belongs in MEMORY.md, not decisions.md.

## Gotchas

- Decisions.md entries sometimes contain stale status — a decision marked `accepted` may have been superseded by a MEMORY.md hot entry without the decisions.md being updated. When there's a conflict, the MEMORY.md hot entry reflects the most recent direction.
- `Alternatives rejected` is often omitted from informal entries. When writing a new ADR, always fill in this field — it's the part that prevents re-litigation.
- Decisions.md can embed operational instructions, not just historical context. For example: "Use impact analysis before refactoring any service command." This is valid and useful.
- Some projects have sparse decisions.md (inferred from index data rather than documented explicitly). Sparse = needs manual review and enrichment.

## Quality Gates

- [ ] `decisions.md` exists before any significant architecture decision is made
- [ ] Every entry has `Alternatives rejected` filled in
- [ ] Superseded decisions reference the replacement ADR
- [ ] Cross-project decisions documented in `memory/decisions.md`, not just project-level
- [ ] decisions.md read before proposing any change to a system with existing ADRs

## Related

- Vault articles: `memory/decisions.md`, `projects/my-project/decisions.md`
- Related skills: `prd-patterns` (PRDs reference decisions for context), `sprint-patterns` (sprint planning reads decisions before proposing architecture changes)
