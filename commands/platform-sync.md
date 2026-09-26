---
description: "Review upstream platform capability drift (Claude Code / Codex releases) against the repo's runtime assumptions"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
  - AskUserQuestion
---

# /platform-sync — Platform Capability Drift Review

Invoke the `platform-sync` skill (`.agents/skills/platform-sync/SKILL.md`) and follow it exactly.

Compare current platform capabilities (Claude Code, Codex) against what `docs/PLATFORMS.md` and the runtime surfaces assume; report drift with evidence and propose doc/config updates. Read-only until the user approves changes.
