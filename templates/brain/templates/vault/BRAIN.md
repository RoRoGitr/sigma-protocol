# AI Brain Vault Behavior Contract

## Identity

This is your persistent knowledge vault. It is the durable layer for session
history, decisions, project gotchas, Q&A, and cross-project patterns.

## Memory Layers

1. **Hot cache** - `hot.md`, compact current context loaded at session start
2. **Vault** - persistent markdown knowledge, queryable mid-task
3. **Project bridge** - `.sigma/memory/` files that point project agents back to this vault

## Folder Map

| Folder | Purpose |
|--------|---------|
| `memory/` | Persistent cross-session facts, organized by topic |
| `sessions/` | Daily session journals |
| `projects/` | Per-project context, decisions, and gotchas |
| `connections/` | Cross-project pattern links |
| `qa/` | Filed query answers |
| `inbox/` | New items that need review |
| `research/` | Daily autoresearch and gap-close outputs |
| `agents/` | Shared agent lessons and reviewed operating notes |

## Rules

1. Every durable note gets frontmatter: `type`, `date`, `status`, `tags`.
2. Use `[[wikilinks]]` for internal references.
3. New unclassified files go to `inbox/`.
4. Prefer editing existing files over creating duplicates.
5. Promote project-local lessons into the vault only when they are useful beyond one task.

## Protocol

- Session start reads `hot.md`, `memory/index.md`, project gotchas, and recent sessions.
- Session end captures high-signal knowledge into `sessions/`.
- Daily research compiles sessions, scores the vault, closes open research gaps, and writes reversible evolution proposals.
- Evolution changes use `verified:false` markers until a person or later review confirms them.
