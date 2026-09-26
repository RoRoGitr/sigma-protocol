# EAS build debugging — reference

> Verified 2026-06-04. `eas-cli` 20.0.0. The CLI hides the real error — it only shows the
> queue/upload phase. The actual Metro/Xcode stderr lives in the EAS dashboard log files. Fetch them.

## Get the real log

```bash
eas build:view <build-id> --json
```

This returns up to 4 signed GCS log URLs (≈15-min expiry). The largest (~150–200 KB) is the worker log. Download it and grep:

```bash
curl -s '<signed-worker-log-url>' | grep -nE 'EAGER_BUNDLE|stderr|error|fatal' | head -40
```

## Reproduce the bundle phase locally (no EAS slot burned)

```bash
EXPO_PUBLIC_DEV_MODE=false ./node_modules/.bin/expo export:embed --eager \
  --platform ios --dev false --bundle-output /tmp/eager.bundle --assets-dest /tmp/eager-assets
```

If this fails locally, EAS will fail the same way — fix it here for free.

## Top recurring failures

1. **Build-time `require()` of a gitignored file.** EAS uploads the working tree *minus* `.gitignore` — a file present locally but ignored won't exist on the builder. Move it out of the ignored path. (`eas-cli`'s ignore parser does NOT honor git re-include `!` patterns the way git does.)
2. **npm package with a broken `main`** (empty `lib/`). Bump it, install from the GitHub fix tag, or `patch-package`.
3. **Prod-only env vars missing on EAS.** Check with `eas env:list --environment production`.

## Watch / poll a running build

```bash
eas build:list --limit 1 --json --non-interactive    # latest build + status
# poll status; when "finished"/"errored", fetch the worker log as above
```

## Credentials

```bash
eas credentials                # interactive credentials manager
eas build:configure            # (re)write eas.json build profiles
```

A green `export:embed --eager` + clean `expo-doctor` + committed tree means a remaining EAS failure is *environmental* (credentials, env vars, builder image) — not your bundle.
