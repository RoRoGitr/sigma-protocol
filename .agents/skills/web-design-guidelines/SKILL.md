---
name: web-design-guidelines
description: "Reviewer for modern web interface quality — live-fetches the Web Interface Guidelines and checks responsive, accessibility (WCAG 2.2), interaction, performance, and forms rules, emitting terse file:line findings. Use to 'review my UI', 'check accessibility', 'audit design', 'review UX', or 'check my site against best practices'. Owns review/audit, not taste DNA (design-taste) or tokens (design-tokens). Triggers on 'review my UI', 'web interface guidelines', 'audit design', 'check accessibility', 'responsive review', 'UX review'."
department: engineering
triggers:
  - web-design-guidelines
  - ui-review
  - accessibility-check
  - design-audit
  - responsive-review
  - ux-review
---

# Web Design Guidelines

Reviews UI code against current web interface quality standards and emits terse, actionable `file:line` findings. Fetches the canonical guidelines for each review when accessible; records the source date and any unavailable checks. The resident checklist remains the offline floor.

## When to Use

- "Review my UI" / "audit design" / "review UX."
- "Check accessibility" / responsive review.
- A pre-ship pass on any web component, page, or layout.

## How It Works

1. Fetch the latest guidelines (URL below) before each review.
2. Read the specified files and the existing design/reference contract. Infer the relevant UI surface from the active task before asking for a file list.
3. Apply every fetched rule plus the resident checklist.
4. Output findings as terse `file:line — issue → fix` lines, grouped by severity.

If no files are specified, trace the active UI task to its source and callers. Ask only when the intended surface remains unclear.

### Guidelines source (fetch fresh each review)

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

Use WebFetch (or the exa fetch tool) to retrieve the latest rules; the fetched content carries the full rule set and output format. Fetching a page does not prove its claims are current or applicable. Check its scope; when access fails, label that source check unavailable and continue the useful resident checks.

## Core DNA — Resident Review Checklist

### Responsive
- Match the layout to the product and supported host sizes. Test mobile layouts when supported and narrow desktop panes where relevant; avoid unintended page overflow while preserving intentional map/table scrolling.
- Use a readable, task-appropriate type scale with text-scaling checks. Dense desktop controls and long-form text may need different scales. Use container queries when a component responds to pane size rather than the whole viewport.
- Full-height sections use `min-h-[100dvh]`, never `h-screen` (mobile browser chrome jump).
- Images responsive with intrinsic `width`/`height` (or `aspect-ratio`) to prevent CLS; `loading="lazy"` below the fold.

### Accessibility (WCAG 2.2 baseline)
- Contrast 4.5:1 body / 3:1 large text and UI components.
- Keyboard reachable; `:focus-visible` indicator ≥ 2px and ≥ 3:1 contrast; never `outline: none` without a replacement.
- Pointer targets meet WCAG 2.2 AA 2.5.8: at least 24×24 CSS px or a documented qualifying exception; every drag has a single-pointer alternative (2.5.7); focused element never obscured by sticky chrome (2.4.11 — use `scroll-margin`).
- Auth allows paste, no cognitive-test (3.3.8); no redundant re-entry of earlier data (3.3.7).
- Semantic HTML (`nav`/`main`/`aside`/`section`); ARIA labels on icon-only buttons; `aria-live="polite"` for toasts/streaming; status conveyed by more than color; respect `prefers-reduced-motion`.
- Form fields have associated `<label>`s; errors announced and tied to the field via `aria-describedby`.

### Interaction & states
- Define applicable hover, active, focus and disabled states; limit hover-only effects to appropriate input devices. Frequent keyboard actions remain immediate.
- Choose loading feedback appropriate to the operation: skeleton, progress, short status or spinner. Empty states explain the next action; errors explain recovery near the cause. Do not require decorative motion for every operation.
- Use restrained feedback when it helps; do not animate repeated keyboard actions or move dense controls merely to satisfy a checklist.
- Optimistic UI where safe; debounce/throttle expensive handlers.

### Performance
- Animate only `transform`/`opacity`; never `top`/`left`/`width`/`height`.
- `backdrop-blur` only on fixed/sticky layers, never scrolling containers.
- Avoid layout thrash; batch reads/writes. Defer non-critical JS; lazy-load heavy/below-fold components.
- Watch Core Web Vitals: LCP (prioritize hero image/font), CLS (reserve space), INP (keep handlers light).

### Forms & content
- Label above input, helper optional, error below; correct `type`/`inputmode`/`autocomplete`.
- One primary action per view; destructive actions confirmed.
- Real, specific copy — no placeholder slop (`Lorem ipsum`, `John Doe`, AI clichés).

## Render and interaction evidence

Check two independent results: visual fidelity against the approved reference contract, and interaction quality against the actual task. Inspect the rendered application rather than inferring appearance from CSS. For a picker/composer, verify visible keyboard highlight, true selected state, disabled options, search/no-results, clearing search, Escape/outside dismissal, focus return, menu anchoring, resize persistence and unsent drafts. For forms, verify validation and recovery with entered values preserved.

A build, unit suite or list of source findings cannot establish visual acceptance. Identify screenshots, viewports, exercised paths, real versus simulated integrations and unavailable checks. Keep the existing terse issue locations, with a `Before | After | Why` table when reviewing the visual/interaction changes alongside Emil design-engineering guidance.

## Output Format

```
src/components/Pricing.tsx:42 — icon button 18px with no qualifying size/spacing exception (WCAG 2.5.8) → enlarge the target or satisfy and document the applicable exception
src/app/page.tsx:8 — hero uses h-screen → min-h-[100dvh] (mobile chrome jump)
src/components/Slider.tsx:30 — drag-only reorder, no keyboard alt (WCAG 2.5.7) → add up/down buttons
```

Group by severity (blocking / should-fix / nit). Cite the rule. Always pair issue with fix.

## Anti-Patterns (what NOT to do with this skill)

- Don't use it for taste/aesthetic direction — that's `design-taste`.
- Don't use it to define tokens/theming — that's `design-tokens`.
- Don't use it for native mobile (HIG/Material) — that's the mobile/platform skills.
- Don't emit prose paragraphs; the contract is terse `file:line` findings.
- Attempt the source fetch; if unavailable, record the gap and apply the resident checks without claiming a current-source review.

## Quality Gates

- [ ] Guidelines source inspected and dated, or access failure explicitly recorded
- [ ] Findings are terse `file:line — issue → fix`, grouped by severity, each citing a rule
- [ ] Supported screen/pane sizes, text scaling and intentional versus unintended overflow checked
- [ ] WCAG 2.2 checked: contrast, focus-visible ≥2px/3:1, target size/qualifying exceptions, drag alt, focus-not-obscured, paste-auth, redundant-entry
- [ ] Interaction states (hover/active/focus/disabled/loading/empty/error) verified
- [ ] Performance (transform/opacity only, blur on fixed only, CWV) verified
- [ ] No scope creep into taste, tokens, or native-mobile review

- [ ] Visual fidelity and interaction quality have separate evidence and results; neither is inferred from a build pass.
