# Agent Runtime

## Normal Language Summary

This document defines the layer that turns a Sigma repo into a live AI working environment.

The goal is simple:
- the top-level agent acts like a lead engineer
- it loads memory and code intelligence first
- it delegates work to specialists
- it requires review and testing before completion

## Why The Runtime Layer Exists

Steps 0 through 13 prepare the repo. Step 14 makes the repo operational for day-to-day agent work.

Without this layer, the user still has to remind the agent which role to take, which tool to prefer, and what context to reload. With this layer, the repo carries those decisions itself.

## Coordinator Policy

The visible top-level agent is coordinator-first.

That means it should:
- understand the request
- load runtime context
- pick the right specialists
- assign implementation work
- review outputs
- decide next actions

That agent should not do implementation work by default when specialist workers are available.

## Review Chain

Every non-trivial implementation path should follow this order:

1. implementation worker
2. Devil’s Advocate review
3. Gap Analysis review
4. Testing review

This review chain is part of the runtime contract, not optional etiquette.

## Graph Provider Contract

Sigma owns the contract. The underlying engine can change.

Required capabilities:
- `index`
- `status`
- `searchSemantic`
- `getSymbolContext`
- `getImpact`
- `getProcessTrace`
- `detectChanges`
- `graphQuery`
- `renameAssist`

Default routing:
- structural and blast-radius questions go to the local graph engine
- semantic enrichment can go to Augment when configured
- exact fallback goes to local retrieval and exact search

## Local Graph Engine Policy

Sigma is local-first.

The runtime may use an authorized local graph-engine codebase as the implementation base or reference, but Sigma-facing surfaces must use Sigma naming and Sigma behavior contracts.

Public runtime artifacts should describe:
- Sigma graph engine
- Sigma graph provider
- Sigma runtime graph layer

They should not expose external engine branding in the normal user workflow.

## Memory Model

Sigma uses three memory tiers.

### Project Memory

Shared, durable, human-readable context.

Location:
- `.sigma/memory/project/`

Examples:
- architecture decisions
- codebase conventions
- agent routing decisions
- known hotspots

### Local Memory

Private, gitignored machine-local state.

Location:
- `.sigma/memory/local/`

Examples:
- temporary notes
- sensitive local context
- machine-specific runtime caches

### User Memory

Optional cross-project memory outside the repo.

Location:
- `~/.sigma/memory/<workspace-slug>/`

Examples:
- personal preferences
- repeated workflows
- reusable heuristics

## Tracked Runtime Sources

Step 14 keeps the tracked source of truth small and explicit.

Tracked runtime sources are:
- `AGENTS.md`
- `CLAUDE.md` (imports `@AGENTS.md`)
- `.claude/settings.json`
- `.codex/config.toml`
- the Step 14 schemas under `schemas/`
- this runtime spec

These files describe how the runtime should work.

## Generated Runtime State

The live runtime scaffold is generated into local repo state under:
- `.sigma/runtime/`
- `.sigma/memory/project/`
- `.sigma/memory/local/`
- `.sigma/tools/`

These are generated working artifacts, not tracked source files.

That matters because the runtime scaffold can change per machine, per session, or per project state without forcing repo-tracked churn.

## Runtime Manifest

The repo-local runtime manifest lives at:
- `.sigma/runtime/runtime.manifest.json`

It must define:
- active platforms
- coordinator mode
- graph provider routing
- memory locations
- review chain

## Delegation Policy

The repo-local delegation policy lives at:
- `.sigma/runtime/delegation-policy.json`

It must define:
- top-level agent mode
- which roles can implement
- which roles can review
- mandatory post-implementation gates

## Helper Tool Contract

The repo-local helper tool layer lives at:
- `.sigma/tools/`

It should contain generated scripts or documented placeholders for:
- linting
- type checking
- test execution
- build verification

These tools are Step 14 outputs. They are runtime infrastructure, not Step 12 instruction outputs.

## Codex Runtime

Codex should load:
- `AGENTS.md`
- `.codex/config.toml`
- `.agents/skills/`
- `.codex/skills/` *(compatibility adapter only)*
- `.sigma/tools/`
- `.sigma/runtime/*`
- `.sigma/memory/project/*`

Optional `.codex/rules/*.rules` files may still exist as repo policy overlays, but they are not the primary Step 12 or Step 14 surfaces.

Codex uses its native skill and tool adapters. It does not inherit Claude Code hooks, permission settings, or agent definitions.

## Claude Code Runtime

Tracked entry point:
- `CLAUDE.md` (imports `@AGENTS.md`)

Optional local Claude runtime file:
- `CLAUDE.local.md` when used

Claude Code should load the live files plus:
- `.claude/settings.json`
- `.claude/skills/`
- `.claude/hooks/`
- `.claude/agents/`
- `.sigma/tools/`
- `.sigma/runtime/*`
- `.sigma/memory/project/*`

Claude Code enforces the runtime through project-local settings, hooks, agents, and MCP routing.

Important distinction:
- `CLAUDE.md` is the tracked entry point and imports the shared project context
- a local `CLAUDE.local.md`, hooks, and permissions do not prove another CLI has the same runtime behavior

## Verification Gates

Before calling the runtime ready:
- the runtime manifest must validate against schema
- delegation policy must enforce coordinator-first behavior
- graph config must be local-first
- memory folders must exist
- Codex and Claude runtime guidance must point to the same runtime contract
- the repo must clearly distinguish tracked runtime sources from generated local runtime state

## Fallback If Step 14 Is Deferred

If the workflow temporarily stays at 13 optimized steps, the Step 14 contract should be folded into:
- Step 0 for prerequisites
- Step 12 for rules and runtime guidance
- Step 13 for authored agents and skills

That is a temporary delivery compromise, not the final model.
