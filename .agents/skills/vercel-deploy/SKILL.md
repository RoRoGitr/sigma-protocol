---
name: vercel-deploy
description: "Vercel deployment patterns — Fluid compute, vercel.ts/vercel.json config, environment variables (three-layer model, branch-scoped, NEXT_PUBLIC_ anti-pattern), function duration (maxDuration, plan limits), waitUntil for background tasks, AI SDK streaming routes, edge vs Fluid decision matrix, preview vs production workflow, custom environments, crons, observability, and OIDC keyless auth. Entry-point skill — cross-references vercel:* plugin skills for deep dives. Triggers on: vercel deploy, vercel config, vercel domain, fluid compute, vercel.ts, maxDuration, waitUntil, vercel env, preview deploy, vercel functions, ISR, edge functions, AI SDK vercel, vercel OIDC."
department: engineering
triggers:
  - vercel deploy
  - vercel config
  - vercel domain
  - fluid compute
  - vercel.ts
  - maxDuration
  - waitUntil
  - vercel env
  - preview deploy
  - vercel functions
  - edge functions
  - ISR
  - AI SDK vercel
  - vercel OIDC
  - deploy to vercel
  - vercel production
---

# Vercel Deploy

Vercel deployment patterns for production apps — Fluid compute, environment variables, function config, AI SDK routes, preview workflows, and observability.

> Version anchor: Vercel CLI 54.9.1 · `@vercel/config/v1` (vercel.ts, Dec 2025) · Fluid compute GA Apr 23 2025 · Next.js 16 defaults. Verified 2026-06-04.

---

## When to Use

- Deploying a Next.js, SvelteKit, or static site to Vercel
- Configuring `vercel.ts` / `vercel.json` for production
- Setting up environment variables across scopes
- Configuring AI SDK streaming routes (`maxDuration`, `waitUntil`)
- Debugging cold starts, edge vs Fluid runtime choice
- Setting up preview environments and custom environments (Pro/Enterprise)

## When NOT to Use

- Anonymous/unauthenticated prototype deploys — the old tarball script covers that (demo/prototype only, not production)
- Backend-only services without HTTP surfaces — use Render or Railway
- Docker-based deployments — Vercel is not a container runtime

---

## Deploy Entry Point Decision

| Scenario | Command |
|----------|---------|
| Quick prototype / demo (no account) | `bash /mnt/skills/user/vercel-deploy/scripts/deploy.sh` (tarball endpoint) |
| Linked project, preview | `vercel` |
| Linked project, production | `vercel --prod` |
| Custom environment (Pro+) | `vercel deploy --target=staging` |
| CI/CD | `vercel --prod --yes` with `VERCEL_TOKEN` |

---

## Fluid Compute

Fluid is the default execution model for all new Vercel projects since **April 23 2025**.

Key properties:
- **In-function concurrency:** one instance handles up to N concurrent requests (configurable in dashboard). `concurrency: 10` means each instance handles 10 concurrent requests — Vercel still scales out more instances when needed. Not a global cap.
- **Bytecode caching:** V8 bytecode cached across invocations. Production only — preview cold starts are slower. Do not benchmark cold start in preview.
- **Active CPU billing:** billed on active CPU time + provisioned GB-hours, not invocation count. I/O-bound functions see up to 95% cost reduction. CPU-bound may cost more — load-test before assuming savings.
- **`waitUntil` for background tasks:** fire-and-forget after the HTTP response. Use for logging, analytics, AI post-processing.

```typescript
// Enable/disable per-project in vercel.json or vercel.ts
// {"fluid": true}  — explicit enable for existing projects

// waitUntil pattern
import { waitUntil } from '@vercel/functions';
import type { NextRequest } from 'next/server';

export async function POST(req: NextRequest) {
  const body = await req.json();
  const result = await processRequest(body);

  waitUntil(
    // Runs after response is sent — does not block TTR
    trackAnalytics(body, result)
  );

  return Response.json(result);
}
```

Memory under Fluid: cannot set `memory` in `vercel.json` when Fluid is enabled. Use the dashboard → Functions section. `maxDuration` remains settable in `vercel.json`.

---

## Config: vercel.ts vs vercel.json

Use `vercel.ts` for dynamic or typed config (shipped Dec 2025); `vercel.json` for simple static config. Keep **only one** config file.

### vercel.ts (recommended for complex config)

```typescript
// vercel.ts
import {
  routes,
  type VercelConfig,
  deploymentEnv,
} from '@vercel/config/v1';

const config: VercelConfig = {
  fluid: true,

  // Per-route maxDuration (glob patterns)
  functions: {
    'app/api/chat/route.ts': {
      maxDuration: 300,    // Hobby max 300s, Pro/Enterprise max 800s
    },
    'app/api/stream/route.ts': {
      maxDuration: 300,
    },
  },

  // Crons (fire on production deploys only)
  crons: [
    { path: '/api/cleanup', schedule: '0 0 * * *' },
    { path: '/api/digest', schedule: '0 8 * * 1-5' },
  ],

  // Cache-control helpers
  headers: [
    {
      source: '/api/:path*',
      headers: [
        { key: 'Cache-Control', value: 'no-store' },
      ],
    },
    {
      source: '/_next/static/:path*',
      headers: [
        { key: 'Cache-Control', value: 'public, max-age=31536000, immutable' },
      ],
    },
  ],

  // Rewrites via typed helper
  rewrites: routes.rewrite('/api/v1/:path*', '/api/:path*'),
};

export default config;
```

### vercel.json (static config)

```json
{
  "fluid": true,
  "functions": {
    "app/api/chat/route.ts": { "maxDuration": 300 }
  },
  "crons": [
    { "path": "/api/cleanup", "schedule": "0 0 * * *" }
  ]
}
```

---

## Function Configuration

### maxDuration by plan

| Plan | Max `maxDuration` |
|------|------------------|
| Hobby | 300s |
| Pro | 800s |
| Enterprise | 800s (configurable per-project) |

Place `maxDuration` in route segment config for per-route control:

```typescript
// app/api/chat/route.ts
export const maxDuration = 300;  // MUST be top-level export

export async function POST(req: Request) { ... }
```

Or via `vercel.json` `functions` glob (applies to matching paths).

### Edge vs Fluid decision matrix

| Use case | Runtime | Reason |
|----------|---------|--------|
| Next.js /app routes (default) | **Fluid** | Default since Next.js 16; bytecode cache |
| AI SDK streaming | **Fluid** | Needs `maxDuration` 300–800s |
| Database reads/writes | **Fluid** | Node.js drivers not available on Edge |
| WebSocket termination | **Edge** | Only runtime with WS support |
| Ultra-low-latency APIs (<10ms, no Node deps) | **Edge** | No cold start penalty |
| Middleware | **Edge** | Required by Next.js middleware runtime |

To force Edge on a specific route:

```typescript
export const runtime = 'edge';
```

---

## Environment Variables

Three-layer model:

```
.env.local (gitignored)          ← local dev override
  ↓
vercel env pull .env.local       ← syncs from Vercel dashboard to local
  ↓
Dashboard / vercel env add       ← source of truth for deployed envs
```

### CLI operations

```bash
vercel env add SECRET_KEY production        # add to production only
vercel env add SECRET_KEY preview           # add to all previews
vercel env add SECRET_KEY development       # add to dev environment
vercel env pull .env.local                  # pull current env to local
vercel env ls                               # list all env vars
```

### NEXT_PUBLIC_ anti-pattern

```bash
# WRONG — exposes secret to browser bundle
NEXT_PUBLIC_OPENAI_API_KEY=sk-...

# CORRECT — server-only
OPENAI_API_KEY=sk-...

# Only use NEXT_PUBLIC_ for values that MUST be in the browser
NEXT_PUBLIC_POSTHOG_KEY=phc_...     # OK: intended to be public
NEXT_PUBLIC_APP_URL=https://...     # OK: not a secret
```

Limit: 64 KB total per deployment across all env vars.

### Branch-scoped preview env vars

Override a specific preview var for a branch (overrides the generic preview value):

```bash
vercel env add DATABASE_URL preview --git-branch feature/new-db
```

Useful for per-PR database URLs or API endpoints.

### Custom environments (Pro: 1, Enterprise: 12)

```bash
vercel env pull --environment=staging .env.staging
vercel deploy --target=staging
```

---

## AI SDK Deploy Patterns

### OIDC keyless auth

On deployed Vercel instances: OIDC is automatic — no config needed.

Locally: `vercel link && vercel env pull` then `vercel dev`. Tokens expire after 12h; `vercel dev` auto-refreshes.

Fallback via explicit key:

```bash
vercel env add AI_GATEWAY_API_KEY production
```

### AI SDK streaming route template

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai';
import { waitUntil } from '@vercel/functions';

export const maxDuration = 300;   // REQUIRED on Hobby; up to 800 on Pro

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: openai('gpt-4o'),      // or anthropic(), etc.
    messages,
    onFinish({ usage, text }) {
      // Non-blocking: runs after stream completes
      waitUntil(
        db.usage.create({
          data: {
            inputTokens: usage.inputTokens,
            outputTokens: usage.outputTokens,
            generationId: result.experimental_providerMetadata?.openai?.requestId,
          },
        })
      );
    },
  });

  return result.toDataStreamResponse();
}
```

---

## Preview vs Production Workflow

```
git push origin feature/my-feature
  → Vercel auto-deploys preview
  → Preview URL: https://my-app-abc123.vercel.app
  → Uses "Preview" env vars (+ branch-scoped overrides)

git push origin main
  → Vercel auto-deploys preview of main
  → Does NOT update production URL

vercel --prod   (or merge to production branch)
  → Promotes to production URL
  → Uses "Production" env vars
```

Promote a specific deployment to production without re-building:

```bash
vercel promote <deployment-url>
```

---

## Crons

Crons fire only on production deployments:

```json
{
  "crons": [
    { "path": "/api/cleanup", "schedule": "0 0 * * *" },
    { "path": "/api/digest",  "schedule": "0 8 * * 1-5" }
  ]
}
```

Route must return 200 within the function timeout:

```typescript
// app/api/cleanup/route.ts
export const maxDuration = 60;

export async function GET() {
  await runCleanup();
  return Response.json({ ok: true });
}
```

---

## Observability

Wire `@vercel/otel` for automatic OTel traces to Datadog, Honeycomb, or Grafana Cloud. RSC fetch calls get their own spans.

```typescript
// instrumentation.ts
import { registerOTel } from '@vercel/otel';

export function register() {
  registerOTel({ serviceName: 'my-app' });
}
```

Enable Observability Plus (Pro+) for production source map upload and TypeScript stack traces in the dashboard.

Monitor Fluid costs via the Observability → Functions tab. Filter by function path to identify CPU-intensive routes.

---

## Multi-Region and Failover

```json
{
  "functions": {
    "app/api/data/route.ts": {
      "regions": ["iad1"],
      "functionFailoverRegions": ["sfo1", "hnd1"]
    }
  }
}
```

---

## Anti-Patterns

- Benchmarking cold start in preview — bytecode caching only applies to production
- `NEXT_PUBLIC_` prefix on secret keys (API keys, tokens) — exposes to browser bundle
- Omitting `maxDuration` on AI SDK streaming routes — times out at 10s default on Hobby
- Setting `memory` in `vercel.json` with Fluid enabled — ignored; use dashboard
- Using `vercel.ts` and `vercel.json` simultaneously — only one config file allowed
- Storing OIDC credentials locally as environment variables when `vercel dev` can provide them

---

## Quality Gates

- [ ] Fluid explicitly confirmed for the project (dashboard or `"fluid": true`)
- [ ] `maxDuration` set for all AI SDK streaming routes (300 Hobby, up to 800 Pro)
- [ ] No `NEXT_PUBLIC_` prefix on any secret key
- [ ] Env vars exist in all three scopes: Production, Preview, Development
- [ ] Branch-scoped preview vars set for per-PR database isolation (if applicable)
- [ ] `waitUntil` used for post-response work (analytics, logging)
- [ ] `onRequestError = Sentry.captureRequestError` wired in `instrumentation.ts`
- [ ] Crons path handler returns 200 within `maxDuration`
- [ ] `@vercel/otel` wired in `instrumentation.ts`

---

## Related Skills

- The official **Vercel plugin** skills (`vercel:*` — `deploy`, `env`, `nextjs`, `ai-sdk`, `vercel-functions`) provide deep-dives when that plugin is installed in your environment.
- `observability` — OTel wiring, Sentry, PostHog
