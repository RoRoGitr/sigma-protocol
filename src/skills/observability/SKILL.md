---
name: observability
description: "Production observability — three pillars (logs/metrics/traces), OpenTelemetry SDK + Collector, error tracking (Sentry v10 setup, source maps, Seer Autofix), product analytics (PostHog feature flags, LLM observability, experiments), structured logging with OTel correlation, RED/USE metrics, SLO/burn-rate alerting. Use when wiring monitoring, setting up error tracking, configuring analytics, writing alert rules, or instrumenting LLM calls. Triggers on: observability, logging, metrics, tracing, monitoring, OpenTelemetry, sentry, posthog, error tracking, analytics, SLO, burn rate, gen_ai spans, LLM observability, structured logging, OTLP, Collector."
department: engineering
triggers:
  - observability
  - monitoring
  - logging
  - tracing
  - metrics
  - telemetry
  - OpenTelemetry
  - sentry
  - posthog
  - error tracking
  - analytics
  - SLO
  - burn rate
  - gen_ai spans
  - LLM observability
  - structured logging
  - OTLP
  - Collector
  - session replay
  - feature flag
  - Seer Autofix
---

# Observability

Production patterns for the three pillars — logs, metrics, traces — plus error tracking, product analytics, and LLM/AI observability.

> Reference snapshot, 2026-06-05: `@sentry/node` 10.56.0 · `@sentry/nextjs` 10.56.0 · `posthog-js` 1.380.1 · `posthog-node` 5.36.2 · OTel Python SDK 1.42.1 · OTel Collector 0.153.0 · structlog 25.5.0. Preserve the project's declared versions. Select an explicit GenAI semantic-convention version and instrumentation compatibility before adding LLM telemetry.

---

## When to Use

- Setting up or auditing error tracking (Sentry) in a Next.js or Node service
- Instrumenting a Python/FastAPI service with OpenTelemetry
- Wiring product analytics (PostHog) including feature flags or LLM observability
- Authoring SLO rules or burn-rate alerts
- Adding structured logging with trace correlation
- Instrumenting an LLM/AI pipeline with `gen_ai.*` semantic conventions

## When NOT to Use

- Security SIEM / threat detection — out of scope here
- CI/CD pipeline monitoring — use `ci-cd-patterns`
- Frontend performance (Core Web Vitals) — separate concern
- For AI agent tracing: prefer openinference over LangSmith when vendor-neutrality matters

---

## Three Pillars

```
LOGGING (What happened)     METRICS (How much / how fast)    TRACING (Where did time go)
structlog → JSON             PrometheusMetricReader           OTel SDK → OTLP Collector
sentry.logger.*              Counter / Histogram / UpDown     BatchSpanProcessor → OTLP
posthog.$ai_generation       exemplars link to traces         gen_ai.* semconv for LLM
```

---

## OpenTelemetry — Python / FastAPI

### Zero-code bootstrap (recommended)

```bash
pip install opentelemetry-sdk opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install          # auto-detects FastAPI/SQLAlchemy/httpx/Redis
```

```bash
# Run with auto-instrumentation
OTEL_SERVICE_NAME=my-api \
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318 \
OTEL_TRACES_SAMPLER=parentbased_traceidratio \
OTEL_TRACES_SAMPLER_ARG=0.1 \
OTEL_PYTHON_LOG_CORRELATION=true \
opentelemetry-instrument uvicorn main:app --host 0.0.0.0 --port 8000
```

`OTEL_PYTHON_LOG_CORRELATION=true` injects trace context into stdlib `logging`. It is correlation configuration, not a replacement for a logging export pipeline. The current OTel Python documentation still presents `LoggingHandler` as the SDK bridge from stdlib logging to OTel logs; choose it or a vendor-supported bridge based on the project's exporter and SDK versions.

### Manual SDK setup (when you need custom spans)

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource, SERVICE_NAME

# MUST init before structlog configure
resource = Resource.create({
    SERVICE_NAME: "my-api",
    "service.namespace": "prod",
    "service.instance.id": os.environ["POD_NAME"],   # stable in semconv 1.40+
})
provider = TracerProvider(resource=resource)
provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://otel-collector:4318/v1/traces"))
)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# Custom span
with tracer.start_as_current_span("process_order") as span:
    span.set_attribute("order.id", order_id)
    span.set_attribute("order.total_usd", total)
    result = process(order_id)
```

---

## structlog + OTel Correlation Bridge

Init OTel `TracerProvider` BEFORE calling `structlog.configure()`.

```python
import structlog
import contextvars
from opentelemetry import trace

def add_open_telemetry_spans(
    logger: object, method: str, event_dict: dict
) -> dict:
    """Inject active span IDs into every log line."""
    span = trace.get_current_span()
    if not span.is_recording():
        return event_dict
    ctx = span.get_span_context()
    event_dict["span"] = {
        "trace_id": f"{ctx.trace_id:032x}",
        "span_id":  f"{ctx.span_id:016x}",
        "parent_span_id": (
            f"{span.parent.span_id:016x}" if hasattr(span, "parent") and span.parent else None
        ),
    }
    return event_dict


structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        add_open_telemetry_spans,              # inject span IDs
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),   # JSON in prod
    ],
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Non-blocking async logging in FastAPI handlers
await logger.ainfo("order_processed", order_id=order_id, total_usd=total)
```

### FastAPI middleware — per-request context

```python
from starlette.middleware.base import BaseHTTPMiddleware
import structlog.contextvars

class ObservabilityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        structlog.contextvars.clear_contextvars()          # MUST clear per-request
        structlog.contextvars.bind_contextvars(
            request_id=request.headers.get("x-request-id", ""),
            path=request.url.path,
            method=request.method,
        )
        response = await call_next(request)
        return response
```

---

## Sentry — JavaScript / Next.js (v10)

### Canonical Next.js setup (v10, 3-file pattern)

```bash
npx @sentry/wizard@<project-approved-version> -i nextjs    # generates the 3 files + instrumentation.ts
```

Generated files:
- `instrumentation-client.ts` — browser init
- `sentry.server.config.ts` — Node.js / SSR
- `sentry.edge.config.ts` — Edge runtime
- `instrumentation.ts` — `register()` + `onRequestError`

```typescript
// instrumentation.ts
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    await import('./sentry.server.config');
  }
  if (process.env.NEXT_RUNTIME === 'edge') {
    await import('./sentry.edge.config');
  }
}
export const onRequestError = Sentry.captureRequestError;
```

```typescript
// sentry.server.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampler: ({ name }) => {
    if (name.includes('/health')) return 0.01;
    if (name.includes('/api/')) return 0.2;
    return 0.1;
  },
  enableLogs: true,                        // Sentry Logs API (v10 GA)
  sendDefaultPii: true,                    // v10.4: required for IP inference
  propagateTraceparent: true,              // v10.10: W3C traceparent header
  ignoreSpans: [
    { op: /^browser\.(cache|connect|DNS)$/ },
    { op: 'resource.link', name: /\.css(\?.*)?$/ },
  ],                                       // v10.2+
  streamGenAiSpans: true,                  // v10.53: prevents AI payload drops
});
```

### Server Actions distributed tracing

Server Actions are NOT auto-instrumented — wrap each one explicitly:

```typescript
import * as Sentry from '@sentry/nextjs';
import { headers } from 'next/headers';

export async function createOrder(formData: FormData) {
  return Sentry.withServerActionInstrumentation(
    'createOrder',
    { headers: headers(), formData },
    async () => {
      // your action logic
    }
  );
}
```

### Sentry Logs API (v10+)

```typescript
import * as Sentry from '@sentry/nextjs';

Sentry.init({ ..., enableLogs: true });

const { logger } = Sentry;

logger.info('order_processed', { orderId, totalUsd: total });
logger.warn('payment_retry', { attempt: 3, orderId });
logger.error('checkout_failed', { reason: 'card_declined', orderId });

// Template literals with fmt
logger.info(logger.fmt`Processing order ${orderId} for user ${userId}`);

// beforeSendLog to strip PII
Sentry.init({
  beforeSendLog: (log) => {
    if (log.attributes?.['user.email']) {
      log.attributes['user.email'] = '[REDACTED]';
    }
    return log;
  },
});
```

### Source maps — Debug ID workflow (primary)

```bash
# No --release required; Debug IDs matched automatically
sentry-cli sourcemaps inject ./dist
sentry-cli sourcemaps upload ./dist --validate

# CI step (GitHub Actions)
- name: Upload source maps
  run: |
    sentry-cli sourcemaps inject .next
    sentry-cli sourcemaps upload .next
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: ${{ vars.SENTRY_ORG }}
    SENTRY_PROJECT: ${{ vars.SENTRY_PROJECT }}
```

Releases workflow (optional/additive — still useful for deploy markers):

```bash
sentry-cli releases new "$RELEASE"
sentry-cli releases set-commits "$RELEASE" --auto
sentry-cli releases finalize "$RELEASE"
sentry-cli releases deploys "$RELEASE" new -e production
```

### Session replay

```typescript
Sentry.init({
  replaysSessionSampleRate: 0.1,      // 10% of sessions
  replaysOnErrorSampleRate: 1.0,      // 100% on errors — always keep this at 1.0
  integrations: [
    Sentry.replayIntegration({
      networkDetailAllowUrls: [/https:\/\/api\.yourdomain\.com/],
      networkRequestHeaders: ['X-Request-Id'],
      networkResponseHeaders: ['X-Request-Id'],
      maskAllInputs: true,
      // Lazy-load to reduce bundle size:
      // workerUrl: '/sentry-replay-worker.js'
    }),
  ],
});
```

Production sample-rate table:

| Traffic/day | `replaysSessionSampleRate` | `replaysOnErrorSampleRate` |
|-------------|---------------------------|---------------------------|
| >100k        | 0.01                       | 1.0                        |
| 10k–100k     | 0.1                        | 1.0                        |
| <10k         | 0.25                       | 1.0                        |

CSP requirements for Session Replay WebWorker:
```
connect-src 'self' *.sentry.io;
worker-src blob:;
child-src blob:;   /* Safari ≤15.4 */
```

### Seer / Autofix (GA announced for 2026-06-17 — verify availability before relying on it)

Seer is Sentry's AI debugger — 94.5% root-cause accuracy, $20/mo add-on.

Setup:
1. Connect GitHub integration in Sentry Settings → Integrations
2. Seer SCM Settings → connect repos
3. Seer Project Settings → map projects to repos
4. Optional auto-trigger (10+ events, <14 days, fixability score)
5. Set automation stopping point: RCA only / Solution / PR draft

MCP tool: `mcp__sentry__analyze_issue_with_seer`

Pricing: $1/fix run, $0.003/scan. More tracing + logs + profiles + source maps = better Seer results.

### v9 → v10 breaking changes

| Change | v9 | v10 |
|--------|----|-----|
| `BaseClient`, `hasTracingEnabled`, FID web vital | present | removed |
| `sendDefaultPii` IP inference | implicit | requires `sendDefaultPii: true` |
| `_experiments.enableLogs` | experimental | top-level `enableLogs: true` |
| Logging export | Configure `LoggingHandler` or the project's supported bridge | Verify against the installed OTel Python SDK/exporter |

Forward-compat (v11): `dataCollection: { genAI: { inputs: false, outputs: false }, httpHeaders: { deny: [...] } }` replaces `sendDefaultPii`.

---

## PostHog — Feature Flags + LLM Observability

### Node.js (server-side, v5.x)

```typescript
import { PostHog } from 'posthog-node';

const posthog = new PostHog(process.env.POSTHOG_API_KEY!, {
  host: 'https://us.i.posthog.com',    // ingestion endpoint (NOT us.posthog.com)
  flushAt: 20,
  flushInterval: 10000,
});

// Capture with flags for attribution
const flags = await posthog.getAllFlags(distinctId);
posthog.capture({
  distinctId,
  event: 'order_placed',
  properties: { total_usd: total, $feature_flag_payloads: flags },
});

// Serverless: always shutdown to flush
await posthog.shutdown();
```

### Feature flags — evaluate_flags (recommended, Python v7.14+)

```python
# Python SDK — use evaluate_flags() single-call snapshot
flags = posthog.evaluate_flags(
    distinct_id="user-123",
    flag_keys=["checkout-flow", "new-dashboard"],
)

if flags.is_enabled("checkout-flow"):
    show_new_flow()

# Only send flags that were accessed (reduces noise)
posthog.capture(
    distinct_id="user-123",
    event="page_viewed",
    flags=flags.only_accessed(),
)
```

### LLM / AI Observability

```python
# OTel auto-instrumentation for Anthropic
pip install 'posthog[otel]' opentelemetry-instrumentation-anthropic

# $ai_generation, $ai_trace, $ai_span captured automatically with:
# - cost, latency, token counts, model name, I/O
```

```typescript
// posthog-js: capture AI generation event
posthog.capture('$ai_generation', {
  $ai_provider: 'anthropic',
  $ai_model: 'claude-opus-4-8',
  $ai_input_tokens: usage.inputTokens,
  $ai_output_tokens: usage.outputTokens,
  $ai_total_cost_usd: totalCost,
  $ai_latency: durationMs,
  $ai_trace_id: traceId,          // links spans → trace timeline
});
```

### Next.js — @posthog/next (pre-release, zero-flicker SSR flags)

```typescript
// middleware.ts
import { postHogMiddleware } from '@posthog/next/middleware';
export default postHogMiddleware({ proxy: true });
export const config = { matcher: ['/((?!_next|api).*)'] };
```

```typescript
// app/layout.tsx (RSC)
import { PostHogProvider } from '@posthog/next';
import { getPostHog } from '@posthog/next/server';

export default async function RootLayout({ children }) {
  const posthog = getPostHog();
  const bootstrapFlags = await posthog.getAllFlags(userId);
  return (
    <html>
      <body>
        <PostHogProvider
          apiKey={process.env.NEXT_PUBLIC_POSTHOG_KEY!}
          options={{ api_host: 'https://us.i.posthog.com', bootstrapFlags }}
        >
          {children}
        </PostHogProvider>
      </body>
    </html>
  );
}
```

### PostHog MCP

```bash
claude mcp add --transport http posthog https://mcp.posthog.com/mcp -s user
```

Tools: `/posthog:flags`, `/posthog:insights`, `/posthog:errors`, `/posthog:experiments`, `/posthog:replay` (20+ tools). Primary agent surface — Composio is a fallback.

---

## OTel Collector — Production Pipeline

### Pipeline ordering (non-negotiable)

1. `memory_limiter` MUST be first — OOM-kills the collector if absent during spikes
2. `batch` MUST be last before export
3. Span metrics (`spanmetrics` connector) MUST derive BEFORE `tail_sampling`

### Agent config (per-node DaemonSet)

```yaml
# otel-collector-agent.yaml
receivers:
  otlp:
    protocols:
      grpc: { endpoint: 0.0.0.0:4317 }
      http: { endpoint: 0.0.0.0:4318 }

processors:
  memory_limiter:                  # MUST be first
    check_interval: 1s
    limit_mib: 400
    spike_limit_mib: 100
  filter/health:                   # drop health-check spans (~40% volume)
    spans:
      exclude:
        match_type: strict
        span_names: ["GET /health", "GET /readyz"]
  attributes/pii:
    actions:
      - key: "db.statement"
        action: hash            # preserves query-shape grouping
      - key: "http.request.header.authorization"
        action: delete
      - key: "http.request.header.cookie"
        action: delete
  tail_sampling:
    decision_wait: 30s
    policies:
      - name: errors
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: slow
        type: latency
        latency: { threshold_ms: 2000 }
      - name: baseline
        type: probabilistic
        probabilistic: { sampling_percentage: 5 }
  batch:                           # MUST be last
    send_batch_size: 512
    timeout: 5s

exporters:
  otlp/gateway:
    endpoint: otel-gateway:4317
    tls: { insecure: false }

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, filter/health, attributes/pii, tail_sampling, batch]
      exporters: [otlp/gateway]
```

### Gateway config (fanout Deployment)

Tail sampling requires all spans for a trace on the same collector — use `loadbalancingexporter` with `routing_key: traceID` on the agent tier before tail-sampling.

```yaml
connectors:
  spanmetrics:                     # generates RED metrics from traces
    histogram:
      explicit:
        buckets: [0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    dimensions:
      - name: http.method
      - name: http.status_code
      - name: service.name

exporters:
  otlphttp/vendor:
    endpoint: https://ingest.vendor.io
    headers: { "x-api-key": "${VENDOR_API_KEY}" }
  awss3:                           # cold storage, ~38% vendor bill reduction
    s3uploader:
      region: us-east-1
      s3_bucket: observability-cold
      s3_prefix: otel
      file_prefix: traces
      compression: zstd
      encoding: parquet

service:
  pipelines:
    traces/main:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlphttp/vendor, awss3]
    metrics/spanmetrics:           # RED metrics derived BEFORE tail sampling
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [otlphttp/vendor]
```

### Collector self-monitoring

Scrape these metrics for collector health:

```
otelcol_processor_dropped_spans      # rising = backpressure
otelcol_exporter_queue_size          # rising = export bottleneck
otelcol_process_memory_rss           # near limit = increase memory_limiter
```

---

## Metrics Instrumentation (Python)

```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from prometheus_client import REGISTRY

# Custom Prometheus registry (avoids collision with default)
reader = PrometheusMetricReader(registry=REGISTRY)
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)
meter = metrics.get_meter("my_service")

# RED metrics
request_count = meter.create_counter(
    "http_requests_total",
    description="Total HTTP requests",
)
request_duration = meter.create_histogram(
    "http_request_duration_seconds",
    description="Request duration in seconds",
    unit="s",
)
active_connections = meter.create_up_down_counter(
    "active_connections",
    description="Current active connections",
)

# Exemplar: attach trace_id to histogram observation
with tracer.start_as_current_span("handle_request") as span:
    with request_duration.record(elapsed, {"http.status_code": 200}):
        pass  # exemplar auto-attached from active span context
```

---

## SLO / Error Budget

### Concepts

```
SLI = good_requests / total_requests    (availability SLI)
SLO = 99.9%  →  error_budget = 0.1%   (30-day window = 43.2 min)

Multi-window multi-burn-rate alerts (Google SRE method 6):
  Page (critical): burn > 14.4x over 1h  AND burn > 14.4x over 5m
  Page (warning):  burn > 6x   over 6h  AND burn > 6x   over 30m
  Ticket:          burn > 3x   over 3d  AND burn > 3x   over 6h
```

### Sloth SLO spec (generates Prometheus recording rules)

```yaml
# sloth-slo.yaml
version: prometheus/v1
service: payment-api
slos:
  - name: availability
    objective: 99.9
    description: "99.9% of payment requests succeed"
    sli:
      events:
        error_query: >
          sum(rate(http_requests_total{job="payment-api",code=~"5.."}[{{.window}}]))
        total_query: >
          sum(rate(http_requests_total{job="payment-api"}[{{.window}}]))
    alerting:
      name: PaymentApiAvailability
      page_alert:
        labels: { severity: critical }
      ticket_alert:
        labels: { severity: warning }
```

```bash
sloth generate -i sloth-slo.yaml -o /etc/prometheus/rules/
```

Sloth generates `slo:sli_error:ratio_rate*`, `slo:current_burn_rate:ratio`, and multi-window alerts automatically.

---

## GenAI / LLM Telemetry Compatibility

The OpenTelemetry project moved GenAI conventions into its dedicated GenAI semantic-conventions repository. Do not label a `gen_ai.*` attribute family stable, set `OTEL_SEMCONV_STABILITY_OPT_IN`, or install auto-instrumentation from this skill without first recording all three choices in the project:

1. The GenAI semantic-convention source and version.
2. The instrumentation library and exact version that emits that schema.
3. The backend/exporter version that accepts it, including any migration or dual-emission plan.

Record low-cardinality operational data only when supported by that selected schema: operation, provider, model identifier, duration, outcome, and token counts. Do **not** capture prompt, completion, tool arguments, retrieval text, or user identifiers by default. Any content capture requires an explicit product privacy decision, a bounded retention policy, and redaction before export.

---

## Anti-Patterns

- Treating correlation injection as a logging export pipeline, or assuming a logging bridge is removed without checking the installed OTel SDK
- Placing `batch` processor before `tail_sampling` — loses trace context
- Omitting `memory_limiter` from Collector — OOM on traffic spikes
- Chaining tail-sampling policies with AND — use separate policies (union, not intersection)
- Running tail sampling without `loadbalancingexporter` routing — incomplete traces split across instances
- Capturing prompts, completions, tool arguments, retrieval text, or user identifiers by default — privacy and cost risk
- Assuming a GenAI semantic-convention stability level or attribute name without selecting a compatible schema, instrumentation, and backend
- Relying on `sendDefaultPii: false` in Sentry v10 for IP omission — must explicitly set `sendDefaultPii: true` to include IPs

---

## Quality Gates

- [ ] OTel SDK and instrumentation versions selected from the project's dependency policy; `opentelemetry-bootstrap -a install` run after compatible dep changes
- [ ] `OTLP_EXPORTER_ENDPOINT` configured; `OTEL_SERVICE_NAME` set
- [ ] Collector deployed (agent + gateway, or single instance for small setups)
- [ ] `memory_limiter` is first processor in every Collector pipeline
- [ ] `spanmetrics` connector derives RED metrics BEFORE `tail_sampling`
- [ ] structlog `add_open_telemetry_spans` processor installed and OTel init is before structlog configure
- [ ] Sentry v10 `enableLogs: true` + `propagateTraceparent: true` set
- [ ] Server Actions wrapped with `Sentry.withServerActionInstrumentation`
- [ ] SLO + multi-window burn-rate alerts per service (page at 14.4x/1h, 6x/6h; ticket at 3x/3d)
- [ ] GenAI schema source/version, instrumentation, and backend compatibility recorded before LLM telemetry; no content or user identifiers captured by default
- [ ] Exemplars enabled on Prometheus Histograms for trace → latency bucket linkage
- [ ] Collector self-metrics scraped (`otelcol_processor_dropped_spans`, queue size)
- [ ] PostHog ingestion host uses `us.i.posthog.com` (NOT `us.posthog.com`) for event capture

---

## Version Reference

| Package | Version | Notes |
|---------|---------|-------|
| `@sentry/node` / `@sentry/nextjs` | 10.56.0 | v10 = OTel v2 underneath |
| `sentry-cli` | 2.58.x | Note: 2.x series (not 3.x) |
| `posthog-js` | 1.380.1 | |
| `posthog-node` | 5.36.2 | |
| OTel Python SDK | 1.42.1 | Reference snapshot; `LoggingHandler` remains documented by OTel Python |
| OTel Collector | 0.153.0 | |
| GenAI semantic conventions | selected per project | Dedicated GenAI repository; pin schema, instrumentation, and backend compatibility together |
| structlog | 25.5.0 | `await logger.ainfo()` for async |
