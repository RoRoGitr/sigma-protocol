---
name: api-design-principles
description: "TypeScript API design — tRPC v11, ts-rest, oRPC, OpenAPI 3.1, Zod 4, REST resource naming, error envelopes (RFC 9457), versioning, cursor pagination, and idempotency keys. Use when designing or reviewing an API contract, wiring typed client-server communication, or authoring OpenAPI specs. Triggers on 'api design', 'rest api', 'trpc', 'ts-rest', 'orpc', 'openapi', 'api contract', 'zod schema', 'pagination', 'idempotency key', 'api versioning'."
department: engineering
triggers:
  - api design
  - rest api
  - trpc
  - ts-rest
  - orpc
  - openapi
  - api contract
  - zod schema
  - pagination
  - idempotency key
  - api versioning
  - step-2-architecture
  - step-8-technical-spec
---

# API Design Principles

TypeScript API stack for 2026: tRPC, ts-rest, oRPC, OpenAPI 3.1, Zod 4. Covers REST resource design, typed RPC contracts, error envelopes, versioning, pagination, and idempotency.

> Reference snapshot, 2026-06-05: tRPC 11.17, ts-rest 3.52, oRPC 1.14, Zod 4.4. Choose the project's declared contract and validation versions before using version-specific APIs; this snapshot is not an upgrade instruction.

## When to Use

- Designing or reviewing API endpoints (Steps 2, 8)
- Choosing between tRPC / ts-rest / oRPC / plain REST
- Wiring a typed contract between a TS server and client
- Authoring or updating an OpenAPI 3.1 spec
- Implementing pagination, versioning, or idempotency

## When NOT to Use

- Pure frontend component work — use `frontend-design`
- Database schema design — out of scope here (see your ORM's docs, e.g. Prisma / Drizzle)
- Error handling implementation specifics — use `error-handling-patterns`

## Approach Selection

| Situation | Best Fit | Why |
|-----------|----------|-----|
| Full-stack TypeScript, same repo | **tRPC v11** | End-to-end type inference, no codegen step |
| TS server + non-TS client, or OpenAPI required | **ts-rest** | Contract-first, OpenAPI-compatible, framework-agnostic |
| Public HTTP API, strict REST, multi-language clients | **REST + OpenAPI 3.1** | Broadest interop |
| Experimental / minimalist RPC | **oRPC** | Tiny, type-safe, no router overhead (evaluate maturity first) |

## Key Patterns

### tRPC v11 router

tRPC v11 ships a stable `initTRPC` API with middleware composition and `createCallerFactory` for server-side calls.

```ts
// server/trpc.ts
import { initTRPC } from '@trpc/server';
import { z } from 'zod/v4';    // Zod 4: import from 'zod/v4' sub-path

const t = initTRPC.context<{ userId: string | null }>().create();

export const router = t.router;
export const publicProcedure = t.procedure;
export const authedProcedure = t.procedure.use(({ ctx, next }) => {
  if (!ctx.userId) throw new TRPCError({ code: 'UNAUTHORIZED' });
  return next({ ctx: { userId: ctx.userId } });  // narrows type
});

// server/routers/orders.ts
import { router, authedProcedure } from '../trpc';
import { z } from 'zod/v4';

const CreateOrderInput = z.object({
  items: z.array(z.object({ productId: z.string(), qty: z.int().positive() })),
  idempotencyKey: z.string().uuid().optional(),
});

export const ordersRouter = router({
  create: authedProcedure
    .input(CreateOrderInput)
    .mutation(async ({ ctx, input }) => {
      // idempotency: check store before creating
      if (input.idempotencyKey) {
        const prior = await idempotencyStore.get(input.idempotencyKey);
        if (prior) return prior as Order;
      }
      const order = await db.order.create({ data: { userId: ctx.userId, ...input } });
      if (input.idempotencyKey) {
        await idempotencyStore.set(input.idempotencyKey, order, { ttlMs: 86_400_000 });
      }
      return order;
    }),

  list: authedProcedure
    .input(z.object({ cursor: z.string().optional(), limit: z.int().min(1).max(100).default(20) }))
    .query(async ({ ctx, input }) => {
      const items = await db.order.findMany({
        where: { userId: ctx.userId },
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
        orderBy: { createdAt: 'desc' },
      });
      const hasMore = items.length > input.limit;
      return {
        items: items.slice(0, input.limit),
        nextCursor: hasMore ? items[input.limit - 1].id : null,
        hasMore,
      };
    }),
});
```

### Zod 4 — key API changes vs Zod 3

Zod 4 is a breaking release. Import from the `zod/v4` sub-path to opt in; `zod` (the root) is a compatibility shim during the migration window.

```ts
// Zod 4: explicit sub-path import
import { z } from 'zod/v4';

// NEW in v4: z.int(), z.email(), z.url() as first-class primitives
const CreateUserInput = z.object({
  email:    z.email(),                     // not z.string().email()
  age:      z.int().min(0).max(150),       // not z.number().int()
  website:  z.url().optional(),
  role:     z.enum(['admin', 'member']),
});

// NEW in v4: z.toJSONSchema() built-in (no more zod-to-json-schema dep)
const jsonSchema = z.toJSONSchema(CreateUserInput);

// Zod 4: error.flatten() instance method is unchanged from v3;
// the z.flattenError() static utility was removed.
try {
  CreateUserInput.parse(raw);
} catch (err) {
  if (err instanceof z.ZodError) {
    const flat = err.flatten();  // { fieldErrors, formErrors }
  }
}

// REMOVED in v4: z.string().nonempty() → use z.string().min(1)
```

### ts-rest contract (OpenAPI-compatible)

ts-rest defines contracts independent of framework, generates OpenAPI 3.1, and is usable from Express, Fastify, Next.js, or React Query.

```ts
// contracts/orders.ts
import { initContract } from '@ts-rest/core';
import { z } from 'zod/v4';

const c = initContract();

export const ordersContract = c.router({
  create: {
    method: 'POST',
    path: '/v1/orders',
    headers: z.object({ 'idempotency-key': z.string().uuid().optional() }),
    body: z.object({
      items: z.array(z.object({ productId: z.string(), qty: z.int().positive() })),
    }),
    responses: {
      201: z.object({ id: z.string(), status: z.string(), total: z.number() }),
      409: z.object({ type: z.string(), title: z.string(), status: z.literal(409) }),
      422: z.object({ type: z.string(), title: z.string(), status: z.literal(422), errors: z.array(z.any()) }),
    },
    summary: 'Create an order',
  },

  list: {
    method: 'GET',
    path: '/v1/orders',
    query: z.object({
      cursor: z.string().optional(),
      limit:  z.coerce.number().min(1).max(100).default(20),
    }),
    responses: {
      200: z.object({
        items:      z.array(z.any()),
        nextCursor: z.string().nullable(),
        hasMore:    z.boolean(),
      }),
    },
  },
});

// server/routes/orders.ts (Express adapter)
import { createExpressEndpoints } from '@ts-rest/express';
import { ordersContract } from '../contracts/orders';

createExpressEndpoints(ordersContract, {
  create: async ({ headers, body }) => {
    // idempotency key from headers['idempotency-key']
    const order = await orderService.create(body, headers['idempotency-key']);
    return { status: 201, body: order };
  },
  list: async ({ query }) => {
    const result = await orderService.list(query);
    return { status: 200, body: result };
  },
}, app);
```

### REST resource naming

```
Resources are nouns (plural). HTTP method is the verb.

GET    /v1/users                     — list users
GET    /v1/users/{id}                — get one user
POST   /v1/users                     — create user
PUT    /v1/users/{id}                — replace user
PATCH  /v1/users/{id}                — partial update
DELETE /v1/users/{id}                — delete user
GET    /v1/users/{id}/orders         — user's orders (max 2 nesting levels)

Never:
POST   /v1/createUser
GET    /v1/getUserById/{id}
GET    /v1/users/{id}/orders/{oid}/items/{iid}/history/events/recent   (too deep)
```

### Error envelope — RFC 9457 Problem Details

All error responses follow RFC 9457. Never return raw stack traces.

```ts
interface ProblemDetail {
  type:     string;   // URI identifying the problem type
  title:    string;   // human-readable summary (stable per type)
  status:   number;   // HTTP status code
  detail:   string;   // specific occurrence description
  instance: string;   // request trace URI, e.g. /errors/trace/{traceId}
  // custom extensions allowed:
  errors?:  Array<{ field: string; message: string; code: string }>;
}

// Example 422
{
  "type":     "https://api.example.com/problems/validation-error",
  "title":    "Validation Error",
  "status":   422,
  "detail":   "Request body failed schema validation.",
  "instance": "/errors/trace/01HZ9P3KXRV2MABN",
  "errors":   [{ "field": "email", "message": "Must be a valid email address.", "code": "invalid_email" }]
}
```

### Versioning

URL path versioning for public APIs. Header versioning for internal services.

```
Public:   GET /v1/orders   → GET /v2/orders   (never break v1 without a version bump)
Internal: GET /orders  +  Accept: application/vnd.company.v2+json

Deprecation header:
Deprecation: Tue, 01 Jul 2025 00:00:00 GMT
Sunset:      Tue, 01 Jan 2026 00:00:00 GMT
Link: </v2/orders>; rel="successor-version"
```

### Cursor pagination (default for collections)

Cursor pagination is correct for most APIs. Offset pagination only when the dataset is static or full-table export is required.

```ts
// Shared response shape
interface CursorPage<T> {
  items:      T[];
  nextCursor: string | null;   // base64url-encoded opaque cursor
  hasMore:    boolean;
  total?:     number;          // expensive — omit unless the client needs it
}

// Generating the cursor (stable sort by createdAt + id)
const cursor = Buffer.from(JSON.stringify({ createdAt: lastItem.createdAt, id: lastItem.id }))
  .toString('base64url');

// Consuming the cursor
const decoded = JSON.parse(Buffer.from(cursor, 'base64url').toString());
where = { OR: [
  { createdAt: { lt: decoded.createdAt } },
  { createdAt: decoded.createdAt, id: { lt: decoded.id } },
]};
```

### Idempotency keys

POST and PATCH mutations that are not naturally idempotent must accept an `Idempotency-Key` header.

```ts
// Middleware — store key before executing, return cached response on replay
async function idempotencyMiddleware(req, res, next) {
  const key = req.headers['idempotency-key'];
  if (!key) return next();

  const cached = await idempotencyStore.get(key);
  if (cached) {
    return res.status(cached.status).set(cached.headers).json(cached.body);
  }

  // Intercept and store
  const originalJson = res.json.bind(res);
  res.json = (body) => {
    idempotencyStore.set(key, { status: res.statusCode, headers: res.getHeaders(), body }, {
      ttlMs: 86_400_000,  // 24 hours
    });
    return originalJson(body);
  };

  next();
}
```

## Anti-Patterns

- Verbs in URL paths — `POST /createOrder` instead of `POST /v1/orders`
- No versioning from day one — breaking changes with no migration path
- Offset pagination for live data — pages shift as rows insert; use cursor
- Returning a bare 200 with `{ "error": "not found" }` in the body — use 404 + RFC 9457
- Returning raw stack traces in error responses — client gets internal implementation details
- Skipping idempotency keys on payment/mutation endpoints — retries cause double-charges
- Zod 3 patterns in a Zod 4 project — `z.string().email()` still works via shim but `z.int()` is the correct v4 form

## Quality Gates

- [ ] URL paths are nouns, plural, max two nesting levels deep
- [ ] All collection endpoints return cursor-based pagination with `nextCursor` + `hasMore`
- [ ] Error responses follow RFC 9457 (type, title, status, detail, instance)
- [ ] All POST/PATCH mutations that are not inherently idempotent accept `Idempotency-Key`
- [ ] API versioned at `/v1/` from day one; deprecation headers set when a version is sunsetted
- [ ] Zod 4 imports use `from 'zod/v4'`; no `z.string().email()` — use `z.email()`
- [ ] tRPC procedures use `.use()` middleware for auth, never check auth inside business logic
- [ ] ts-rest responses cover all expected error status codes in the contract
- [ ] `EXPLAIN ANALYZE` run on any query backing a paginated list endpoint
- [ ] Rate limit headers returned: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
