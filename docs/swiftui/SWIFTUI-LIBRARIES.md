# SwiftUI & Apple Platform Libraries

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Canonical index:** `docs/references/CURATED-COMPONENT-LIBRARIES.md`  
**Implementation skill:** `apple-native` + `apple-platform-design`

Use this doc when Steps 0–5 target **native iOS/macOS (SwiftUI)** rather than Expo. The open-source repo does not ship SwiftUI component source — it ships **references and skills**.

---

## When this doc applies

| Signal | Action |
|--------|--------|
| `stack-profile.json` → `platform: "ios-native"` or Step 3 selects Native iOS (SwiftUI) | Read this doc + invoke `apple-native` |
| Expo / React Native stack | Use `rn-component-library` instead — **not** this doc |
| macOS desktop (Tauri/Electron with web UI) | Use `shadcn` + `macos-design` for chrome — **not** SwiftUI libraries |

---

## Curated SwiftUI ecosystem (links)

| Library / API | Role | Reference |
|---------------|------|-----------|
| **SwiftUI** (Apple) | Default UI framework | https://developer.apple.com/documentation/swiftui |
| **SF Symbols** | Icon system | https://developer.apple.com/sf-symbols/ |
| **Swift Charts** | Native charts | https://developer.apple.com/documentation/charts |
| **SwiftData** | Persistence (when applicable) | https://developer.apple.com/documentation/swiftdata |
| **ViewInspector** | SwiftUI test introspection | Skill `testing-apple` |
| **swift-snapshot-testing** | Visual regression | Skill `testing-apple` |

---

## Sigma wiring by step

| Step | Behavior |
|------|----------|
| **3** | Invoke `apple-platform-design` for HIG, Liquid Glass, motion; record SwiftUI in `stack-profile.json` |
| **5** | Native prototype path → `screens/[screen-id].swift` with `#Preview` (see Step 5 native path) |
| **6** | Optional export `docs/tokens/swiftui-tokens.swift` from design tokens |
| **8** | Record SwiftUI + Swift Charts in technical spec manifest when native |
| **11** | PRD agents invoke `apple-native`, `testing-apple` |

---

## Product boilerplates (Swift)

| Template | Path | Notes |
|----------|------|-------|
| swift-trading | `templates/boilerplates/swift/swift-trading/` | Charts, portfolio (stub) |
| swift-fitness | `templates/boilerplates/swift/swift-fitness/` | HealthKit patterns (stub) |
| swift-social | `templates/boilerplates/swift/swift-social/` | Feed, camera (stub) |

See `templates/boilerplates/products/README.md` for status.

---

## Anti-patterns

- Applying mobile HIG patterns to macOS window chrome (use `macos-design`)
- Mixing SwiftUI native stack with Expo/Reusables in the same app without explicit Step 2 ADR
- Using third-party SwiftUI kits not listed here without documenting in `stack-profile.json` + ADR
