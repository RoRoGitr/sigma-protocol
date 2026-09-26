---
name: xcode-intelligence
description: "Xcode 26.3 MCP tools reference — 20 native tools for build, test, preview, and project management. Use when invoking Xcode tools via MCP. Triggers on \'xcode mcp\', \'xcode tools\', \'build project\', \'render preview\', \'xcode bridge\'."
triggers:
  - xcode mcp
  - xcode tools
  - render preview
  - documentation search
  - xcode build mcp
  - xcrun mcpbridge
department: engineering
---

# Xcode 26.3 MCP Intelligence

Reference for the 20 Xcode MCP tools exposed via `xcrun mcpbridge` and the headless `XcodeBuildMCP` alternative. Use this skill when working with Xcode builds, previews, tests, or Apple documentation.

---

> **Version:** Patterns target Xcode 26.3 MCP Bridge.

## Xcode MCP Tools (via `xcrun mcpbridge`)

These tools are available when Xcode 26.3+ is running and the MCP bridge is registered.

### Build & Run

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `BuildProject` | Build the current project/workspace | `scheme`, `configuration` (Debug/Release), `destination` |
| `GetBuildErrors` | Retrieve build errors and warnings | `includeWarnings` (bool) |
| `GetBuildSettings` | Get resolved build settings | `scheme`, `key` (specific setting) |
| `InstallAndRun` | Build, install, and launch on device/sim | `scheme`, `destination` |

### Testing

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `RunAllTests` | Execute the full test suite | `scheme`, `destination`, `configuration` |
| `RunTestMethod` | Run a single test method | `testIdentifier` (e.g., `MyTests/testLogin`) |
| `RunTestClass` | Run all tests in a class | `className` |

### Preview & Visualization

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `RenderPreview` | Render a SwiftUI preview as image | `filePath`, `previewName` |

### Project Structure

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `GetProjectStructure` | List project groups, targets, files | `depth` |
| `GetSchemes` | List all available schemes | — |
| `GetDevices` | List simulators and connected devices | `platform` (iOS, macOS, etc.) |

### File Operations

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `XcodeRead` | Read file contents via Xcode | `filePath` |
| `XcodeWrite` | Write/create file via Xcode | `filePath`, `content` |
| `XcodeGlob` | Find files by glob pattern | `pattern`, `rootPath` |
| `XcodeGrep` | Search file contents | `pattern`, `filePath` or `rootPath` |

### Documentation

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `DocumentationSearch` | Search Apple developer documentation | `query`, `framework` (optional) |

### Source Control (Xcode-integrated)

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `GetSourceChanges` | Show uncommitted changes | — |
| `StageFiles` | Stage files for commit | `filePaths` |
| `CreateCommit` | Create a git commit | `message` |

### Diagnostics

| Tool | Description | Key Parameters |
|------|-------------|----------------|
| `GetDiagnostics` | Xcode diagnostics and live issues | `filePath` (optional) |

---

## Environment Detection

Detect whether you're running inside Xcode's embedded Claude Agent or standalone Claude Code:

| Signal | Xcode Agent | Claude Code |
|--------|-------------|-------------|
| `CLAUDE_CONFIG_DIR` | Contains `Xcode/CodingAssistant` | `.claude/` in project root |
| MCP tools available | All 20 via native bridge | Only if `xcrun mcpbridge` registered |
| File I/O | Use `XcodeRead`/`XcodeWrite` | Use `Read`/`Write`/`Edit` |
| Build invocation | Use `BuildProject` | Use `BuildProject` (MCP) or `xcodebuild` (Bash) |

**Rule:** If MCP Xcode tools are available, prefer them over raw `xcodebuild` shell commands. They integrate with Xcode's live issue tracking and incremental build system.

---

## YourApp Build Mapping

Translation from current project xcodebuild commands to MCP equivalents:

| Current (xcodebuild) | MCP Equivalent | Notes |
|-----------------------|----------------|-------|
| `xcodebuild -scheme YourApp -sdk iphonesimulator build` | `BuildProject(scheme: "YourApp", destination: "simulator")` | MCP handles SDK selection |
| `xcodebuild test -scheme YourAppTests` | `RunAllTests(scheme: "YourAppTests")` | Streams results to Xcode |
| `xcodebuild -showBuildSettings` | `GetBuildSettings(scheme: "YourApp")` | Parsed structured output |
| `xcodebuild -list` | `GetSchemes()` | Cleaner than CLI parsing |
| `xcrun simctl list devices` | `GetDevices(platform: "iOS")` | Filtered by platform |
| `xcodegen generate` | **No MCP equivalent** | Always use shell: `Bash(xcodegen generate)` |
| `swift build` | **No MCP equivalent** | SPM builds still use shell |

---

## XcodeBuildMCP Fallback (Headless)

When Xcode is not running (CI, headless environments, SSH sessions), use the `XcodeBuildMCP` npm package instead:

```
MCP Server: XcodeBuildMCP
Command: npx -y xcodebuildmcp@beta mcp
Transport: stdio
```

### Available XcodeBuildMCP Tools

| Tool | Description |
|------|-------------|
| `xcodebuild_build` | Build project via xcodebuild CLI |
| `xcodebuild_test` | Run tests via xcodebuild CLI |
| `xcodebuild_clean` | Clean build artifacts |
| `xcodebuild_resolve_dependencies` | Resolve SPM dependencies |
| `xcodebuild_show_schemes` | List available schemes |
| `xcodebuild_show_destinations` | List available destinations |
| `xcodebuild_show_build_settings` | Show build settings |

### When to Use Which

| Scenario | Use |
|----------|-----|
| Xcode open, interactive development | `xcrun mcpbridge` (native tools) |
| CI/CD pipeline | `XcodeBuildMCP` (headless) |
| SSH / headless Mac | `XcodeBuildMCP` (headless) |
| Preview rendering | `xcrun mcpbridge` only (requires Xcode) |
| Apple doc search | `xcrun mcpbridge` only (requires Xcode) |

---

## Troubleshooting

### `xcrun mcpbridge` not found
- Verify Xcode 26.3+ is installed: `xcodebuild -version`
- Ensure Xcode CLI tools point to 26.3: `xcode-select -p`
- Re-register: `claude mcp add --transport stdio xcode -- xcrun mcpbridge`

### MCP tools timeout
- Xcode must be running and not in a modal dialog
- Kill zombie Xcode processes: `killall Xcode && open -a Xcode`
- Check bridge process: `ps aux | grep mcpbridge`

### Build errors not appearing via MCP
- Use `GetBuildErrors(includeWarnings: true)` after `BuildProject`
- Fall back to `xcodebuild 2>&1 | xcpretty` for verbose output

### XcodeBuildMCP fails to start
- Ensure Node.js 18+ is installed: `node --version`
- Clear npx cache: `npx clear-npx-cache`
- Install explicitly: `npm install -g xcodebuildmcp@beta`

---

## See Also

- `xcode-agent-workflow` -- Agentic coding patterns with Xcode MCP
- `your-app-build` -- YourApp build and verification workflow
- `swiftui-patterns` -- SwiftUI architecture patterns
- `docs/architecture/XCODE-MCP-INTEGRATION.md` -- ADR for this integration

## When NOT to Use

- Not for non-Xcode build systems (Gradle, CMake) — Xcode MCP tools only
- Not for agentic workflow patterns — use xcode-agent-workflow instead
- Not for Android development — iOS/macOS Xcode toolchain only
- Not for Xcode UI navigation — MCP tool invocation reference only

## Related Skills

- `swift-concurrency` — engineering/mobile/swift
- `swiftui-patterns` — engineering/mobile/swift
- `mobile-ui-testing` — engineering/mobile/testing

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Bash, Read, Write, Edit
