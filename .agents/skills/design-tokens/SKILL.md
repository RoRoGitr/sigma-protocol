---
name: design-tokens
description: "Design-token architecture for the modern web — W3C DTCG (2025.10 stable) token files, Tailwind v4 CSS-first @theme, shadcn registries + tweakcn theming, the three-tier primitive/semantic/component hierarchy, OKLCH, light-dark() dark mode, and Style Dictionary / Terrazzo transformers. Use when building a design system, defining tokens, wiring theming/dark-mode, naming color/space/type scales, or making a token set portable across tools. Triggers on 'design tokens', 'design system tokens', 'theming', 'dark mode tokens', 'tailwind v4 theme', 'DTCG', 'shadcn registry', 'tweakcn', 'token architecture', 'OKLCH'."
department: engineering
triggers:
  - design-tokens
  - design-system
  - theming
  - dark-mode
  - tailwind-v4
  - dtcg
  - shadcn-registry
  - tweakcn
  - token-architecture
  - oklch
---

# Design Tokens

The token contract for AI-built design systems: portable W3C DTCG token files, Tailwind v4 CSS-first `@theme`, shadcn registries with tweakcn theming, and the transformer pipeline that turns one source of truth into utilities, CSS vars, and platform outputs. This is the layer `design-taste` and `frontend-design` consume but neither defines.

## When to Use

- Standing up a new design system or refactoring hardcoded hex/px into tokens.
- Wiring theming: light/dark, multi-brand, accessibility (high-contrast) modes.
- Naming and structuring color, spacing, type, radius, shadow, and motion scales.
- Making a token set portable between Figma, code, and other agents/tools.
- Installing or authoring shadcn registry components/themes.

## Core DNA

### W3C DTCG — the portable token contract (2025.10 stable)

The Design Tokens Format Module reached its first stable version on 2025-10-28 (W3C Community Group). It is a Community Group report, not a W3C Recommendation. Verify target-tool support. [Format specification](https://www.designtokens.org/tr/2025.10/format/).

- Tokens require `$value` and a declared or inherited `$type`; optional metadata includes `$description` and `$deprecated`.
- Aliases reference other tokens with `{group.token}` curly-brace syntax — this is what makes the three-tier hierarchy work.
- Composite `$type`s: `typography`, `shadow`, `gradient`, `transition`, `border`, `strokeStyle` — a single token holds multiple sub-values.
- Color values are structured objects, including `colorSpace` and `components`; CSS strings are export formats. [Color specification](https://www.designtokens.org/tr/2025.10/color/).
- The companion **Resolver Module** defines how modes (light/dark/brand/a11y) resolve from one token set.

```json
{
  "color": {
    "$type": "color",
    "blue": { "500": { "$value": { "colorSpace": "oklch", "components": [0.62, 0.19, 256] } } },
    "primary": { "$value": "{color.blue.500}", "$description": "Brand accent" }
  },
  "shadow": {
    "card": {
      "$type": "shadow",
      "$value": { "color": { "colorSpace": "srgb", "components": [0, 0, 0], "alpha": 0.2 }, "offsetX": { "value": 0, "unit": "px" }, "offsetY": { "value": 1, "unit": "px" }, "blur": { "value": 3, "unit": "px" }, "spread": { "value": 0, "unit": "px" } }
    }
  }
}
```

### Three-tier hierarchy (the consensus architecture)

Never let a component reference a raw primitive. Three tiers, each referencing the one above via `{alias}`:

1. **Primitive / global** — raw scale values, no meaning. `color.blue.500`, `space.4`, `font.size.lg`. Never used directly in components.
2. **Semantic / alias** — purpose-named, reference primitives. `color.background.default`, `color.text.primary`, `color.border.subtle`, `color.action.primary`. This is the layer that flips for dark mode.
3. **Component** — scoped to a component, reference semantics. `button.background.primary`, `card.border`, `input.ring.focus`.

Renaming a brand color touches one primitive; the semantic and component tiers follow automatically. Dark mode swaps only the semantic tier's resolution — primitives and component tokens are untouched.

### Naming

- Pattern: `category.concept.property.variant.state` (e.g. `color.action.primary.hover`).
- Semantic over literal: `color.text.danger`, never `color.text.red`. The whole point is decoupling intent from value.
- Consistent casing and ordering across the set — token names are an API.

## Key Patterns

### Tailwind v4 — CSS-first `@theme`

Tailwind v4 dropped `tailwind.config.js`. Tokens live in CSS as the source of theme. They become CSS custom properties AND generate utilities. AI tools read CSS reliably and mis-parse JS config — CSS-first is the agent-friendly default. OKLCH is v4's default color space.

```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.62 0.19 256);
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.15 0 0);
  --spacing-gutter: 1.5rem;
  --radius-card: 0.75rem;
  --font-display: "Geist", sans-serif;
}
```

This generates `bg-primary`, `text-foreground`, `rounded-card`, `font-display`, etc., and exposes every token as `var(--color-primary)`.

**The `@theme inline` theming gotcha (load-bearing):** a plain `@theme` token compiles to a value that always resolves to its `:root` definition — so swapping a CSS var under `[data-theme]` or `.dark` does nothing (the `--color-primary` always-resolves-to-root bug, tailwindlabs discussion #15600). To make tokens theme-switchable, declare them with `@theme inline` and point them at a separate `:root` var layer:

```css
@theme inline {
  --color-primary: var(--primary);   /* utility references the indirection var */
}
:root        { --primary: oklch(0.62 0.19 256); }
.dark        { --primary: oklch(0.72 0.15 256); }
[data-brand="alt"] { --primary: oklch(0.55 0.22 30); }
```

### Dark mode and modes

- Prefer the semantic-tier swap (above): one indirection var layer per mode under `:root`, `.dark`, `[data-theme]`, `[data-brand]`.
- `light-dark()` CSS function handles two-mode color in a single declaration when you don't need data-attribute brands: `color: light-dark(oklch(0.15 0 0), oklch(0.95 0 0));` with `color-scheme: light dark` on `:root`.
- `@property` registers animatable custom properties (`syntax`, `inherits`, `initial-value`) so theme transitions can interpolate instead of snapping.
- Multi-brand: scope brand overrides to a `data-brand` attribute on a wrapper, not the root, so multiple brands can coexist on one page.

### shadcn registries (an ecosystem, not a library)

shadcn is now a registry protocol. As of the 2026-06 changelog, **any public repo with a `registry.json` is an installable source** for components, tokens, AND agent instructions.

- Official registry + **tweakcn** (visual theme editor, Tailwind v4, generates the `:root`/`.dark` OKLCH var blocks — the fastest way to author a shadcn theme).
- Motion/animated registries: **Aceternity**, **Magic UI**. Primitive blocks: Origin UI. Block marketplaces: shadcn.io, Shadcnblocks.
- Wire the `shadcn` MCP (already configured in this stack) for live component lookup — `mcp__shadcn__search_items_in_registries`, `view_items_in_registries`, `get_add_command_for_items` — instead of fetching docs by URL.
- shadcn's `components.json` `cssVariables: true` is the bridge: its variables are the semantic tier, so a tweakcn-generated theme drops straight into the `@theme inline` + `:root` pattern above.

### Transformers (DTCG source → outputs)

- **Style Dictionary v4** — ESM, transitive transforms, set `outputReferences: true` to preserve `var()` aliasing in CSS output (keeps the three-tier links instead of flattening to literals).
- **Terrazzo** (formerly Cobalt) — DTCG-native with built-in lint.
- **Open Props** — ready-made primitive defaults to start from.

Pipeline: author DTCG JSON → transform with Style Dictionary/Terrazzo → emit Tailwind v4 `@theme` CSS (+ optional iOS/Android/Figma). One source, many targets.

## Anti-Patterns

- Components referencing primitives directly (`bg-blue-500` in a button) — always go through the semantic tier.
- Literal color names in the semantic tier (`color.red`) instead of intent (`color.danger`).
- Plain `@theme` (not `@theme inline`) for any token that must change per theme — it silently locks to `:root`.
- Inverting colors for dark mode instead of resolving a distinct semantic mapping.
- Maintaining tokens in `tailwind.config.js` on v4, or hand-editing generated CSS instead of the DTCG source.
- Hardcoded hex/px anywhere a token exists; fabricating a parallel token system next to shadcn's `cssVariables`.

## Quality Gates

- [ ] Tokens authored as DTCG (`$value`/`$type`/`{alias}`) or a clearly-tiered CSS var set — not scattered literals
- [ ] Three tiers present and respected: primitives → semantic → component, components never touch primitives
- [ ] Tailwind v4 uses `@theme` (CSS-first), no `tailwind.config.js` theme block
- [ ] Theme-switchable tokens use `@theme inline` + a `:root`/`.dark`/`[data-*]` indirection layer (no always-resolves-to-root bug)
- [ ] Color in OKLCH (or Display-P3) for new scales; dark mode is a semantic-tier resolution, not an inversion
- [ ] shadcn theming routed through `components.json` cssVariables (tweakcn-compatible); registry installs via the `shadcn` MCP
- [ ] Transformer pipeline preserves references (`outputReferences: true`) if DTCG → CSS is generated

## Sources

- W3C DTCG stable 2025.10: w3.org/community/design-tokens/2025/10/28 + CG-FINAL-format-20251028 + CG-FINAL-resolver-20251028
- Tailwind v4 `@theme`: tailwindcss.com/docs/theme; `@theme inline` gotcha: tailwindlabs/tailwindcss discussion #15600
- Three-tier + OKLCH + Style Dictionary v4 / Terrazzo: maviklabs design-tokens-tailwind-v4-2026, matchkit.io, sujeet.pro design-tokens-and-theming
- shadcn GitHub registries: ui.shadcn.com/docs/changelog/2026-06-github-registries; tweakcn: github.com/jnsahaj/tweakcn
