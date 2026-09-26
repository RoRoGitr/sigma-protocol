---
name: testing
description: "TypeScript and web testing skill — Vitest for unit/integration, Playwright for E2E, MSW for network mocking, Testing Library for React components. Covers the full test pyramid: unit, integration, component, and E2E. Use when writing tests for TypeScript/JavaScript projects, setting up test infrastructure, choosing between test layers, or implementing TDD red-green-refactor. NOT for mobile (iOS/Android/React Native) — use testing-apple or mobile-ui-testing. Triggers on 'vitest', 'playwright', 'msw', 'testing library', 'jest', 'test pyramid', 'unit test', 'integration test', 'e2e test', 'tdd', 'red-green-refactor', 'mock service worker', 'test coverage', 'mutation testing', 'contract testing', 'test data builder'."
department: engineering
triggers:
  - vitest
  - playwright
  - msw
  - testing library
  - jest
  - test pyramid
  - unit test
  - integration test
  - e2e test
  - tdd
  - red-green-refactor
  - mock service worker
  - test coverage
  - mutation testing
  - contract testing
  - test data builder
  - web testing
  - typescript test
---

# TypeScript / Web Testing

The canonical testing skill for TypeScript and web projects. Covers the full test pyramid: unit (Vitest), integration (Vitest + real deps), component (Testing Library), E2E (Playwright), and network mocking (MSW).

> Reference snapshot, 2026-06-04: Vitest 4.1.8 · @playwright/test 1.60.0 · msw 2.14.6 · @testing-library/react 16.3.2. Keep the project's declared test-tool versions; this snapshot does not authorize upgrades.

## When to Invoke

Invoke this skill when:

- Setting up test infrastructure for a TypeScript/web project
- Writing unit tests for business logic or utility functions
- Writing integration tests for API routes or service boundaries
- Testing React components in isolation with Testing Library
- Writing E2E flows with Playwright for critical user journeys
- Mocking network requests with MSW
- Implementing TDD red-green-refactor for new features or bug fixes
- Evaluating test coverage quality (mutation testing)
- Building test data factories or fixtures

## When NOT to Use

- iOS/macOS native testing (Swift, SwiftUI, XCTest) — use `testing-apple`
- React Native / Expo app testing — use `mobile-ui-testing`
- Agent-device / Maestro simulator automation — use `mobile-ui-testing`
- Visual regression for mobile screens — use `mobile-ui-testing`

---

## Test Pyramid

```
           /\
          /  \     E2E (Playwright) — ~10%
         /    \    Critical user journeys; slow
        /------\
       /        \  Component (Testing Library) — ~20%
      /          \ React components in isolation
     /------------\
    /              \ Integration (Vitest) — ~20%
   /                \ API routes, DB, service boundaries
  /------------------\
 /                    \ Unit (Vitest) — ~50%
/                      \ Pure functions, domain logic, hooks
```

**Decision rule:**
- If the logic has no I/O side effects → unit test
- If it crosses a module or service boundary → integration test
- If it involves a rendered React component → component test
- If it is a complete user-visible flow → E2E test

---

## TDD Red-Green-Refactor Loop

This loop is the primary workflow for all logic-bearing code.

```
1. RED   — Write the smallest failing test that documents the desired behavior
2. GREEN — Write the minimal production code to make it pass (no gold-plating)
3. REFACTOR — Simplify code and test without changing behavior; re-run to confirm green
4. COMMIT — Atomic commit with one coherent change set
5. REPEAT
```

**Rules:**
- Never write production code before the failing test exists.
- A test that is already green before you write any code is a useless test — delete it and write a real one.
- Refactor step is mandatory, not optional — clean code now costs less than cleanup later.

---

## Key Patterns

### Vitest — unit test

```typescript
// src/lib/discount.test.ts
import { describe, it, expect } from 'vitest';
import { calculateDiscount } from './discount';

describe('calculateDiscount', () => {
  it('returns 10% of order total when total exceeds threshold', () => {
    expect(calculateDiscount({ total: 150 }, { threshold: 100, pct: 10 })).toBe(15);
  });

  it('returns 0 when total is at threshold boundary', () => {
    expect(calculateDiscount({ total: 100 }, { threshold: 100, pct: 10 })).toBe(0);
  });

  it('returns 0 when total is below threshold', () => {
    expect(calculateDiscount({ total: 50 }, { threshold: 100, pct: 10 })).toBe(0);
  });
});
```

### Vitest — integration test (API route)

```typescript
// src/app/api/orders/route.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { POST } from './route';
import { resetTestDb, seedTestDb } from '@/test/db';

describe('POST /api/orders', () => {
  beforeEach(async () => {
    await resetTestDb();
    await seedTestDb();
  });

  it('creates an order and returns 201 with the new order id', async () => {
    const req = new Request('http://localhost/api/orders', {
      method: 'POST',
      body: JSON.stringify({ userId: 'user-1', items: [{ productId: 'prod-1', qty: 2 }] }),
      headers: { 'content-type': 'application/json' },
    });

    const res = await POST(req);
    const body = await res.json();

    expect(res.status).toBe(201);
    expect(body.id).toMatch(/^order-/);
    expect(body.status).toBe('pending');
  });

  it('returns 400 when items array is empty', async () => {
    const req = new Request('http://localhost/api/orders', {
      method: 'POST',
      body: JSON.stringify({ userId: 'user-1', items: [] }),
      headers: { 'content-type': 'application/json' },
    });

    const res = await POST(req);
    expect(res.status).toBe(400);
  });
});
```

### Testing Library — React component test

```typescript
// src/components/LoginForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { LoginForm } from './LoginForm';

describe('LoginForm', () => {
  it('calls onSubmit with email and password on valid submission', async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText('Email'), 'user@example.com');
    await userEvent.type(screen.getByLabelText('Password'), 'secret123');
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'user@example.com',
        password: 'secret123',
      });
    });
  });

  it('shows a validation error when email is empty', async () => {
    render(<LoginForm onSubmit={vi.fn()} />);
    await userEvent.click(screen.getByRole('button', { name: /sign in/i }));
    expect(await screen.findByRole('alert')).toHaveTextContent(/email is required/i);
  });
});
```

### MSW — Mock Service Worker for network mocking

MSW intercepts requests at the network level, not by patching `fetch`. This means your actual fetch/axios code runs unchanged.

```typescript
// src/test/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/user/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'Test User',
      email: 'user@example.com',
    });
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json() as Record<string, unknown>;
    return HttpResponse.json({ id: 'order-123', ...body }, { status: 201 });
  }),

  // Simulate error
  http.get('/api/products', () => {
    return HttpResponse.json({ error: 'Service unavailable' }, { status: 503 });
  }),
];

// src/test/setup.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Override a handler in a single test:

```typescript
import { http, HttpResponse } from 'msw';
import { server } from '@/test/setup';

it('shows error state when the API is down', async () => {
  server.use(
    http.get('/api/user/:id', () =>
      HttpResponse.json({ error: 'Not found' }, { status: 404 }),
    ),
  );

  render(<UserProfile userId="u-1" />);
  expect(await screen.findByRole('alert')).toHaveTextContent(/not found/i);
});
```

### Playwright — E2E test

```typescript
// e2e/checkout.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Checkout flow', () => {
  test('completes a purchase from product page to confirmation', async ({ page }) => {
    await page.goto('/products/widget-x');
    await page.getByTestId('add-to-cart').click();
    await expect(page.getByTestId('cart-count')).toHaveText('1');

    await page.getByTestId('checkout-button').click();
    await page.getByLabel('Card number').fill('4242424242424242');
    await page.getByLabel('Expiry').fill('12/28');
    await page.getByLabel('CVC').fill('123');
    await page.getByRole('button', { name: /place order/i }).click();

    await expect(page.getByTestId('order-confirmation')).toBeVisible();
    await expect(page).toHaveURL(/\/orders\/[a-z0-9-]+/);
  });

  test('shows inline error for expired card', async ({ page }) => {
    await page.goto('/checkout');
    await page.getByLabel('Card number').fill('4000000000000069');
    await page.getByLabel('Expiry').fill('12/20');
    await page.getByLabel('CVC').fill('123');
    await page.getByRole('button', { name: /place order/i }).click();

    await expect(page.getByRole('alert')).toContainText(/card.*expired/i);
  });
});
```

### Test data builder pattern

Eliminates fixture boilerplate and makes test data intent obvious.

```typescript
// src/test/builders/user.ts
type UserOverrides = Partial<{
  id: string;
  email: string;
  role: 'admin' | 'customer';
  verified: boolean;
}>;

export function buildUser(overrides: UserOverrides = {}) {
  return {
    id: `user-${Math.random().toString(36).slice(2, 8)}`,
    email: `test-${Date.now()}@example.com`,
    role: 'customer' as const,
    verified: true,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  };
}

// Usage in a test
const admin = buildUser({ role: 'admin' });
const unverified = buildUser({ verified: false });
```

### Contract testing

Define the behavioral contract any implementation must satisfy, then run the same suite against each implementation.

```typescript
// src/test/contracts/storage-contract.ts
import { describe, it, expect } from 'vitest';
import type { Storage } from '@/lib/storage/types';

export function storageContract(factory: () => Storage) {
  describe('Storage contract', () => {
    it('returns undefined for a key that has never been set', async () => {
      const s = factory();
      expect(await s.get('missing')).toBeUndefined();
    });

    it('round-trips a stored value', async () => {
      const s = factory();
      await s.set('key', { value: 42 });
      expect(await s.get('key')).toEqual({ value: 42 });
    });

    it('deletes an existing key', async () => {
      const s = factory();
      await s.set('key', 'data');
      await s.delete('key');
      expect(await s.get('key')).toBeUndefined();
    });
  });
}

// src/lib/storage/memory.test.ts
import { storageContract } from '@/test/contracts/storage-contract';
import { MemoryStorage } from './memory';

storageContract(() => new MemoryStorage());

// src/lib/storage/redis.test.ts
import { storageContract } from '@/test/contracts/storage-contract';
import { RedisStorage } from './redis';

storageContract(() => new RedisStorage({ host: 'localhost', port: 6379 }));
```

---

## What to Mock vs Not Mock

| Mock this | Do NOT mock this |
|-----------|-----------------|
| External HTTP APIs | Your own modules |
| Time (`vi.useFakeTimers`) | Business logic under test |
| Random values (`vi.spyOn(Math, 'random')`) | The database in integration tests |
| Browser globals unavailable in Node | File system in unit tests of real file operations |

**Golden rule:** mock at the boundary of your system, not inside it. If you mock a module you own, your tests no longer verify that the module works.

---

## Coverage Targets

| Code type | Line target | Branch target |
|-----------|-------------|---------------|
| Domain / business logic | 90%+ | 80%+ |
| API routes / service layer | 75%+ | 70%+ |
| React components | 60%+ | 50%+ |
| Utilities / helpers | 85%+ | 75%+ |
| Config / setup / types | Skip | Skip |

**Coverage is a floor, not a goal.** A 95%-covered module with trivial assertions is worse than a 65%-covered module with property-based tests on every invariant. Use mutation testing (Stryker) on critical paths to validate your test suite actually catches bugs.

---

## Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    exclude: ['node_modules', 'dist', 'e2e'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['**/*.config.*', '**/*.d.ts', 'src/test/**', 'e2e/**'],
      thresholds: {
        lines: 70,
        branches: 65,
        functions: 75,
        statements: 70,
      },
    },
  },
  resolve: {
    alias: { '@': path.resolve(__dirname, 'src') },
  },
});
```

## Playwright Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 7'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

---

## Quality Gates

- [ ] Unit tests exist for all functions with branching logic (not just happy path)
- [ ] Integration tests hit real implementations — no mocked-out database in integration layer
- [ ] MSW handlers cover all API endpoints tested in component / integration tests
- [ ] E2E flows cover the top 3 critical user journeys
- [ ] Test names describe behavior, not implementation: "returns 0 when below threshold" not "test case 3"
- [ ] No `setTimeout` / `sleep` in tests — use `waitFor`, Vitest fake timers, or MSW delays
- [ ] `vi.mock` at module level only, never inside a test body
- [ ] Test data built with factories / builders, not inline object literals
- [ ] Coverage thresholds enforced in CI (`vitest run --coverage`)
- [ ] Playwright tests run against a built app (`npm run build && npm run start`) in CI

---

## Related Skills

- `testing-apple` — Swift, XCTest, ViewInspector, swift-snapshot-testing for iOS/macOS
- `mobile-ui-testing` — agent-device, Maestro, Detox for mobile E2E and simulator automation
- `quality-gates` — CI configuration, Lefthook pre-commit hooks, branch protection
