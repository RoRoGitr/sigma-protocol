# Skill Gap Analysis — Run Track v1

**Version:** 1.0.0  
**Updated:** 2026-06-29  
**Rule:** Intelligence layer only — skills route; MCPs/CLIs execute ([`ad-image-prompting`](../../.agents/skills/ad-image-prompting/SKILL.md) pattern).

---

## Marketing numbered skills (01–23)

| Skill | Verdict | Run step | Action |
|-------|---------|----------|--------|
| `01-market-research` | **Keep** | M1 | Trim: move Porter/Blue Ocean deep diagrams to `references/` if >4KB |
| `02-customer-avatar` | **Keep** | M2 | — |
| `03-brand-voice` | **Keep** | M4 | — |
| `04-offer-architect` | **Keep** | M4, Step 1.5 | — |
| `05-sales-strategy` | **Keep** | M4, S5 crossover | — |
| `06-email-sequences` | **Keep** | M7 | — |
| `07-landing-page-copy` | **Keep** | Step 9, M4 | — |
| `08-ads-strategy` | **Keep** | M5 | — |
| `09-retargeting-strategy` | **Keep** | M5, M9 | — |
| `10-launch-playbook` | **Keep** | M8 | — |
| `11-partnership-outreach` | **Keep** | M5 optional | — |
| `12-content-ideation` | **Keep** | M6 | — |
| `13-content-matrix` | **Keep** | M6 | — |
| `14-video-script` | **Keep** | M6 via `/content` | — |
| `15-thumbnail-prompts` | **Keep** | M6 via `/content` | — |
| `16-seo-content` | **Keep** | M9 | — |
| `17-community-update` | **Keep** | M10 | — |
| `18–23` content skills | **Keep** | M6 execution | Bound to `/content`, not M-steps |

---

## Sales skills

| Skill | Verdict | Run step | Action |
|-------|---------|----------|--------|
| `icp-definition` | **Keep** | M2, S1 | — |
| `lead-qualification` | **Keep** | S1, S4 | — |
| `outreach-sequencing` | **Keep** | S3 | — |
| `discovery` | **Keep** | S4 | — |
| `objection-handling` | **Keep** | S4, S8 | — |
| `high-ticket-closing` | **Keep** | S5 | — |
| `pricing-psychology` | **Keep** | S5 | — |
| `sales-identity` | **Keep** | Pre-S3 mindset | Optional invoke before outbound |
| `content-to-client` | **Keep** | S6 | — |
| `dm-funnel` | **Keep** | S6 | — |
| `follow-up-system` | **Keep** | S7 | — |
| `retention-engine` | **Keep** | M10 | Marketing-owned |

**Sales bench:** No changes required — canon aligns with research.

---

## New skills (v1)

| Skill | Type | Department | Hands off to |
|-------|------|------------|--------------|
| `gtm-stack-setup` | Reference + checklist | marketing | PostHog docs, the social scheduler MCP, Meta Business Help |
| `crm-pipeline-setup` | Reference + checklist | sales | GHL/HubSpot setup guides |
| `run-marketing` | Orchestrator | marketing | M1–M10 step skills |
| `run-sales` | Orchestrator | sales | S1–S8 step skills |
| `run-m-*` (10) | Orchestrator | marketing | Domain skills per phase |
| `run-s-*` (8) | Orchestrator | sales | Domain skills per phase |

---

## Trim candidates (post-v1 pass)

| Skill | Issue | Trim action |
|-------|-------|-------------|
| `01-market-research` | Long framework prose in SKILL.md | Extract frameworks to `references/market-frameworks.md` |
| `10-launch-playbook` | Duplicates CMO ORB summary | Keep ORB in department canon; skill = PLF execution only |

**Do not trim:** Sales skills — already dense and actionable.

---

## Coverage score (full framework)

| Track | Steps | Existing skill binding | New atom skills | Coverage |
|-------|-------|------------------------|-----------------|----------|
| M1–M10 | 10 | 10/10 | gtm-stack-setup | **100%** |
| S1–S8 | 8 | 8/8 | crm-pipeline-setup | **100%** |
| C1–C8 | 8 | 8/8 | content-production-queue | **100%** |
| G1–G8 | 8 | 8/8 | funnel-instrumentation-setup, ab-test-spec | **100%** |
| Co1–Co6 | 6 | 5/6 (Co4 moderation = playbook-only) | — | **≥83%** |
| O1–O8 | 8 | 8/8 | — | **100%** |
| Fn1–Fn7 | 7 | 7/7 | — | **100%** |
| L0–L8 | 9 | 9/9 | entity-formation-setup | **100%** |

---

## Content + Growth (v2)

| Skill | Verdict | Run step | Action |
|-------|---------|----------|--------|
| `14-video-script`, `18-youtube-script-writer` | **Keep** | C3 | — |
| `15-thumbnail-prompts` | **Keep** | C4 | — |
| `19-short-form-scripts` | **Keep** | C5 | — |
| `20-linkedin-writer`, `21-twitter-threads`, `23-story-posts` | **Keep** | C6 | — |
| `22-video-research` | **Keep** | C2 | — |
| `16-seo-content` | **Keep** | G8 | Moved primary bind from M9 to G8 |
| `content-production-queue` | **New atom** | C8 | the social scheduler MCP routing; checklist only |
| `funnel-instrumentation-setup` | **New atom** | G1, G2 | PostHog/GA4 event naming |
| `ab-test-spec` | **New atom** | G3–G5 | Hypothesis template |

**M9 trim:** M9 owns weekly review **cadence** only; G3–G5 own CRO **execution**.

---

## Community + Ops (v3)

| Skill | Verdict | Run step | Action |
|-------|---------|----------|--------|
| `community-analytics` | **Keep** | Co1, Co4, Co5 | — |
| `17-community-update` | **Keep** | Co2, Co3 | Distinct from `/run-content` scripts |
| `system-health`, `doctor-fix` | **Keep** | O1, O5 | — |
| `sprint-plan`, `backlog-groom`, `daily-standup` | **Keep** | O2 | — |
| `qa-plan`, `release-review`, `quality-gates` | **Keep** | O3 | Coordinates 8-gate pipeline |
| `observability` | **Keep** | O4 | — |
| `maintenance-plan` | **Keep** | O5, O7, O8 | — |
| `weekly-review` | **Keep** | O6 | WBR cadence |

---

## Finance + Legal (v4)

| Skill | Verdict | Run step | Action |
|-------|---------|----------|--------|
| `cost-optimizer` | **Keep** | Fn1, Fn4–Fn6 | — |
| `estimation-engine` | **Keep** | Fn3, Fn7 | — |
| `pricing-psychology` | **Keep** | Fn2 | — |
| `writing-clearly` | **Keep** | L1–L3 | Template prose |
| `entity-formation-setup` | **New atom** | L0 | LLC/S-Corp/C-Corp decision matrix |
| `deep-research` | **Keep** | L4, L8 | Trademark / precedent |
| `saas-security-patterns` | **Keep** | L5, L6 | DPA + compliance |

---

## New orchestrators (v2–v4)

| Skill | Type | Department |
|-------|------|------------|
| `run-content` | Orchestrator | content |
| `run-growth` | Orchestrator | growth |
| `run-community` | Orchestrator | community |
| `run-ops` | Orchestrator | ops |
| `run-finance` | Orchestrator | finance |
| `run-legal` | Orchestrator | legal |

---

## Registry updates required

Add to [`agent-skill-registry.json`](../../.claude/lib/agent-skill-registry.json):

- All `run-*` step and orchestrator entries (**64** numbered steps + **8** orchestrators)  
- Atom skills: `gtm-stack-setup`, `crm-pipeline-setup`, `content-production-queue`, `funnel-instrumentation-setup`, `ab-test-spec`, `weekly-review`, `entity-formation-setup`  
- `run_steps` cross-links per department in `.agents/departments/*/department.md`
