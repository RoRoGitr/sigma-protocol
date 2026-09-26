# AI Brain Package

This package installs a global markdown-based memory layer for local AI CLIs.
It can use an existing Obsidian vault or a plain folder. The selected path is
stored in `~/.claude/brain/.brain-config.yaml`, and every script reads from that
config instead of hardcoded machine paths.

## What Gets Installed

- `~/.claude/brain/scripts/` - compile, flush, query, evict, evolve, lint, status, hot-cache, autoresearch
- `~/.claude/brain/hooks/` - SessionStart, PreCompact, Stop/SessionEnd hooks
- `~/.claude/skills/brain-*` - seven brain skills
- `~/.local/bin/brain-*` - terminal wrappers such as `brain-status`
- daily cron files - launchd on macOS, systemd user timers on Linux

## Install

From the Sigma Protocol repository:

```bash
scripts/install-brain.sh --yes
```

The installer:

- detects an existing Obsidian vault when available
- falls back to `~/Documents/AI Brain`
- initializes the vault scaffold
- wires Claude Code hooks additively
- checks RTK and prints the manual install command when it is missing
- writes a daily autoresearch timer

## Vault Structure

```text
AI Brain/
  memory/
  sessions/
  projects/
  connections/
  qa/
  inbox/
    evolution/
  research/
  agents/
  hot.md
  build-log.md
```

## Commands

```bash
brain-status
brain-query "What decisions did we make about auth?"
brain-compile
brain-lint
brain-score
brain-evolve --detect-only
brain-evolve --apply
```

## Safety Model

- Session hooks fail open.
- Background workers check the optional `agent-spawn-guard` before spawning.
- Daily autoresearch has a 24-hour cooldown.
- Evolution writes are reversible: generated changes use `verified:false`
  `EVOLVE` blocks or create new files without overwriting existing files.
- Project `.sigma/memory` folders are a bridge into the global brain, not a
  second vault.
