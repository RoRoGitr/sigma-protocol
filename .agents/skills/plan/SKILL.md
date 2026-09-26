---
name: plan
description: "Turn any PRD into a detailed implementation plan using relevant skills and available evidence."
---
---
version: "1.0.0"
last_updated: "2025-12-21"
changelog:
  - "1.0.0: Initial release — PRD-first implementation planning with available evidence"
description: "Turn any PRD into a detailed implementation plan using relevant skills and available evidence."
allowed-tools:
  # PRIMARY MCP Tools (Use First)
  - mcp_ref_ref_search_documentation
  - mcp_ref_ref_read_url
  - mcp_exa_web_search_exa
  - mcp_exa_get_code_context_exa
  - mcp_exa_crawling_exa
  - mcp_exa_deep_researcher_start
  - mcp_exa_deep_researcher_check

  # ALWAYS ACTIVE (Specialized)
  - mcp_sequential-thinking_sequentialthinking

  # BACKUP MCP Tools (Use only if primary fails)
  - mcp_ref_ref_search_documentation
  - mcp_ref_ref_read_url
  - mcp_firecrawl_firecrawl_search
  
  # OTHER TOOLS
  - web_search
  - read_file
  - write
  - list_dir
  - glob_file_search
  - grep
  - codebase_search
  - run_terminal_cmd
parameters:
  - --prd-id
  - --prd-path
  - --phase-brief
  - --depth
  - --skills
  - --output
---

# @plan

**PRD-first implementation planning with evidence-backed research and relevant skills**

## 🎯 Purpose

You use this when you want to stop re-typing “plan this implementation, use skills, be detailed, follow best-practices dimensions, find evidence, don’t assume.”

This command produces a **single, comprehensive implementation plan** that is:
- **Skill-driven** (loads and applies project skills/rules when available)
- **Evidence-backed** (non-trivial decisions cite an available authoritative source or state the uncertainty)
- **Assumption-free** (unknowns become explicit questions/TBDs)
- **Dimension-complete** (Functional, Technical, Security, Testing, UX/A11y, Performance, Observability, Rollout/Ops)

**Important:** This command creates a plan. It does **not** implement code.

---

## 📋 Command Usage

```bash
# Plan a specific screen PRD from Step 5's numbered folder structure
@plan --prd-id=01-auth/01-welcome-screen

# Plan an entire flow (all PRDs in the flow folder, in numeric order)
@plan --prd-id=01-auth

# Plan from an explicit file path
@plan --prd-path=docs/prds/F03-voice-intake-agent.md

# Inject an explicit tracked phase brief
@plan --prd-path=docs/prds/F03-voice-intake-agent.md --phase-brief=docs/plans/PHASE-BRIEF-F03.md

# Deeper planning + explicitly force skill usage
@plan --prd-id=01-auth/01-welcome-screen --depth=deep --skills=frontend-aesthetics,backend-engineering,database-modeling

# Override output path
@plan --prd-id=01-auth/01-welcome-screen --output=docs/plans/PLAN-YYYY-MM-DD-auth-welcome.md
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--prd-id` | PRD ID (supports Step 5 flow/screen IDs; legacy paths also supported) | Optional (but recommended) |
| `--prd-path` | Explicit path to a PRD markdown file | Optional |
| `--phase-brief` | Optional tracked phase brief to inject into planning context | Auto-discover from PRD or feature slug |
| `--depth` | `quick` / `standard` / `deep` | `standard` |
| `--skills` | Comma-separated list of skills to apply | Auto-detect |
| `--output` | Output plan filepath | Auto-generate (see below) |

### PRD Path Formats (Step 5 Numbered Structure)

| Format | Example | Resolves To |
|--------|---------|-------------|
| `flow/screen` | `01-auth/01-welcome-screen` | `docs/prds/flows/01-auth/01-welcome-screen.md` |
| `flow` (all screens) | `01-auth` | All `.md` in `docs/prds/flows/01-auth/` |
| `legacy` | `frontend/01-feature` | `docs/prds/frontend/01-feature.md` |

---

## 📁 File Management (CRITICAL)

**Default output directory:** `docs/plans/` (create if missing)

**Default filename:** `docs/plans/PLAN-YYYY-MM-DD-<slug>.md`
- `slug` should be derived from PRD ID or PRD title (kebab-case)

**File strategy:** `append-dated` (each run generates a new dated file)

**Manifest (if your repo uses it):** `updateManifest('@plan', planPath, 'append-dated')`

---

## ✅ Non-Negotiable Rules (Read First)

1. **No assumptions.** If a requirement or constraint is missing, do not guess. Ask a question or label it **TBD** (with impact).
2. **Capability-aware research.** Any non-trivial implementation decision must be supported by citations from available primary documentation or search results; record when no source is available.
3. **Skills must be applied.** If skills exist, load them and treat them as constraints.
4. **Best-practices dimensions are mandatory.** Every plan must explicitly cover:  
   Functional, Technical, Security, Testing, UX/A11y, Performance, Observability, Rollout/Ops.
5. **HITL checkpoints.** Stop for approval before the plan is considered final.

---

## ⚡ Preflight (auto)

1) **Capture date** (for filename): `date +"%Y-%m-%d"`  
2) **Resolve PRD(s)** in this priority order:
- If `--prd-path` is provided → read it.
- Else if `--prd-id` is provided → resolve using:
  - Step 5 numbered structure:
    - If `prdId` looks like `^\d{2}-` and contains `/` → `docs/prds/flows/${prdId}.md`
    - If `prdId` looks like `^\d{2}-` and does NOT contain `/` → include all `docs/prds/flows/${prdId}/[0-9][0-9]-*.md` in numeric order
  - Else → `docs/prds/${prdId}.md`
- Else → use the PRD content provided in the chat/context as the source of truth.

3) **Load project anchors** if they exist (do not assume they exist):
- `docs/specs/MASTER_PRD.md`
- `docs/stack-profile.json`
- `docs/architecture/ARCHITECTURE.md`
- `docs/technical/TECHNICAL-SPEC.md`
- `docs/design/DESIGN-SYSTEM.md`
- `docs/design/UI-PROFILE.md`
- `docs/design/ui-profile.json`
- `docs/states/STATE-SPEC.md`

4) **Load tracked phase brief context** when available:
- If `--phase-brief` is provided → load it directly.
- Else if the PRD path or PRD ID makes the feature slug obvious → look for the newest matching `docs/plans/PHASE-BRIEF-*.md`.
- If no brief exists, continue normally.

5) **Bulletproof gate awareness (if steps 4/5 were used):**
- If present, load:
  - `docs/flows/TRACEABILITY-MATRIX.md`
  - `docs/flows/ZERO-OMISSION-CERTIFICATE.md`
  - `docs/prds/flows/WIREFRAME-TRACKER.md`
  - `docs/wireframes/PROTOTYPE-SUMMARY.md`
- If missing, note the risk and ask whether to proceed.

---

## 🧩 Skill Activation (required)

### How to choose skills

1) If `--skills` is provided → use those skills (and only those, unless you explicitly justify adding another).  
2) Else, auto-detect based on PRD content + repo evidence:
- UI/components/screens → `frontend-aesthetics`
- API/server actions/endpoints/auth/permissions → `backend-engineering`
- Tables/migrations/RLS/Postgres/Supabase/Drizzle → `database-modeling`

### How to load skills (in order)

For each selected skill, load constraints from:
1. `src/skills/<category>/<skill>/SKILL.md` (authored source, preferred)
2. `.cursor/rules/*<skill>*.mdc` (Cursor rules)
3. `claude-code/plugins/sss-skillpack/skills/<skill>/SKILL.md` (if using SSS plugin)

If a requested skill cannot be found, do **not** proceed silently. Ask the user whether to:
- provide the skill file/path, or
- proceed with generic best practices (flagged as weaker).

---

## 🔎 Research Protocol (required)

For each major area of the plan, use an available documentation or search capability before deciding:
- **Framework/stack specifics** (Next.js, Supabase, Drizzle, Expo, etc.)
- **Auth patterns** (sessions vs JWT, RLS, RBAC)
- **Data modeling patterns** (constraints, indexing, migrations, RLS)
- **UI patterns** (a11y requirements, component architecture, form validation)
- **Performance** (caching, pagination/virtualization, budgets)
- **Testing** (best practices for the stack, e2e strategy)

**Research notes must include:**
- Query string and capability used
- Key findings (bulleted)
- Citations (source name + URL)

If research is inconclusive, mark as **UNKNOWN** and ask a question. Do not guess.

---

## 🧠 Planning & Task Creation (CRITICAL — DO THIS FIRST)

Before writing the plan, create a task list that follows the best-practices dimensions. Use this skeleton (expand it heavily based on PRD):

```markdown
## Implementation Plan Tasks (Draft)

### Phase 0: Context & Constraints
- [ ] Load PRD(s) + anchors (stack, architecture, technical spec, design system, states)
- [ ] Load matching phase brief if one exists
- [ ] Identify scope boundaries + acceptance criteria mapping
- [ ] Identify missing info (blocking vs non-blocking)
- [ ] Select and load required skills; extract constraints
- [ ] Evidence: confirm stack best practices for key areas

### Phase 1: Architecture & Data Flow
- [ ] Define system boundaries + module ownership
- [ ] Define domain model + invariants
- [ ] Define data flow (UI → actions → DB) and error strategy

### Phase 2: Database (if applicable)
- [ ] Tables, constraints, indexes
- [ ] RLS policies + authorization model
- [ ] Migration plan + rollout/backfill strategy

### Phase 3: Backend/API (if applicable)
- [ ] Contracts (request/response), validation, error shapes
- [ ] AuthN/AuthZ enforcement points
- [ ] Idempotency, retries, rate limiting (as needed)

### Phase 4: Frontend/UI (if applicable)
- [ ] Routes/pages + layouts
- [ ] Component architecture + state management
- [ ] Forms, validation, loading/error/empty states
- [ ] Accessibility (WCAG), keyboard nav, focus management

### Phase 5: Testing
- [ ] Unit tests (core logic)
- [ ] Integration tests (DB/actions/routes)
- [ ] E2E tests (happy path + critical edge cases)
- [ ] Test data/fixtures strategy

### Phase 6: Performance
- [ ] Budgets (latency, bundle size, p95 targets if relevant)
- [ ] Caching, pagination/virtualization, query optimization

### Phase 7: Observability & Ops
- [ ] Logging/events, metrics, tracing (as applicable)
- [ ] Alerting / error tracking integration points

### Phase 8: Rollout & Backout
- [ ] Feature flags (if needed)
- [ ] Migration sequencing + rollback plan
- [ ] Monitoring checkpoints + kill switch
```

**HITL Checkpoint →** Present the plan and ask the user to approve before implementation.

---

## 🧾 Output Template (MUST FOLLOW EXACTLY)

Write the plan to `docs/plans/...` and also print a short summary in chat. The plan file must include:

1) **Context and inputs used**  
2) **Skills applied** (constraints enforced)  
3) **Open questions**  
   - Blocking  
   - Non-blocking  
4) **Scope** (in-scope, out-of-scope, acceptance criteria map)  
5) **Architecture overview** (modules, data flow, integration points, invariants)  
6) **Work breakdown** (detailed checklist by phases)  
7) **Best-practices dimensions checklist**  
   - Functional / Technical / Security / Testing / UX-A11y / Performance / Observability / Rollout-Ops  
8) **Risk register**  
9) **Research notes (sources + citations)**
10) **HITL checkpoint** (approve/revise)  

---

## 🔗 Related Commands

- `@holes` — Run gap analysis on the PRD or the plan (recommended before implementation)
- `@verify-prd` — Ensure PRD quality meets 8+/10 before implementing
- `@implement-prd` — Execute implementation after plan approval

---

$END$







