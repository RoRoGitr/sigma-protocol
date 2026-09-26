#### Catalog-driven repo template selection (required when "Repo template" is in play)

Do **not** ask the user to pick from memory. Read the machine catalog and rank options:

1. **Read** `templates/landing-page-templates/catalog.json` (7 templates; schema at `schemas/landing-page-template-catalog.schema.json` if present).
2. **Map** the locked page type from Phase A Decision 1 → catalog `target_page_type` filter:

| Phase A page type | Prefer `target_page_type` (in order) |
|-------------------|--------------------------------------|
| Product marketing page (SaaS/app) | `saas-product`, `ai-product`, `developer-tool` |
| Waitlist / coming soon | `saas-product`, `changelog` |
| Demo / signup / free trial | `saas-product`, `developer-tool`, `ai-product` |
| Course / coaching sales page | `content-marketing`, `saas-product` |
| Portfolio / services page | `portfolio` |
| Other | show full catalog |

Also filter by orientation when relevant: if `docs/stack-profile.json` → `platform` is mobile-native, prefer `mobile-app`.

3. **Present** the top 3 catalog matches (name, `target_page_type`, `strengths`) via AskUserQuestion — not a generic "Repo template" label.
4. **Record** the chosen entry in `docs/landing-page/TEMPLATE-MAPPING.md`: template name, catalog `target_page_type`, path `templates/landing-page-templates/<name>/`, and why it beat the alternatives.

#### Boilerplate marketing shell detection (required before offering that option)

Before listing "Boilerplate marketing shell" as an option:

1. Read `.sigma/boilerplate.json` if present.
2. Detect a marketing/landing shell using **any** of:
   - `.sigma/modules.manifest.json` → `modules.marketing.enabled === true` (list `modules.marketing.files`)
   - `boilerplate.json` → `stack.landing` block (e.g. fintech monorepos)
   - `boilerplate.json` → `configFiles` containing a `landing/` path
   - Known paths on disk: `landing/`, `src/app/(marketing)/`, `src/routes/(marketing)/`
3. If **none** detected → omit "Boilerplate marketing shell" from the AskUserQuestion options (do not offer a dead option).
4. If detected → include the concrete path(s) in the option label, e.g. `Boilerplate marketing shell — landing/ (from fintech boilerplate)`.

#### shadcn blocks gate (required before offering shadcn option)

Only offer "shadcn blocks + customize" when **both** are true:
- `docs/stack-profile.json` → `"componentLibrary": "shadcn/ui"` (or Step 2 recorded shadcn)
- `.sigma/runtime-baseline.json` → `design_tools.shadcn_mcp === true` **OR** shadcn CLI is available

If shadcn is in stack but MCP/CLI unavailable → offer "shadcn blocks (install CLI first)" as a blocked option with the Step 0 install path, or fall through to repo template / direct HTML.
