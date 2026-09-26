---
name: ux-designer
description: "Design task-centered user journeys, information architecture and interactions with clear next actions, recovery, accessibility and reference-backed prototypes."
triggers:
  - step-3-ux-design
  - step-4-flow-tree
  - step-5-wireframe-prototypes
  - accessibility-audit
  - user-flow-design
---

# UX designer

Start with what the user is trying to accomplish and the setting in which they work. A dashboard, native utility, marketing page and creative experience need different patterns. Do not use a hero and card grid as the default wireframe for every product.

## Frame the task

Record in the existing UX/design artifact:

- Intended user, primary task, entry point and meaningful completion evidence.
- Existing project versus new work; what must stay familiar and what may change.
- Device, window constraints, keyboard/pointer/touch needs and frequency of use.
- The next useful action, what the user needs to understand first, and how they recover from mistakes.

For an existing product, inspect the actual workflow before proposing replacements. Distinguish observed behavior, user requirements and assumptions. Do not ask the user to repeat information already available in the project.

## Reference-to-interaction contract

Inspect the relevant product surfaces and important open states. Record the reference source/date and viewport when available. Translate it into specific behaviors and hierarchy in `DESIGN.md`; a reference URL or aesthetic label alone is insufficient.

For example, a Cursor-like composer brief should specify one writing surface, nearby context/model controls, searchable choices, visible keyboard focus, draft retention, connection disclosure and resizing behavior. It should not inherit coding or tool-execution powers merely because the reference product has them.

Use `design-taste` for visual direction and the platform skill for host conventions. Resolve conflicts explicitly: approved product constraints first; platform semantics for the host; frequency and purpose for custom motion. Do not substitute decoration for a usable flow.

## Map the journey

For each important flow, record:

| Item | What to define |
| --- | --- |
| Entry | Where the user starts and the context already present |
| Next action | The control they can find and what it changes |
| Evidence | The visible result that confirms the action worked |
| Recovery | Back, cancel, retry and undo behavior where supported |
| Boundaries | Permissions, disabled capability, saved versus unsaved work |
| Completion | What is finished and what still requires review or external work |

Maintain stable screen, flow and artifact IDs across Steps 3–7. Link alternate paths to their source decision. Map loading, no results, empty, validation, permission, error and interrupted work alongside the successful path. Preserve entered data where safe; avoid reset-on-render behavior.

## Match patterns to the work

- **Workspaces:** predictable navigation, concise headers, compact lists where comparison matters, contextual inspectors and clear selected state.
- **Composers:** one writing area, relevant context, honest model/tool choices, streaming and stop/retry states, preserved drafts and readable responses.
- **Complex forms:** logical groups, progressive disclosure, visible dependencies, explicit validation and recovery without losing entries.
- **Marketing:** a clear promise, credible proof, coherent narrative and appropriate calls to action.
- **Onboarding:** short guidance beside real work, an obvious starting action, and resumable progress. Tutorial completion must not imply that the underlying task passed review.

Keep controls consistent in meaning and placement. Use space and typography before adding containers. Expose advanced controls when they help the current decision; avoid showing implementation details that do not help the user act.

## Prototype before scaling

Choose one representative end-to-end slice before producing every screen. Verify component and stack feasibility in Step 2. In Step 5, render and operate the selected slice with realistic content and difficult states. Compare the result against the reference contract before standardizing it in Step 6.

If the stack cannot use the requested library, surface that early. An authorized native alternative is possible, but its accessibility and behavior still need proof. Respect recorded unattended authorization and the step's existing checkpoints; this skill adds no independent permission flow.

## Accessibility and platform fit

Use semantic controls, associated labels, logical focus order, visible focus and meaningful error announcements. Convey status with text or shape as well as color. Check contrast, text scaling, reduced motion and narrow-window behavior.

Size controls for their input mode and applicable accessibility requirements. Prefer generous touch targets, commonly 44px; compact pointer interfaces can use a different scale while meeting target-size and spacing requirements. Do not impose marketing typography or phone layouts on a desktop inspector. Use platform conventions and test them in the actual host when available.

Keyboard use must not wait for decorative animation. Menus need search/arrow/Enter/Escape behavior where appropriate, a visible active choice and correct focus return. Drag-based actions need a keyboard or single-pointer alternative.

## Deliver and review

The UX artifact should contain the task, flow, chosen patterns, screen/component requirements, accessibility behavior and acceptance evidence. Use diagrams or wireframes where they clarify relationships; a static diagram does not prove a live interaction.

Report visual fidelity and interaction quality separately. Review actual rendered output and run the user journey; a successful build does not prove either result. When reviewing UI changes, use a `Before | After | Why` table and name the next correction precisely.
