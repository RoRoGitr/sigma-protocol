# Native tabs — reference

> Verified 2026-06-04. SDK 56 forked `expo-router` from `react-navigation`, which changed the
> native-tabs story. Both options below render real `UITabBarController` / `BottomNavigationView`.

## Two options

| | `expo-router` native tabs | `react-native-bottom-tabs` |
|---|---|---|
| Import | `expo-router` (`NativeTabs.Trigger.*`) | `@bottom-tabs/react-navigation` |
| Best for | NEW apps on SDK 56+ | migrating an existing React Navigation app, or when you need its TS types |
| Backed by | native tab controller | native tab controller |
| System glass material | yes (semi-transparent bg) | yes |

## expo-router native tabs (preferred for new apps)

```tsx
import { NativeTabs } from 'expo-router';

export default function Layout() {
  return (
    <NativeTabs>
      <NativeTabs.Trigger name="index" />
      <NativeTabs.Trigger name="search" />
      <NativeTabs.Trigger name="profile" />
    </NativeTabs>
  );
}
```

- SF Symbols (iOS) / Android drawable resources are set per trigger.
- Post-fork: do **not** import `@react-navigation/bottom-tabs` directly — it breaks. Route through `expo-router`.

## react-native-bottom-tabs (migration path)

Use `@bottom-tabs/react-navigation` when an app already runs React Navigation and a full rewrite to expo-router native tabs isn't worth it yet. It wraps the same native controllers.

## Native code → rebuild

Native tabs touch native code → `npx expo prebuild --clean && npx expo run:ios` after wiring them. Metro reload won't pick them up.
