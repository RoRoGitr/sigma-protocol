# Run Track v1 — Acceptance Criteria

**Version:** 1.0.0  
**Gate command:** `node scripts/verify-run-track.mjs` (must exit 0)

---

## Scaffolding (must all pass before growth ops continues)

| ID | Requirement | Evidence |
|----|-------------|----------|
| A01 | 20 Run step sources | `steps/run-m-*`, `steps/run-s-*` |
| A02 | 2 orchestrators | `run-marketing`, `run-sales` |
| A03 | Command mirrors | `commands/*.md` |
| A04 | Skill mirrors | `.agents/skills/run-*` (OSS single surface; no `.claude/skills` tree in repo) |
| A05 | Atom skills | `gtm-stack-setup`, `crm-pipeline-setup` |
| A06 | M/S PRD schema | `schemas/sigma-run-prd.schema.json` |
| A07 | Backlogs shell | `.sigma/backlogs/{marketing,sales}/prd.json` valid JSON (items may be empty) |
| A08 | Run config | `.sigma/run-track.json` |
| A09 | Research pack | 6 docs under `docs/run-track/` |
| A10 | Registry wired | `.claude/lib/agent-skill-registry.json` run steps |
| A11 | Sync script | `scripts/sync-steps-to-platforms.sh` → `commands/` |
| A12 | SigmaHQ sync | `scripts/sigmahq-sync-run-track.py --dry-run` |
| A13 | Run registry valid | `node scripts/verify-run-track.mjs` (Run Track scope) |
| A14 | MASTER_PRD | `docs/specs/MASTER_PRD.md` |
| A15 | Output dirs | `docs/run-track/{marketing,sales}/README.md` (sample M1–M3 artifacts optional) |
| A16 | Sales output dir | `docs/run-track/sales/README.md` |

**Gap score target:** 100% — zero open requirements on this list.
