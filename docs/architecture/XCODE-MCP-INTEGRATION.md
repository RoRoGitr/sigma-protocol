# ADR: Xcode 26.3 MCP Bridge Integration

**Status:** Accepted
**Date:** 2026-02-07
**Authors:** Sigma Protocol Team

## Context

Xcode 26.3 (RC February 3, 2026) embeds the Claude Agent SDK, providing an AI coding assistant that runs directly inside Xcode with access to 20 native MCP tools. project's `.claude/` configuration includes the full department roster (60+ agents), the bundled skill pool, and rule files but has no awareness of these Xcode capabilities.

We need to:
1. Enable project agents (Claude Code) to invoke Xcode's build, test, preview, and doc search tools via MCP
2. Enable Xcode's embedded Claude Agent to inherit project's skill and command library
3. Provide a headless alternative for CI/CD environments where Xcode UI is not available

## Decision

### MCP Bridge Strategy (Dual Server)

We register two MCP servers:

| Server | Command | Transport | Use Case |
|--------|---------|-----------|----------|
| `xcode` | `xcrun mcpbridge` | stdio | Interactive development (Xcode running) |
| `XcodeBuildMCP` | `npx -y xcodebuildmcp@beta mcp` | stdio | CI/CD, headless, SSH sessions |

**Rationale:** The native `xcrun mcpbridge` provides the richest integration (previews, documentation, live diagnostics) but requires Xcode to be running. `XcodeBuildMCP` (npm) wraps `xcodebuild` CLI commands for environments where the Xcode GUI is unavailable.

### Symlink Inheritance Strategy

Rather than duplicating configuration, we symlink the project's `.agents/skills/` and `commands/` directories into Xcode's `ClaudeAgentConfig` directory (operator-local `.claude/skills/` and `.claude/commands/` remain a compatibility fallback in older checkouts):

```
.agents/skills/  --> ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/skills/
commands/        --> ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/commands/
```

**Rationale:**
- Single source of truth — edits to skills/commands propagate to both Claude Code and Xcode Agent
- No sync scripts or watchers needed
- Per-project — re-running setup for a different project updates the symlinks
- Non-destructive — existing Xcode config is backed up before symlinking

### Shared CLAUDE.md

Both Claude Code and Xcode's embedded agent read the project-root `CLAUDE.md`. We add an "Xcode 26.3 Integration" section that both agents can reference for MCP server info and build patterns.

## Alternatives Considered

### 1. Duplicate Skills in Xcode Config Directory
**Rejected.** Creates divergence between Claude Code and Xcode Agent configurations. Requires a sync mechanism that adds complexity.

### 2. XcodeBuildMCP Only (No Native Bridge)
**Rejected.** Loses access to `RenderPreview`, `DocumentationSearch`, and `GetDiagnostics` — the highest-value tools for interactive SwiftUI development.

### 3. Native Bridge Only (No XcodeBuildMCP)
**Rejected.** CI/CD pipelines run headless without Xcode GUI. Builds would fail in automated environments.

### 4. Separate CLAUDE.md for Xcode Agent
**Rejected.** Xcode's agent reads the project-root `CLAUDE.md` by default. A separate file would mean maintaining two sources of truth for project conventions.

## Consequences

### Positive
- project agents gain access to 20 native Xcode tools for builds, tests, previews, and doc search
- Xcode's Claude Agent inherits the full project skill library (370+ skills, 90+ commands)
- CI/CD environments get headless build support via XcodeBuildMCP
- Single `CLAUDE.md` serves both runtime contexts
- Setup is idempotent and non-destructive (backs up existing config)

### Negative
- Requires Xcode 26.3+ (not yet GA — RC as of Feb 3, 2026)
- `RenderPreview` and `DocumentationSearch` only work when Xcode is running
- Symlinks are per-project — switching projects requires re-running setup
- XcodeBuildMCP is on `@beta` tag — may have breaking changes

### Risks
- Apple may change the `xcrun mcpbridge` interface in future Xcode updates
- XcodeBuildMCP npm package is community-maintained (cameroncooke/XcodeBuildMCP)
- Symlink targets depend on macOS directory conventions (`~/Library/Developer/Xcode/`)

## Implementation

| Component | Path |
|-----------|------|
| Xcode MCP tools reference | `.claude/skills/xcode-intelligence/SKILL.md` |
| Agentic workflow patterns | `.claude/skills/xcode-agent-workflow/SKILL.md` |
| Setup script | `scripts/setup-xcode-claude.sh` |
| Setup command | `commands/setup-xcode-integration.md` (or legacy `.claude/commands/setup-xcode-integration.md`) |
| Setup documentation | `docs/setup/XCODE-CLAUDE-SETUP.md` |
| MCP server config | `.claude/settings.json` (`mcpServers` key) |
| Agent updates | `.claude/agents/sigma-ios-engineer.md`, `sigma-devops.md` |
| Rule updates | `.claude/rules/mcp-tools.md`, `skills-reference.md` |
| Project config | `CLAUDE.md` (new section) |

## References

- [Apple Newsroom - Xcode 26.3](https://www.apple.com/newsroom/2026/02/xcode-26-point-3-unlocks-the-power-of-agentic-coding/)
- [Anthropic - Apple's Xcode now supports Claude Agent SDK](https://www.anthropic.com/news/apple-xcode-claude-agent-sdk)
- [fatbobman - Xcode 26.3 + Claude Agent](https://fatbobman.com/en/posts/xcode-263-claude)
- [rudrank - Xcode MCP Tools in Cursor, Claude Code and Codex](https://rudrank.com/exploring-xcode-using-mcp-tools-cursor-external-clients)
- [XcodeBuildMCP GitHub](https://github.com/cameroncooke/XcodeBuildMCP)
- [Claude Help - Using Claude in Xcode](https://support.claude.com/en/articles/12293051-using-claude-in-xcode)
