# Run Track Output Template

**Required sections for every Run Track artifact** (M-steps, S-steps, M/S PRDs, daily task exports).

Copy this structure into each output file. Write at a **sixth-grade reading level**: short sentences, no jargon without a glossary row.

---

## What we're doing

<!-- One sentence. What happens in this step. -->

## Why it matters

<!-- One sentence. Business outcome if this is done right. -->

## Your tasks today

<!-- MAX 3 items. Founder does these with their hands (logins, approvals, recordings). -->

1. 
2. 
3. 

## Your agent's tasks

<!-- Agent can do these with tools/skills. Unlimited list OK. -->

1. 

## Done when

- [ ] 
- [ ] 

## Words you might see

| Term | Plain meaning |
|------|---------------|
| ICP | Ideal Customer Profile — the kind of person you want to buy |
| GTM | Go-to-market — how you find customers and sell |
| CRM | Customer Relationship Manager — where deals and contacts live |
| UTM | Link tags that tell you which ad or post brought a visitor |
| Pixel | Small code on your site that tells ad platforms when someone visits |
| MQL | Marketing Qualified Lead — someone marketing says is worth sales' time |
| SQL | Sales Qualified Lead — someone sales confirmed is a real opportunity |

---

## PRD frontmatter (when emitting Mxx.xxx / Sxx.xxx JSON)

Use [`schemas/sigma-run-prd.schema.json`](../../schemas/sigma-run-prd.schema.json).

Minimum JSON fields: `prd_id`, `title`, `slug`, `department`, `run_step`, `goal`, `daily_tasks` (≤3), `artifact_path`, `plain_language_summary`.

---

## Linear issue format (Linear replaced the SigmaHQ kanban 2026-07-11)

When mirroring to Linear (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json):

```markdown
title: [marketing|M3] Connect PostHog
description: founder: create project, paste project ID in overlay
labels: run-track, marketing, M3, wave:W0
```

Wave labels are MANDATORY on every created issue (Linear when configured, otherwise wave-labeled GitHub Issues). Never write task tracking to the retired SigmaHQ kanban — GitHub always owns the PR/branch/review/merge loop.
