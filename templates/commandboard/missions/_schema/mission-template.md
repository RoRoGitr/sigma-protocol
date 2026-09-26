# Mission: {{TITLE}}

**ID:** `{{ID}}`
**Workspace:** `{{WORKSPACE}}`
**Status:** `{{STATUS}}`
**Created:** `{{CREATED}}`
**Deadline:** `{{DEADLINE}}`

---

## Why This Mission Matters

<!-- 2-4 sentences. What outcome do we need? Why now? What's at stake if we don't ship? -->

{{WHY}}

## /goal Condition

> {{OVERALL_GOAL_CONDITION}}

This is the argument you pass to `/goal` when dispatching this mission:

```
claude -p '/goal {{OVERALL_GOAL_CONDITION}}'
```

## Success Criteria

### Machine-Verifiable
<!-- Runnable predicates — halt oracle counts these automatically. -->

{{MACHINE_CHECKS}}

### Human Sign-Off Required
<!-- LLM-assessed, but completion requires explicit human "yes". -->

{{SOFT_CRITERIA}}

## Constraints

<!-- What CAN'T we touch? Budget caps? Tier gates? Audience? -->

- **Do not touch:** {{DO_NOT_TOUCH}}
- **Budget:** {{BUDGET}}
- **Tier gate:** {{TIER_GATE}}
- **Audience:** {{AUDIENCE}}

## Halt Conditions

Mission ends when ANY of:

{{HALT_ON}}

## Auto-Research

<!-- Keywords the mission-autoresearch agent watches for relevant external intel. -->

- **Enabled:** {{AUTORESEARCH_ENABLED}}
- **Cadence:** {{AUTORESEARCH_CADENCE}}
- **Keywords:** {{AUTORESEARCH_KEYWORDS}}

## Stack

<!-- Parent mission (if any) and sub-missions. -->

- **Parent:** {{PARENT_ID}}
- **Children:** {{CHILDREN}}

## Ledger

OODA log: [`ledger.jsonl`](./ledger.jsonl)

## Notes

<!-- Running notes, pivots, open questions. Promote to success_criteria or constraints when they harden. -->

{{NOTES}}
