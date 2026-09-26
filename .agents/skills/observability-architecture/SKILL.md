---
name: observability-architecture
description: "Backend observability — structured logging, metrics, distributed tracing. Use when implementing monitoring and observability. Triggers on \'observability\', \'logging\', \'metrics\', \'tracing\', \'monitoring\', \'OpenTelemetry\'."
triggers: ["observability", "monitoring", "sentry", "posthog", "logging", "tracing", "metrics", "telemetry", "error tracking", "analytics"]
tags: [engineering, observability, monitoring, logging, devops]
department: engineering
---

# Observability Architecture

Production patterns for monitoring, logging, error tracking, and product analytics. Covers the full stack from structured logging to telemetry governance.

> **Version:** Patterns target OpenTelemetry 1.40+.

## Three Pillars

```
┌──────────────────────────────────────────────────────────┐
│                    OBSERVABILITY                          │
├──────────────┬──────────────────┬────────────────────────┤
│   LOGGING    │    METRICS       │    TRACING             │
│ (What)       │ (How much)       │ (Where)                │
│ structlog    │ Prometheus/StatsD│ OpenTelemetry          │
│ Sentry       │ PostHog events   │ LangSmith (AI)         │
│ CloudWatch   │ Grafana          │ Distributed traces     │
└──────────────┴──────────────────┴────────────────────────┘
```

## Division of Responsibility

### Error Tracking (Sentry)
- Runtime exceptions and crash reports
- Performance monitoring (transactions, spans)
- Release health tracking
- Issue triage and assignment
- Source map uploads for frontend

### Product Analytics (PostHog / Mixpanel)
- Pageviews and user sessions
- Product events (feature usage, conversions)
- Funnel analysis
- Web vitals and performance metrics
- Feature flags and A/B tests

### Structured Logging (Application)
- Request/response logging
- Business logic audit trail
- Background job execution
- Debug information for development

## Structured Logging (Python)

```python
import structlog

logger = structlog.get_logger(__name__)

# Configure structlog for JSON output in production
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),  # Production
    ],
)

# Usage — always log structured data, not strings
logger.info("order_processed",
    order_id=order.id,
    user_id=user.id,
    amount=order.total,
    duration_ms=elapsed,
)

# Bind context for request lifecycle
structlog.contextvars.bind_contextvars(
    request_id=request.headers.get("x-request-id"),
    user_id=current_user.id,
)
```

## Sentry Integration

```python
# Backend (FastAPI)
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.celery import CeleryIntegration

sentry_sdk.init(
    dsn=os.environ["SENTRY_DSN"],
    environment=os.environ.get("ENV", "development"),
    traces_sample_rate=0.1,  # 10% of transactions
    profiles_sample_rate=0.1,
    integrations=[FastApiIntegration(), CeleryIntegration()],
    before_send=scrub_pii,  # CRITICAL: strip PII before sending
)
```

```typescript
// Frontend (Next.js)
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.01,
  replaysOnErrorSampleRate: 1.0,
});
```

## Event Taxonomy

Consistent naming prevents analytics chaos:

```
{domain}_{action}_{target}

Examples:
  auth_login_success
  auth_login_failed
  order_created_checkout
  order_completed_payment
  feature_used_dashboard
  error_thrown_api
```

| Rule | Good | Bad |
|------|------|-----|
| snake_case | `order_created` | `orderCreated`, `Order Created` |
| Past tense for completed | `payment_processed` | `process_payment` |
| Domain prefix | `auth_login_success` | `login_success` |
| No PII in event names | `user_upgraded_plan` | `john_upgraded_pro` |

## Telemetry Governance

### PII Scrubbing (CRITICAL)

```python
def scrub_pii(event, hint):
    """Strip PII before sending to Sentry/PostHog."""
    SCRUB_FIELDS = {"password", "token", "secret", "credit_card", "ssn", "email"}
    if "request" in event:
        for key in list(event["request"].get("data", {}).keys()):
            if any(field in key.lower() for field in SCRUB_FIELDS):
                event["request"]["data"][key] = "[REDACTED]"
    return event
```

### Env-Driven Configuration

```bash
# NEVER hardcode DSNs or keys in source
SENTRY_DSN=https://xxx@sentry.io/123
POSTHOG_KEY=phc_xxx
POSTHOG_HOST=https://app.posthog.com
LOG_LEVEL=INFO          # DEBUG in dev, INFO in prod
TRACES_SAMPLE_RATE=0.1  # 10% in prod, 1.0 in dev
```

## Production Checklist

- [ ] Structured logging (JSON in prod, pretty in dev)
- [ ] Sentry for error tracking with source maps
- [ ] Product analytics for feature usage
- [ ] PII scrubbing before any external transmission
- [ ] Env-driven configuration (no hardcoded DSNs)
- [ ] Event naming taxonomy documented and enforced
- [ ] Alerting rules for critical errors (PagerDuty/Slack)
- [ ] Log retention policy (30 days hot, 90 days cold)
- [ ] Health check endpoints for uptime monitoring

## When NOT to Use

- Not for application logic debugging — use systematic-debugging skill
- Not for CI/CD pipeline monitoring — use ci-cd-patterns
- Not for security monitoring (SIEM, threat detection) — use security skills
- Not for frontend performance monitoring — focuses on backend observability (logs, metrics, traces)

## Related Skills

- `crewai-patterns` — architecture
- `langgraph-patterns` — architecture
- `address-sanitizer` — security
- `audit-context-building` — security

## Platform Support

Works with: Claude Code, Cursor, Codex.

## Tools Used

EXA MCP, Bash
