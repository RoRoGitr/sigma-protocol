---
description: "Batch execution with checkpoints for implementation plans. Use when executing a written plan with review gates. Triggers on 'execute plan', 'implement plan', 'batch execution', 'plan execution'."
name: executing-plans
department: core
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Record the plan in the runtime's available task tracker, or maintain a checklist in the plan file when no task tool is exposed, and proceed. Do not call an unavailable tool name.

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Inspect the skills actually available in this runtime. If `superpowers:finishing-a-development-branch` is available and applicable, announce its use and follow it within the repository's permissions and workflow.
- If it is unavailable, follow the repository's documented completion procedure: verify the required tests/checks, report their output and outstanding changes, present the permitted completion options, and execute only the authorized choice. Do not invent a skill call or treat missing tooling as permission to merge, deploy or clean up.
- Preserve the plan's explicit approval gates and the report-and-wait policy below in either path.

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess

## When NOT to Use

- Not for creating plans — use brainstorming or deep-research first
- Not for single-file edits — execution overhead exceeds benefit for trivial changes
- Not for exploratory research — requires a written plan as input
- Not for debugging — use systematic-debugging skill instead

## Related Skills

- `agent-development` — meta
- `agentation` — meta
- `creating-opencode-plugins` — meta
- `bdd-scenarios` — qa

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

Use the file-reading, editing, shell verification and task-tracking capabilities actually exposed by the runtime. Tool names vary by client; inspect the available tools before calling them. Use the plan-file checklist when no task tracker is present. If a required capability has no supported equivalent, report the blocker under the stop policy above. External research tools are needed only when the plan requires research.
