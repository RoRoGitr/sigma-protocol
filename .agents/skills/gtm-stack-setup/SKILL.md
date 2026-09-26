---
name: gtm-stack-setup
description: "GTM stack checklist — analytics, pixels, email, social scheduling. Routes to PostHog, your social scheduler, Meta; does NOT call APIs."
department: marketing
---

# gtm-stack-setup

**Mission:** Produce a founder-friendly checklist to connect marketing tools. This skill **does not call APIs** — it outputs steps and hands off to MCPs/CLIs.

## When to invoke

- Run Track M3 (`/run-m-3-stack-tracking`)
- Any time analytics or pixels are missing before launch

## Read first

- `docs/run-track/TOOL-STACK-MATRIX.md`
- `docs/run-track/marketing/M2-AVATAR-POSITIONING.md` (if exists)
- Project overlay: `.claude/departments/marketing.md` or `{project}/.claude/departments/marketing.md`

## Checklist order

1. **Analytics** — PostHog or GA4: project create, snippet/SDK, test `$pageview` + 1 custom event
2. **Error tracking** — Sentry (if app live): project + DSN in env (no secrets in git)
3. **Meta Pixel** — if paid social: pixel ID, PageView + Lead/Purchase events
4. **Google tag** — if Google Ads: gtag or GTM container
5. **Email** — Resend / ConvertKit / GHL: domain verify, from-address
6. **CRM link** — note CRM choice for Sales S2; do not configure pipeline here
7. **the social scheduler** — `accounts_list` MCP → document account IDs in overlay
8. **UTM convention** — `utm_source`, `utm_medium`, `utm_campaign` table in doc

## Handoffs

| Tool | Execute via |
|------|-------------|
| PostHog | PostHog docs / project settings |
| the social scheduler | your scheduler's MCP → `accounts_list`, `posts_create` (HITL) |
| Meta Pixel | Meta Events Manager docs |
| Sentry | MCP `user-sentry` or `sentry` skill |

## Output

Write `docs/run-track/marketing/M3-STACK-CHECKLIST.md` using `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md`.

Emit `M03.001` to `.sigma/backlogs/marketing/prd.json` if any tool setup is a multi-day task.

## Negative boundaries

- Do not store API keys in repo
- Do not configure CRM pipeline stages (Sales S2)
- Do not write ad creative (M5 / `/ads`)
