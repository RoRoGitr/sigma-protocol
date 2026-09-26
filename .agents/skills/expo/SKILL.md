---
name: expo
description: "One living Expo + React Native engineering skill — native modules (Expo Modules API), typed routes, native tabs, EAS build debugging, and per-SDK deltas. Version facts live in references/sdk-changelog.md (never in the skill name). Use when building, upgrading, or debugging an Expo / React Native app. Triggers on 'expo', 'react native', 'expo sdk', 'sdk upgrade', 'eas build', 'expo modules api', 'requireNativeModule', 'config plugin', 'typed routes', 'href type', 'native tabs', 'bottom tabs', 'new architecture', 'rn js engine', 'metro', 'eas build failed', 'bundle phase'."
department: engineering
triggers:
  - expo
  - react native
  - expo sdk
  - sdk upgrade
  - eas build
  - expo modules api
  - requireNativeModule
  - config plugin
  - typed routes
  - href type
  - native tabs
  - bottom tabs
  - new architecture
  - rn js engine
  - metro
  - eas build failed
  - bundle phase
---

# Expo

The single Expo + React Native engineering skill. One competency: working inside an Expo/RN app. Per-SDK version facts live in `references/sdk-changelog.md` with a hard "last verified" stamp — a version number in a skill *name* guarantees staleness; a version number in a *reference file* with a date is honest.

## When to Use

- Authoring a native module (Swift / Kotlin) via the Expo Modules API
- Wiring typed routes, native tabs, or navigation in Expo Router
- An `eas build` fails or returns "Unknown error. See logs..."
- Upgrading the Expo SDK or auditing a project's SDK alignment
- Debugging post-upgrade breakage (new architecture, RN JS engine, bridge removal, Metro)

## When NOT to Use

- Pure JS/TS app logic with no Expo/RN surface — use the React skill
- UI building, data-fetching, dev-client, NativeWind/Tailwind, API routes, `use dom`, deployment, CI/CD workflows, the upgrade *procedure* — Expo ships first-party vendor skills for these (`expo-app-design:*`, `expo-deployment:*`, `upgrading-expo`), now scaffolded into new SDK projects. Point at them; do not re-author.
- Apple-native (SwiftUI internals, Xcode) without RN — use the apple-native skill
- App-store submission flows — use the `asc-*` family

## Core DNA

1. **New architecture is the only runtime.** The JS↔native bridge is removed in current RN. Fabric + TurboModules + Codegen is the sole native path; there is no legacy interop layer. Any wrapped native lib must be new-arch compatible.
2. **The RN JS engine is the default runtime.** Plan for byte-code source maps and runtime API coverage gaps (e.g. some Web globals are absent — verify at runtime, not just at bundle time).
3. **Version facts are dated, not baked in.** Read `references/sdk-changelog.md` before giving any "which SDK / which RN / ship-or-don't" advice, and check its stamp. If the stamp is old, re-verify against `npm view expo dist-tags` and `expo.dev/changelog` before answering.
4. **Defer to the vendor for breadth.** Expo maintains and scaffolds its own Skills (and writes `AGENTS.md` / `CLAUDE.md` into new projects). This skill carries the durable engineering DNA; vendor skills carry the broad how-to.
5. **The CLI hides real errors.** `eas build` only shows the queue/upload phase. The actual Metro/Xcode stderr lives in the EAS dashboard log files — fetch them.

## Key Patterns

### Native module — Expo Modules API

```bash
npx create-expo-module --local my-cool-module   # in-project, auto-linked
npx create-expo-module my-cool-module           # standalone npm package
```

Swift definition (Kotlin mirrors the same DSL):

```swift
// ios/MyCoolModuleModule.swift
import ExpoModulesCore

public class MyCoolModuleModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyCoolModule")                 // MUST match requireNativeModule<>('MyCoolModule')
    Constants(["PI": Double.pi])
    Function("hello") { (name: String) -> String in "Hello \(name)" }
    AsyncFunction("delayedGreeting") { (name: String, ms: Int) async -> String in
      try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
      return "Delayed hi to \(name)"
    }
    Events("onLocationUpdate")           // sendEvent("onLocationUpdate", {...}) to fire
    OnCreate { /* runs at module load */ }
    OnDestroy { /* cleanup */ }
  }
}
```

JS surface:

```ts
import { NativeModule, requireNativeModule } from 'expo';
declare class MyCoolModule extends NativeModule<{ onLocationUpdate: (p: {lat:number;lng:number}) => void }> {
  PI: number;
  hello(name: string): string;
  delayedGreeting(name: string, ms: number): Promise<string>;
}
export default requireNativeModule<MyCoolModule>('MyCoolModule');
```

Config plugin (modify native config at prebuild time):

```js
// app.plugin.js
const { withInfoPlist } = require('expo/config-plugins');
module.exports = (config, props = {}) =>
  withInfoPlist(config, (cfg) => {
    cfg.modResults.NSLocationWhenInUseUsageDescription = props.locationReason ?? 'We need your location.';
    return cfg;
  });
```

Rebuild loop after native edits: `npx expo prebuild --clean && npx expo run:ios`. Details + Kotlin mirror + local-vs-published table: `references/native-modules.md`.

### Typed routes (default-on in current SDKs)

Typed routes ship on by default — `experiments.typedRoutes` is no longer needed. Keep `.expo/types/**/*.ts` in `tsconfig.json` includes; restart Metro if autocomplete goes stale.

```tsx
import { Link, useRouter } from 'expo-router';
import type { Href } from 'expo-router';

<Link href="/profile">Profile</Link>
const href: Href<'/profile/[id]'> = { pathname: '/profile/[id]', params: { id } };
useRouter().push({ pathname: '/profile/[id]', params: { id: '42' } }); // object form always typed
```

Group routes (`(tabs)`) appear in the type union; catch-all params are `string[]`. Full reference: `references/typed-routes.md`.

### Native tabs (post router fork)

Recent SDKs forked `expo-router` from `react-navigation` — direct `@react-navigation/*` imports break; route through `expo-router`'s own surface. Prefer `expo-router`'s native tabs (`NativeTabs.Trigger.*`) for new apps; use the community `react-native-bottom-tabs` (`@bottom-tabs/react-navigation`) when migrating an existing React Navigation app or when you need its TS types. Both render real `UITabBarController` / `BottomNavigationView` and pick up the system glass material on a semi-transparent background. Native code → `prebuild --clean` + `run:ios` required. Comparison + SF-Symbol/Android-resource patterns: `references/native-tabs.md`.

### EAS build debugging

`eas build:view <id> --json` exposes 4 signed GCS log URLs (15-min expiry); the largest (~150-200 KB) is the worker log. Grep it for `EAGER_BUNDLE` / `stderr` to see what Metro saw on the build server. Reproduce the bundle phase locally without burning a slot:

```bash
EXPO_PUBLIC_DEV_MODE=false ./node_modules/.bin/expo export:embed --eager \
  --platform ios --dev false --bundle-output /tmp/eager.bundle --assets-dest /tmp/eager-assets
```

Top recurring failures: (1) a build-time `require()` of a gitignored file (EAS uploads working-tree minus `.gitignore`) — move the file out of the ignored path; (2) an npm package with a broken `main` (empty `lib/`) — bump, install from the GitHub fix tag, or `patch-package`; (3) prod-only env vars missing on EAS (`eas env:list --environment production`). Full recipes, credential setup, and the watch/poll loop: `references/eas-build-debugging.md`.

### Pre-build quality gates

Before burning an EAS slot: `typecheck` clean → `lint` clean → `npx expo-doctor` all checks pass → `expo export:embed --eager` succeeds → tree committed. If all pass and EAS still fails, it's environmental. For the runtime smoke step (does the *installed* app actually launch through its screens), use the mobile-shipping skill — bundle success ≠ runtime success.

## Anti-Patterns

- Putting an SDK version in this skill's name or body — it goes stale silently. Versions live only in `references/sdk-changelog.md` with a stamp.
- Telling a user an SDK is "preview / don't ship" from memory. Re-verify against `npm view expo dist-tags` first — a version cliff can flip the answer in days.
- Re-authoring UI / data-fetching / deployment content the vendor Expo skills already own and keep current.
- Importing `@react-navigation/*` directly in a post-fork SDK — it breaks; go through `expo-router`.
- Assuming legacy `NativeModules` / bridge interop exists — it is gone; wrap libs as new-arch native.
- Treating `expo export:embed --eager` as a full ship gate — it catches bundle-time errors only, not runtime crashes, visual bugs, or nav regressions.
- Fighting `.gitignore` re-include patterns to ship a build-time file — `eas-cli`'s parser doesn't honor them like git does. Move the file instead.

## Quality Gates

- [ ] Read `references/sdk-changelog.md` and checked its "last verified" stamp before any version claim
- [ ] Native module `Name(...)` matches the `requireNativeModule<>('...')` string
- [ ] After native edits: `prebuild --clean` + native rebuild run, not just Metro reload
- [ ] No direct `@react-navigation/*` imports on a post-fork SDK
- [ ] Wrapped native libs are new-arch / TurboModule compatible
- [ ] Build-time `require()` targets are git-tracked or outside any ignored path
- [ ] Vendor Expo skills referenced for UI/data/deploy breadth instead of duplicated
- [ ] Pre-EAS gates pass (typecheck, lint, expo-doctor, eager embed, committed tree)

## References

| File | Content |
|------|---------|
| `references/sdk-changelog.md` | Per-SDK deltas (RN / React / JS engine / architecture / router) with a hard "last verified" stamp — the only place version facts live |
| `references/native-modules.md` | Expo Modules API — Kotlin mirror, events, local-vs-published, gotchas, post-bridge note |
| `references/typed-routes.md` | Typed routes (default-on), `Href<T>`, group/catch-all routes, migration |
| `references/native-tabs.md` | Native tabs, the router fork, `react-native-bottom-tabs` vs `expo-router` native tabs, SF Symbols + Android resources |
| `references/eas-build-debugging.md` | Log-fetch recipe, common bundle-phase failures, credential setup, env vars, watch/poll |

## 2026-06 Landscape

### SDK 56
- **Expo UI (SwiftUI + Jetpack Compose) is stable on both platforms** — in the default template and Expo Go. Components update shared state synchronously on the UI thread via worklets (flicker-free native inputs). Use for OS-native surfaces only (pickers, menus, toolbars, context menus). Its native look bypasses NativeWind styling — keep it off branded cinematic screens.
- **Expo Router v7**: native toolbars (`Stack.Toolbar`), zoom transitions, data loaders + streaming SSR, decoupled from React Navigation — direct `@react-navigation/*` imports break on current SDKs, go through `expo-router` surfaces.
- **Android cold starts ~40% faster.** iOS builds 16% faster (+20% on EAS via precompiled community libs).
- **Evan Bacon departed Expo (May 29, 2026)** after 9 years. Router v7 features shipped regardless — watch roadmap continuity at expo.dev/changelog.

### SDK 56 + pnpm scaffold gotchas
Real failures hit scaffolding a fresh SDK 56 + pnpm + NativeWind v4 + Reanimated 4 app — each silently breaks Metro or jest:

- **`nativewind/babel` is a PRESET, not a plugin.** It goes in babel `presets` (alongside `['babel-preset-expo', { jsxImportSource: 'nativewind' }]`), never in `plugins`. Wrong placement → Metro: `.plugins is not a valid Plugin property`.
- **NativeWind v4 needs `metro.config.js` wrapped with `withNativeWind({ input: './global.css' })`.** Without it, `className` silently no-ops (no error, just unstyled).
- **With pnpm, `react-native-css-interop` must be a DIRECT dependency.** pnpm's strict node_modules hides it otherwise and Metro can't resolve its `jsx-runtime`.
- **RNTL v14 `render` is async** — `await render(...)` or `screen` throws "render function has not been called" (see mobile-ui-testing).
- **Reanimated 4's `react-native-worklets` throws in jest** unless jest config sets `resolver: require.resolve('react-native-worklets/jest/resolver.js')`. Do NOT `jest.mock('react-native-reanimated', ...)` with `/mock` — that path is dead; use the resolver.
- **SDK 56 expo-router bans direct `@react-navigation/*` deps.** Types like `BottomTabBarProps` come from `expo-router/build/react-navigation/bottom-tabs`, not `@react-navigation/bottom-tabs`.

### NativeWind-based app component adoption table

| Verdict | Library | Rationale |
|---------|---------|-----------|
| **ADOPT NOW** | react-native-reusables (founded-labs) | shadcn-style + NativeWind v4; CSS-var dual theming makes dark-only trivial; copy-paste = full control |
| **ADOPT NOW** | Reanimated 4.4 CSS animations API | New-arch standard; 4.4 = iOS Core Animation-backed CSS engine (`IOS_CSS_CORE_ANIMATION` flag); CSS SVG + path-morph in 4.3+; community-blessed Moti replacement; new-arch only |
| **ADOPT NOW** | react-native-skia | Film grain + beam shaders; FractalNoise/Turbulence built-in; Graphite/WebGPU backend migration underway — future-proofs it |
| **ADOPT NOW** | FlashList v2 | No estimates, masonry prop, `maintainVisibleContentPosition` default, native sticky headers; new-arch only; `inverted` removed — use `maintainVisibleContentPosition` instead |
| **ADOPT NOW** | sonner-native | Parity with web Sonner; community-consensus toast lib; styleable to flat-hairline |
| **ADOPT NOW** | expo-image | SDK-bundled; recycling + blurhash/thumbhash placeholders — default image primitive |
| **ADOPT NOW** | react-native-keyboard-controller | OverKeyboardView + keyboard-aware chat input; official Reanimated migration target |
| **ADOPT NOW** | Native `formSheet` (react-native-screens) | Zero-dep native bottom sheet first; reach for gorhom only for snap-point/gesture-rich sheets |
| **ADOPT LATER** | Legend List 3 (`KeyboardAwareLegendList`) | Purpose-built chat/AI list; avoid inverting FlashList for DM surfaces |
| **ADOPT LATER** | gorhom/bottom-sheet v5 | Open Reanimated-4.4 bugs: #2690 mounts-invisible on Android w/ 4.4.0; #2678 worklet `window` crash in 5.2.14 — pin Reanimated 4.3.1 or wait for fixes |
| **ADOPT LATER** | Zeego v3 | Native menus standard but slow cadence; Expo UI context menus may cover first |
| **ADOPT LATER** | react-native-screen-transitions | Shared-element + gesture cinematic transitions on expo-router; API mid-refactor as of Jun 2026 |
| **ADOPT LATER** | NativeWind v5 | Preview only (5.0.0-preview.3); requires Tailwind v4.1 + RN 0.81 + new arch + Reanimated 4 + `react-native-css` peer; v4.2.2 is stable under maintainer danstepanov |
| **WATCH** | Uniwind | Tailwind-v4-native, Unistyles team, reusables-compatible; 238k wk npm downloads; credible NativeWind successor; revisit at v5 decision point |
| **WATCH** | react-native-effects / react-native-shine (WebGPU) | Drop-in GPU effects on background thread; v0.1.x/labs — use Skia today, keep these as the upgrade path |
| **WATCH** | react-native-runtimes (Margelo) | Multi-runtime startup wins for super apps; brand new Jun 2026 |
| **AVOID** | Tamagui | Second styling compiler; conflicts with NativeWind |
| **AVOID** | Moti | Legacy — community consensus is "drop Moti, Reanimated v4 CSS API is the replacement" |
| **AVOID** | expo-glass-effect / liquid-glass libs | Opposite of flat-hairline anti-glassmorphism aesthetic |
| **AVOID** | gluestack-ui | Redundant with reusables |

### Cinematic motion on Expo

For premium dark cinematic motion (film grain, beam sweeps, animated splash) — see the `expo-cinematic-motion` skill. The short version: one full-screen Skia `<Canvas>` overlay, one SkSL `RuntimeEffect` for beam + grain in the same pass, driven by `useClock()` + `useDerivedValue` uniforms (zero React re-renders). Reference implementation: `maazjnr/PremiumWallet_Template`.

## Related Skills

- `mobile-shipping` — native-vs-OTA decision + runtime pre-build simulator smoke
- `mobile-app-security` — securing the RN app (post-bridge cert pinning / secure storage)
- `mobile-ui-testing` — agent-device / Maestro / Detox validation
- `expo-cinematic-motion` — Skia shader splash overlays, film grain, beam sweeps, Reanimated 4.4 CSS motion
- `apple-native` — Swift / SwiftUI internals when authoring iOS native module code
- Vendor: `expo-app-design:*`, `expo-deployment:*`, `upgrading-expo` (Expo-maintained, scaffolded into new projects)
