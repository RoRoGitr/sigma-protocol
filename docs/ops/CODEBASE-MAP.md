# CODEBASE MAP

- Generated: 2026-03-17T19:25:48Z
- Project Root: .
- Repo Shape: monorepo
- Package Manager: npm
- Runtime Signal: claude

## Stack Profile
### Languages
- go
- typescript
- Primary Workload: protocol-authoring

## Entrypoints
### Packages
- packages/_upstream
- packages/sigma-protocol-core
- packages/sigma-protocol-plugin
- packages/sss-harness
### CLI Entrypoints
- cli/sigma-cli.js
- go/cmd/sigma/main.go
### Workflow Surfaces
- steps
- ops
- audit
- dev
- deploy
- marketing

## Data / Auth / Integration Surfaces
### Data
- drizzle
### Docs
- AGENTS.md
- CLAUDE.md.example

## Conventions
### Top-level directories
- audit
- cli
- deploy
- dev
- docs
- drizzle
- experiments
- generators
- go
- landing-page
- marketing
- marketing-book-research
- node_modules
- ops
- packages
- platforms
- schemas
- scripts
- src
- steps
- templates
- tests
- tools
- v2
### Notable signals
- workspace-based
- codex-configured
- claude-configured

## Hotspots
- None detected

## Sigma Readiness
- Mode: protocol-dev
### Present artifacts
- steps
- templates/steps
- packages/sigma-protocol-core
- AGENTS.md
- CLAUDE.md.example
- .codex/config.toml
- .claude/settings.json
- Recommended next command: sigma step-0-environment-setup
