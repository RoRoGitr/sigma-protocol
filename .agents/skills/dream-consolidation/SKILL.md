---
name: dream-consolidation
description: "Autonomous background memory consolidation — Orient/Gather/Consolidate/Prune cycle. Use when implementing agent memory management, background learning, or session-to-session knowledge transfer. Triggers on 'dream mode', 'memory consolidation', 'dream consolidation', 'background learning', 'agent dreaming'."
triggers: ["dream mode", "memory consolidation", "dream consolidation", "background learning", "agent dreaming", "knowledge transfer", "memory pruning"]
priority: medium
tags: [core, memory, consolidation, agent-learning, background-processing]
department: core
---

# Dream Consolidation — Autonomous Background Memory Management

Systematic approach to autonomous memory consolidation during agent idle periods. A background forked subagent reviews past sessions, extracts patterns, resolves contradictions, and prunes stale entries — keeping persistent memory under budget while maximizing knowledge density. Derived from production Dream mode in large-scale agent harnesses (`src/services/autoDream/`, 519K+ lines).

## 1. Dream Mode Overview

Dream mode spawns a background forked subagent that reviews past session history and consolidates persistent memory. It runs when the user is idle — no active conversation, no pending tasks. The dream agent operates under strict safety constraints: read-only bash, no codebase modification, no message sending.

### Core Contract

```
Input:  Current MEMORY.md + referenced files + recent session logs
Output: Updated MEMORY.md + new/updated memory files + pruned stale entries
Budget: 200 lines / ~25KB maximum for MEMORY.md index
Safety: Read-only bash, no code changes, no user-facing messages
```

The dream agent consolidates what the system has learned into a compact, high-signal memory that future sessions can consume efficiently at startup (first 200 lines injected into system prompt).

## 2. Activation Gates

All gates must be met before a dream cycle triggers. If any gate fails, dreaming is deferred.

| Gate | Condition | Why |
|------|-----------|-----|
| **Time elapsed** | >= 24 hours since last dream | Prevents excessive consolidation churn |
| **Session threshold** | >= 5 sessions since last dream | Ensures enough new material to consolidate |
| **Lock not held** | Dream lock file not present | Prevents concurrent dream agents |
| **Feature flag** | Dream mode enabled (GrowthBook: `tengu_onyx_plover`) | Gated rollout, kill switch capability |
| **User idle** | No active conversation for >= 10 minutes | Never interrupts active work |

### Lock Mechanism

```
Acquire: Write lock file with timestamp + agent ID
Hold:    Dream cycle duration (typically 2-5 minutes)
Release: Delete lock file on completion (success or failure)
Stale:   Lock older than 30 minutes = force-release (dream agent crashed)
```

## 3. Four-Phase Dream Cycle

Each dream execution follows a strict four-phase pipeline. Phases execute sequentially — no parallel execution, no phase skipping.

### Phase 1: Orient

Read the current state of persistent memory. Build a mental model of what the system knows.

**Actions:**
- Read `MEMORY.md` index completely
- Read all referenced memory files (follow every link)
- Identify gaps (referenced files that are missing or empty)
- Identify contradictions (entries that conflict with each other)
- Identify stale entries (completed projects still marked active, outdated references)
- Build a categorized inventory: permanent rules, active projects, conventions, references

**Output:** Internal assessment of memory health — what is current, what is stale, what conflicts.

### Phase 2: Gather

Scan recent session logs for new knowledge worth persisting.

**Actions:**
- Read session logs from the period since last dream
- Extract and tag each finding by category:

| Tag | Description | Priority |
|-----|-------------|----------|
| `user_preference` | Explicit user correction or stated preference | Highest |
| `project_fact` | New project detail, endpoint, configuration | High |
| `technical_pattern` | Recurring code pattern, architecture decision | High |
| `feedback` | User correction of agent behavior | Highest |
| `convention` | Naming, formatting, tooling preference | Medium |
| `one_off` | Single-use fact, already in git | Low (skip) |

**Priority order:** corrections > new patterns > confirmations. User corrections are the highest-signal input — they represent explicit feedback that the system got something wrong.

**Output:** Tagged list of findings with source session references.

### Phase 3: Consolidate

Merge findings with existing memory. This is the core synthesis step.

**Rules:**
1. **Update existing files** when new information extends or corrects an existing entry. Do not create duplicates.
2. **Create new files** only for genuinely new knowledge that has no existing home.
3. **Resolve contradictions:** Newer information wins by default. If the contradiction is ambiguous, flag for user review with a `[REVIEW]` marker.
4. **Update MEMORY.md index:** Add new entries, update descriptions, reorganize sections if categories shift.
5. **Cross-reference:** Ensure every memory file is linked from `MEMORY.md`. Orphan files are invisible to agents.

**Merge Strategy:**

```
For each finding:
  1. Search existing memory for related entries (keyword + semantic match)
  2. If match found:
     a. Is the finding newer? -> Update existing entry
     b. Is the finding a contradiction? -> Newer wins, flag if ambiguous
     c. Is the finding a confirmation? -> Skip (already known)
  3. If no match:
     a. Is the finding high-priority? -> Create new memory file + index entry
     b. Is the finding low-priority? -> Skip (not worth the memory budget)
```

**Output:** Updated memory files, updated `MEMORY.md` index.

### Phase 4: Prune

Enforce the 200-line budget on `MEMORY.md`. Memory must stay compact to fit in the system prompt injection window.

**Pruning Priority (remove first):**

| Priority | What to Prune | Reason |
|----------|--------------|--------|
| 1 | Completed project entries | No longer actionable |
| 2 | Code-derivable memories | Can be re-learned from codebase |
| 3 | Superseded entries | Replaced by newer information |
| 4 | Low-signal conventions | Obvious or tooling-enforced |
| 5 | Duplicate references | Same information linked twice |

**Pruning actions:**
- Archive completed project entries to `memory/MEMORY-ARCHIVE.md` (not deleted — moved)
- Remove code-derivable memories entirely (the code is the source of truth)
- Delete superseded entries after verifying the replacement is complete
- Verify all remaining file references point to valid files (dead link cleanup)

**Output:** Pruned `MEMORY.md` within 200-line budget. Archive file updated.

## 4. Memory Quality Rules

Every memory entry must meet these quality standards. The dream agent enforces these during consolidation.

| Rule | Description |
|------|-------------|
| **Named** | Every memory has a descriptive name (not "misc" or "notes") |
| **Described** | Description is specific enough for relevance matching — an agent reading only the description can decide whether to load the full file |
| **Typed** | Category tag: permanent rule, active project, convention, reference |
| **Sourced** | Feedback memories include: the rule + why it exists + how to apply it |
| **No duplicates** | Same fact stored in exactly one place. Cross-reference, do not copy. |
| **Actionable** | Each entry enables a decision or prevents a mistake. Pure trivia is pruned. |

### Feedback Memory Format

Feedback entries (user corrections) follow a strict format:

```markdown
## [Rule Name]
**Rule:** [What to do / not do]
**Why:** [Why the user corrected this — what went wrong]
**Apply when:** [Trigger conditions — when an agent should recall this]
```

## 5. Implementation Pattern

Pseudocode for the dream lifecycle.

### shouldDream()

```python
def should_dream() -> bool:
    if dream_lock_exists() and not dream_lock_stale():
        return False
    if hours_since_last_dream() < 24:
        return False
    if sessions_since_last_dream() < 5:
        return False
    if not feature_flag_enabled("tengu_onyx_plover"):
        return False
    if user_is_active():
        return False
    return True
```

### runDream()

```python
def run_dream():
    lock = acquire_dream_lock()
    try:
        # Phase 1: Orient
        memory_state = read_all_memory_files()
        health = assess_memory_health(memory_state)

        # Phase 2: Gather
        sessions = read_sessions_since(last_dream_timestamp())
        findings = extract_and_tag(sessions)
        findings.sort(key=priority, reverse=True)

        # Phase 3: Consolidate
        for finding in findings:
            match = search_existing_memory(finding, memory_state)
            if match and finding.is_newer:
                update_memory_entry(match, finding)
            elif match and finding.is_contradiction:
                resolve_contradiction(match, finding)  # newer wins
            elif not match and finding.priority >= HIGH:
                create_memory_entry(finding)

        update_memory_index()

        # Phase 4: Prune
        prune_completed_projects()
        prune_code_derivable()
        prune_superseded()
        verify_file_references()
        enforce_line_budget(max_lines=200)

        record_dream_timestamp()
    finally:
        release_dream_lock(lock)
```

## 6. Safety Constraints

Dream mode operates under strict safety boundaries. These are non-negotiable.

| Constraint | Enforcement |
|-----------|------------|
| **Read-only bash** | Dream agent's tool allowlist excludes Write/Edit for code files. Only memory files are writable. |
| **Cannot modify codebase** | No changes to source code, tests, configuration, or infrastructure |
| **Cannot send messages** | No user-facing output, no Telegram/Discord/email, no channel notifications |
| **Lock prevents concurrency** | Only one dream agent runs at a time. Lock file with stale detection. |
| **Graceful abort on user activity** | If the user starts a conversation during a dream cycle, the dream agent checkpoints and exits cleanly |
| **Budget-bounded** | Dream agent has a fixed token budget. If exhausted mid-cycle, checkpoint and defer remaining work. |
| **No network calls** | Dream agent does not fetch external resources. All input comes from local filesystem. |

### Abort Protocol

```
1. User activity detected during dream
2. Dream agent receives abort signal
3. Write checkpoint: which phase, what was completed, what remains
4. Release dream lock
5. Exit cleanly
6. Next dream cycle resumes from checkpoint
```

## 7. Application Patterns

Dream consolidation applies across different product contexts with varying configurations.

### your runtime — "Agent Learns While You Sleep"

The user's agent runs dream consolidation overnight. By morning, the agent has processed all of yesterday's sessions, extracted patterns, and updated its memory. The user experiences an agent that "remembers" without being told.

- Dream interval: 24 hours (Free tier), configurable (Pro/Enterprise)
- Memory budget: 200 lines (standard)
- Focus: user preferences, project conventions, recurring task patterns

### your trading desk — Overnight Trading Pattern Extraction

Trading agents dream between market sessions. Consolidation extracts: winning patterns, losing patterns, market regime characteristics, parameter drift.

- Dream interval: After market close (daily)
- Memory budget: Extended (500 lines for strategy memory)
- Focus: strategy performance, market patterns, risk events
- Special: Quantitative metrics included in memory entries (win rate, Sharpe, drawdown)

### SSS Protocol — Project Decision Consolidation

Development agents consolidate architecture decisions, code patterns, and user corrections across sprint sessions.

- Dream interval: 24 hours (standard)
- Memory budget: 200 lines (standard)
- Focus: architecture decisions, user corrections, code conventions

### Premium Tier Configuration

| Tier | Dream Interval | Memory Budget | Features |
|------|---------------|---------------|----------|
| **Free** | Manual only (user triggers) | 100 lines | Basic Orient/Gather/Consolidate/Prune |
| **Pro** | 24 hours (automatic) | 200 lines | Full cycle + contradiction resolution |
| **Enterprise** | 4 hours (automatic) | 500 lines | Full cycle + cross-project memory + custom tags |

## Quality Gates

- [ ] Dream lock acquired before any memory writes
- [ ] All four phases execute in order (Orient -> Gather -> Consolidate -> Prune)
- [ ] User corrections tagged as highest priority and never pruned
- [ ] No duplicate entries after consolidation
- [ ] MEMORY.md index within 200-line budget after pruning
- [ ] All file references in MEMORY.md point to valid files
- [ ] Archived entries moved (not deleted) to MEMORY-ARCHIVE.md
- [ ] Dream agent used read-only bash only (no code modifications)
- [ ] Checkpoint written on abort (no lost work)
- [ ] Dream timestamp recorded on completion (prevents re-triggering)

## When NOT to Use

- Not for real-time memory updates during active conversation — use direct memory writes instead
- Not for code-level pattern extraction — use linters, static analysis, or agent DNA for code patterns
- Not for cross-agent communication — dream is a single-agent background process, not a messaging system
- Not when session count is below threshold (< 5 sessions) — insufficient data for meaningful consolidation
- Not as a substitute for explicit user feedback — dream extracts implicit patterns, but explicit corrections should be written to memory immediately (not deferred to dream)

## Related Skills

- `agent-spawning-patterns` — core (dream mode is a specific background task pattern within the spawning framework)
- `context-engineering-advanced` — core (memory extraction techniques used in the Gather phase)
- `reducing-entropy` — core (compact memory format that maximizes signal per token)
- `remembering-conversations` — meta (persistent memory patterns that dream consolidation maintains)
- `session-continuity` — core (session logs that dream mode consumes as input)

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Read, Write, Edit, Grep (for memory file discovery and session log scanning), Bash (read-only)
