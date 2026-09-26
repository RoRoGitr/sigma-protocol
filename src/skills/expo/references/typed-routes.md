# Expo Router typed routes — reference

> Verified 2026-06-04. Typed routes are **default-on** in current SDKs (since SDK 55);
> `experiments.typedRoutes` is no longer needed. This is mostly historical context + the `Href<T>` API.

## It's on by default

- Keep `.expo/types/**/*.ts` in your `tsconfig.json` `include`.
- Restart Metro if autocomplete goes stale after adding/renaming a route file.
- No `experiments.typedRoutes` flag required anymore.

## `Href<T>` usage

```tsx
import { Link, useRouter } from 'expo-router';
import type { Href } from 'expo-router';

<Link href="/profile">Profile</Link>

const href: Href<'/profile/[id]'> = { pathname: '/profile/[id]', params: { id } };
useRouter().push({ pathname: '/profile/[id]', params: { id: '42' } }); // object form is always typed
```

## Route shapes

- **Group routes** `(tabs)` appear in the generated type union but don't add a path segment.
- **Dynamic** `[id]` → `params: { id: string }`.
- **Catch-all** `[...rest]` → `params: { rest: string[] }`.

## Migration note

If you're on an older app with `experiments.typedRoutes` set, you can remove the flag — it's the default now. Direct `@react-navigation/*` imports are NOT typed by expo-router and break post-fork (SDK 56) — go through `expo-router`'s surface.
