---
name: error-handling-patterns
description: "TypeScript error handling — the Result/Either pattern, neverthrow (ok/err/ResultAsync), Effect (when worth it vs neverthrow), typed discriminated-union errors, error boundaries, retry with backoff, and when to throw vs return. Use when implementing error handling in TS services, domain logic, or API layers. Triggers on 'error handling', 'neverthrow', 'result type', 'either', 'effect', 'typed errors', 'retry', 'error boundary', 'exception handling'."
department: engineering
triggers:
  - error handling
  - neverthrow
  - result type
  - either
  - typed errors
  - effect
  - retry
  - error boundary
  - exception handling
  - try catch
  - graceful degradation
---

# Error Handling Patterns (TypeScript)

TypeScript error handling built on the Result pattern. Covers neverthrow, Effect (when warranted), typed discriminated unions, error layer boundaries, retry/backoff, and the throw-vs-return decision.

> Version anchor: neverthrow 8.2, effect 3.21. Verified 2026-06-04.

## When to Use

- Implementing error handling in TS domain logic, services, or use cases
- Choosing between Result types and thrown exceptions for a given layer
- Wiring retry/backoff around external I/O
- Deciding whether Effect is worth the overhead vs neverthrow

## When NOT to Use

- Debugging existing errors — use `systematic-debugging`
- Python exception hierarchies — the patterns here are TS-specific
- Logging and monitoring setup — out of scope here (use your logger / APM, e.g. pino + OpenTelemetry)

## Throw vs Return — the decision

The rule is not "never throw." The rule is: **throw at boundaries, return Results in domain logic.**

| Situation | Use |
|-----------|-----|
| Domain/business logic | `Result<T, E>` — callers handle typed failures |
| Unrecoverable programmer errors (invariant violation) | `throw` — do not hide this |
| Infrastructure boundary (parse config at startup) | `throw` — fail fast, fail loud |
| External API adapters wrapping `async` calls | `ResultAsync` — surfaces errors as values |
| React component error containment | Error boundary class component |

Never swallow exceptions. Every `catch` either handles meaningfully, wraps and re-throws with context, or logs and re-throws.

## Key Patterns

### Typed error hierarchy

Define domain error types as discriminated unions, not string codes.

```ts
// errors.ts
export type AppError =
  | { type: 'NOT_FOUND';       resource: string; id: string }
  | { type: 'VALIDATION';      field: string; message: string }
  | { type: 'CONFLICT';        message: string }
  | { type: 'UNAUTHORIZED' }
  | { type: 'FORBIDDEN';       action: string }
  | { type: 'RATE_LIMITED';    retryAfterMs: number }
  | { type: 'EXTERNAL_API';    service: string; cause: unknown }
  | { type: 'INTERNAL';        message: string; cause?: unknown };

// Helpers for common cases
export const notFound    = (resource: string, id: string): AppError =>
  ({ type: 'NOT_FOUND', resource, id });
export const validation  = (field: string, message: string): AppError =>
  ({ type: 'VALIDATION', field, message });
export const unauthorized = (): AppError => ({ type: 'UNAUTHORIZED' });
```

### neverthrow — ok / err / ResultAsync

neverthrow represents success/failure as values, keeping error types in the function signature.

```ts
import { ok, err, ResultAsync, Result } from 'neverthrow';
import { AppError, notFound, validation } from './errors';

// Synchronous domain logic
function validateEmail(raw: string): Result<string, AppError> {
  const clean = raw.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clean)) {
    return err(validation('email', 'Must be a valid email address.'));
  }
  return ok(clean);
}

// Async infrastructure call wrapped as ResultAsync
function fetchUser(id: string): ResultAsync<User, AppError> {
  return ResultAsync.fromPromise(
    db.user.findUniqueOrThrow({ where: { id } }),
    (cause) => {
      if (isPrismaNotFoundError(cause)) return notFound('User', id);
      return { type: 'INTERNAL', message: 'Database read failed.', cause };
    },
  );
}

// Composing with andThen (flatMap)
async function updateUserEmail(userId: string, rawEmail: string): Promise<Result<User, AppError>> {
  return validateEmail(rawEmail)
    .asyncAndThen((email) => fetchUser(userId)
      .andThen((user) =>
        ResultAsync.fromPromise(
          db.user.update({ where: { id: userId }, data: { email } }),
          (cause) => ({ type: 'INTERNAL' as const, message: 'Update failed.', cause }),
        ),
      ),
    );
}

// Caller: exhaustive match
const result = await updateUserEmail(userId, rawEmail);
if (result.isErr()) {
  const e = result.error;
  switch (e.type) {
    case 'VALIDATION':   return res.status(422).json(toProblemDetail(e));
    case 'NOT_FOUND':    return res.status(404).json(toProblemDetail(e));
    case 'UNAUTHORIZED': return res.status(401).json(toProblemDetail(e));
    default:             return res.status(500).json(toProblemDetail(e));
  }
}
return res.status(200).json(result.value);
```

### Mapping AppError → HTTP (RFC 9457)

Centralize the HTTP mapping. Don't scatter status code decisions across handlers.

```ts
// http/problem-detail.ts
import { AppError } from '../errors';

interface ProblemDetail {
  type:     string;
  title:    string;
  status:   number;
  detail:   string;
  instance: string;
}

const STATUS_MAP: Record<AppError['type'], number> = {
  NOT_FOUND:    404,
  VALIDATION:   422,
  CONFLICT:     409,
  UNAUTHORIZED: 401,
  FORBIDDEN:    403,
  RATE_LIMITED: 429,
  EXTERNAL_API: 502,
  INTERNAL:     500,
};

const TITLE_MAP: Record<AppError['type'], string> = {
  NOT_FOUND:    'Resource Not Found',
  VALIDATION:   'Validation Error',
  CONFLICT:     'Conflict',
  UNAUTHORIZED: 'Unauthorized',
  FORBIDDEN:    'Forbidden',
  RATE_LIMITED: 'Too Many Requests',
  EXTERNAL_API: 'External Service Error',
  INTERNAL:     'Internal Server Error',
};

export function toProblemDetail(err: AppError, traceId: string): ProblemDetail {
  const status = STATUS_MAP[err.type];
  const detail = err.type === 'VALIDATION'
    ? `${err.field}: ${err.message}`
    : err.type === 'NOT_FOUND'
    ? `${err.resource} with id '${err.id}' was not found.`
    : 'message' in err ? err.message : TITLE_MAP[err.type];

  return {
    type:     `https://api.example.com/problems/${err.type.toLowerCase().replace(/_/g, '-')}`,
    title:    TITLE_MAP[err.type],
    status,
    detail,
    instance: `/errors/trace/${traceId}`,
  };
}
```

### Effect — when it is worth it over neverthrow

Effect is the right choice when you need: dependency injection via services, structured concurrency (fiber-based), observability (span tracing built in), or a large team that benefits from a unified effect system. It is NOT worth it for simple error-as-value patterns in a small service — neverthrow is the lighter choice there.

```ts
import { Effect, pipe } from 'effect';

// Domain service using Effect
const validateEmail = (raw: string): Effect.Effect<string, AppError> =>
  Effect.sync(() => raw.trim().toLowerCase()).pipe(
    Effect.filterOrFail(
      (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email),
      () => validation('email', 'Must be a valid email address.'),
    ),
  );

const fetchUser = (id: string): Effect.Effect<User, AppError> =>
  Effect.tryPromise({
    try:   () => db.user.findUniqueOrThrow({ where: { id } }),
    catch: (cause) => isPrismaNotFoundError(cause)
      ? notFound('User', id)
      : { type: 'INTERNAL' as const, message: 'DB read failed.', cause },
  });

// Composition with pipe
const updateUserEmail = (userId: string, rawEmail: string) =>
  pipe(
    validateEmail(rawEmail),
    Effect.flatMap((email) =>
      pipe(
        fetchUser(userId),
        Effect.flatMap((user) =>
          Effect.tryPromise({
            try:   () => db.user.update({ where: { id: userId }, data: { email } }),
            catch: (cause) => ({ type: 'INTERNAL' as const, message: 'Update failed.', cause }),
          }),
        ),
      ),
    ),
  );

// Running at the edge
const result = await Effect.runPromiseExit(updateUserEmail(userId, rawEmail));
```

Rule: use Effect when you already use it for DI or concurrency. Do not introduce Effect solely for error handling — neverthrow is sufficient.

### Retry with exponential backoff

```ts
import { ResultAsync } from 'neverthrow';

interface RetryOptions {
  maxAttempts: number;
  baseDelayMs: number;
  maxDelayMs:  number;
  jitter:      boolean;
  isRetryable: (err: unknown) => boolean;
}

async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  opts: RetryOptions,
): Promise<T> {
  let attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (cause) {
      attempt++;
      if (attempt >= opts.maxAttempts || !opts.isRetryable(cause)) throw cause;

      const base  = Math.min(opts.baseDelayMs * 2 ** (attempt - 1), opts.maxDelayMs);
      const delay = opts.jitter ? base * (0.5 + Math.random() * 0.5) : base;

      await new Promise((r) => setTimeout(r, delay));
    }
  }
}

// Usage: wrap external API calls
const data = await retryWithBackoff(
  () => externalApi.fetchPrices(),
  {
    maxAttempts: 4,
    baseDelayMs: 200,
    maxDelayMs:  10_000,
    jitter:      true,
    isRetryable: (e) => isNetworkError(e) || isRateLimitError(e),
  },
);
```

### Error layer boundaries

Domain errors never cross into infrastructure. Infrastructure errors are wrapped before surfacing.

```
┌────────────────────────────────────────────────────────────┐
│ HTTP layer       Maps AppError → HTTP status + RFC 9457    │
│                  Never catches — just maps                  │
├────────────────────────────────────────────────────────────┤
│ Application      Returns Result<T, AppError>               │
│ (use cases)      Catches domain errors from domain layer   │
├────────────────────────────────────────────────────────────┤
│ Domain           Returns Result<T, DomainError>            │
│                  Throws only for invariant violations       │
├────────────────────────────────────────────────────────────┤
│ Infrastructure   Catches DB/network errors, wraps as       │
│ adapters         AppError, returns ResultAsync             │
└────────────────────────────────────────────────────────────┘
```

### Exhaustive discriminated-union handling

TypeScript's `never` guard ensures every error branch is handled.

```ts
function assertNever(x: never): never {
  throw new Error(`Unhandled variant: ${JSON.stringify(x)}`);
}

function httpStatusForError(err: AppError): number {
  switch (err.type) {
    case 'NOT_FOUND':    return 404;
    case 'VALIDATION':   return 422;
    case 'CONFLICT':     return 409;
    case 'UNAUTHORIZED': return 401;
    case 'FORBIDDEN':    return 403;
    case 'RATE_LIMITED': return 429;
    case 'EXTERNAL_API': return 502;
    case 'INTERNAL':     return 500;
    default:             return assertNever(err);
    // TypeScript errors here if you add a new AppError variant and forget to handle it
  }
}
```

## Anti-Patterns

- Empty `catch {}` blocks — every catch must handle, wrap+rethrow, or log+rethrow. Never swallow.
- `catch (e: any)` without narrowing — catch with `unknown` and narrow to `AppError` before use.
- Business logic checking `err.message` strings — use typed discriminated unions; strings break on refactor.
- Returning `null` to signal "not found" — callers must know to check; use `Result<T | null, AppError>` or `Result<T, NotFoundError>`.
- Using Effect when neverthrow is sufficient — Effect's DI/concurrency overhead is not free.
- Logging the full stack trace to the client in production responses — log server-side, return `instance` traceId.
- Retrying non-idempotent operations without idempotency keys — retrying a charge causes double-billing.

## Quality Gates

- [ ] All domain functions return `Result<T, AppError>` — no bare thrown exceptions in domain logic
- [ ] Infrastructure adapters use `ResultAsync.fromPromise()` with explicit error mapping
- [ ] HTTP layer maps `AppError` to RFC 9457 Problem Details — no ad-hoc status code decisions in handlers
- [ ] `switch (err.type)` has a `default: assertNever(err)` guard ensuring exhaustive handling
- [ ] Retry logic uses exponential backoff with jitter; only retries retryable error types
- [ ] `catch` blocks never empty; every catch handles, wraps, or logs + rethrows with context
- [ ] No stack traces in client-facing error responses; `instance` field carries a trace ID
- [ ] Zod parse errors are caught and mapped to `AppError.VALIDATION` before reaching callers
