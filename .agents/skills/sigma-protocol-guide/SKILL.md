---
name: sigma-protocol-guide
description: "Install, learn, and navigate Sigma Protocol -- the Steps 0–15 development methodology"
triggers:
  - install sigma
  - set up sigma
  - sigma protocol
  - teach me sigma
  - what is step
  - explain step
---

# Sigma Protocol Guide

## What is Sigma Protocol?

Sigma Protocol is an 18-step (Steps 0–15 + conditional 1.5 and 11.5) product development methodology for AI-assisted development. It guides you from raw idea to a build-ready execution backlog through three phases:

- **Foundation (Steps 0-4):** define the product, architecture, UX, and flow tree
- **Design (Steps 5-9):** produce wireframe PRDs, design system, state specs, technical specs, and optional landing-page work
- **Build (Steps 10-15):** break features into PRDs, generate execution backlogs, configure platform context, generate the project skillpack, bootstrap the agent runtime, and wire observability

Use the Step Quick Reference below and the package `steps/` and `commands/` directories to inspect the numbered methodology.

## Installation

Use the checked-in package installer documented by the repository README. It requires `git`, Node >=20 and `python3`; `jq` is recommended. If you already have the package checkout, use that checkout rather than cloning another copy.

For a new package checkout:

```bash
git clone https://github.com/Dallionking/sigma-protocol-public sigma-protocol-v2
cd sigma-protocol-v2
bash scripts/install.sh
```

Run the installer only when installation is authorized: it renders package commands and installs Claude Code assets and the department system. `--all` also installs the optional SigmaHQ board; include it only when that board is requested. This is a package-checkout install, not a standalone `sigma` binary download. Restricted runtimes must use their supported installation path or report the blocked prerequisite; do not substitute a guessed release URL.

## Project Initialization

From the package checkout, verify the installed surfaces:

```bash
node scripts/validate-cascade.mjs
bash scripts/doctor.sh
```

Then open the target project in the agent CLI and run `/step-0-environment-setup` from the installed/imported commands before beginning `/step-1-ideation`. Follow the package `GETTING-STARTED.md` and `docs/PLATFORMS.md` for the current client-specific command import and context-loading contract. These commands do not require a `sigma init` or `sigma install` binary.

## Active Workflow Contract

The active Sigma workflow is:

1. Steps `0-15`, plus conditional Steps `1.5` and `11.5`
2. `/prd-json --mode prototype` after Step 5 when you need a prototype backlog
3. `/prd-json --mode implementation` after Step 11 when you need an implementation backlog
4. `/prd-orchestrate` when you want dependency-aware swarm planning

Removed pseudo-step labels are not part of the active workflow vocabulary.

### Canonical machine outputs

```text
.sigma/backlogs/prototype/prd.json
.sigma/backlogs/implementation/prd.json
.sigma/orchestration/*
```

## Step Quick Reference

| Step | Command | Produces | Prerequisite |
|------|---------|----------|-------------|
| 0 | `/step-0-environment-setup` | Environment validation | None |
| 1 | `/step-1-ideation` | `MASTER_PRD.md` | Step 0 |
| 1.5 | `/step-1.5-offer-architecture` | `OFFER-ARCHITECTURE.md` | Step 1 when monetized |
| 2 | `/step-2-architecture` | `ARCHITECTURE.md` | Step 1 |
| 3 | `/step-3-ux-design` | `UX-DESIGN.md` | Step 2 |
| 4 | `/step-4-flow-tree` | Screen inventory | Step 3 |
| 5 | `/step-5-wireframe-prototypes` | Flow PRDs under `docs/prds/flows/` | Step 4 |
| 6 | `/step-6-design-system` | `docs/design/DESIGN-SYSTEM.md` + `docs/tokens/design-tokens.json` | Step 5 |
| 7 | `/step-7-interface-states` | `docs/states/STATE-SPEC.md` | Step 5 + Step 6 |
| 8 | `/step-8-technical-spec` | `docs/technical/TECHNICAL-SPEC.md` | Step 7 |
| 9 | `/step-9-landing-page` | `docs/landing-page/LANDING-PAGE.md` + avatar/diary/research docs | Step 8 when needed |
| 10 | `/step-10-feature-breakdown` | `docs/implementation/FEATURE-BREAKDOWN.md` | Step 8 |
| 11 | `/step-11-prd-generation` | `docs/prds/F[N]-[FEATURE-NAME].md` + `docs/prds/.prd-status.json` | Step 10 |
| 12 | `/step-12-context-engine` | Native Codex and Claude runtime context surfaces | Step 11 |
| 13 | `/step-13-skillpack-generator` | `src/skills/<category>/<skill>/SKILL.md`, `src/agents/<category>/<agent>.md`, and runtime adapters | Step 12 |
| 14 | `/step-14-agent-runtime-bootstrap` | Helper tools, runtime manifests, memory, and coordinator wiring | Step 13 |

### Standalone workflow commands

| Command | Produces | When |
|---------|----------|------|
| `/prd-json --mode prototype` | `.sigma/backlogs/prototype/prd.json` | After Step 5 |
| `/prd-json --mode implementation` | `.sigma/backlogs/implementation/prd.json` | After Step 11 |
| `/prd-orchestrate` | `.sigma/orchestration/*` | When you need swarm planning |

## Breadcrumb Teaching

After any step completes, recommend the next numbered step or the appropriate standalone command. Keep the user on one transition at a time.

## Troubleshooting

- **Commands missing:** check the package installation and the client import instructions in `GETTING-STARTED.md`; this package guide does not require a standalone `sigma` binary.
- **Wrong platform detected:** run from the project root.
- **A step failed:** inspect its output and run `bash scripts/doctor.sh` from the package checkout for package validation.
- **Need to migrate legacy backlogs:** move active work into `.sigma/backlogs/*` and regenerate canonical backlog artifacts with `/prd-json`.
