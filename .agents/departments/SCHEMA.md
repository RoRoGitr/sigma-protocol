# Sigma Protocol Department Context — Canonical Schema

**Version:** 1.1.0
**Owner:** Sigma Protocol core
**Consumers:** `department-composer.sh` (runtime), `flush.py` (Layer 3 writer), backend-engineer (classifier), lead-architect (department expansion).

This document is the contract between the three layers of department context and every tool that reads or writes them. Changes to this file are breaking changes. Bump the version and update every consumer.

---

## 1. The 13 Canonical Departments

Exact identifiers for department heads. Alias slashes (`/ads`, `/growth`, `/support`, `/gtm`, `/go-to-market`) resolve per `config.department_aliases` in `agent-skill-registry.json`; an alias with its own canon directory (an **alias-canon**) composes that canon instead of its target's. Case-sensitive directory names: always lowercase.

| Slash | Role | Canon file |
|-------|------|-----------|
| `/engineering` | CTO | `.agents/departments/engineering/department.md` |
| `/security` | CISO | `.agents/departments/security/department.md` |
| `/legal` | General Counsel | `.agents/departments/legal/department.md` |
| `/marketing` | CMO | `.agents/departments/marketing/department.md` |
| `/content` | Chief Content Officer | `.agents/departments/content/department.md` |
| `/finance` | CFO | `.agents/departments/finance/department.md` |
| `/ops` | COO | `.agents/departments/ops/department.md` |
| `/sales` | CSO | `.agents/departments/sales/department.md` |
| `/product` | CPO | `.agents/departments/product/department.md` |
| `/community` | Community Lead | `.agents/departments/community/department.md` |
| `/trading` | Chief Trading Officer | `.agents/departments/trading/department.md` |
| `/design` | Design Director | `.agents/departments/design/department.md` |
| `/qa` | QA Engineer | `.agents/departments/qa/department.md` |

**Alias canons (not counted in 13):** `/ads` → `ads/` (routes to marketing), `/growth` → `growth/` (routes to marketing), `/support` → `support/` (routes to community), `/gtm` → `gtm/` (routes to marketing; the go-to-market conductor persona — see `gtm/department.md` §9). `/go-to-market` is a plain alias to marketing with no canon dir of its own; use `/gtm` for the GTM persona.

**Run Track exception:** Eight Run Track departments expose numbered workflow commands — `/run-marketing` through `/run-legal` plus per-step `/run-m-*`, `/run-s-*`, `/run-c-*`, `/run-g-*`, `/run-co-*`, `/run-o-*`, `/run-fn-*`, `/run-l-*` (64 steps total). See [`docs/run-track/README.md`](../../docs/run-track/README.md). Product, Design, and Engineering stay on Build Track (Steps 0–15); QA, Security, and Trading use gate-only slashes.

Any slash command matching a department or alias triggers the composer. Everything else passes through untouched.

---

## 2. Department Routing Table

The composer injects context. The slash command's own `.md` file (from repo `commands/` or the operator's local command import path) still runs — the composer wraps, it does not replace.

| Slash | Persona agent | Primary tools / MCPs |
|-------|---------------|----------------------|
| `/marketing` | `cmo` | exa, ref, greptile-free, claude_ai_Canva |
| `/ads` | `paid-media-director` | exa, ref, claude-in-chrome (ad managers) |
| `/content` | `content-director` | exa, youtube-transcription, notebooklm-workflow, media-generation |
| `/growth` | `growth-engineer` | exa, ref, analytics-MCPs (project-supplied) |
| `/engineering` | `lead-architect` | gitnexus, ref, exa |
| `/ops` | `ops-director` | ref, claude_ai_Gmail, claude_ai_Google_Calendar |
| `/finance` | `finance-director` | ref, exa (no write tools by default) |

Persona agents live at `.claude/agents/{agent-name}.md` in the project or user-global `~/.claude/agents/`. The composer does not spawn them — invoking the slash command does.

---

## 3. Layer Contracts

### Layer 1 — Department Canon (REQUIRED, STATIC)

**Path:** `.agents/departments/{dept}/department.md` inside the Sigma Protocol repo.

**Ownership:** Sigma Protocol maintainers. Students never edit Layer 1. Updates ship via reinstall (re-run `scripts/install-departments.sh`).

**Purpose:** canonical methodology, persona voice manifesto, stable skill inventory. This is the spine — what makes `/marketing` *be* a CMO regardless of which project invokes it.

**Frontmatter (STRICT — all fields required unless marked optional):**

```yaml
---
name: string              # Persona display name. Example: "CMO" or "Chief Marketing Officer"
description: string       # One line, <160 chars. Used by doc generators.
agent: string             # Persona agent identifier. Example: "cmo"
allowed-tools: string[]   # Whitelist of Claude tools. Example: ["Read", "Write", "Edit", "Bash", "mcp__exa__*"]
model: string             # Opus required for C-suite. Example: "claude-opus-4-7"
skills: string[]          # optional. Pre-linked skill slugs from `.agents/skills/`.
version: string           # Semver. Example: "1.0.0"
updated: string           # ISO 8601. Example: "2026-04-17"
---
```

**Body (STRICT SECTIONS — in this order):**

```markdown
# {Persona Name} — {Department} Canon

## Mission
One paragraph. What this executive is responsible for and the business outcomes they own.

## Voice Manifesto
Bulleted list. How this persona speaks. Rhetorical moves allowed, anti-patterns forbidden.

## Methodology
Numbered phases. The canonical workflow this persona follows from briefing to shipped artifact.

## Skill Arsenal
Markdown table. Skill slug → purpose → when to invoke. (Historically also titled "Skill Inventory" — "Skill Arsenal" is the canonical heading.)

## Decision Framework
How this persona chooses between options. Include weighting criteria and gate conditions.

## Escalation Rules
When this persona stops and hands off to a human (budget thresholds, legal review, etc.).

## Negative Boundaries
What this persona will NEVER do. Examples: "Never promise ROI numbers without A/B data."
```

**Size target:** 2000-4000 tokens. A canon over 5000 tokens means the department is too broad and should split.

**Example canon (`marketing/department.md`):**

```markdown
---
name: CMO
description: Chief Marketing Officer persona — brand, positioning, GTM, lifecycle
agent: cmo
allowed-tools: ["Read", "Write", "Edit", "Bash", "mcp__exa__*", "mcp__ref__*"]
model: opus
skills: ["01-market-research", "02-customer-avatar", "03-brand-voice", "07-landing-page-copy"]
version: 1.0.0
updated: 2026-04-17
---

# CMO — Marketing Canon

## Mission
Own brand perception, demand generation, and lifecycle economics. Convert strategic
positioning into measurable pipeline.

## Voice Manifesto
- Lead with outcomes, not activities.
- No hedging. If the data supports a claim, make it.
- Cite studies with year + sample size, or don't cite.
- Active voice. Nouns before modifiers.

## Methodology
1. Audit — ICP, offer, current funnel, competitor landscape.
2. Position — Blue Ocean differentiator, value equation (Hormozi).
3. Sequence — TOFU/MOFU/BOFU assets, tied to funnel stage.
4. Instrument — UTM, attribution, cohort definitions.
5. Launch — 5-phase ORB framework.
6. Iterate — weekly metric review, monthly offer revisit.

## Skill Arsenal
| Slug | Purpose | When |
|------|---------|------|
| 01-market-research | Competitive intel | Pre-launch, quarterly |
| 02-customer-avatar | ICP definition | Before any copy |
| 03-brand-voice | Voice guidelines | All content review |
| 07-landing-page-copy | Long-form copy | Launch assets |

## Decision Framework
Weight: existing-pipeline-impact (40), 90-day-revenue-lift (30), brand-equity (20), effort (10).

## Escalation Rules
- Budget decisions >$10K → escalate to CFO persona.
- Legal claims in copy → escalate to human.
- Trademark or partnership mentions → escalate to human.

## Negative Boundaries
- Never fabricate testimonials, reviews, or case-study numbers.
- Never promise ROI without a statistically valid experiment.
- Never ship copy that violates FTC endorsement guidelines.
```

---

### Layer 2 — Project Overlay (OPTIONAL, PROJECT-SCOPED)

**Path:** `{project-root}/.claude/departments/{dept}.md`

**Ownership:** Whoever owns the project. Evolves as the project evolves. Committed to git with the project.

**Purpose:** project-specific facts the CMO/CFO/etc. must know before speaking — current offer, ICP, KPIs, ad account IDs, ecosystem rules.

**Frontmatter:** none required. Optional `updated:` timestamp for freshness.

**Suggested sections (NONE REQUIRED — overlay whatever the project needs):**

```markdown
# {Department} — Project Overlay: {Project Name}

## Current Offer
Name, price, pricing model, guarantee, what's included.

## ICP (Ideal Customer Profile)
Demographic + psychographic + technographic. Tie to funnel stage if relevant.

## KPIs & Targets
Metric → target → current → owner. Refresh monthly.

## Active Channels & Accounts
Platform → account ID → role → permission scope. Sanitize — no secrets here.

## Project-Specific Rules
Anything that contradicts or constrains the canon. Example: "Never offer discounts
>20% without founder approval."

## Ecosystem Boundaries
What this product is NOT allowed to claim, offer, or integrate.
```

**Size target:** 500-2000 tokens. Bigger means the overlay is doing canon's job.

**Example overlay for a shipped SaaS:**

```markdown
# Marketing — Project Overlay: Acme DataSync

## Current Offer
Acme DataSync Pro — $49/mo, 14-day free trial, annual 20% off.
Includes: unlimited syncs, 10 integrations, Slack support.

## ICP
B2B data engineers at 50-500 person companies. Pain: integration sprawl,
manual CSV patching. Sophistication: high technical, low marketing.

## KPIs & Targets
| Metric | Target | Current | Owner |
|--------|--------|---------|-------|
| MRR | $50K | $32K | CEO |
| Trial → Paid | 18% | 12% | PM |
| CAC payback | <6mo | 9mo | CMO |

## Active Channels & Accounts
- Google Ads: 555-123-4567 (Admin: founder)
- LinkedIn Ads: acme-datasync-co
- Newsletter: ConvertKit, 8K list

## Project-Specific Rules
- Never offer >20% discount without founder approval.
- All copy referencing enterprise features must link to the self-serve limits doc.

## Ecosystem Boundaries
- Not HIPAA-compliant. Do not pitch to healthcare.
- No SOC 2 yet — do not claim "enterprise-ready security."
```

---

### Layer 3 — User Overlay (OPTIONAL, USER-SCOPED, SELF-EVOLVING)

**Path:** `~/.claude/departments/{dept}/user-overlay.md`

**Ownership:** `flush.py` writes this. Humans may edit manually (explicit memory saves). The composer reads only.

**Purpose:** accumulated user-specific learnings across projects — voice preferences, campaign outcomes, anti-patterns the user has encountered.

**Frontmatter (OPTIONAL but recommended):**

```yaml
---
department: string        # Mirrors directory name
owner: string             # User email or identifier
updated: string           # ISO 8601 of last write
token_count: integer      # flush.py estimate for budget tracking
schema_version: string    # Matches this SCHEMA.md version
---
```

**Required sections (STRICT — flush.py MUST conform):**

```markdown
## Voice & Prefs
{entries}

## What Worked
{entries}

## What Failed
{entries}

## Anti-Patterns To Avoid
{entries}
```

**Entry format (STRICT — newest-at-top, ISO-8601 timestamped):**

```markdown
- {ISO-8601-timestamp} — {what was learned, scoped to one sentence}
  Context: {campaign/deploy/feature identifier}
  Why it matters: {one sentence}
```

Example:

```markdown
## What Worked
- 2026-04-10T14:22:00Z — Email subject lines under 40 chars lifted open rate from 22% → 31%.
  Context: Academy Apr-2026 launch, 3-email welcome sequence
  Why it matters: Default CRM template defaults to 55+ char subjects.

- 2026-03-28T09:05:00Z — Testimonial-led hero beat feature-led hero by 18% CTR.
  Context: SaaS landing page A/B test, n=2400
  Why it matters: Persona defaulted to feature-led until this test.
```

**Size budget:** **5000 tokens per overlay file (HARD CAP).**

When `flush.py` pushes a new entry that would exceed 5000 tokens, it MUST:

1. Compute an estimate (tiktoken if available, else chars/4).
2. If over cap, summarize the oldest 20% of entries per section into a single "Summary of entries before {date}" bullet at the bottom of that section.
3. Delete the summarized individual entries.
4. Update `token_count` in frontmatter.

Never let the overlay grow past the cap. Better to lose detail than to blow the composer budget.

**Append-only rule (exception: pruning):** new entries go at the top of their section. Never reorder, never edit existing entries. Pruning is the only exception — it collapses the bottom of a section into a summary bullet, which is a write.

---

## 4. Composition Rules (Runtime Behavior)

The composer (`~/.claude/hooks/department-composer.sh`) executes as a `UserPromptSubmit` hook. It:

1. **Detects** — reads stdin (JSON or raw), extracts the prompt, checks the first slash-token against the 13 canonical departments, then against `config.department_aliases` in the repo registry. An alias with its own canon directory (alias-canon: `/ads`, `/growth`, `/support`, `/gtm`) composes that directory's `department.md`; other aliases compose their target department. No match → exit 0 silently, no stdout.
2. **Sources** — builds three paths (Layer 1/2/3). For each: missing → skip + log INFO. Empty → skip + log INFO. Unreadable → skip + log WARN.
3. **Scans** — each present layer is scanned for banned substrings (case-insensitive): built-in neutral markers (`confidential-internal`, `do-not-ship`, `internal-only`) plus any terms the operator lists in `~/.claude/department-composer-banned.txt` (one lowercase term per line). Any hit → drop the layer entirely + log WARN.
4. **Composes** — emits header (dept name, timestamp, CWD), then each surviving layer with a `## LAYER N — {Label}` divider and a `Source: {absolute path}` line.
5. **Logs** — appends a single-line event to `~/.claude/logs/department-composer.log` with dept, layer hit count, elapsed ms, CWD.
6. **Budgets** — target ≤200ms; soft budget. Exceeds → WARN log entry. Never fails the hook.

**Fail-safe invariant:** every non-zero exit is a bug. The hook always exits 0. If composition fails, the slash command still runs without the overlay.

---

## 5. Self-Evolution Contract

The user overlay learns over time via three mechanisms:

| Trigger | Mechanism | Owner |
|---------|-----------|-------|
| **Explicit save** | User says "save this to my marketing overlay" — Claude appends a timestamped entry to the correct section. | Session Claude |
| **Post-session classification** | Stop hook runs `flush.py` → classifies session events → appends to relevant department overlay(s). | `flush.py` (backend-engineer owns) |
| **End-of-invocation prompt (OPTIONAL)** | After a long `/marketing` session, the department persona may ask: "Want me to save X, Y, Z to your overlay?" | Persona agent |

**Classifier contract (for flush.py):**

Input: session transcript (JSONL of user messages + assistant actions).
Output: zero or more entries, each with:
```json
{
  "department": "marketing",
  "section": "What Worked",
  "timestamp": "2026-04-17T21:45:00Z",
  "entry": "Subject lines under 40 chars lifted open rate 22% → 31%.",
  "context": "Academy Apr-2026 launch",
  "why": "Default CRM templates start at 55+ chars"
}
```

flush.py appends to `~/.claude/departments/{department}/user-overlay.md`. If the file doesn't exist, flush.py creates it with the required section headers and frontmatter (`schema_version: 1.0.0`).

**Ambiguity rule:** if flush.py can't classify an entry to one of the 13 departments with ≥0.8 confidence, it drops the entry. Do not write to a "general" overlay; do not duplicate across departments.

---

## 6. Versioning

Changes to this SCHEMA.md use semver:

- **MAJOR:** breaking changes to frontmatter fields, required sections, or layer order.
- **MINOR:** new optional sections, new departments added, new frontmatter fields.
- **PATCH:** clarifications, typo fixes, example updates.

Every canon file's `version:` frontmatter tracks this schema's version at time of writing. The composer does NOT currently enforce schema version — canon files can be any version. But backend-engineer and flush.py MUST refuse to write when `schema_version` in user-overlay frontmatter is newer than they understand.

---

## 7. Files That Consume This Schema

| Consumer | What it reads | What it writes |
|----------|---------------|----------------|
| `~/.claude/hooks/department-composer.sh` | All 3 layers | Log + stdout |
| `flush.py` (Stop hook) | Session transcript | Layer 3 overlays |
| `backend-engineer` agent | This SCHEMA.md + session data | Classifier proposals |
| `lead-architect` agent | This SCHEMA.md | New department canons |
| `cmo` / `finance-director` / etc. persona agents | All 3 layers at runtime | Nothing (read-only personas) |

When you add a new consumer, update this table in the same PR.
