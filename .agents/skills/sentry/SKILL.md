---
name: sentry
description: Sentry error-tracking + performance standard — capture with context not noise, scrub PII, wire source maps, set release/environment, and avoid the patterns that bury real errors. Use when adding error tracking, instrumenting exceptions, breadcrumbs, tracing, or triaging Sentry noise.
triggers: [sentry, error tracking, exception capture, captureException, breadcrumbs, source maps, error monitoring, crash reporting, performance tracing]
---

# Sentry — Error Tracking & Performance

Sentry exists to surface the errors that matter with enough context to fix them fast. The failure mode is **noise**: unscrubbed PII, duplicate issues, and handled-but-captured exceptions that bury the one crash that matters.

## The Iron Rules

1. **Capture with context, not just the error.** Attach `tags` (route, feature, tenant-tier — never tenant PII), `context` (request id, non-PII state), and `breadcrumbs` (the trail to the failure). A bare `captureException(e)` with no context is a needle with no haystack map.
2. **Scrub PII before it leaves the process.** Configure `beforeSend` to strip email, tokens, auth headers, message bodies, and raw IP (or set `sendDefaultPii: false`). A crash report is not a place to leak user data.
3. **Set `release` + `environment`.** Every event tagged with the release SHA and env (prod/staging/dev). Without `release` you cannot tell if a deploy introduced or fixed an issue, and source maps won't associate.
4. **Upload source maps for every release.** A minified stack trace is unactionable. Wire source-map upload into the build/deploy; verify symbolication on a test error.
5. **Don't capture what you handle.** If you catch an error and degrade gracefully (return a 503, show a fallback), that's expected behavior — capture it as a `message` at `warning` level with context, or not at all. Reserve `captureException` at `error`/`fatal` for genuine unexpected failures, so the dashboard reflects real incidents.

## Patterns

- **Init once** at the entry point with `dsn`, `release`, `environment`, `tracesSampleRate` (sample — don't trace 100% in prod), and a `beforeSend` PII scrubber.
- **Manual capture:** `Sentry.captureException(e, { tags, contexts })` for unexpected; `captureMessage(msg, 'warning')` for handled-but-notable.
- **Breadcrumbs:** automatic for fetch/console; add manual breadcrumbs at decision points on critical paths (auth, payment, order submit).
- **Scopes:** use `withScope` to attach request-local tags/context without leaking into other events.
- **Performance:** wrap critical transactions (checkout, order submit) in spans; sample.
- **Alerting:** route `fatal`/spike alerts to the on-call channel; rate-limit noisy known-issues.

## Common mistakes (audit for these)

- `captureException` on every handled error → dashboard noise drowns real crashes.
- No `beforeSend` scrub → PII (emails, tokens, message bodies) shipped to Sentry.
- Missing `release`/source maps → minified, un-actionable stack traces.
- 100% trace sampling in prod → cost + quota burn; sample.
- Global scope mutation (`setTag` without `withScope`) → context bleeds across requests.

## Verify
- Trigger a test error → it appears symbolicated (real file:line via source maps), tagged with `release` + `environment`.
- `beforeSend` strips a known PII field (assert in a unit test of the scrubber).
- Handled/degraded paths do NOT create `error`-level issues (they log `warning` or nothing).
