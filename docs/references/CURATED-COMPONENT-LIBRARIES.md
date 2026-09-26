# Curated Component & UI Libraries

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Purpose:** Single reference for Steps 0–2 (stack/boilerplate), 5–6 (wireframes/design system), 8–11 (implementation). Agents **read this file** before offering component-library options or chart/gamification patterns — do not invent libraries not listed here.

---

## How steps consume this doc

| Step | When to read | What to record |
|------|--------------|----------------|
| **0** | Phase C / C.1 greenfield scaffold | Seed `docs/stack-profile.json` hints; run `@new-project` against `templates/boilerplates/catalog.json` |
| **1** | Phase C feasibility | Note `boilerplateCandidate`, platform, domain needs (charts, gamification) |
| **2** | Phase A stack + component decisions | Lock `componentLibrary`, `chartsLibrary`, `styling` in `stack-profile.json` |
| **5–6** | Wireframe / token work | Match primitives to library column below |
| **8–11** | Technical spec + PRDs | Copy install commands from Step 8 manifest; invoke bound skills |

**Skills to invoke by platform:**

| Platform | Primary skills |
|----------|----------------|
| Web / Next.js / desktop (Tauri/Electron) | `shadcn`, `react`, `frontend-design`, `design-tokens` |
| Mobile (Expo / RN) | `rn-component-library`, `react-native-patterns`, `expo`, `mobile-app-security` |
| Apple native (SwiftUI) | `apple-native`, `apple-platform-design`, `testing-apple` |
| Charts (mobile) | `rn-component-library` (Bklit section) |
| Gamification / trophies | `companion-system` (gacha/cosmetics), learning-platform boilerplate |
| Apple native (SwiftUI) | `apple-native`, `apple-platform-design`, `testing-apple` — see `docs/swiftui/SWIFTUI-LIBRARIES.md` |
| macOS chrome (desktop web shell) | `macos-design`, `apple-platform-design` |

---

## Web & Next.js

| Library | Role | Install / docs | Sigma wiring |
|---------|------|----------------|--------------|
| **shadcn/ui** | Default web component system (copy-paste, Tailwind v4) | https://ui.shadcn.com — `npx shadcn@latest init` | Steps 0 `design_tools.shadcn_mcp`, 2 Decision 4, 5 blocks, 6 tokens, 8 web manifest |
| **Magic UI / motion primitives** | Marketing polish (border-beam, particles, shimmer) | https://magicui.design | Shipped in `nextjs-saas` under `src/components/ui/` — reference, do not duplicate blindly |
| **Tremor** | Dashboard charts (web) | https://tremor.so | Optional when Step 8 marks `chartsLibrary: tremor` |
| **Recharts** | General-purpose React charts | https://recharts.org | Fallback web charts; prefer Tremor for dashboard density |

**Boilerplate UI standard:** `templates/boilerplates/UI-STANDARD-HANDOFF.md` (semantic tokens, true-black dark mode, `content-container`).

**Landing marketing templates:** `templates/landing-page-templates/catalog.json` (Step 9).

---

## Mobile (Expo / React Native)

| Library | Role | Install / docs | Sigma wiring |
|---------|------|----------------|--------------|
| **React Native Reusables** | Default mobile component system (shadcn model for RN) | https://reactnativereusables.com — `npx @react-native-reusables/cli@latest init` | Step 0 C.1, 8 mobile manifest, skill `rn-component-library` |
| **NativeWind v4** | Tailwind-style styling for RN | https://www.nativewind.dev — `npx expo install nativewind tailwindcss` | Required with Reusables; **do not** pair with Tamagui on the same app |
| **@shopify/flash-list** | High-performance lists | `npx expo install @shopify/flash-list` | Step 8 manifest — never default to FlatList for production lists |
| **expo-image** | Cached images + blurhash | `npx expo install expo-image` | Step 8 manifest |
| **Tamagui** | Cross-platform UI kit | https://tamagui.dev | **Deprecated default** — conflicts with NativeWind + Reusables Expo stack; only if explicitly chosen in Step 2 with documented reason |

---

## Charts & data visualization

| Library | Platform | Install / docs | When to use |
|---------|----------|----------------|-------------|
| **@bklit/charts** | Mobile (Skia) | https://www.npmjs.com/package/@bklit/charts — `npm install @bklit/charts react-native-skia` | Trading, portfolio, analytics screens; invoke `rn-component-library` §3 |
| **Tremor** | Web dashboards | https://tremor.so | Admin, CRM, SaaS metrics |
| **Recharts** | Web general | https://recharts.org | Custom chart layouts when Tremor blocks do not fit |
| **Swift Charts** | iOS native | Apple HIG | SwiftUI product boilerplates only |

**In-repo reference implementations:**

- Fintech charts UX: `templates/boilerplates/products/mobile/fintech/` (portfolio, trading flows)
- Learning progress UI: `templates/boilerplates/products/mobile/learning-platform/`

---

## Gamification, trophies & achievements

| Resource | Type | Location | When to use |
|----------|------|----------|-------------|
| **Learning platform gamification module** | In-repo reference | `templates/boilerplates/products/mobile/learning-platform/src/lib/gamification/` | XP, streaks, achievements, leaderboard-ready patterns |
| **Achievement screens inventory** | Flow PRD reference | `templates/boilerplates/products/mobile/learning-platform/docs/flows/SCREEN-INVENTORY.md` | Trophy/achievement UI coverage |
| **companion-system skill** | Gacha / collectible DNA | `.claude/skills/companion-system/SKILL.md` | Pet/companion cosmetics, rarity, marketplace — not generic CRUD trophies |
| **Operator vault (optional, local SSD)** | Extended reference archive | See [Operator-local references](#operator-local-references-dallion-t7) | When mounted; never required for open-source consumers |

Record in `stack-profile.json` when applicable:

```json
{
  "gamification": {
    "pattern": "xp-streak-achievements",
    "reference": "templates/boilerplates/products/mobile/learning-platform/src/lib/gamification/"
  }
}
```

---

## Boilerplates ↔ libraries (quick map)

Read **`templates/boilerplates/catalog.json`** for the full list. Summary:

| Boilerplate | Platform | Default component library |
|-------------|----------|---------------------------|
| `nextjs-saas` | web | shadcn/ui |
| `expo-mobile` | mobile | react-native-reusables + NativeWind |
| `nextjs-ai` | web | shadcn/ui |
| `nextjs-portable` | web | shadcn/ui |
| `tanstack-saas` | web | shadcn/ui |
| `products/mobile/learning-platform` | mobile | Reusables + gamification refs |
| `products/mobile/fintech` | mobile + landing | Reusables + Bklit-style chart screens |

Scaffold: `@new-project --template=<id>` (see `.agents/skills/new-project/SKILL.md`).

Module IDs for feature toggles: `templates/boilerplates/_shared/module-catalog.json`  
Integration pack summary: `docs/references/integration-packs-catalog.md`

---

## Anti-patterns (do not offer without explicit Step 2 approval)

- Tamagui + NativeWind + Reusables on the same Expo app
- `react-native-chart-kit` (unmaintained — use `@bklit/charts`)
- FlatList for long production lists (use FlashList)
- Hardcoded hex colors when semantic tokens exist (see UI-STANDARD-HANDOFF)
- Inventing a component library not listed here without an ADR in Step 2

---

## Related docs

- `templates/boilerplates/README.md` — boilerplate overview
- `templates/boilerplates/catalog.json` — machine-readable boilerplate picker
- `docs/FILE-PATH-REFERENCE.md` — artifact paths across steps
- Skill: `rn-component-library` — Reusables + Bklit implementation patterns
- Skill: `shadcn` — registry, blocks, presets for web
- Skill: `agentic-ui` — agent surfaces, generative UI contract (Step 3+)
