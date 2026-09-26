---
name: image-to-code
description: "Turn a screenshot, Figma file, or screen recording into production-grade, accessible frontend code. Generate-or-segment, extract design tokens, implement, then loop on visual fidelity until it scores. Two non-bypassable gates: accessibility and visual-fidelity. Use when converting a design/mockup/screenshot into a component or page. Triggers on 'screenshot to code', 'figma to code', 'convert design', 'implement from mockup', 'design handoff', 'pixel perfect', 'design fidelity', 'image to code'."
department: engineering
triggers:
  - screenshot to code
  - figma to code
  - convert design
  - implement from mockup
  - design handoff
  - pixel perfect
  - design fidelity
  - image to code
---

# Image to Code

Turn a visual reference into production-grade, accessible frontend. Three input paths (screenshot, Figma, video), one token-extraction layer, and two non-bypassable gates (accessibility, visual fidelity). The image is the source of truth; the code is the translation.

> Capability snapshot, 2026-06: model quality is task- and host-dependent. Select an enabled model from the current host and validate it against the supplied reference; do not treat this snapshot as a routing rule. Detect the project's Tailwind version before producing output. DCGen segmentation and design-loop fidelity scoring remain optional methods. Runs on Claude Code and Codex.

## When to Use

- Converting a screenshot/image of a UI into a component or page
- Implementing from a Figma file or design-system handoff
- Extracting behavior/ARIA from a screen recording into code
- Redesigns where visual quality and fidelity matter

Skip for: from-scratch aesthetic direction with no reference (use `design-taste` + `frontend-design`); backend; native mobile.

## Core DNA

1. **Reference first, code second.** For visual tasks, generate or ingest the reference and analyze it before writing any code. Never freeform-code from "good taste" memory when a reference is available.
2. **Extract tokens, never hardcode.** Pull a two-layer token manifest (primitive vars → semantic aliases → Tailwind `@theme`). No raw hex/px in output.
3. **Accessibility by construction.** A semantic-HTML + ARIA constraint goes in the prompt BEFORE generation; complex widgets use Radix/Headless UI/React Aria. This gate cannot be skipped.
4. **Loop on fidelity.** Non-trivial UI gets a render → screenshot → score → fix loop until it scores or plateaus. Single-pass is for trivial fragments only.
5. **Production-ready, not div-soup.** Loading/error/empty states, error boundaries, responsive smoke, form labels — before "done."

## Key Patterns

### Model selection

| Input | Preferred model | Note |
|-------|-----------------|------|
| Screenshot / raster UI | Gemini 3 Flash / 3.1 Pro Preview, or GPT-5.x | Strong multimodal screenshot reading |
| Figma file / PDF / doc | Claude Opus 4.x | Best on structured design docs |
| Any, with 2+ keys | Run 2 models in parallel | Compare outputs, take the stronger |

Detect Tailwind version from `package.json` before generating: v4 → `@theme` output; v3 → `tailwind.config.js`.

### Path A — Screenshot / image (generate-first when no reference exists)

1. If the task is visual and no reference is supplied, generate the design image(s) first — large, readable, section-specific images (not one tiny compressed board). Generate fresh standalone images per section rather than cropping. Keep heroes clean, spacious, readable at a small-laptop viewport.
2. Deeply analyze: extract typography (family, scale, weight), spacing rhythm, button/input treatment, color, layout structure.
3. Segment-aware generation (DCGen) for complex layouts: decompose into segments → generate per-segment code → reassemble with CSS Grid → run an LLM cohesion pass. Adds ~8-15% visual similarity over single-shot.

Avoid the AI defaults: one giant compressed image, text too small to read, centered-dark-hero clichés, card-inside-card-inside-card, repeated left-text/right-image, weak hierarchy, fake-interface pill/label spam.

### Path B — Figma input

1. Detect Figma URLs / `.fig` / exported JSON.
2. **Component classification first:** map design nodes to EXISTING project components before generating anything new (Builder.io-style index of the component repo). Reuse > regenerate.
3. Two-layer token extraction from Figma variables → semantic aliases → Tailwind `@theme`. Never emit hardcoded values.
4. Iterative import: nav/shell → atoms → molecules → page. Not one giant generation.

### Path C — Interaction / video input

1. Extract behavioral context from the recording (modals, dropdowns, keyboard nav, focus order) BEFORE codegen.
2. Use that behavior to assign correct ARIA roles/labels/handlers — this is how you avoid div-soup with no keyboard support.

### Token architecture (all paths)

```css
/* Output a token manifest, not inline values. Tailwind v4 target: */
:root {
  --blue-600: oklch(0.55 0.2 255);          /* primitive */
}
@theme {
  --color-action-primary: var(--blue-600);   /* semantic alias → utilities */
}
```

### Gate 1 — Accessibility (mandatory, non-bypassable)

- Put a semantic-HTML + ARIA constraint block in EVERY generation prompt before output.
- Complex widgets (dialog, combobox, tabs, menu) → Radix / Headless UI / React Aria, never raw divs.
- Post-generation: run `eslint-plugin-jsx-a11y` at error level.
- BLOCK on: missing accessible name, no keyboard operability, no visible focus, raw `div` with `onClick`, unlabeled form inputs.

### Gate 2 — Visual fidelity loop (mandatory for non-trivial UI)

1. Render → screenshot the result.
2. Score 5 criteria (0-12 each): composition, typography, color/contrast (WCAG AA), visual identity, polish.
3. Gate: `>= 54/60` OR 2 consecutive rounds with zero new issues.
4. Max 10 iterations, then escalate. On 2 consecutive no-improvement iterations, switch the generating model.

### Production-readiness checklist (before completion)

Loading/error/empty states · error boundary · WCAG 2.2 AA (text 4.5:1, UI 3:1) · responsive smoke at 375/768/1440px · no raw `div` onClick / missing `aria-label` · all form inputs labeled. For generative/dynamic UI, constrain to a 20-40 primitive catalog + Zod-validate the model's component selection.

## Anti-Patterns

- Freeform-coding from memory when a visual reference is available; skipping the analyze step.
- One giant compressed image for many sections; cropping old images instead of generating fresh section views.
- Hardcoding hex/px instead of emitting a two-layer token manifest.
- Div-soup with no ARIA / keyboard support; raw divs for dialogs/combobox instead of Radix/Headless UI/React Aria.
- Single-pass generation for non-trivial UI (no fidelity loop); looping forever with no plateau/escalation rule.
- Ignoring the project's existing components (regenerating what already exists) on the Figma path.
- Emitting v3 `tailwind.config.js` when the project is on v4 (detect first).
- Shipping with no loading/error/empty states or unlabeled form inputs.

## Quality Gates

- [ ] Reference generated/ingested and analyzed before any code (visual tasks)
- [ ] Tailwind version detected; output matches (v4 `@theme` / v3 config)
- [ ] Two-layer token manifest emitted; zero hardcoded hex/px in output
- [ ] Figma path: existing components mapped/reused before generating new
- [ ] Video path: behavior extracted → correct ARIA roles/handlers assigned
- [ ] Gate 1: semantic-HTML+ARIA prompt constraint; Radix/Headless UI/React Aria for complex widgets; `eslint-plugin-jsx-a11y` clean; blocks on missing name/keyboard/focus
- [ ] Gate 2: fidelity loop to >=54/60 or 2 clean rounds; max 10 iterations then escalate; model-switch on 2 no-improvement rounds
- [ ] Production checklist: loading/error/empty states, error boundary, WCAG 2.2 AA contrast, responsive smoke at 375/768/1440px, labeled inputs
