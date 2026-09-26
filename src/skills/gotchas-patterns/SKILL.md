---
name: gotchas-patterns
description: 'Use when tracking, writing, reading, or promoting project-specific gotchas. Triggers on: gotchas.md, project gotcha, gotcha tracking, gotcha promotion, hard-won knowledge, lesson learned, re-learning prevention, decisions.md vs gotchas.md, recurring trap.'
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Gotchas Patterns

## When to Use

Use when you encounter a sharp edge, silent failure, or non-obvious behavior in any project — especially one that would be easy to hit again. Also use when deciding whether a gotcha belongs in `gotchas.md` vs `decisions.md`, or when promoting a recurring cross-project trap to a global skill.

## Core Patterns

### File Convention

Every project gets its own gotchas file. Path is always:

```
your-knowledge-base/projects/{project-slug}/gotchas.md
```

Examples:
- `projects/my-ai-tooling/gotchas.md`
- `projects/my-messaging-system/gotchas.md`
- `projects/my-courses/gotchas.md`
- `projects/my-discord-bot/gotchas.md`
- `projects/my-trading-platform/gotchas.md` — per-concept gotchas embedded in relevant concept files

### Entry Format

Each gotcha follows a strict 3-part format:

```markdown
- **{Brief title in bold}** — {one-sentence description of the trap}. {Reproduction context or error symptom}. {Exact fix}. Discovered: {date} {session context}.
```

Requirements:
- Title is machine-parseable (bold, specific — not "weird bug" but "PreCompact hook timeout blocks compaction")
- Description states WHAT the trap is, not just that it exists
- Fix is actionable: a command, a code change, or a config value
- Discovery context anchors when/where it was found

### Gotchas vs Decisions

| File | What Belongs Here |
|------|------------------|
| `gotchas.md` | Non-obvious traps, silent failures, things that bite you when you don't know them. The system works one way when you expect another. |
| `decisions.md` | Intentional architectural choices. The system works this way ON PURPOSE. Rationale for trade-offs. |

Examples:
- `bunx` resolving to ephemeral `/private/tmp/` paths → **gotchas.md** (silent breakage on reboot)
- "We chose Bun over Node for cold start performance" → **decisions.md** (intentional)
- `settings.json` hook entries require `"matcher"` key even when empty → **gotchas.md** (silent failure)
- "Separate MCP per exchange instead of mega-MCP" → **decisions.md** (deliberate design)

### Promotion Path: Project Gotcha → Global Skill

Promote a gotcha when:
1. The same trap appears in 2+ different projects
2. The fix is non-trivial and would take time to rediscover
3. The pattern generalizes beyond one specific project

Promotion process:
1. Write the global skill in `~/.claude/skills/{slug}/SKILL.md`
2. Link the skill from each project's gotchas entry
3. The gotcha entry stays in `gotchas.md` as a pointer to the skill

Current examples of promoted gotchas:
- Service startup race condition (stale daemon) → `operational-patterns` skill
- Background execution silent failure (exit 0, no output) → `operational-patterns` skill
- Single-epoch training convergence → `convergence-patterns` skill

### Gotcha Detection Triggers

Write a new gotcha entry when:
- You spent more than 15 minutes debugging something non-obvious
- An agent made the same mistake twice
- A platform behavior contradicts what the docs imply
- An error returns exit code 0 but produces no output (silent failure signature)
- A config change requires a restart that isn't documented

### Cross-Project Grep Pattern

Before writing a new gotcha, grep to see if it already exists:

```bash
grep -r "brief title keywords" "your-knowledge-base/projects/" --include="gotchas.md"
```

If found in one other project, add a cross-reference. If found in 2+ projects, promote to global skill.

## Gotchas

- **`learnings.md` is the global cross-project gotcha log** — `your-knowledge-base/memory/learnings.md` aggregates hard-won knowledge across ALL projects with project attribution. Check it before starting work in any project to pre-empt known traps.
- **Knowledge systems rot silently** — gotchas.md files with broken internal links, stale project-map references, and unupdated entries erode trust. Run `brain-lint` periodically to catch integrity issues.
- **Partial quality gates are worse than no gates** — a single-line gotcha entry that says "this is a problem" without the fix creates false confidence. Always include the reproduction + fix pair.

## Detection / Indicators

- Debugging the same issue you recall from a prior session → check gotchas.md first
- Agent repeating the same incorrect approach twice → entry needed
- Silent exit 0 with no output → silent failure gotcha candidate
- Configuration change with no visible effect → stale daemon or wrong config gotcha candidate

## File Locations

| Component | Path | Purpose |
|-----------|------|---------|
| Global learnings | `your-knowledge-base/memory/learnings.md` | Cross-project hard-won knowledge |
| AI tooling gotchas | `your-knowledge-base/projects/my-ai-tooling/gotchas.md` | Agent system traps |
| Messaging system gotchas | `your-knowledge-base/projects/my-messaging-system/gotchas.md` | Broker/identity traps |
| Courses gotchas | `your-knowledge-base/projects/my-courses/gotchas.md` | Recording/curriculum traps |
| Discord bot gotchas | `your-knowledge-base/projects/my-discord-bot/gotchas.md` | Bot-specific traps |

## Quality Gates

- [ ] Gotcha entry has: bold title, description, exact fix, discovery date/context
- [ ] Gotchas vs decisions split is correct (trap vs intentional)
- [ ] Cross-project recurrence checked before writing (grep first)
- [ ] Recurring cross-project gotcha promoted to global skill, not just duplicated

## Related

- Vault articles: `memory/learnings.md`, `projects/my-ai-tooling/gotchas.md`
- Related skills: `operational-patterns` (runtime traps), `convergence-patterns` (training traps)
