---
name: electron
description: Electron desktop app scaffold and security baseline for Sigma Step 0 / Step 8 platform matrices. Use when the stack is Electron (electron-vite + React + TypeScript), not for automating third-party Electron apps.
---

# Electron Desktop Scaffold

Sigma default for **building** an Electron desktop app (not automating Slack/VS Code).

## Scaffold (Step 0)

```bash
npm create @quick-start/electron@latest . -- --template react-ts
```

Prefer **electron-vite** templates — React, TypeScript, and context isolation defaults.

## Security baseline (non-negotiable)

Confirm in generated `BrowserWindow` options:

```js
new BrowserWindow({
  webPreferences: {
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
    preload: path.join(__dirname, 'preload.js'),
  },
})
```

IPC: expose only typed APIs via `contextBridge` in preload — never pass raw Node APIs to the renderer.

## stack-profile.json

```json
{
  "platform": "desktop",
  "framework": "electron",
  "frontendFramework": "react-ts",
  "ipcPattern": "contextBridge-typed-wrappers"
}
```

## Related skills

- Desktop shell alternative → `tauri-patterns`
- macOS chrome / window layout → `macos-design`
- Web UI inside shell → `frontend-design`, `shadcn`, `react`
