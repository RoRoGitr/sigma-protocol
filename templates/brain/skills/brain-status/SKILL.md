---
name: brain-status
description: "Show Brain knowledge base health dashboard -- article counts, last compile time, session count, MEMORY.md stats, and recent flush activity. Triggers: brain status, brain health, knowledge status, brain stats, brain dashboard."
version: "1.0.0"
tags: [memory, brain, status, dashboard]
---

# Brain Status

Show a quick health dashboard for the Brain knowledge base.

## When to Invoke

- Start of a work session to see brain health
- After compilation to verify articles were created
- When the user asks "how's my brain?" or "brain status"

## What to Show

Gather and display using the configured vault path (from `.brain-config.yaml` or `BRAIN_VAULT_PATH` env var, default `~/claude-brain/`):

1. **Article Counts** (by directory):
   ```bash
   find $VAULT_PATH/memory -name "*.md" ! -name "_*" | wc -l
   find $VAULT_PATH/sessions -name "*.md" ! -name "_*" | wc -l
   find $VAULT_PATH/projects -name "*.md" ! -name "_*" | wc -l
   find $VAULT_PATH/connections -name "*.md" ! -name "_*" | wc -l
   find $VAULT_PATH/qa -name "*.md" ! -name "_*" | wc -l
   ```

2. **State Info** (from `scripts/brain-state.json`):
   - Last compilation time
   - Total compilation cost
   - Query count
   - Last lint time

3. **MEMORY.md Stats**:
   - Line count of MEMORY.md
   - Number of memory files

4. **Recent Flush Activity** (last 5 lines of flush log):
   ```bash
   tail -5 scripts/flush.log
   ```

## Output Format

```
## Brain Status

| Metric | Value |
|--------|-------|
| Memory articles | N |
| Session journals | N |
| Project articles | N |
| Connections | N |
| Q&A articles | N |
| MEMORY.md lines | N / 200 max |
| Memory files | N |
| Last compile | YYYY-MM-DD HH:MM |
| Total cost | $X.XX |
| Queries run | N |
| Last lint | YYYY-MM-DD HH:MM |

### Recent Flush Activity
(last 5 flush.log entries)
```
