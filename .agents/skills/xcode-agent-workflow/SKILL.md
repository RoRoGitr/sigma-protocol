---
name: xcode-agent-workflow
description: "Agentic Xcode workflow patterns — build-preview-fix loops, automated Xcode tasks. Use when automating Xcode development. Triggers on \'xcode agent\', \'xcode workflow\', \'agentic xcode\', \'xcode automation\'."
triggers:
  - xcode agent
  - agentic xcode
  - xcode workflow
  - xcode claude agent
  - preview driven development
department: engineering
---

# Xcode Agent Workflow

Patterns for agentic coding with Xcode 26.3's embedded Claude Agent and Claude Code working together. Covers the build-preview-fix loop, shared configuration strategy, and when to use each tool.

---

## Agentic Build Loop

The core development cycle when MCP tools are available:

```
Plan (read requirements)
  |
  v
Write (implement code)
  |
  v
BuildProject (compile)
  |
  v
GetBuildErrors ---[errors?]--> Fix --> BuildProject (loop)
  |
  [clean build]
  v
RenderPreview (visual check)
  |
  v
RunAllTests (verify behavior)
  |
  v
GetDiagnostics (final lint)
  |
  v
Done
```

### Step-by-Step

1. **Plan**: Read the PRD/feature spec. Use `DocumentationSearch` for unfamiliar APIs.
2. **Write**: Create or edit Swift files. Use `XcodeRead`/`XcodeWrite` in Xcode Agent, or `Read`/`Edit` in Claude Code.
3. **Build**: `BuildProject(scheme: "YourApp", configuration: "Debug")`
4. **Check errors**: `GetBuildErrors(includeWarnings: true)` — fix all errors before proceeding.
5. **Preview**: `RenderPreview(filePath: "Views/GameView.swift", previewName: "GameView_Previews")` — visual verification.
6. **Test**: `RunAllTests(scheme: "YourAppTests")` — confirm behavior matches spec.
7. **Diagnostics**: `GetDiagnostics()` — catch any remaining live issues.

**Key rule:** Never skip the build step. A preview on broken code wastes cycles.

---

## CLAUDE.md Shared Strategy

The project `CLAUDE.md` at the repository root is read by both:
- **Claude Code** (when invoked from terminal)
- **Xcode's embedded Claude Agent** (when working in Xcode)

This means:
- Project conventions, build commands, and quality gates are automatically shared
- Agent-specific instructions should use environment detection (see `xcode-intelligence` skill)
- Do NOT create separate config files — maintain a single source of truth

### What Goes in CLAUDE.md

| Content | Both Agents Use It? |
|---------|---------------------|
| Project overview, architecture | Yes |
| Build commands (xcodebuild / MCP) | Yes |
| Code style, naming conventions | Yes |
| Quality gates, testing requirements | Yes |
| Swarm orchestration rules | Claude Code only (Xcode Agent is single-agent) |
| MCP server configuration | Claude Code only (Xcode has its own config) |

---

## Symlink Inheritance

Skills and commands flow from the project `.claude/` directory to Xcode's configuration via symlinks:

```
Project                                  Xcode ClaudeAgentConfig
.claude/skills/ ----symlink----> ~/Library/Developer/Xcode/
                                   CodingAssistant/ClaudeAgentConfig/skills/
commands/ + .agents/skills/ --symlink----> ~/Library/Developer/Xcode/
                                   CodingAssistant/ClaudeAgentConfig/commands/
```

Run `scripts/setup-xcode-claude.sh` to establish these symlinks. This means:
- New skills added to the project are immediately available in Xcode's Claude Agent
- No manual copying or syncing required
- Symlinks are per-project — switch projects by re-running setup

---

## Preview-Driven Development

Use `RenderPreview` for visual verification during implementation. This is faster than launching the simulator.

### Pattern

```
1. Write/edit a SwiftUI view
2. RenderPreview to see the result
3. Adjust layout/styling based on preview
4. Repeat until visually correct
5. Then run tests for behavioral verification
```

### When RenderPreview Works Best

| Scenario | Use RenderPreview? |
|----------|--------------------|
| SwiftUI view layout | Yes — fast visual feedback |
| Color/typography changes | Yes — instant verification |
| Animation timing | No — preview is static image |
| Navigation flows | No — use simulator via `InstallAndRun` |
| Data-dependent UI | Partial — requires preview data in `#Preview` block |
| UIKit views | No — `RenderPreview` requires SwiftUI previews |

---

## Apple Documentation Integration

Use `DocumentationSearch` instead of web search for Apple API lookups:

```
DocumentationSearch(query: "NavigationStack path binding")
DocumentationSearch(query: "SwiftData ModelContext", framework: "SwiftData")
DocumentationSearch(query: "ScenePhase background", framework: "SwiftUI")
```

### When to Use DocumentationSearch vs Web Search

| Need | Tool |
|------|------|
| Official Apple API reference | `DocumentationSearch` |
| Apple framework conceptual guides | `DocumentationSearch` |
| Community patterns, tutorials | Web search (EXA, Firecrawl) |
| Third-party library docs | `Context7` or web search |
| WWDC session content | Web search |

---

## Xcode Agent vs Claude Code Decision Matrix

Choose the right tool for the job:

| Task | Best Tool | Why |
|------|-----------|-----|
| **Single view implementation** | Xcode Agent | Preview-driven, tight feedback loop |
| **Fix a build error** | Xcode Agent | `GetBuildErrors` + in-context fix |
| **Multi-file refactor** | Claude Code | Better at coordinating cross-file changes |
| **Full PRD implementation** | Claude Code swarm | Parallel agents, task management |
| **API exploration** | Xcode Agent | `DocumentationSearch` is faster than web |
| **UI polish iteration** | Xcode Agent | `RenderPreview` for rapid visual feedback |
| **Test-driven development** | Either | Both can run tests; Xcode gives richer output |
| **Architecture design** | Claude Code | Needs research skills, multi-file analysis |
| **CI/CD integration** | Claude Code | Needs `XcodeBuildMCP` (headless), shell access |
| **Code review** | Claude Code | Greptile MCP integration, PR workflows |

### Hybrid Workflow

For maximum productivity, use both:

1. **Claude Code** for planning, architecture, multi-file scaffolding
2. **Xcode Agent** for implementing individual views with preview-driven iteration
3. **Claude Code** for running tests across the full suite and PR review
4. **Xcode Agent** for quick fixes flagged during review

---

## Common Workflows

### New SwiftUI View (Xcode Agent)
```
1. DocumentationSearch — look up relevant APIs
2. XcodeWrite — create the new view file
3. BuildProject — verify it compiles
4. RenderPreview — visual check
5. RunTestMethod — verify specific behavior
```

### Multi-Feature PRD (Claude Code Swarm)
```
1. /implement-prd — parse PRD into tasks
2. Swarm agents implement in parallel
3. Each agent uses BuildProject for verification
4. Gap analyst runs final verification
5. /greptile-pr-review for code review
```

### Bug Fix (Xcode Agent)
```
1. GetBuildErrors or GetDiagnostics — find the issue
2. XcodeRead — read the problematic file
3. XcodeWrite — apply the fix
4. BuildProject — verify fix compiles
5. RunTestMethod — verify fix passes
6. RenderPreview — verify visual correctness
```

---

## See Also

- `xcode-intelligence` -- Full MCP tools reference
- `your-app-build` -- project build workflow
- `swiftui-patterns` -- SwiftUI architecture patterns
- `docs/setup/XCODE-CLAUDE-SETUP.md` -- Setup guide

## When NOT to Use

- Not for non-Xcode IDEs (VS Code, Android Studio) — Xcode-specific agent patterns
- Not for React Native/Expo builds — native Xcode project workflows
- Not for Xcode MCP tool reference — use xcode-intelligence for tool docs
- Not for manual Xcode usage — agentic automation patterns only

## Related Skills

- `swift-concurrency` — engineering/mobile/swift
- `swiftui-patterns` — engineering/mobile/swift
- `mobile-ui-testing` — engineering/mobile/testing

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Firecrawl MCP, EXA MCP, Greptile MCP, Bash, Read, Write, Edit
