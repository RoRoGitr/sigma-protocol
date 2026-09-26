# Agent Capability Matrix

Complete inventory of all Sigma Protocol agents with their capabilities, roles, and constraints.
**Generated from `.claude/agents/` frontmatter — regenerate after roster changes rather than hand-editing.**

**Total agents:** 61 (across 13 departments)

---

## Quick Stats

| Department | Agents | Can Spawn Sub-Agents |
|------------|--------|----------------------|
| Community | 7 | 1 |
| Design | 3 | 0 |
| Engineering | 10 | 0 |
| Finance | 4 | 0 |
| Legal | 7 | 0 |
| Marketing | 7 | 0 |
| Ops | 1 | 0 |
| Product | 3 | 0 |
| Qa | 4 | 0 |
| Sales | 5 | 0 |
| Security | 6 | 1 |
| (root) | 1 | 0 |
| Trading | 3 | 0 |
| **Total** | **61** | **2** |

---

## Full Agent Matrix

### Community

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `community-lead` | sonnet | 3 | Yes |
| `cs-director` | opus | 5 | — |
| `discord` | sonnet | 3 | — |
| `media-gen` | sonnet | 2 | — |
| `notebooklm` | sonnet | 3 | — |
| `research-media` | sonnet | 4 | — |
| `telegram` | sonnet | 3 | — |

### Design

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `design-director` | opus | 9 | — |
| `design-systems-architect` | sonnet | 4 | — |
| `ux-director` | sonnet | 3 | — |

### Engineering

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `backend-engineer` | sonnet | 5 | — |
| `compound-engineer` | sonnet | 4 | — |
| `devops` | sonnet | 4 | — |
| `dream-engineer` | opus | 3 | — |
| `frontend-engineer` | sonnet | 6 | — |
| `harness-architect` | opus | 4 | — |
| `lead-architect` | opus | 5 | — |
| `mobile-developer` | sonnet | 11 | — |
| `observability-engineer` | sonnet | 5 | — |
| `x402-engineer` | opus | 3 | — |

### Finance

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `due-diligence-analyst` | opus | 2 | — |
| `finance-director` | opus | 3 | — |
| `pricing-strategist` | opus | 3 | — |
| `unit-economics-analyst` | opus | 2 | — |

### Legal

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `donna-paulsen` | opus | 0 | — |
| `general-counsel` | opus | 4 | — |
| `harvey-specter` | opus | 0 | — |
| `jessica-pearson` | opus | 0 | — |
| `louis-litt` | opus | 0 | — |
| `mike-ross` | opus | 0 | — |
| `rachel-zane` | opus | 0 | — |

### Marketing

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `cmo` | opus | 8 | — |
| `content-director` | sonnet | 8 | — |
| `copywriter` | opus | 3 | — |
| `growth-engineer` | sonnet | 10 | — |
| `landing-page-specialist` | opus | 3 | — |
| `manychat` | sonnet | 5 | — |
| `paid-media-director` | opus | 2 | — |

### Ops

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `ops-director` | opus | 11 | — |

### Product

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `cpo` | opus | 6 | — |
| `product-owner` | sonnet | 3 | — |
| `venture-studio-partner` | sonnet | 3 | — |

### Qa

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `devils-advocate` | opus | 2 | — |
| `knowledge-distiller` | sonnet | 3 | — |
| `qa-engineer` | opus | 6 | — |
| `verification-loop` | sonnet | 3 | — |

### Sales

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `cso` | opus | 5 | — |
| `discovery-specialist` | opus | 2 | — |
| `follow-up-systemizer` | opus | 2 | — |
| `negotiation-specialist` | opus | 2 | — |
| `outbound-systems-architect` | opus | 2 | — |

### Security

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `security-ai-safety` | opus | 0 | — |
| `security-compliance` | opus | 0 | — |
| `security-infra` | opus | 0 | — |
| `security-lead` | opus | 0 | Yes |
| `security-mobile` | opus | 0 | — |
| `security-web-api` | opus | 0 | — |

### (root)

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `sigma-step-judge` | opus | 2 | — |

### Trading

| Agent | Model | Skills | Can Spawn |
|-------|-------|--------|-----------|
| `chief-trading-officer` | opus | 3 | — |
| `market-data-engineer` | opus | 2 | — |
| `quant-strategist` | opus | 3 | — |

---

## Model Distribution

| Model | Agents |
|-------|--------|
| opus | 40 |
| sonnet | 21 |

---

## Coordinators (Can Spawn Sub-Agents)

- `community-lead` (community)
- `security-lead` (security)

All other agents are leaf workers — they execute and report; they do not spawn.

---

## How to Use This Matrix

- **Dispatching work?** Pick the department first (see [DEPARTMENTS.md](DEPARTMENTS.md)), then the specialist whose description matches the task. The registry (`.claude/lib/agent-skill-registry.json`) holds each agent's triggers and skill bindings.
- **Adding an agent?** Copy `AGENT-TEMPLATE.md`, place it under `.claude/agents/<department>/`, register it in the registry, then run `node scripts/validate-cascade.mjs`.
- **Details per agent** — open its file; the frontmatter lists tools, model, and skills, and the body is the persona definition.
