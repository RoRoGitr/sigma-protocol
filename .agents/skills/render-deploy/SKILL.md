---
name: render-deploy
description: "Render.com IaC authoring and deployment workflow — render.yaml blueprints, service types (web/worker/cron/pserv/static/keyvalue), projects/environments model, env var wiring (fromDatabase/fromService/fromGroup), autoscaling, cron patterns, deploy lifecycle (preDeployCommand, healthCheckPath), blueprint validation, preview environments, Render CLI, Render Workflows, and workspace plan migration (2026-08-01). NOT a Render analytics/ops tool (cross-reference pp-render for drift/cost/rightsize). Triggers on: render.yaml, Blueprint, render deploy, render services, fromDatabase, fromService, fromGroup, autoscaling, cron job, env group, preview environments, render blueprint, deploy hook, Render Workflows, render.com."
department: engineering
triggers:
  - render.yaml
  - Blueprint
  - render deploy
  - render services
  - fromDatabase
  - fromService
  - fromGroup
  - autoscaling
  - cron job
  - env group
  - preview environments
  - render blueprint
  - deploy hook
  - Render Workflows
  - render.com
  - render CLI
  - IaC render
  - render.yaml blueprint drift
---

# Render Deploy

Render.com IaC authoring — `render.yaml` blueprints, service types, env var wiring, autoscaling, cron jobs, deploy lifecycle, and preview environments.

> Reference snapshot, 2026-06-04: Render Blueprint specification and CLI v2.19.0. Verify the current Blueprint schema and the workspace's selected CLI before applying version-specific fields; this skill does not authorize an upgrade.

**Related skills:**
- `pp-render` — analytical ops: drift detection, cost review, rightsize, env diff/promote, incident timeline
- Project-scoped `render-vercel-deploy` — builds on this skill with project-specific service IDs

---

## When to Use

- Authoring or reviewing a `render.yaml` blueprint
- Setting up web services, background workers, cron jobs, or Postgres databases
- Wiring env vars from databases, other services, or env groups
- Configuring autoscaling, preview environments, or deploy hooks
- Validating a blueprint before merging
- Understanding the 2026-08-01 workspace plan migration

## When NOT to Use

- Render operational analytics (drift, cost, rightsize) — use `pp-render`
- Render Postgres query tuning — database concerns, not IaC
- General CI/CD pipeline config — use `ci-cd-patterns`

---

## Deprecated Field Aliases

Always use the current field names:

| Deprecated | Current | Notes |
|-----------|---------|-------|
| `env` | `runtime` | Service runtime type |
| `redis` | `keyvalue` | Key-value store service type |
| `autoDeploy` | `autoDeployTrigger` | Deploy trigger policy |
| `pullRequestPreviewsEnabled` | `previews.generation` | Preview env control |

---

## Service Types Reference

```yaml
services:
  - type: web        # HTTP server, public URL
  - type: worker     # Background process, no public URL
  - type: cron       # Scheduled job (at-most-once)
  - type: pserv      # Private service (internal network only)
  - type: static     # Static site from build output

databases:           # top-level key for managed Postgres
  - name: mydb

envVarGroups:        # top-level key for shared env var groups
  - name: shared-config

# NOTE: keyvalue (Redis/Key Value) goes under services:
services:
  - type: keyvalue
    name: cache
```

Key fields by service type:

| Field | web | worker | cron | pserv | static |
|-------|-----|--------|------|-------|--------|
| `buildCommand` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `startCommand` | ✓ | ✓ | — | ✓ | — |
| `schedule` | — | — | ✓ | — | — |
| `healthCheckPath` | ✓ | — | — | ✓ | — |
| `scaling` | ✓ | ✓ | — | — | — |
| `disk` | ✓ | ✓ | — | ✓ | — |
| `previews` | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Blueprint Structure

### Flat (root-level, single environment)

```yaml
services:
  - type: web
    name: api
    runtime: node
    plan: starter
    buildCommand: npm ci && npm run build
    startCommand: node dist/server.js
    healthCheckPath: /health
    maxShutdownDelaySeconds: 30   # default 30, max 300
    autoDeployTrigger: commit     # commit | checksPass | off
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: maindb
          property: connectionString
      - key: REDIS_URL
        fromService:
          type: keyvalue
          name: cache
          property: connectionString

databases:
  - name: maindb
    plan: starter
    databaseName: myapp_prod
    storageAutoscalingEnabled: true   # auto +50% storage at >90% full (prod DBs)

envVarGroups:
  - name: shared-config
    envVars:
      - key: LOG_LEVEL
        value: info
      - key: API_SECRET
        sync: false    # prompts on first create; NOT re-prompted on updates
```

### Projects/environments model (multi-environment, canonical for new apps)

The projects/environments model is the current canonical structure for new apps. Do NOT duplicate resources at both root level and inside environments.

```yaml
projects:
  - name: myapp
    environments:
      - name: production
        networking:
          isolation: enabled        # prevents staging creds leaking into prod
        services:
          - type: web
            name: api
            runtime: node
            plan: standard
            buildCommand: npm ci && npm run build
            startCommand: node dist/server.js
            healthCheckPath: /health
            autoDeployTrigger: checksPass
            envVars:
              - key: NODE_ENV
                value: production
              - key: DATABASE_URL
                fromDatabase:
                  name: maindb-prod
                  property: connectionString
            scaling:
              minInstances: 2
              maxInstances: 10
              targetCPUPercent: 60
              targetMemoryPercent: 75

          - type: worker
            name: queue-processor
            runtime: node
            plan: standard
            startCommand: node dist/worker.js
            scaling:
              minInstances: 1
              maxInstances: 5
              targetCPUPercent: 70

        databases:
          - name: maindb-prod
            plan: standard
            storageAutoscalingEnabled: true

        envVarGroups:
          - name: prod-secrets
            envVars:
              - key: STRIPE_SECRET_KEY
                sync: false

      - name: staging
        services:
          - type: web
            name: api
            runtime: node
            plan: starter
            buildCommand: npm ci && npm run build
            startCommand: node dist/server.js
            envVars:
              - key: NODE_ENV
                value: staging
              - key: DATABASE_URL
                fromDatabase:
                  name: maindb-staging
                  property: connectionString

        databases:
          - name: maindb-staging
            plan: starter
```

### Immutable fields (cannot change after service creation)

- `type` — service type
- `databaseName` — Postgres database name
- `region` — deployment region

---

## Env Var Wiring

### fromDatabase — all properties

```yaml
- key: DATABASE_URL
  fromDatabase:
    name: maindb
    property: connectionString    # most common

# All available properties:
# connectionString, internalConnectionString, externalConnectionString
# database, host, hostnames, internalHostname, password, port, user
```

### fromService — cross-service injection

```yaml
# Web service URL
- key: API_URL
  fromService:
    type: web
    name: api
    envVarKey: RENDER_INTERNAL_HOSTNAME    # rendered by Render at deploy

# Key-value (Redis) connection string
- key: REDIS_URL
  fromService:
    type: keyvalue
    name: cache
    property: connectionString

# All keyvalue properties: connectionString, host, port
```

### fromGroup — shared env group

```yaml
envVars:
  - fromGroup: shared-config     # pulls all vars from the group
  - key: OVERRIDE_ME
    value: service-specific      # service-level overrides group var
```

Multiple groups: Render applies group vars in order; later groups win on key collision. Warning: multiple-group precedence is unstable — test before relying on it.

### sync: false semantics

`sync: false` means "prompt for a value on first blueprint apply; do not re-prompt on subsequent applies." It is effectively a one-time input, not a recurring prompt. It is also excluded from preview environments and invalid in env groups.

```yaml
- key: DATABASE_PASSWORD
  sync: false    # prompted once at first deploy; ignored on updates
```

Never commit literal secret values in `render.yaml`. Use `sync: false` or reference secrets from env groups.

### generateValue

Auto-generates a random value on first create (useful for session secrets):

```yaml
- key: SESSION_SECRET
  generateValue: true
```

---

## Autoscaling

Requires **Pro** workspace or higher. Silently disabled in preview environments (runs `minInstances`).

```yaml
scaling:
  minInstances: 1
  maxInstances: 10            # absolute max: 100 instances
  targetCPUPercent: 60        # valid range: 1–90
  targetMemoryPercent: 75     # valid range: 1–90
```

Scale-out formula: `ceil(current_instances × actual_utilization / target_utilization)`

Cannot autoscale services with persistent disk.

---

## Cron Jobs

```yaml
services:
  - type: cron
    name: daily-cleanup
    runtime: node
    schedule: "0 2 * * *"      # UTC ONLY — no DST awareness
    startCommand: node scripts/cleanup.js
    buildCommand: npm ci
```

Cron constraints:
- Expressions are **UTC only** — no DST; account for the offset yourself
- Maximum run duration: **12 hours**
- Guarantee: **at-most-once** — not exactly-once. Restarts can re-run a job
- Each cron run spins up an **ephemeral container** — no persistent disk access
- Minimum billing: **$1/mo** per cron service regardless of runtime
- Crons cannot scale (autoscaling not applicable)

Idempotency is mandatory — design every cron as if it might run twice:

```typescript
// scripts/cleanup.js — idempotent pattern
async function cleanup() {
  const marker = await db.getCleanupMarker(today());
  if (marker?.completed) {
    // already ran today — idempotent skip (log via your logger if useful)
    return;
  }
  await db.runCleanup();
  await db.setCleanupMarker(today(), { completed: true });
}
```

Manual trigger (for testing): Render dashboard → Cron Service → Trigger Run.

---

## Deploy Lifecycle

```yaml
services:
  - type: web
    name: api
    preDeployCommand: npm run db:migrate    # runs BEFORE new container starts
                                            # blocks deploy on failure
                                            # use for zero-downtime DB migrations
    buildCommand: npm ci && npm run build
    startCommand: node dist/server.js
    healthCheckPath: /health
    maxShutdownDelaySeconds: 60             # default 30, max 300; extend for graceful drain
    autoDeployTrigger: checksPass           # deploy only after CI passes
    buildFilter:
      paths:
        - apps/api/**
        - packages/shared/**
      ignoredPaths:
        - docs/**
        - "*.md"
```

`initialDeployHook`: runs once on the very first deploy. Use for seed data:

```yaml
initialDeployHook: node scripts/seed.js
```

`autoDeployTrigger` values:

| Value | Behavior |
|-------|---------|
| `commit` | Deploy on every push to watched branch |
| `checksPass` | Deploy only after all CI checks pass (recommended for production) |
| `off` | Manual deploys only |

---

## Blueprint Validation + CI

Install Render CLI:

```bash
brew tap render-oss/render && brew install render   # macOS
curl -fsSL https://render.com/install | sh           # Linux
```

Validate locally (CLI v2.7.1+):

```bash
render blueprints validate                           # validates render.yaml in cwd
render blueprints validate -f my-blueprint.yaml     # custom path (2026-02-09)
```

Wire JSON schema for IDE completions:

```json
// .vscode/settings.json
{
  "yaml.schemas": {
    "https://render.com/schema/render.yaml.json": ["render.yaml"]
  }
}
```

### GitHub Actions — validate + deploy hook

```yaml
name: Render Deploy
on:
  push:
    branches: [main]

permissions: {}

jobs:
  validate:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v6.0.3
      - name: Validate blueprint
        run: |
          curl -fsSL https://render.com/install | sh
          render blueprints validate

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    permissions:
      contents: read
    environment: production
    steps:
      - name: Trigger Render deploy
        run: |
          curl -X POST "${{ secrets.RENDER_DEPLOY_HOOK_URL }}"
```

Store `RENDER_DEPLOY_HOOK_URL` as a GitHub Actions secret. For image-backed services, append `?imgURL=<image>` to the hook URL to specify the image.

---

## Render CLI Cheatsheet

```bash
render login                              # authenticate
render services list                      # list all services
render services create                    # interactive service creation (CLI v2.16+)
render logs --service-id srv-xxx          # stream service logs
render ssh srv-xxx                        # SSH into running instance
render ssh srv-xxx --ephemeral            # SSH into one-off ephemeral instance (v2.19.0)
render psql -d db-xxx                     # non-interactive Postgres shell
render blueprints validate                # validate render.yaml
render blueprints validate -f custom.yaml # custom blueprint path
render deploy srv-xxx                     # trigger manual deploy
```

`--ephemeral` (v2.19.0): spawns a fresh instance for debugging; does not touch production. Exits when you disconnect.

---

## Preview Environments

```yaml
services:
  - type: web
    name: api
    previews:
      generation: automatic    # automatic | manual | off
      expireAfterDays: 3
      serviceDetails:
        plan: starter          # preview can use a cheaper plan
        # autoDeployTrigger, envVars overrides allowed here
```

Preview environment behavior:
- Autoscaling is disabled in preview environments — runs at `minInstances`
- `sync: false` vars are excluded from previews
- Each PR creates an isolated preview environment with its own URL
- Previews do not inherit production secrets unless explicitly wired

---

## Render Workflows (Public Beta, 2026-04-07)

Durable, stateful multi-step background processes. Use instead of cron when:

| Need | Use |
|------|-----|
| Scheduled, short-lived, simple | Cron service |
| Durable, survives failures, retry logic | Render Workflows |
| Total duration >12h | Render Workflows |
| Multi-step with state across steps | Render Workflows |
| Payment pipelines, data migrations, agent chains | Render Workflows |

```bash
render workflows init --language typescript   # scaffold a new workflow
```

SDK available in TypeScript and Python (beta). Workflows persist state across restarts and retry failed steps automatically.

---

## Workspace Plan Migration (2026-08-01)

Old plans (Individual, Team) → new plans mandatory by August 1, 2026:

| New Plan | Price | Key Features |
|----------|-------|-------------|
| **Hobby** | Free | Single user, limited resources |
| **Pro** | $25/mo flat, unlimited seats | Autoscaling, custom domains, Pro compute |
| **Scale** | $499/mo flat | Higher limits, priority support |
| **Enterprise** | Custom | SLA, SAML, dedicated infra |

Autoscaling requires **Pro** or higher. Dedicated outbound IPs (Pro+, added 2026-05-19): $100/mo per IP set.

---

## Anti-Patterns

- Committing literal secret values in `render.yaml` — use `sync: false` or env groups
- Relying on `sync: false` for re-prompting on blueprint updates — it is initial-create only
- Using both root-level resources and `environments:` in the same blueprint — duplicates services
- Designing cron jobs without idempotency — Render's at-most-once guarantee means restarts can re-run
- Running long operations in cron jobs without a 12h budget check — max run duration is 12 hours
- Setting `scaling.maxInstances` > 100 — Render hard limit
- Expecting autoscaling in preview environments — it is silently disabled
- Using `autoDeployTrigger: commit` on production — use `checksPass` to require CI to pass first

---

## Quality Gates

- [ ] Service binds to `0.0.0.0:$PORT` (not a hardcoded port)
- [ ] `healthCheckPath` returns 200 within the service's startup window
- [ ] `storageAutoscalingEnabled: true` on all production Postgres databases
- [ ] No literal secret values in `render.yaml` — `sync: false` or env groups for secrets
- [ ] `render blueprints validate` passes locally and in CI before merge
- [ ] Preview environments have `expireAfterDays` set
- [ ] Cron jobs are idempotent (safe to run twice)
- [ ] `autoDeployTrigger: checksPass` on production web services
- [ ] `preDeployCommand` used for DB migrations (blocks deploy on failure)
- [ ] `isolation: enabled` on production environment (projects/environments model)
- [ ] Pro workspace (or higher) confirmed before relying on autoscaling
