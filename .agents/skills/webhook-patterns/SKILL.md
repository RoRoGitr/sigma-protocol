---
name: webhook-patterns
description: "Receiving webhooks safely in TypeScript: HMAC signature verification, idempotency keys with a dedupe store, fast-ack + async processing, retry/backoff, dead-letter queues, ordering, replay protection, and timeouts. Use when implementing a webhook receiver endpoint or auditing an existing one. Triggers on 'webhook', 'webhook handler', 'hmac', 'signature verification', 'webhook idempotency', 'webhook retry', 'dead letter', 'replay protection'."
department: engineering
triggers:
  - webhook
  - webhook handler
  - hmac signature
  - signature verification
  - webhook idempotency
  - webhook retry
  - dead letter
  - replay protection
  - webhook processing
---

# Webhook Patterns

Receiving webhooks safely and reliably: signature verification, idempotency, fast-ack + async processing, retry/backoff, dead-letter, ordering, and replay protection.

> Snippets assume an injected `logger` (e.g. pino) and a `db` client (e.g. Prisma) in scope.

## When to Use

- Implementing a webhook receiver for any third-party service
- Auditing an existing webhook handler for reliability gaps
- Designing the queue/worker split for heavy webhook processing

## When NOT to Use

- Sending outgoing webhooks to downstream consumers — the patterns here are for receivers
- Billing-specific webhook logic — use `billing-patterns`

## The Four Invariants

Every production webhook receiver must satisfy four invariants:

1. **Only accept signed requests** — reject unsigned or tampered events at the network boundary
2. **Process each event exactly once** — idempotency store deduplicates at-least-once delivery
3. **Respond 200 fast** — ack within 3s (most providers have a 5–30s timeout); do the work asynchronously
4. **Never lose an event** — dead-letter queue captures events that exhaust all retries

## Key Patterns

### HMAC signature verification

Signature verification is the first operation — do it before reading the body into any data structure.

```ts
// lib/webhook-verify.ts
import { createHmac, timingSafeEqual } from 'node:crypto';

interface VerifyOptions {
  secret:    string;
  tolerance: number;  // max age of the timestamp in seconds
}

export function verifyWebhookSignature(
  rawBody:   string,
  signature: string,   // from 'webhook-signature' or provider-specific header
  timestamp: string,   // unix seconds as string, from provider header
  opts:      VerifyOptions,
): void {
  // Replay protection: reject stale timestamps
  const tsMs  = parseInt(timestamp, 10) * 1000;
  const ageMs = Date.now() - tsMs;
  if (ageMs > opts.tolerance * 1000 || ageMs < 0) {
    throw new Error(`Webhook timestamp outside tolerance: age ${ageMs}ms`);
  }

  // Compute expected signature
  const payload  = `${timestamp}.${rawBody}`;
  const expected = createHmac('sha256', opts.secret).update(payload).digest('hex');

  // Timing-safe comparison — prevents timing-oracle attacks
  const sigBuf = Buffer.from(signature, 'hex');
  const expBuf = Buffer.from(expected, 'hex');
  if (sigBuf.length !== expBuf.length || !timingSafeEqual(sigBuf, expBuf)) {
    throw new Error('Webhook signature mismatch');
  }
}

// Usage in an HTTP handler (Express/Next.js/Hono)
export async function rawBodyMiddleware(req: Request, res: Response, next: NextFunction) {
  const chunks: Buffer[] = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    // Preserve raw string before any JSON.parse — signatures are computed on the raw payload
    (req as any).rawBody = Buffer.concat(chunks).toString('utf-8');
    next();
  });
}
```

Note: providers that compute signatures differently (e.g., Stripe includes `v1=` prefix; GitHub uses `sha256=` prefix) — strip the prefix before comparing. Read provider docs; the pattern above is the generic HMAC-SHA256 form.

### Fast-ack + async processing

Respond 200 immediately. Do not do database writes, external API calls, or complex logic in the synchronous handler body. Enqueue the verified payload and return.

```ts
// routes/webhook.ts
import { verifyWebhookSignature } from '../lib/webhook-verify';
import { queue } from '../lib/queue';   // your job queue: BullMQ, pg-boss, Inngest, etc.

export async function webhookHandler(req: Request, res: Response): Promise<void> {
  const rawBody  = (req as any).rawBody as string;
  const sig      = req.headers['x-webhook-signature'] as string;
  const ts       = req.headers['x-webhook-timestamp'] as string;

  // Verify signature synchronously — cheap
  try {
    verifyWebhookSignature(rawBody, sig, ts, {
      secret:    process.env.WEBHOOK_SECRET!,
      tolerance: 300,  // 5 minutes
    });
  } catch (err) {
    res.status(400).json({ error: 'Invalid signature' });
    return;
  }

  const event = JSON.parse(rawBody) as WebhookEvent;

  // Acknowledge only after the configured queue confirms durable acceptance.
  // Verify durability, retry, DLQ, and idempotency settings for this provider.
  await queue.add('webhook.process', { eventId: event.id, event });

  // Respond 200 immediately
  res.status(200).json({ received: true });
}
```

### Idempotency — dedupe store

The queue worker checks a processed-event log before doing any work. Store the key and result atomically with the business operation.

```ts
// workers/webhook-worker.ts
import { db } from '../lib/db';

export async function processWebhookEvent(job: { data: { eventId: string; event: WebhookEvent } }) {
  const { eventId, event } = job.data;

  // Idempotency check
  const existing = await db.processedWebhookEvent.findUnique({
    where: { eventId },
  });
  if (existing) {
    logger.info({ eventId, type: event.type }, 'webhook_duplicate_skipped');
    return;
  }

  await db.$transaction(async (tx) => {
    // Handle the event
    await handleEvent(tx, event);

    // Mark processed inside the same transaction
    await tx.processedWebhookEvent.create({
      data: {
        eventId,
        type:        event.type,
        processedAt: new Date(),
      },
    });
  });
}
```

Schema for the dedupe store (PostgreSQL example):

```sql
CREATE TABLE processed_webhook_events (
  event_id     TEXT PRIMARY KEY,
  type         TEXT NOT NULL,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- TTL: clean up old records (keep 30 days for audit; providers retry within 3–7 days)
CREATE INDEX ON processed_webhook_events (processed_at);
```

### Retry and backoff in the queue worker

Configure the job queue to retry failed jobs with backoff. Do not implement retries inside the worker function itself — that blocks the job slot.

```ts
// BullMQ example — job options applied at queue.add() time
await queue.add('webhook.process', payload, {
  attempts:  5,
  backoff: {
    type:  'exponential',
    delay: 1_000,   // 1s, 2s, 4s, 8s, 16s
  },
  removeOnComplete: { age: 60 * 60 * 24 },  // keep 24h for observability
  removeOnFail:     false,                   // failed jobs become dead-letters
});

// pg-boss equivalent
await boss.send('webhook.process', payload, {
  retryLimit:    5,
  retryDelay:    1,     // seconds
  retryBackoff:  true,
  expireInHours: 24,
});
```

### Dead-letter queue

Failed jobs that exhaust all retries go to a dead-letter queue. Operators review and replay manually after fixing the root cause.

```ts
// BullMQ: the 'failed' event fires on the Worker instance, not the Queue.
// (webhookWorker is created in the Timeouts section below.)
webhookWorker.on('failed', async (job, err) => {
  if (job && job.attemptsMade >= job.opts.attempts!) {
    logger.error(
      { eventId: job.data.eventId, type: job.data.event.type, err: err.message },
      'webhook_dead_letter',
    );
    await deadLetterQueue.add('webhook.dead', {
      originalJobId:  job.id,
      eventId:        job.data.eventId,
      event:          job.data.event,
      failedAt:       new Date().toISOString(),
      lastError:      err.message,
    });
  }
});

// Replay a dead-letter job
async function replayDeadLetter(deadLetterId: string): Promise<void> {
  const job = await deadLetterQueue.getJob(deadLetterId);
  if (!job) throw new Error('Dead-letter job not found');

  // Remove from dedupe store so it can be re-processed
  await db.processedWebhookEvent.deleteMany({
    where: { eventId: job.data.eventId },
  });

  await webhookQueue.add('webhook.process', {
    eventId: job.data.eventId,
    event:   job.data.event,
  });
}
```

### Ordering and causal consistency

Webhooks do not arrive in order. Design handlers to be order-independent, or use a version/sequence field to guard against stale updates.

```ts
async function upsertSubscription(tx: PrismaClient, event: SubscriptionEvent): Promise<void> {
  // Guard: only update if the event is newer than the stored record
  // Use the provider's event timestamp or sequence number, not your DB updatedAt
  const existing = await tx.subscription.findUnique({ where: { providerId: event.subscriptionId } });

  if (existing && existing.providerUpdatedAt >= event.occurredAt) {
    logger.info({ eventId: event.id }, 'webhook_stale_event_skipped');
    return;
  }

  await tx.subscription.upsert({
    where:  { providerId: event.subscriptionId },
    create: { /* ... */ providerUpdatedAt: event.occurredAt },
    update: { /* ... */ providerUpdatedAt: event.occurredAt },
  });
}
```

### Timeouts

The worker must set a maximum execution time. A job that never resolves consumes a worker slot and blocks progress.

```ts
// BullMQ has no per-job `timeout` option. Create a Worker (NOT Queue.process(),
// which is the legacy Bull v3 API) and bound each operation with your own
// timeout inside the processor.
import { Worker } from 'bullmq';

const webhookWorker = new Worker(
  'webhook.process',
  async (job) => {
    await Promise.race([
      processEvent(job.data.event),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Worker timeout')), 25_000)),
    ]);
  },
  { concurrency: 5 },
);
```

## Anti-Patterns

- Processing the event body before verifying the signature — parse after verification, not before
- Computing signatures on the parsed (JSON.stringify'd) body instead of the raw bytes — JSON key order is not guaranteed; always sign/verify the original raw string
- Doing blocking work in the HTTP handler before responding — times out, provider marks the endpoint as failed
- Not writing the idempotency record in the same transaction as the business operation — creates a window for duplicate processing on crash-recovery
- Setting dedupe TTL shorter than the provider's retry window — an event can be retried after your TTL expires, causing double-processing
- Swallowing errors in the worker without re-throwing — the job queue cannot retry what it believes succeeded
- Using wall-clock `Date.now()` as the event version for ordering — use the provider's sequence or event timestamp

## Quality Gates

- [ ] Signature verified before any body parsing; invalid signatures return 400 with no processing
- [ ] Timestamp tolerance checked (default 5 minutes); requests outside tolerance rejected
- [ ] Handler responds 200 before doing any work; heavy processing happens in a queue worker
- [ ] Worker checks dedupe store at start; idempotency record written in same transaction as business state
- [ ] Durable enqueue is confirmed before acknowledgement; the selected provider's durability mode, retry/backoff policy, dead-letter route, and idempotency boundary are recorded and verified
- [ ] Dead-letter queue monitored with alerts; replay procedure documented and tested
- [ ] Event handlers are order-independent, or use provider timestamp to guard against stale events
- [ ] Worker has a maximum execution timeout configured; never runs indefinitely
- [ ] Signature comparison uses `timingSafeEqual` — no string equality (`===`)
