---
name: apple-platform-design
description: "Apple-platform design DNA — Liquid Glass (iOS/macOS 26+), spring/PhaseAnimator/KeyframeAnimator motion, matched-geometry hero transitions, SF Symbol effects, HIG fundamentals, and native macOS layout (traffic lights, window chrome, sidebar, keyboard, light+dark). Use when designing Apple-native UI or a Mac-style desktop app, or simulating macOS chrome in a web artifact. Covers the design side; platform build/engineering (SwiftUI internals, Xcode) lives in the mobile pass. Triggers on 'apple design', 'liquid glass', 'glass effect', 'spring/bounce/snappy', 'macos app', 'native feel', 'sidebar layout', 'traffic lights', 'SF Symbols', 'HIG'."
department: engineering
triggers:
  - apple-design
  - liquid-glass
  - glass-effect
  - macos-design
  - native-feel
  - sf-symbols
  - hig
  - phase-animator
  - keyframe-animator
  - desktop-app-design
---

# Apple Platform Design

The design DNA that produces "it feels like Apple built it" across iOS and macOS — Liquid Glass material, spring motion, SF Symbol effects, HIG discipline, and native Mac window/layout patterns. This is the **design** layer; SwiftUI engineering internals and Xcode workflows live in the mobile pass.

## When to Use

- Designing iOS/macOS-native UI (iOS 26+ / macOS 26+) or anything that must "feel native."
- Glass effects, transparency, vibrancy, blur.
- Spring/bounce/snappy motion, PhaseAnimator/KeyframeAnimator, matched-geometry hero transitions, SF Symbol effects.
- Building a macOS desktop app (Tauri/Electron/native) or simulating Mac window chrome in a React/HTML artifact.

## Core DNA

### Platform consistency

- Follow the Human Interface Guidelines; use system-provided APIs over custom reimplementations.
- Respect the user's appearance preference (`@Environment(\.colorScheme)` / `prefers-color-scheme`) — design both modes, never auto-invert.
- Default to system fonts: SF Pro Display (headings), SF Pro Text (body), SF Mono, New York. Web stack: `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text"`.
- Animation is feedback. Every state change animates; no instant snaps.

### Liquid Glass (iOS 26+, macOS 26+)

Glass is a **focal** material — if everything is glass, nothing is. Reserve it for primary surfaces; use tints to signal prominence (primary action = accent-tinted glass, secondary stays neutral). Pair with subtle layered shadows (5–10% opacity), never heavy drop shadows. Test in light AND dark — glass behaves differently per appearance.

```swift
// SwiftUI
View().glassEffect()
View().glassEffect(.regular.tint(.blue))        // prominence/state
View().glassEffect(.regular.interactive())      // responds to touch

// Batch multiple glass surfaces so the renderer composites them together
GlassEffectContainer {
  HStack {
    Button("One") { }.glassEffect()
    Button("Two") { }.glassEffect()
  }
}
```

```swift
// AppKit
let glass = NSGlassEffectView()
glass.material = .hudWindow   // or .sidebar, .menu, .popover
glass.tintColor = .systemBlue
```

Web simulation: `backdrop-filter: blur()` for vibrancy, kept on fixed/sticky layers only.

## Key Patterns

### Motion

Spring physics, never `linear` (mechanical). Three API generations:

```swift
// Modern (iOS 17+) — preferred
.animation(.spring(.snappy), value: state)   // tight, responsive
.animation(.spring(.bouncy), value: state)   // playful overshoot
.animation(.spring(.smooth), value: state)   // gentle, no overshoot
.animation(.spring(duration: 0.4, bounce: 0.3), value: state)

// Legacy (iOS 13–16)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: state)
```

- **PhaseAnimator** for multi-stage progression through named phases (e.g. heart scale → fade), with a different animation curve per phase.
- **KeyframeAnimator** for precise multi-property timing (`KeyframeTrack(\.scale)` + `KeyframeTrack(\.rotation)` running on independent timelines).
- **Matched geometry** for hero transitions: same `matchedGeometryEffect(id:in:)` on source and destination across navigation.
- **SF Symbol effects** (iOS 17+): `.symbolEffect(.bounce, value: count)`, `.pulse`, `.wiggle, options: .repeat(3)`, `.breathe, options: .speed(0.5)`.
- **Completion callbacks**: `withAnimation(.spring(.bouncy)) { … } completion: { triggerHaptic() }`.
- Web equivalents: `200–300ms`, `cubic-bezier(0.25,0.1,0.25,1)` (easeOutQuart) or a subtle spring; never linear.

### Native macOS layout

A native app is a **system tool**, not a website in a window — appear when needed, get out of the way after.

Pre-flight checklist before any Mac UI:
1. Layout: top bar for global actions, sidebar for navigation (skip if minimal), center for content.
2. Traffic lights integrated into the chrome (top bar or sidebar) — never floating awkwardly over content.
3. Top ~50px draggable and uncluttered (window drag zone).
4. Show empty states; progressive disclosure — reveal UI only when useful.
5. Keyboard shortcut for every primary action, each with visual feedback.
6. Design light AND dark; do not invert.
7. Search always prominent (floating bar or command palette).
8. Drag-and-drop content IN and OUT — non-negotiable for native feel.
9. Micro-animation on every state change.
10. Onboarding brief and modal, teaching shortcuts by doing.

Web-artifact specifics: simulate window chrome (title bar, three traffic-light dots, rounded corners). Radii: 10px windows, 8px cards, 6px buttons, 4px inputs. Dark bg `#1e1e1e`–`#2a2a2a` (not pure black); light bg `#fafafa`–`#ffffff` (not pure white). Spacing on a 4px base (4/8/12/16/24/32/48/64), generous card padding (16–24px). Headings tight `-0.02em`–`-0.04em`; line-height 1.4 UI / 1.6 reading.

Interaction: hover = 5–10% background shift (not borders); active = `scale(0.98)`; focus ring = system accent, 2–3px with offset; toasts top-right, auto-dismiss 3–4s; popovers originate from trigger with arrow; modals center with backdrop blur, ESC to dismiss; system accent used sparingly for primary actions only.

## Anti-Patterns

- Glass on everything — it stops reading as a focal material.
- Heavy single drop shadows that look "designed"; pure-black/pure-white backgrounds.
- Floating traffic lights disconnected from window content.
- Web-first layouts in a Mac app (`max-width: 1200px` centered).
- Linear easing; instant state changes with no transition.
- System-blue everywhere instead of reserved for primary actions.
- Loading spinners with no context — use skeletons or progress.
- Modals for everything — prefer inline editing, popovers, sheets.
- Inverting light/dark instead of designing both.

## Quality Gates

- [ ] Every interactive element has a hover/press state; every state change animates (no snaps)
- [ ] Glass reserved for primary surfaces; tints signal prominence; batched in `GlassEffectContainer`
- [ ] Light and dark both designed, not auto-inverted; not pure black / pure white
- [ ] SF Symbols animate on change; hero transitions use `matchedGeometryEffect`
- [ ] Motion is spring/easeOut, never linear; reduced-motion respected (`@Environment(\.accessibilityReduceMotion)` / `prefers-reduced-motion`)
- [ ] Haptics on key interactions (`UIImpactFeedbackGenerator`)
- [ ] (macOS) traffic lights integrated, top 50px draggable, keyboard shortcut per primary action, drag-in-and-out supported
- [ ] System font stack; accent color used sparingly for primary actions
