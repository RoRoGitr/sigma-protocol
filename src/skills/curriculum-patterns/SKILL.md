---
name: curriculum-patterns
description: 'Use when designing, restructuring, auditing, or recording course modules — including module placement, prerequisite chains, slide audits, lesson dependency analysis, recording setup, and cross-source consistency checks. Triggers on: curriculum, module, lesson, prerequisite, slide audit, recording, M0/M1/M1.5/M2/M3/M4, academy, course design.'
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# Curriculum Patterns

## When to Use

Use when placing new lessons, auditing module boundaries, restructuring a course, setting up a recording session, or verifying that multiple data sources agree on curriculum state. Applies to LP Academy and any future courses built on this methodology.

## Core Methodology

Lesson placement follows dependency chains, not topic affinity. A lesson belongs in the module that first satisfies all its prerequisites — regardless of subject matter. Topic grouping is a secondary concern.

Module structure should be audited against a canonical multi-source checklist before recording begins. Each source that disagrees represents a production error that compounds downstream through bundle → export → dashboard → student.

## Key Patterns

### Module Placement Prerequisite Rule

1. List all concepts the lesson requires the student to already understand.
2. Identify which module introduces the last prerequisite.
3. Place the lesson in that module or later — never earlier.
4. Topic affinity (e.g., "this is about AI tools") is secondary to dependency ordering.

Three placement options when a lesson doesn't fit clearly:

| Option | Criteria |
|--------|----------|
| A | Place in the prerequisite-satisfying module |
| B | Place as capstone of adjacent module |
| C | Extract as free YouTube lead magnet (viral potential > paywall value) |

### 6-Source Consistency (LP Academy Standard)

All six sources must agree before any curriculum change ships:

| # | Source | Controls |
|---|--------|----------|
| 1 | T7 `CURRICULUM.md` | Canonical lesson list and ordering |
| 2 | T7 `RECORDING-TRACKER.md` | Recording status per lesson |
| 3 | LP-Web `data.ts` `CORE_MODULES` | Frontend module/lesson definitions |
| 4 | LP-Web `data.ts` array `.length` | Implicit count from spread operators |
| 5 | Convex `queries.ts` `ALL_MODULES` | Backend module metadata served to UI |
| 6 | Convex `seed.ts` filtered count | Actual lesson records seeded to database |

Source disagreement = corrupt curriculum state. Run the 6-source consistency check before every sprint that touches lesson order or slugs.

### Slide Audit Methodology

Before recording any module, audit slides for:
- Sequential logic (does each slide build on the previous?)
- Prerequisite accuracy (does slide content assume knowledge not yet taught?)
- M1/prior-module overlap detection (deduplication, not repetition)
- Recording readiness (any blocking format decisions?)

M2 audit outcome: approved as-is with minor callouts. M3 required 4 structural changes before recording (missing bridge slide, skill/multi-agent overlap with M1 102, 3-5 workers rule repeated 3x, missing anti-patterns segment).

### Per-Module Sequential Numbering

Use per-module sequential numbering (1, 2, 3...), not global cross-module numbering. Videos sort correctly within each folder independently. A lesson's number is meaningful only within its module.

### Recording Session Setup

- Set Borumi working directory via "Save As" at the start of each session — it remembers the last directory and defaults to it silently.
- No Gamma deck for install/setup videos — screen share only. Decks add no instructional value when the demo IS the lesson.
- Lesson format per M4 standard: video + PromptCodeBlock (in-page, not PDF) + command signature + before/after project state + exercise + Gamma deck PDF.

## Gotchas

- Moving a lesson requires synchronized updates across 12 locations in LP-Web (data.ts, seed.ts, queries.ts, migrations.ts, 3 test files, 2 VIDEO-ORDER.md, RECORDING-TRACKER.md, 2 GAMMA-DECK-URLS.md, T7 physical media). Missing any one creates drift that compounds.
- T7 SSD blocks `rm -rf` via safety gate. Use `trash` for deletions on T7.
- T7 is exFAT — `sed` redirects are unreliable. Use Python `pathlib` for batch file operations on T7.
- `zsh` lacks `declare -A`. Use Python for any batch rename or associative array operations on T7.
- Borumi remembers last working directory. Wrong directory at record time propagates error through entire pipeline.
- M1.5 free slugs must update in TWO places: `pricing-config.ts` (position-based) and `middleware.ts` (explicit slug set). Missing one creates a silent access bypass.
- PRD arithmetic errors propagate: agent briefs should include the derivation, not just the final count.

## File Locations / Conventions

```
LP-Web:
  app/data/data.ts                   — CORE_MODULES, lesson arrays
  app/lib/pricing-config.ts          — MODULE_TIER_MAP, MODULE_LESSON_COUNTS, free slug gates
  middleware.ts                      — SLUG_TO_MODULE_CODE route mapping
  convex/content/seed.ts             — LESSONS_SEED, MODULES_SEED
  convex/content/queries.ts          — ALL_MODULES
  convex/content/migrations.ts       — forward-only migration functions

T7 SSD (operator-local — not required for Sigma installs):
  Maintain slide decks and course media in your own storage; paths are project-specific.
  CURRICULUM.md                      — canonical lesson list
  RECORDING-TRACKER.md               — recording status per lesson
  GAMMA-DECK-URLS.md (per module)    — slide deck URLs
```

Module naming: `m0`, `m1`, `m1-5`, `m2`, `m3`, `m4` etc. When course media lives outside the repo, audit file contents after directory renames — do not hardcode personal drive paths in open-source artifacts.

## Quality Gates

- [ ] All 6 sources agree on lesson count per module
- [ ] No lesson references concepts from a later module
- [ ] Slide audit completed for target module before recording begins
- [ ] Borumi working directory set via "Save As" before first recording
- [ ] `pricing-config.ts` and `middleware.ts` updated together when slugs change
- [ ] T7 folder contents audited after any directory rename

## Related

- Vault articles: `curriculum-module-restructuring.md`, `module-placement-prerequisite-rule.md`, `m2-m3-slide-audit.md`
- Related skills: `migration-patterns` (for Convex lesson migrations), `sprint-patterns` (for curriculum reconciliation sprints)
