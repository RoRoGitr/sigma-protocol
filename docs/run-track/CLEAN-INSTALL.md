# Run Track — Clean Install Policy

**What ships in git:** framework only (commands, steps, skills, research canon, empty output READMEs).

**What never ships:** your filled playbooks, gap reports, or project-specific config.

---

## Tracked (framework)

| Path | Purpose |
|------|---------|
| `steps/run-*`, `commands/run-*.md` | All 64 step commands + 8 orchestrators |
| `.agents/skills/run-*` | Skill adapters |
| `docs/run-track/RESEARCH-*.md` | Methodology research (not operator notes) |
| `docs/run-track/RUN-TRACK-*.md` | Roadmap, acceptance, this file |
| `docs/run-track/*/README.md` | Empty output directory shells |
| `docs/run-track/BUSINESS-MODEL.example.json` | Copy → `BUSINESS-MODEL.json` locally |
| `.sigma/backlogs/*/prd.json.example` | Copy → `prd.json` per department |

---

## Gitignored (per-project / operator)

| Path | Why |
|------|-----|
| `docs/run-track/**/M*.md`, `S*.md`, `C*.md`, … | **Your** step outputs |
| `docs/run-track/BUSINESS-MODEL.json` | Your SaaS/B2B/creator module choice |
| `docs/run-track/GAP-ANALYSIS*.md` | Internal QA reports |
| `docs/specs/MASTER_PRD.md` | **Your** product PRD (Build Track) |
| `.sigma/backlogs/*/prd.json` | **Your** Run Track task backlogs |
| `docs/analysis/` | All gap/devil's advocate reports |

After clone:

```bash
cp docs/run-track/BUSINESS-MODEL.example.json docs/run-track/BUSINESS-MODEL.json
for d in marketing sales content growth community ops finance legal; do
  cp .sigma/backlogs/marketing/prd.json.example ".sigma/backlogs/$d/prd.json"
done
```

Then run `/run-marketing` on **your product repo**, not sigma-protocol meta artifacts.
