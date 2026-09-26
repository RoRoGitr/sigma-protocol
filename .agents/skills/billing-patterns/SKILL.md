---
name: billing-patterns
description: "Subscription and payments billing patterns — webhook-driven state machine, idempotent event handling, trial→paid transitions, proration, dunning/retries, entitlement checks, and reconciling from the provider rather than the client. Vendor-neutral (Stripe and RevenueCat used as examples). Use when implementing subscription billing, handling payment webhooks, or designing an entitlement system. Triggers on 'billing', 'subscription', 'payment', 'webhook billing', 'stripe', 'revenuecat', 'entitlement', 'dunning', 'trial', 'proration', 'idempotent billing'."
department: engineering
triggers:
  - billing
  - subscription
  - payment
  - webhook billing
  - stripe
  - revenuecat
  - entitlement
  - dunning
  - trial
  - proration
  - idempotent billing
  - payment webhooks
---

# Billing Patterns

Production subscription billing: webhook-driven state machines, idempotent event processing, trial→paid, proration, dunning, and entitlement checks. Provider-neutral — Stripe and RevenueCat are used as concrete examples.

> Version anchor: stripe 22.2. Verified 2026-06-04.

## When to Use

- Implementing subscription lifecycle (create, upgrade, downgrade, cancel, reactivate)
- Handling incoming billing webhooks
- Designing or reviewing an entitlement/access-check system
- Implementing dunning (retry logic for failed payments)
- Reasoning about proration on mid-cycle plan changes

## Core Rule: Never Trust the Client

The client sends `{ plan: 'pro' }` in a form submit. That is an assertion, not evidence. The canonical truth about what a user has paid for lives **only** in the billing provider. Every entitlement check must query your local subscription record, which is kept in sync by webhooks from the provider — never set by client requests.

## Key Patterns

### Subscription state machine

Model the subscription lifecycle as an explicit state machine with a finite set of valid states and transitions. Unknown states must be handled explicitly (not silently ignored).

```ts
// subscription.ts
export type SubscriptionStatus =
  | 'trialing'
  | 'active'
  | 'past_due'      // payment failed, in grace period
  | 'unpaid'        // grace period exhausted, access suspended
  | 'canceled'      // user canceled, end of period reached
  | 'incomplete'    // initial payment failed during creation
  | 'paused';       // billing paused (provider-specific)

export interface Subscription {
  id:               string;
  userId:           string;
  providerId:       string;   // provider's subscription ID
  plan:             string;   // e.g. 'pro_monthly'
  status:           SubscriptionStatus;
  currentPeriodEnd: Date;
  trialEnd:         Date | null;
  cancelAtPeriodEnd: boolean;
  updatedAt:        Date;
}

// Valid transitions
const VALID_TRANSITIONS: Record<SubscriptionStatus, SubscriptionStatus[]> = {
  incomplete:  ['active', 'canceled'],
  trialing:    ['active', 'past_due', 'canceled'],
  active:      ['past_due', 'canceled', 'paused'],
  past_due:    ['active', 'unpaid', 'canceled'],
  unpaid:      ['active', 'canceled'],
  canceled:    ['active'],           // reactivation
  paused:      ['active', 'canceled'],
};

function assertValidTransition(from: SubscriptionStatus, to: SubscriptionStatus): void {
  if (!VALID_TRANSITIONS[from]?.includes(to)) {
    throw new Error(`Invalid subscription transition: ${from} → ${to}`);
  }
}
```

### Idempotent webhook handler

Billing providers deliver events at-least-once. Store a processed event log keyed by the provider's event ID and skip duplicates.

> Snippets assume an injected `logger`, a `db` client (e.g. Prisma), and a `billingQueue` (a durable queue, e.g. BullMQ) in scope.

```ts
// webhook-handler.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2025-10-01' });

export async function handleStripeWebhook(req: Request): Promise<Response> {
  // Step 1: verify signature — reject unsigned events
  const sig = req.headers.get('stripe-signature');
  if (!sig) return new Response('Missing signature', { status: 400 });

  let event: Stripe.Event;
  try {
    const raw = await req.text();
    event = stripe.webhooks.constructEvent(raw, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return new Response('Invalid signature', { status: 400 });
  }

  // Step 2: enqueue durably, THEN ack. Never fire-and-forget a billing event —
  // a process restart between the 200 and processing would silently drop a
  // payment event (e.g. a lost invoice.payment_succeeded locks out a paying
  // user). Persist to a durable queue first (see the webhook-patterns skill);
  // processEvent() runs in the worker.
  await billingQueue.add('billing.process', { eventId: event.id, event });

  return new Response('ok', { status: 200 });
}

async function processEvent(event: Stripe.Event): Promise<void> {
  // Step 3: idempotency — skip already-processed events
  const already = await db.processedWebhookEvent.findUnique({ where: { eventId: event.id } });
  if (already) return;

  // Step 4: handle the event
  await db.$transaction(async (tx) => {
    switch (event.type) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated': {
        const sub = event.data.object as Stripe.Subscription;
        await upsertSubscription(tx, sub);
        break;
      }
      case 'customer.subscription.deleted': {
        const sub = event.data.object as Stripe.Subscription;
        await tx.subscription.update({
          where: { providerId: sub.id },
          data:  { status: 'canceled', updatedAt: new Date() },
        });
        break;
      }
      case 'invoice.payment_failed': {
        const inv = event.data.object as Stripe.Invoice;
        if (inv.subscription) {
          await tx.subscription.update({
            where: { providerId: inv.subscription as string },
            data:  { status: 'past_due', updatedAt: new Date() },
          });
        }
        break;
      }
      case 'invoice.payment_succeeded': {
        const inv = event.data.object as Stripe.Invoice;
        if (inv.subscription) {
          await tx.subscription.update({
            where:  { providerId: inv.subscription as string },
            data:   { status: 'active', updatedAt: new Date() },
          });
        }
        break;
      }
      default:
        // Log unknown events; do not throw — future event types should not crash the handler
        logger.debug({ eventId: event.id, type: event.type }, 'webhook_unhandled_event_type');
    }

    // Step 5: mark as processed inside the same transaction
    await tx.processedWebhookEvent.create({
      data: { eventId: event.id, type: event.type, processedAt: new Date() },
    });
  });
}

async function upsertSubscription(tx: PrismaClient, sub: Stripe.Subscription): Promise<void> {
  const status = sub.status as SubscriptionStatus;
  await tx.subscription.upsert({
    where:  { providerId: sub.id },
    create: {
      providerId:       sub.id,
      // look up your internal user by the provider's customer id
      userId:           (await tx.user.findFirstOrThrow({
                          where: { stripeCustomerId: sub.customer as string },
                        })).id,
      plan:             sub.items.data[0].price.id,
      status,
      currentPeriodEnd: new Date(sub.current_period_end * 1000),
      trialEnd:         sub.trial_end ? new Date(sub.trial_end * 1000) : null,
      cancelAtPeriodEnd: sub.cancel_at_period_end,
      updatedAt:        new Date(),
    },
    update: {
      plan:             sub.items.data[0].price.id,
      status,
      currentPeriodEnd: new Date(sub.current_period_end * 1000),
      trialEnd:         sub.trial_end ? new Date(sub.trial_end * 1000) : null,
      cancelAtPeriodEnd: sub.cancel_at_period_end,
      updatedAt:        new Date(),
    },
  });
}
```

### Entitlement check

Entitlement is a read of your local subscription table. Never call the billing provider's API on every request — that adds latency and creates an availability dependency.

```ts
// entitlement.ts
export type Feature = 'analytics' | 'api_access' | 'team_seats' | 'priority_support';

const PLAN_FEATURES: Record<string, Feature[]> = {
  free:        [],
  starter:     ['analytics'],
  pro:         ['analytics', 'api_access'],
  enterprise:  ['analytics', 'api_access', 'team_seats', 'priority_support'],
};

export async function hasFeature(userId: string, feature: Feature): Promise<boolean> {
  const sub = await db.subscription.findFirst({
    where: {
      userId,
      status: { in: ['active', 'trialing'] },
      currentPeriodEnd: { gt: new Date() },
    },
    select: { plan: true },
  });

  if (!sub) return false;
  return (PLAN_FEATURES[sub.plan] ?? []).includes(feature);
}

// Middleware
export function requireFeature(feature: Feature) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const allowed = await hasFeature(req.userId!, feature);
    if (!allowed) {
      return res.status(403).json({
        type:     'https://api.example.com/problems/feature-not-available',
        title:    'Feature Not Available',
        status:   403,
        detail:   `Your current plan does not include ${feature}. Upgrade to access this feature.`,
        instance: `/errors/trace/${req.traceId}`,
      });
    }
    next();
  };
}
```

### Trial → paid transition

Do not manage trial state yourself. The billing provider tracks `trial_end`. Your webhook handler updates `status` from `trialing` → `active` (on successful charge) or `past_due`/`canceled` (on failure). Your entitlement check treats `trialing` with a non-expired `currentPeriodEnd` as having full plan features.

```ts
// Trialing users get full plan features until trialEnd
export async function hasFeature(userId: string, feature: Feature): Promise<boolean> {
  const sub = await db.subscription.findFirst({
    where: {
      userId,
      status: { in: ['active', 'trialing'] },     // both status values grant access
      currentPeriodEnd: { gt: new Date() },
    },
    select: { plan: true },
  });
  return (PLAN_FEATURES[sub?.plan ?? ''] ?? []).includes(feature);
}
```

### Proration on plan change

Proration is computed and previewed before confirming the switch. Never change the plan without showing the user what they owe or receive as credit.

```ts
// Preview proration amount before switching
async function previewPlanChange(subscriptionId: string, newPriceId: string) {
  const sub = await stripe.subscriptions.retrieve(subscriptionId);
  const prorationDate = Math.floor(Date.now() / 1000);

  const preview = await stripe.invoices.retrieveUpcoming({
    customer:        sub.customer as string,
    subscription:    subscriptionId,
    subscription_items: [{ id: sub.items.data[0].id, price: newPriceId }],
    subscription_proration_date: prorationDate,
  });

  return {
    amountDueNow: preview.amount_due,   // in smallest currency unit (cents)
    creditBalance: preview.starting_balance,
    lines:         preview.lines.data,
  };
}

// Confirm the change
async function changePlan(subscriptionId: string, newPriceId: string) {
  return stripe.subscriptions.update(subscriptionId, {
    items:                  [{ id: (await stripe.subscriptions.retrieve(subscriptionId)).items.data[0].id, price: newPriceId }],
    proration_behavior:     'create_prorations',
    billing_cycle_anchor:   'unchanged',
  });
}
```

### Dunning — retry logic for failed payments

Do not implement your own retry loop. Configure the provider's dunning settings (Stripe Smart Retries, or your provider's equivalent). Your responsibility is handling the resulting `invoice.payment_failed` events and communicating with the user.

```ts
// Respond to dunning events
case 'invoice.payment_failed': {
  const inv = event.data.object as Stripe.Invoice;
  const attemptCount = inv.attempt_count;

  // Progressive messaging: get more urgent as retries increase
  const urgency: 'low' | 'medium' | 'high' =
    attemptCount === 1 ? 'low' : attemptCount <= 3 ? 'medium' : 'high';

  await notificationService.sendPaymentFailedEmail(userId, { attemptCount, urgency });

  // After exhausting retries the provider cancels — handled by subscription.deleted event
  break;
}
```

## Anti-Patterns

- Setting subscription status from a client-side POST — status is set exclusively by webhook events
- Calling the billing provider API on every entitlement check — store subscription state locally, sync via webhooks
- Processing webhook events without verifying the signature — unsigned events must be rejected at the door
- Not marking events as processed inside the same database transaction as the state update — creates a window for duplicate processing on retries
- Implementing your own payment retry loop — use the provider's built-in dunning; duplicate charges are a compliance risk
- Treating `trial_end` as the access revocation date without checking the webhook — the provider charges at `trial_end`; access continues if payment succeeds; your webhook handler updates the record
- Not providing a proration preview before a plan change — users who see an unexpected charge file chargebacks

## Quality Gates

- [ ] Webhook signature verified before processing; unsigned requests return 400
- [ ] Processed event IDs stored in the database; duplicate events are skipped (no double-processing)
- [ ] Event processing responds 200 fast (async queue or fire-and-forget); no synchronous heavy work in the handler
- [ ] `SubscriptionStatus` is a discriminated union with exhaustive handling; no `else` catch-alls for unknown states
- [ ] Entitlement checks read from the local subscription table; no live provider API call in the hot path
- [ ] `status IN ('active', 'trialing')` and `currentPeriodEnd > now` both required for active access
- [ ] Plan changes preview proration before confirming; user sees what they owe
- [ ] Dunning handled by provider settings; app layer sends user notifications based on `invoice.payment_failed` events
- [ ] `processedWebhookEvent` upsert and subscription update are inside a single database transaction
