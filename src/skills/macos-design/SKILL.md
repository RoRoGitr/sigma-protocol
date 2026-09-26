---
name: macos-design
description: "Design native-feeling Mac and desktop workspaces with platform-correct windows, clear hierarchy, keyboard-first interactions and verified runtime behavior."
license: MIT
source: https://github.com/davepoon/buildwithclaude
---

# macOS application design

Sigma adaptation of the upstream skill. Select platform conventions for the actual host and task; fixed color, radius and animation recipes are not a substitute for inspecting the interface.

## Begin with the host and workflow

Identify native Swift/AppKit, Tauri, Electron or browser prototype; inspect the existing window and main task. Verify relevant host APIs before using native-window features. Desktop applications need predictable navigation, a clear working area and reachable actions at their supported minimum window size.

- Use real system window controls/title-bar integration in native shells. Do not duplicate traffic lights or fake draggable chrome inside a real app window.
- For a browser-only visual prototype, simulated chrome is optional and must be labeled as presentation, not working host behavior.
- Use the appropriate system font stack when it serves readability and platform fit. Familiar fonts are valid.
- Keep navigation quieter than the working content. Distinguish sidebar, canvas/document, inspector and transient menu through purposeful surfaces and spacing.
- Use the approved palette and semantic tokens; support required appearance modes deliberately. Do not claim both light and dark modes from one tested screenshot.

## Native-feeling interaction

Primary actions should be keyboard-accessible with visible shortcut hints where useful. Preserve familiar text-editing keys and never intercept them without a task-specific reason. Repeated keyboard actions and navigation should respond immediately.

For panes, test supported widths, resizing by pointer and keyboard, expand/collapse, and persistence across rerenders. A saved window or panel preference must not snap back while new content streams.

Use popovers for contextual choices, sheets or dialogs for contained decisions, and inline editing when it is clearer. Menus need visible active/selected states, keyboard navigation, Escape and outside dismissal, viewport collision handling and correct focus return. Do not obscure the focused field with a footer or overlay.

Add drag-and-drop only when it serves an actual supported import/export task. If offered, define accepted types, progress, cancellation and failure; keep an equivalent picker/action. Do not add a decorative attachment or drag affordance without an implementation.

## Composition and components

Inspect relevant desktop references in the state being designed, including open menus, populated content and error states. Record the reference-to-implementation contract in the existing `DESIGN.md`.

Choose components compatible with the project stack and host. Reuse suitable installed primitives for menus, focus management and dialogs. Confirm library/version and installation capability before promising integration. If a dependency is unavailable, record that limitation and verify the authorized alternative; never describe visual imitation as an installed library.

A professional workspace does not need every section enclosed in a card. Use alignment, whitespace, type hierarchy and subtle separators to show structure. Keep diagnostic detail behind disclosure unless it is needed for the current decision. Derive radii, spacing and type from a successful working prototype rather than enforcing one universal numeric scale.

## Custom motion: frequency and purpose

Emil's interaction framework governs custom UI motion when it conflicts with a blanket animation recipe:

- Frequent keyboard actions: immediate; no decorative delay.
- Frequent pointer interactions: minimal feedback where helpful.
- Occasional sheets, popovers and transitions: short, interruptible motion only for orientation or feedback.
- Rare onboarding moments: more expression may fit, but never block the task.

Prefer native host transitions or exact-property CSS for simple behavior. Use spring physics only when gestures or interruptibility justify it. Respect reduced motion, gate hover-only effects to appropriate pointer devices, and avoid layout thrashing. Neither a default duration nor a spring library proves that the interaction feels good.

## Verify the working application

Check a representative slice before scaling the design: open → act → visible result → recover. Test short/long content, loading/empty/error/unavailable states, keyboard and pointer, narrow/wide panes, text scaling, appearance modes required by the brief, and interruptions.

Record **visual fidelity** against the chosen reference separately from **interaction quality**. Builds and unit tests are supporting evidence. Browser validation of a Tauri interface is useful but does not prove native dialogs, macOS window behavior or Windows acceptance. State those limits.

When reviewing UI changes, use a `Before | After | Why` table. Match the approved direction and active step checkpoints; recorded unattended delegation remains valid and this skill adds no additional approval stop.
