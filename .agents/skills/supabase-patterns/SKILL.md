---
name: supabase-patterns
description: "Supabase production patterns — Row Level Security (RLS performance, multi-tenant, Auth Hooks, MFA), supabase-js v2 client, Edge Functions (Deno 2.1), Realtime v2, pgvector / HNSW semantic search, and migrations + branching. Use when building, securing, or operating a Supabase-backed application. Triggers on 'supabase', 'row level security', 'rls', 'supabase auth', 'supabase rls', 'edge function', 'deno', 'realtime', 'pgvector', 'hnsw', 'supabase migration', 'supabase branch', 'auth hook', 'mfa', 'totp', 'supabase storage', 'postgres changes', 'supabase cli'."
department: engineering
triggers:
  - supabase
  - row level security
  - rls
  - supabase auth
  - supabase rls
  - edge function
  - deno
  - realtime
  - pgvector
  - hnsw
  - supabase migration
  - supabase branch
  - auth hook
  - mfa
  - totp
  - supabase storage
  - postgres changes
  - supabase cli
  - auth.uid
  - anon key
  - service role
---

# Supabase Patterns

Production-grade Supabase patterns across all major surfaces: RLS security + performance, Auth Hooks, MFA/TOTP, Edge Functions (Deno 2.1), Realtime v2, pgvector/HNSW semantic search, and migrations + branching.

> Version anchor: supabase-js v2.107.0, supabase CLI v2.105.0, pgvector 0.8.0+, Deno 2.1 (Edge runtime), Realtime v2 GA. Verified 2026-06-04.

For the `handle_new_user` trigger failure mode specifically, also see the `supabase-auth-signup-debugging` skill (SQLSTATE table, migration repair commands, direct admin user creation).

## When to Use

- Writing or auditing RLS policies for correctness and performance
- Implementing auth hooks (custom access token, MFA, password)
- Building Edge Functions in Deno 2.1
- Setting up Realtime subscriptions at scale
- Adding vector search with HNSW indexes
- Managing migrations, declarative schema, and preview branches

## When NOT to Use

- Choosing between Supabase vs Convex — architecture decision, not a coding pattern
- Pure React/TS client code with no Supabase calls

---

## 1. RLS Performance and Security

### The InitPlan Trick — 171 ms → < 0.1 ms

Wrapping `auth.uid()` in `(select auth.uid())` causes PostgreSQL to evaluate it once per statement (InitPlan) instead of once per row (correlated subquery). Benchmark from production: 171 ms → < 0.1 ms on a 500 k-row table.

```sql
-- ❌  Slow: auth.uid() called once per row
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = user_id);

-- ✅  Fast: evaluated once per statement
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
```

### Essential Policy Template

```sql
-- ENABLE + FORCE (table-owner bypass requires both)
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts FORCE ROW LEVEL SECURITY;

-- SELECT
CREATE POLICY "posts_select_own" ON public.posts
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = author_id);

-- INSERT
CREATE POLICY "posts_insert_own" ON public.posts
  FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = author_id);

-- UPDATE — supply BOTH USING and WITH CHECK
-- Without USING: UPDATE silently returns 0 rows.
-- Without WITH CHECK: user can transfer row ownership to another user.
CREATE POLICY "posts_update_own" ON public.posts
  FOR UPDATE TO authenticated
  USING  ((select auth.uid()) = author_id)
  WITH CHECK ((select auth.uid()) = author_id);

-- DELETE
CREATE POLICY "posts_delete_own" ON public.posts
  FOR DELETE TO authenticated
  USING ((select auth.uid()) = author_id);
```

### Multi-Tenant Isolation

Store `org_id` in `app_metadata` (not `user_metadata` — users can write that). Use the Custom Access Token hook (§2) to embed the claim at mint time. The JWT cache is 1 hour — membership revocation takes up to 1 hour to propagate.

```sql
-- Read org_id from the JWT claim (not from a join)
CREATE POLICY "resources_org_scoped" ON public.resources
  FOR SELECT TO authenticated
  USING (
    org_id = (select (auth.jwt() ->> 'app_metadata')::jsonb ->> 'org_id')
  );
```

### SECURITY DEFINER Functions

Use when a policy requires joining 3+ tables or running > 100 ms. The `search_path = ''` hardening prevents search-path injection.

```sql
CREATE OR REPLACE FUNCTION public.user_has_access(resource_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''       -- required; prevents search-path injection
AS $$
DECLARE result boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM public.memberships m
    JOIN public.resources r ON r.org_id = m.org_id
    WHERE m.user_id = auth.uid() AND r.id = resource_id
  ) INTO result;
  RETURN result;
END;
$$;

-- Use in a policy
CREATE POLICY "resources_select" ON public.resources
  FOR SELECT TO authenticated USING (public.user_has_access(id));
```

### Debugging RLS Locally

```sql
-- Test a policy as a specific user (in a transaction — safe to rollback)
BEGIN;
  SET LOCAL role = authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "user-uuid-here", "app_metadata": {"org_id": "org-123"}}';
  EXPLAIN ANALYZE SELECT * FROM public.posts WHERE author_id = 'user-uuid-here';
ROLLBACK;
```

---

## 2. Auth Hooks

**Permission wiring is mandatory** — failing to do this exposes the hook via the public API.

```sql
-- Grant execute to supabase_auth_admin (called by the auth system)
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;

-- Revoke from public-facing roles (security requirement)
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;
```

### Custom Access Token Hook — Embed org_id at Mint Time

```sql
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  claims   jsonb;
  org_id   text;
BEGIN
  claims := event -> 'claims';

  -- Look up the user's org membership
  SELECT m.org_id::text
  INTO org_id
  FROM public.memberships m
  WHERE m.user_id = (event ->> 'user_id')::uuid
  LIMIT 1;

  -- Inject into app_metadata (persisted in the JWT)
  IF org_id IS NOT NULL THEN
    claims := jsonb_set(claims, '{app_metadata,org_id}', to_jsonb(org_id));
  END IF;

  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

-- Save as a migration so it deploys consistently
```

Configure in Dashboard → Authentication → Hooks → Custom Access Token.

### MFA Verification Attempt Hook — Rate-Limit Bad Codes

```sql
CREATE OR REPLACE FUNCTION public.mfa_verification_attempt_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE attempts int;
BEGIN
  SELECT count(*) INTO attempts
  FROM public.mfa_failed_verification_attempts
  WHERE user_id = (event ->> 'user_id')::uuid
    AND factor_id = (event ->> 'factor_id')::uuid
    AND created_at > now() - interval '15 minutes';

  IF attempts >= 5 THEN
    RETURN jsonb_build_object('error', jsonb_build_object(
      'http_code', 429,
      'message', 'Too many failed attempts. Try again in 15 minutes.'
    ));
  END IF;

  IF NOT (event ->> 'valid')::boolean THEN
    INSERT INTO public.mfa_failed_verification_attempts(user_id, factor_id)
    VALUES ((event ->> 'user_id')::uuid, (event ->> 'factor_id')::uuid);
  END IF;

  RETURN event;
END;
$$;
```

---

## 3. MFA / TOTP

```ts
import { createClient } from "@supabase/supabase-js";
const supabase = createClient(url, anonKey);

// Step 1: Enroll a TOTP factor
const { data: enroll } = await supabase.auth.mfa.enroll({ factorType: "totp", friendlyName: "Authenticator" });
// enroll.totp.qr_code — show this QR to the user
// enroll.id          — factor ID, save for challenge/verify

// Step 2: Verify the enrollment (user scans QR, enters first code)
const { data: challenge } = await supabase.auth.mfa.challenge({ factorId: enroll.id });
const { data: verify }    = await supabase.auth.mfa.verify({ factorId: enroll.id, challengeId: challenge.id, code: totpCode });
```

**Enforce AAL2 via a restrictive RLS policy** — use `AS RESTRICTIVE` so permissive policies cannot bypass it:

```sql
-- Applies to ALL users; permissive policies cannot override this
CREATE POLICY "require_aal2_for_sensitive_data" ON public.financial_records
  AS RESTRICTIVE
  FOR ALL TO authenticated
  USING (
    (select (auth.jwt() -> 'aal')::text) = '"aal2"'
  );
```

**Check assurance level in application code:**

```ts
const { data: { currentLevel, nextLevel } } = await supabase.auth.mfa.getAuthenticatorAssuranceLevel();
if (currentLevel !== "aal2" && nextLevel === "aal2") {
  // redirect to MFA challenge page
}
```

---

## 4. Edge Functions (Deno 2.1)

### Project Structure

```
supabase/functions/
  deno.json              ← import map (NOT deprecated import_map.json)
  _shared/
    supabase.ts          ← client factory (forward Auth header or use service role)
    cors.ts              ← OPTIONS preflight helper
  my-function/
    index.ts
```

```jsonc
// supabase/functions/deno.json
{
  "imports": {
    "@supabase/supabase-js": "jsr:@supabase/supabase-js@2.107.0",
    "std/":                  "jsr:@std/std@0.224.0/"
  }
}
```

```ts
// supabase/functions/_shared/supabase.ts
import { createClient } from "@supabase/supabase-js";

/** Forward user's JWT — respects RLS */
export function getClient(req: Request) {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
}

/** Bypass RLS — server-side writes only */
export function getAdminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}
```

### Hub Pattern — One Function, Multiple Actions

```ts
// supabase/functions/payments/index.ts
import { getClient } from "../_shared/supabase.ts";

const ok  = (data: unknown)  => new Response(JSON.stringify(data),  { status: 200, headers: { "Content-Type": "application/json" } });
const err = (msg: string, s = 400) => new Response(JSON.stringify({ error: msg }), { status: s });

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" } });
  }

  const { action, ...params } = await req.json();

  if (action === "createIntent")   return ok(await createPaymentIntent(req, params));
  if (action === "confirmPayment") return ok(await confirmPayment(req, params));
  if (action === "getHistory")     return ok(await getPaymentHistory(req, params));

  return err("Unknown action");
});
```

**Deploy:** `supabase functions deploy payments --use-api` (no Docker required with Deno 2.1 runtime).

**Rule:** forwarded-JWT client for user-facing reads; service-role client only for writes that must bypass RLS (e.g., webhook receivers). Never expose the service-role key to the browser.

---

## 5. Realtime v2

### Broadcast (ephemeral, low-latency)

```ts
const channel = supabase.channel("room:xyz");

channel
  .on("broadcast", { event: "cursor" }, (payload) => { updateCursor(payload.x, payload.y); })
  .subscribe();

// Send to all subscribers in the channel
channel.send({ type: "broadcast", event: "cursor", payload: { x: 100, y: 200 } });
```

### Presence (CRDT state per participant)

```ts
const channel = supabase.channel("room:xyz", { config: { presence: { key: userId } } });

channel
  .on("presence", { event: "sync" },  () => { const state = channel.presenceState(); /* render */ })
  .on("presence", { event: "join" },  ({ newPresences }) => { /* user joined */ })
  .on("presence", { event: "leave" }, ({ leftPresences }) => { /* user left */ })
  .subscribe(async (status) => {
    if (status === "SUBSCRIBED") await channel.track({ online_at: new Date().toISOString() });
  });
```

### Postgres Changes

```ts
supabase.channel("db-changes")
  .on("postgres_changes", { event: "INSERT", schema: "public", table: "orders", filter: `user_id=eq.${userId}` },
    (payload) => { /* handle the change — update UI / cache / state */ })
  .subscribe();
```

**Scale warning:** at 100 subscribers + 1 INSERT/s, Postgres Changes causes 100 DB reads/s (one RLS check per subscriber per event). For high-throughput tables use a public table (no RLS) with a Postgres trigger that calls `realtime.send()` to re-broadcast — one write, server-side fan-out:

```sql
CREATE OR REPLACE FUNCTION notify_order_created()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM realtime.send(
    jsonb_build_object('type', 'INSERT', 'record', row_to_json(NEW)),
    'broadcast',
    'orders:' || NEW.user_id::text
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER order_created_notify
  AFTER INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION notify_order_created();
```

**Private channels** require Realtime Authorization (RLS on `realtime.messages`). Public channels bypass it — set project to private-only if all channels need authorization.

**Replica identity** — add `ALTER TABLE public.orders REPLICA IDENTITY FULL;` to receive `old` record on UPDATE/DELETE events.

---

## 6. pgvector / Semantic Search

### Index Decision

| Scenario | Choose |
|----------|--------|
| New project, any table size | **HNSW** (no training step, safe on empty table, better recall) |
| Memory-constrained, < 1 M rows | IVFFlat |

```sql
-- HNSW index (m=16 default, ef_construction=64 default)
CREATE INDEX ON public.documents
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Half-precision for OpenAI text-embedding-3-small / text-embedding-3-large (cuts storage in half)
ALTER TABLE public.documents ADD COLUMN embedding halfvec(1536);
CREATE INDEX ON public.documents
  USING hnsw (embedding halfvec_cosine_ops)
  WITH (m = 16, ef_construction = 64);
```

Always `CREATE INDEX CONCURRENTLY` in production to avoid table lock.

### Semantic Search Function (push filters inside, not outside)

```sql
-- ✅  Filters applied INSIDE the function — LIMIT is respected
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.75,
  match_count     int   DEFAULT 10,
  filter_org_id   uuid  DEFAULT NULL
)
RETURNS TABLE(id uuid, content text, similarity float)
LANGUAGE sql
AS $$
  SELECT id, content, 1 - (embedding <=> query_embedding) AS similarity
  FROM public.documents
  WHERE
    (filter_org_id IS NULL OR org_id = filter_org_id)
    AND 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY embedding <=> query_embedding
  LIMIT match_count;
$$;
```

**Anti-pattern:** chaining `.eq("org_id", orgId)` after `.rpc("match_documents", ...)` — PostgREST applies it as an outer filter AFTER the LIMIT, so you get fewer than `match_count` results.

### Distance Operators

| Operator | Metric | Best For |
|----------|--------|----------|
| `<->` | Euclidean | General use |
| `<#>` | Negative inner product | Normalized vectors (fastest) |
| `<=>` | Cosine | Safe default for text embeddings |

### Iterative Scans (pgvector 0.8.0+)

Prevents fewer-than-LIMIT results when the WHERE clause is selective:

```sql
SET hnsw.iterative_scan = relaxed_order;   -- allows small accuracy trade-off for completeness
SET hnsw.max_scan_tuples = 20000;          -- upper bound on tuples examined
```

### Automatic Embeddings Pipeline

```sql
-- Trigger clears the embedding column when source content changes
CREATE OR REPLACE FUNCTION queue_embedding_update()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.content IS DISTINCT FROM OLD.content THEN
    NEW.embedding := NULL;   -- marks as stale; the cron job regenerates it
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER documents_content_changed
  BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION queue_embedding_update();
```

Pipeline: trigger marks row stale → pg_cron runs every 10 s → pg_net calls an Edge Function → Edge Function calls OpenAI → UPDATE sets `embedding`.

---

## 7. Migrations and Branching

### Declarative Schema (recommended workflow)

```
supabase/schemas/
  00_extensions.sql      -- CREATE EXTENSION IF NOT EXISTS pgvector
  01_users.sql           -- table definitions
  02_posts.sql
  03_rls.sql             -- all RLS policies in one file
  04_functions.sql       -- Postgres functions and triggers
```

Order in `supabase/config.toml`:

```toml
[db]
schema_paths = [
  "./schemas/00_extensions.sql",
  "./schemas/01_users.sql",
  "./schemas/02_posts.sql",
  "./schemas/03_rls.sql",
  "./schemas/04_functions.sql",
]
```

Generate a versioned migration from schema diff:

```bash
supabase db diff --schema public -f add_posts_table   # writes supabase/migrations/<timestamp>_add_posts_table.sql
supabase migration up                                  # apply locally
supabase db push                                       # apply to linked remote project
```

### Migration Discipline

```bash
# Never edit the remote DB via Dashboard — it breaks migration history
# One db push at a time — concurrent pushes conflict

# Pull remote drift (remote-first projects)
supabase db pull

# After merges, reset local DB to apply all migrations cleanly
supabase db reset

# Rollback: generate a new "undo" migration — never edit an applied one
supabase migration new revert_add_posts_table

# Repair tracking table only (does not touch schema)
supabase migration repair --status applied 20260601120000
supabase migration repair --status reverted 20260601120000
```

### Regenerate TypeScript Types

```bash
supabase gen types typescript --local > src/lib/database.types.ts
# Commit the generated file; CI fails if git diff is non-empty after generation
```

### CI/CD Pattern

```yaml
# .github/workflows/supabase.yml
- name: Setup Supabase CLI
  uses: supabase/setup-cli@v1
  with: { version: 2.105.0 }

- name: Run migrations (staging)
  if: github.ref == 'refs/heads/develop'
  run: supabase db push --project-ref ${{ secrets.STAGING_PROJECT_REF }}

- name: Run migrations (production)
  if: github.ref == 'refs/heads/main'
  run: supabase db push --project-ref ${{ secrets.PROD_PROJECT_REF }}
```

### Branching (Preview Environments)

- **Preview branches:** ephemeral, auto-paused on inactivity, deleted when PR closes. Seed with `supabase/seed.sql`.
- **Persistent branches:** for staging / QA environments.
- Deploy sequence: clone remote → pull migrations → health check → configure → migrate → seed → deploy.

```bash
# Create a persistent branch for staging
supabase branches create staging --persistent
```

---

## Anti-Patterns

- `auth.uid()` without `(select ...)` wrapper — 171 ms tax on large tables
- `ENABLE ROW LEVEL SECURITY` without `FORCE` — table owner (postgres/service role) bypasses silently
- UPDATE policy with only `USING` and no `WITH CHECK` — user can transfer row ownership to another user
- Auth Hook function without `GRANT` to `supabase_auth_admin` / `REVOKE` from public roles — hook callable via public API
- `AS PERMISSIVE` for MFA enforcement — permissive policies are additive; use `AS RESTRICTIVE`
- Chaining `.eq()` after `.rpc()` for vector search filters — PostgREST applies it after LIMIT, defeating the LIMIT
- Deploying Edge Functions without `--use-api` flag — old Docker-based deploy is deprecated in Deno 2.1
- Editing `import_map.json` — replaced by `deno.json` in Deno 2.1; the old file is ignored
- Running `supabase db push` on a team without git pull + reset first — concurrent pushes produce drift
- `HNSW` index on a float-precision column for OpenAI embeddings — use `halfvec(1536)` to halve storage with negligible accuracy loss

## Quality Gates

- [ ] Every RLS policy uses `(select auth.uid())` not bare `auth.uid()`
- [ ] Every table has both `ENABLE` and `FORCE ROW LEVEL SECURITY`
- [ ] UPDATE policies have both `USING` and `WITH CHECK` clauses
- [ ] SECURITY DEFINER functions set `search_path = ''`
- [ ] Auth Hook functions have correct `GRANT`/`REVOKE` wiring
- [ ] MFA-enforcing policies use `AS RESTRICTIVE`
- [ ] Vector search filters pushed inside the SQL function, not chained after `.rpc()`
- [ ] `supabase gen types` output committed and verified in CI (git diff check)
- [ ] Edge Functions use `deno.json` import map with pinned versions
- [ ] Migrations are forward-only; destructive changes get a separate rollback migration
