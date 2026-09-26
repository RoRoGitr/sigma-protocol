# Sigma Prompting Methodology

**Status:** active
**Last updated:** `2026-09-19`

## Purpose

Sigma prompts should be directional enough to keep work coherent and open enough to let the agent discover the local codebase correctly.

The baseline pattern is:

1. `Intent`: what needs to be accomplished and why it matters
2. `Direction`: where to look, which patterns to follow, and what constraints apply
3. `Quality bar`: how success is verified

## Core Rule

Prefer discovery-first prompts over brittle path-by-path instructions.

Good:

- "Implement authentication using the existing service and error-handling patterns."
- "Follow the repo's current orchestration structure and regenerate the affected command or runtime adapter from its source."

Bad:

- "Create exactly `src/auth/service.ts` with these methods in this order."
- "Write to the old Ralph backlog files after Step 11."

## Prompt Structure

```md
## Intent
What is changing and why.

## Direction
What code, docs, or artifacts to inspect before editing.
What existing patterns must be preserved.

## Quality Bar
Tests, checks, invariants, or acceptance criteria that must pass.
```

## Platform Layering

The task prompt stays portable. Platform-specific adaptation belongs in the platform layer.

- Codex: concise markdown, profile-aware execution, explicit orchestration boundaries
- Claude Code: command and hook surfaces aligned to the same workflow contract

Model guidance reviewed on September 19, 2026: [GPT-6 Astra](https://developers.openai.com/api/docs/guides/latest-model) and [Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1). The sources checked did not establish Fable 5.2; verify a requested release before assigning it capabilities.

Preserve the same outcome and authority boundaries across hosts. Use native tools, concise progress updates, targeted edits and tests appropriate to the change. Record explicit unattended authorization once; otherwise retain numbered-phase gates. Ask for decisions and evidence, not private reasoning transcripts. Apply examples, XML delimiters or extra review rounds only when they solve an observed problem.

Keep skill descriptions specific and load support material only when needed. Evaluate prompt changes on representative tasks with the same acceptance criteria and record the exact model, host, settings and failures. Static file parity is not evidence of model quality. See [research decisions](audits/protocol-refresh-2026-09-19/SOURCES.md).

## Backlog and Orchestration Language

Use the current nouns:

- `.sigma/backlogs/prototype/prd.json`
- `.sigma/backlogs/implementation/prd.json`
- `.sigma/orchestration/*`
- `schemas/execution-backlog.schema.json`
- `schemas/prd-map.schema.json`

Avoid older Ralph-era nouns in active prompts, except when describing migration or archived history.

**Legacy read-only:** `docs/ralph/*` may still be read for migration compatibility; never write new backlog artifacts there. Canonical machine backlogs live under `.sigma/backlogs/*`.

## Recommended Command Prompting

When asking an agent to operate inside Sigma, specify:

1. the workflow stage or command being used
2. the canonical output path if relevant
3. the verification gate expected before completion
4. the migration/deprecation constraint if legacy inputs may appear

Example:

```md
Run `/prd-json --mode implementation` against the current Step 11 PRDs.
Write the backlog to `.sigma/backlogs/implementation/prd.json`.
Preserve compatibility reads from `docs/ralph/*` if present, but do not write there.
Finish only after validation passes.
```

## Review Expectations

For non-trivial work, Sigma expects:

- a dependency-aware plan
- explicit Devil's Advocate review
- explicit Gap Analysis review
- explicit Testing review
- verification commands with results

## Related Docs

- `docs/WORKFLOW-OVERVIEW.md`
- `docs/PLATFORMS.md`
- `docs/COMMANDS.md`
- `docs/archive/RALPH-LEGACY.md`
