# Expo Modules API — native module reference

> Verified 2026-06-04 against docs.expo.dev/modules. Post-bridge (RN 0.85): the JS↔native bridge
> is gone — modules run on TurboModules/JSI. Any wrapped native lib must be new-arch compatible.

## Scaffold

```bash
npx create-expo-module --local my-cool-module   # in-project, auto-linked, no publish
npx create-expo-module my-cool-module           # standalone npm package
```

## Swift definition

```swift
// ios/MyCoolModuleModule.swift
import ExpoModulesCore

public class MyCoolModuleModule: Module {
  public func definition() -> ModuleDefinition {
    Name("MyCoolModule")                 // MUST equal requireNativeModule<>('MyCoolModule')
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

## Kotlin mirror (same DSL)

```kotlin
// android/.../MyCoolModuleModule.kt
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class MyCoolModuleModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("MyCoolModule")
    Constants("PI" to Math.PI)
    Function("hello") { name: String -> "Hello $name" }
    AsyncFunction("delayedGreeting") { name: String, ms: Int ->
      Thread.sleep(ms.toLong()); "Delayed hi to $name"
    }
    Events("onLocationUpdate")
  }
}
```

## JS surface

```ts
import { NativeModule, requireNativeModule } from 'expo';
declare class MyCoolModule extends NativeModule<{ onLocationUpdate: (p: {lat:number;lng:number}) => void }> {
  PI: number;
  hello(name: string): string;
  delayedGreeting(name: string, ms: number): Promise<string>;
}
export default requireNativeModule<MyCoolModule>('MyCoolModule');
```

## Config plugin (mutate native config at prebuild)

```js
// app.plugin.js
const { withInfoPlist } = require('expo/config-plugins');
module.exports = (config, props = {}) =>
  withInfoPlist(config, (cfg) => {
    cfg.modResults.NSLocationWhenInUseUsageDescription = props.locationReason ?? 'We need your location.';
    return cfg;
  });
```

## Local vs published

| | `--local` | standalone package |
|---|---|---|
| Linking | automatic | `npm install` / autolinking |
| Publish | no | yes |
| Use when | app-specific native code | reusable across apps |

## Gotchas

- `Name("…")` must match the `requireNativeModule<>('…')` string exactly, or you get a runtime "module not found".
- After any native edit: `npx expo prebuild --clean && npx expo run:ios` (Metro reload is NOT enough).
- Legacy `NativeModules` / bridge interop is gone in RN 0.85 — do not assume it exists; wrap libs as new-arch native.
