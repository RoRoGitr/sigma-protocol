## Step Boundary

Step 12 OWNS:
- `AGENTS.md` Step 12 managed sections (methodology + project constraints + design artifacts)
- `.sigma/memory/` minimum bridge files (`project/`, `local/`, `agents/`)

Step 12 IMPORTS from Steps 0–11:
- MASTER_PRD, architecture, design system, technical spec, feature breakdown, PRD status, stack-profile

Step 12 does NOT OWN:
- `.sigma/tools/`, `.sigma/runtime/` (Step 14)
- Deep `.sigma/memory/` taxonomy beyond bridge files (Step 14)
- `src/skills/`, `src/agents/` (Step 13)
- Platform-specific mirror directories

---

## Phase A — Context Import & Surface Detection

### Upstream Requirements

| Artifact | Source Step | Required |
|----------|-----------|----------|
| `docs/specs/MASTER_PRD.md` | Step 1 | **Yes** |
| `docs/architecture/ARCHITECTURE.md` | Step 2 | **Yes** |
| `docs/design/DESIGN-SYSTEM.md` | Step 6 | **Yes** |
| `docs/technical/TECHNICAL-SPEC.md` | Step 8 | **Yes** |
| `docs/implementation/FEATURE-BREAKDOWN.md` | Step 10 | **Yes** |
| `docs/prds/F*-*.md` or `.prd-status.json` | Step 11 | **Yes** |

**Fallback:** If MASTER_PRD, ARCHITECTURE, or TECHNICAL-SPEC are missing, halt: "Step 12 requires upstream artifacts from Steps 1–11."

Read if present:
- `AGENTS.md`, `CLAUDE.md` (when present), `docs/stack-profile.json`, `docs/specs/constitution.md`
- `docs/specs/OFFER_ARCHITECTURE.md`, `docs/states/STATE-SPEC.md`
- `src/skills/`, `src/agents/`, `commands/` (rendered steps)
- `.sigma/runtime-baseline.json`

Absorb useful content from legacy `.sigma/rules/` if it exists — then retire or mark deprecated. Do **not** treat `.claude/`, `.codex/`, `.cursor/` as required outputs.

For every target runtime, probe instruction loading at the repository root and from a nested directory. Record the loaded/unloaded result, scope and precedence rule, command or UI evidence, and any unsupported import explicitly. Do not claim that one instruction file imports another unless the probe proves it.

<HARD-GATE>
Do NOT proceed to Phase B until user approves context scope.
Use AskUserQuestion: "Context imported. Approve AGENTS.md synthesis scope?"
Options: [Approve — plan AGENTS.md sections, Revise scope, Skip optional artifacts]
</HARD-GATE>

---

## Phase B — AGENTS.md Section Plan

**Goal:** Plan what goes into `AGENTS.md` before writing.

### Required sections (when upstream artifacts exist)

| Section | Source | Purpose |
|---------|--------|---------|
| Project identity | Step 1 MASTER_PRD | Name, outcome, constraints |
| Active workflow | Sigma canon | Steps 0–15 + backlog paths |
| Stack profile | Step 0/2/8 | Framework, component libraries, integrations |
| Project constraints | `constitution.md` | Immutable principles (verbatim) |
| Design artifacts | Steps 5/9 | Visual source-of-truth paths |
| Skill invocation | Step 13 preview | `src/skills/` + SKILLS-INVOKE convention |
| Memory bridge | Step 12 | `.sigma/memory/` + optional shared layer |
| Session resume | Step 12 | 3 constraints + sprint state path + cold-start file |

For each planned instruction, record its owner, scope, source or recorded operator decision, freshness status, destination, and whether it is a source fact or an inference. Surface contradictions and unknowns before synthesis; only an explicit authorized decision may promote an inference to policy.

### DNA vs Skills separation

- **DNA (in AGENTS.md):** anti-slop, HARD-GATE, verification thresholds, coordinator-first policy
- **Skills (in `src/skills/`):** stack patterns, component libraries, framework specifics — invoke per step phase

Do NOT duplicate full skill bodies into AGENTS.md. Point to paths and invoke phases.

### Context budget

- Measure the cumulative always-on context and retrieval cost for each target runtime; do not impose a fixed per-file target
- Push depth into `src/skills/` and `docs/`
- Preserve user-authored policy outside managed blocks. Use a thin `CLAUDE.md` adapter only when the detected runtime loading probe supports that import; otherwise record the supported native surface and do not duplicate the AGENTS body.
- Include compaction-survival "Session Resume" section

<HARD-GATE>
Do NOT proceed to Phase C until user approves the section plan.
Use AskUserQuestion: "AGENTS.md section plan ready. Approve synthesis?"
Options: [Approve — write AGENTS.md, Revise sections, Show DNA vs Skills split]
</HARD-GATE>

---

## Phase C — Project Context Synthesis

**Goal:** Write or update `AGENTS.md` with the planned sections. Regenerate only Step 12–managed blocks (clearly labeled comments or headers).

When a detected runtime loading probe supports it, create or update only the thin native `CLAUDE.md` adapter needed to import `@AGENTS.md`. Preserve operator-owned content and do not turn it into a second instruction source. If the probe does not support it, preserve the file and record the loaded native surface instead.

### Constitution (when `docs/specs/constitution.md` exists)

Copy principles **verbatim** under `## Project Constraints (from constitution.md v{VERSION})`. No summarizing.

### Design artifacts (when Step 5 or 9 outputs exist)

Emit the detected visual source-of-truth paths and their tool receipts. HTML/native artifacts are portable defaults; Pen, Taste, Designscape, or another renderer are optional adapters only when their local capability probe and owner source are recorded.

Skip section when none exist.

### Stack + component libraries

Reference locked choices from `docs/stack-profile.json` and `docs/references/CURATED-COMPONENT-LIBRARIES.md`. List which methodology skills to invoke (`shadcn`, `rn-component-library`, `agentic-ui`, `companion-system`, etc.).

<HARD-GATE>
Do NOT proceed to Phase D until user approves AGENTS.md synthesis.
Use AskUserQuestion: "AGENTS.md updated. Approve memory bridge wiring?"
Options: [Approve — create memory bridge, Revise AGENTS.md, Add missing section]
</HARD-GATE>

---

## Phase D — Memory Bridge + Linear Wiring

**Goal:** Create `.sigma/memory/` bridge and optional Linear milestone.

### Memory bridge (always)

Create or update:
- `.sigma/memory/project/README.md` — project name, synthesized steps, decisions, conventions, pointer to shared memory layer or "none", and source/authorization/retention/redaction/rollback metadata for each write
- `.sigma/memory/local/.gitkeep`
- `.sigma/memory/agents/README.md` — agent memory purpose; Step 14 may expand

Read `runtime-baseline.json -> memory_layer`. If `configured: false`, `.sigma/memory/` is the source of truth — valid pass.

Keep bridge files within the measured context budget. Tag entries: semantic / episodic / procedural, and preserve existing user entries unless an authorized migration explicitly changes them.

### Linear (when configured — Linear replaced the SigmaHQ kanban 2026-07-11)

If `linear.configured: true` (LINEAR_API_KEY in Keychain + `linear.project` in runtime-baseline.json):
1. Verify Step 11 engineering issues (label `eng-task`) exist in `linear.project`
2. Record the repo → `linear.project` mapping in AGENTS.md so every runtime knows where task state lives (GitHub always owns the PR/branch/review/merge loop; the tracker board is Linear here)
3. Create a Step 12 completion milestone issue — labels `milestone`, `step-12`, `wave:W0` (wave labels are MANDATORY)

If not configured, use wave-labeled GitHub Issues as the task board (or file artifacts for offline tracking) — record the repo's board choice in AGENTS.md the same way. Never the retired SigmaHQ kanban.

<HARD-GATE>
Do NOT proceed to Phase E until user approves memory bridge.
Use AskUserQuestion: "Memory bridge complete. Run verification?"
Options: [Approve — verify and hand off, Revise memory bridge, Adjust Linear wiring]
</HARD-GATE>

---

## Phase E — Verification & Handoff

### Required verification
- `AGENTS.md` contains labeled Step 12 sections and a measured cumulative-context report
- root and nested runtime probes show which instruction surfaces load, their scope/precedence, and unresolved imports
- `CLAUDE.md`, when a detected runtime probe supports the adapter, is thin and does not duplicate the managed instruction body
- `.sigma/memory/project/README.md`, `local/.gitkeep`, `agents/README.md` exist
- Constitution and design-artifact sections present when upstream artifacts exist
- No requirement for `.claude/`, `.codex/`, or platform mirror directories
- Step 13/14 handoff paths documented in AGENTS.md
- generated rules distinguish source facts, recorded operator decisions, inferences, and unknowns; contradictions are reported rather than silently resolved

### Mandatory: Run $holes

Fix gaps before final gate.

### Downstream handoff

| Artifact | Consumed By | Purpose |
|----------|-------------|---------|
| `AGENTS.md` | Step 13, 14 | Project brain |
| `.sigma/memory/project/README.md` | Step 14 | Memory scaffold expansion |
| `.sigma/memory/agents/README.md` | Step 14 | Agent memory subfolders |

<HARD-GATE>
FINAL GATE — Do NOT proceed to Step 13 without explicit approval.
Use AskUserQuestion: "Step 12 complete. Ready for Step 13 — Skillpack Generator?"
Options: [Proceed to Step 13, Revise AGENTS.md, Review memory bridge]
</HARD-GATE>

---

<!-- include: _partials/step-verify-handoff.md -->

<verification>
## Step 12 Verification Schema

### Required Files (40 points)
| File | Path | Points |
|------|------|--------|
| Project brain | /AGENTS.md | 20 |
| Project memory bridge | /.sigma/memory/project/README.md | 10 |
| Agent memory bridge | /.sigma/memory/agents/README.md | 5 |
| Local memory marker | /.sigma/memory/local/.gitkeep | 5 |

### Content Quality (35 points)
| Check | Points |
|-------|--------|
| Workflow steps 0–15 documented | 8 |
| Stack + skill invoke paths documented | 8 |
| Constitution verbatim when present | 7 |
| Design artifact paths when present | 6 |
| Session resume / compaction section | 6 |

### DNA Compliance (15 points)
| Check | Points |
|-------|--------|
| DNA vs Skills separation | 5 |
| Anti-slop in outputs | 5 |
| Linear project mapping documented when configured | 5 |

### Boundary Integrity (10 points)
| Check | Points |
|-------|--------|
| No platform mirror requirements | 4 |
| Step 14 handoff explicit | 3 |
| $holes pass completed | 3 |

### Pass Threshold
95/100 minimum.
</verification>

$END$
