---
id: 1
title: "Welcome to SigmaHQ — Set Up Your Command Center"
status: todo
priority: high
class: standard
created: "2026-01-01T00:00:00Z"
tags:
  - onboarding
  - sigmahq
---

# Welcome to SigmaHQ

You're looking at your first kanban task. SigmaHQ is now installed at `~/.commandboard/`. Here's how to get oriented in 3 moves.

## Move 1 — Open Your Dashboard

Run this to build and open your live dashboard:

```bash
hq board
```

The dashboard reads every workspace under `~/.commandboard/workspaces/`, aggregates tasks, active missions, and brain dumps, and renders them as a local HTML dashboard. No server needed.

## Move 2 — Create Your First Real Task

Add a kanban task for the actual thing you're working on:

```bash
kanban-md create \
  --dir ~/.commandboard/workspaces/personal \
  --title "My first real task" \
  --status todo \
  --priority high
```

Or add a project workspace for a specific project:

```bash
mkdir -p ~/.commandboard/workspaces/products/my-project
cp ~/.commandboard/workspaces/personal/config.yml \
   ~/.commandboard/workspaces/products/my-project/config.yml
# Edit the config.yml to set the board name
```

## Move 3 — Articulate Your North-Star Outcome

A **mission** is the ceiling above PRDs, sprints, and tasks. It answers "what are we trying to accomplish, and when are we done?"

In Claude Code, run:

```
/mission new
```

This creates a structured mission file at `~/.commandboard/missions/{slug}/` with machine-verifiable success criteria, constraints, and a halt oracle. Once set, every session starts with the mission context injected automatically.

---

**Mark this task done when you've completed all three moves:**

```bash
hq done personal 1
```
