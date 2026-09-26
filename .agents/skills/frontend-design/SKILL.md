---
name: frontend-design
description: "Implement polished interfaces from the product's task, platform, inspected references and approved design direction. Use for applications, desktop workspaces, websites and component design."
triggers:
  - step-9-landing-page
  - scaffold
  - ui-healer
  - implement-prd
  - component-design
---

# Frontend design

Build an interface that makes the intended work clear and dependable. Use `design-taste` to establish the direction, the relevant platform skill for host conventions, and this skill to implement the result. An adjective such as modern, premium or Linear-like is a starting brief, not an acceptance criterion.

## Select the product category first

| Surface | Design priority | Apply when justified |
| --- | --- | --- |
| Product workspace, dashboard or IDE | Task hierarchy, readable density, predictable controls, persistent working context | Compact rows, inspectors, command menus and progressive disclosure |
| Native or desktop application | Window behavior, keyboard conventions, adaptable panes, platform integration | Native title bars, system fonts and restrained materials |
| Marketing or editorial site | Message, proof, visual narrative and conversion | Expressive type, imagery, asymmetry or larger transitions |
| Creative or exploratory experience | An explicit creative brief and usable interaction | Unconventional composition and purposeful effects |

Do not transfer landing-page defaults to a frequently used workspace. Familiar fonts, neutral backgrounds, familiar layouts and ordinary radii are valid choices. There is no universal requirement for extreme styling, contrasting display fonts, gradients, texture, a hero section or a page-load animation.

## Inspect before implementing

1. Read the current screen, its callers, existing components and styles. Identify what stays and what the user has authorized changing.
2. Inspect a small set of task-relevant references. For a composer, inspect the composer and open model menu, not only the reference product's landing page. Record screenshots or observed states, source/date and viewport where available.
3. In the existing `DESIGN.md`, connect each reference to specific choices: hierarchy, spacing, surfaces, typography, component behavior and acceptance evidence. Separate observed facts from inferred behavior. Inaccessible reference states remain unverified.
4. Check the selected stack and installed components before promising a library. Confirm package/version, host compatibility, required dependencies, licensing and the ability to render it. A visual approximation is not an installed shadcn, Radix, Base UI or AI Elements component.

A compatible installed component is usually preferable to a new implementation of focus management, menus or resizing. A package name does not establish integration quality. If installation is unavailable or rejected, explain the limitation, use only an authorized alternative and test that alternative separately; do not bypass the restriction or claim the requested library is present.

## Build one representative working slice

Start with the interaction most likely to determine whether the product feels right. For a planning workspace this may be navigation → composer → searchable model selection → response; for a form, editing → validation → recovery → submit.

Use realistic approved content, including long labels and empty/error states. Never invent metrics, testimonials or working integrations for visual effect. A clearly labeled fixture can test rendering but cannot establish a live integration.

Before spreading the treatment across screens, compare the running slice with the reference contract. If the result remains wrong, revisit composition, grouping, control choice or interaction flow. A palette or radius change alone is not a structural redesign. Honor any recorded unattended delegation; do not add new approval stops beyond the active workflow.

## Compose a coherent system

- Make the primary task and next action apparent. Supporting navigation and metadata should recede.
- Use borders, backgrounds and elevation to communicate relationships. Do not wrap every label, section and action in another card.
- Keep related controls together. A composer normally has one writing surface with nearby context, model and send/stop controls; connection diagnostics can use progressive disclosure.
- Use semantic tokens from Step 6. Adjust the existing cascade rather than repeatedly appending overrides. Preserve layout rules while changing appearance.
- Keep real behavior behind every affordance. Do not add decorative attachment, microphone, model or tool controls with no working capability.
- Preserve drafts, focus, selection and scroll intent across updates. A render must not reset a chosen pane width or overwrite unsent text.

## Motion ownership

Platform guidance controls native host behavior. The approved product direction controls aesthetics. For custom motion, use Emil's frequency-and-purpose approach: repeated keyboard actions are immediate, frequent navigation stays fast, and occasional transitions need a clear orientation or feedback purpose. Prefer exact-property CSS transitions for simple interactions; use springs or another installed library only when interruptibility or gestures justify it. Respect reduced motion and never delay access to content until an animation ends.

## Acceptance: two independent results

**Visual fidelity:** inspect actual renders at relevant window sizes. Compare hierarchy, alignment, density, type, contrast and surfaces with the selected direction. Inspect empty, populated and long-content states. A screenshot of a happy path is insufficient.

**Interaction quality:** operate the slice by keyboard and pointer. Verify disabled choices, search/no-results, focus return, outside dismissal, scrolling, resizing, loading, failure, cancellation and draft retention where applicable. Use a real supported connection for integration claims; identify simulated results explicitly.

Builds and unit tests support these checks but do not replace them. Report which result passed, which remains unverified and the evidence paths. When reviewing changes, use a `Before | After | Why` table. Never award visual acceptance solely from source code, a rubric score or the presence of a named library.

## Handoff

Update the existing design record with the chosen pattern, implementation component, rendered evidence, tested interactions and remaining limitations. Step 5 proves the representative slice, Step 6 formalizes reusable decisions, and Step 7 specifies complete state behavior. Keep the brand and product constraints consistent across those handoffs.
