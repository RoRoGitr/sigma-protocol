# Sigma Protocol Plugin System

The plugin system packages Sigma's authored source plus Claude-facing runtime surfaces into a distributable format. It is an **alternative distribution channel**, not a replacement for the CLI workflow.

## Overview

The plugin builder collects:
- authored skills from `src/skills/` (with `.agents/skills/` fallback)
- authored agents from `src/agents/`
- rendered commands from `commands/` (with operator-local `.claude/commands/` fallback if present)
- Claude-facing hooks and rules from `.claude/` (operator-local)

It packages them into `dist/plugin/` with a manifest file (`plugin.json`).

## Building

```bash
# Build with auto-dated version
./scripts/plugin/build-plugin.sh

# Build with specific version
./scripts/plugin/build-plugin.sh 1.0.0

# Dry run (no files written)
DRY_RUN=true ./scripts/plugin/build-plugin.sh
```

## Output Structure

```
dist/plugin/
├── plugin.json          # Manifest with component counts and metadata
├── skills/              # Authored skill folders, each with SKILL.md
├── agents/              # Authored agent markdown files
├── commands/            # Rendered commands/ (canonical import surface)
├── hooks/               # All .claude/hooks/**/* files
└── rules/               # All .claude/rules/*.md files
```

## Installing in a Project

Copy the plugin contents into your project. Import commands from `commands/` (canonical); copy to `.claude/commands/` only if your Claude Code setup expects that local path:

```bash
cp -r dist/plugin/skills/ /path/to/project/.agents/skills/
cp -r dist/plugin/agents/ /path/to/project/src/agents/
cp -r dist/plugin/commands/ /path/to/project/commands/
# Optional — Claude Code local import path:
# cp -r dist/plugin/commands/ /path/to/project/.claude/commands/
cp -r dist/plugin/rules/ /path/to/project/.claude/rules/
cp -r dist/plugin/hooks/ /path/to/project/.claude/hooks/
```

## Skill Categories

The manifest tracks three skill categories:

| Category | Flag | Behavior |
|----------|------|----------|
| **A: Manual-Only** | `disable-model-invocation: true` | Must type `/skill-name` explicitly |
| **B: Claude-Invocable** | _(default, no flag)_ | Auto-invokes on context match, shows in `/` menu |
| **C: Background** | `user-invocable: false` | Auto-invokes when relevant, hidden from `/` menu |

## Manifest Schema

See `src/plugin/plugin-schema.json` for the full JSON Schema definition.

## Relationship to CLI Workflow

- The CLI workflow (`claude "Run step 1"`) works unchanged regardless of whether the plugin is installed
- The plugin is a packaging convenience for distributing Sigma Protocol to new projects
- `src/skills/` and `src/agents/` remain the authored source of truth
- `commands/` is the canonical slash-command import surface for any CLI
- `.claude/` hooks and rules are operator-local Claude Code runtime config
