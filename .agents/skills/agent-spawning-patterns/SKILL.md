---
name: agent-spawning-patterns
description: "Agent lifecycle patterns — fork subagent, coordinator/worker, team memory, background tasks. Use when designing multi-agent systems, implementing agent spawning, or building coordinator/worker architectures. Triggers on 'agent spawning', 'fork subagent', 'coordinator worker', 'team memory', 'multi-agent'."
triggers: ["agent spawning", "fork subagent", "coordinator worker", "team memory", "multi-agent", "background task", "agent lifecycle"]
priority: high
tags: [core, multi-agent, orchestration, agent-lifecycle]
department: core
---

# Agent Spawning Patterns — Multi-Agent Lifecycle Management

Systematic patterns for spawning, coordinating, and managing agent lifecycles in multi-agent systems. Covers fork isolation, coordinator/worker architecture, shared memory with security guards, background task patterns, and tool restriction enforcement. Derived from production patterns in large-scale agent harnesses (519K+ lines).

## 1. Fork Subagent Pattern

Parent agents create child agents with fully isolated context. The child receives a fresh conversation window — no inherited state, no shared memory unless explicitly passed.

### Spawn Contract

```
Parent -> Child:
  - Task description (structured prompt with scope + constraints + acceptance criteria)
  - Restricted tool set (explicit allowlist, not full parent capabilities)
  - Abort controller reference (parent can terminate child)
  - Resource budget (max tokens, max turns, timeout)

Child -> Parent:
  - Structured result (JSON or markdown with defined schema)
  - Exit status (completed | failed | timed_out | aborted)
  - Files modified list (for conflict detection)
```

### Resource Isolation

Each subagent operates within its own token budget. The parent's context is not consumed by child execution. This enables parallel fan-out without context pressure on the coordinator.

```
FORK_SUBAGENT flag:
  - Fresh conversation (no parent history)
  - Own token counter
  - Own tool session
  - Cannot access parent's in-memory state
  - CAN access filesystem (shared artifact layer)
```

### Communication Model

Input and output are the ONLY communication channels. No shared variables, no message passing during execution. The parent sends a task prompt, the child returns a structured result. Mid-execution communication happens through filesystem artifacts only (scratchpad files, status files).

## 2. Coordinator/Worker Architecture (COORDINATOR_MODE)

A coordinator agent manages the lifecycle of multiple worker agents through phased execution.

### Phase Progression

```
Phase 1: Research     — Workers gather information, read code, analyze requirements
Phase 2: Synthesis    — Coordinator merges findings, resolves conflicts, produces plan
Phase 3: Implementation — Workers execute assigned tasks in parallel
Phase 4: Verification — Workers validate each other's output, run tests
```

### Phase Gates

The coordinator reviews all worker output before advancing to the next phase. No automatic phase transitions. Workers cannot self-advance the pipeline.

### Scratchpad Communication

Workers share a scratchpad directory for file-based communication. Each worker writes to its own namespace within the scratchpad. Workers read (but never write to) other workers' namespaces.

```
.scratchpad/
  worker-1/
    findings.md
    status.json
  worker-2/
    findings.md
    status.json
  coordinator/
    plan.md
    phase-gate-results.json
```

### Async Messaging

Workers receive task assignments and phase notifications via XML-structured messages:

```xml
<task-notification>
  <type>assignment | phase-advance | abort | status-request</type>
  <from>coordinator</from>
  <to>worker-3</to>
  <payload>
    <!-- Task details, phase info, or abort reason -->
  </payload>
</task-notification>
```

### File Ownership Rule

**File ownership is sacred.** Two agents NEVER edit the same file. The coordinator assigns explicit file boundaries in every task description. If two workers need to modify the same file, the coordinator sequences them (worker A completes, then worker B starts on that file).

Violation of file ownership produces merge conflicts, lost work, and non-deterministic output. Enforce at assignment time, not at merge time.

## 3. Team Memory (TEAMMEM)

Shared memory enables agents to persist and retrieve knowledge across sessions. A secret guard layer auto-redacts sensitive content before storage.

### Secret Guard

The secret guard scans all content written to team memory and automatically redacts:
- API keys and tokens (pattern-matched)
- Passwords and credentials
- Connection strings with embedded credentials
- Private keys and certificates

Redacted entries are replaced with `[REDACTED: <type>]` markers. The original values never enter shared memory.

### Memory Scope Separation

`.claude/agent-memory/` is the disposable Claude-native runtime cache (gitignored). Durable project knowledge belongs in `.sigma/memory/project/` (methodology memory — see Step 12 → *Two memory layers*).

| Scope | Location | Git Status | Visibility |
|-------|----------|------------|------------|
| **Project** | `.claude/agent-memory/` | Gitignored (runtime scratch) | This checkout, all sessions |
| **Local** | `.claude/agent-memory-local/` | Gitignored | This machine only (sensitive data) |
| **User** | `~/.claude/agent-memory/` | N/A | Cross-repo, this user only |

### System Prompt Injection

The first 200 lines of `MEMORY.md` are injected into every agent's system prompt at spawn time. This provides baseline context without consuming the full memory budget. Agents can read the complete memory files on demand.

### Memory Structure

```markdown
# MEMORY.md

## PERMANENT Rules
- [Rule Name](memory/rule-file.md) — Description

## ACTIVE Projects
- [Project Name](memory/project-file.md) — Status, location

## Conventions
- Framework: pnpm (not npm)
- Testing: vitest (not jest)
```

Each referenced file contains the detailed memory entry. The index provides quick relevance matching.

## 4. Background Task Patterns

Agents can execute tasks in the background with different blocking behaviors and progress tracking.

### Task Types

| Type | Behavior | Use Case |
|------|----------|----------|
| **Foreground** | Blocks coordinator until complete | Critical path work, sequential dependencies |
| **Background** | Async notification on completion | Long-running builds, test suites, deployments |
| **Dream** | Autonomous when user idle | Memory consolidation, pattern extraction (see `dream-consolidation` skill) |
| **Shell** | Long-running with progress tracking | Database migrations, large file operations |

### Heartbeat Protocol

Background workers send periodic heartbeat messages to the coordinator:

```json
{
  "worker_id": "worker-3",
  "task_id": "impl-auth-middleware",
  "status": "running",
  "progress": 0.65,
  "last_file_modified": "src/auth/middleware.ts",
  "estimated_remaining": "2 minutes"
}
```

**Silence detection:** If a worker goes silent beyond 2x the expected heartbeat interval, the coordinator probes once. If no response after the probe, the coordinator reassigns the task.

### Shell Task Progress

Long-running shell commands report progress through structured output:

```
[PROGRESS] 45/100 files processed
[PROGRESS] 67/100 files processed
[COMPLETE] 100/100 files processed. Exit code: 0
```

The coordinator parses progress lines to update task status without blocking on completion.

## 5. Agent Tool Restrictions

Tool access is role-based and enforced at the registration level, not by convention.

### Access Tiers

| Role | Tool Access | Spawn Capability |
|------|------------|-----------------|
| **Coordinator** | All tools + spawn subagents | Can create workers, reviewers, specialists |
| **Worker** | Explicit allowlist only | Cannot spawn subagents |
| **Security Agent** | Read-only (Read, Grep, Glob) | Cannot spawn, cannot write |
| **Reviewer** | Read-only + comment tools | Cannot spawn, cannot modify code |

### Enforcement

Tool restrictions are enforced at the registration level. When a worker agent is spawned, its available tool set is fixed. The worker cannot escalate its own permissions or access tools outside its allowlist.

Only coordinators can spawn subagents. This prevents recursive spawn chains and ensures the coordinator maintains a complete view of all active agents.

### Allowlist Pattern

```yaml
# Worker agent definition
tools:
  allowed:
    - Read
    - Write
    - Edit
    - Bash
    - Grep
    - Glob
  denied:
    - TaskCreate  # Cannot spawn subagents
    - TaskUpdate  # Cannot modify other tasks
```

## 6. Spawn Decision Framework

Match the harness complexity to the task, not the other way around.

| Task Scope | Files Changed | Spawn Strategy | Agents |
|------------|---------------|----------------|--------|
| **Trivial** | < 3 files | No spawn — do it directly | 0 (coordinator handles) |
| **Simple** | 3-10 files | Single worker agent | 1 worker |
| **Standard** | 10-30 files | Coordinator + 3-5 workers | 4-6 total |
| **Complex** | 30+ files | Full swarm with reviewers | 8-20 total (max 60 concurrent) |

### Decision Criteria

- **< 5 turns to complete?** Do not spawn. Coordination overhead exceeds parallelism benefit.
- **Independent subtasks?** Spawn parallel workers. Non-blocked slices run simultaneously.
- **Shared state required?** Use scratchpad directory. Never shared in-memory state.
- **Security-sensitive?** Include read-only security reviewer in the swarm.
- **Cross-cutting concerns?** Assign a dedicated integration agent to manage boundaries.

### Scaling Limits

- Max concurrent workers: 60 (validated at 59 workers with 100% success rate)
- Recommended batch size: 10-20 workers per dispatch wave
- Abort threshold: >30% spawn failure rate — stop, diagnose, reduce batch
- Rolling spawn: start 10, wait for health check, then next 10

## 7. Anti-Patterns

Patterns that degrade multi-agent system quality. Avoid these categorically.

| Anti-Pattern | Why It Fails | Correct Pattern |
|-------------|-------------|-----------------|
| Spawning for < 5-turn tasks | Coordination overhead > parallelism gain | Coordinator handles directly |
| Two agents editing same file | Merge conflicts, lost work, non-deterministic output | Sacred file ownership — one file, one agent |
| Agents negotiating with each other | No shared context, circular reasoning, deadlocks | Coordinator resolves all conflicts |
| Relying on agent memory over artifacts | Memory is volatile, compacts, hallucinates | Structured files are source of truth |
| Recursive spawn chains | Exponential resource consumption, no oversight | Only coordinators spawn, max 2 levels deep |
| Workers self-reporting completion | Unverified claims, no evidence | Structured completion report with file:line evidence |
| Spawning without tool restrictions | Workers escalate privileges, spawn rogue agents | Explicit allowlist at registration time |

## Quality Gates

- [ ] File ownership boundaries defined before any worker spawns
- [ ] Every worker has an explicit tool allowlist (not "all tools")
- [ ] Coordinator reviews phase output before advancing pipeline
- [ ] Heartbeat interval set and silence detection configured
- [ ] Structured completion reports required (not free-text "I'm done")
- [ ] Secret guard active on all team memory writes
- [ ] Spawn count within scaling limits (max 60 concurrent)
- [ ] Task assignment includes: scope, constraints, acceptance criteria, file boundaries, dependencies

## When NOT to Use

- Not for single-agent tasks that complete in < 5 turns — coordination overhead is pure waste
- Not for tasks where all changes touch the same 1-2 files — no parallelism possible
- Not for exploratory/research tasks where the scope is undefined — define scope first, then spawn
- Not for debugging sessions where interactive back-and-forth is needed — spawned agents cannot ask clarifying questions mid-execution

## Related Skills

- `dream-consolidation` — core (autonomous background memory consolidation, a specific background task pattern)
- `context-engineering-advanced` — core (context window management for long-running agent sessions)
- `reducing-entropy` — core (token optimization for agent prompts and tool results)
- `dispatching-parallel-agents` — orchestration (parallel agent dispatch patterns)
- `subagent-driven-development` — orchestration (fresh subagent per task workflow)
- `executing-plans` — core (checkpoint-based execution used by worker agents)

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

TaskCreate, TaskUpdate, TaskList, TaskGet, Read, Write, Edit, Bash, Grep, Glob
