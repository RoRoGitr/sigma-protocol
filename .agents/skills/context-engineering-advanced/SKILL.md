---
name: context-engineering-advanced
description: "Advanced context window management — compaction strategies, memory extraction, context collapse, budget tracking. Use when optimizing agent context usage, implementing compaction, or managing long-running sessions. Triggers on 'context engineering', 'compaction', 'context window', 'context collapse', 'memory extraction'."
triggers: ["context engineering", "compaction", "context window", "context collapse", "memory extraction", "context budget", "reactive compact"]
priority: critical
tags: [core, context-optimization, agent-performance, compaction]
department: core
---

# Context Engineering Advanced — Session-Level Context Window Management

Systematic strategies for managing the full context window lifecycle in AI agent sessions. Covers compaction hierarchies, memory extraction before information loss, post-compaction recovery, and budget allocation. Apply them through the controls the current runtime actually exposes.

## Relationship to `reducing-entropy`

`reducing-entropy` operates at the **content level** — compressing individual messages, code snippets, and documentation before they enter context. This skill operates at the **session level** — managing how the entire context window fills, compacts, and recovers across a long-running conversation. Use both together: `reducing-entropy` shrinks what goes in, `context-engineering-advanced` manages the container.

## 1. Compaction Strategy Hierarchy

Four tiers, each triggered by different conditions. Apply the lightest tier that solves the pressure.

```
Tier 1: Micro-Compact     — single message too large
Tier 2: Reactive-Compact  — tool result exceeds budget
Tier 3: Context Collapse   — old turns folded into summary
Tier 4: Auto-Compact      — approaching window limit
```

### Tier 1: Micro-Compact (Single Message)

**Trigger:** A single message or tool result contains redundant structure (repeated JSON keys, verbose error traces, duplicate log lines).

**Action:**
- Strip repeated patterns within the message
- Collapse verbose tool output (e.g., 500-line grep result to top 20 matches + count)
- Remove decorative formatting (ASCII borders, repeated separators)
- Preserve: error messages, file paths, line numbers, decision-relevant data

**Example:**
```
BEFORE: 847-line npm install output with every package version
AFTER:  "npm install completed. 312 packages. 0 vulnerabilities. 3 warnings: [list]"
```

### Tier 2: Reactive-Compact (Oversized Tool Results)

**Trigger:** A tool call returns more material than is needed for the next decision, or the runtime reports context pressure. Use any token measurement the runtime provides; do not assume a universal threshold.

**Action:**
- Truncate to the most relevant section (first N matches, head of file, relevant function)
- Append a summary line: what was truncated, total size, how to retrieve the rest
- Never silently drop data — the agent must know information was compressed

**Pattern:**
```typescript
// Reactive compact decision flow
if (toolResult.tokens > remainingBudget * 0.25) {
  const truncated = truncateToRelevant(toolResult, query);
  const summary = `[Truncated: ${toolResult.lines} lines -> ${truncated.lines} lines. ` +
                   `Full result available via re-query with narrower scope.]`;
  return { content: truncated.content + '\n' + summary };
}
```

### Tier 3: Context Collapse (Turn Folding)

**Trigger:** Older turns are crowding out the task, or the runtime warns of compaction/context pressure.

**Action:**
- Fold multiple old conversation turns into a single summary turn
- Preserve: decisions made, user corrections, constraints, configuration learned, and outcomes. For append-only conversation histories, summarize the durable state without implying that earlier records were removed.
- Discard: reasoning chains, exploratory dead ends, superseded plans
- Keep the most recent 5-8 turns verbatim (recency bias matters for coherence)

**Summary turn format:**
```markdown
## Session Context (collapsed from turns 1-47)
**Task:** [current objective]
**Decisions:** [list of confirmed decisions with rationale]
**Files Modified:** [path list]
**User Corrections:** [things the user corrected — high priority to preserve]
**Current State:** [where we are in the workflow]
**Blocked By:** [outstanding blockers if any]
```

### Tier 4: Auto-Compact (Window Limit)

**Trigger:** The runtime is approaching its compaction or context limit.

**Action — 3-phase process:**

1. **Extract** — Scan all messages for persistent-worthy information (see Memory Extraction below)
2. **Summarize** — Generate a compact session summary covering task, progress, decisions, and next steps
3. **Rebuild** — Replace the conversation with: system prompt + compaction reminder + recent turns

**Post-compact state:**
```
[System prompt — unchanged]
[Compaction reminder — injected, see section 3]
[Summary of prior conversation — 1 message]
[Last 3-5 turns — verbatim]
```

## 2. Memory Extraction During Compaction

Before ANY compaction tier 3 or 4, run an extraction pass. Information lost during compaction is gone permanently — extraction is the only safety net.

### What to Extract

| Category | Examples | Destination |
|----------|----------|-------------|
| **Decisions** | "We chose Zustand over Redux because..." | `MEMORY.md` or session log |
| **User corrections** | "No, use pnpm not npm" | `MEMORY.md` (PERMANENT section) |
| **Configuration learned** | "The staging server is at..." | `MEMORY.md` or `.env` reference |
| **File paths referenced** | Files read, modified, or planned | Session state / handoff file |
| **Patterns established** | "Always use server actions for mutations" | `MEMORY.md` or agent DNA |
| **Blockers identified** | "Waiting on API key from client" | Kanban board |

### Extraction Pattern

```typescript
// Pre-compaction extraction
function extractBeforeCompact(messages: Message[]): ExtractionResult {
  const decisions = messages.filter(m => containsDecisionLanguage(m));
  const corrections = messages.filter(m => isUserCorrection(m));
  const configs = messages.filter(m => containsConfigInfo(m));
  const filePaths = messages.flatMap(m => extractFilePaths(m));

  return {
    decisions: decisions.map(summarizeDecision),
    corrections: corrections.map(m => m.content),  // keep verbatim
    configurations: configs.map(summarizeConfig),
    filesReferenced: [...new Set(filePaths)],
  };
}
```

### Decision Language Signals

Look for these patterns to identify decisions worth preserving:
- "We'll go with X" / "Let's use X" / "Decided: X"
- "Instead of X, use Y" (user correction — always preserve)
- "The reason is..." / "Because..." (rationale)
- "From now on..." / "Always..." / "Never..." (rules)
- "Configuration: X = Y" / "Set X to Y"

## 3. Compaction Reminders (Post-Compact Injection)

After compaction, the agent loses conversational context. A compaction reminder bridges the gap.

### Injection Format

```xml
<system-reminder>
## Session State (post-compaction)

**Active Task:** [what we are building/doing]
**Current Step:** [where in the workflow — step number, phase, iteration]
**Sprint State:** [read from .sprint-state.json if exists]

**Files Modified This Session:**
- path/to/file1.ts — [what changed]
- path/to/file2.ts — [what changed]

**Key Decisions Made:**
1. [decision + rationale]
2. [decision + rationale]

**User Preferences Learned:**
- [correction or preference]

**What to Do Next:**
- [immediate next action]

**Do NOT:**
- Re-read files already summarized above
- Re-ask questions already answered (see decisions)
- Restart work already completed
</system-reminder>
```

### Compact-Reinject Hook Pattern

A hook that fires after compaction to restore critical state automatically:

```bash
#!/bin/bash
# compact-reinject.sh — runs on SessionStart (covers post-compaction restarts)

# Read sprint state if it exists
if [ -f ".sprint-state.json" ]; then
  echo "Sprint state: $(cat .sprint-state.json | jq -r '.currentStep')"
  echo "Task: $(cat .sprint-state.json | jq -r '.taskId')"
fi

# Read latest handoff if it exists
LATEST_HANDOFF=$(ls -t .claude/handoff-*.md 2>/dev/null | head -1)
if [ -n "$LATEST_HANDOFF" ]; then
  echo "Latest handoff: $LATEST_HANDOFF"
  head -50 "$LATEST_HANDOFF"
fi
```

### Front-Loading Principle

Put stable task facts where the runtime can preserve or retrieve them. Do not assume a particular provider's compaction order or retention behavior:

- **First messages**: Task definition, constraints, acceptance criteria
- **Early messages**: Architecture decisions, file layout, key patterns
- **Middle messages**: Implementation details (compactable)
- **Late messages**: Debugging, iteration (most likely to be compacted)

Critical decisions should be written to persistent storage (MEMORY.md, handoff files) immediately — do not rely on them surviving in context.

## 4. Context Budget Management

### Budget Allocation

```
Total Context Window: 100%

SYSTEM_PROMPT:      runtime-managed — project instructions and rules
RECENT_MESSAGES:    task-relevant turns and current constraints
TOOL_RESULTS:       narrow reads, search results, and command output
HISTORY:            summarized or retrieved only when needed
```

### Token Budget Per Message Category

| Message Type | Max Budget | Compression Strategy |
|-------------|-----------|---------------------|
| System prompt sections | Runtime-managed | Reference by path, not inline content |
| User messages | Preserve constraints and decisions | Summarize only when the runtime compacts history |
| Assistant reasoning | Keep conclusions and evidence | Discard superseded exploration |
| Tool results | Proportionate to the next decision | Read specific lines and narrow queries |

### Efficiency Techniques

1. **Reference over inline**: `"See auth logic in src/auth/service.ts:45-80"` is cheaper than pasting 35 lines.
2. **Structured over prose**: A JSON object or markdown table compresses 40-60% better than equivalent prose.
3. **Incremental reads**: Read 50 lines at a time from large files, not the entire file.
4. **Scoped searches**: `grep pattern src/auth/` not `grep pattern .` — narrower results, fewer wasted tokens.
5. **Deduplication**: If a file was read earlier in the session, reference the prior read instead of re-reading.

### Pressure Monitoring

```
GREEN:  task evidence remains accessible
YELLOW: tool output or history is starting to obscure the next decision
RED:    the runtime reports context pressure or imminent compaction
CRITICAL: a continuation would lose constraints or evidence; write a handoff before proceeding
```

At CRITICAL level, the priority is data preservation over task completion. Write a handoff file with full session state before the context overflows and information is silently truncated.

## 5. Handoff File Protocol

When approaching context limits, write a handoff file that enables a new session to continue seamlessly.

### Handoff File Format

```markdown
# Handoff — {project} — {timestamp}

## Task
[What we were building/doing]

## Progress
- [x] Completed step A
- [x] Completed step B
- [ ] In progress: step C (60% done)
- [ ] Not started: step D

## Files Modified
| File | Change | Status |
|------|--------|--------|
| src/auth/service.ts | Added JWT validation | Complete |
| src/auth/middleware.ts | Rate limiting | In progress — needs tests |

## Decisions Made
1. Using Zustand for state management (Redux too heavy for this scope)
2. JWT tokens expire in 15 minutes (standard security practice)

## Blockers
- None currently

## Next Actions (in order)
1. Write tests for rate limiting middleware
2. Add refresh token rotation
3. Update API documentation

## Sprint State
- Step: [current sprint step]
- Pipeline gates passed: [list]
- Pipeline gates remaining: [list]

## Context for Continuation
[Any nuance that a fresh session needs to know — user preferences, gotchas encountered, non-obvious constraints]
```

### File Location

```
{repo}/.claude/handoff-{YYYYMMDD-HHMM}.md
```

## 6. Implementation Patterns

### Session Lifecycle

```
Session Start
    |
    v
Inject: CLAUDE.md + rules + compaction reminder (if post-compact)
    |
    v
Work loop (read, search, plan, delegate, review)
    |
    +-- Monitor context utilization after every tool call
    |   |
    |   +-- GREEN: continue
    |   +-- YELLOW: trigger Tier 3 collapse
    |   +-- RED: trigger Tier 4 auto-compact
    |   +-- CRITICAL: write handoff, then compact
    |
    v
Session End
    |
    v
Write handoff file + update kanban + update MEMORY.md
```

### Multi-Session Continuity

For tasks that span multiple sessions:

1. **Session N ends**: Write handoff file with full state
2. **Session N+1 starts**: Read latest handoff file, MEMORY.md, sprint state
3. **Session N+1 validates**: Verify files listed in handoff still match expected state
4. **Session N+1 continues**: Pick up from "Next Actions" in handoff

## Quality Gates

- [ ] Context utilization stays below 85% except during active tool execution
- [ ] No information loss on critical decisions after compaction (verify via MEMORY.md)
- [ ] Handoff file written before reaching 80% capacity
- [ ] Session state recoverable from compaction artifacts alone (handoff + MEMORY.md + sprint state)
- [ ] User corrections always survive compaction (extracted to persistent memory)
- [ ] Post-compaction reminder includes: task, step, files modified, decisions, next actions
- [ ] Budget allocation follows the 15/35/25/remaining split within 5% tolerance

## When NOT to Use

- Not for token optimization within a single message — use `reducing-entropy` instead
- Not for prompt engineering or system prompt design — this is session management, not prompt craft
- Not for agent-to-agent communication compression — use structured handoff protocols
- Not for short sessions (<20 turns) where compaction is unnecessary

## Related Skills

- `reducing-entropy` — core (content-level token optimization, complementary)
- `session-continuity` — core (session start/end protocols)
- `executing-plans` — core (checkpoint-based execution that benefits from compaction awareness)
- `remembering-conversations` — meta (persistent memory patterns)

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Write, Edit, Bash (for hook scripts), Grep (for handoff file discovery)
