---
name: session-continuity
description: "Resume work across Claude Code sessions with context preservation. Use when continuing work from a previous session. Triggers on \'resume session\', \'continue work\', \'session handoff\', \'pick up where\'."
triggers: ["session start", "continue work", "handoff", "context preservation", "where was I", "resume"]
tags: [core, session-management, context, continuity]
department: core
---

# Session Continuity

Techniques to maintain context across AI coding sessions. Prevents the "where was I?" problem and eliminates re-explanation.

## The Problem

Sessions are isolated by default:
- No persistent memory between sessions
- Context resets on new session start
- Developer expects continuity
- Re-explaining wastes time and tokens

## Session Start Protocol

### 1. Load Context Files (Priority Order)

```
1. CLAUDE.md                    # Core project rules
2. Recent git log (5 commits)   # What changed recently
3. git status                   # Current branch and uncommitted work
4. Active task board             # What's in progress
5. Handoff file (if exists)     # Previous session state
```

### 2. Detect Active Work

```bash
# Recent activity
git log --oneline -5

# Current branch and status
git status

# Uncommitted changes
git diff --stat

# Active tasks
cat .tasks.json 2>/dev/null || echo "No task file"
```

### 3. Acknowledge Context

```markdown
# If continuing work:
"Continuing from previous session. Last work: [X]. Current branch: [branch]."

# If new work:
"Starting fresh on [X]. Current branch: [branch]."
```

## Handoff Protocol (Session End)

When a session is approaching context limits or ending, write a checkpoint:

```markdown
# Handoff — {timestamp}

## Current Task
[What was being worked on]

## Progress
- [x] Completed item 1
- [x] Completed item 2
- [ ] In progress: item 3
- [ ] Not started: item 4

## Modified Files
- `path/to/file.py` — Added error handling
- `path/to/test.py` — 3 new test cases

## Key Decisions
- Chose approach X over Y because [reason]
- Discovered constraint: [detail]

## Next Steps
1. [Immediate next action]
2. [Following action]
3. [Final action]

## Blockers
- [Any blockers or open questions]
```

Save to: `{project}/.claude/handoff-{timestamp}.md`

## During Session

### Checkpoint on Major Milestones

After completing a significant sub-task:
1. Commit the work
2. Update task status
3. Write a brief checkpoint note

### Context Compression

When context window is getting full:
1. Summarize completed work into structured format
2. Keep only active task context in detail
3. Reference handoff file for historical context

## State Detection

At session start, detect the project state automatically:

| Signal | Meaning | Action |
|--------|---------|--------|
| Uncommitted changes | Work in progress | Ask before modifying |
| Recent handoff file (<24h) | Previous session state | Read and acknowledge |
| Failed tests in last commit | Broken state | Prioritize fixing |
| Open PR | Review pending | Check PR status |
| Stale branch (>7d behind main) | Needs rebase | Warn user |

## Anti-Patterns

- Starting work without checking git status
- Ignoring handoff files from previous sessions
- Re-reading entire codebase when a handoff exists
- Not writing handoff when approaching context limits
- Assuming previous session state without verification

## When NOT to Use

- Not for single-turn questions — continuity overhead is unnecessary for quick answers
- Not for fresh-start tasks where prior context would mislead
- Not for multi-user handoffs — designed for single-user session chains
- Not for real-time pair programming — optimized for async session resumption

## Related Skills

- `agent-development` — meta
- `agentation` — meta
- `creating-opencode-plugins` — meta
- `bdd-scenarios` — qa

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Bash, Read, Write, Edit
