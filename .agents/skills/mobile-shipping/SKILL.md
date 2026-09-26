---
name: mobile-shipping
description: "The 'how do I ship this change' DNA for Expo iOS/Android apps. Native-vs-OTA decision matrix (icon/splash/native modules require a build; JS/images/copy/logic use eas update) plus a deterministic pre-build simulator smoke test before burning an EAS slot. Use when planning a release, triaging a change, or verifying a build before submission. Triggers on 'eas build', 'eas update', 'OTA update', 'over the air', 'new build', 'app icon update', 'native change', 'simulator smoke', 'pre-build verify', 'do we need a new build', 'mobile ship'."
department: engineering
triggers:
  - eas build
  - eas update
  - OTA update
  - over the air
  - new build
  - app icon update
  - native change
  - simulator smoke
  - pre-build verify
  - do we need a new build
  - mobile ship
  - before eas build
---

# Mobile Shipping

The "what/how do I ship this change" DNA for Expo iOS/Android apps. Two inseparable halves: knowing **whether a change needs a new native build or an OTA push**, and **verifying the build works on device before burning the slot**.

> Version anchor: EAS CLI 20.0.0, Expo Updates fingerprint v0.18. Verified 2026-06-04.

## When to Use

- Planning what to ship: "do we need a new build or can we OTA this?"
- Before running `eas build --profile production`
- After any change to auth flow, navigation, native modules, or screen-mount hooks
- When EAS build slots are limited and you need confidence before burning one

## When NOT to Use

- Pure JS/TS refactors that only change business logic — use `expo export:embed --eager` to check the bundle, then `eas update` directly
- EAS build failures after smoke passes — use the `expo` skill's `references/eas-build-debugging.md`
- Android-only builds — Android emulator pre-build verification is analogous; adapt the `xcrun simctl` steps to `emulator`/`adb`

---

## Part 1: Native Build vs OTA Decision Matrix

The single most-asked question on a shipping mobile app: **"Do we need a new build for this change?"**

The answer depends on whether the change touches the **native bundle** (baked into the IPA/APK at build time) or the **JavaScript bundle** (loaded at runtime by Expo Updates).

| Change | Path | Time to user |
|--------|------|--------------|
| App icon (home-screen) | New build + TestFlight/Play Store | 25–60 min |
| Splash screen image | New build + TestFlight/Play Store | 25–60 min |
| App display name | New build + TestFlight/Play Store | 25–60 min |
| App version number bump | New build | 25–60 min |
| Bundle identifier change | New build + new App Store record | 60+ min |
| New permission (camera, location, push) | New build | 25–60 min |
| Native module added/removed | New build | 25–60 min |
| Any change in `app.json` `ios:` or `android:` block | New build | 25–60 min |
| CocoaPods version pin change | New build | 25–60 min |
| Anything in `Info.plist` or `AndroidManifest.xml` | New build | 25–60 min |
| **JS code (.ts/.tsx/.js)** | `eas update --channel production` | ~30 sec |
| **In-app images loaded via `require()`** | `eas update --channel production` | ~30 sec |
| **Fonts loaded via JS** | `eas update --channel production` | ~30 sec |
| **NativeWind / Tailwind classes** | `eas update --channel production` | ~30 sec |
| **API endpoints, auth logic, business logic** | `eas update --channel production` | ~30 sec |
| **Copy text, error messages, translations** | `eas update --channel production` | ~30 sec |
| **Push notification handler logic** (not registration) | `eas update --channel production` | ~30 sec |

### Why app icons can't be OTA'd

The app icon and splash screen live in iOS's compiled `Assets.car` archive inside the IPA. iOS reads them from the bundle at install time, not at app launch. Changing them requires a new IPA → new TestFlight build → user update.

OTA updates swap only the JavaScript bundle. Native assets are baked at compile time.

### How OTA updates work

Expo Updates is a runtime inside your app that checks for a new JS bundle on launch:

```bash
eas update --channel production --message "Fix booking confirmation copy"
```

The bundle uploads to Expo's CDN. Each app launch:
1. App fetches the update manifest for its channel
2. If a newer bundle exists with a matching `runtimeVersion`, it downloads in background
3. The new bundle loads on the **next** app launch (not the current one)

`reloadAsync()` forces immediate apply but most apps accept the next-launch behavior.

### Runtime version gating

Each EAS build has a `runtimeVersion` (set in `app.json`). OTA updates only apply to builds with the **same** runtime version.

**Bump runtime version when:**
- Adding/removing/upgrading any native module
- Upgrading Expo SDK
- Adding new permissions

**Do NOT bump runtime version for:**
- Pure JS changes
- Adding JS-only npm packages
- UI/UX changes

> **SDK 56 + fingerprint v0.18 note:** `@expo/fingerprint` 0.18 makes runtime-version channel resolution finer-grained. It uses a hash of your native configuration rather than a manually declared string. If you use `"runtimeVersion": { "policy": "fingerprint" }` in `app.json`, fingerprint v0.18 catches more native-impacting changes automatically — including changes to certain `app.json` fields that older versions missed. Check `npx @expo/fingerprint compare` before and after a change if you're unsure whether the fingerprint changed.

### Channel layout

```json
// eas.json
{
  "build": {
    "preview": { "channel": "preview" },
    "production": { "channel": "production" }
  }
}
```

Standard channels:
- `preview` — internal TestFlight/internal track builds; test OTA fixes here first
- `production` — App Store / Play Store builds
- `staging` / `dev` — testing-only environments

### Practical workflows

**Bug fix (copy, wrong API endpoint, logic error):**

```bash
git add . && git commit -m "fix: copy"
eas update --channel production --message "Fix copy"
# Done. Users get it on next app launch — no Apple review.
```

**Native change (icon, splash, new dependency):**

```bash
git add . && git commit -m "chore: new app icon"
eas build --profile production --platform ios --non-interactive
# Wait ~7–10 min, then submit via EAS or direct upload
```

**Mixed change (icon + JS feature):**

Treat as native — ship as one new build. Splitting into separate `eas build` + `eas update` cycles creates version confusion and doubles notification noise.

**Hotfix after a TestFlight build is in review:**

```bash
# Fix the JS bug, commit
eas update --channel production --message "Hotfix: payment retry"
# Existing TF testers get the fix on next launch. No new build needed.
```

### Configuring Expo Updates (if not already wired)

```json
// app.json
{
  "expo": {
    "runtimeVersion": "1.0.0",
    "updates": {
      "url": "https://u.expo.dev/<project-id>",
      "fallbackToCacheTimeout": 0
    }
  }
}
```

If `updates.url` is missing, run `eas update:configure`. Create one new build after configuring — existing builds won't pick up the URL change.

---

## Part 2: Pre-Build Simulator Smoke Test

Run this before every `eas build --profile production`. `expo export:embed --eager` catches bundle-time errors only. It does NOT catch runtime crashes, visual bugs, navigation regressions, or DB integration failures. The simulator boot exercises the whole stack the same way an end user does.

### Tooling

- **iOS Simulator** (`xcrun simctl`) — boot, install, screenshot, terminate apps from CLI
- **`xcodebuild`** — build the local dev client (avoids burning an EAS slot for verification)
- **Computer-use / simulator-driver MCP** — drive interactive taps through critical user flows. If your development environment has a computer-use or simulator-driver MCP available, use it for Steps 6–12. If not, drive interactions manually and screenshot each step.

### When to run

- Before every `eas build --profile production --platform ios` (mandatory)
- After any change to:
  - Auth flow (sign-in / sign-up / onboarding)
  - Native module imports
  - Navigation structure (new screens, changed routes)
  - Screen-mount critical hooks (anything that runs at component render time)
  - App icon, splash, or asset configuration

### 12-Step Verification Flow

Adapt the screen-specific assertions to your app. The 12-step skeleton is universal.

**1. Boot simulator**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
open -a Simulator
```

**2. Build dev client locally**

```bash
cd ios && xcodebuild \
  -workspace <App>.xcworkspace \
  -scheme <App> \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build/sim \
  build
```

**3. Install on simulator**

```bash
xcrun simctl install "iPhone 16 Pro" \
  ios/build/sim/Build/Products/Debug-iphonesimulator/<App>.app
```

**4. Launch app, screenshot splash**

```bash
xcrun simctl launch "iPhone 16 Pro" com.<bundle>.id
sleep 2
xcrun simctl io "iPhone 16 Pro" screenshot /tmp/04-splash.png
```

Assertion: splash logo visible (not blank, not invisible-on-background).

**5. Screenshot auth landing**

Wait for splash to dismiss (~2–3s), screenshot.
Assertion: login screen rendered with logo and auth buttons.

**6. Tap "Sign in with email"** via computer-use / simulator-driver MCP (or manually)

**7. Enter test credentials** (email + password fields)

**8. Tap "Sign In", screenshot post-auth screen**

Assertion: lands on expected onboarding or home screen (not an error alert).

**9. Walk through onboarding** (if applicable)

Each step: tap selection → tap Next → screenshot.

**10. Reach main app, screenshot home tab**

Assertion: no error alert, app routes to main tabs correctly.

**11. Screenshot key feature screen + tap primary action**

Assertion: primary create/submit action renders correctly; no crash (common crash site for `crypto.randomUUID()` gaps and native API mismatches).

**12. Screenshot remaining tabs**

Assertion: all tabs render; avatar/profile loads; no blank screens.

### Codified script template

```bash
#!/usr/bin/env bash
# scripts/simulator-smoke.sh
set -euo pipefail

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_NAME="iPhone 16 Pro"
APP_BUNDLE_ID="com.example.app"
APP_NAME="ExampleApp"
RUN_DIR="$PROJECT/docs/validation/$(date +%Y%m%d-%H%M%S)-smoke"
mkdir -p "$RUN_DIR"

echo "=== Boot simulator ==="
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator
sleep 5

echo "=== Build local dev client ==="
cd "$PROJECT/ios"
xcodebuild \
  -workspace "$APP_NAME.xcworkspace" \
  -scheme "$APP_NAME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath build/sim \
  -quiet build || { echo "FAIL: xcodebuild failed"; exit 1; }

echo "=== Install ==="
APP_PATH="$PROJECT/ios/build/sim/Build/Products/Debug-iphonesimulator/$APP_NAME.app"
xcrun simctl install "$SIM_NAME" "$APP_PATH"

echo "=== Launch + screenshots ==="
xcrun simctl terminate "$SIM_NAME" "$APP_BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$SIM_NAME" "$APP_BUNDLE_ID"

sleep 2 && xcrun simctl io "$SIM_NAME" screenshot "$RUN_DIR/04-splash.png"
sleep 3 && xcrun simctl io "$SIM_NAME" screenshot "$RUN_DIR/05-auth-landing.png"

# Steps 6-12: interactive — use computer-use/simulator-driver MCP from your agent
# session, or capture screenshots manually after each interaction.

echo "=== Smoke run complete. Screenshots: $RUN_DIR ==="
ls "$RUN_DIR"
```

Wire into `package.json`:

```json
{
  "scripts": {
    "smoke:ios": "bash scripts/simulator-smoke.sh"
  }
}
```

### Failure protocol

A smoke failure → STOP. Do not run `eas build`. Fix the bug locally, re-run smoke, confirm green, then proceed with the build.

### Why smoke beats `expo export:embed --eager`

`expo export:embed --eager` catches bundle-time errors (missing imports, syntax bugs, broken package mains). It does NOT catch:

- Runtime crashes from native API gaps (e.g., `crypto.randomUUID()` not in Hermes)
- Visual bugs (icon-on-icon, white-on-white, wrong layout)
- Navigation regressions (button leads to wrong screen)
- DB / auth integration failures
- Permission flow regressions

The simulator boot exercises the whole stack end-to-end.

---

## Pre-EAS Gates (run all before burning a slot)

```bash
# 1. Type-check
npx tsc --noEmit

# 2. Lint
npx eslint . --ext .ts,.tsx

# 3. Expo doctor
npx expo-doctor

# 4. Bundle smoke (catches import errors)
EXPO_PUBLIC_DEV_MODE=false ./node_modules/.bin/expo export:embed --eager \
  --platform ios --dev false \
  --bundle-output /tmp/eager.bundle \
  --assets-dest /tmp/eager-assets

# 5. Simulator smoke (catches runtime errors)
npm run smoke:ios
```

All 5 must pass before running `eas build`.

---

## Quality Gates

- [ ] Decision matrix consulted — confirmed whether a new build is actually required
- [ ] Runtime version bumped if native modules or SDK changed
- [ ] Fingerprint compared before/after if using `policy: fingerprint` (`npx @expo/fingerprint compare`)
- [ ] All 5 pre-EAS gates pass (typecheck, lint, expo-doctor, eager embed, simulator smoke)
- [ ] Simulator smoke covers: splash → auth → onboarding → home → primary action
- [ ] Smoke failure stops the release — no `eas build` until smoke is green

## Related Skills

- `expo` — SDK version facts, Expo Modules API, EAS build debugging recipes
- `mobile-ui-testing` — agent-device, Maestro, Detox for behavioral E2E tests
- `apple-native` — Swift / SwiftUI internals when the native layer is the root cause
