# CONTEXT.md — Living Decision Log

> **Template version:** 1.0.0
> Copy this file into your project root or `docs/` directory and update it as decisions are made.
> Agents should update this file after any architectural or design decision.

---

## Project Metadata

| Field | Value |
|-------|-------|
| **Project** | {project-name} |
| **Version** | 0.1.0 |
| **Created** | {YYYY-MM-DD} |
| **Last Updated** | {YYYY-MM-DD} |
| **Primary Runtime** | claude-code / codex / both |
| **SSS Step** | 0 |

---

## Decision Log

Record every non-trivial decision here. If a decision was reversed, add a new row rather than deleting the old one.

| # | Date | Decision | Rationale | Alternatives Considered | Decided By | Status |
|---|------|----------|-----------|------------------------|------------|--------|
| 1 | {YYYY-MM-DD} | {What was decided} | {Why this choice} | {What else was evaluated} | {human / agent / both} | active |

### Decision Template

When adding a new entry:
- **Decision:** State the choice clearly in one sentence
- **Rationale:** Why this is the right call given current constraints
- **Alternatives:** What was rejected and why (prevents re-litigating)
- **Decided By:** Whether a human, agent, or both made the call
- **Status:** `active`, `superseded`, or `deferred`

---

## Current Assumptions

List assumptions the team is operating under. Mark each with a confidence level. Agents should challenge assumptions rated `low` before building on them.

| # | Assumption | Confidence | Basis | Last Verified |
|---|-----------|------------|-------|---------------|
| 1 | {What we assume to be true} | high / medium / low | {Evidence or source} | {YYYY-MM-DD} |

---

## Open Questions

Unresolved questions that block or influence future decisions. Assign an owner and target date.

| # | Question | Impact | Owner | Target Date | Resolution |
|---|----------|--------|-------|-------------|------------|
| 1 | {What needs answering} | {What it blocks or affects} | {Who is responsible} | {YYYY-MM-DD} | {Answer once resolved} |

---

## Dependency Map

Track external dependencies, integrations, and their status. This complements `runtime-baseline.json` with runtime details.

| Dependency | Type | Version / API | Status | Notes |
|-----------|------|---------------|--------|-------|
| {e.g., Supabase} | service / library / API | {version or endpoint} | active / planned / deprecated | {any constraints} |

---

## Integration Notes

Capture integration-specific context that agents need when working across service boundaries.

### {Integration Name}

- **Connection:** {How it connects — SDK, REST, RPC, etc.}
- **Auth:** {Auth mechanism — API key, OAuth, service account}
- **Constraints:** {Rate limits, payload limits, known gotchas}
- **Related Decisions:** {Link to decision log entries, e.g., #3}

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| {YYYY-MM-DD} | {who} | Initial CONTEXT.md created from template |

---

> **Maintenance rules:**
> - Update after every architectural decision, integration change, or assumption shift
> - Review open questions weekly — close resolved ones, add new ones
> - Agents: read this file before starting work on any task that touches architecture or integrations
> - Agents: append to the decision log after making non-trivial choices — do not modify existing entries
