---
name: motion
description: "One general-purpose web animation skill — GSAP 3.15 + ScrollTrigger, Motion v12 (ex-Framer), Anime.js v4 ESM, View Transitions API (SPA+MPA), CSS scroll-driven animations, WAAPI, and a Three.js r184 WebGPU deep-dive. Use when adding scroll, page-transition, gesture, micro-interaction, or 3D animation to a web UI. Triggers on 'animation', 'gsap', 'scrolltrigger', 'framer motion', 'motion', 'anime.js', 'view transition', 'scroll-driven', 'three.js', 'webgpu', 'scroll animation', 'page transition', 'reduced motion'."
department: engineering
triggers:
  - animation
  - gsap
  - scrolltrigger
  - framer motion
  - motion
  - anime.js
  - view transition
  - scroll-driven
  - three.js
  - webgpu
  - page transition
  - reduced motion
---

# Motion (Web Animation)

The general-purpose web-animation skill: pick the right library for the job, implement it correctly at current versions, and never ship motion that ignores `prefers-reduced-motion`. Covers production scroll work, page transitions, React component animation, lightweight SVG motion, and 3D.

> Reference snapshot, 2026-06-05: GSAP 3.15.0 · Motion for React v12 (`motion/react`) · Anime.js v4.4.1 · Three.js r184. Resolve the project's dependency and browser-support targets before selecting an API; this snapshot is not an upgrade instruction.

## When to Use

- Scroll-linked reveals, pinning, horizontal scroll, scroll progress
- Page/route transitions between views or documents
- React component enter/exit, layout, gesture animation
- Lightweight SVG / draggable / scroll-synced micro-motion
- 3D scenes, WebGL/WebGPU canvas layers

Skip for: the aesthetic decision of *whether/how much* to animate (use `design-taste`); component-level Motion usage inside a feature build (covered briefly in `frontend-design`); HyperFrames seek-driven video rendering (use the HyperFrames adapter skills — see the note at the end).

## Core DNA

1. **Library selection is the first decision.** Match the task to the lightest tool that does it — see the decision table. Don't reach for GSAP when CSS scroll-driven suffices, or for Three.js when 2D motion works.
2. **Animate `transform`/`opacity` only.** They stay on the compositor. `will-change: transform` before, remove after.
3. **Reduced motion is mandatory, every library.** `gsap.matchMedia()`, `<MotionConfig reducedMotion="user">`, or a `@media` wrapper — provide a calmer alternative, never just disable.
4. **Clean up on unmount / route change.** Orphaned ScrollTriggers and RAF loops leak; kill them.
5. **Use current APIs.** Anime.js v3 syntax errors on v4. Framer Motion is now `motion`. Three.js Clock is deprecated → Timer.

## Key Patterns

### Library selection decision tree

| Task | Use | Why |
|------|-----|-----|
| Simple single-element scroll progress/reveal, no JS | CSS scroll-driven (`animation-timeline`) | Zero-dep, compositor-driven |
| Page / view / route transition | View Transitions API | Native crossfade + shared element |
| Complex scroll sequences, pin, horizontal scroll | GSAP + ScrollTrigger | Battle-tested scroll engine |
| React component enter/exit/layout/gesture | Motion v12 | React-native, interruptible, WAAPI-backed |
| Lightweight SVG / draggable / scroll-synced micro | Anime.js v4 | Compact ESM, `waapi.animate()` 3KB |
| 3D / WebGL / WebGPU | Three.js r184 | WebGPURenderer + RenderPipeline |
| Native zero-dep keyframe | WAAPI `element.animate()` | No library at all |

### GSAP 3.15 + ScrollTrigger

```tsx
import { useGSAP } from "@gsap/react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
gsap.registerPlugin(ScrollTrigger, useGSAP);

function Section() {
  const ref = useRef<HTMLDivElement>(null);
  useGSAP(() => {
    const tl = gsap.timeline({
      scrollTrigger: { trigger: ref.current, start: "top 80%", end: "bottom 20%", scrub: true },
    });
    tl.from(".item", { y: 48, opacity: 0, stagger: 0.1, ease: "power3.out" });
  }, { scope: ref });   // useGSAP auto-reverts on unmount
  return <div ref={ref}>...</div>;
}
```

- `scrub` and `toggleActions` are **mutually exclusive** — pick one per ScrollTrigger.
- Put the ScrollTrigger on the **timeline**, not on child tweens.
- Horizontal scroll via `containerAnimation` **requires `ease: "none"`** (the #1 horizontal-scroll bug).
- `ScrollTrigger.batch(".items", {...})` over per-element triggers; `ScrollTrigger.refresh()` after layout changes.
- SPA route cleanup: `ScrollTrigger.getAll().forEach((st) => st.kill())` in a pathname effect.
- Reduced motion: `gsap.matchMedia()` with a `reduceMotion: "(prefers-reduced-motion: reduce)"` condition.
- DO NOT: ScrollTrigger on child tweens, infinite repeat in prod, `markers: true` in prod.

### Motion v12 (React)

```tsx
import { motion, AnimatePresence, useScroll, useTransform, MotionConfig, LazyMotion, domAnimation, m } from "motion/react";

// framer-motion → motion: package renamed; import from 'motion/react'.
<motion.section initial={{ opacity: 0, y: 24 }} whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true }} transition={{ type: "spring", bounce: 0, duration: 0.4 }} />

<motion.div layout layoutId="card" />                 {/* shared-element + interruptible */}
<AnimatePresence>{open && <motion.div exit={{ opacity: 0 }} />}</AnimatePresence>

// Bundle: LazyMotion + m drops ~34kb → ~4.6kb
<LazyMotion features={domAnimation}><m.div animate={{ x: 100 }} /></LazyMotion>

// Global a11y
<MotionConfig reducedMotion="user">{children}</MotionConfig>
```

v12 adds oklch/oklab/`color-mix` animation, hardware-accelerated scroll via ScrollTimeline, axis-locked layout, React 19 compat.

### View Transitions API

```js
// SPA — feature-detect, fallback to instant swap
if (document.startViewTransition) document.startViewTransition(() => updateDOM());
else updateDOM();
```

```css
/* MPA — cross-document, opt in with one CSS rule */
@view-transition { navigation: auto; }
::view-transition-old(root), ::view-transition-new(root) { animation-duration: 0.3s; }

/* Shared element across the transition */
.hero { view-transition-name: hero; }
```

React 19.3's `<ViewTransition>` is stable for the DOM. It runs only when its update is marked as a React Transition (`startTransition`, `useDeferredValue`, or a Suspense reveal); it does not currently apply to React Native. Progressive-enhancement: unsupported browser View Transition APIs get an instant swap.

### CSS scroll-driven animations

```css
@media not (prefers-reduced-motion: reduce) {
  .reveal {
    animation: fade-up linear both;
    animation-timeline: view();      /* or scroll() for page progress */
    animation-range: entry 0% cover 40%;
  }
}
@keyframes fade-up { from { opacity: 0; transform: translateY(40px); } to { opacity: 1; transform: none; } }
```

CRITICAL: declare `animation-timeline` AFTER the `animation` shorthand or the shorthand resets it. Firefox does NOT support scroll-driven animations (Jun 2026) — provide a fallback or use GSAP ScrollTrigger as progressive enhancement. Prefer this over GSAP for simple single-element cases.

### Anime.js v4 (ESM rewrite — v3 syntax will error)

```js
import { animate, createTimeline, createDraggable, svg, waapi, onScroll } from "animejs";

animate(".mark", {
  x: 280, rotate: "1turn", opacity: [0, 1],
  duration: 1200, ease: "outExpo",          // v3 'easeOutExpo' → 'outExpo'; 'easing' → 'ease'
  onRender: () => {},                        // v3 'change' → 'onRender'; 'loopComplete' → 'onLoop'
  autoplay: onScroll({ sync: true }),        // scroll-synced
});

const tl = createTimeline().add(".title", { y: [40, 0] }).add(".accent", { scaleX: [0, 1] }, 250);
createDraggable(".chip");
waapi.animate(".x", { opacity: 1 }, { duration: 500 });   // 3KB WAAPI path
```

Renames: `anime()` global gone (named imports), `anime.path()` → `svg.createMotionPath()`, `anime.setDashoffset()` → `svg.createDrawable()`, `direction` → `reversed`/`alternate`, `composition: 'blend'` for additive. v4.4.0 fixed transform order (breaking). See the v3→v4 migration guide before porting.

### WAAPI

```js
const anim = el.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 400, fill: "both" });
el.getAnimations().forEach((a) => a.cancel());     // inspect/cancel
// ScrollTimeline / ViewTimeline available Chrome 115+; Motion v12 and Anime.js waapi.animate() wrap this.
```

### Three.js r184 — WebGPU deep-dive

```js
import * as THREE from "three/webgpu";
import { pass, bloom } from "three/tsl";

const renderer = new THREE.WebGPURenderer({ antialias: true });  // auto-falls-back to WebGL2
renderer.setSize(w, h);

// Timer replaces the deprecated Clock (r184)
const timer = new THREE.Timer();
function frame(ts) { timer.update(ts); mixer?.update(timer.getDelta()); renderer.renderAsync(scene, camera); requestAnimationFrame(frame); }

// RenderPipeline replaces EffectComposer/PostProcessing (EffectComposer is legacy WebGL-only)
const post = new THREE.PostProcessing(renderer);
post.outputNode = bloom(pass(scene, camera));
```

- `three/webgpu` + `three/tsl` for renderer, materials, and post-processing via TSL nodes; supports MRT.
- `AnimationMixer.setTime(t)` for deterministic seek; `.update(delta)` for real-time.
- Lazy-load Three.js (`import()`); it's a large dependency. Cap pixel ratio (`Math.min(devicePixelRatio, 2)`).

### Universal performance + reduced-motion

```js
// will-change before, clear after
gsap.set(el, { willChange: "transform" });
// ...animation...
gsap.set(el, { clearProps: "all" });

ScrollTrigger.config({ limitCallbacks: true, ignoreMobileResize: true });
```

Animate `transform`/`opacity` only. Use `ScrollTrigger.batch()` over per-element triggers. Test under 4x CPU throttle. Every library gets a reduced-motion path: `gsap.matchMedia()` / `MotionConfig reducedMotion="user"` / `@media not (prefers-reduced-motion)`.

## Anti-Patterns

- Reaching for GSAP/Three.js when CSS scroll-driven or WAAPI does the job.
- Animating `width`/`height`/`top`/`left` instead of `transform`/`opacity`.
- Shipping any animation with no `prefers-reduced-motion` path.
- ScrollTrigger on child tweens; `scrub` + `toggleActions` together; `markers: true` / infinite repeat in prod.
- `containerAnimation` horizontal scroll without `ease: "none"`.
- Not cleaning up ScrollTriggers / RAF loops on unmount or route change (memory leak).
- Anime.js v3 syntax on v4 (`easing`, `'easeOutExpo'`, `anime()` global) — it errors.
- Declaring `animation-timeline` before the `animation` shorthand (shorthand resets it).
- Three.js Clock (deprecated r184) → use Timer; EffectComposer for new post-processing → use RenderPipeline.
- Assuming View Transitions / scroll-driven everywhere — Firefox lacks scroll-driven; feature-detect and fall back.

## Quality Gates

- [ ] Library chosen via the decision table (lightest tool that does the job)
- [ ] Only `transform`/`opacity` animated; `will-change` set before and cleared after
- [ ] Reduced-motion path present in EVERY library used (matchMedia / MotionConfig / @media)
- [ ] ScrollTriggers and RAF loops cleaned up on unmount / route change
- [ ] GSAP: ScrollTrigger on timeline, one of scrub/toggleActions, `ease:"none"` for horizontal `containerAnimation`
- [ ] Motion imported from `motion/react`; LazyMotion+`m` where bundle matters
- [ ] Anime.js uses v4 named imports and renamed options (no v3 syntax)
- [ ] `animation-timeline` declared after `animation`; Firefox scroll-driven fallback provided
- [ ] View Transitions feature-detected with a fallback path
- [ ] Three.js: `three/webgpu`, Timer (not Clock), RenderPipeline (not EffectComposer), capped pixel ratio, lazy-loaded
- [ ] Verified under 4x CPU throttle

## HyperFrames note

The six legacy adapter skills (`css-animations`, `animejs`, `gsap`, `three`, `waapi`, `lottie`) cover **HyperFrames seek-driven video rendering** — paused timelines registered on `window.__timelines` / `window.__hfAnime`, finite durations, render-from-time not wall-clock. That is a different problem from general UI motion. For HyperFrames compositions, use those adapter skills; for everything on the live web, use this skill.
