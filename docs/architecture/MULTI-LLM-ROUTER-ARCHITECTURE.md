# Multi-LLM Router & Council Architecture

**Working Document** — Multi-model routing, LLM council orchestration, and subscription wrapping for Sigma Protocol.
**Date:** 2026-02-15
**Author:** Sigma Architecture Team
**Status:** Draft — Architecture Decision Record + Implementation Blueprint

**Supported Platforms:** Claude Code (primary), Codex, Cursor

---

## Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Vision](#2-vision)
3. [Two Core Primitives](#3-two-core-primitives)
4. [Architecture Overview](#4-architecture-overview)
5. [Primitive 1: Skill-Level Routing](#5-primitive-1-skill-level-routing)
6. [Primitive 2: LLM Council](#6-primitive-2-llm-council)
7. [Subscription Wrapping (OAuth + API Key Dual Auth)](#7-subscription-wrapping)
8. [Configuration Schema (sigma-router.json)](#8-configuration-schema)
9. [Claude Code Teams Integration](#9-claude-code-teams-integration)
10. [Composability: /council + /swarm](#10-composability)
11. [Cost Controls & Policies](#11-cost-controls--policies)
12. [Existing Ecosystem & Prior Art](#12-existing-ecosystem--prior-art)
13. [Phased Implementation Plan](#13-phased-implementation-plan)
14. [Open Questions & Risks](#14-open-questions--risks)
15. [Context Adapter Layer](#15-context-adapter-layer)
16. [Sigma Steps Default Routing & Council Configs](#16-sigma-steps-default-routing--council-configs)
17. [Adversarial Council — Role-Specialized Prompting](#17-adversarial-council--role-specialized-prompting)
18. [Competitive Implementation](#18-competitive-implementation)
19. [Feedback Loop & Model Performance Tracking](#19-feedback-loop--model-performance-tracking)
20. [Step 0 Integration — Router as Infrastructure](#20-step-0-integration--router-as-infrastructure)
21. [The Sigma Senate — Accumulated Council Wisdom](#21-the-sigma-senate--accumulated-council-wisdom)
22. [Emergency Cascade & Graceful Degradation](#22-emergency-cascade--graceful-degradation)
23. [Cross-Project Learning & Meta-Optimization](#23-cross-project-learning--meta-optimization)
24. [References](#24-references)

---

## 1. Problem Statement

Current AI-assisted development tools bind you to a single LLM provider per session. Claude Code uses Anthropic models. Codex uses OpenAI models. Gemini CLI uses Google models. Each model has distinct strengths and weaknesses:

| Model | Strengths | Weaknesses |
|-------|-----------|------------|
| Claude Opus 4.6 | Deep reasoning, architecture, nuance | Higher latency, cost |
| Claude Sonnet 4.5 | Balanced speed/quality, great code | Less depth than Opus |
| GPT-5.3 Codex | Fast code generation, broad patterns | Different architectural style |
| Gemini 3 Pro | 2M context, multimodal, visual | Tool calling inconsistencies |
| Kimi K2.5 | Long-context, strong Chinese language | Smaller ecosystem |
| GLM-4.7 (Z.ai) | Reasoning, open-weight | Fewer integrations |
| Qwen3-Coder | Open-source, local-capable | Smaller than frontier models |

**The constraint**: No single model is best at everything. A senior frontend designer benefits from Gemini's visual reasoning. An architecture planner benefits from Opus's depth. A rapid scaffolder benefits from GPT's speed. A code reviewer benefits from seeing the same code through multiple model lenses simultaneously.

**The opportunity**: Claude Code's **teammates infrastructure** (TeamCreate, SendMessage, TaskList) already orchestrates multiple agents. If different agents could use different models, the team becomes genuinely heterogeneous — each playing to their model's strengths.

---

## 2. Vision

Build a **multi-LLM orchestration layer** within Claude Code's existing harness that enables:

1. **Skill-Level Routing** — Each skill/agent automatically uses the best model for its task
2. **LLM Council** — High-stakes decisions fan out to multiple models, then synthesize the best answer
3. **Subscription Wrapping** — Use existing paid subscriptions (ChatGPT Plus, Gemini Advanced, etc.) instead of per-token API billing
4. **Composability** — `/council` and `/swarm` work together, council for planning, swarm for execution

All of this should work within Claude Code's native teams, messaging, and task management — not as a separate tool, but as an extension of how Sigma Protocol already operates.

---

## 3. Two Core Primitives

### Routing (1-to-1)

```
Task → Router → Best Single Model → Response
```

The router maps each skill/agent/task type to the most capable model. This is transparent to the agent — it doesn't know it's hitting Gemini instead of Claude. The proxy translates API formats.

**Use case**: Routine work. Frontend skill → Gemini. Backend skill → Opus. Quick tasks → Haiku/Flash.

### Council (1-to-many)

```
Task → Fan-out to N Models → Peer Review → Chairman Synthesis → Response
```

Inspired by [llm-council](https://github.com/llm-council/llm-council) (Andrej Karpathy). The same prompt goes to multiple models simultaneously. Each produces an independent response. A chairman model synthesizes the best elements into a single, superior output.

**Use case**: High-stakes decisions. Architecture planning. Devil's advocate reviews. Security audits. PRD generation.

### Why Two Primitives

| Situation | Use Routing | Use Council |
|-----------|-------------|-------------|
| Writing a React component | Yes — route to best code model | No — overkill |
| Planning system architecture | No — single perspective insufficient | Yes — diverse perspectives needed |
| Quick bug fix | Yes — fast model | No — speed matters |
| Security review | Maybe — specialized model | Yes — different models find different vulns |
| PRD generation | No | Yes — diverse product thinking |
| Scaffolding boilerplate | Yes — fastest model | No — no ambiguity |
| Devil's advocate critique | No | Yes — different failure modes per model |

---

## 4. Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Claude Code CLI                     │
│                  (User's Terminal)                     │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │ /council    │  │ /swarm      │  │ /route       │ │
│  │ command     │  │ command     │  │ (implicit)   │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘ │
│         │                │                │          │
│  ┌──────▼────────────────▼────────────────▼───────┐ │
│  │           Sigma Orchestrator Agent              │ │
│  │     (reads sigma-router.json config)            │ │
│  └──────┬──────────┬──────────┬──────────┬────────┘ │
│         │          │          │          │           │
│  ┌──────▼───┐ ┌────▼────┐ ┌──▼─────┐ ┌──▼──────┐  │
│  │Teammate A│ │Teammate B│ │Teammate│ │Teammate │  │
│  │ Opus 4.6 │ │GPT-5.3  │ │Gemini  │ │ Kimi K2 │  │
│  └──────┬───┘ └────┬────┘ └──┬─────┘ └──┬──────┘  │
│         │          │          │          │           │
└─────────┼──────────┼──────────┼──────────┼───────────┘
          │          │          │          │
┌─────────▼──────────▼──────────▼──────────▼───────────┐
│              Sigma Router (Local Proxy)                │
│         (API format translation layer)                 │
│                                                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐ │
│  │Anthropic │ │ OpenAI   │ │ Gemini   │ │OpenRouter│ │
│  │Transform │ │Transform │ │Transform │ │Transform │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬────┘ │
└───────┼─────────────┼────────────┼────────────┼───────┘
        │             │            │            │
        ▼             ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐ ┌─────────┐  ┌─────────┐
   │Anthropic│  │ OpenAI  │ │ Google  │  │OpenRouter│
   │  API    │  │  API    │ │  API    │  │   API    │
   │ (or     │  │ (or     │ │ (or     │  │(100+     │
   │  sub)   │  │  sub)   │ │  sub)   │  │ models)  │
   └─────────┘  └─────────┘ └─────────┘  └─────────┘
        ▲             ▲            ▲
        │             │            │
   ┌─────────────────────────────────────────────────┐
   │         Subscription Wrapper (Optional)           │
   │   CLIProxyAPI / VibeProxy — OAuth token capture   │
   │   Turns $20/mo subscriptions into API endpoints   │
   └─────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility | Implementation |
|-------|---------------|----------------|
| **Commands** | User-facing `/council`, `/swarm`, `/route` | Sigma commands (`commands/`) |
| **Orchestrator** | Reads config, spawns teammates, manages council protocol | Sigma agent (.claude/agents/) |
| **Teammates** | Execute tasks, report via SendMessage | Claude Code teams (TeamCreate) |
| **Router Proxy** | Translates API formats between providers | Claude Code Router / CCProxy (local service) |
| **Subscription Wrapper** | Wraps OAuth subscriptions as API endpoints | CLIProxyAPI / VibeProxy (optional) |
| **Provider APIs** | Actual LLM inference | Anthropic, OpenAI, Google, etc. |

---

## 5. Primitive 1: Skill-Level Routing

### How It Works

1. Orchestrator receives a task (e.g., "implement the frontend for this screen")
2. Orchestrator checks `sigma-router.json` → `routing.skills["frontend-design"]` → `gemini/gemini-3-pro`
3. Spawns a teammate configured to use Gemini (via `ANTHROPIC_BASE_URL` pointing at the proxy)
4. Teammate executes normally — it doesn't know it's using Gemini. Claude Code's tools, messaging, and task management all work identically
5. Teammate reports back to orchestrator via SendMessage

### Routing Rules

Routes can be defined at multiple granularities:

```json
{
  "routing": {
    "skills": {
      "frontend-design": "gemini/gemini-3-pro",
      "architecture": "anthropic/claude-opus-4-6",
      "backend-engineering": "openai/gpt-5.3-codex",
      "scaffolding": "openai/gpt-5.3-codex",
      "code-review": "anthropic/claude-sonnet-4-6",
      "quick-tasks": "anthropic/claude-haiku-4-5"
    },
    "agents": {
      "sigma-media-gen": "gemini/gemini-3-pro-image-preview",
      "sigma-planner": "anthropic/claude-opus-4-6",
      "devils-advocate": "council:critique"
    },
    "fallback": "anthropic/claude-sonnet-4-6"
  }
}
```

### Model Capability Matching

The router should understand model capabilities to prevent misrouting:

```json
{
  "model_capabilities": {
    "anthropic/claude-opus-4-6": {
      "tool_calling": true,
      "max_context": 200000,
      "multimodal": true,
      "strengths": ["reasoning", "architecture", "nuance"],
      "cost_tier": "high"
    },
    "gemini/gemini-3-pro": {
      "tool_calling": true,
      "max_context": 2000000,
      "multimodal": true,
      "strengths": ["visual", "long-context", "multimodal"],
      "cost_tier": "medium"
    },
    "openai/gpt-5.3-codex": {
      "tool_calling": true,
      "max_context": 256000,
      "multimodal": true,
      "strengths": ["code-generation", "speed", "patterns"],
      "cost_tier": "medium"
    }
  }
}
```

---

## 6. Primitive 2: LLM Council

### The Council Protocol

Inspired by [llm-council](https://github.com/llm-council/llm-council) (Andrej Karpathy) and the research paper "Language Model Council: Democratically Benchmarking Foundation Models on Highly Subjective Tasks" (NAACL 2025).

### Three-Stage Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│                    COUNCIL PROTOCOL                            │
│                                                                │
│  Stage 1: FAN-OUT (Divergence)                                │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ Opus    │ │ GPT-5.3 │ │ Gemini  │ │ Kimi K2 │           │
│  │         │ │ Codex   │ │ 3 Pro   │ │         │           │
│  │ Plan A  │ │ Plan B  │ │ Plan C  │ │ Plan D  │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       │           │           │           │                   │
│  Stage 2: PEER REVIEW (Convergence) — Optional               │
│       │           │           │           │                   │
│       ▼           ▼           ▼           ▼                   │
│  ┌────────────────────────────────────────────┐               │
│  │ Each model reviews all others anonymously  │               │
│  │ Scores: correctness, completeness, risks   │               │
│  └─────────────────────┬──────────────────────┘               │
│                        │                                       │
│  Stage 3: SYNTHESIS (Reduction)                               │
│                        ▼                                       │
│  ┌────────────────────────────────────────────┐               │
│  │           CHAIRMAN MODEL                    │               │
│  │   Receives: all plans + all reviews         │               │
│  │   Produces: single synthesized output       │               │
│  │   (Best elements from all perspectives)     │               │
│  └────────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────┘
```

### Council Configurations

Different tasks need different council setups:

```json
{
  "councils": {
    "planning": {
      "description": "Architecture and feature planning",
      "participants": [
        "anthropic/claude-opus-4-6",
        "openai/gpt-5.3-codex",
        "gemini/gemini-2.5-pro"
      ],
      "chairman": "anthropic/claude-opus-4-6",
      "peer_review": true,
      "anonymize": true
    },
    "critique": {
      "description": "Devil's advocate multi-perspective critique",
      "participants": [
        "anthropic/claude-opus-4-6",
        "openai/gpt-5.3-codex",
        "gemini/gemini-2.5-pro",
        "moonshot/kimi-k2.5"
      ],
      "chairman": "rotate",
      "peer_review": false,
      "output_format": "union",
      "note": "No synthesis — collect all concerns as a structured list"
    },
    "code_review": {
      "description": "Multi-model code review for bug/vuln detection",
      "participants": [
        "anthropic/claude-opus-4-6",
        "openai/gpt-5.3-codex"
      ],
      "chairman": null,
      "peer_review": false,
      "output_format": "union",
      "note": "Union of all findings, deduplicated. No chairman needed."
    },
    "prd_generation": {
      "description": "Product requirements from diverse perspectives",
      "participants": [
        "anthropic/claude-opus-4-6",
        "openai/gpt-5.3-codex",
        "gemini/gemini-2.5-pro"
      ],
      "chairman": "anthropic/claude-opus-4-6",
      "peer_review": true,
      "anonymize": true
    }
  }
}
```

### Chairman Strategies

| Strategy | When to Use | Trade-off |
|----------|------------|-----------|
| **Fixed** (e.g., always Opus) | Planning, PRD synthesis | Biased toward chairman's style |
| **Rotate** | Devil's advocate, reviews | Balanced but inconsistent |
| **None (Union)** | Code review, bug detection | All findings preserved, no synthesis |
| **Vote** | Simple decisions | Democratic but slow |
| **Human** | Critical architecture decisions | Best quality, requires HITL |

### Anonymization

During peer review, model identities are hidden. Each response is labeled "Response A", "Response B", etc. This prevents:
- Self-preference bias (models ranking their own output higher)
- Brand bias (models favoring or disfavoring specific providers)
- Forces evaluation on content quality alone

---

## 7. Subscription Wrapping

### The Cost Problem

API billing adds up fast with council patterns (N models × cost per call):

| Council Type | Models | Est. Cost (API) | Est. Cost (Subscription) |
|-------------|--------|-----------------|------------------------|
| Planning (3 models + synthesis) | 4 calls | ~$0.80 | ~$0.00* |
| Critique (4 models, no synthesis) | 4 calls | ~$0.60 | ~$0.00* |
| Code Review (2 models) | 2 calls | ~$0.30 | ~$0.00* |

*Assuming existing subscription with unused capacity.

### How OAuth Wrapping Works

```
┌──────────────────────────────────────────────────────┐
│                Subscription Flow                       │
│                                                        │
│  1. User runs: cli-proxy-api --codex-login             │
│  2. Browser opens ChatGPT OAuth page                   │
│  3. User logs in with their ChatGPT Plus account       │
│  4. CLIProxyAPI captures OAuth token                   │
│  5. Token stored in ~/.cli-proxy-api/tokens/           │
│  6. Proxy exposes: http://localhost:PORT/v1/...        │
│  7. Claude Code hits local endpoint                    │
│  8. Proxy adds OAuth token, forwards to OpenAI         │
│  9. Request goes through subscription (no API billing) │
│  10. Response translated to Anthropic format           │
└──────────────────────────────────────────────────────┘
```

### Supported Subscriptions

| Subscription | Monthly Cost | What You Get | OAuth Tool |
|-------------|-------------|-------------|------------|
| ChatGPT Plus | $20/mo | GPT-5.3, GPT-5.1-Codex | CLIProxyAPI, VibeProxy |
| ChatGPT Pro | $200/mo | Unlimited GPT-5.3, o3 | CLIProxyAPI, VibeProxy |
| Gemini Advanced | $20/mo | Gemini 3 Pro, 2.5 Pro | CLIProxyAPI, VibeProxy |
| Claude Pro | $20/mo | Opus 4.6, Sonnet 4.5 | CLIProxyAPI, VibeProxy |
| Claude Max | $100-200/mo | Higher limits | CLIProxyAPI, VibeProxy |
| Z.ai | Free/Paid | GLM-4.7 | CC Mirror, API key |
| Kimi/Moonshot | Free/Paid | Kimi K2.5 | CLIProxyAPI |
| Qwen Code | Free | Qwen3-Coder | CLIProxyAPI |

### Dual Auth Configuration

Each provider in `sigma-router.json` supports both authentication methods:

```json
{
  "providers": {
    "openai": {
      "auth_methods": {
        "subscription": {
          "type": "oauth_proxy",
          "proxy": "cli-proxy-api",
          "endpoint": "http://localhost:8787",
          "login_command": "cli-proxy-api --codex-login",
          "note": "Uses ChatGPT Plus subscription, no per-token cost"
        },
        "api_key": {
          "type": "api_key",
          "key_env": "OPENAI_API_KEY",
          "endpoint": "https://api.openai.com/v1",
          "note": "Direct API, pay-per-token"
        }
      },
      "preferred_auth": "subscription",
      "fallback_auth": "api_key"
    },
    "gemini": {
      "auth_methods": {
        "subscription": {
          "type": "oauth_proxy",
          "proxy": "cli-proxy-api",
          "endpoint": "http://localhost:8788",
          "login_command": "cli-proxy-api --login --project_id $GCP_PROJECT_ID"
        },
        "api_key": {
          "type": "api_key",
          "key_env": "GEMINI_API_KEY",
          "endpoint": "https://generativelanguage.googleapis.com/v1beta"
        }
      },
      "preferred_auth": "api_key",
      "fallback_auth": "subscription"
    },
    "anthropic": {
      "auth_methods": {
        "native": {
          "type": "native",
          "note": "Claude Code's own subscription/API key. No proxy needed."
        }
      },
      "preferred_auth": "native"
    }
  }
}
```

### Multi-Account Load Balancing

CLIProxyAPI supports round-robin across multiple accounts:

```json
{
  "openai": {
    "accounts": [
      { "name": "personal-plus", "type": "subscription" },
      { "name": "work-pro", "type": "subscription" },
      { "name": "api-fallback", "type": "api_key", "key_env": "OPENAI_API_KEY" }
    ],
    "strategy": "round-robin",
    "failover": true
  }
}
```

---

## 8. Configuration Schema

### sigma-router.json (Full Schema)

```json
{
  "$schema": "https://sigma-protocol.dev/schemas/sigma-router.json",
  "version": "1.0.0",

  "providers": {
    "<provider-name>": {
      "auth_methods": {
        "subscription": { "type": "oauth_proxy", "proxy": "...", "endpoint": "..." },
        "api_key": { "type": "api_key", "key_env": "...", "endpoint": "..." }
      },
      "preferred_auth": "subscription | api_key | native",
      "fallback_auth": "subscription | api_key | null",
      "models": ["model-id-1", "model-id-2"],
      "capabilities": {
        "tool_calling": true,
        "max_context": 200000,
        "multimodal": true,
        "strengths": ["reasoning", "code"],
        "cost_tier": "low | medium | high"
      },
      "health_check": {
        "enabled": true,
        "interval_ms": 60000,
        "timeout_ms": 5000
      }
    }
  },

  "routing": {
    "skills": {
      "<skill-name>": "<provider>/<model>"
    },
    "agents": {
      "<agent-name>": "<provider>/<model> | council:<council-name>"
    },
    "task_types": {
      "default": "<provider>/<model>",
      "background": "<provider>/<model>",
      "think": "<provider>/<model>",
      "long_context": "<provider>/<model>",
      "web_search": "<provider>/<model>"
    },
    "fallback": "<provider>/<model>"
  },

  "councils": {
    "<council-name>": {
      "description": "...",
      "participants": ["<provider>/<model>", "..."],
      "chairman": "<provider>/<model> | rotate | null",
      "peer_review": true,
      "anonymize": true,
      "output_format": "synthesis | union | vote",
      "max_cost_usd": 2.00,
      "timeout_ms": 120000
    }
  },

  "policies": {
    "auto_council_threshold": {
      "description": "When to auto-trigger council instead of routing",
      "architecture_decisions": true,
      "security_reviews": true,
      "prd_generation": true,
      "plan_mode": true
    },
    "cost_controls": {
      "max_daily_spend_usd": 50.00,
      "prefer_subscription": true,
      "council_budget_per_invocation_usd": 5.00
    },
    "quality_controls": {
      "require_tool_calling": true,
      "min_context_window": 100000,
      "exclude_incompatible_models": true
    }
  }
}
```

### Config File Locations

| Platform | Config Path |
|----------|-------------|
| Claude Code | `.claude/sigma-router.json` or `~/.claude/sigma-router.json` (global) |
| Codex | `.codex/sigma-router.json` |
| Project-level | `./sigma-router.json` (overrides global) |

---

## 9. Claude Code Teams Integration

### How Council Maps to Teammates

The council protocol runs entirely within Claude Code's native teams infrastructure:

```
/council "Plan the authentication system for Golden Circle"

1. TeamCreate("council-auth-planning")

2. Spawn teammates (one per council participant):
   Task(subagent_type="general-purpose", team_name="council-auth-planning",
        name="council-opus", prompt="[council prompt]")
   → This teammate's ANTHROPIC_BASE_URL points at proxy → routes to Opus

   Task(subagent_type="general-purpose", team_name="council-auth-planning",
        name="council-gpt", prompt="[same council prompt]")
   → This teammate's ANTHROPIC_BASE_URL points at proxy → routes to GPT-5.3

   Task(subagent_type="general-purpose", team_name="council-auth-planning",
        name="council-gemini", prompt="[same council prompt]")
   → This teammate's ANTHROPIC_BASE_URL points at proxy → routes to Gemini

3. All three execute in parallel

4. Each reports back via SendMessage to orchestrator

5. Orchestrator spawns chairman teammate:
   Task(name="council-chairman", prompt="Synthesize these three plans: [A] [B] [C]")

6. Chairman synthesizes and reports final plan

7. TeamDelete (cleanup)
```

### Routing for Individual Teammates

The proxy needs to know which model to use for each teammate. Two approaches:

**Approach A: Named routes** — Each teammate name maps to a model in config:
```json
{
  "teammate_routes": {
    "council-opus": "anthropic/claude-opus-4-6",
    "council-gpt": "openai/gpt-5.3-codex",
    "council-gemini": "gemini/gemini-2.5-pro"
  }
}
```

**Approach B: Model header** — Teammate passes desired model in request header:
```
x-sigma-model: openai/gpt-5.3-codex
```
The proxy reads this header and routes accordingly. This is more flexible and doesn't require pre-configuration.

**Recommended: Approach B** with Approach A as fallback for skills that always use the same model.

### Swarm + Council Composition

```
/council + /swarm workflow:

Phase 1: COUNCIL-PLAN
  └─ /council "Plan feature X"
     ├─ Opus plans independently
     ├─ GPT plans independently
     ├─ Gemini plans independently
     └─ Chairman synthesizes → Final Plan

Phase 2: SWARM-IMPLEMENT
  └─ /swarm (using Final Plan)
     ├─ Frontend worker (routed to Gemini)
     ├─ Backend worker A (routed to Opus)
     ├─ Backend worker B (routed to GPT-5.3)
     └─ Test worker (routed to Sonnet)

Phase 3: COUNCIL-REVIEW
  └─ /council "Review implementation of feature X"
     ├─ Opus reviews code
     ├─ GPT reviews code
     ├─ Gemini reviews code
     └─ Union of all findings → Review Report
```

---

## 10. Composability

### Command Integration

| Command | What It Does | Model Behavior |
|---------|-------------|---------------|
| `/route` (implicit) | Routes task to best model | 1-to-1, transparent |
| `/council <prompt>` | Fans out to N models, synthesizes | 1-to-many, structured |
| `/swarm` | Parallelizes implementation across workers | Each worker routed individually |
| `/council + /swarm` | Council plans, swarm implements | Council for decisions, routing for execution |
| `/plan` (in plan mode) | Planning with council backing | Auto-councils if `plan_mode: true` in policies |

### /council Command Design

```
Usage: /council [options] <prompt>

Options:
  --config <name>     Use named council config (default: "planning")
  --models <list>     Override participants (comma-separated)
  --chairman <model>  Override chairman model
  --no-review         Skip peer review stage
  --budget <usd>      Max spend for this council
  --output <format>   synthesis | union | vote (default: synthesis)
  --dry-run           Show cost estimate without executing

Examples:
  /council "Design the auth architecture"
  /council --config critique "Review this PR for security issues"
  /council --models opus,gpt,gemini --no-review "Plan the database migration"
  /council --dry-run "Evaluate three deployment strategies"
```

### Integration with Plan Mode

When `policies.auto_council_threshold.plan_mode` is `true`:

1. User enters plan mode (or sigma-planner agent is invoked)
2. Orchestrator detects plan mode context
3. Automatically triggers council instead of single-model planning
4. Council produces synthesized plan
5. Plan presented to user for approval (HITL checkpoint preserved)
6. On approval, swarm executes using skill-level routing

---

## 11. Cost Controls & Policies

### Cost Estimation

Before any council execution, display estimated cost:

```
🏛️ Council: planning (3 participants + chairman)
   Participants: Opus 4.6, GPT-5.3, Gemini 2.5 Pro
   Chairman: Opus 4.6
   Estimated input tokens: ~8,000 × 4 = ~32,000
   Estimated cost: $0.72 (API) / $0.00 (subscription)
   Auth method: 2 via subscription, 1 via API key, 1 native

   Proceed? [Y/n]
```

### Subscription-First Policy

When `policies.cost_controls.prefer_subscription` is `true`:
1. Check if the model is available via subscription wrapper
2. If yes, use subscription (zero marginal cost)
3. If subscription is rate-limited or unavailable, fall back to API key
4. If no API key configured, skip that participant and warn

### Budget Guards

```json
{
  "cost_controls": {
    "max_daily_spend_usd": 50.00,
    "council_budget_per_invocation_usd": 5.00,
    "warn_at_pct": 80,
    "hard_stop_at_pct": 100,
    "track_file": ".sigma/spend-log.json"
  }
}
```

---

## 12. Existing Ecosystem & Prior Art

### Proxy / Router Solutions

| Project | Language | Approach | Best For |
|---------|----------|----------|----------|
| [Claude Code Router](https://github.com/musistudio/claude-code-router) | Node.js | Multi-provider routing with transformers | Skill-level routing |
| [CCProxy](https://ccproxy.orchestre.dev/) | Go | High-performance proxy with circuit breakers | Enterprise, performance-critical |
| [CC Mirror](https://github.com/numman-ali/cc-mirror) | Node.js | Isolated Claude Code instances per provider | Separate variant per model |
| [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) | Go | OAuth subscription wrapping | Subscription-based access |
| [VibeProxy](https://github.com/automazeio/vibeproxy) | Swift | macOS menu bar OAuth wrapper | Mac-native subscription wrapping |
| [LiteLLM](https://docs.litellm.ai/) | Python | Universal LLM gateway | Enterprise gateway |

### Council / Ensemble Research

| Project | Approach | Key Insight |
|---------|----------|-------------|
| [llm-council](https://github.com/llm-council/llm-council) | Fan-out → Peer Review → Synthesis | Anonymization prevents self-preference bias |
| NAACL 2025 Paper | Democratic benchmarking | Council outperforms any single judge on subjective tasks |
| [Multi-LLM Dev Framework](https://github.com/thomas-jamet/Multi-LLM-Development-Framework) | Provider-agnostic patterns | Consistent dev patterns across models |

### Native Claude Code Support

Claude Code natively supports LLM gateway configuration via:
- `ANTHROPIC_BASE_URL` — point at any proxy
- `ANTHROPIC_AUTH_TOKEN` — custom auth token
- `apiKeyHelper` — dynamic key rotation script
- LiteLLM integration documented in official docs

Reference: [Claude Code LLM Gateway Docs](https://code.claude.com/docs/en/llm-gateway)

---

## 13. Phased Implementation Plan

### Phase 1: Routing Foundation (Target: Week 1-2)

**Goal**: Any skill/agent can be routed to any model via config.

- [ ] Set up Claude Code Router as local proxy service
- [ ] Create `sigma-router.json` schema and validator
- [ ] Implement routing config reader in orchestrator agent
- [ ] Define initial skill→model mappings for Golden Circle project
- [ ] Create `/route` command (or make routing implicit via config)
- [ ] Test: Frontend agent uses Gemini, Backend agent uses Opus
- [ ] Document setup guide for new projects

**Key Files**:
```
.claude/sigma-router.json          (project config)
~/.claude/sigma-router.json        (global defaults)
commands/route.md                   (command definition)
.claude/agents/sigma-router.md     (orchestrator agent)
```

### Phase 2: Subscription Wrapping (Target: Week 2-3)

**Goal**: Use existing subscriptions instead of API keys where possible.

- [ ] Install and configure CLIProxyAPI
- [ ] Set up OAuth flows for ChatGPT, Gemini, and any other subscriptions
- [ ] Add dual-auth support (subscription + API key fallback) to sigma-router.json
- [ ] Implement auth health checks (detect rate limits, expired tokens)
- [ ] Test: Council call using 3 subscriptions, zero API spend
- [ ] Create `/sigma setup-subscriptions` wizard command

### Phase 3: Council Primitive (Target: Week 3-4)

**Goal**: `/council` command that fans out, optionally peer-reviews, and synthesizes.

- [ ] Create `/council` command definition
- [ ] Implement fan-out logic (spawn N teammates with same prompt)
- [ ] Implement response collection via SendMessage
- [ ] Implement chairman synthesis stage
- [ ] Add peer review stage (optional, anonymized)
- [ ] Add council configs (planning, critique, code_review, prd_generation)
- [ ] Test: Planning council produces better architecture plans than single model
- [ ] Add `--dry-run` for cost estimation

**Key Files**:
```
commands/council.md                 (command definition)
.claude/agents/sigma-council.md     (council orchestrator)
.claude/skills/council-protocol.md  (council skill)
```

### Phase 4: Composability (Target: Week 4-5)

**Goal**: `/council` + `/swarm` work together seamlessly.

- [ ] Integrate council with plan mode (auto-council for planning)
- [ ] Integrate council with devil's advocate agent
- [ ] Build council→swarm pipeline (council plans, swarm executes)
- [ ] Build swarm→council pipeline (swarm implements, council reviews)
- [ ] Add cost tracking and budget enforcement
- [ ] Performance benchmarks: council vs single-model quality comparison
- [ ] Create user-facing documentation and tutorials

### Phase 5: Platform Abstraction (Target: Week 5-6)

**Goal**: Works on Codex and Cursor — not just Claude Code.

- [ ] Abstract proxy config for Codex (config.toml integration)
- [ ] Platform-specific teammate spawning adapters
- [ ] Cross-platform sigma-router.json reader
- [ ] Integration tests across platforms

---

## 14. Open Questions & Risks

### Open Questions

1. **Tool call fidelity**: How well do GPT/Gemini handle Claude Code's specific tool schemas after translation? This needs empirical testing per tool.

2. **Subscription TOS**: OAuth wrapping of subscriptions may violate provider terms of service. Need to evaluate per-provider TOS and note risks.

3. **Rate limiting**: Subscription accounts have different rate limits than API. How do we handle mid-council rate limiting (one participant stalls)?

4. **Context window mismatch**: If a council prompt exceeds one participant's context window, do we truncate, summarize, or skip that participant?

5. **Chairman objectivity**: Can we measure chairman bias? Should we A/B test different chairman models to find the least biased?

6. **Determinism**: Council outputs are inherently non-deterministic (different models, different orderings). Is that a feature or a bug for reproducibility?

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Provider TOS violation (subscription wrapping) | Medium | Document TOS per provider, offer API-only mode |
| Tool call translation errors | High | Extensive testing matrix, fallback to native model |
| Council adds latency | Medium | Parallel fan-out, timeout policies, fast-mode (2 models) |
| Cost explosion from accidental council loops | High | Budget guards, max daily spend, confirmation prompts |
| Model availability (providers go down) | Medium | Health checks, circuit breakers, graceful degradation |
| Prompt leakage between providers | Low | Each teammate gets isolated context, no cross-provider state |

---

## 15. Context Adapter Layer

### The Problem: Same Context, Different Windows

A council that sends identical context to Gemini (2M tokens), Opus (200K tokens), and GPT-5.3 (256K tokens) is leaving value on the table. Each model should receive context **optimized for its window size and strengths**.

### Model-Aware Context Engineering

```
┌────────────────────────────────────────────────────────────────┐
│                    CONTEXT ADAPTER LAYER                         │
│                                                                  │
│  Source Context: Full codebase + PRDs + schema + history         │
│  (could be 500K+ tokens)                                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Gemini       │  │ Opus         │  │ GPT-5.3              │  │
│  │ Strategy:    │  │ Strategy:    │  │ Strategy:            │  │
│  │ FULL         │  │ TARGETED     │  │ MODULE + NEIGHBORS   │  │
│  │              │  │              │  │                      │  │
│  │ Send entire  │  │ Send only:   │  │ Send:                │  │
│  │ codebase,    │  │ - Target     │  │ - Target module      │  │
│  │ all PRDs,    │  │   module     │  │ - Direct imports     │  │
│  │ full schema, │  │ - Relevant   │  │ - Shared types       │  │
│  │ all history  │  │   schema     │  │ - Related PRD        │  │
│  │              │  │   tables     │  │ - Key patterns       │  │
│  │ WHY: Can see │  │ - The one    │  │                      │  │
│  │ connections  │  │   PRD that   │  │ WHY: Broad enough    │  │
│  │ across the   │  │   matters    │  │ for context, focused │  │
│  │ ENTIRE       │  │              │  │ enough for speed     │  │
│  │ project      │  │ WHY: Deeper  │  │                      │  │
│  │              │  │ reasoning on │  │                      │  │
│  │              │  │ less noise   │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### Context Strategy Configuration

```json
{
  "context_strategies": {
    "full_codebase": {
      "description": "Send everything — entire repo, all docs, full schema",
      "target_models": ["gemini/gemini-2.5-pro", "gemini/gemini-3-pro"],
      "max_tokens": 2000000,
      "includes": ["codebase", "prds", "schema", "history", "tests"]
    },
    "targeted_module": {
      "description": "Surgical context — only the relevant module and its direct dependencies",
      "target_models": ["anthropic/claude-opus-4-6", "anthropic/claude-sonnet-4-6"],
      "max_tokens": 180000,
      "includes": ["target_module", "direct_imports", "relevant_schema", "target_prd"],
      "excludes": ["tests", "unrelated_modules", "history"]
    },
    "module_plus_neighbors": {
      "description": "Target module plus neighboring modules and shared types",
      "target_models": ["openai/gpt-5.3-codex"],
      "max_tokens": 200000,
      "includes": ["target_module", "neighbor_modules", "shared_types", "related_prd", "key_patterns"]
    },
    "minimal": {
      "description": "Just the function/file in question with type signatures",
      "target_models": ["anthropic/claude-haiku-4-5"],
      "max_tokens": 50000,
      "includes": ["target_file", "type_definitions"]
    }
  }
}
```

### Why This Matters for Council Quality

Different context windows produce genuinely different insights:

| Model | Context Strategy | What It Sees That Others Don't |
|-------|-----------------|-------------------------------|
| Gemini (2M) | Full codebase | Cross-module patterns, dead code, inconsistencies between distant files |
| Opus (200K) | Targeted | Deep architectural implications of the specific module being discussed |
| GPT (256K) | Module + neighbors | Practical integration points and dependency issues |

The council synthesis then combines: holistic awareness (Gemini) + deep reasoning (Opus) + practical implementation (GPT). Each model contributes what its context strategy uniquely enables.

### Context Adapter Implementation

The adapter sits between the orchestrator and the fan-out stage:

```
Orchestrator → Context Adapter → [Model-specific context bundles] → Fan-out
```

The adapter:
1. Receives the raw task + full available context
2. Reads each participant's context strategy from config
3. Builds model-specific context bundles (file selection, summarization, prioritization)
4. Passes each bundle to the corresponding teammate

This is a **pre-processing step** — it runs once before the council, not per-turn.

---

## 16. Sigma Steps Default Routing & Council Configs

### Every Step Gets a Default Model Strategy

Each of the 13 Sigma Protocol steps has a natural affinity for either routing or council. These defaults should ship with Sigma Protocol so every project gets intelligent model allocation out of the box.

### Step-Level Routing Table

```json
{
  "steps": {
    "step-0-environment-setup": {
      "mode": "route",
      "model": "anthropic/claude-sonnet-4-6",
      "rationale": "Setup is procedural, doesn't need deep reasoning"
    },
    "step-1-ideation": {
      "mode": "council",
      "council": "planning",
      "rationale": "Diverse creative perspectives produce richer product vision"
    },
    "step-1.5-offer-architecture": {
      "mode": "council",
      "council": "planning",
      "rationale": "Pricing and offer design benefits from diverse market perspectives"
    },
    "step-2-architecture": {
      "mode": "council",
      "council": "planning",
      "rationale": "Multiple architectural philosophies compete and synthesize"
    },
    "step-3-ux-design": {
      "mode": "route",
      "model": "gemini/gemini-3-pro",
      "rationale": "Visual reasoning and spatial design is Gemini's superpower"
    },
    "step-4-flow-tree": {
      "mode": "route",
      "model": "anthropic/claude-opus-4-6",
      "rationale": "Exhaustive completeness checking requires deep analytical reasoning"
    },
    "step-5-wireframe-prototypes": {
      "mode": "route",
      "model": "gemini/gemini-3-pro",
      "rationale": "Visual/spatial reasoning for screen design and layout"
    },
    "step-6-design-system": {
      "mode": "route",
      "model": "gemini/gemini-3-pro",
      "rationale": "Color theory, typography, visual token design"
    },
    "step-7-interface-states": {
      "mode": "council",
      "council": "lite_review",
      "rationale": "Different models catch different edge states (empty, error, loading, partial)"
    },
    "step-8-technical-spec": {
      "mode": "council",
      "council": "planning",
      "rationale": "Architecture-grade technical depth needs multiple perspectives"
    },
    "step-9-landing-page": {
      "mode": "route",
      "model": "gemini/gemini-3-pro",
      "rationale": "Copywriting + visual design + conversion optimization"
    },
    "step-10-feature-breakdown": {
      "mode": "route",
      "model": "anthropic/claude-opus-4-6",
      "rationale": "Deep analytical decomposition of features into implementable units"
    },
    "step-11-prd-generation": {
      "mode": "council",
      "council": "prd_generation",
      "rationale": "Product thinking benefits from diverse viewpoints"
    },
    "step-11.5-prd-swarm": {
      "mode": "swarm",
      "routing": "per_skill",
      "rationale": "Parallel implementation — each worker uses best model for its domain"
    },
    "step-12-context-engine": {
      "mode": "route",
      "model": "anthropic/claude-opus-4-6",
      "rationale": "Meta-reasoning about context engineering requires the deepest model"
    },
    "step-13-skillpack-generator": {
      "mode": "route",
      "model": "anthropic/claude-opus-4-6",
      "rationale": "Skill definition requires understanding of protocol abstractions"
    },
    "step-verify": {
      "mode": "council",
      "council": "critique",
      "rationale": "Multi-model scoring eliminates single-model verification blindspots"
    }
  }
}
```

### Lite Council for Non-Critical Steps

Not every council needs 4 models. Define a `lite_review` council for steps that benefit from a second opinion without the full ceremony:

```json
{
  "councils": {
    "lite_review": {
      "description": "Quick 2-model sanity check",
      "participants": [
        "anthropic/claude-opus-4-6",
        "openai/gpt-5.3-codex"
      ],
      "chairman": null,
      "peer_review": false,
      "output_format": "union",
      "note": "Fast, cheap — just catch what one model misses"
    }
  }
}
```

### Override Mechanism

Users can override step defaults per-project:

```json
{
  "step_overrides": {
    "step-3-ux-design": {
      "mode": "council",
      "council": "planning",
      "rationale": "This project has complex UX requirements, council it"
    }
  }
}
```

---

## 17. Adversarial Council — Role-Specialized Prompting

### Beyond Same-Prompt Council

Standard council gives every model the **same prompt**. Adversarial council gives each model a **different role** while addressing the same problem. This produces fundamentally richer output because each model evaluates through a different lens.

### The Adversarial Pattern

```
┌──────────────────────────────────────────────────────────────────┐
│            ADVERSARIAL COUNCIL: Auth System Design                 │
│                                                                    │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────┐  │
│  │ OPUS           │  │ GPT-5.3        │  │ GEMINI             │  │
│  │ Role: Security │  │ Role: Pragmatic│  │ Role: UX           │  │
│  │ Architect      │  │ Engineer       │  │ Specialist         │  │
│  │                │  │                │  │                    │  │
│  │ "Your ONLY     │  │ "Your concern  │  │ "Your concern is   │  │
│  │ concern is     │  │ is speed,      │  │ how auth FEELS to  │  │
│  │ attack         │  │ maintainabil-  │  │ a 65-year-old.     │  │
│  │ vectors,       │  │ ity, and DX.   │  │ Password rules vs  │  │
│  │ OWASP, token   │  │ Propose the    │  │ accessibility.     │  │
│  │ theft, session │  │ simplest thing │  │ Timeout vs senior  │  │
│  │ hijacking."    │  │ that works."   │  │ cognitive load."   │  │
│  └───────┬────────┘  └───────┬────────┘  └──────────┬─────────┘  │
│          │                   │                      │             │
│          ▼                   ▼                      ▼             │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                    CHAIRMAN SYNTHESIS                        │   │
│  │  "You have three expert perspectives on auth design.         │   │
│  │   Security says X. Engineering says Y. UX says Z.            │   │
│  │   Produce ONE design that satisfies all three — or           │   │
│  │   explicitly document where you made trade-offs."            │   │
│  └────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### Adversarial Council Configuration

```json
{
  "councils": {
    "adversarial_design": {
      "description": "Role-specialized evaluation from competing perspectives",
      "type": "adversarial",
      "participants": [
        {
          "model": "anthropic/claude-opus-4-6",
          "role": "Security Architect",
          "lens": "Evaluate ONLY from security perspective: attack vectors, OWASP compliance, session management, token security, data exposure risks",
          "tone": "aggressive_critic"
        },
        {
          "model": "openai/gpt-5.3-codex",
          "role": "Pragmatic Engineer",
          "lens": "Evaluate ONLY from implementation perspective: simplicity, maintainability, developer experience, time to implement, technical debt risk",
          "tone": "practical_realist"
        },
        {
          "model": "gemini/gemini-3-pro",
          "role": "UX Specialist",
          "lens": "Evaluate ONLY from end-user perspective: accessibility for seniors, cognitive load, error recovery, session convenience, trust signals",
          "tone": "user_advocate"
        }
      ],
      "chairman": "anthropic/claude-opus-4-6",
      "chairman_instruction": "Synthesize all perspectives into ONE design. Where perspectives conflict, document the trade-off explicitly and justify your choice.",
      "peer_review": false,
      "output_format": "synthesis_with_tradeoffs"
    }
  }
}
```

### Pre-Built Adversarial Roles Library

Common role combinations that can be mixed and matched:

| Role | Lens | Best Model | Use For |
|------|------|-----------|---------|
| Security Architect | Attack vectors, compliance, data protection | Opus | Auth, API design, data flows |
| Pragmatic Engineer | Simplicity, DX, maintainability | GPT-5.3 | Any implementation decision |
| UX Advocate | End-user experience, accessibility, cognitive load | Gemini | UI, flows, error handling |
| Cost Optimizer | Infrastructure cost, API spend, scaling economics | GPT-5.3 | Architecture, infrastructure |
| Performance Engineer | Latency, throughput, memory, bundle size | Opus | Frontend, backend, database |
| Regulatory Analyst | GDPR, HIPAA, CCPA, accessibility law | Opus | Data handling, user management |
| Scale Architect | Horizontal scaling, distributed systems, failure modes | Opus | Architecture decisions |
| Senior Advocate | 55+ specific: font sizes, touch targets, plain language | Gemini | Golden Circle-specific |

### When to Use Adversarial vs Standard Council

| Scenario | Standard Council | Adversarial Council |
|----------|-----------------|-------------------|
| "Plan the auth system" | Each model plans independently | Each model critiques from a different angle |
| "Review this PR" | Each model reviews the same code | One checks security, one checks performance, one checks UX |
| "Design the database schema" | Each model proposes a schema | One optimizes for reads, one for writes, one for flexibility |
| "Write the PRD" | Each model writes a PRD | One focuses on user stories, one on tech constraints, one on business value |

**Rule of thumb**: Standard council when you want **diverse solutions**. Adversarial council when you want **comprehensive evaluation** of one solution.

---

## 18. Competitive Implementation

### The Concept

Instead of routing one implementation task to one model, have **multiple models implement the same thing independently**, then pick the best (or merge the best parts).

```
┌──────────────────────────────────────────────────────────────┐
│          COMPETITIVE IMPLEMENTATION: ActivityFeed.tsx           │
│                                                                │
│  Same spec → 3 independent implementations:                   │
│                                                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐              │
│  │ Opus       │  │ GPT-5.3    │  │ Gemini     │              │
│  │            │  │            │  │            │              │
│  │ Verbose,   │  │ Concise,   │  │ Creative,  │              │
│  │ thorough,  │  │ pattern-   │  │ visual-    │              │
│  │ well-      │  │ based,     │  │ first,     │              │
│  │ documented │  │ pragmatic  │  │ novel UI   │              │
│  │            │  │            │  │ patterns   │              │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘              │
│        │               │               │                      │
│        ▼               ▼               ▼                      │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                  REVIEW AGENT                            │   │
│  │                                                          │   │
│  │  Scores each implementation on:                          │   │
│  │  - Code quality (linting, types, patterns)     [0-25]    │   │
│  │  - Performance (re-renders, bundle impact)     [0-25]    │   │
│  │  - Accessibility (WCAG, senior-friendly)       [0-25]    │   │
│  │  - Maintainability (readability, modularity)   [0-25]    │   │
│  │                                                          │   │
│  │  Decision: PICK winner | MERGE best parts | HYBRID       │   │
│  └────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### When to Use Competitive Implementation

This is expensive (3x the implementation cost), so reserve it for **high-leverage components**:

```json
{
  "competitive_implementation": {
    "enabled": true,
    "triggers": {
      "component_tags": ["core", "critical-path", "high-traffic"],
      "file_patterns": ["**/components/core/**", "**/lib/algorithms/**"],
      "manual": true
    },
    "participants": [
      "anthropic/claude-opus-4-6",
      "openai/gpt-5.3-codex",
      "gemini/gemini-3-pro"
    ],
    "evaluation_criteria": {
      "code_quality": { "weight": 25, "evaluator": "static_analysis" },
      "performance": { "weight": 25, "evaluator": "lighthouse_sim" },
      "accessibility": { "weight": 25, "evaluator": "axe_audit" },
      "maintainability": { "weight": 25, "evaluator": "complexity_score" }
    },
    "output_strategy": "pick_winner",
    "alternatives": ["merge_best_parts", "hybrid_with_human_review"]
  }
}
```

### Example: Golden Circle Tab Bar

The tab bar is the most-touched component in the app. Every user interacts with it hundreds of times. Perfect candidate:

```
/competitive-implement "Build the main tab bar for Golden Circle"
  --spec docs/prds/mobile/tab-bar.md
  --criteria accessibility:40,performance:30,code_quality:30

→ Opus: Builds with explicit WCAG AAA, verbose accessibility props, 80px touch targets
→ GPT: Builds concise, pattern-matching from popular RN tab bars, animated transitions
→ Gemini: Builds with novel haptic feedback patterns, adaptive icon sizing for vision

→ Reviewer: Merges Opus's accessibility props + GPT's animation + Gemini's adaptive sizing
→ Result: A tab bar better than any single model would produce
```

### Competitive vs Council

| Aspect | Council | Competitive |
|--------|---------|-------------|
| Input | Same prompt, produce opinion/plan | Same spec, produce working code |
| Output | Synthesized document | Working implementation |
| Cost | N API calls (text only) | N full implementation cycles |
| When | Decisions, plans, reviews | Critical components, algorithms |
| Frequency | Often (every architecture decision) | Rare (only high-leverage code) |

---

## 19. Feedback Loop & Model Performance Tracking

### The Measurement Problem

Without data, multi-model orchestration is just expensive guessing. The system needs a feedback loop that tracks which models and which council configurations actually produce better outcomes.

### What to Measure

```
┌──────────────────────────────────────────────────────────────┐
│                    FEEDBACK LOOP                                │
│                                                                │
│  ┌───────────┐    ┌───────────┐    ┌───────────────────────┐  │
│  │ Council   │───▶│ Implement │───▶│ Outcome Tracking      │  │
│  │ Decision  │    │ ation     │    │                       │  │
│  └───────────┘    └───────────┘    │ - Revision count      │  │
│       ▲                            │ - Bug density          │  │
│       │                            │ - Verify score         │  │
│       │                            │ - Time to completion   │  │
│       │                            │ - User satisfaction    │  │
│       │                            └──────────┬────────────┘  │
│       │                                       │               │
│       │    ┌──────────────────────────────────┘               │
│       │    │                                                   │
│       │    ▼                                                   │
│       │  ┌───────────────────────────────────────────────┐    │
│       │  │         MODEL AFFINITY PROFILE                 │    │
│       │  │                                                │    │
│       │  │ golden-circle project:                         │    │
│       │  │   opus:  architecture=92, react_native=78      │    │
│       │  │   gpt:   architecture=84, react_native=91      │    │
│       │  │   gemini: architecture=79, react_native=85     │    │
│       │  │                                                │    │
│       │  │ Recommendation: Route RN to GPT, arch to Opus  │    │
│       │  └──────────────────────┬────────────────────────┘    │
│       │                         │                              │
│       └─────────────────────────┘                              │
│         (Routing table auto-adjusts)                           │
└──────────────────────────────────────────────────────────────┘
```

### Metrics Schema

```json
{
  "performance_tracking": {
    "enabled": true,
    "store": ".sigma/model-performance.json",
    "metrics": {
      "planning_accuracy": {
        "description": "How many revisions were needed after the plan?",
        "measurement": "revision_count",
        "lower_is_better": true
      },
      "bug_density": {
        "description": "Bugs found per model-generated code block",
        "measurement": "bugs_per_kloc",
        "lower_is_better": true
      },
      "verification_score": {
        "description": "Score when /step-verify runs on this model's output",
        "measurement": "score_0_to_100",
        "higher_is_better": true
      },
      "time_to_completion": {
        "description": "Wall-clock time from task assignment to completion",
        "measurement": "seconds",
        "lower_is_better": true
      },
      "council_vs_single": {
        "description": "A/B comparison: council output vs single-model output",
        "measurement": "quality_delta_pct",
        "higher_is_better": true
      }
    },
    "auto_adjust": {
      "enabled": true,
      "min_samples": 10,
      "confidence_threshold": 0.8,
      "description": "After 10+ data points with 80%+ confidence, auto-update routing table"
    }
  }
}
```

### Performance Log Example

```json
{
  "entries": [
    {
      "timestamp": "2026-02-15T14:30:00Z",
      "project": "golden-circle",
      "task": "implement-activity-feed",
      "model": "openai/gpt-5.3-codex",
      "skill": "react-native-components",
      "metrics": {
        "time_to_completion_s": 145,
        "verification_score": 87,
        "revisions_needed": 1,
        "bugs_found_post_review": 0
      }
    },
    {
      "timestamp": "2026-02-15T15:00:00Z",
      "project": "golden-circle",
      "task": "plan-auth-architecture",
      "mode": "council",
      "council_config": "planning",
      "participants": ["opus", "gpt-5.3", "gemini-2.5-pro"],
      "chairman": "opus",
      "metrics": {
        "time_to_completion_s": 340,
        "verification_score": 94,
        "revisions_needed": 0,
        "participant_scores": {
          "opus": 91,
          "gpt-5.3": 86,
          "gemini": 83
        },
        "council_improvement_over_single": "+8%"
      }
    }
  ]
}
```

### Adaptive Routing

Once enough data accumulates, the router can **auto-optimize**:

```
Week 1: Static config → "frontend-design" routes to Gemini (based on assumption)
Week 3: 15 samples collected → GPT-5.3 scores 12% higher on React Native components
Week 3: Router auto-suggests: "Promote GPT-5.3 to default for react-native-components?"
User approves → Config updated automatically
```

The human always approves changes (HITL preserved), but the system surfaces the recommendation with data backing.

---

## 20. Step 0 Integration — Router as Infrastructure

### Router Setup IS Environment Setup

The multi-LLM router should be a first-class part of Sigma Protocol's Step 0 (Environment Setup), not an afterthought add-on.

### Enhanced Step 0 Flow

```
Step 0: Environment Setup (Enhanced)
│
├── Phase 1: Core Tools
│   ├── Verify Claude Code / Codex / Cursor installed
│   ├── Validate MCP servers
│   └── Check tool availability
│
├── Phase 2: Multi-LLM Router Setup (NEW)
│   │
│   ├── 2a. Detect Available Credentials
│   │   ├── Scan for API keys: GEMINI_API_KEY, OPENAI_API_KEY, etc.
│   │   ├── Scan for OAuth tokens: ~/.cli-proxy-api/tokens/
│   │   ├── Scan for subscriptions: ChatGPT, Gemini, Claude, Z.ai
│   │   └── Report: "Found: 3 API keys, 2 subscriptions"
│   │
│   ├── 2b. Install Proxy Service
│   │   ├── Install Claude Code Router (npm install -g @musistudio/claude-code-router)
│   │   ├── Install CLIProxyAPI (if subscriptions detected)
│   │   └── Verify proxy health
│   │
│   ├── 2c. Configure OAuth Flows (Interactive)
│   │   ├── "You have a ChatGPT Plus subscription. Connect it? [Y/n]"
│   │   ├── → Opens browser for OAuth login
│   │   ├── "You have Gemini Advanced. Connect it? [Y/n]"
│   │   └── → Opens browser for OAuth login
│   │
│   ├── 2d. Generate sigma-router.json
│   │   ├── Auto-populate providers from detected credentials
│   │   ├── Apply default step→model mappings
│   │   ├── Apply default council configurations
│   │   └── Set cost policies based on available auth methods
│   │
│   ├── 2e. Health Check All Providers
│   │   ├── Ping each provider endpoint
│   │   ├── Verify tool calling support
│   │   ├── Measure latency per provider
│   │   └── Report: "4 providers healthy, 7 models available, avg latency 340ms"
│   │
│   └── 2f. Display Summary
│       ├── "Multi-LLM Router: READY"
│       ├── "Providers: Anthropic (native), OpenAI (subscription), Gemini (API key)"
│       ├── "Council available: 3 participants, ~$0.00/council (subscription-first)"
│       └── "Run /council --dry-run to test"
│
└── Phase 3: Project Scaffolding
    ├── Generate CLAUDE.md / AGENTS.md
    ├── Copy skills, commands, agents
    └── Ready to proceed to Step 1
```

### Setup Command

```bash
# Full interactive setup
sigma install --platform claude-code --with-router

# Quick setup (auto-detect, no prompts)
sigma install --platform claude-code --with-router --auto

# Add router to existing project
sigma router init

# Re-run OAuth flows
sigma router auth --provider openai
sigma router auth --provider gemini

# Health check
sigma router doctor
```

---

## 21. The Sigma Senate — Accumulated Council Wisdom

### The Problem: Stateless Councils

Individual councils are stateless. They produce an output and discard all context. This means:
- Council B doesn't know what Council A decided
- The same debate can happen repeatedly across councils
- Architectural principles aren't enforced across decisions

### The Senate Pattern

The **Sigma Senate** is a persistent knowledge base of council decisions that accumulates over a project's lifetime. Every council decision becomes a Senate Resolution that future councils must reference.

```
┌──────────────────────────────────────────────────────────────┐
│                      SIGMA SENATE                              │
│         (Accumulated Council Decision Log)                     │
│                                                                │
│  Resolution 001 (2026-02-15)                                  │
│  Council: planning | Participants: Opus, GPT, Gemini          │
│  Decision: Session-based auth over JWT                        │
│  Rationale: Senior users need persistent sessions; JWT        │
│    refresh complexity adds cognitive load to error states      │
│  Vote: 3-0 unanimous                                          │
│                                                                │
│  Resolution 002 (2026-02-16)                                  │
│  Council: planning | Participants: Opus, GPT, Gemini          │
│  Decision: PostgreSQL + Drizzle ORM                           │
│  Rationale: Type-safe schema with migration tooling;           │
│    Drizzle's query builder reduces SQL injection surface       │
│  Vote: 2-1 (Gemini preferred Prisma, overruled)              │
│                                                                │
│  Resolution 003 (2026-02-17)                                  │
│  Council: adversarial_design | Participants: Opus, GPT, Gemini│
│  Decision: 60px minimum touch targets, 80px for primary nav   │
│  Rationale: WCAG AAA for motor accessibility; senior users     │
│    with arthritis need larger targets than standard 44px       │
│  Vote: 3-0 unanimous                                          │
│                                                                │
│  ─────────────────────────────────────────────────────         │
│  CONSTITUTIONAL PRINCIPLES (derived from resolutions):         │
│  - Security must not compromise senior UX                      │
│  - Type safety at every boundary                               │
│  - Accessibility is non-negotiable, not a nice-to-have        │
│  - Simplicity over cleverness in auth/session management       │
└──────────────────────────────────────────────────────────────┘
```

### How Future Councils Reference the Senate

When a new council is convened, the Senate log is injected into every participant's context:

```
COUNCIL PROMPT (with Senate context):

"You are participating in an architecture council for Golden Circle.

EXISTING SENATE RESOLUTIONS (you must respect these unless you
explicitly argue for overriding one with justification):

1. Session-based auth (not JWT) — for senior UX
2. PostgreSQL + Drizzle ORM — for type safety
3. 60px min touch targets, 80px primary nav — for accessibility

YOUR TASK: Design the notification system..."
```

This means:
- Decisions compound — each council builds on previous decisions
- Contradictions are surfaced explicitly ("I recommend JWT for notifications, which contradicts Resolution 001 because...")
- Architectural coherence emerges organically over time
- New team members can read the Senate log to understand WHY decisions were made

### Senate Storage

```json
{
  "senate": {
    "store": ".sigma/senate-resolutions.json",
    "auto_inject": true,
    "max_resolutions_in_context": 20,
    "summarize_after": 50,
    "constitutional_principles": {
      "auto_derive": true,
      "derive_after_n_resolutions": 5,
      "human_review_required": true
    }
  }
}
```

### Senate as Auto-Generated ADRs

Each Senate Resolution IS an Architecture Decision Record (ADR), auto-formatted:

```
.sigma/senate/
├── 001-session-auth-over-jwt.md
├── 002-postgresql-drizzle-orm.md
├── 003-60px-touch-targets.md
├── 004-expo-sdk-52-cross-platform.md
├── CONSTITUTION.md  (auto-derived principles)
└── INDEX.md         (chronological list with status)
```

This integrates with existing ADR workflows and documentation patterns.

---

## 22. Emergency Cascade & Graceful Degradation

### The Problem: Mid-Council Failures

What happens when a council is executing and one provider goes down? A naive approach ("skip that participant") produces degraded results without the user knowing.

### Cascade Chain

Each provider has a fallback chain of models with similar capabilities:

```json
{
  "cascade": {
    "openai/gpt-5.3-codex": {
      "chain": [
        "moonshot/kimi-k2.5",
        "anthropic/claude-sonnet-4-6",
        "openrouter/meta-llama/llama-4-maverick"
      ],
      "match_criteria": ["tool_calling", "code_generation"],
      "timeout_ms": 10000
    },
    "gemini/gemini-3-pro": {
      "chain": [
        "gemini/gemini-2.5-flash",
        "anthropic/claude-opus-4-6"
      ],
      "match_criteria": ["multimodal", "long_context"]
    },
    "anthropic/claude-opus-4-6": {
      "chain": [
        "openai/gpt-5.3-codex",
        "gemini/gemini-2.5-pro"
      ],
      "match_criteria": ["reasoning", "architecture"]
    }
  }
}
```

### Degradation Levels

```
Level 0: FULL COUNCIL
  All participants responding normally.
  → Proceed as configured.

Level 1: SUBSTITUTION
  One participant failed/timed out.
  → Substitute from cascade chain.
  → Log: "GPT-5.3 timed out, substituted with Kimi K2.5"
  → Quality: ~95% of full council

Level 2: REDUCED COUNCIL
  Substitution also failed. Council has N-1 participants.
  → Proceed with remaining participants.
  → Warn user: "Council reduced to 2 participants (Opus + Gemini)"
  → Quality: ~80% of full council

Level 3: SINGLE-MODEL FALLBACK
  Only one participant available.
  → Fall back to single-model mode.
  → Warn user: "Council unavailable. Using Opus solo."
  → Offer: "Retry council later? [Y/n]"
  → Quality: Baseline (no council benefit)

Level 4: FULL OUTAGE
  No models available.
  → Queue task for retry.
  → Notify user: "All providers down. Task queued for retry in 5 minutes."
```

### Health Check Integration

Proactive health checking prevents mid-council failures:

```json
{
  "health_check": {
    "pre_council": true,
    "check_before_fan_out": true,
    "exclude_unhealthy": true,
    "report_degradation": true,
    "check_interval_ms": 60000,
    "endpoints": {
      "anthropic": "https://api.anthropic.com/v1/messages",
      "openai": "https://api.openai.com/v1/models",
      "gemini": "https://generativelanguage.googleapis.com/v1beta/models"
    }
  }
}
```

Before every council, the orchestrator pings all participant endpoints. If one is down, it pre-substitutes before fan-out — avoiding the mid-execution failure entirely.

---

## 23. Cross-Project Learning & Meta-Optimization

### The Vision: Learning Across Projects

You may run more than one project on Sigma Protocol. Each project generates model performance data. Patterns emerge:

```
Across 4 projects:
  - Gemini scores 15% higher on React Native component generation
  - Opus scores 22% higher on architecture planning
  - GPT-5.3 is 3x faster for scaffolding tasks
  - Council improves planning quality by 18% avg vs single-model
  - Adversarial council catches 2.3x more issues than standard council
```

### Meta-Learning Architecture

```
┌──────────────────────────────────────────────────────────────┐
│               CROSS-PROJECT LEARNING                           │
│                                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Project  │  │ Project  │  │ Project  │  │ Project  │    │
│  │ A        │  │ B        │  │ C        │  │ D        │    │
│  │          │  │          │  │          │  │          │    │
│  │ perf.json│  │ perf.json│  │ perf.json│  │ perf.json│    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │            │
│       ▼             ▼             ▼             ▼            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              META-OPTIMIZER                              │  │
│  │                                                          │  │
│  │  Aggregates performance data across all projects         │  │
│  │  Identifies model×skill affinities                       │  │
│  │  Generates optimized default routing tables               │  │
│  │  Publishes recommendations to global config              │  │
│  └────────────────────────────────────────────────────────┘  │
│                          │                                    │
│                          ▼                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           GLOBAL DEFAULTS (updated monthly)              │  │
│  │                                                          │  │
│  │  ~/.sigma/global-routing-defaults.json                   │  │
│  │                                                          │  │
│  │  "Based on data from 4 projects, 847 tasks:              │  │
│  │   - react-native-components → gpt-5.3 (91 avg score)    │  │
│  │   - architecture → opus (92 avg score)                   │  │
│  │   - ux-design → gemini (94 avg score)                    │  │
│  │   - council:planning → +18% over single (p<0.05)"       │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Privacy-Aware Aggregation

Cross-project learning must respect privacy:

```json
{
  "cross_project_learning": {
    "enabled": true,
    "opt_in": true,
    "data_shared": {
      "model_scores": true,
      "task_types": true,
      "council_configs": true,
      "code_content": false,
      "project_names": false,
      "file_paths": false,
      "prompts": false
    },
    "aggregation": "local_only",
    "alternatives": ["local_only", "sigma_cloud", "self_hosted"]
  }
}
```

By default, learning happens **locally only** — across your own projects. An optional `sigma_cloud` mode could aggregate anonymized performance data across all Sigma Protocol users (with explicit opt-in), creating a community-driven model routing intelligence.

### Community-Driven Routing Presets

If enough users opt in, the community generates validated routing presets:

```
sigma router presets list
  - react-native-app (95% confidence, 200+ data points)
  - express-api-backend (90% confidence, 150+ data points)
  - nextjs-fullstack (88% confidence, 120+ data points)
  - expo-mobile (92% confidence, 180+ data points)

sigma router presets apply react-native-app
  → Applied: routing table optimized for React Native projects
  → Based on community data from 200+ projects
```

### The Compounding Effect

This creates a flywheel:
1. Sigma Protocol users generate performance data
2. Data optimizes routing tables across projects
3. Better routing → better outputs → more users
4. More users → more data → better routing
5. Repeat

Each project that uses the multi-LLM router makes the routing smarter for every future project. This is the network effect that turns the router from a tool into a platform.

---

## 24. References

### Projects & Tools
- [CC Mirror](https://github.com/numman-ali/cc-mirror) — Isolated Claude Code variants with custom providers
- [Claude Code Router](https://github.com/musistudio/claude-code-router) — Multi-model routing for Claude Code
- [CCProxy](https://ccproxy.orchestre.dev/) — Go-based API translation proxy
- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) — Subscription-to-API wrapper
- [VibeProxy](https://github.com/automazeio/vibeproxy) — macOS OAuth wrapper app
- [LiteLLM](https://docs.litellm.ai/) — Universal LLM gateway
- [llm-council](https://github.com/llm-council/llm-council) — Multi-model democratic evaluation

### Documentation
- [Claude Code LLM Gateway](https://code.claude.com/docs/en/llm-gateway) — Official gateway configuration docs
- [Claude Code Model Config](https://code.claude.com/docs/en/model-config) — Model selection environment variables

### Research
- "Language Model Council: Democratically Benchmarking Foundation Models on Highly Subjective Tasks" — NAACL 2025
- [LLM Council blog post](https://virtuslab.com/blog/ai/llm-council/) — Karpathy's AI consensus mechanism analysis

---

*This document is a living architecture record. Update it as implementation progresses and decisions are validated.*
