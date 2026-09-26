# Run Track — Growth Operations

Run Track scaffolds **how to market, sell, and operate while you build**. It runs in parallel with Build Track (Steps 0–15).

| Track | Command entry | PRD prefix | Backlog |
|-------|---------------|------------|---------|
| Marketing | `/run-marketing` | `M01.xxx` | `.sigma/backlogs/marketing/prd.json` |
| Sales | `/run-sales` | `S01.xxx` | `.sigma/backlogs/sales/prd.json` |
| Content | `/run-content` | `C01.xxx` | `.sigma/backlogs/content/prd.json` |
| Growth | `/run-growth` | `G01.xxx` | `.sigma/backlogs/growth/prd.json` |
| Community | `/run-community` | `Co01.xxx` | `.sigma/backlogs/community/prd.json` |
| Ops | `/run-ops` | `O01.xxx` | `.sigma/backlogs/ops/prd.json` |
| Finance | `/run-finance` | `Fn01.xxx` | `.sigma/backlogs/finance/prd.json` |
| Legal | `/run-legal` | `L00.xxx` | `.sigma/backlogs/legal/prd.json` |

**Total:** 64 numbered steps + 8 orchestrators. See [HOW-TO-USE.md](./HOW-TO-USE.md) and [RUN-TRACK-ROADMAP.md](./RUN-TRACK-ROADMAP.md).

**Clean install:** [CLEAN-INSTALL.md](./CLEAN-INSTALL.md) — framework only; your outputs stay local/gitignored.

## When to start

Configured in `.sigma/run-track.json`:

| Orchestrator | Default trigger |
|--------------|-----------------|
| `/run-marketing` | After Step 11 or Step 1 |
| `/run-sales` | After M2 or Step 1.5 |
| `/run-content` | After M6 |
| `/run-growth` | After M3 |
| `/run-community` | After M2 or M8 |
| `/run-ops` | After Step 11 or first `@dev-loop` |
| `/run-finance` | After Step 1.5 |
| `/run-legal` | After Step 1 |

## Research basis

| Doc | Purpose |
|-----|---------|
| [RESEARCH-MARKETING-AGENCY-ONBOARDING.md](./RESEARCH-MARKETING-AGENCY-ONBOARDING.md) | Agency process → M1–M10 |
| [RESEARCH-SALES-TEAM-ONBOARDING.md](./RESEARCH-SALES-TEAM-ONBOARDING.md) | SDR/AE onboarding → S1–S8 |
| [RESEARCH-CONTENT-TEAM-ONBOARDING.md](./RESEARCH-CONTENT-TEAM-ONBOARDING.md) | Content ops → C1–C8 |
| [RESEARCH-GROWTH-OPS-ONBOARDING.md](./RESEARCH-GROWTH-OPS-ONBOARDING.md) | Growth team → G1–G8 |
| [RESEARCH-COMMUNITY-MANAGER-ONBOARDING.md](./RESEARCH-COMMUNITY-MANAGER-ONBOARDING.md) | Community → Co1–Co6 |
| [RESEARCH-STARTUP-COO-OPS.md](./RESEARCH-STARTUP-COO-OPS.md) | COO ops → O1–O8 |
| [RESEARCH-STARTUP-CFO-FINANCE-OPS.md](./RESEARCH-STARTUP-CFO-FINANCE-OPS.md) | CFO ops → Fn1–Fn7 |
| [RESEARCH-STARTUP-GC-LEGAL-OPS.md](./RESEARCH-STARTUP-GC-LEGAL-OPS.md) | GC ops → L0–L8 |
| [TOOL-STACK-MATRIX.md](./TOOL-STACK-MATRIX.md) | Tool tiers + MCP/skill bindings |
| [SKILL-GAP-ANALYSIS.md](./SKILL-GAP-ANALYSIS.md) | Keep / trim / add for skills |
| [BUSINESS-MODEL-MODULES.md](./BUSINESS-MODEL-MODULES.md) | SaaS / B2B / service / creator add-ons |
| [RESEARCH-ENTITY-FORMATION.md](./RESEARCH-ENTITY-FORMATION.md) | LLC/S-Corp/C-Corp → L0 |
| [HOW-TO-USE.md](./HOW-TO-USE.md) | `@continue --source=run-track` walkthrough |

## Acceptance

External gate: `node scripts/verify-run-track.mjs --wave=4`  
Criteria: [RUN-TRACK-ACCEPTANCE.md](./RUN-TRACK-ACCEPTANCE.md)  
Verify: `node scripts/verify-run-track.mjs --wave=4 --deep`

## Output standard

Every Run Track artifact uses [RUN-TRACK-OUTPUT-TEMPLATE.md](../../templates/run-track/RUN-TRACK-OUTPUT-TEMPLATE.md) — sixth-grade readable, founder tasks capped at 3 per day.

## After Build Track (Steps 0–15)

See **[AFTER-STEP-15.md](../AFTER-STEP-15.md)** — what to run next: Run Track, `@dev-loop`, `@gap-analysis`, ship.
