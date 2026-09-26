# App Assets

Place your app icon and splash screen images here before publishing.

| File | Size | Purpose |
|------|------|---------|
| `icon.png` | 1024x1024 | iOS and Android app icon |
| `splash.png` | 1284x2778 | Splash screen image |
| `adaptive-icon.png` | 1024x1024 | Android adaptive icon foreground |

## After adding images

Update `app.json` to point to them:

```json
{
  "expo": {
    "icon": "./assets/icon.png",
    "splash": {
      "image": "./assets/splash.png"
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png"
      }
    }
  }
}
```

Running `npm run setup` will also write these paths into `app.json` automatically once the files exist.
