---
name: holes
description: "PRE-implementation gap analysis and risk assessment - identifies holes in PLANS, requirements, and specifications BEFORE coding starts. Use gap-analysis for POST-implementation verification."
---
# holes — pre-implementation gap analysis

Run `$holes` BEFORE coding: during planning, after a PRD, before scaffolding. It finds gaps, risks, missing dependencies, and ambiguities in plans — not in code (that is `$gap-analysis`).

Mindset: a principal architect reviewing a design. "What is undefined? What will bite us later?" Completeness over speed, explicit over implicit.

## Inputs to capture first

1. What are we analyzing? (a PRD/feature, an architecture change, a scaffold plan, the whole spec)
2. What stage is the project? (ideation, design, spec, implementation)
3. Any known concerns already?
4. Decision deadline?

Load whatever planning docs exist: `docs/specs/MASTER_PRD.md`, `docs/architecture/ARCHITECTURE.md`, `docs/technical/TECHNICAL-SPEC.md`, `docs/implementation/FEATURE-BREAKDOWN.md`, `docs/stack-profile.json`, PRDs under `docs/prds/`.

## A. Requirements gaps

**User flows** — for every flow in scope, confirm all states are defined:
- signup: input, validation, success, error, email-verification
- login: input, validation, success, error, mfa, password-reset
- create/read/update/delete: loading, empty, saving, success, error, conflict, not-found, unauthorized, cascade-warning
- checkout/subscription: payment input, processing, success, failure, retry, upgrade, downgrade, cancel

**Edge cases** — confirm each is addressed: offline, slow network (>3s), timeout/retry, empty state, large dataset (pagination/virtualization), concurrent edit, stale cache, max length, special characters/unicode, pasted-content sanitization, session expiry mid-action, permission change mid-session, payment decline, refund, partial payment. Auth and payment gaps are HIGH severity.

**Vague language** — flag and demand specifics: "fast" (give latency targets), "easy to use", "when needed", "as appropriate", "etc.", "similar to", "may/might", "simple", "good enough".

## B. Technical gaps

- **API contracts:** request/response shapes, auth method, rate limits, pagination, exhaustive error codes, versioning, CORS. Routes with no docs = HIGH.
- **Data models:** every entity named in the PRD must have a schema definition. Missing = HIGH.
- **State management, performance budgets, and integration points** are specified, not implied.

## C. Risk assessment

Score each risk `likelihood (1-5) × impact (1-5)`: ≥20 CRITICAL, ≥12 HIGH, ≥6 MEDIUM, else LOW. Give a mitigation for each.

- **Scalability:** N+1 queries, pagination, caching, background jobs vs request cycle, large file uploads, websocket limits, search indexing.
- **Security:** RLS on all tables, input validation, rate limiting, audit logging, encryption of PII, secrets management.

## D. Dependencies

Map each as blocking / prerequisite / integration with status and owner. Always check: project scaffolding present? External services in `.env.example` (Supabase, Stripe, Resend, PostHog, OpenAI…) have accounts/credentials?

## E. Report

Write `docs/analysis/HOLES-ANALYSIS-<date>.md`:

```markdown
# Holes Analysis — <date>, scope: <scope>

## Summary
Gaps: <n> · Risks: <n> · Blocking deps: <n>
Severity: Critical <x> / High <x> / Medium <x> / Low <x>

## Requirements gaps        (by severity)
## Risk heat map            (risk | likelihood | impact | score | level | mitigation)
## Dependencies             (blocking / prerequisites / integrations)
## Decision matrix          (open questions needing an owner + deadline)
## Recommendations          (before vs during implementation)
```

Then auto-generate todos for every critical/high finding.

## Gap score (epistemic gate)

`gapScore = max(0, 100 − 50×critical − 10×high − 2×medium)`. Emit:

```markdown
<!-- EPISTEMIC-GATE-START -->
## Epistemic Confidence (Holes) — Gap Score: <x>%  [PASS ≥70 | BLOCKED <70]
<!-- EPISTEMIC-GATE-END -->
```

A score below 70% caps downstream confidence at 70% and blocks `$implement-prd` until critical gaps are resolved.

## Final gate

Present totals (gaps, risks, blocking deps, severity breakdown, gap score) and the report path. Require explicit approval. Critical gaps and blocking dependencies must be resolved before implementation.

Related: `$gap-analysis` (post-implementation), `$step-verify`, `$status`, `$security-audit`, `$implement-prd`.
