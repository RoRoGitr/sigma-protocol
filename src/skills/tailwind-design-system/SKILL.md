---
name: tailwind-design-system
description: "The Tailwind v4 + shadcn/ui v4 implementation skill — CSS-first @theme config, @utility/@source/@reference directives, the @theme vs @theme inline cascade gotcha, OKLCH tokens, and the full shadcn CLI 4.10 / registry / preset / data-slot toolchain. Use when configuring Tailwind v4, wiring shadcn, or implementing a design system in Tailwind. Triggers on 'tailwind', 'tailwind v4', 'design system', 'shadcn', '@theme', 'design tokens in tailwind', 'shadcn registry', 'shadcn preset'."
department: engineering
triggers:
  - tailwind
  - tailwind v4
  - design system
  - shadcn
  - "@theme"
  - shadcn registry
  - shadcn preset
  - tailwind config
  - shadcn init
---

# Tailwind Design System (Tailwind v4 + shadcn/ui v4)

The implementation authority for the Tailwind v4 utility/token API and the shadcn/ui v4 component toolchain. This skill owns the `@theme` cascade rules, the v4 directive surface, and the shadcn CLI/registry/preset mechanics.

This skill does NOT own the abstract token *taxonomy*. The DTCG (W3C Design Tokens) primitive→semantic→component model and the Style Dictionary pipeline live in `design-tokens` — this skill is how those tokens land as Tailwind `@theme` variables and shadcn CSS scaffolds. Reference `design-tokens` for the spec; implement it here.

> Reference snapshot, 2026-06: Tailwind CSS v4.3 and shadcn CLI 4.10.0. v4 is the preprocessor — it does NOT compose with Sass/Less/Stylus. Detect the project's Tailwind and shadcn versions before applying v4-only directives; this snapshot is not an upgrade instruction.

## When to Use

- Setting up or migrating a Tailwind v4 project (CSS-first config)
- Implementing design tokens as `@theme` variables; wiring dark mode
- Initializing, theming, or extending shadcn/ui v4
- Authoring or consuming a shadcn registry / preset

Skip for: non-Tailwind CSS frameworks, the abstract token taxonomy (use `design-tokens`), aesthetic direction (use `design-taste`), component composition intent (use `frontend-design`).

## Core DNA

1. **The CSS is the config.** v4 has no `tailwind.config.js` for new work. `@import "tailwindcss"` + `@theme` is the surface. `@config` is a legacy escape hatch only.
2. **`@theme` for cascade tokens, `@theme inline` for already-var tokens.** This distinction is the single most common v4 contrast bug — get it right.
3. **Keep `@theme` lean.** 3-5 color steps per hue, 3 radius values, 1-2 fonts. 50 color tokens = 250+ generated classes. Token taxonomy belongs in `design-tokens`; `@theme` is the emit layer.
4. **shadcn via CLI, never hand-copied.** Use the package runner; merge with `--dry-run`/`--diff`; validate registries before installing.
5. **Semantic tokens, not raw colors.** `bg-background`, `text-muted-foreground` — never `bg-blue-500`, never arbitrary values.

## Key Patterns

### Tooling setup (pick one bundler path)

```css
/* app.css */
@import "tailwindcss";
```

- Vite → `@tailwindcss/vite` (NOT PostCSS). Remove `autoprefixer` and `postcss-import` — v4 handles both.
- PostCSS-based stacks → `@tailwindcss/postcss`. CLI-only → `@tailwindcss/cli`.
- Migrating from v3 → `npx @tailwindcss/upgrade`.

### `@theme` vs `@theme inline` (the cascade gotcha)

```css
/* Plain @theme emits var(--...) into the utility — cascade-OVERRIDABLE.
   Use for any token that changes by context (dark mode, surface contexts). */
@theme {
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.15 0.02 286);
}

/* @theme inline bakes the LITERAL value into the utility — NOT overridable
   by a wrapper/cascade class. Use ONLY for tokens already pointing at a CSS var. */
@theme inline {
  --color-card: var(--background);  /* shadcn scaffold pattern */
}
```

Rule: dark-mode / context tokens → plain `@theme`. Tokens that just alias an existing CSS var → `@theme inline`. Mixing these up silently breaks dark-mode contrast.

### Dark mode via `@custom-variant`

```css
@custom-variant dark (&:where(.dark, .dark *));

:root { --color-background: oklch(1 0 0); --color-foreground: oklch(0.15 0.02 286); }
.dark { --color-background: oklch(0.15 0.02 286); --color-foreground: oklch(0.98 0 0); }
```

Cascade order: `@theme` defaults → `:root` → `.dark` → surface-context wrappers.

### `@utility`, `@source`, `@reference`, `@plugin`

```css
/* v4 replaces @layer utilities {} */
@utility tab-4 { tab-size: 4; }
@utility tab-* { tab-size: --value(integer); }   /* functional value */

/* Content auto-detected — no `content` array. Tune with @source: */
@source inline("bg-brand-{50,100,500,600,700}");  /* v4 safelist replacement */
@source not "./src/legacy";

/* Scoped styles (CSS Modules, Vue/Svelte <style>) can't see @theme/@utility without: */
@reference "../../app.css";

/* Plugins load in CSS, not require() */
@plugin "@tailwindcss/typography";
```

### Renamed / changed utilities (v3 → v4)

| v3 | v4 | Note |
|----|----|------|
| `shadow-sm` / `shadow` | `shadow-xs` / `shadow-sm` | scale shifted |
| `rounded-sm` / `rounded` | `rounded-xs` / `rounded-sm` | scale shifted |
| `blur-sm` / `blur` | `blur-xs` / `blur-sm` | scale shifted |
| `outline-none` | `outline-hidden` | v4 `outline-none` now sets `outline-style:none` — forced-colors a11y regression |
| `ring` (3px blue) | `ring-3` | v4 `ring` = 1px currentColor |
| `bg-opacity-50` | `bg-black/50` | color modifiers |
| `flex-shrink-0` | `shrink-0` | simplified |

Also: default border color is now `currentColor` (was gray-200); `space-y-4` selector changed to `:not(:last-child)` — prefer `gap` on flex/grid parents.

### v4.1+ / v4.3 utilities

`text-shadow-*`, `mask-*`, colored `drop-shadow`, `pointer-fine`/`pointer-coarse`, `user-valid`/`user-invalid`, safe alignment, `overflow-wrap`, `@source inline`; v4.3 adds `scrollbar-*`, `zoom-*`, `tab-*`, `@container-size`. `--spacing(N)` shorthand replaces `calc(var(--spacing) * N)`.

### Tokens file pattern

```css
/* Generated tokens (committed) imported into the theme layer */
@import "./tokens.css" layer(theme);
```

Keep the DTCG-generated `tokens.css` separate and committed; run a quarterly drift audit. `@theme static` forces all variables into output (use when JS reads tokens at runtime).

### shadcn/ui v4 — canonical CSS scaffold

```css
@import "tailwindcss";
@import "shadcn/tailwind.css";
@custom-variant dark (&:is(.dark *));

:root { --background: oklch(1 0 0); --foreground: oklch(0.15 0.02 286); --radius: 0.625rem; /* ...OKLCH tokens */ }
.dark { --background: oklch(0.15 0.02 286); --foreground: oklch(0.98 0 0); /* ... */ }

@theme inline {                         /* inline — plain @theme breaks dark mode here */
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --radius-sm: calc(var(--radius) * 0.6);   /* 7-level scale: sm/md/lg/xl/2xl/3xl/4xl */
  --radius-md: calc(var(--radius) * 0.8);
  --radius-lg: var(--radius);
}
```

Don't mix HSL leftovers with OKLCH defaults — different interpolation produces hover artifacts. Style internals via the `data-slot` attribute every primitive emits (`[data-slot="card-content"]`), not wrapper divs. Base colors: neutral/stone/zinc plus mauve/olive/mist/taupe.

### shadcn CLI 4.10 — commands

```bash
# Init / create
npx shadcn@<project-approved-version> init --preset base-nova
npx shadcn@<project-approved-version> init --preset <code> --pointer        # --pointer flag (v4.5)

# Add (incl. GitHub registries — v4.10: any public repo with registry.json)
npx shadcn@<project-approved-version> add button card dialog
npx shadcn@<project-approved-version> add owner/repo/component-name          # owner/repo/item, no build step
npx shadcn@<project-approved-version> add @magicui/shimmer-button --dry-run --diff

# Apply a preset to an EXISTING project (v4.4 — replaces init --preset --force)
npx shadcn@<project-approved-version> apply --preset <code>
npx shadcn@<project-approved-version> apply --preset <code> --only theme     # or --only font (partial adoption)

# Preset inspection (v4.4)
npx shadcn@<project-approved-version> preset resolve | url <code> | open <code>

# Registry authoring/validation (v4.8)
npx shadcn@<project-approved-version> registry validate owner/repo[#ref]      # validate before install

# Eject (v4.9) — detach from CLI management
npx shadcn@<project-approved-version> eject
```

Registry: `registry.json` at repo root; `include` field composes a large registry across files; `target` supports alias placeholders (`~/`); items can declare package imports. Security: `view`/`validate` before installing third-party items; pin commit SHA refs. (`registry:build`/`registry:mcp` are deprecated → `build`.)

Style catalog: `nova`/`vega` (originals), `luma` (rounded/soft/macOS), `sera` (editorial/serif), `rhea` (compact Luma for dense UIs). Pick: dashboard/product → rhea; consumer/marketing → luma; editorial → sera.

### Switching presets in an existing project

Use `apply --preset <code>` (not `init --preset --force`). For partial adoption: `apply --only theme` / `--only font`. Reinstall-all only with explicit user approval.

## Anti-Patterns

- `tailwind.config.js` for new v4 work; leaving `autoprefixer`/`postcss-import` installed.
- Plain `@theme` for tokens that need cascade overrides (breaks dark mode) — or `@theme inline` for context tokens.
- `.dark {}` overrides with no `@custom-variant dark` declared.
- `@layer utilities {}` instead of `@utility`; a `content` array instead of `@source`; `require()` plugins instead of `@plugin`.
- v3 utility names (`shadow-sm` meaning the old shadow, `ring` for 3px, `outline-none` for hidden outline).
- Arbitrary values (`w-[347px]`), inline styles for spacing/color, raw colors (`bg-blue-500`) instead of semantic tokens.
- `init --preset --force` to switch presets in an existing project — use `apply`.
- Hand-fetching shadcn files from GitHub instead of the CLI; installing a third-party registry item without `validate`/`view`.
- Mixing HSL and OKLCH token values; styling shadcn internals via wrapper divs instead of `data-slot`.

## Quality Gates

- [ ] CSS-first config (`@import "tailwindcss"` + `@theme`); no `tailwind.config.js` for new work
- [ ] `@theme` (plain) for cascade/dark-mode tokens; `@theme inline` only for var-alias tokens
- [ ] `@custom-variant dark` declared; OKLCH tokens consistent (no HSL leftovers)
- [ ] `@utility` / `@source` / `@reference` / `@plugin` used per v4 (no v3 `@layer utilities`, no `content` array, no `require()`)
- [ ] v4 utility names (`shadow-xs`, `ring-3`, `outline-hidden`); no v3 names
- [ ] Semantic tokens only — no arbitrary values, no raw colors, no inline styles for spacing/color
- [ ] shadcn installed/updated via CLI with `--dry-run`/`--diff`; third-party registries `validate`d first
- [ ] `apply --preset` used for existing-project preset changes (not `init --force`); shadcn internals styled via `data-slot`
- [ ] `@theme` kept lean; DTCG token taxonomy deferred to `design-tokens`
