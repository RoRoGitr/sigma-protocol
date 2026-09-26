---
name: skill-name
description: "What this skill does and when to use it. Triggers on 'trigger phrase 1', 'trigger phrase 2', 'trigger phrase 3'."
version: "1.0.0"
department: engineering
triggers:
  - trigger phrase 1
  - trigger phrase 2
  - trigger phrase 3
tags:
  - category-tag
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Skill Name

## When to Use

Describe the scenarios where this skill should be activated. Be specific about:
- What user requests trigger this skill
- What codebase patterns indicate this skill is needed
- What this skill does NOT cover (boundaries)

## Key Patterns

### Pattern 1: [Name]

```typescript
// Real code example from a codebase — not toy examples
// Show the pattern members will actually implement
```

**Why this pattern:** Explain the reasoning, not just the code.

### Pattern 2: [Name]

```typescript
// Another key pattern
```

## File Locations

| Component | Path | Purpose |
|-----------|------|---------|
| Entry point | `src/index.ts` | Main module |
| Config | `config/*.json` | Configuration |
| Tests | `tests/*.test.ts` | Test suite |

## Quality Gates

Before marking work complete, verify:

- [ ] All tests pass
- [ ] Types are correct (no `any` unless justified)
- [ ] No linting errors
- [ ] Edge cases handled
- [ ] [Skill-specific gate 1]
- [ ] [Skill-specific gate 2]

## Common Mistakes

1. **[Mistake]** — [Why it's wrong and what to do instead]
2. **[Mistake]** — [Why it's wrong and what to do instead]

---

## Frontmatter Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Kebab-case skill identifier |
| `description` | Yes | One-line description with trigger phrases embedded |
| `version` | Yes | Semver string (start at "1.0.0") |
| `department` | Recommended | One of: engineering, design, security, marketing, community, ops, core, meta, architecture, qa, tools |
| `triggers` | Recommended | Array of phrases that activate this skill (also embed in description) |
| `tags` | Optional | Category tags for discovery |
| `allowed-tools` | Optional | Restrict which tools this skill can use |
| `source` | Optional | Origin attribution (e.g., "anthropics", "community") |
| `user-invocable` | Optional | Set to `true` if callable as a slash command |

## Naming Convention

Skills follow the pattern: `.claude/skills/{department}/{skill-name}/SKILL.md`

- One skill = one capability (not "backend" — too broad)
- Department groups related skills for discovery
- SKILL.md is the required filename (uppercase)
- Directory name matches the `name` field in frontmatter
