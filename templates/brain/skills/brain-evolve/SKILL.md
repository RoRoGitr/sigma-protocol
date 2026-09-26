---
name: brain-evolve
description: "Detect skill/agent gaps and generate evolution proposals from vault knowledge. Use when the user says '/brain-evolve', 'evolve skills', 'update agents from vault', 'check skill gaps', 'are my agents up to date', 'evolve agents'."
version: "1.0.0"
tags: [memory, brain, evolve, skills, agents]
---

# Brain Evolve -- Stage 4 Autoresearch

Detect gaps between vault knowledge and existing skills/agents. Generate proposals to close them.

## Steps

1. Run `uv run --directory scripts python scripts/evolve.py --detect-only` via Bash
2. Parse the JSON output -- show detection summary
3. If detections found, ask user: "Found N evolution opportunities. Generate proposals? (~$0.50/proposal)"
4. If approved, run `uv run --directory scripts python scripts/evolve.py` (full mode)
5. Display proposals from your vault's `inbox/evolution/` directory
6. For each proposal, ask user to approve or skip
7. Apply approved proposals by reading the proposal content and writing to the target file

## 5 Detectors

| Detector | What it finds |
|----------|---------------|
| Skill Gaps | Tags with 5+ articles but no matching skill |
| Stale Skills | Skills 14+ days behind latest vault knowledge |
| Agent Enrichment | Gotchas not yet in agent DNA |
| Missing Links | Agents without relevant skill connections |
| New Agents | Projects needing dedicated agents |

## Display Format

```
Evolution Scan: 25 opportunities detected

  Skill Gaps:        3  (tags with 5+ articles, no matching skill)
  Stale Skills:      5  (14+ days behind latest vault knowledge)
  Agent Enrichment: 12  (gotchas not in agent DNA)
  Missing Links:     4  (agents without relevant skill connections)
  New Agents:        1  (projects needing dedicated agents)

Top proposals:
  1. [skill_gap] convex-patterns -- 15 articles, 3 projects (confidence: 0.85)
  2. [agent_enrichment] backend-engineer -- 8 missing gotchas from sigma-capital
  3. [skill_stale] auth-patterns -- 23 days behind latest vault article
```

## Nudges

- If 0 detections: "Skills and agents are in sync with vault knowledge."
- If skill_gaps > 5: "High gap count -- consider running full proposal generation."
- If agent_enrichments > 10: "Many agents missing gotchas -- /brain-evolve --apply would batch-update."
