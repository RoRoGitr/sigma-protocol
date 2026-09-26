---
name: prd-patterns
description: Use when authoring, refreshing, or reviewing PRDs — including feature breakdown, backend specs, coverage expansion sprints, stale PRD detection, and Step 11 execution. Triggers on: PRD, feature breakdown, specs, prd-refresh, Step 11, docs/prds/, coverage expansion, backend wiring spec, feature audit.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# PRD Patterns

## When to Use

Use when generating new PRDs (Step 11), auditing PRD coverage against a live codebase, refreshing stale PRDs before a backend sprint, or defining a backend wiring spec for a frontend-first project. Also applies when defining module lesson inventory (PRD as lesson spec).

## Core Methodology

PRDs drift against actively developed code. Run a codebase audit before any backend sprint — never assume PRDs from last week reflect today's codebase. The audit approach: walk the codebase feature-by-feature against the existing PRD list. Any screen, route, or component group without a corresponding PRD gets flagged.

Refresh sprints run Steps 11 → 12 → 14 only (partial re-run). Steps 1-10 artifacts (architecture, UX, wireframes, feature breakdown) remain valid if the app structure did not change.

## Key Patterns

### PRD Coverage Audit

Before any backend sprint:
1. Walk the codebase feature-by-feature against the PRD list.
2. Flag any route, screen, or component group without a PRD.
3. Flag PRDs older than ~1 week against actively-developed code as likely stale.
4. Stale = generated, then frontend commits diverged from the spec.

Example: 11 PRDs generated on day 0. By day 6 (6 days of frontend commits), 5 were stale and 5 features had zero coverage. PRD drift rate: ~30% per week of active frontend development.

### Parallel PRD Regeneration

When expanding PRD coverage across many features, dispatch multiple agents with non-overlapping file boundaries:

```
Agent 1: stale PRDs batch A (e.g., F3/F4/F5)
Agent 2: stale PRDs batch B (e.g., F9/F12)
Agent 3: new PRDs batch (e.g., F13-F17)
Agent 4: tracker + scope fixes
```

Non-overlapping file ownership eliminates merge conflicts. Dispatch all four in parallel.

### PRD Structure (Step 11 Standard)

Each PRD specifies without ambiguity:
- Feature overview + acceptance criteria
- Edge function names (hyphenated, matching platform convention — e.g., Supabase uses `bookings-create`, not `/bookings/create`)
- Table schemas with column types, constraints, and NULL policy
- RLS/access control policies per table
- Hook conversion specs: mock-data function being replaced + React Query hook replacing it
- Migration requirements (flag explicitly if net-new tables required)

### Risk Assessment Table

Include a risk table per PRD sprint:

| PRD | Edge Functions | Hook Conversions | New Migrations | Risk |
|-----|---------------|-----------------|----------------|------|
| F13 | 6 | 4 + 2 mutations | 0 | 4/5 |

Migrations that break "zero new migration" assumptions must be flagged — they change sprint sequencing and can block parallel work.

### Feature Dependency Graph

Document cross-feature dependencies explicitly in the coverage expansion doc:

```
F13 Admin ──shares EF + hook──→ F17 Dashboard
F16 Connect ──requires──→ 00011_social_features.sql migration
F4 Discovery ──blocked by──→ destination vs city column rename
```

Cross-cutting data model issues (column renames, schema mismatches) must be fixed once at the source, not patched per-feature.

### PRD Prop Lock Pattern

For large frontend surfaces (e.g., 27 components with established prop contracts): lock prop contracts in PRD Section 12 as "DO NOT MODIFY." Any prop changes require a separate PRD amendment. This prevents scope creep during backend sprints and protects UI work from regression.

### Mission System Note

PRDs use YAML frontmatter including a `mission_id` field. Include this field when the PRD is linked to a curriculum unit or lesson objective.

### Module Expansion Pattern

For module expansion PRDs (e.g., expanding a module from 9 → 29 videos), the PRD specifies:
- Chapter breakdown with video count per chapter
- Per-lesson structure (video format + companion artifacts)
- Launch-blocking vs post-launch-drop sequencing
- Arithmetic derivation shown, not just the total (prevents count errors from propagating)

## Gotchas

- PRD older than ~1 week against actively-developed code: treat as potentially stale, verify before using as backend spec.
- Edge function naming: match the platform's convention exactly. Supabase uses hyphenated names (`bookings-create`). Slash-separated paths are wrong.
- `useState` vs `useQuery`: when a hook uses raw `useState`, hook conversion is a full rewrite, not a data-source swap. Flag this in the PRD risk section.
- Cross-feature shared dependencies (shared EF, shared hook) must be coordinated — duplicated implementations diverge silently.
- Arithmetic in PRD briefs must show derivation. A number without the math propagates silently if wrong (e.g., "26 videos" stated without showing the calculation, which was actually 29).

## File Locations / Conventions

```
Standard PRD location:
  docs/prds/{FEAT-ID}.md            — feature PRDs
  docs/prds/features/{FEAT-R2-X}.md — round-2 / supplemental PRDs

Project-specific:
  docs/prds/WEB-01.md through WEB-08.md — web-side contracts

Frontmatter fields:
  mission_id: string                — links PRD to academy mission
  status: draft | review | approved
  risk: 1/5 to 5/5
  blocking: [list of PRD IDs this blocks]
```

PRD ID conventions: `FEAT-N` for features, `WEB-N` for web-side contracts, `FEAT-R2-X` for round-2 specs.

## Quality Gates

- [ ] Codebase audit run against existing PRDs before sprint begins
- [ ] All screens, routes, and component groups have corresponding PRDs
- [ ] Stale PRDs (>1 week against active frontend) refreshed
- [ ] Edge function names match platform naming convention exactly
- [ ] Cross-cutting data issues documented and assigned to a single fix point
- [ ] Migration requirements flagged and sequenced
- [ ] Arithmetic in PRD counts shows derivation, not just total
- [ ] Context engine (CONTEXT.md) updated to reflect expanded PRD scope

## Related

- Vault articles: `prd-coverage-expansion.md`, `prd-refresh-sprint.md`, `round2-prd-backend-specs.md`
- Related skills: `sprint-patterns` (for parallel PRD dispatch and mock-data strategy), `migration-patterns` (for DB specs in PRDs)
