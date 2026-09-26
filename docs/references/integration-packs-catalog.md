# Integration Packs Catalog

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Source of truth for module IDs:** `templates/boilerplates/_shared/module-catalog.json`

Sigma boilerplates compose **integration packs** (auth, billing, marketing, etc.) from the shared module catalog. Step 0 reads this when validating stack integrations for `boilerplate-project` mode. Step 2 and `@new-project` use module IDs for `--modules=` and flow-tree driven selection.

---

## Module catalog (canonical IDs)

| Module ID | Name | Platform | Default | Key integrations / env |
|-----------|------|----------|---------|------------------------|
| `marketing` | Marketing pages | web | yes | Landing, pricing, blog, legal |
| `auth` | Authentication | both | yes | Supabase / Better Auth — `NEXT_PUBLIC_SUPABASE_*` or mobile `EXPO_PUBLIC_*` |
| `dashboard` | Dashboard shell | both | yes | App layout, sidebar, nav |
| `settings` | Settings | both | yes | Profile, account, notifications |
| `billing` | Billing & subscriptions | web | yes | Stripe — `STRIPE_SECRET_KEY`, webhook secret |
| `admin` | Admin panel | web | yes | Role-gated admin routes |
| `aiChat` | AI chat | both | no | OpenAI / AI SDK — `OPENAI_API_KEY` |
| `crudExample` | CRUD example | both | no | Demo data patterns |
| `onboarding` | Onboarding | both | yes | Welcome, setup wizard |
| `notifications` | In-app notifications | both | no | Notification center |
| `errorStates` | Error / empty states | both | yes | 404, 500, maintenance |
| `mobileOnboarding` | Mobile onboarding | mobile | yes | Permissions, push opt-in |
| `purchases` | In-app purchases | mobile | yes | RevenueCat — `REVENUECAT_API_KEY` |

Full route lists and dependencies: **`templates/boilerplates/_shared/module-catalog.json`**.

---

## Framework template → default integrations

Derived from `templates/boilerplates/catalog.json`. Step 0 Phase C uses these when `.sigma/boilerplate.json` is present.

| Template | Auth | Database / backend | Payments | Analytics | AI |
|----------|------|-------------------|----------|-----------|-----|
| `nextjs-saas` | Supabase Auth | Supabase Postgres | Stripe | PostHog | Vercel AI SDK |
| `expo-mobile` | Supabase Auth | Supabase | RevenueCat | PostHog RN | — |
| `nextjs-ai` | Convex Auth | Convex | — | — | Vercel AI SDK |
| `nextjs-portable` | Better Auth | Drizzle + Postgres | Stripe | — | optional |
| `tanstack-saas` | Supabase Auth | Supabase | Stripe | — | — |

---

## Product template extensions

| Product | Extends | Extra integration packs |
|---------|---------|-------------------------|
| `products/mobile/fintech` | expo-mobile | Broker OAuth, landing Next.js shell, waitlist |
| `products/mobile/learning-platform` | expo-mobile | Gamification (XP/streaks/achievements), course progress |
| `products/courses-lms` | nextjs-saas | Video hosting, certificates (stub) |
| `products/ai-tools` | nextjs-ai | Credits, multi-tool routing (stub) |

---

## Step wiring

1. **Step 0 Phase C** — If `boilerplate-project`, read `.sigma/boilerplate.json` + this file; skip redundant integration questions.
2. **Step 2 Phase A** — If no boilerplate yet, read `templates/boilerplates/catalog.json` and recommend template + modules.
3. **`@new-project`** — Resolves modules from `--modules`, `--flow-tree`, or template defaults (see `.agents/skills/new-project/SKILL.md`).

---

## UI / component libraries (cross-reference)

Component and chart libraries are **not** integration packs — see **`docs/references/CURATED-COMPONENT-LIBRARIES.md`**.
