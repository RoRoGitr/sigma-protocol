#### Boilerplate catalog (required when no `.sigma/boilerplate.json`)

Do **not** guess template names. Read the machine catalog and rank options:

1. **Read** `templates/boilerplates/catalog.json` (framework + product templates).
2. **Read** `templates/boilerplates/_shared/module-catalog.json` for module IDs when discussing features.
3. **Read** `docs/references/integration-packs-catalog.md` for integration pack summaries.
4. **Map** platform + product type from `docs/stack-profile.json`, `MASTER_PRD.md`, or Phase A/C decisions:

| Signal | Prefer catalog entries |
|--------|------------------------|
| Mobile app, IAP | `expo-mobile`, `products/mobile/*` |
| Full SaaS web | `nextjs-saas`, `tanstack-saas` |
| AI-first / real-time | `nextjs-ai`, `products/ai-tools` |
| Self-host / portable | `nextjs-portable` |
| Courses / gamification | `products/mobile/learning-platform` |
| Trading / fintech | `products/mobile/fintech` |

5. **If** `.sigma/boilerplate.json` already exists → document inherited template in the environment/architecture report; **skip** AskUserQuestion picker.
6. **If** greenfield (no boilerplate, no root `package.json`) → present top 3 catalog matches via AskUserQuestion with `id`, `stack`, and `use_when`.
7. **On selection** → record `boilerplateCandidate` in `docs/stack-profile.json` and instruct user to run `@new-project --template=<id>` (or clone product path from catalog `path` field) before Step 2 locks architecture.
8. **Status gate** — omit catalog entries with `"status": "stub"` unless user explicitly wants a stub shell; prefer `"status": "ready"` or `"status": "built"`.
