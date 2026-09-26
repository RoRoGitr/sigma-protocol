---
name: brain-query
description: "Ask the Brain knowledge base a question using index-guided retrieval. No RAG needed -- the LLM reads the structured index and selects relevant articles. Triggers: brain query, ask brain, search brain, what do I know about."
version: "1.0.0"
tags: [memory, brain, query, search]
---

# Brain Query

Ask the Brain knowledge base a question. Uses index-guided retrieval (no vector DB, no RAG) -- the LLM reads the structured index, identifies relevant articles, and synthesizes an answer with wikilink citations.

## When to Invoke

- When the user asks "what do I know about X?"
- Before starting work that has prior decisions recorded
- To check for existing patterns before implementing something new
- When recalling a decision made in a past session

## Commands

```bash
# Ask a question (answer saved to qa/ by default)
uv run --directory scripts python scripts/query.py "What auth patterns do I use across projects?"

# Skip saving the answer back to the vault
uv run --directory scripts python scripts/query.py "What gotchas exist for Convex?" --no-file-back

# Skip the 7-day answer cache
uv run --directory scripts python scripts/query.py "Latest deployment patterns?" --no-cache
```

Note: `--file-back` is the default behavior. Use `--no-file-back` to skip saving answers to the vault. Use `--no-cache` to bypass the 7-day deduplication cache for a fresh answer.

## How It Works

1. Reads `memory/index.md` (the master catalog)
2. Loads all wiki articles into context
3. Claude identifies 3-10 relevant articles
4. Synthesizes answer with `[[wikilink]]` citations
5. Saves answer to `qa/{slug}.md` and updates index (default behavior)

## The Compounding Loop

Every query makes the brain smarter:
- Question asked -> answer synthesized -> answer saved as qa/ article -> next time the topic comes up, the answer is already in the index -> faster, more accurate

## Cost

- Query without file-back: ~$0.15-0.25
- Query with file-back (default): ~$0.25-0.40
