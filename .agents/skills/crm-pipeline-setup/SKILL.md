---
name: crm-pipeline-setup
description: "CRM pipeline setup — stage definitions, required fields, SLAs. Reference only; routes to GHL/HubSpot; does NOT call APIs."
department: sales
---

# crm-pipeline-setup

**Mission:** Document a sales pipeline the team (or founder) can configure in CRM. **Does not call CRM APIs.**

## When to invoke

- Run Track S2 (`/run-s-2-crm-pipeline`)
- Before any outbound sequence (S3)

## Read first

- `docs/run-track/RESEARCH-SALES-TEAM-ONBOARDING.md`
- `.agents/departments/sales/department.md` (canonical stage names)
- `docs/run-track/sales/S1-ICP-ACCOUNTS.md`

## Required pipeline stages (do not rename)

1. New  
2. Engaged  
3. Discovery Booked  
4. Qualified  
5. Evaluation  
6. Negotiation  
7. Verbal  
8. Closed Won / Closed Lost  

Each stage needs **one-sentence exit criteria** (HubSpot best practice).

## CRM tier routing

| Tier | Tool | Setup doc focus |
|------|------|-----------------|
| Bootstrap | Notion table | Column = stage, required fields as properties |
| Default | GHL or HubSpot free | Pipelines, deal properties, lifecycle |
| Scale | Salesforce | Opportunity stages, validation rules |

## Required fields at Qualified (SQL)

- Qualification notes  
- Estimated deal size  
- Economic buyer named  
- Timeline  
- Success criteria  

## Output

`docs/run-track/sales/S2-CRM-PIPELINE.md` + data dictionary table + `S02.001` in `.sigma/backlogs/sales/prd.json`.

Use sixth-grade template sections.

## Negative boundaries

- No lifecycle stage backward moves — use separate Re-engagement Status property
- No discount policy changes (founder / finance)
- No API automation in this skill
