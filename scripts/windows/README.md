# Windows Script Wrappers

These `.cmd` files provide Windows compatibility for Sigma Protocol shell helpers.

## How They Work

Each wrapper script attempts to use the best available Windows path:

1. **WSL (Windows Subsystem for Linux)** when a real Unix toolchain is required
2. **Git Bash** when shell compatibility is enough
3. **Node.js CLI fallback** when a direct Sigma command exists

## Available Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| `sigma-ralph.cmd` | Deprecated compatibility wrapper for the retired Ralph model | Prints migration guidance and exits non-zero |
| `spawn-streams.cmd` | Spawn parallel agent streams | Active |
| `health-monitor.cmd` | Monitor stream health | Active |
| `merge-streams.cmd` | Merge completed streams | Active |

## Current Baseline

For active Sigma execution on Windows, use:

```cmd
sigma prd-json --mode prototype
sigma prd-json --mode implementation
sigma prd-orchestrate
```

Canonical machine-readable paths:

```text
.sigma/backlogs/prototype/prd.json
.sigma/backlogs/implementation/prd.json
.sigma/orchestration/*
```

## Setup Options

### Option 1: WSL (Recommended)

Use WSL when you need Unix-native tooling for shell helpers.

```cmd
wsl --install
```

### Option 2: Git Bash

Install Git Bash from https://git-scm.com/download/win and ensure `bash` is on your PATH.

### Option 3: Node.js CLI Only

```cmd
npm install -g sigma-protocol
sigma prd-json --mode implementation
sigma prd-orchestrate
```

## Usage Examples

```cmd
REM Generate canonical backlog artifacts
sigma prd-json --mode implementation

REM Build orchestration plan
sigma prd-orchestrate

REM Show migration guidance for the retired Ralph model
sigma-ralph.cmd
```

## Troubleshooting

### "bash not found"

Install Git Bash or WSL.

### Path conversion issues

Use forward slashes when possible:

```cmd
spawn-streams.cmd --workspace=/c/Projects/myapp
```
