# QA Engineer Reference — Templates & Detailed Protocols

## Gap Analysis Round Protocol

Each round has 6 phases:

```
Phase 1: DEEP SEARCH — repository search for definitions, imports, callers or consumers, and relevant tests; GitNexus adds semantic or structural search when available
Phase 2: SEMANTIC AUDIT — Read files, check for contradictions between components
Phase 3: THRESHOLD CONSISTENCY — Cross-reference all hardcoded values across files
Phase 4: STRUCTURAL INTEGRITY — Count files, verify existence, validate frontmatter
Phase 5: SURFACE DRIFT — Check steps/ ↔ commands/ parity (bash scripts/lint-step-parity.sh) and registry wiring (node scripts/validate-cascade.mjs)
Phase 6: CROSS-MODEL REVIEW — Run the configured, approved independent-model review command and record the command and model
```

### Search Tool Hierarchy (MANDATORY)

| Priority | Tool | Use When |
|----------|------|----------|
| 1 | Repository search (`rg`, `Grep`, `Glob`, `Read`) | Trace definitions, imports, callers or consumers, and relevant tests |
| 2 | GitNexus, when available | Semantic search, import/export graphs, call chains, and impact analysis |
| 3 | Exact-match validation | Confirm the scoped search results and all affected references |

**Rules:** Start with available repository search. Use GitNexus for semantic or structural queries only when its tool is available. If it is unavailable or fails, continue with native search and record that fallback; do not block verification.

### Round 1: Broad Pattern Sweep

Focus: Known bad patterns, phantom references, missing files.

1. **Repository discovery sweep** — find definitions, imports, callers or consumers, and relevant tests across the codebase
2. **Structural analysis** — use GitNexus to map dependencies and find orphans when available; otherwise trace imports and consumers with repository search
3. **Exact-match validation** — confirm specific patterns and all affected references
4. **Structural checks** — all expected files exist, counts match docs, required frontmatter present
5. **Fix all issues.** Proceed to Round 2.

### Round 2: Semantic Depth

Focus: Contradictions between files, logical errors in instructions.

1. Cross-reference thresholds — every hardcoded value matches its canonical source
2. Pipeline handoff validation — Agent A output matches Agent B expected input
3. Instruction conflict detection — parallel agents with conflicting responsibilities
4. Guard rail verification — loop prevention, timeouts, fallbacks present
5. **Fix all issues.** Proceed to Round 3.

### Round 3: Mirror Drift

Focus: Platform mirror synchronization.

1. Count files in mirror vs canonical (.claude/)
2. Grep for fixed patterns in mirrors
3. Verify thresholds and models match in mirror copies
4. Sync mirrors from canonical source. Proceed to Round 4.

### Round 4+: Progressive Depth

Focus: Whatever prior rounds missed. Edge cases, error handling, race conditions.
**Continue until a round comes back with 0 new issues.**

### When to Stop

Stop when ALL are true:
1. Current round found 0 new issues
2. Acceptance score >= 95%
3. A configured, approved cross-model review from an independent model family confirms clean
4. No red flag blockers remain

---

## BDD Scenario Template

```gherkin
Feature: [Feature Name]
  As a [role]
  I want to [action]
  So that [benefit]

  Scenario: [Happy Path]
    Given [precondition]
    And [another precondition]
    When [action]
    Then [expected result]
    And [another expected result]

  Scenario: [Error Case]
    Given [precondition]
    When [action that fails]
    Then [error is shown]
    And [user can recover]

  Scenario: [Edge Case]
    Given [unusual condition]
    When [action]
    Then [correct handling]
```

---

## Verification Report Template

```markdown
# Verification Report: [Feature/PRD ID]

**Generated:** [TIMESTAMP]
**Verified By:** QA Engineer Agent (opus)
**Status:** PASS | PARTIAL | FAIL
**Rounds Run:** [N]
**Acceptance Score:** [X]% ([passed]/[total] checks)

## Summary

| Category | Score | Status |
|----------|-------|--------|
| Functionality | [X]/[Y] | [status] |
| Code Quality | [X]/[Y] | [status] |
| Testing | [X]/[Y] | [status] |
| Security | [X]/[Y] | [status] |
| Accessibility | [X]/[Y] | [status] |
| **Total** | **[X]%** | **[STATUS]** |

## Quality Gate Results

| Gate | Status | Evidence |
|------|--------|----------|
| Automated Checks | PASS/FAIL | [test count, lint status, build status] |
| Gap Analysis | PASS/FAIL | [acceptance score, rounds run] |
| Devils Advocate | PASS/FAIL | [findings count, critical resolved] |
| Cross-Model Review | PASS/FAIL | [codex findings, resolution status] |

## Round Summary

| Round | Focus | Issues Found | Issues Fixed | Score |
|-------|-------|-------------|-------------|-------|
| 1 | Pattern sweep | N | N | X% |
| 2 | Semantic depth | N | N | X% |
| 3 | Mirror drift | N | N | X% |
| 4 | Edge cases | 0 | 0 | X% ← CLEAN |

## Acceptance Criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | [AC from PRD] | PASS/FAIL | [file:line reference] |

## Test Results

[Test output summaries by layer]

## Mutation Testing

- Kill ratio: [X]%
- Surviving mutants: [list critical ones]

## Cross-Model Review

- Codex round: [N]
- Codex findings: [N] (all fixed / N remaining)

## Anti-Slop Score

- Average prompt score: [X]/10
- Files below 7: [list or "none"]

## Issues Found

| # | Round | Severity | File | Issue | Status |
|---|-------|----------|------|-------|--------|
| 1 | [N] | CRITICAL | [file:line] | [description] | Fixed/Open |

## Recommendation

**[SHIP / SHIP WITH CONDITIONS / DO NOT SHIP]**

- [ ] Acceptance score >= 95%
- [ ] Zero red flag blockers
- [ ] Cross-model review clean
- [ ] Devils advocate review addressed
- [ ] Anti-slop score >= 7 average
- [ ] All must-have requirements verified with evidence
- [ ] Mutation kill ratio >70% on critical paths
```

---

## Anti-Slop Scoring

| Pattern | Severity |
|---------|----------|
| Over-engineered abstractions | Critical |
| Premature helpers for one-time operations | Critical |
| Wrapper-for-wrapper (indirection without value) | Critical |
| Template paste (copied boilerplate without adaptation) | Critical |
| Kitchen-sink error handling (catches everything, handles nothing) | Moderate |
| Comments that restate the code | Minor |
| Verbose where clear would do | Minor |

```
SLOP_SCORE = 10 - (critical * 3) - (moderate * 1) - (minor * 0.5)
PASS = score >= 7
```

---

## AI Test Smell Detection

| Smell | Pattern | Fix |
|-------|---------|-----|
| **Happy-path-only** | Tests only exercise success cases | Add error, boundary, and edge case tests |
| **Truthiness assertions** | `expect(result).toBeTruthy()` | Assert specific values: `expect(result.id).toBe("abc-123")` |
| **Mock-hiding** | Mocked dependencies hide real integration failures | Use testcontainers or in-memory databases |
| **Implementation-mirroring** | Test reimplements the function and compares | Test observable behavior, not internal logic |
| **Snapshot overreliance** | Large snapshot tests nobody reviews | Use targeted assertions; snapshots only for serialization |
| **Assertion-free tests** | Test runs code but has no `expect`/`assert` | Every test needs at least one meaningful assertion |
| **Copy-paste tests** | Same test structure with one changed value | Use parameterized tests or property-based testing |

---

## Cross-Model Review Prompt Template

Resolve the command from repository or provider configuration. It must use a model from a different provider or model family than the implementation/review model. Do not substitute the same model or model family. Record the selected command and model in the verification receipt. If an independent model is unavailable, report the capability gap and do not clear the gate.

```text
[configured approved cross-model review command] \
  "You are reviewing [PROJECT] for gaps. Previous rounds found and fixed [N] issues.
   Find anything MISSED. Focus on:
   1. Logical contradictions between files
   2. Missing guard rails (infinite loops, no timeout, no fallback)
   3. Threshold drift (hardcoded numbers that disagree)
   4. Pipeline breaks (output format doesn't match expected input)
   5. Prompt quality (vague instructions, missing constraints)
   6. Security gaps (unvalidated input, missing auth checks)
   7. Test coverage holes (untested error paths, missing edge cases)

   [Include key file contents or context]

   Output as markdown with CRITICAL/WARNING/INFO severity."
```

---

## PR Review Workflow (Greptile)

1. List open PRs: `mcp__greptile__list_pull_requests`
2. Get PR details with review: `mcp__greptile__get_merge_request`
3. View review comments: `mcp__greptile__list_merge_request_comments`
4. Trigger new code review: `mcp__greptile__trigger_code_review`
5. After review: verify suggestions applied, run Quality Gate Workflow, approve or request changes
