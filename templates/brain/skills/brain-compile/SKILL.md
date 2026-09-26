---
name: brain-compile
description: "Compile session logs into structured knowledge articles in the Brain vault. Runs the LLM compiler to extract concepts, connections, and Q&A from daily session journals. Triggers: brain compile, compile knowledge, build brain, compile sessions."
version: "1.0.0"
tags: [memory, brain, compile, knowledge]
---

# Brain Compile

Compile accumulated session logs into structured, cross-referenced knowledge articles.

## When to Invoke

- End of day to process all captured sessions
- After a major session with many decisions
- When the user says "compile my brain" or "process sessions"
- Automatically triggered by flush.py after 6 PM

## Commands

```bash
# Compile only new/changed session logs (incremental)
uv run --directory scripts python scripts/compile.py

# Force recompile everything
uv run --directory scripts python scripts/compile.py --all

# Compile a specific session file
uv run --directory scripts python scripts/compile.py --file sessions/2026-04-07.md

# Preview what would be compiled
uv run --directory scripts python scripts/compile.py --dry-run

# Also run MEMORY.md eviction after compilation (moves stale entries to vault)
uv run --directory scripts python scripts/compile.py --evict
```

## MEMORY.md Eviction

The `--evict` flag runs `evict.py --execute` after compilation completes. Eviction moves MEMORY.md bullet entries older than 14 days from hot storage (MEMORY.md, read every session) to warm storage (vault `memory/evicted-{slug}.md`, read on demand). This keeps MEMORY.md within the in-context budget.

Run eviction standalone:
```bash
# Preview what would be evicted (dry run, default)
uv run --directory scripts python scripts/evict.py

# Execute eviction with default 14-day threshold
uv run --directory scripts python scripts/evict.py --execute

# Custom age threshold
uv run --directory scripts python scripts/evict.py --days 7 --execute
```

## What Gets Created

- **Project concepts** -- your vault's `projects/{project}/concepts/{topic}.md`
- **Cross-project connections** -- your vault's `connections/{topic}.md`
- **Q&A articles** -- your vault's `qa/{slug}.md`
- **Index updates** -- your vault's `memory/index.md`
- **Build log entry** -- your vault's `build-log.md`

## Cost

~$0.45-0.65 per session file compiled. The compiler uses Opus via Claude Agent SDK with file write tools.

## After Compiling

Report to the user:
- Number of articles created/updated
- Total compilation cost
- Current knowledge base size (article count)
