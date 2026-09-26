---
name: expo-cinematic-motion
description: "Premium dark cinematic motion for Expo/React Native apps — Skia SkSL shader splash overlays, film grain, beam sweeps, Reanimated 4.4 CSS animations. Use when building animated splash screens, cinematic dark UI, or premium motion systems. Triggers on 'cinematic splash', 'skia shader', 'film grain', 'beam sweep', 'premium motion', 'animated splash', 'dark cinematic ui', 'void cinematic', 'shader background', 'rn splash animation', 'expo splash overlay', 'sksl', 'fractal noise', 'turbulence rn'."
department: engineering
triggers:
  - cinematic splash
  - skia shader
  - film grain
  - beam sweep
  - premium motion
  - animated splash
  - dark cinematic ui
  - void cinematic
  - shader background
  - rn splash animation
  - expo splash overlay
  - sksl
  - fractal noise
  - turbulence rn
---

# Expo Cinematic Motion

Premium dark cinematic motion patterns for Expo and React Native. The aesthetic: flat-hairline dark design systems — matte black fills, void backgrounds, precise light effects (beam sweeps, film grain) — no glassmorphism, no sheen, no blob gradients. Pairs directly with flat-hairline NativeWind design systems.

## When to Use

- Building an animated splash overlay (before or after the native static splash)
- Adding cinematic film grain to a dark screen
- A beam/light-sweep that passes through a wordmark or logo
- Any Reanimated 4.4 CSS-driven component entry animation (letter-spacing reveal, opacity reveal)
- A non-Skia fallback using Reanimated + expo-linear-gradient

## When NOT to Use

- Glassmorphism, frosted-glass, blur-backdrop, or sheen effects — those are anti-patterns for this aesthetic
- Screens where Expo UI (SwiftUI/Compose) components are prominent — native look conflicts with the cinematic layer
- Apps without `react-native-skia` installed and no intent to add it — use the baseline non-Skia fallback below

---

## Part 1: Splash Overlay Contract

### Component shape

```tsx
// components/SplashOverlay.tsx
interface SplashOverlayProps {
  onDone: () => void;
}
```

Rules:
- **Self-contained** — receives only `onDone`. No knowledge of app routing, auth state, or external stores.
- **Duration ≤ 2 seconds** from mount to `onDone()` call. Users reject longer splash sequences.
- **MANDATORY reduced-motion check.** Every animated splash must detect `AccessibilityInfo.isReduceMotionEnabled()` and provide an instant-fade path. A cinematic splash that ignores `reduceMotion` is an accessibility failure.
- **Native splash stays static behind it.** The native splash image (configured in `app.json`) shows until the JS bundle loads. The `<SplashOverlay>` mounts on top and owns the animated dismissal. Never try to animate the native splash itself.

### Reduced-motion path

```tsx
import { AccessibilityInfo } from 'react-native';
import { useEffect, useState } from 'react';

function usePrefersReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    AccessibilityInfo.isReduceMotionEnabled().then(setReduced);
    const sub = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduced);
    return () => sub.remove();
  }, []);
  return reduced;
}
```

In the overlay: if `prefersReducedMotion`, skip to a 150ms opacity fade and call `onDone()` immediately.

---

## Part 2: Skia Shader Splash (Full Implementation)

### Architecture

One full-screen `<Canvas>` overlay. One SkSL `RuntimeEffect` for the beam pass. Film grain in the same pass or via `<FractalNoise>`. All uniforms driven by `useClock()` + `useDerivedValue` — zero React re-renders during animation.

```tsx
import { Canvas, Fill, Shader, Skia, useClock } from '@shopify/react-native-skia';
import { Dimensions, StyleSheet } from 'react-native';

// SkSL: beam sweep + hash-noise grain in one pass
const SPLASH_SHADER_SRC = `
uniform float2 resolution;
uniform float time;        // 0 → 1 progress
uniform float grainSeed;   // advances each frame

// Hash-based noise (no texture lookup required)
float hash(float2 p) {
  return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float grain(float2 uv, float seed) {
  return hash(uv * resolution + seed) * 2.0 - 1.0;
}

// Beam: rotated-UV smooth-step band
float beam(float2 uv, float t) {
  float angle = radians(-35.0);
  float2 rotUV = float2(
    uv.x * cos(angle) - uv.y * sin(angle),
    uv.x * sin(angle) + uv.y * cos(angle)
  );
  float edge = 0.04;
  float bandCenter = t * 1.6 - 0.3;
  return smoothstep(bandCenter - edge, bandCenter, rotUV.x)
       - smoothstep(bandCenter, bandCenter + edge, rotUV.x);
}

half4 main(float2 fragCoord) {
  float2 uv = fragCoord / resolution;

  // Base: void fill
  half4 base = half4(0.04, 0.04, 0.04, 1.0);

  // Beam (additive, masked to center band)
  float b = beam(uv, time) * 0.35;
  half4 beamColor = half4(b * 0.9, b * 0.95, b, 0.0);  // slightly cool white

  // Film grain (overlay blend approximation)
  float g = grain(uv, grainSeed) * 0.05;  // 3–8% opacity
  half4 grainColor = half4(g, g, g, 0.0);

  return base + beamColor + grainColor;
}
`;

const effect = Skia.RuntimeEffect.Make(SPLASH_SHADER_SRC)!;
```

### Driving uniforms from Reanimated

```tsx
import Animated, {
  useSharedValue, useDerivedValue, useAnimatedStyle, withTiming, runOnJS,
} from 'react-native-reanimated';

const { width, height } = Dimensions.get('window');

export function SplashOverlay({ onDone }: SplashOverlayProps) {
  const clock = useClock();
  const progress = useSharedValue(0);
  const opacity = useSharedValue(1);
  const reduced = usePrefersReducedMotion();

  useEffect(() => {
    if (reduced) {
      // Instant path
      setTimeout(onDone, 150);
      return;
    }
    // 1.6s beam sweep + 0.3s fade-out = ~1.9s total
    progress.value = withTiming(1, { duration: 1600 });
    setTimeout(() => {
      opacity.value = withTiming(0, { duration: 300 }, () => runOnJS(onDone)());
    }, 1400);
  }, []);

  const uniforms = useDerivedValue(() => ({
    resolution: [width, height] as [number, number],
    time: progress.value,
    grainSeed: (clock.value / 16) % 1000,  // advances ~60 fps
  }));

  const animatedStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));

  return (
    <Animated.View style={[StyleSheet.absoluteFill, animatedStyle]}>
      <Canvas style={StyleSheet.absoluteFill}>
        <Fill>
          <Shader source={effect} uniforms={uniforms} />
        </Fill>
      </Canvas>
    </Animated.View>
  );
}
```

### Built-in FractalNoise alternative (simpler, no custom SkSL)

When the beam is handled separately (e.g., via a LinearGradient transform), use Skia's built-in noise filter for grain only:

```tsx
import { Canvas, Rect, FractalNoise } from '@shopify/react-native-skia';

// Grain overlay layer — mount on top of the screen, pointerEvents="none"
// The noise shader nests directly in <Rect>; compositing is via the Rect's
// blendMode + opacity props (no <Blend> wrapper — that composites multiple shaders).
<Canvas style={StyleSheet.absoluteFill} pointerEvents="none">
  <Rect x={0} y={0} width={width} height={height} opacity={0.05} blendMode="overlay">
    <FractalNoise freqX={0.65} freqY={0.65} octaves={2} />
  </Rect>
</Canvas>
```

For **animated grain** (grain that shifts frame-by-frame), increment a `seed` uniform via `useClock()` — static grain reads as texture, animated grain reads as film.

### 60fps budget notes

- Keep octaves ≤ 2–3 for FractalNoise; higher octaves are expensive on low-end Android.
- One Canvas, not multiple stacked Canvases.
- On low-end Android, degrade to static (non-animated) grain — detect with `Platform.OS === 'android'` + a device performance heuristic or a user preference flag.
- Profile before and after the Skia Graphite/WebGPU migration — confirm shader code runs on the new backend in CI before pinning versions.

---

## Part 3: Reanimated 4.4 CSS API (Non-Shader Component Motion)

For letter-spacing reveals, opacity fades, and `entering`/`exiting` transitions — Reanimated 4.4's CSS animations API (new-arch only):

The CSS API is driven entirely through **style props** (`animationName`, `animationDuration`, `animationTimingFunction`, `animationIterationCount`, …). `animationName` holds a plain keyframes object (`from` / `to` / `'NN%'` keys). There is no `animatedProps.animation` shape — that does not exist.

```tsx
import Animated from 'react-native-reanimated';

// Letter-spacing reveal (wordmark entrance) — keyframes object, not a special type
const revealKeyframes = {
  from: { opacity: 0, letterSpacing: 12 },
  to: { opacity: 1, letterSpacing: 0 },
};

<Animated.Text
  style={[
    styles.wordmark,
    {
      animationName: revealKeyframes,
      animationDuration: '800ms',
      animationTimingFunction: 'ease-out',
      animationFillMode: 'forwards',
    },
  ]}
>
  WORDMARK
</Animated.Text>
```

Reanimated 4.4 note: the iOS Core Animation-backed CSS engine is behind the `IOS_CSS_CORE_ANIMATION` flag in 4.4.0 — enable in your Reanimated config for hardware-accelerated CSS timing on iOS. Check for Reanimated-4.4 compatibility with gorhom/bottom-sheet before upgrading (open bugs #2690, #2678 — pin 4.3.1 if the app uses bottom sheets heavily).

---

## Part 4: Baseline Non-Skia Fallback

When `react-native-skia` is not installed:

```tsx
import { useEffect } from 'react';
import { StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue, useAnimatedStyle, withTiming, withSequence, runOnJS,
} from 'react-native-reanimated';

export function SplashOverlayFallback({ onDone }: SplashOverlayProps) {
  const opacity = useSharedValue(0);
  const beamX = useSharedValue(-0.5);

  useEffect(() => {
    // Fade in void
    opacity.value = withTiming(1, { duration: 200 });
    // Beam sweep via gradient translateX
    beamX.value = withSequence(
      withTiming(1.5, { duration: 1200 }),
      withTiming(1.5, { duration: 200 }, () => {
        opacity.value = withTiming(0, { duration: 300 }, () => runOnJS(onDone)());
      }),
    );
  }, []);

  const containerStyle = useAnimatedStyle(() => ({ opacity: opacity.value }));
  const beamStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: beamX.value * 400 }],
  }));

  return (
    <Animated.View style={[StyleSheet.absoluteFill, containerStyle, { backgroundColor: '#0a0a0a' }]}>
      <Animated.View style={[styles.beam, beamStyle]}>
        <LinearGradient
          colors={['transparent', 'rgba(220,230,255,0.18)', 'transparent']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={StyleSheet.absoluteFill}
        />
      </Animated.View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  beam: {
    position: 'absolute',
    top: 0, bottom: 0,
    width: 120,
    transform: [{ rotate: '-35deg' }],
  },
});
```

This version omits film grain (no shader) but preserves the beam sweep and void fill. Swap for the full Skia version when Skia is added to the project.

---

## Part 5: References

| Source | What to copy |
|--------|-------------|
| `github.com/maazjnr/PremiumWallet_Template` | Open-source Expo app with aurora SkSL shader background + 60fps transitions; closest full implementation of this splash architecture |
| `github.com/ainalem/FilmGrainShader` | RN Skia animated-grain-over-gradient demo with intensity control |
| Skia docs `shaders/perlin-noise` | FractalNoise/Turbulence props + "Organic Background" overlay-blend recipe on dark fill |
| William Candillon (can.dev / YouTube) | Uniforms-from-Reanimated patterns; gradient/aurora and shader-transition recipes; GLSL→SkSL conversion discipline (`image.eval()` not `texture()`) |
| `@m090009` ShaderWrapper pattern | Snapshot any `<View>` → overlay Canvas → `RuntimeShader` — grain over arbitrary live UI |
| `@reactiive_` (Enzo Mangano) | Skia shader-over-UI patterns, 120+ open-source RN animations |

---

## Aesthetic Guardrail

This skill pairs with flat-hairline dark design systems:
- Void black base fills (`#0a0a0a`–`#111`)
- Single-pixel hairline borders (`border-[0.5px]`)
- Monochrome or near-monochrome palettes
- Additive-blend light effects (beam as `plus`/`screen` blend mode)

**Anti-patterns for this aesthetic:** glassmorphism, frosted-blur, sheen overlays, rainbow gradients, excessive glow, neon. If a component looks like a glass card, it does not belong in this system.

---

## Quality Gates

- [ ] `AccessibilityInfo.isReduceMotionEnabled()` checked; instant-fade path wired
- [ ] Splash duration ≤ 2s from mount to `onDone()`
- [ ] Grain octaves ≤ 3; one Canvas (not stacked)
- [ ] All uniforms driven via `useDerivedValue` — no `setState` inside animation loop
- [ ] Skia Graphite migration compatibility checked before pinning versions
- [ ] Non-Skia fallback exists or is deliberately omitted with a comment

## Related Skills

- `expo` — SDK version facts, component adoption table, Expo UI notes
- `mobile-shipping` — native splash config in `app.json`, pre-EAS smoke test
- `apple-platform-design` — when the cinematic layer must coexist with native toolbars or `Stack.Toolbar`
