# Claude Code Hook Reference

Complete reference for Claude Code hooks as of 2026. Hooks are shell scripts or commands that execute at specific lifecycle points during a Claude Code session.

## Configuration

Hooks are defined in `.claude/settings.json` under the `"hooks"` key. Each hook event maps to an array of hook groups, where each group can include a `matcher` (for tool-scoped events) and an array of hook commands.

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolName",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/your-hook.sh\""
          }
        ]
      }
    ]
  }
}
```

**Matcher** is optional. When present, the hook only fires for the specified tool (e.g., `"Bash"`, `"Write"`, `"Edit"`). When absent, the hook fires for all tools under that event.

---

## Exit Code Contract

Every hook communicates its result through its exit code:

| Exit Code | Meaning | Behavior |
|-----------|---------|----------|
| **0** | **Pass** — hook succeeded | Operation proceeds normally |
| **1** | **Block** — hook rejected the operation | Claude aborts the action and reports the error to the user |
| **2+** | **Ignore** — hook is not applicable | Hook treated as not present; operation proceeds |

Use exit 0 for observer hooks that only log. Use exit 1 for gate hooks that enforce policy. Use exit 2 when a hook determines it does not apply to the current context (wrong file type, wrong tool, etc.).

---

## Hook Data Payload

Every hook receives these environment variables:

| Variable | Type | Description |
|----------|------|-------------|
| `CLAUDE_SESSION_ID` | string | Unique identifier for the current session |
| `CLAUDE_PROJECT_DIR` | string | Absolute path to the project root |
| `CLAUDE_CWD` | string | Current working directory |
| `CLAUDE_PERMISSION_MODE` | string | Current permission level (`default`, `plan`, `acceptEdits`, `dontAsk`, `bypassPermissions`) |
| `CLAUDE_HOOK_EVENT_NAME` | string | Name of the event that triggered this hook |
| `CLAUDE_AGENT_ID` | string | Identifier of the agent running the hook |
| `CLAUDE_AGENT_TYPE` | string | Agent type: `lead`, `teammate`, or `subagent` |
| `CLAUDE_TRANSCRIPT_PATH` | string | Path to the current session transcript file |

### Tool-Specific Variables (PreToolUse / PostToolUse)

| Variable | Type | Description |
|----------|------|-------------|
| `CLAUDE_TOOL_NAME` | string | Name of the tool being called (e.g., `Bash`, `Write`, `Edit`) |
| `CLAUDE_TOOL_INPUT` | string | Tool input parameters (JSON or plain text) |
| `CLAUDE_TOOL_OUTPUT` | string | Tool output (PostToolUse only) |
| `CLAUDE_FILE_PATH` | string | File path for Write/Edit/Read tools |

### Event-Specific Variables

| Variable | Event | Description |
|----------|-------|-------------|
| `CLAUDE_WORKTREE_PATH` | WorktreeCreate/Remove | Absolute path of the worktree |
| `CLAUDE_WORKTREE_BRANCH` | WorktreeCreate/Remove | Branch checked out in the worktree |
| `CLAUDE_CONFIG_PATH` | ConfigChange | Path of the changed config file |
| `CLAUDE_CONFIG_CHANGE_KIND` | ConfigChange | `created`, `updated`, or `deleted` |
| `CLAUDE_INSTRUCTIONS_LOADED` | InstructionsLoaded | JSON array of loaded instruction sources |
| `CLAUDE_ELICITATION_ID` | Elicitation/Result | Unique ID of the elicitation prompt |
| `CLAUDE_ELICITATION_TYPE` | Elicitation/Result | Type of elicitation (`confirm`, `input`, `select`) |
| `CLAUDE_ELICITATION_RESULT` | ElicitationResult | User's response to the elicitation |

---

## All 23 Hook Events

### Session Lifecycle

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **SessionStart** | Once when a Claude Code session begins | Observer |
| **SessionEnd** | Once when a Claude Code session ends (explicit exit or timeout) | Observer |
| **Stop** | When Claude stops generating (before returning control to user) | Observer |
| **PreCompact** | Before context compaction at ~85% capacity | Observer |
| **PostCompact** | After context compaction completes | Observer |

### Tool Lifecycle

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **PreToolUse** | Before any tool call executes (supports `matcher` for specific tools) | Gate |
| **PostToolUse** | After any tool call completes (supports `matcher` for specific tools) | Observer/Transformer |

### Agent Lifecycle

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **SubagentStart** | When a subagent is spawned (via Task tool) | Observer |
| **SubagentEnd** | When a subagent completes or is terminated | Observer |
| **TeammateJoin** | When a teammate joins the current team | Observer |
| **TeammateLeave** | When a teammate leaves the current team | Observer |
| **TeammateIdle** | When a teammate has no pending work | Observer |

### Task Lifecycle

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **TaskCreated** | When a new task is created (via TaskCreate tool) | Observer |
| **TaskCompleted** | When a task is marked as completed | Observer |
| **TaskFailed** | When a task fails or is cancelled | Observer |

### Worktree Lifecycle (2026)

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **WorktreeCreate** | After `git worktree add` succeeds | Gate/Observer |
| **WorktreeRemove** | After `git worktree remove` succeeds | Gate/Observer |

### Configuration Lifecycle (2026)

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **ConfigChange** | When CLAUDE.md, settings.json, .claude/rules/*.md, or .mcp.json changes | Gate/Observer |
| **InstructionsLoaded** | After all instruction sources are resolved for a task | Observer |

### Elicitation Lifecycle (2026)

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **Elicitation** | When Claude prompts the user for input (confirm/input/select) | Gate |
| **ElicitationResult** | When the user responds to an elicitation prompt | Observer |

### Notification Lifecycle

| Event | When It Fires | Pattern |
|-------|---------------|---------|
| **Notification** | When Claude Code emits a notification (completion, error, etc.) | Observer |

---

## Hook Patterns

### Gate Pattern

Gates **block or allow** an operation. They return exit 0 to allow, exit 1 to block. Use for policy enforcement.

```bash
#!/usr/bin/env bash
# Gate: block PR creation if file budget exceeded
set -euo pipefail

TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Only check gh pr create commands
if ! echo "$TOOL_INPUT" | grep -q "gh pr create"; then
    exit 0  # not relevant — allow
fi

CHANGED=$(git diff --name-only origin/main...HEAD | wc -l)
if [[ "$CHANGED" -gt 90 ]]; then
    echo "ERROR: PR has $CHANGED changed files (limit: 90). Split into stacked PRs." >&2
    exit 1  # block the PR creation
fi

exit 0  # within budget — allow
```

**When to use:** PreToolUse (block before execution), WorktreeCreate (enforce branch naming), ConfigChange (prevent deletion of critical files), Elicitation (validate prompts before showing to user).

### Observer Pattern

Observers **log or notify** without affecting the operation. They always return exit 0.

```bash
#!/usr/bin/env bash
# Observer: log session metadata on end
set -euo pipefail

SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

echo "{\"session\":\"$SESSION_ID\",\"ended\":\"$TIMESTAMP\"}" \
    >> "$PROJECT_DIR/docs/sessions/session-metadata.jsonl"

exit 0
```

**When to use:** SessionStart/End (logging), PostToolUse (tracking), TaskCompleted (notifications), InstructionsLoaded (audit trails), SubagentStart (monitoring).

### Transformer Pattern

Transformers **inject context** back into the conversation by writing JSON to stdout. Claude reads the `additionalContext` field and incorporates it into its next response.

```bash
#!/usr/bin/env bash
# Transformer: remind about frontend skills when editing UI files
set -euo pipefail

FILE_PATH="${CLAUDE_FILE_PATH:-}"
EXT="${FILE_PATH##*.}"

if [[ "$EXT" == "tsx" || "$EXT" == "jsx" ]]; then
    cat << 'EOF'
{
  "additionalContext": "This is a UI file. Consider using @frontend-design skill."
}
EOF
fi

exit 0
```

**When to use:** PreToolUse (inject guidance before tool runs), PostToolUse (add context based on results), InstructionsLoaded (supplement loaded rules).

---

## Current Hooks in This Project

### Active Hooks (configured in settings.json)

| Hook File | Event | Matcher | Pattern | Purpose |
|-----------|-------|---------|---------|---------|
| `greptile-pr-hook.sh` | PostToolUse | Bash | Transformer | Detects `gh pr create` output and reminds to run Greptile review |
| `validators/validate-file.sh` | PostToolUse | Write, Edit | Gate | Runs file-type-specific validators after writes/edits |
| `pr-file-budget-preflight.sh` | PreToolUse | (all) | Gate | Blocks `gh pr create` when changed files exceed 90-file budget |
| `ui-skill-enforcement.sh` | PreToolUse | (all) | Transformer | Injects `@frontend-design` reminder when editing UI files |
| `slas/session-end-summary.sh` | SessionEnd | n/a | Observer | Logs session metadata to JSONL |
| `slas/session-start-context.sh` | SessionStart | n/a | Transformer | Injects developer preferences and recent session context |
| `setup-check.sh` | SessionStart | n/a | Gate | Verifies project structure, dependencies, and tool availability |
| `orchestrator-stop.sh` | Stop | n/a | Observer | Polls orchestration inbox for unprocessed messages |
| `team-iterm-launcher.sh` | SubagentStart | n/a | Transformer | Creates iTerm2 split panes for agent team members |
| `task-completed-handler.sh` | TaskCompleted | n/a | Observer | Checks if Devil's Advocate or Gap Analyst tasks are unblocked |
| `teammate-idle-handler.sh` | TeammateIdle | n/a | Observer | Surfaces unblocked pending tasks when a teammate goes idle |

### Template Hooks (not yet in settings.json)

| Hook File | Event | Pattern | Purpose |
|-----------|-------|---------|---------|
| `worktree-lifecycle.sh` | WorktreeCreate, WorktreeRemove | Gate/Observer | Auto-setup worktrees, enforce branch naming, cleanup on remove |
| `config-change-handler.sh` | ConfigChange | Gate/Observer | Audit config changes, block critical file deletion, validate JSON |
| `instructions-loaded-observer.sh` | InstructionsLoaded | Observer | Audit which rules load per agent, detect unexpected sources |

### Supporting Files

| File | Purpose |
|------|---------|
| `lib/iterm-applescript-helpers.sh` | AppleScript helpers for iTerm2 window/pane management |
| `lib/iterm-python-bridge.py` | Python bridge for iTerm2 API (fallback) |
| `slas/dna-classifier.sh` | Classifies SLAS distill output as DNA/skill/one-off |
| `validators/validate-file.sh` | Router that dispatches to type-specific validators |
| `validators/prd-validator.py` | Validates PRD markdown structure |
| `validators/typescript-validator.sh` | TypeScript lint/type checks |
| `validators/ui-validation.sh` | UI component validation rules |
| `validators/design-tokens-validator.py` | Design token schema validation |
| `validators/bdd-validator.py` | BDD scenario format validation |
| `validators/csv-validator.py` | CSV structure validation |
| `team-pane-watcher.sh` | Background process that watches for new teammates and creates panes |

---

## Activating Template Hooks

To activate a template hook, add its entry to `.claude/settings.json`. Each template file includes the exact JSON to copy-paste. Example for WorktreeCreate:

```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/worktree-lifecycle.sh\""
          }
        ]
      }
    ]
  }
}
```

Then customize the TODO sections in the hook file for your project's needs.

---

## Writing Custom Hooks

### Checklist

1. Start with `#!/usr/bin/env bash` and `set -euo pipefail`
2. Use `$CLAUDE_PROJECT_DIR` or `$PWD` for paths — never hardcode absolute paths
3. Choose the correct exit code: 0 (pass), 1 (block), 2+ (ignore)
4. For transformers, output valid JSON with `additionalContext` to stdout
5. Send warnings and errors to stderr (`>&2`), not stdout
6. Keep hooks fast — they run synchronously and block Claude's response
7. Make hooks idempotent — they may fire multiple times for the same event
8. Test with `bash -x .claude/hooks/your-hook.sh` before deploying
9. Mark as executable: `chmod +x .claude/hooks/your-hook.sh`

### Common Mistakes

- **Printing to stdout in a gate hook** — Claude interprets stdout as JSON context. Use stderr for error messages in gate hooks, or structure stdout as valid JSON.
- **Forgetting `exit 0` at the end** — if your script exits with a non-zero code due to `set -e` on an unrelated command, Claude treats it as a block.
- **Slow hooks** — hooks run synchronously. A hook that takes 5+ seconds noticeably degrades responsiveness. Move heavy work to background processes.
- **Hardcoded paths** — hooks must work for any user who clones the project. Use `$CLAUDE_PROJECT_DIR`, `$PWD`, or `$HOME` — never absolute paths to a specific user's filesystem.

---

## Further Reading

- [Claude Code Hooks Documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
- `.claude/hooks/` — all hook implementations in this project
- `scripts/hooks/` — minimal logging stubs for orchestration observability
- `.claude/rules/slas-system.md` — SLAS hook architecture
