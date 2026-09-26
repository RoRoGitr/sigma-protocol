---
name: brain-score
description: "Show vault quality score, trend, and health nudges. Use when the user says '/brain-score', 'vault score', 'brain health', 'how's my brain doing', or 'knowledge base score'."
version: "1.0.0"
tags: [memory, brain, score, health]
---

# Brain Score

Display the current vault quality score and trend from the autoresearch feedback loop.

## Steps

1. Run `uv run --directory scripts python scripts/lint.py --score` via Bash
2. Parse the JSON output
3. Display:
   - Current score (0-100) with breakdown (connectivity, integrity, freshness)
   - Trend: compare to previous scores in the history array
   - Article count
   - Last compile timestamp (from `scripts/last-compile.json`)

## Display Format

```
Brain Score: 72.4 / 100  (^ +1.2 from last run)

  Connectivity: 31.2 / 40  (78% of articles have backlinks)
  Integrity:    28.0 / 30  (1 broken wikilink)
  Freshness:    13.2 / 30  (44% updated in last 30 days)

Articles: 2,037  |  Last compile: 2h ago  |  Trend: ^ improving

7-day history: 71.2 -> 71.8 -> 72.4
```

## Nudges

- If score dropped since last run: "Score dropped -- run /brain-compile to recover"
- If last compile > 24h ago: "Compile overdue -- run /brain-compile"
- If freshness < 10: "Many stale articles -- consider compiling recent sessions"
- If connectivity < 20: "Low connectivity -- articles need more [[wikilinks]]"

## If vault-quality-score.json Does Not Exist

Tell the user: "No score history yet. Run /brain-compile to baseline your vault, then /brain-score to see results."

Score history is stored at `scripts/vault-quality-score.json`.
