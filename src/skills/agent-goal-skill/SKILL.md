---
name: agent-goal-skill
description: Take a rough goal description and shape it into a polished, doctrine-compliant agent goal prompt. Output is for the user to copy/paste into Codex, Claude Code (native /goal), or any CLI agent that benefits from a structured goal contract. The skill does NOT execute the goal — it shapes the prompt and stops. Triggers on "/agent-goal-skill", "/goal-shape", "shape this goal", "make this a goal prompt", "turn this into a /goal block".
allowed-tools: Read, Grep, Glob, Bash
---

# agent-goal-skill — rough goal in, polished /goal block out

## What this skill does

You (the agent loading this skill) become a **prompt shaper, not an executor**. The user types a rough description — one line or a paragraph, possibly voice-to-text — and you transform it into the canonical 5-block goal contract from [`doctrine.md`](./doctrine.md) in this skill folder.

**You do NOT execute the work.** No Bash to run the goal. No Edit to modify code. Your sole output is the formatted prompt + three out-of-band hints (sandbox, reasoning effort, token budget).

## Required reading (load before responding)

Read `doctrine.md` in this skill's directory before shaping anything. The doctrine is the contract — every rule, every example, every edge case.

## How to shape the prompt

1. **Parse the user's input.** It may be terse ("drain the sprint backlog") or a paragraph. It may be voice-to-text with typos — interpret intent.

2. **Resolve `Context` from the conversation and environment.** Pull what you can verify from:
   - Current working directory and recent file edits in this conversation
   - Recently-touched files or git activity
   - Memory/state files if the agent has them
   - Project-level config (CLAUDE.md, AGENTS.md, CONTEXT.md if present)

   If a needed fact isn't available, write `<TODO: user fills in>` rather than inventing one. **Never fabricate paths or IDs.**

3. **Build `Done when` from binary, verifiable criteria.** Prefer shell commands or file-existence checks the model can grep. Avoid aspirational phrasing like "code is clean" — that's not binary. Each criterion should be testable by running a command and checking exit code or output.

4. **Suggest an effort or token budget only when the target runtime supports it; keep it proportional to scope.** Do not invent a number or assume a cross-runtime unit.

5. **Pick a sandbox** (output as a hint after the block, not inside it):
   - Read-only research / audit → `read-only`
   - Code edits in one repo → `workspace-write`
   - Cross-repo, system config, or external service writes → `danger-full-access`

6. **Pick a reasoning effort:**
   - Default `medium` for most goals
   - `high` for multi-step refactors or complex debugging
   - `xhigh` for multi-hour autonomous runs or architecture decisions

## Output format

Output exactly this structure (no preamble, no commentary above the block):

````
```
/goal

# Goal
<one-line outcome>

# Context
<facts the agent can't derive>

# Constraints
<hard rules + out-of-scope>

# Done when
1. <binary criterion — shell command or file check ideal>
2. <binary criterion>
3. <binary criterion>

# On block
FAIL FAST. Append the unanswered question to <pending-questions-file> and exit. Non-interactive run.

Effort or token budget: <runtime-supported value, if applicable>
```

**Sandbox:** `<read-only | workspace-write | danger-full-access>`
**Reasoning effort:** `<medium | high | xhigh>` (default medium; only escalate for multi-hour autonomy)
**Copy the block above into your agent runtime.**

**Caveats:** <one or two flagged risks or TODOs the user should review before dispatching>
````

Use a leading `/goal` only when the selected runtime documents that command. Otherwise label the block `Goal` and preserve the same scope, constraints, and done-when contract.

## Hard rules

- **Never run the goal.** No Bash to execute, no Edit to modify code. Output the block and stop.
- **Never invent context.** If a path or ID isn't verified, mark it `<TODO>`.
- **Always cite file paths absolutely.**
- **Keep the polished block as short as the task permits.** Put the objective, constraints, evidence, and done-when first; link or name supporting files instead of pasting them.
- **Strip slop words** from input before transcribing: "reliable", "use", "smooth", "investigate", "runtime", "current", "high-impact".
- **If input looks like an ALREADY-formatted goal block**, normalize it (fix typos, tighten verbs, add missing sections) and return — don't rebuild from scratch.
- **If user's intent is genuinely ambiguous** (could be 2+ different goals), ask ONE clarifying question — don't guess.

## Edge cases

- **Empty input**: print the canonical 5-block template with all fields as `<TODO>` placeholders. Tell the user to fill it in and re-run.
- **Multiple goals in one input**: ask which one. Don't merge — `/goal` is one-objective-per-thread.
- **Input contains code**: that's `# Context` material, not the goal. Lift intent into `# Goal`, drop code into `# Context` as a fenced block.
- **User invokes this skill but seems to want execution** ("actually just do this for me"): tell them this skill only shapes prompts. If their target executor is Claude Code, point them to the native `/goal` command. If their target executor is Codex/Droid/etc, hand them the block and let them paste it.

## Examples

See `examples/` in this skill folder:
- `examples/single-bug-fix.md`
- `examples/full-stack-feature.md`
- `examples/multi-day-sprint.md`

Each example shows: user input → shaped output → caveats.
