---
name: dispatching-parallel-agents
description: "Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies. Dispatch one agent per problem domain for parallel execution."
version: "1.0.0"
source: "@obra/superpowers"
triggers:
  - orchestrate
  - stream
  - prd-swarm
  - multiple-failures
---

# Dispatching Parallel Agents

## Overview

When you have multiple unrelated problems (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

---

## When to Use

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one can fix others)
- Need to understand full system state
- Agents would interfere with each other (editing same files)

---

## The Pattern

### 1. Identify Independent Domains

Group problems by what's broken:

```markdown
Domain A: Tool approval flow (3 tests)
Domain B: Batch completion behavior (2 tests)
Domain C: Abort functionality (1 test)

Each domain is independent - fixing A doesn't affect C.
```

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass / Fix this issue
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Dispatch in Parallel

```typescript
// All three run concurrently
Task("Fix agent-tool-abort.test.ts failures")
Task("Fix batch-completion-behavior.test.ts failures")
Task("Fix tool-approval-race-conditions.test.ts failures")
```

### 4. Review and Integrate

When agents return:
1. Read each summary
2. Verify fixes don't conflict
3. Run full test suite
4. Integrate all changes

---

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

### Example Prompt

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" 
   - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" 
   - fast tool aborted instead of completed
3. "should properly track pendingToolCount" 
   - expects 3 results but gets 0

These are timing/race condition issues.

Your task:
1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

---

## Common Mistakes

| Mistake | Problem | Better Approach |
|---------|---------|-----------------|
| "Fix all the tests" | Too broad, agent gets lost | "Fix agent-tool-abort.test.ts" |
| No context | Agent doesn't know where | Paste error messages and test names |
| No constraints | Agent can refactor everything | "Do NOT change production code" |
| "Fix it" | You don't know what changed | "Return summary of root cause and changes" |

---

## When NOT to Use

| Situation | Why Not | Alternative |
|-----------|---------|-------------|
| Related failures | Fix one can fix others | Investigate together first |
| Need full context | Understanding requires entire system | Single agent investigation |
| Exploratory debugging | Don't know what's broken yet | Single agent with broad scope |
| Shared state | Agents would conflict | Sequential execution |

---

## Real Example

**Scenario:** 6 test failures across 3 files after major refactoring

**Analysis:**
- agent-tool-abort.test.ts: 3 failures (timing issues)
- batch-completion-behavior.test.ts: 2 failures (tools not executing)
- tool-approval-race-conditions.test.ts: 1 failure (execution count = 0)

**Decision:** Independent domains - abort logic, batch completion, race conditions are separate.

**Dispatch:**
```
Agent 1 → Fix agent-tool-abort.test.ts
Agent 2 → Fix batch-completion-behavior.test.ts
Agent 3 → Fix tool-approval-race-conditions.test.ts
```

**Results:**
- Agent 1: Replaced timeouts with event-based waiting
- Agent 2: Fixed event structure bug (threadId in wrong place)
- Agent 3: Added wait for async tool execution to complete

**Integration:** All fixes independent, no conflicts, full suite green.

**Time saved:** 3 problems solved in parallel vs sequentially.

---

## Verification

After agents return:

1. **Review each summary** - Understand what changed
2. **Check for conflicts** - Did agents edit same code?
3. **Run full suite** - Verify all fixes work together
4. **Spot check** - Agents can make systematic errors

---

## Integration with SSS Protocol

### Multi-agent dispatch
For multi-agent dispatch, use `/sigma-dispatch` (Sigma 3.0). Until that ships, dispatch agents directly via the Agent/Task tool.

### /prd-swarm
PRD swarm execution uses parallel agents per PRD.

### Multiple test failures
When tests fail across different files, dispatch parallel investigators.

---

## Key Benefits

1. **Parallelization** - Multiple investigations happen simultaneously
2. **Focus** - Each agent has narrow scope, less context to track
3. **Independence** - Agents don't interfere with each other
4. **Speed** - 3 problems solved in time of 1

---

*Remember: One agent per independent problem domain. Don't mix concerns.*
