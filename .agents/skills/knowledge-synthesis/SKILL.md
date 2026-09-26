---
name: knowledge-synthesis
description: "Synthesize research from multiple sources into structured knowledge. Use when consolidating information from research. Triggers on \'synthesize\', \'knowledge base\', \'consolidate research\', \'cross-reference\'."
triggers: ["distill knowledge", "extract insights", "update patterns", "session summary", "learnings", "what worked", "what failed"]
tags: [qa, learning, knowledge-management, patterns]
department: qa
---

# Knowledge Synthesis

Extract, organize, and preserve insights from completed work to enable cross-session learning. Turns one-time discoveries into permanent organizational knowledge.

## When to Use

- After completing a significant feature or sprint
- After debugging a hard-to-find issue
- After discovering a new pattern or anti-pattern
- During retrospectives or post-mortems
- When onboarding (capture what surprised you)

## Pattern File Structure

```
{project}/patterns/
├── what-works.md          # Validated approaches
├── what-fails.md          # Documented failures and why
├── architecture-decisions.md  # ADRs in lightweight format
└── gotchas.md             # Non-obvious traps and workarounds
```

## Extraction Protocol

### Step 1: Identify Outputs

After a work session, scan for:
- Files created or modified
- Tests added
- Errors encountered and resolved
- Decisions made (and alternatives rejected)
- Surprises or unexpected behaviors

### Step 2: Categorize Insights

| Category | Target File | What to Extract |
|----------|------------|-----------------|
| Success patterns | `what-works.md` | Approaches that solved the problem well |
| Failure patterns | `what-fails.md` | Approaches that failed, with reasons |
| Architecture decisions | `architecture-decisions.md` | Design choices with rationale |
| Non-obvious traps | `gotchas.md` | Footguns, quirks, silent failures |

### Step 3: Format Entry

```markdown
### [Short descriptive title]
**Date**: YYYY-MM-DD
**Context**: [What problem was being solved]
**Finding**: [What was discovered]
**Evidence**: [File paths, error messages, metrics]
**Recommendation**: [What to do/avoid going forward]
```

### Step 4: Deduplicate

Before adding a new entry:
1. Search existing pattern files for similar content
2. If duplicate exists, update the existing entry with new evidence
3. If related but different, cross-reference with a link

## What-Works Entry Template

```markdown
### Eager loading eliminates N+1 in order listing
**Date**: 2026-03-20
**Context**: Order list endpoint was making 200+ DB queries
**Finding**: SQLAlchemy `selectinload` reduced to 2 queries, 10x speedup
**Evidence**: `api/orders.py:45` — response time dropped from 2.1s to 180ms
**Recommendation**: Always use eager loading for list endpoints with relations
```

## What-Fails Entry Template

```markdown
### Redis cache without TTL causes stale data in user profiles
**Date**: 2026-03-20
**Context**: User profile updates weren't reflected for hours
**Finding**: Cache-aside pattern without TTL meant data only refreshed on cache eviction
**Evidence**: User #4521 support ticket, `services/cache.py:23`
**Root Cause**: Missing `ex=300` parameter in `redis.set()`
**Recommendation**: Every `redis.set()` MUST have an explicit TTL. Add to linter rules.
```

## Gotcha Entry Template

```markdown
### SQLAlchemy async sessions can't be shared across tasks
**Date**: 2026-03-20
**Context**: Background Celery task was failing with "session is closed"
**Finding**: Async sessions are bound to the event loop that created them
**Trap**: Passing a session object to a Celery task seems natural but silently fails
**Fix**: Create a new session inside each task function
```

## Anti-Patterns

- Writing vague entries ("it didn't work")
- Skipping the "why" — always explain root cause
- Duplicating entries instead of updating existing ones
- Only capturing failures — successes are equally valuable
- Writing entries that are too project-specific to be reusable

## When NOT to Use

- Not for code generation — synthesizes research into structured knowledge
- Not for real-time data aggregation — point-in-time knowledge synthesis
- Not for project documentation — cross-domain knowledge organization
- Not for brainstorming — consolidates existing information, not ideation

## Related Skills

- `address-sanitizer` — security
- `audit-context-building` — security
- `audit-prep-assistant` — security
- `brainstorming` — core

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Grep, Glob
