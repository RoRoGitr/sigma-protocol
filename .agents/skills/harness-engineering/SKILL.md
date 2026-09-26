---
name: harness-engineering
description: "CLI agent harness architecture — tool systems, permission layers, hook pipelines, context engineering. Use when building agent harnesses, CLI tools with AI capabilities, or extending agent tool systems. Triggers on 'harness', 'agent harness', 'cli agent', 'tool system', 'hook pipeline'."
triggers: ["harness", "agent harness", "cli agent", "tool system", "hook pipeline", "agent tool", "agent architecture"]
tags: [engineering, architecture, agent-harness, tools]
department: engineering
---

# Harness Engineering — CLI Agent Harness Architecture

Production patterns for building CLI agent harnesses with tool systems, layered permissions, hook pipelines, and context management. Derived from a 519K-line TypeScript agent harness (1,916 files, 42 tools, 87 feature flags).

## 1. Tool System Architecture

Each tool is a self-contained directory with a standard structure:

```
src/tools/
  ├── ReadTool/
  │   ├── prompt.ts         # System prompt fragment injected when tool is available
  │   ├── constants.ts      # Tool name, description, max results
  │   ├── inputSchema.ts    # Zod schema for parameter validation
  │   ├── execute.ts        # Core logic with AbortController support
  │   ├── UI.tsx            # Ink (React) component for terminal rendering
  │   └── utils.ts          # Shared helpers
  ├── WriteTool/
  │   └── ...
  └── BashTool/
      └── ...
```

### Tool Registration

Tools register declaratively and are loaded at startup:

```typescript
interface ToolDefinition {
  name: string;
  description: string;
  inputSchema: ZodSchema;          // Zod schema for parameter validation
  prompt(): string;                 // Returns system prompt fragment
  execute(params: Input, opts: {
    abortController: AbortController;
    context: ToolContext;
  }): AsyncGenerator<ToolEvent>;    // Streaming execution
  UI: React.FC<{ events: ToolEvent[] }>;  // Terminal UI component
}

// Registration
const tools: Map<string, ToolDefinition> = new Map();
tools.set('Read', ReadToolDefinition);
tools.set('Write', WriteToolDefinition);
// ...42 total tools
```

### Tool Execution Flow

```
User/Model requests tool
    │
    v
Validate input against Zod schema
    │
    v
Run PreToolUse hooks (may block, modify, or proceed)
    │
    v
Check permissions (mode-based + category-specific)
    │
    v
Execute tool with AbortController
    │
    v
Stream results via AsyncGenerator → render with Ink UI
    │
    v
Run PostToolUse hooks
    │
    v
Return result to conversation
```

### Prompt Injection

Each tool contributes a system prompt fragment via `prompt()`. These fragments tell the model how to use the tool effectively:

```typescript
// ReadTool/prompt.ts
export function prompt(): string {
  return `
    Reads a file from the local filesystem.
    - The file_path parameter must be an absolute path
    - By default, reads up to 2000 lines
    - Results use cat -n format with line numbers starting at 1
  `;
}
```

All tool prompts are concatenated into the system prompt at session start. This is how the model knows what tools exist and how to invoke them.

## 2. Permission System (Layered, 196KB)

### Mode Hierarchy

```
bypassPermissions  →  Everything auto-approved (agent/daemon mode)
       ↑
  acceptEdits      →  File edits auto-approved, bash still prompts
       ↑
      plan         →  Read-only tools auto-approved, all writes prompt
       ↑
    default        →  All tools prompt for approval
```

**Inheritance rule:** Parent agent mode → child inherits. Child can restrict, never expand.

### Bash Permission Pipeline (96KB)

Five layers, evaluated in order. First decisive layer wins:

```
Layer 1: Command Allowlist
  │  Known-safe commands pass without prompt
  │  Examples: ls, git status, pwd, echo, cat (read-only)
  │
Layer 2: Command Blocklist
  │  Always-blocked patterns, no override
  │  Examples: rm -rf /, shutdown, mkfs, dd if=/dev
  │
Layer 3: Dangerous Command Heuristics
  │  Pattern matching for risky operations
  │  Examples: --force, --hard, DROP TABLE, > /etc/
  │  Action: prompt with warning context
  │
Layer 4: Path Validation
  │  Working directory containment
  │  Sensitive path protection (/etc, /usr, ~/.ssh)
  │  Symlink resolution (prevent escape)
  │
Layer 5: Argument Analysis
  │  Flag combinations that change risk level
  │  Examples: git push --force, rm -r (without -f = prompt, with -f = block)
  │  Context-dependent: same command, different risk at different paths
  │
  v
DECISION: allow | prompt | block
```

### Bash Security Layer (100KB)

Separate from permissions — this layer detects attacks:

```
Shell Injection Detection:
  - $() command substitution in arguments
  - Backtick execution in strings
  - Pipe chains to dangerous commands (curl | bash)
  - Semicolon/newline command chaining

Shell Expansion Analysis:
  - Glob bombs (/**/**/**, {a..z}{a..z}{a..z})
  - Brace expansion attacks
  - Variable expansion in unexpected positions

Environment Variable Safety:
  - Blocks modification of PATH, LD_PRELOAD, DYLD_*
  - Detects env -i (clear environment) attempts
  - Validates SHELL, HOME modifications

Heredoc Safety:
  - Scans heredoc content for injection patterns
  - Validates delimiter handling
```

### File Write Permissions

```
Sensitive File Detection:
  .env, .env.*, credentials.json, *.pem, *.key,
  id_rsa, id_ed25519, .npmrc (with tokens),
  settings.json (with secrets), .git/config

Path-Based Rules:
  ALLOW: project directory, /tmp, designated output dirs
  DENY: home dotfiles, system directories, other projects
  PROMPT: everything else

Content Analysis:
  Scan content being written for: API keys, passwords,
  private keys, tokens, connection strings

Diff-Based Approval:
  For edits: show exact diff for review
  For new files: show full content preview
  For overwrites: show before/after comparison
```

### Runtime Permission Prompt

```
┌─────────────────────────────────────────────┐
│ Claude wants to run: git push --force       │
│                                             │
│ ⚠ This is a destructive operation that      │
│   overwrites remote history.                │
│                                             │
│ [Allow] [Deny] [Always Allow for Session]   │
└─────────────────────────────────────────────┘
```

Three responses: `allow` (one-time), `deny` (block + inform model), `always` (session-scoped allowlist addition).

## 3. Hook System

### Hook Types

| Hook | Trigger | Can Block | Can Modify |
|------|---------|-----------|------------|
| PreToolUse | Before any tool call | Yes | Yes (modify args) |
| PostToolUse | After tool completes | No | Yes (modify result) |
| SessionStart | Session begins | No | No |
| SessionEnd | Session ends | No | No |
| Notification | External event | No | No |

### Hook Configuration

```json
// settings.json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash scripts/lint-check.sh $FILE_PATH"
      },
      {
        "matcher": "Bash",
        "command": "bash scripts/sprint-step-guard.sh"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "command": "bash scripts/sprint-step-tracker.sh"
      }
    ],
    "SessionStart": [
      {
        "command": "bash scripts/compact-reinject.sh"
      }
    ]
  }
}
```

### Hook Return Protocol

```typescript
interface HookResult {
  action: 'proceed' | 'block' | 'modify';
  message?: string;       // Shown to model if blocked
  modifiedArgs?: object;  // New args if action is 'modify'
}

// Hook script exit codes
// 0 = proceed
// 1 = block (stderr = message to model)
// 2 = modify (stdout = JSON with modified args)
```

### Hook Composition

Hooks execute in declaration order. First `block` wins. Multiple `modify` hooks chain (each receives previous modification). All hooks see the original tool name and arguments.

```
PreToolUse hooks: [guard, lint, audit]
    │
    guard: proceed ──→ lint: modify(args) ──→ audit: proceed
    │                      │
    │                      └── modified args passed to tool
    │
    guard: block ──→ (lint and audit never run)
```

## 4. Context Engineering

### Compaction Strategies

| Strategy | Trigger | Action | Scope |
|----------|---------|--------|-------|
| Micro-compact | Single message too large | Strip verbosity within one message | Message-level |
| Reactive-compact | Tool result > 25% budget | Truncate + summarize before adding to context | Result-level |
| Context collapse | >60% utilization, old turns | Fold old turns into summary | Session-level |
| Auto-compact | ~80% window usage | Full compaction: extract → summarize → rebuild | Session-level |

### Budget Allocation

```
SYSTEM_PROMPT:    15-20%   (non-compactable)
RECENT_MESSAGES:  30-40%   (keep verbatim, last 5-8 turns)
TOOL_RESULTS:     20-25%   (compactable, newest first)
HISTORY:          remaining (first to compact)
```

### Memory Extraction Before Compaction

Before any Tier 3+ compaction, extract and persist:
- Decisions made (→ MEMORY.md)
- User corrections (→ MEMORY.md, PERMANENT section)
- Configuration learned (→ MEMORY.md or project config)
- File paths referenced (→ handoff file)
- Patterns established (→ agent DNA or skill)

### Post-Compaction Recovery

Inject a `<system-reminder>` after compaction with: current task, files modified, decisions made, current step, what to do next. The compact-reinject hook (SessionStart) handles this automatically.

## 5. Agent Spawning Architecture

### Fork Subagent

```typescript
const child = forkSubagent({
  task: "Implement the auth middleware",
  tools: ['Read', 'Write', 'Edit', 'Bash', 'Grep', 'Glob'],  // restricted
  permissionMode: 'acceptEdits',  // cannot exceed parent's mode
  abortController: new AbortController(),
  maxTurns: 30,  // prevent runaway
});

// Parent waits for structured result
const result = await child.execute();
// result: { status, filesChanged, testsAdded, evidence }
```

### Coordinator/Worker

```
Coordinator (Opus)
    │
    ├── Research Phase → gather context, read files
    │
    ├── Synthesis Phase → create plan, assign tasks
    │
    ├── Implementation Phase → spawn workers in parallel
    │   ├── Worker A (Sonnet) → owns files [a.ts, b.ts]
    │   ├── Worker B (Sonnet) → owns files [c.ts, d.ts]
    │   └── Worker C (Sonnet) → owns files [e.ts, f.ts]
    │   
    │   Workers communicate via scratchpad directory:
    │   .scratchpad/
    │     ├── worker-a-completion.json
    │     ├── worker-b-completion.json
    │     └── shared-context.md
    │
    └── Verification Phase → review worker output, run tests
```

### Team Memory

Shared memory with automatic secret guard:
- Redacts: API keys, passwords, tokens, private keys
- Scopes: `project` (git-committed), `local` (gitignored), `user` (cross-repo)
- Injection: first 200 lines of team MEMORY.md in system prompt at spawn

## 6. Skill System

### Skill Loading Order

```
1. Bundled skills (compiled into binary, always available)
2. Directory-loaded skills (.claude/skills/{dept}/{name}/SKILL.md)
3. MCP skills (loaded from MCP servers at runtime)
```

### Skill Structure

```yaml
---
name: skill-name
description: "What + when + trigger phrases"
triggers: ["keyword1", "keyword2"]
version: 1.0.0
tags: [department, category]
---

# Skill Title
[Content: patterns, code examples, quality gates]
```

### Auto-Invocation

Skills match via trigger phrases in the description and triggers array. When a task contains matching keywords, the skill content is loaded into context automatically.

## 7. Feature Flag Pattern

### Compile-Time (Build Configuration)

```typescript
// Resolved at build time — dead code eliminated
if (feature('BUDDY')) {
  // This entire block removed from builds where BUDDY=false
  registerBuddySystem();
}
```

87 compile-time flags in the reference implementation. Cannot be changed after build.

### Runtime (GrowthBook / Remote Config)

```typescript
const gb = new GrowthBook({
  apiHost: 'https://cdn.growthbook.io',
  clientKey: process.env.GROWTHBOOK_KEY,
  attributes: { userId, plan, org },
});

if (gb.isOn('tengu_kairos')) {
  enableDaemonMode();
}
```

Server-controlled, per-user gating, no redeploy needed.

## Quality Gates

- [ ] Every tool has: inputSchema (Zod), prompt(), execute(), UI component
- [ ] Permission modes form strict hierarchy (child cannot exceed parent)
- [ ] All bash commands pass through 5-layer permission pipeline
- [ ] Shell injection detection covers: $(), backticks, pipes, heredocs
- [ ] Hooks return structured results (proceed/block/modify)
- [ ] Hook composition follows first-block-wins, chain-modify semantics
- [ ] Context budget tracked per message category
- [ ] Memory extracted before any Tier 3+ compaction
- [ ] Subagents receive restricted tool sets and abort controllers
- [ ] File ownership enforced (no two agents edit same file)
- [ ] Skills have: name, description with triggers, version, tags
- [ ] Feature flags documented with lifecycle (create → rollout → cleanup)

## When NOT to Use

- Not for general software architecture — use `senior-architect` or `architecture-patterns`
- Not for specific tool implementation (e.g., a Read tool) — this covers the system, not individual tools
- Not for security auditing — use `permission-engineering` for the security-specific patterns
- Not for context optimization within messages — use `reducing-entropy`

## Related Skills

- `permission-engineering` — security (deep dive into permission layers)
- `context-engineering-advanced` — core (session-level context management)
- `agent-spawning-patterns` — core (multi-agent lifecycle patterns)
- `feature-flag-architecture` — architecture (flag system design)
- `architecture-patterns` — architecture (general patterns)

## Platform Support

Works with: Claude Code, Cursor, Codex, Sigma Factory.
