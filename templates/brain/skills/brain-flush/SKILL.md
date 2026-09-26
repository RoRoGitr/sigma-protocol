---
name: brain-flush
description: "Manually flush current session knowledge to your Brain vault. Use when you want to checkpoint knowledge mid-session without waiting for session end. Triggers: brain flush, save to brain, capture knowledge, flush session, checkpoint brain."
version: "1.0.0"
tags: [memory, brain, flush, knowledge]
---

# Brain Flush

Manually extract knowledge from the current conversation and save it to your configured vault's `sessions/` directory.

## When to Invoke

- Mid-session when important decisions were just made
- Before a risky operation that could fail and lose context
- When the user says "save this to brain" or "remember this"
- After a long research or architecture discussion

## How It Works

1. Extract the last 30 turns from the current conversation
2. Write them to a temp file at `/tmp/brain-flush-manual-{timestamp}.md`
3. Run flush.py to extract knowledge via Claude Agent SDK
4. Append results to today's session file in your vault's `sessions/YYYY-MM-DD.md`

## Execution

### Automatic (preferred)
Hooks fire automatically on PreCompact and session end. No action needed.

### Manual Mid-Session
When the user says "save this to brain" or "brain flush":

1. Summarize the last ~30 exchanges from this conversation into a temp file:
   ```bash
   cat > /tmp/brain-flush-manual-$(date +%Y%m%d-%H%M%S).md << 'CONTEXT'
   CWD: $(pwd)

   [Paste your summary of recent conversation here -- decisions, lessons, gotchas, action items]
   CONTEXT
   ```

2. Run flush:
   ```bash
   uv run --directory scripts python scripts/flush.py /tmp/brain-flush-manual-$(date +%Y%m%d-%H%M%S).md "manual-flush"
   ```

The flush agent extracts structured knowledge and appends to today's session file.

## What Gets Extracted

The flush agent extracts:
- **Decisions Made** -- with rationale
- **Lessons Learned** -- gotchas, patterns, insights
- **Action Items** -- follow-ups and TODOs

Routine tool calls, trivial exchanges, and obvious content are skipped.

## After Flushing

Confirm to the user:
- What was saved (summary of extracted knowledge)
- Where it was saved (session file path)
- Article count in vault
