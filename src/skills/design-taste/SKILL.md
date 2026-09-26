---
name: design-taste
description: "Choose and verify a visual direction from the product brief, brand and references. Use for UI design, redesign and visual review; adapt marketing patterns to their proper scope."
---

# Design taste for Sigma

Start with the user's product and existing visual system. Distinctive design must help the intended user understand and act. Do not replace a functioning brand with a fashionable preset.

## Provenance and upstream status

Sigma maintains this project-specific skill; it is not an untouched upstream Taste Skill installation. Reviewed 2026-09-19 against [Taste Skill's changelog](https://github.com/Leonxlnx/taste-skill/blob/e79ca9ec7e071eb3a3b623c4fb752e853fc3ed58/CHANGELOG.md). Upstream v2 is experimental and adds brief inference, design-system selection and a preserve-versus-overhaul redesign process. Its marketing-focused default explicitly excludes dashboards, complex forms and native mobile. Apply transferable ideas to those products through their own platform and usability guidance, not the marketing recipe.

Upstream updates are inputs for review, not permission to replace user files or global skills. Record the revision, license, changed behavior and a representative before/after comparison before adopting another update.

## Read the brief before selecting a style

State one short design read: product/page kind, audience, primary task, brand constraints, reference signals, device/input modes and success evidence. Identify whether this is greenfield, preserve, or an explicitly authorized overhaul.

Use the existing system when one exists. When adopting Material, Fluent, Carbon, Polaris, Primer, GOV.UK, USWDS or a platform-native system, verify the actual official components and applicable version. Describe an aesthetic imitation as an approximation, not an official implementation.

For a genuinely open direction, propose a small number of meaningfully different options with a reason each fits the brief. References need URLs, dates and the specific lesson taken from them. A reference is not permission to copy assets or layout wholesale.

## Reference-to-implementation contract

Inspect the actual surface being designed: a model menu in its open state, a populated workspace, or a form showing recovery. A homepage screenshot cannot establish an IDE composer's behavior. Prefer a small set of relevant first-party examples over a large mood board. Capture the source URL/date, observed states and viewport when available; label behavior inferred from a static image.

In the existing `DESIGN.md`, record a short table:

| Reference observation | Product decision | Implementation | Acceptance evidence |
| --- | --- | --- | --- |
| The writing area and model control share one surface | Keep composition and model choice together | Compatible input/command/popover primitives verified in this stack | Rendered composer plus keyboard and draft-retention checks |
| Navigation has lower emphasis than work content | Use quieter chrome and clear current location | Semantic surfaces, type and selected-state tokens | Populated and empty views at supported window sizes |

Include preserved brand/product constraints, chosen density, type hierarchy, surface/border roles, component choices and important states. Describe observable differences rather than relying on modern, premium, clean or anti-slop labels. Do not prescribe one product's layout for every category.

Before batching screens, build the representative Step 5 slice and compare it to this contract. If the user's complaint is about structure or behavior, a palette/radius-only restyle does not address it. Under delegated checkpoints, proceed with recorded assumptions and evidence; do not invent an approval or add new permission gates.

## Ownership and conflict resolution

The product brief and approved direction decide the experience. Platform guidance owns actual host semantics; Step 6 owns reusable tokens; Step 7 owns state behavior. Use frequency and purpose for custom motion: repeated keyboard actions are immediate, while occasional transitions can explain a change. Familiar fonts, neutral surfaces and restraint remain valid even when another skill's marketing examples suggest expressive decoration.

Confirm stack/component feasibility before committing to a visual library. Distinguish a researched reference, a copied/adapted component, an installed dependency and a tested integration. An unavailable package or renderer is a named limitation, not permission to bypass a restriction or claim the desired implementation exists.

## Visual controls

`DESIGN_VARIANCE`, `MOTION_INTENSITY` and `VISUAL_DENSITY` are optional 1–10 shorthand for communicating choices, not measured quality scores. Derive them from the task. A dense trading workspace and a public landing page should not inherit the same values.

Existing Sigma mode labels remain shorthand:

- **Premium / Agency:** deliberate composition and asset direction for marketing when the brief supports it.
- **Editorial-Minimal:** typography and information hierarchy with restrained decoration.
- **Brutalist-Tactical:** an explicitly chosen graphic language; legibility and accessibility still apply.
- **GPT-strict:** legacy label for structured visual review. It does not require simulated randomness, a reasoning transcript, or mandatory GSAP effects.

Choose a coherent direction and explain its relationship to the brand. Inter, purple, centered layouts, equal columns and rounded corners are not inherently wrong. Challenge unexamined defaults; preserve intentional choices that serve the product. Respect the approved Step 3 direction.

## Implementation and artifact handoff

- **Canvas:** Pen.dev can supply `.pen` artifacts and documented exports. Confirm the actual installed interface, authentication and export capability. Save the editable source and screenshots; an export is not proof that production behavior works.
- **Direct:** render a prototype in the chosen project stack using its existing components. Taste Skill guides design decisions; it is not a runtime or renderer.
- **Optional host:** [TasteCode](https://github.com/Leonxlnx/tastecode/tree/b65a844f7ed6e1d6816d482a48508076fd7383fa) is an early-beta desktop host with Design Mode. Do not invent a CLI/MCP endpoint or native-mobile support. Use only capabilities actually present.

Capture artifact paths, source/tool versions, viewport, scope, approval and remaining gaps. Map source elements to stable screen/flow IDs and implementation components. Do not turn a mockup into a claim of implemented functionality.

## Content, interaction and motion

Use real approved content. Never invent customer quotes, logos, revenue, adoption counts or more plausible-looking fake numbers. Mark fixtures as sample data and keep them out of marketing proof.

Derive type scale, palette, spacing, density and component states from the selected direction. Check real content lengths, localization, keyboard/focus behavior, touch interaction and contrast. Existing labels, routes, form fields, legal text and data behavior do not change silently during a visual redesign.

Motion needs a purpose, an implementation and a reduced-motion alternative. Prefer simple native behavior; use an installed motion library when it earns its cost. Profile substantial effects rather than treating a library name or fixed duration as a performance guarantee. No content or primary action may depend on completing an animation.

For AI features only, show partial/streaming output, interruption, uncertain results, refusal, cancellation, retry/resume, failure after partial action and the appropriate approval boundary. Test representative actual outputs or clearly labeled fixtures, not one ideal screenshot.

## Review evidence

Before calling the visual work ready, record:

- Selected brief-derived direction and preserved brand/product constraints.
- Editable source and actual rendered evidence on representative screen sizes and input modes.
- Important interaction states, content extremes and flow coverage.
- Accessibility checks and reduced-motion behavior where motion exists.
- Source-backed content and asset rights; no fabricated proof.
- Comparison with the approved direction, recorded limitations and the relevant phase approval.

`DESIGN.md` records the decisions and invariants. Step 6 owns reusable tokens; Step 7 owns complete state behavior; the implementation skills own stack mechanics. Keep those responsibilities separate.

## Evaluation briefs

Use [the workspace, composer and complex-form briefs](references/evaluation-briefs.md) to assess this design workflow after meaningful revisions. These are behavioral evaluation tasks, not automatic proof of visual quality. Report visual fidelity and interaction quality independently, retain evidence, and mark an evaluation not run when no actual run occurred.
