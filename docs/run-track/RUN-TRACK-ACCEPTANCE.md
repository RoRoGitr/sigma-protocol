# Run Track Acceptance Criteria

**Version:** 2.0.0  
**Updated:** 2026-06-29  
**Supersedes:** [RUN-TRACK-V1-ACCEPTANCE.md](./RUN-TRACK-V1-ACCEPTANCE.md) (v1 rows retained below for history)

**External gate:** `node scripts/verify-run-track.mjs --wave=N` — exit 0 required before starting wave N+1.

---

## Global criteria (all waves)

| ID | Criterion | Evidence |
|----|-----------|----------|
| G1 | Manifest is single source of truth | `scripts/run_track_manifest.py` |
| G2 | Generator is idempotent | `python3 scripts/generate-run-track-steps.py` |
| G3 | Commands synced | `steps/run-*` → `commands/run-*.md` via `sync-steps-to-platforms.sh` |
| G4 | Registry patched | `.claude/lib/agent-skill-registry.json` |
| G5 | Schema covers all depts | `schemas/sigma-run-prd.schema.json` |
| G6 | Backlog shell per dept | `.sigma/backlogs/{dept}/prd.json.example` (+ local `prd.json`) |
| G7 | SigmaHQ sync fail-open | `sigmahq-sync-run-track.py --dept all --dry-run` |
| G8 | Sixth-grade output template | `templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md` |

---

## Wave 1 — Marketing + Sales (18 steps, 2 orchestrators)

| ID | Criterion | Pass when |
|----|-----------|-----------|
| W1-1 | M1–M10 step files | All slugs in `steps/` + `commands/` |
| W1-2 | S1–S8 step files | Same |
| W1-3 | Orchestrators | `run-marketing`, `run-sales` |
| W1-4 | Atom skills | `gtm-stack-setup`, `crm-pipeline-setup` |
| W1-5 | Research | Marketing + Sales onboarding docs |
| W1-6 | Verify | `--wave=1` exit 0 |

**Note:** Sample project artifacts (e.g. filled M1–M3 in sigma-protocol meta repo) are **not** framework requirements.

---

## Wave 2 — Content + Growth (34 cumulative steps, 4 orchestrators)

| ID | Criterion | Pass when |
|----|-----------|-----------|
| W2-1 | C1–C8 | Content spine per roadmap |
| W2-2 | G1–G8 | Growth spine per roadmap |
| W2-3 | Orchestrators | `run-content`, `run-growth` |
| W2-4 | Atom skills | `content-production-queue`, `funnel-instrumentation-setup`, `ab-test-spec` |
| W2-5 | Triggers | `content_after_step`, `growth_after_step` in `.sigma/run-track.json` |
| W2-6 | Research | Content team + Growth ops onboarding docs |
| W2-7 | M9/M10 boundary | M9 = cadence only; G3–G5 own CRO execution |
| W2-8 | Verify | `--wave=2` exit 0 |

---

## Wave 3 — Community + Ops (48 cumulative steps, 6 orchestrators through wave 3; 8 at wave 4)

| ID | Criterion | Pass when |
|----|-----------|-----------|
| W3-1 | Co1–Co6 | Community spine |
| W3-2 | O1–O8 | Ops spine (coordinates `@dev-loop`, does not replace) |
| W3-3 | Orchestrators | `run-community`, `run-ops` |
| W3-4 | Triggers | `community_after_step`, `ops_after_step` |
| W3-5 | Research | Community manager + Startup COO docs |
| W3-6 | Verify | `--wave=3` exit 0 |

---

## Wave 4 — Finance + Legal (64 cumulative steps, 8 orchestrators)

| ID | Criterion | Pass when |
|----|-----------|-----------|
| W4-1 | Fn1–Fn7 | Finance spine (Fn prefix, never F) |
| W4-2 | L0–L8 | Legal spine (L0 = entity formation / LLC·S-Corp checklist) |
| W4-3 | Orchestrators | `run-finance`, `run-legal` |
| W4-4 | Atom skill | `entity-formation-setup` for L0 |
| W4-5 | Triggers | `finance_after_step`, `legal_after_step` |
| W4-6 | Research | CFO + GC ops docs |
| W4-7 | Post-15 guide | `docs/AFTER-STEP-15.md` lists all 8 orchestrators |
| W4-8 | Dept docs | `docs/DEPARTMENTS.md`, `docs/COMMANDS.md`, `HOW-TO-USE.md` |
| W4-9 | Clean install | `CLEAN-INSTALL.md`; sample artifacts gitignored |
| W4-10 | Verify | `--wave=4` exit 0 |

---

## Gap analysis integration

Run `@gap-analysis` after each wave verify. Target: **100%** on wave-scoped rows above. Loop:

```bash
node scripts/verify-run-track.mjs --wave=N
# fix failures
node scripts/verify-run-track.mjs --wave=N  # repeat until exit 0
```

Do not start wave N+1 research until wave N verify exits 0.
