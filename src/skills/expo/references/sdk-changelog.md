# Expo SDK changelog — version truth

> **Last verified: 2026-06-04.** This file is the ONLY place SDK/RN/React version facts live.
> Before quoting any number, re-check the stamp. If it is stale, run `npm view expo dist-tags`
> and `npm view react-native dist-tags`, read `expo.dev/changelog`, then update this file + the stamp.

## Current dist-tags (npm, 2026-06-04)

| Package | latest | next | canary/nightly |
|---|---|---|---|
| `expo` | **56.0.8** (stable 2026-05-21) | 56.0.8 | `57.0.0-canary` |
| `react-native` | **0.85.3** | `0.86.0-rc.3` | 0.87 nightly |
| `react` | **19.2.7** (SDK 56 ships 19.2) | — | — |
| `expo-router` | **56.2.8** | — | — |
| `@expo/cli` | **56.1.13** | — | — |
| `eas-cli` | **20.0.0** | — | — |
| `@expo/fingerprint` | **0.18.x** | — | — |

## SDK 56 (stable 2026-05-21) — the deltas that bite

- **RN 0.85 + React 19.2 + Hermes V1.** Node 20.19.4 minimum.
- **Bridge fully removed (RN 0.85).** Fabric + TurboModules + Codegen is the *only* native path. No legacy interop layer — every wrapped native lib must be new-arch.
- **`expo-router` forked from `react-navigation` (SDK 56).** Direct `@react-navigation/*` imports break; route through `expo-router`'s own surface (`NativeTabs.Trigger.*`, etc.).
- **Min iOS raised to 16.4** (drops iPhone 7 / SE 1st-gen).
- **Shared Animation Backend** (C++) is the default animation driver.
- **Stable object APIs** for Calendar / Contacts / MediaLibrary; **async file-system** API; **stable Expo UI** primitives (`Host`, `Row`, `Column`, …).
- **Official Expo Skills + `AGENTS.md`/`CLAUDE.md` scaffolding** are written into new SDK 56 projects — prefer the vendor skills for UI/data/deploy breadth.

## Engine / arch history (durable)

- **Hermes V1** is the default JS engine since **RN 0.84**. No JavaScriptCore.
- **Node 22** minimum since RN 0.84; SDK 56 pins Node 20.19.4 as the floor.
- New Architecture has been default since SDK 54; the bridge-removal completion is the 0.85 milestone.

## How to re-verify (do this, do not guess)

```bash
npm view expo dist-tags
npm view react-native dist-tags
npm view react version
npm view expo-router version
npm view eas-cli version
```

A version number baked into memory (or a skill *name*) goes stale in days — SDK 56 flipped from "preview, don't ship" to "stable" on 2026-05-21. Always read the stamp above first.
