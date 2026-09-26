---
name: brain-lint
description: "Run health checks on the Brain knowledge base. Detects broken wikilinks, orphan pages, stale articles, sparse content, and contradictions. Triggers: brain lint, vault health, check brain, brain health check."
version: "1.0.0"
tags: [memory, brain, lint, health]
---

# Brain Lint

Run 7-point health checks on your Brain Obsidian vault.

## When to Invoke

- Weekly maintenance check
- Before trusting brain answers for critical decisions
- After a large batch compilation
- When the user says "check my brain health"

## Commands

```bash
# Run all structural checks (free, instant)
uv run --directory scripts python scripts/lint.py

# Skip LLM checks (same as default)
uv run --directory scripts python scripts/lint.py --structural-only

# Include LLM contradiction detection (~$0.15-0.25)
uv run --directory scripts python scripts/lint.py --deep

# Auto-fix missing backlinks
uv run --directory scripts python scripts/lint.py --fix
```

## 7 Health Checks

| # | Check | Type | Catches |
|---|-------|------|---------|
| 1 | Broken links | Structural | `[[wikilinks]]` to non-existent files |
| 2 | Orphan pages | Structural | Articles with zero inbound links |
| 3 | Orphan sources | Structural | Session files not yet compiled |
| 4 | Stale articles | Structural | Source session changed since compile |
| 5 | Missing backlinks | Structural | A links B but B doesn't link A |
| 6 | Sparse articles | Structural | Under 200 words |
| 7 | Contradictions | LLM | Conflicting claims across articles |

## Output

Report saved to your vault's `inbox/lint-YYYY-MM-DD.md`.

Show the user a summary: error count, warning count, suggestion count, and the top 5 issues.
