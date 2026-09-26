---
name: convex
description: "Convex backend skill — schema, queries, mutations, actions, reactive useQuery, indexes, pagination, auth, file storage, scheduling, crons, Components system, convex-helpers (RLS, relationships, streams), agent and workflow components, and testing. Use when building, designing, or debugging a Convex backend. Triggers on 'convex', 'defineSchema', 'defineTable', 'convex query', 'convex mutation', 'convex action', 'useQuery', 'ctx.db', 'convex auth', 'convex cron', 'convex scheduler', 'convex component', 'convex deploy', 'npx convex', 'convex-helpers', 'customQuery', 'customMutation', 'convex agent', 'convex workflow'."
department: engineering
triggers:
  - convex
  - defineSchema
  - defineTable
  - convex query
  - convex mutation
  - convex action
  - useQuery
  - ctx.db
  - convex auth
  - convex cron
  - convex scheduler
  - convex component
  - convex deploy
  - npx convex
  - convex-helpers
  - customQuery
  - customMutation
  - convex agent
  - convex workflow
---

# Convex

Reactive backend platform: "functions are the API." Queries are subscriptions, mutations are ACID transactions, actions hit the outside world. No raw SQL — the query engine is reactive by design.

> Version anchor: convex@1.40.0, convex-helpers@0.1.118, @convex-dev/agent@0.6.2, @convex-dev/workflow@0.4.3, @convex-dev/rate-limiter@0.3.2. Verified 2026-06-04.

## When to Use

- Building or extending a Convex backend schema, functions, or cron jobs
- Designing reactive real-time data flows using `useQuery`
- Implementing auth, file storage, or scheduled work
- Adding RLS or relationship helpers via convex-helpers
- Wiring AI agents or durable multi-step workflows
- Testing Convex functions with convex-test

## When NOT to Use

- Choosing between Convex vs Supabase — that is an architecture decision, not a coding pattern
- Pure React or frontend state unrelated to the Convex subscription layer

---

## 1. Schema

```ts
// convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    clerkId: v.string(),
    email:   v.string(),
    role:    v.union(v.literal("admin"), v.literal("member")),
    profile: v.optional(v.object({ bio: v.string(), avatarUrl: v.string() })),
  })
    .index("by_clerkId", ["clerkId"])
    .index("by_email",   ["email"]),

  posts: defineTable({
    authorId: v.id("users"),
    title:    v.string(),
    body:     v.string(),
    status:   v.union(v.literal("draft"), v.literal("published")),
    tags:     v.array(v.string()),
  })
    .index("by_author_status", ["authorId", "status"]),
}, { schemaValidation: true });
```

**Validator composition** — reduce duplication between schema and arg validators:

```ts
const UserBase = v.object({ email: v.string(), role: v.union(v.literal("admin"), v.literal("member")) });
// UserBase.pick(["email"])  UserBase.omit(["role"])  UserBase.extend({ bio: v.optional(v.string()) })
```

**TypeScript helpers:**

```ts
import type { Doc, Id } from "./_generated/dataModel";
import type { Infer } from "convex/values";
import type { WithoutSystemFields } from "convex/server";

type User = Doc<"users">;                           // full row including _id, _creationTime
type NewUser = WithoutSystemFields<Doc<"users">>;   // for insert helpers
type Role = Infer<typeof UserBase>["role"];
```

**Explicit table names** on all db ops (mandatory since v1.31.0):

```ts
// ✅  ctx.db.get("users", id)
// ❌  ctx.db.get(id)          — will throw in projects with custom ID generation
```

---

## 2. Queries and Mutations

Both use `args:` + `returns:` validators. Both are required on every public function.

```ts
// convex/users.ts
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

export const getUser = query({
  args:    { id: v.id("users") },
  returns: v.union(v.object({ _id: v.id("users"), email: v.string(), role: v.string() }), v.null()),
  handler: async (ctx, { id }) => {
    return ctx.db.get("users", id);
  },
});

export const updateRole = mutation({
  args:    { id: v.id("users"), role: v.union(v.literal("admin"), v.literal("member")) },
  returns: v.null(),
  handler: async (ctx, { id, role }) => {
    const user = await ctx.db.get("users", id);
    if (!user) throw new Error(`User ${id} not found`);
    await ctx.db.patch("users", id, { role });
    return null;
  },
});
```

**Index queries** — always filter with `.withIndex()` before `.collect()`:

```ts
const posts = await ctx.db
  .query("posts")
  .withIndex("by_author_status", (q) => q.eq("authorId", authorId).eq("status", "published"))
  .order("desc")
  .take(20);           // never .collect() on an unbounded set
```

**Pagination:**

```ts
import { paginationOptsValidator } from "convex/server";

export const listPosts = query({
  args:    { paginationOpts: paginationOptsValidator },
  returns: v.any(),   // PaginationResult<Doc<"posts">>
  handler: async (ctx, { paginationOpts }) => {
    return ctx.db.query("posts").order("desc").paginate(paginationOpts);
  },
});
```

**Constraint:** never call `Date.now()` inside a query — queries must be deterministic. Use it in mutations or actions, or pass the timestamp as an argument.

---

## 3. Actions

Actions run outside the database transaction and can call third-party APIs, run AI models, or read/write files.

```ts
// convex/notifications.ts
import { action, internalMutation } from "./_generated/server";
import { internal } from "./_generated/api";
import { v } from "convex/values";

// ✅  Preferred pattern: mutation schedules action (writes intent, then schedules)
export const sendWelcomeEmail = internalMutation({
  args:    { userId: v.id("users") },
  returns: v.null(),
  handler: async (ctx, { userId }) => {
    await ctx.db.patch("users", userId, { welcomeQueued: true });
    await ctx.scheduler.runAfter(0, internal.notifications._sendEmail, { userId });
    return null;
  },
});

// Internal action — not callable from client
export const _sendEmail = action({
  args:    { userId: v.id("users") },
  returns: v.null(),
  handler: async (ctx, { userId }) => {
    const user = await ctx.runQuery(internal.users.getUser, { id: userId });
    await fetch("https://api.email.example.com/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ to: user?.email, template: "welcome" }),
    });
    return null;
  },
});
```

**Runtimes:** default = Convex runtime (10 min / 512 MB / 64 MB memory). Add `"use node";` at the top of the file for Node.js APIs (npm packages with native bindings, `Buffer`, `fs`, `child_process`).

**Anti-patterns:**
- Calling an action directly from a React client — use `mutation → schedules → action` instead.
- Calling `ctx.runMutation` + `ctx.runMutation` sequentially in an action — each call is a separate transaction; the action is NOT atomic. Write one mutation that performs both operations atomically.

---

## 4. Auth

```ts
// convex/auth.config.ts  (third-party JWT — Clerk, Auth0, custom)
export default {
  providers: [{
    domain:    "https://clerk.example.com",
    applicationID: "convex",
  }],
};
```

**Read identity in any function:**

```ts
const identity = await ctx.auth.getUserIdentity();
if (!identity) throw new Error("Unauthenticated");
const { subject, email, name } = identity;  // subject = provider user ID
```

**Auth injection via customQuery (convex-helpers — see §8):**

```ts
import { customQuery } from "convex-helpers/server/customFunctions";

const authQuery = customQuery(query, {
  args:    {},
  input:   async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");
    const user = await ctx.db.query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .unique();
    if (!user) throw new Error("User not found");
    return { ctx: { ...ctx, user } };   // user is now typed on ctx in every handler
  },
});

export const myData = authQuery({
  args:    {},
  returns: v.any(),
  handler: async (ctx) => ctx.db.query("posts")
    .withIndex("by_author_status", (q) => q.eq("authorId", ctx.user._id)),
});
```

**First-party auth library** — `@convex-dev/auth` (Magic Links / OTP / OAuth / Passwords without an external service). Install separately; see its docs for the `ConvexAuthProvider` setup and `useAuthActions` hook.

---

## 5. File Storage

```ts
// 3-step URL upload flow (for all file sizes)
// Step 1: Client requests a signed upload URL
export const generateUploadUrl = mutation({
  args: {}, returns: v.string(),
  handler: async (ctx) => ctx.storage.generateUploadUrl(),
});

// Step 2: Client POSTs file to the signed URL
// fetch(uploadUrl, { method: "POST", body: file, headers: { "Content-Type": file.type } })

// Step 3: Client saves the returned storageId
export const saveFile = mutation({
  args: { storageId: v.string(), ownerId: v.id("users") }, returns: v.null(),
  handler: async (ctx, { storageId, ownerId }) => {
    await ctx.db.insert("files", { storageId, ownerId });
    return null;
  },
});

// Retrieve a served URL (action or query)
const url = await ctx.storage.getUrl(storageId);   // returns string | null

// Delete on record removal
await ctx.storage.delete(storageId);
```

---

## 6. Scheduling and Crons

```ts
// ctx.scheduler — internal.* refs only, never api.*
await ctx.scheduler.runAfter(5_000, internal.jobs.processItem, { itemId });
await ctx.scheduler.runAt(new Date("2026-12-01"), internal.jobs.yearEndReport, {});

// Check or cancel a scheduled job
const job = await ctx.db.system.get(scheduledFunctionId);   // _scheduled_functions table
await ctx.scheduler.cancel(scheduledFunctionId);
```

```ts
// convex/crons.ts
import { cronJobs } from "convex/server";
import { internal } from "./_generated/api";

const crons = cronJobs();

crons.interval("clean expired sessions", { hours: 1 },    internal.sessions.cleanExpired, {});
crons.cron("daily digest",              "0 9 * * *",       internal.digest.send, { tz: "UTC" });
crons.daily("nightly snapshot",         { hourUTC: 3, minuteUTC: 0 }, internal.snapshots.take, {});

export default crons;
```

**Guarantees:** crons have at-most-once delivery per interval. If the function throws, the next run fires normally (no retry backoff by default — use convex-helpers action retries for that).

---

## 7. Components

The Components system (`convex.config.ts`) is the primary architecture for reusable backend modules.

```ts
// convex/convex.config.ts
import { defineApp } from "convex/server";
import agent from "@convex-dev/agent/convex.config";
import rateLimiter from "@convex-dev/rate-limiter/convex.config";

const app = defineApp();
app.use(agent,       { name: "agent" });
app.use(rateLimiter, { name: "rateLimiter" });
export default app;
```

```ts
// convex/chat.ts — access component functions via the components object
import { components } from "./_generated/api";
import { mutation } from "./_generated/server";
import { v } from "convex/values";

export const sendMessage = mutation({
  args:    { threadId: v.string(), content: v.string() },
  returns: v.null(),
  handler: async (ctx, { threadId, content }) => {
    await ctx.runMutation(components.rateLimiter.limit, { name: "chat", key: threadId });
    await ctx.db.insert("messages", { threadId, content });
    return null;
  },
});
```

**Transaction semantics:** component mutations share the top-level transaction. A component exception rolls back only the component's own writes unless the exception is re-thrown from the parent function (which rolls back everything).

---

## 8. convex-helpers

Install: `npm i convex-helpers`

```ts
import { customQuery, customMutation } from "convex-helpers/server/customFunctions";
import { wrapDatabaseReader, wrapDatabaseWriter } from "convex-helpers/server/rowLevelSecurity";
import type { Rules, DataModel } from "convex-helpers/server/rowLevelSecurity";
import { getAll, getOneFrom, getManyFrom, getManyVia } from "convex-helpers/server/relationships";
import { stream } from "convex-helpers/server/stream";
import { paginator } from "convex-helpers/server/pagination";
```

### Row-Level Security

```ts
// convex/lib/withRLS.ts
const rules: Rules<{ userId: Id<"users"> }, DataModel> = {
  users:    { read: async (ctx, doc) => doc._id === ctx.userId, modify: async (ctx, doc) => doc._id === ctx.userId },
  posts:    { read: async (ctx, doc) => doc.status === "published" || doc.authorId === ctx.userId },
  _default: "deny",   // fail-closed — blocks any table not explicitly listed
};

export function withUserRLS(ctx: GenericQueryCtx, userId: Id<"users">) {
  return {
    ...ctx,
    db: wrapDatabaseReader({ userId }, ctx.db, rules),
  };
}
```

### Relationship Helpers

```ts
// One-to-one
const profile = await getOneFrom(ctx.db, "profiles", "by_userId", user._id, "userId");

// One-to-many
const posts = await getManyFrom(ctx.db, "posts", "by_authorId", user._id, "authorId");

// Many-to-many via junction table
const tags = await getManyVia(ctx.db, "postTags", "by_postId", "tagId", post._id, "postId");

// Batch get (replaces N individual db.get calls)
const users = await getAll(ctx.db, "users", userIds);
```

### Streams (complex paginated joins)

```ts
import { stream, mergedStream } from "convex-helpers/server/stream";

// Merge two ordered streams into one (e.g., direct + group messages, sorted by time)
const combined = mergedStream(
  stream(ctx.db, schema).query("directMessages").withIndex("by_time").order("asc"),
  stream(ctx.db, schema).query("groupMessages").withIndex("by_time").order("asc"),
  (a, b) => a.sentAt - b.sentAt,
);

const page = await combined.paginate(paginationOpts);
```

---

## 9. Agent Component (@convex-dev/agent 0.6.2, AI SDK v6)

```ts
// convex/convex.config.ts — already shown in §7
// convex/aiAgent.ts
import { Agent } from "@convex-dev/agent";
import { components } from "./_generated/api";
import { openai } from "@ai-sdk/openai";
import { action, mutation } from "./_generated/server";
import { v } from "convex/values";

const supportAgent = new Agent(components.agent, {
  model:          openai("gpt-4o"),
  embeddingModel: openai.embedding("text-embedding-3-small"),
  instructions:   "You are a helpful support agent.",
});

export const createThread = mutation({
  args: { title: v.string() }, returns: v.object({ threadId: v.string() }),
  handler: async (ctx, { title }) => {
    const { threadId } = await supportAgent.createThread(ctx, components.agent, { title });
    return { threadId };
  },
});

export const chat = action({
  args: { threadId: v.string(), message: v.string() }, returns: v.string(),
  handler: async (ctx, { threadId, message }) => {
    const { text } = await supportAgent.continueThread(ctx, components.agent, {
      threadId,
      messages: [{ role: "user", content: message }],
    });
    return text;
  },
});
```

**AI SDK v6 breaking changes:** tool `args` renamed to `input`; `mimeType` renamed to `mediaType`. Tool approval: check `needsApproval` on the result, then call `approveToolCall` or `denyToolCall`.

---

## 10. Workflow Component (@convex-dev/workflow 0.4.3)

Durable multi-step workflows. Each step is checkpointed — a restart resumes from the last completed step.

```ts
// convex/convex.config.ts — app.use(workflow, { name: "workflow" });
import { WorkflowManager } from "@convex-dev/workflow";
import { components } from "./_generated/api";
import { v } from "convex/values";

const workflow = new WorkflowManager(components.workflow);

export const onboardUser = workflow.define({
  args:    { userId: v.id("users") },
  handler: async (step, { userId }) => {
    await step.runMutation(internal.users.setStatus, { userId, status: "onboarding" });
    await step.sleep(24 * 60 * 60 * 1000);                                   // wait 24 hours
    const verified = await step.runQuery(internal.users.isEmailVerified, { userId });
    if (!verified) {
      await step.runMutation(internal.email.sendReminder, { userId });
    }
    await step.runMutation(internal.users.setStatus, { userId, status: "active" });
  },
});

// Start a workflow from a mutation
const workflowId = await workflow.start(ctx, components.workflow, internal.workflows.onboardUser, { userId });
```

---

## 11. Testing (convex-test + vitest)

```ts
// convex/users.test.ts
import { convexTest } from "convex-test";
import { expect, test } from "vitest";
import { api } from "./_generated/api";
import schema from "./schema";
import * as modules from "./_generated/server";

test("getUser returns null for missing id", async () => {
  const t = convexTest(schema, modules);
  const result = await t.query(api.users.getUser, { id: "jh7abc123" as any });
  expect(result).toBeNull();
});

test("updateRole mutates the user", async () => {
  const t = convexTest(schema, modules);
  const userId = await t.mutation(api.users.createUser, { email: "a@b.com", role: "member" });
  await t.mutation(api.users.updateRole, { id: userId, role: "admin" });
  const user = await t.query(api.users.getUser, { id: userId });
  expect(user?.role).toBe("admin");
});

// Run arbitrary db operations inside t.run for setup/teardown
test("component test with agent", async () => {
  const t = convexTest(schema, modules);
  // Component test modules are registered via the modules glob passed to convexTest above
  // (there is no global agentTest helper — see each component's testing docs for its setup).
  await t.run(async (ctx) => {
    const thread = await ctx.db.insert("threads", { title: "test" });
    expect(thread).toBeTruthy();
  });
});
```

---

## Anti-Patterns

- `ctx.db.get(id)` without a table name — throws in projects with custom ID generation (v1.31.0+)
- Missing `returns:` validator — skips runtime shape enforcement and loses inferred TS return type
- `.collect()` on an unbounded query — counts bandwidth even if you filter in JS afterward; use `.withIndex()` first
- Calling an action from a React client directly — the client can call it twice on retry; prefer `mutation → scheduler.runAfter(0, ...)` 
- Sequential `ctx.runMutation` calls inside an action — each is a separate transaction; use one mutation for atomic writes
- Using `api.*` in `ctx.scheduler` — scheduler requires `internal.*` refs only
- `Date.now()` inside a query — queries must be deterministic; read timestamps from mutation args or `ctx` context

## Quality Gates

- [ ] `returns:` validator on every public query, mutation, and action
- [ ] Explicit table name on every `ctx.db.get`, `ctx.db.patch`, `ctx.db.replace`, `ctx.db.delete`
- [ ] `.withIndex()` filters applied before `.collect()` or `.take()` on any hot-path query
- [ ] `internal.*` used exclusively in `ctx.scheduler` and `crons` — never `api.*`
- [ ] No direct action calls from React client on mutation paths — mutation schedules the action
- [ ] RLS implemented via `wrapDatabaseReader/Writer` with `_default: "deny"` if user-scoped data exists
- [ ] `convex dev` generates clean `_generated/` before `convex deploy`
- [ ] New Components declared in `convex.config.ts` and accessed only via `components` object
