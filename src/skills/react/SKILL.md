---
name: react
description: "One dense React skill — React 19.3 + React Compiler, RSC/Suspense streaming, Next.js 16 Cache Components, View Transitions, Fragment refs, render performance, and composition (compound components, context, slots). Use when writing, optimizing, or structuring React/Next.js code. Triggers on 'react component', 'next.js', 'react performance', 'slow render', 'memoization', 're-render', 'server component', 'rsc', 'suspense', 'use cache', 'react compiler', 'view transition', 'fragment ref', 'compound component', 'composition'."
department: engineering
triggers:
  - react component
  - nextjs
  - react performance
  - slow render
  - memoization
  - re-render
  - server component
  - rsc
  - suspense
  - use cache
  - react compiler
  - compound component
  - composition
---

# React

The single React/Next.js engineering skill: React 19.3 with the Compiler doing the memoization, RSC + Suspense streaming + Cache Components for data, and composition patterns for component APIs. Performance is a design property here, not a post-hoc memo pass.

> Reference snapshot, 2026-09-19: React 19.3, React Compiler 1.0, and Next.js 16. This is not an instruction to upgrade an existing project. Resolve the project's declared React, Next.js, and compiler versions before enabling a feature or migration.

## When to Use

- Writing or reviewing React components / Next.js routes
- Slow renders, frequent re-renders, sluggish lists or forms
- Data fetching architecture (RSC, Suspense, caching)
- Designing flexible component APIs (compound components, slots, render props)

Skip for: non-React frameworks, backend/database performance, build/bundler config beyond what the Compiler/Next requires, pure CSS/visual work (use `frontend-design`).

## Core DNA

1. **Let the Compiler memoize.** React Compiler 1.0 auto-memoizes. Write plain components. Reach for `useMemo`/`useCallback`/`memo` only for the three real reasons below — not by default.
2. **Fetch on the server, stream with Suspense.** Async Server Components fetch data; sibling Suspense boundaries stream it. `useEffect` data-fetching is a client-side last resort.
3. **Cache shared data, not user-specific data.** `use cache` for shared/cacheable; Suspense + no cache for fresh/user-specific. Don't reach for `unstable_cache`/`fetch` cache options in App Router.
4. **Compose, don't drill.** Compound components share state via context; consumers compose meaning instead of passing 20 props.
5. **Measure before optimizing.** Profiler + the "Memo ✨" badge tell the truth; guesses don't.

## Key Patterns

### React Compiler 1.0 (write plain, then optimize selectively)

Install `babel-plugin-react-compiler` at the version selected for the project; do not use this skill to apply a blanket `@latest` upgrade. Keep `eslint-plugin-react-hooks` compatible with the project's ESLint setup.

```ts
// next.config.ts — Next.js 16
export default { reactCompiler: true };
// Vite: add the reactCompiler babel plugin; Babel must run before other transforms.
```

- ESLint: enable `react-hooks` `recommended-latest` (ships the compiler-powered rules: purity, refs, set-state-in-effect, preserve-manual-memoization). The old standalone `eslint-plugin-react-compiler` is merged in — remove it.
- Verify it ran: the "Memo ✨" badge in React DevTools.
- **Memoization decision tree (new code):** write plain. Keep a manual hook ONLY for (a) `useEffect` dependency stability, (b) library reference-equality boundaries (D3, AG Grid, TanStack Table), (c) very wide context values. Profiler-confirmed >50ms sync work is the fourth, rare reason.
- **Existing code:** do NOT mass-delete memos. Turn the Compiler on, fix Rules-of-React violations, clean per-file on touch. Pin the exact compiler version if test coverage is weak.
- **Incremental adoption:** `compilationMode: 'annotation'` + `'use memo'` opt-in; `'use no memo'` escape hatch (always with a TODO + tracking link); `react-compiler-healthcheck` to scope it.
- Build trade-off: dev +15-30%, prod +10-20% build time.

### React 19.3 DOM APIs

`<ViewTransition>` and Fragment refs are stable in React 19.3. Use them only when the project is on React 19.3+ and rendering to the DOM.

```tsx
import { Fragment, ViewTransition, startTransition, useRef } from "react";

startTransition(() => setOpen((value) => !value)); // marks the update for <ViewTransition>

<ViewTransition>{open && <Panel />}</ViewTransition>

const groupRef = useRef(null);
<Fragment ref={groupRef}>{children}</Fragment> // focus, observe, or measure sibling DOM children
```

- A `ViewTransition` runs for updates marked by `startTransition`, `useDeferredValue`, or a Suspense reveal. Urgent updates do not animate.
- Fragment refs avoid an otherwise artificial wrapper when behavior must apply to a group of sibling DOM nodes. They expose a `FragmentInstance`, not a single DOM element.

### RSC + Suspense streaming

```tsx
// Async Server Component fetches directly — no useEffect, no client waterfall
async function Dashboard() {
  return (
    <>
      {/* sibling (not nested) boundaries — independent data streams in parallel */}
      <Suspense fallback={<StatsSkeleton />}><Stats /></Suspense>
      <Suspense fallback={<FeedSkeleton />}><Feed /></Suspense>
    </>
  );
}
async function Stats() {
  const data = await getStats(); // fetched on the server
  return <StatsView data={data} />;
}
```

- One Suspense boundary per independent data source. Skeleton dimensions must match content (avoid CLS). Pair every Suspense with an ErrorBoundary. Verify the CDN/reverse-proxy does chunked transfer (buffering kills streaming).
- Pass a Promise from a Server Component to a Client Component and read it with `use()` inside Suspense. NEVER create a new Promise inside the Client Component render — it suspends forever.
- PPR for mixed routes: `experimental.ppr: 'incremental'` + `export const experimental_ppr = true`; place Suspense close to dynamic data so the static shell ships from CDN edge (~50ms TTFB).

### `use cache` (Next.js 16 Cache Components)

```tsx
// next.config.ts
export default { cacheComponents: true };

async function getProducts() {
  "use cache";
  cacheLife("hours");
  cacheTag("products");
  return db.products.findAll();
}
// Invalidate: revalidateTag("products")
// Private/per-user: "use cache: private"
```

Decision: shared, cacheable → `use cache`. User-specific, must be fresh → Suspense + no cache. `use cache` replaces `unstable_cache()`, `fetch` cache options, and route-level ISR config for the App Router.

### React 19 APIs

```tsx
import { use, useActionState, useOptimistic, startTransition } from "react";

// use() — read a passed-in Promise or Context, inside Suspense
const data = use(promiseFromServer);

// Form Actions — pending state without manual flags
const [state, formAction, isPending] = useActionState(submitAction, initial);

// Optimistic UI
const [optimistic, addOptimistic] = useOptimistic(items, reducer);

// Non-urgent updates stay responsive
startTransition(() => setFilter(next));

// LCP resource hints
import { preload, preinit, prefetchDNS, preconnect } from "react-dom";
```

### Render-performance patterns (still load-bearing under the Compiler)

```tsx
// Lift state DOWN — isolate re-render scope to the input that owns it
function Form() { return (<><NameInput /><EmailInput /></>); }

// Colocate state with usage — modal state lives at its trigger, not App root
function MainContent() {
  const [open, setOpen] = useState(false);
  return (<><button onClick={() => setOpen(true)}>Open</button>{open && <Modal />}</>);
}

// Virtualize long lists (100+ rows) — @tanstack/react-virtual
const v = useVirtualizer({ count: items.length, getScrollElement: () => ref.current, estimateSize: () => 50 });

// Stable, unique keys — never index keys on reorderable lists
{items.map((item) => <Item key={item.id} {...item} />)}

// Lazy-load heavy components
const Editor = lazy(() => import("./HeavyEditor"));

// Zustand selector slicing — subscribe to the slice, not the whole store
const userName = useStore((s) => s.user.name);

// Split context by concern; useDeferredValue for typeahead lag
```

- Eliminate waterfalls: `Promise.all` for independent fetches; start promises early, await late.
- Million.js only for specialist UIs the Compiler doesn't cover well — trading grids, spreadsheets, log viewers.

### Composition — compound components

```tsx
const TabsContext = createContext<{ value: string; onValueChange: (v: string) => void } | null>(null);
function useTabs() {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error("Tabs.* must be used within <Tabs>");
  return ctx;
}

function Tabs({ defaultValue, value: controlled, onValueChange, children }: TabsProps) {
  const [internal, setInternal] = useState(defaultValue);
  const value = controlled ?? internal;
  const setValue = onValueChange ?? setInternal;
  return <TabsContext.Provider value={{ value, onValueChange: setValue }}>{children}</TabsContext.Provider>;
}

function TabsTrigger({ value, children }: { value: string; children: React.ReactNode }) {
  const { value: selected, onValueChange } = useTabs();
  return (
    <button role="tab" aria-selected={selected === value}
      data-state={selected === value ? "active" : "inactive"} onClick={() => onValueChange(value)}>
      {children}
    </button>
  );
}
```

- Support both controlled and uncontrolled modes (`controlled ?? internal`).
- Throw a helpful error when a sub-component is used outside its provider.
- Compound components > props explosion. Render props expose internal state; hooks reuse logic without rendering. Slots (`displayName` lookup) give named insertion points.

## Anti-Patterns

- Manually memoizing everything "just in case" in new code — that's the doctrine the Compiler replaced. Write plain.
- Mass-deleting existing memos when turning the Compiler on — leave them; clean on touch.
- `useEffect` data-fetching in Server-Component-capable routes; nested (instead of sibling) Suspense boundaries that serialize independent streams.
- Creating a new Promise inside a Client Component passed to `use()` — infinite suspend.
- `unstable_cache()`/`fetch` cache options in the App Router — use `use cache`.
- Skeletons whose dimensions don't match content (CLS); Suspense with no paired ErrorBoundary.
- Index keys on reorderable lists; lifting state too high; one giant context.
- Props explosion (20-prop `Table`) instead of compound components.
- Using React 19.3-only View Transitions or Fragment refs in an older React target.

## Quality Gates

- [ ] React Compiler enabled; `react-hooks` ESLint `recommended-latest` passing; "Memo ✨" badge confirms it ran
- [ ] New components written plain; manual memo only for effect deps / library boundaries / wide context / profiler-confirmed >50ms
- [ ] Server-side data fetched in async Server Components; sibling Suspense boundaries; every Suspense paired with ErrorBoundary
- [ ] Skeletons match content dimensions (no CLS); PPR used for mixed static/dynamic routes
- [ ] `use cache` for shared data; Suspense + no cache for user-specific
- [ ] `use()` consumes a Promise created on the server (never inside the Client Component)
- [ ] Lists >100 items virtualized; stable unique keys; heavy components lazy-loaded
- [ ] Compound components support controlled + uncontrolled, throw on out-of-provider use, expose ARIA
- [ ] INP measured; `startTransition` on input lag >100ms
