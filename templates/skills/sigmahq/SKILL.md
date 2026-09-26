---
name: sigmahq
description: DEPRECATED (frozen 2026-07-11 — Linear replaced the SigmaHQ kanban). Kept for existing installs only. Use Linear (steps/_partials/linear-tracking.md) for task tracking.
status: deprecated
superseded_by: steps/_partials/linear-tracking.md
---

# SigmaHQ Runtime — DEPRECATED

> **Frozen 2026-07-11.** Linear replaced the SigmaHQ kanban as the Sigma Protocol
> task tracker. Never write new task tracking here — see
> `steps/_partials/linear-tracking.md` and `templates/commandboard/DEPRECATED.md`.
> The content below is preserved for existing installs only.

SigmaHQ is local mission control. The shared data folder is:

```bash
${SIGMAHQ_HOME:-$HOME/.commandboard}
```

Use the shared `hq` command first. Do not call hidden Claude-only hooks from Codex, and do not bypass `kanban-md` for persistent task updates.

## Start Of Session

```bash
hq health
hq today
```

If the dashboard, briefing, schedule, or XP/rank are stale:

```bash
hq sync --no-open
```

## Task Updates

List tasks:

```bash
hq tasks personal
hq tasks products/my-project
```

Move work:

```bash
hq move products/my-project 12 doing
hq done products/my-project 12
```

`hq done` and `hq move` update kanban-md first, then refresh stats, schedule blocks, briefing data, and dashboard output. This keeps Codex and Claude Code on the same board.

## Daily Refresh

Install a local 8 AM refresh:

```bash
hq daily-refresh install --time 08:00
```

Remove it:

```bash
hq daily-refresh remove
```

## Agent Parity Rule

Codex and Claude Code share:

- `hq` CLI
- `SIGMAHQ_HOME`
- `~/.commandboard/workspaces`
- `kanban-md` task files
- generated briefing, schedule, stats, and dashboard files

Claude Code still owns Claude-native slash commands and SessionStart hooks. Codex uses this skill plus the same `hq` CLI. Both write through the same command layer.
