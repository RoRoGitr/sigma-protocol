---
name: tdd-skill-creation
description: "Use when creating new skills, editing existing skills, or verifying skills work before deployment. Applies Test-Driven Development methodology to skill documentation."
version: "1.0.0"
source: "@obra/superpowers writing-skills"
triggers:
  - create-skill
  - new-skill
  - edit-skill
  - step-13-skillpack-generator
  - skill-verification
  - new-command
  - test-gen
---

# TDD for Skill Creation

**Writing skills IS Test-Driven Development applied to documentation.**

You write test cases (pressure scenarios), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

## The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

---

## TDD Mapping for Skills

| TDD Concept | Skill Creation Equivalent |
|-------------|---------------------------|
| Test case | Pressure scenario with subagent |
| Production code | Skill document (SKILL.md) |
| Test fails (RED) | Agent violates rule without skill |
| Test passes (GREEN) | Agent complies with skill present |
| Refactor | Close loopholes while maintaining compliance |
| Write test first | Run baseline scenario BEFORE writing skill |
| Watch it fail | Document exact rationalizations agent uses |
| Minimal code | Write skill addressing those specific violations |

---

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in CLAUDE.md or project rules)
- Mechanical constraints (if enforceable with validation, automate it)

---

## RED-GREEN-REFACTOR for Skills

### RED: Write Failing Test (Baseline)

Run a pressure scenario with a subagent **WITHOUT** the skill loaded. Document:

```markdown
## Baseline Test Results

**Scenario:** [Description of what you asked the agent to do]

**Without skill, agent did:**
- [Actual behavior 1]
- [Actual behavior 2]

**Rationalizations used (verbatim):**
- "I thought it would be faster to..."
- "Since the user didn't explicitly say..."
- "It seemed obvious that..."

**Pressure triggers that caused violations:**
- Time pressure: "This needs to be done quickly"
- Sunk cost: "I've already done most of the work"
- Authority: "The senior dev said to skip this"
```

### GREEN: Write Minimal Skill

Write a skill that addresses **those specific rationalizations**. Don't add extra content for hypothetical cases.

```markdown
## Skill Content (Minimal)

**Addresses rationalization 1:**
[Rule/guidance]

**Addresses rationalization 2:**
[Rule/guidance]
```

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

```markdown
## Loophole Discovered

**New rationalization:** "I followed the spirit of the rule, not the letter"

**Counter added to skill:**
"Violating the letter of the rules IS violating the spirit of the rules."
```

---

## Skill Structure

### Required Frontmatter

```yaml
---
name: skill-name-with-hyphens
description: "Use when [specific triggering conditions and symptoms]. Third person."
version: "1.0.0"
triggers:
  - keyword-1
  - keyword-2
---
```

**Frontmatter Rules:**
- Only `name`, `description`, `version`, `triggers` supported
- Name: letters, numbers, hyphens only (no special chars)
- Description: Start with "Use when...", max 500 chars
- **NEVER summarize the skill's workflow in description** (agents shortcut it)

### Body Structure

```markdown
# Skill Name

## Overview
Core principle in 1-2 sentences.

## When to Use
- Symptoms and use cases (bullets)
- When NOT to use

## Core Pattern
Before/after comparison or key rules

## Quick Reference
Table or bullets for scanning

## Common Mistakes
What goes wrong + fixes

## Checklist
- [ ] Verification items
```

---

## Bulletproofing Against Rationalization

Skills that enforce discipline need to resist rationalization.

### Close Every Loophole Explicitly

```markdown
# ❌ BAD: Vague rule
"Write tests before code"

# ✅ GOOD: Explicit with closed loopholes
"Write tests before code.

**No exceptions:**
- Don't keep untested code as 'reference'
- Don't 'adapt' existing code while writing tests  
- Don't look at implementation before tests pass
- Delete means delete"
```

### Build Rationalization Table

Every excuse agents make goes in the table:

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to agents. Test it. |
| "Too simple to test" | Simple things break. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "This is different because..." | It's not. Follow the rule. |
| "I'm following the spirit" | The letter IS the spirit. |

### Create Red Flags List

Help agents self-check:

```markdown
## Red Flags - STOP and Start Over

- Code before test
- "I already manually tested it"
- "This achieves the same purpose"
- "This is different because..."

**All of these mean: Start over.**
```

---

## Testing Different Skill Types

### Discipline-Enforcing Skills (rules/requirements)

**Examples:** TDD, verification-before-completion, coding standards

**Test with:**
- Pressure scenarios (time + sunk cost + exhaustion combined)
- Academic questions (do they understand the rules?)
- Find rationalizations and add explicit counters

**Success:** Agent follows rule under maximum pressure

### Technique Skills (how-to guides)

**Examples:** debugging patterns, performance optimization, design patterns

**Test with:**
- Application scenarios (can they apply it?)
- Edge cases (do they handle variations?)
- Missing information (are instructions complete?)

**Success:** Agent successfully applies technique to new scenario

### Reference Skills (documentation/APIs)

**Examples:** API docs, command references, library guides

**Test with:**
- Retrieval scenarios (can they find info?)
- Application scenarios (can they use what they found?)
- Gap testing (are common use cases covered?)

**Success:** Agent finds and correctly applies reference

---

## Skill Creation Checklist

**Use TodoWrite to track each item.**

### RED Phase

- [ ] Create pressure scenarios (3+ combined pressures)
- [ ] Run scenarios WITHOUT skill
- [ ] Document baseline behavior verbatim
- [ ] Identify rationalizations/patterns

### GREEN Phase

- [ ] Name uses letters, numbers, hyphens only
- [ ] Description starts with "Use when..."
- [ ] Description does NOT summarize workflow
- [ ] Address specific baseline failures
- [ ] Run scenarios WITH skill - verify compliance

### REFACTOR Phase

- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters
- [ ] Build rationalization table
- [ ] Create red flags list
- [ ] Re-test until bulletproof

### Quality Checks

- [ ] Overview is 1-2 sentences
- [ ] Quick reference table exists
- [ ] Common mistakes documented
- [ ] No narrative storytelling
- [ ] Flowcharts only for non-obvious decisions

---

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |

**All of these mean: Test before deploying. No exceptions.**

---

## Integration with SSS Protocol

### Step 13 (Skillpack Generator)

Use TDD methodology for all generated skills:
1. Run baseline test for each skill type
2. Write minimal skill addressing failures
3. Refactor until bulletproof

### New Skill Creation

Before adding ANY skill to the protocol:
1. Define pressure scenarios
2. Run baseline test
3. Document rationalizations
4. Write skill
5. Verify compliance
6. Close loopholes

---

## The Bottom Line

**Creating skills IS TDD for process documentation.**

Same Iron Law: No skill without failing test first.
Same cycle: RED (baseline) → GREEN (write skill) → REFACTOR (close loopholes).
Same benefits: Better quality, fewer surprises, bulletproof results.

If you follow TDD for code, follow it for skills. It's the same discipline applied to documentation.

---

*Remember: If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.*
