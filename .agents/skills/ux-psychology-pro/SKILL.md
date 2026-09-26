---
name: ux-psychology-pro
description: "65-principle behavioral design framework (Kahneman, Norman, Cialdini, NN/g) plus WCAG 2.2's 6 new A/AA criteria, surfaced per page type — landing, pricing, onboarding, dashboard, checkout, trust — with code-level examples. A weighted review layer, explicitly anti-dark-pattern. Use when reviewing or designing any conversion-relevant UI, or auditing accessibility against the 2026 EAA baseline. Triggers on 'ux psychology', 'conversion review', 'why don't users convert', 'pricing page psychology', 'onboarding flow', 'dark pattern check', 'wcag 2.2', 'accessibility audit'."
department: engineering
triggers:
  - ux-psychology
  - conversion-review
  - behavioral-design
  - pricing-psychology
  - onboarding-ux
  - dark-pattern-check
  - wcag-2.2
  - accessibility-audit
---

# UX Psychology Pro

Advisory review layer that surfaces the most relevant behavioral-psychology principles for the page or component being designed, plus the WCAG 2.2 accessibility floor. A **weighted input** — it informs decisions, it never overrides aesthetics, brand, or creative direction. Explicitly anti-dark-pattern.

## When to Use

Run after building or designing — build first, then apply the psychology + a11y lens to find what's missing:

- Landing, pricing, onboarding, checkout, trust pages.
- Subscription/conversion funnels.
- Dashboard layouts and data presentation.
- Navigation and information architecture.
- Any page where you want a specific user action.
- Accessibility audits against the 2026 EU Accessibility Act / EN 301 549 baseline (WCAG 2.2).

## Core DNA

### Decision process

1. Identify the page type (landing / pricing / onboarding / dashboard / checkout / trust).
2. Pull the 3–5 most relevant principles from the prescriptions below.
3. For each: state what it is → how to apply it to THIS page → what the anti-pattern looks like.
4. Weight against constraints (brand, a11y, technical always win).
5. Recommend specific, implementable changes — point to the markup/copy/layout line, not abstract advice.

### Weighting hierarchy (highest first)

1. Brand identity and creative vision.
2. Accessibility and usability (non-negotiable — WCAG 2.2, touch targets, contrast).
3. Technical quality (performance, SEO, responsive).
4. Psychology principles (subtle influence, never heavy-handed manipulation).

Never sacrifice aesthetics or trust for a psychology trick. If a principle conflicts with good design, good design wins.

### What this is NOT

Not a dark-patterns handbook (ethical application only) · not a complete design system (augments `design-taste`/`frontend-design`) · not a replacement for real user research · not a rigid checklist.

## Key Patterns — Page-Type Prescriptions

### Landing
- **First Impressions** — value clear in under 3s, formed in ~50ms, no second chance.
- **Anchoring** — lead with the strongest metric; the first number sets the reference.
- **Social Proof** — real numbers visible early; vague claims don't convert.
- **Information Scent** — navigation makes the next step obvious.
- **Aesthetic-Usability** — visual polish earns trust before content does.

### Pricing
- **Anchoring** — show/feature the premium tier first; everything else feels like a deal.
- **Loss Aversion** — frame what free users MISS, not just what paid users get (losing hurts ~2x).
- **Default Effect** — pre-select the recommended tier; most users never change defaults.
- **Commitment/Consistency** — users who already used free features are primed to upgrade.

### Onboarding
- **Progressive Commitment** — small free action first, account second, payment last.
- **Cognitive Load** — one question per screen beats a long form.
- **Zeigarnik Effect** — visible progress (step 2 of 4); incomplete tasks pull users back.
- **Reciprocity** — give value before asking for info.

### Dashboard
- **Chunking** — group by category/priority, not one giant list.
- **Spatial Memory** — consistent layout so returning users find things instantly; don't move things.
- **Satisficing** — highlight the single most important insight.
- **Recognition Over Recall** — show full context (labels, timestamps, icons).

### Checkout
- **Cognitive Load** — guest checkout, minimal fields, one decision at a time.
- **Transparency** — show ALL costs before the payment step (surprise fees = #1 abandonment).
- **Loss Aversion** — trust badges/guarantees NEXT TO the pay button, not the footer.
- **Default Effect** — pre-select standard shipping, pre-check "save info."

### Trust / About
- **Authority** — methodology, data sources, team expertise.
- **Hierarchy of Trust** — this page serves interest → confidence; don't ask for the sale here.
- **Transparency** — honest about limitations; vulnerability builds trust.

### Code-level examples

Anchoring (pricing) — mark one tier `featured` with a "Most Popular" badge so it becomes the anchor; Basic reads as a bargain, Enterprise makes Pro look reasonable.

Loss Aversion (CTA) — `Get Premium Access` → `Keep My Premium Access` with copy naming what they'd lose ("you'll lose daily insights, saved dashboards, priority support"). Framing as protecting something owned roughly doubles pull.

Zeigarnik (onboarding) — replace an 8-field single page with a 3-step progress bar (`Profile / Preferences / Review`) showing "Step 2 of 3" and 2–3 fields per step.

Cognitive Load (checkout) — replace forced account creation with guest checkout (`Email (for receipt)` + `Pay Now`) and defer "create an account" to after the sale.

### Principle categories (65 total)

Attention (4) · Gestalt (8) · Memory (10) · Sensemaking (3) · Decision Making (5) · Motor/Interaction (3) · Motivation (4) · Cognitive Biases (10) · Persuasion (9) · Emotion (6) · Ethics (3). Core insight per family: users see less than you think; visual grouping drives comprehension; recognition beats recall; defaults persist; trust before ask; beautiful feels easier; bright line between persuasion and manipulation.

## Key Patterns — WCAG 2.2 (the 2026 a11y floor)

WCAG 2.2 is the EU Accessibility Act / EN 301 549 baseline. Six new Success Criteria the older frameworks miss — encode all six:

| SC | Level | Requirement | Implementation |
|----|-------|-------------|----------------|
| **2.5.8 Target Size (Minimum)** | AA | Pointer targets at least 24×24 CSS px (or adequate spacing) | Size icon buttons/links ≥ 24px; add padding or spacing between dense tap targets. (Note: `design-taste`/mobile push 44px for touch — 24px is the hard a11y floor.) |
| **2.5.7 Dragging Movements** | AA | Any drag operation has a single-pointer alternative | Pair every drag (sliders, reorder, kanban, drag-to-upload) with click/tap or buttons — no drag-only actions. |
| **2.4.11 Focus Not Obscured (Minimum)** | AA | The focused element is not entirely hidden by sticky headers/footers/overlays | Add `scroll-margin` for sticky chrome; ensure focused items scroll into a visible region. |
| **2.4.13 Focus Appearance** | AAA→treat as floor | Focus indicator ≥ 2px thick and ≥ 3:1 contrast against adjacent colors | Use `:focus-visible` rings ≥ 2px with a 3:1 contrast ring color; never `outline: none` without a replacement. |
| **3.3.8 Accessible Authentication (Minimum)** | AA | No cognitive-function test (no memorized password puzzle, no transcription) for any auth step; allow paste | Support password managers and paste into all auth fields; offer email-link/passkey/copy-paste OTP — no "retype the code from memory," no character-by-character entry. |
| **3.3.7 Redundant Entry** | A | Don't make users re-enter info already given in the same process | Auto-fill / carry forward earlier-entered data (shipping → billing "same as") or let users select it; don't re-ask. |

Plus the standing floor: text contrast 4.5:1 (3:1 large), keyboard reachable, `:focus-visible` not `:focus`, focus-trapped modals with ESC, ARIA labels on icon-only buttons, `aria-live="polite"` for toasts/streaming/announcements, semantic HTML, status conveyed by more than color.

## Anti-Patterns

- **Fake scarcity counters** — if it's not real, don't show it.
- **Confirmshaming** — "No, I don't want to save money."
- **Hidden costs at checkout** — #1 abandonment cause.
- **Forced continuity / roach-motel** — easy in, impossible out.
- **Misdirection** — visual tricks to force wrong clicks.
- **Fake social proof** — fabricated testimonials, inflated numbers.
- **Dark defaults** — pre-checking opt-ins the user didn't ask for.
- A11y: `outline: none` without a replacement; drag-only interactions; cognitive-test auth or paste-blocked fields; tap targets below 24px; focus hidden behind sticky chrome.

## Quality Gates

- [ ] Page type identified; 3–5 relevant principles pulled, each with apply + anti-pattern
- [ ] Recommendations are specific (point to markup/copy/layout), not abstract
- [ ] No dark patterns introduced; every persuasion lever is real and reversible
- [ ] WCAG 2.2: target size ≥ 24px, every drag has a single-pointer alt, focus never obscured, focus ring ≥ 2px / 3:1
- [ ] Auth allows paste + no cognitive test (3.3.8); no redundant re-entry (3.3.7)
- [ ] Standing a11y floor met: 4.5:1 contrast, keyboard reachable, `:focus-visible`, ARIA on icon buttons, status not color-only
- [ ] Weighting respected — brand/a11y/technical took priority over any psychology lever

## Sources

NN/g Psychology for UX (112 resources, 11 categories); Kahneman (Prospect Theory), Norman (Emotional Design), Cialdini (Influence), Hick, Fitts, Miller, Zeigarnik. WCAG 2.2: w3.org/WAI/standards-guidelines/wcag/new-in-22 + w3.org/TR/WCAG22 (EAA / EN 301 549 baseline).
