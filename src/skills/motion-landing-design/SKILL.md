---
name: motion-landing-design
description: "Award-grade landing-page motion system — a concept taxonomy + divergence protocol for GSAP 3 + ScrollTrigger + Lenis scroll work. Pattern library (char-split reveals, text-mask reveals, clip-path wipes, SVG line-draw narratives, velocity skew, magnetic buttons, custom cursor + spotlight, film grain, velocity marquees, pinned rails, sticky-swap galleries, scroll-scrubbed state machines, pinned product frames, number roll-ups, border-beam orbits, view-transition page morphs, WebGL shader washes, scroll-velocity type stretch, exploded-diagram scrub, image-sequence scrubbing) — each entry names its intent, physics, when-to-use, and variation axes so every build comes out DIFFERENT. The mandatory divergence protocol forces fresh research + brand-derived motion before designing. Use for marketing/landing pages that need an award-winning feel — NOT app dashboards. Triggers on 'award-winning landing', 'scroll animation', 'scrolltrigger', 'micro animations', 'motion design', 'lenis', 'image sequence scroll'."
department: engineering
triggers:
  - award-winning landing
  - scroll animation
  - scrolltrigger
  - micro animations
  - motion design
  - lenis
  - image sequence scroll
  - landing page motion
  - magnetic button
  - pinned horizontal scroll
---

# Motion Landing Design

A **concept taxonomy + divergence protocol** for award-grade landing pages — the GSAP 3 · ScrollTrigger · Lenis scroll dialect. This is NOT a template and NOT a worked example. It is a library of motion *mechanisms* plus a forcing function that makes every generation come out different, brand-derived, and freshly researched.

**Why v2 exists:** a fixed example trains the executor to clone it — same chapter order, same section words, same palette energy. That is the failure this skill is built to prevent. Here, the patterns are ingredients; the **divergence protocol (§2) is the recipe-writing discipline** you must run first. The page's structure, vocabulary, and palette come from the *client's brand and fresh references* — never from this document.

> Stack anchor: GSAP 3.12+ · ScrollTrigger · Lenis 1.1+. CDN for prototypes; bundled (`npm i gsap lenis`) for production React. A `prefers-reduced-motion` fallback is **mandatory, not optional** — ship it every time.

**Use this** for marketing/landing/hero pages that need to feel earned. **Do NOT use it** for app dashboards — their motion budget is the inverse (sub-150ms confirmations, no scroll-jacking, no pinning, no custom cursor). For that, reach for the broader `motion` skill and `frontend-design`. Scroll-jacking a dashboard is a defect; scroll-chaptering a landing page is the craft.

---

## 0. Stack & setup (mechanical — same every time)

**Prototype (single HTML file):**
```html
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/gsap.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/gsap@3.12.5/dist/ScrollTrigger.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/lenis@1.1.14/dist/lenis.min.js"></script>
```

**Production React:** `npm i gsap lenis`, register once, drive Lenis off GSAP's ticker so ScrollTrigger and smooth-scroll share one clock:
```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import Lenis from "lenis";
gsap.registerPlugin(ScrollTrigger);

const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches;
const lenis = new Lenis({ lerp: 0.09, wheelMultiplier: 1.04 }); // ~.09 is a calm sweet spot; tune per brand
lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((t) => lenis.raf(t * 1000));
gsap.ticker.lagSmoothing(0);
```
In React, do all of this inside `useGSAP()` / a `useLayoutEffect` and **return `() => { lenis.destroy(); ScrollTrigger.getAll().forEach(t => t.kill()); }`** — leaked ScrollTriggers across route changes are the #1 production bug.

**Reduced-motion fallback (ALWAYS):**
```css
@media (prefers-reduced-motion: reduce){
  *,*::before,*::after{animation-duration:.01ms!important;animation-iteration-count:1!important;transition-duration:.01ms!important}
}
```
Guard every velocity/skew/parallax/pin effect behind `if (!reduced)`. Pinned sections must still render their **final** layout when reduced — never strand a user mid-scrub. (Stranding gotcha → §4.)

---

## 1. Concept taxonomy

Each entry is a *mechanism*, not a layout. Read **intent** (the feeling), **physics** (the mechanism + compact core), **use/avoid**, and **vary** (≥3 axes to make it look unlike any prior build). Mix and recombine — the page's identity comes from WHICH you pick, in what ORDER, against the brand. `--accent`, `--bg`, durations, and eases below are **placeholders the brand resolves** (see §2 Phase 1). Never ship the placeholder values as defaults.

### Reveal & type

**char-split reveal** — *intent:* a headline that arrives, not appears. *physics:* split each line into `inline-block` chars in an `overflow:hidden` clip; stagger `yPercent:118→0`.
```js
document.querySelectorAll(".ln").forEach(ln=>{ln.innerHTML=[...ln.textContent].map(c=>`<span class="ch">${c===" "?"&nbsp;":c}</span>`).join("");});
gsap.from(".ch",{yPercent:118,duration:1,ease:"power4.out",stagger:.028});
```
`.ln{display:block;overflow:hidden;white-space:nowrap}` (nowrap is load-bearing — §4). *use:* hero / chapter heads. *avoid:* body copy, >2 lines (dilutes). *vary:* axis of travel (up/rotateX/blur-in); stagger origin (l→r, center-out, random); unit (char vs word vs line); ease (power4 vs back vs expo).

**text-mask reveal** — *intent:* words wiped into existence by a moving edge. *physics:* `background:linear-gradient` clipped to text (`background-clip:text;color:transparent`), animate `background-position` or a `clip-path` inset on scroll.
```js
gsap.fromTo(".mask",{"--p":"0%"},{"--p":"100%",ease:"none",scrollTrigger:{trigger:".mask",start:"top 80%",end:"top 40%",scrub:1}});
/* .mask{background:linear-gradient(90deg,var(--accent) var(--p,0%),rgba(255,255,255,.18) var(--p,0%));-webkit-background-clip:text;background-clip:text;color:transparent} */
```
*use:* manifesto lines, value props. *avoid:* tiny type (clip jitters). *vary:* wipe direction/angle; hard edge vs soft gradient; per-word vs whole-paragraph; color-fill vs reveal-from-transparent.

**clip-path wipe** — *intent:* a panel or image uncovered like a curtain. *physics:* animate `clip-path` inset/polygon from collapsed to full on a scrub or enter.
```js
gsap.fromTo(".wipe",{clipPath:"inset(0 100% 0 0)"},{clipPath:"inset(0 0% 0 0)",ease:"power3.inOut",scrollTrigger:{trigger:".wipe",start:"top 75%",end:"top 35%",scrub:1}});
```
*use:* image reveals, section transitions, before/after. *avoid:* over-nesting (clip-path doesn't compose with overflow tricks cleanly). *vary:* shape (inset/circle/polygon diagonal); direction; paired counter-wipe on an inner layer for parallax-within-reveal.

**scroll-velocity type stretch** — *intent:* type that feels the speed of the scroll. *physics:* map `ScrollTrigger.getVelocity()` to `font-variation-settings` width/weight (variable font) or `scaleX`, clamped, via `quickTo`.
```js
if(!reduced){const wd=gsap.quickTo(".stretch","--wght",{duration:.3,ease:"power2"});
  ScrollTrigger.create({onUpdate:s=>wd(gsap.utils.clamp(380,760,500+Math.abs(s.getVelocity())/8))});}
```
*use:* one display word/marquee as a kinetic accent. *avoid:* whole paragraphs (illegible in motion). *vary:* axis (width vs weight vs slant vs scaleX); response curve; snap-back ease.

### Cursor, field & atmosphere

**velocity skew** — *intent:* the page leans into a fling. *physics:* skew a hero element by scroll velocity, clamped tight.
```js
if(!reduced){const skew=gsap.quickTo(".skewT","skewY",{duration:.4,ease:"power3"});
  ScrollTrigger.create({onUpdate:s=>skew(gsap.utils.clamp(-4,4,s.getVelocity()/-340))});}
```
*use:* hero headline, marquee band. *avoid:* anything users read while scrolling slowly. *vary:* axis (skewX/skewY/rotate); clamp width; sensitivity divisor.

**parallax layers** — *intent:* depth without 3D. *physics:* scrub multiple layers at different `y` rates over a trigger.
```js
[[".l1",-90],[".l2",-150],[".l3",-70]].forEach(([s,y])=>gsap.to(s,{y,ease:"none",scrollTrigger:{trigger:".hero",start:"top top",end:"bottom top",scrub:true}}));
```
*use:* hero backdrops, floating stat badges. *avoid:* mobile (hide layers <900px). *vary:* layer count; rate spread; axis (y vs x vs scale vs rotate drift).

**magnetic buttons** — *intent:* the CTA wants to be pressed. *physics:* element leans toward cursor on `mousemove`, elastic snap-back on leave.
```js
document.querySelectorAll(".magnetic").forEach(b=>{b.addEventListener("mousemove",e=>{const r=b.getBoundingClientRect();
  gsap.to(b,{x:(e.clientX-r.left-r.width/2)*.32,y:(e.clientY-r.top-r.height/2)*.42,duration:.4,ease:"power3.out"});});
  b.addEventListener("mouseleave",()=>gsap.to(b,{x:0,y:0,duration:.7,ease:"elastic.out(1,.45)"}));});
```
`will-change:transform`; skip on `pointer:coarse`. *use:* primary CTA, nav logo. *avoid:* dense button groups (they fight). *vary:* pull strength; snap ease (elastic vs back); whether label/icon counter-move.

**custom cursor + lagged ring + spotlight** — *intent:* a bespoke pointer that says "considered." *physics:* dot tracks instantly; ring lerps behind (`*.14`); a CSS-var radial follows.
```js
addEventListener("mousemove",e=>{cur.style.left=e.clientX+"px";cur.style.top=e.clientY+"px";
  spot.style.setProperty("--mx",e.clientX+"px");spot.style.setProperty("--my",e.clientY+"px");});
(function loop(){rx+=(mx-rx)*.14;ry+=(my-ry)*.14;ring.style.left=rx+"px";ring.style.top=ry+"px";requestAnimationFrame(loop)})();
/* #cur{mix-blend-mode:difference} keeps it visible over any bg; @media(max-width:900px) restore cursor:auto */
```
*use:* brand-forward sites with hover affordances. *avoid:* touch, content-heavy reading pages. *vary:* dot shape/blend; ring lerp lag; spotlight radius/softness; grow-on-hover targets.

**film grain / atmosphere** — *intent:* texture, analog warmth, a moodier black. *physics:* fixed overlay — SVG `feTurbulence` animated with `steps()` for judder, or a tiling noise png.
```css
body::after{content:"";position:fixed;inset:-100%;pointer-events:none;z-index:90;opacity:.05;
  background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");animation:grain 7s steps(8) infinite}
```
`inset:-100%` so the translate never exposes an edge; `opacity ≤ .06`. *use:* premium/noir/editorial brands. *avoid:* clean/clinical/SaaS-bright brands. *vary:* grain vs scanlines vs dust vs vignette pulse; opacity; tint.

**WebGL / canvas shader wash** — *intent:* a living, generative backdrop no stock asset can match. *physics:* a fragment shader (gradient flow, fbm noise, metaballs) on a full-bleed canvas, `uTime` ticked, optionally `uScroll`/`uMouse` driven. Keep it BEHIND content, `pointer-events:none`, paused off-screen.
```js
// minimal: requestAnimationFrame → set uniform uTime; feed lenis scroll into uScroll for reactive flow
gl.uniform1f(uTime, performance.now()*0.001);
```
*use:* hero of a tech/AI/crypto/audio brand where "generative" is on-message. *avoid:* perf-constrained pages, when it competes with foreground type. *vary:* shader family (flow-field vs caustics vs voronoi vs plasma); palette from brand; scroll/mouse reactivity on/off; resolution scale for perf.

### Marquees, rails & galleries

**velocity-reactive marquee** — *intent:* a band that surges with the scroll. *physics:* ticker loop whose base speed gets scroll velocity added; render content twice for a seamless wrap.
```js
function marquee(el,dir){let x=0,v=0;ScrollTrigger.create({onUpdate:s=>{v=gsap.utils.clamp(-14,14,s.getVelocity()/110)}});
  gsap.ticker.add(()=>{x-=(dir*.6+v);const w=el.scrollWidth/2;if(x<-w)x+=w;if(x>0)x-=w;el.style.transform=`translateX(${x}px)`});}
```
*use:* section dividers, logo/testimonial bands. *avoid:* >2 stacked (busy). *vary:* opposing dirs; content (text/logos/images); skew the whole band; reactivity strength.

**pinned horizontal rail** — *intent:* a sideways gallery that earns its scroll. *physics:* pin a section; translate an over-wide track 0→`-(scrollWidth-innerWidth)`. **`invalidateOnRefresh` mandatory** so distance recomputes on resize.
```js
const track=document.querySelector(".track"),dist=()=>track.scrollWidth-innerWidth;
gsap.to(track,{x:()=>-dist(),ease:"none",scrollTrigger:{trigger:".pin",start:"top 12%",end:()=>"+="+dist(),pin:true,scrub:1,invalidateOnRefresh:true}});
```
Function-values (`()=>`) for `x`/`end` so they re-evaluate on refresh. *use:* roster, product line, process steps. *avoid:* >~8 cards (scroll fatigue). *vary:* card shape/overlap; progress indicator; per-card enter-stagger as it crosses center.

**sticky-swap gallery** — *intent:* one pinned stage, content swapping in place as you scroll a list. *physics:* `position:sticky` visual + a sibling list of triggers; each list item's enter swaps the active media (crossfade), no pin-distance math.
```js
document.querySelectorAll(".swap-item").forEach((it,i)=>ScrollTrigger.create({trigger:it,start:"top 60%",end:"bottom 60%",
  onToggle:s=>{if(s.isActive){gsap.to(".stage-media",{opacity:0,duration:.2,onComplete:()=>setMedia(i)});gsap.to(".stage-media",{opacity:1,duration:.4,delay:.2})}}}));
```
*use:* feature tours, "how it works" with a persistent visual. *avoid:* when each item needs full-bleed (use pin instead). *vary:* swap transition (fade/slide/scale); sticky side (media left vs right); active-item emphasis.

### Scrubbed narratives

**scroll-scrubbed state machine** — *intent:* a thing visibly *earning* a status as you scroll. *physics:* pin; map `progress` to a **discrete** stage index; drive a setter.
```js
ScrollTrigger.create({trigger:".pin",start:"top 14%",end:"+=1500",pin:true,scrub:1,
  onUpdate(self){const i=Math.min(STAGES-1,Math.floor(self.progress*STAGES));setStage(i);}});
setStage(0); // init so pre-scroll state is correct
```
`Math.floor(p*N)` quantizes → the value is the discrete migration, not a smooth tween. `overwrite:"auto"` on the moving element. *use:* a process/pipeline/lifecycle story. *avoid:* purely decorative scrubbing. *vary:* number of stages; what moves (a card across columns, a bar filling, a map lighting up); the data shown per stage.

**SVG line-draw narrative** — *intent:* a path that draws itself to tell a sequence (a journey, a connection map, a signature). *physics:* set `stroke-dasharray = pathLength`, scrub `stroke-dashoffset` length→0; reveal nodes as the line reaches them.
```js
const p=document.querySelector(".path"),L=p.getTotalLength();p.style.strokeDasharray=L;p.style.strokeDashoffset=L;
gsap.to(p,{strokeDashoffset:0,ease:"none",scrollTrigger:{trigger:".path-sec",start:"top 70%",end:"bottom 60%",scrub:1}});
```
*use:* roadmaps, architecture diagrams, "our process," connected logos. *avoid:* when the path is decorative noise. *vary:* path shape; node pop timing; multiple paths racing; gradient stroke that travels.

**exploded-diagram scrub** — *intent:* a product/concept that assembles or disassembles as you scroll. *physics:* pin; map progress to each part's offset from its assembled position (lerp out along its own vector); reverse for assemble.
```js
parts.forEach((el,i)=>gsap.fromTo(el,{x:0,y:0,opacity:1},{x:el.dataset.dx,y:el.dataset.dy,ease:"none",
  scrollTrigger:{trigger:".explode",start:"top top",end:"+=1400",scrub:1,pin:i===0}}));
```
*use:* hardware, layered software stacks, "what's inside." *avoid:* flat/2D products with no parts. *vary:* explode vs assemble direction; labels that fly in per part; rotate the whole rig as it explodes.

**number roll-up** — *intent:* a stat that counts into place. *physics:* tween a throwaway object, `once:true`.
```js
ScrollTrigger.create({trigger:".fin",start:"top 60%",once:true,onEnter(){gsap.to({v:0},{v:TARGET,duration:1.6,ease:"power3.out",onUpdate(){el.textContent=Math.round(this.targets()[0].v)}})}});
```
*use:* metrics, pricing, social proof. *vary:* easing pace; prefix/suffix; odometer-style digit roll vs plain count; stagger multiple counters.

### Framed product & cinematic

**pinned product frame** — *intent:* the real product, framed and presented. *physics:* show the app in a chrome frame; scale a fixed-design-width iframe by `clientWidth/designWidth`; reveal on a scrub.
```js
function fit(){const f=document.querySelector(".frame iframe"),w=f.parentElement.clientWidth;f.style.transform=`scale(${w/1600})`;}
addEventListener("resize",fit);fit();
```
`pointer-events:none` on the iframe so scroll passes through; fixed design width (e.g. 1600) then scale — never responsive width on the iframe (internal reflow). *use:* showing a live UI. *avoid:* when a static shot suffices. *vary:* frame chrome (browser/device/none); reveal (scale-in vs tilt-in vs unfold); multiple frames in a fan.

**border-beam orbit** — *intent:* the highest grade of "this is alive" — a light orbiting one hero object. *physics:* `@property` angle + `conic-gradient` + `mask-composite:exclude` to hollow it to a 1px border.
```css
.beam::before{content:"";position:absolute;inset:-1px;border-radius:inherit;padding:1px;
  background:conic-gradient(from var(--ba,0deg),transparent 0 76%,var(--accent) 88%,#fff 94%,transparent 100%);
  -webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0);-webkit-mask-composite:xor;mask-composite:exclude;animation:orbit 5.2s linear infinite}
@property --ba{syntax:'<angle>';initial-value:0deg;inherits:false}@keyframes orbit{to{--ba:360deg}}
```
`@property` is what lets the angle interpolate. **One beam per viewport, max** — reserve it for the single hero object. *vary:* orbit speed; beam width/falloff; dual counter-orbiting beams; color from brand accent only.

**view-transition page morph** — *intent:* routes that morph instead of cut — a shared element flows from card to detail. *physics:* the View Transitions API; tag the shared element with matching `view-transition-name` on both views; wrap the nav in `document.startViewTransition`.
```js
if(document.startViewTransition){link.addEventListener("click",e=>{e.preventDefault();document.startViewTransition(()=>navigate(href));});}
/* .hero-card{view-transition-name:feature-3} same name on the destination's hero */
```
*use:* multi-page brand sites, gallery→detail. *avoid:* when no element is genuinely shared. *vary:* which element morphs; custom `::view-transition-*` keyframes; fade vs slide vs scale the rest.

**image-sequence scrub (the Apple technique)** — *intent:* cinematic product hero scrubbed frame-by-frame. *physics:* extract ~100–150 webp frames; preload into `Image[]`; draw `round(progress*(n-1))` to a `<canvas>` under a pin.
```bash
ffmpeg -i in.mp4 -vf "fps=30,scale=1600:-1" -q:v 70 frames/%03d.webp   # 100–150 frames: fewer judders, more bloats
```
```js
ScrollTrigger.create({trigger:".seqPin",start:"top top",end:"+=2400",pin:true,scrub:1,
  onUpdate(s){const f=Math.round(s.progress*(N-1));if(f!==cur){cur=f;ctx.drawImage(imgs[f],0,0,canvas.width,canvas.height)}}});
```
Set `canvas.width/height` in JS (not just CSS) or it draws blurry; only redraw on integer-frame change. *use:* a flagship product moment. *avoid:* when you have no good source footage. *vary:* what scrubs (product spin / liquid / type morph); frame count; paired text overlays per range.

---

## 2. Divergence protocol (mandatory — the heart of v2)

Run these phases **in order, every time**. This is what makes generations differ. Do not skip Phase 0 or Phase 1 because the request "seems clear."

> **ANTI-ANCHOR RULE (absolute):** Never reuse the structure, section sequence, section vocabulary, or palette of ANY prior build or reference — including anything you have seen, this skill's examples, or a sibling page. References are *quality bars and idea fuel, not blueprints.* If your output's skeleton matches a previous one, you have failed the brief. The brand's soul, not a remembered layout, decides the page.

### Phase 0 — Research (before any design)
1. **Study the live brand.** Read the client's existing site/app/brand doc. Extract: what the product *is*, its tone (clinical? rebellious? luxurious? playful?), its existing palette/type, and the ONE feeling it must leave. Capture the brand's "physical metaphor" — does this brand feel like *liquid*, *machined metal*, *paper*, *light*, *circuitry*, *fabric*? That metaphor will dictate motion.
2. **Pull ≥2 FRESH external motion references** via web/X research tools (Awwwards, Godly, FWA, X/dribbble motion posts, recent agency sites). They must be NEW to this build — not from memory. Note *what mechanism* each uses and *why it works for that brand*.
3. **Cite them in the direction memo** (name + URL + the one idea you're taking as inspiration, not as a template).

### Phase 1 — Align (propose, then WAIT for lock)
1. Propose **2–3 NAMED directions** (e.g. "Tidal," "Blueprint," "Broadcast"). Each names: the controlling **brand-derived motion metaphor** (the brand's soul dictates how things move — liquid brand → easing that overshoots and settles like water; machined brand → crisp `power4` snaps and grid pins; paper brand → folds, clip-path creases, page-turn morphs), the rough chapter idea (NOT borrowed from any example), and the palette **derived from the client brand** (never a default).
2. **Novelty quota:** each direction must include **≥3 motion ideas NOT in this skill's taxonomy** — invented for this brand or pulled from the fresh references. The taxonomy is your floor, not your ceiling.
3. **Ask the operator/client questions** that change the design (brand assets available? hero metaphor? must-have proof? motion appetite vs accessibility/perf constraints? any sacred brand rules?).
4. **WAIT for direction lock.** Do not build the page until a direction is chosen. (You may build a tiny concept artifact in Phase 2 to *help* the choice, but not the full page.)

### Phase 2 — Build
1. **Concept artifact first** — one chapter or the hero, in the locked direction, as a single proof. Get a read on it before committing the whole page.
2. Then build out, composing taxonomy mechanisms + the novel ideas, structured by the locked direction's own narrative — never this document's order.

### Phase 3 — Verify (do this before claiming done — kept verbatim from v1, it's load-bearing)
Motion bugs are invisible in code review — you must *watch the page scroll*. Use the agent-browser CLI in a **single batch** (open → scroll-through → screenshot), **isolated session** (`close --all` + `sleep 2` first; never parallel browsers on one session), at viewport **1920×1080**:
1. Open the page; scroll top→bottom capturing a screenshot at each chapter boundary.
2. Inspect every capture for: **headline wrap bugs** (char-split nowrap), **pin distances** (does a pin release too early/late, leaving dead scroll or overlap), **overshoot** (does a scrubbed element fly past its target), marquee seam jumps, and **reduced-motion stranding** (re-run with the media query forced — confirm no section is stuck mid-scrub; if states look wrong, it's usually the late-refresh gotcha in §4).
3. Fix what the screenshots show.
4. **Recapture** — never declare done off the pre-fix screenshots.

Report **PASS/MISS per chapter** with the screenshot as evidence. "Looks right in the code" is not verification for motion.

---

## 3. Asset pipeline (when you need character-consistent brand figures)

For agent rosters, founder portraits, or mascots, use **Higgsfield MCP with a Soul** so every image shares one identity.
- Create/reuse a Soul: pass `soul_2` + the `soul_id` so the same face/wardrobe recurs across the set.
- **Prompt formula (palette stays brand-derived):** `"[editorial/cinematic] portrait of [role], [wardrobe + brand badge], [brand-derived studio/setting], single [brand-accent]-colored key light, [secondary] rim light, [brand-mood] shadows, premium magazine aesthetic, 85mm, no text or letters anywhere in frame"`.
- Put the **brand badge on the wardrobe** (lapel pin, chest patch) so it's diegetic, not pasted.
- **Palette-lock the accent** to the page's brand accent — the key light is the only saturated color in frame.
- **"no text or letters anywhere in frame"** is mandatory — it suppresses the garbled-glyph artifact.
- Keep setting + shadow grammar constant across the set so the cards read as one family, not a stock grab bag.

---

## 4. Field notes — production gotchas (every one bit live; keep them)

- **`white-space:nowrap` on char-split lines is non-negotiable.** Without it, `inline-block` chars wrap mid-word as the viewport narrows and the headline shatters. Each line is its own `overflow:hidden` clip so chars rise from a clean edge.
- **Clamp velocity-driven effects tight.** `getVelocity()` spikes huge on fling-scroll; unclamped skew/stretch looks broken. Tune the sensitivity divisor (bigger = subtler).
- **Pin distance must use function-values + `invalidateOnRefresh`.** `x:()=>-dist()` and `end:()=>"+="+dist()` re-evaluate on resize/font-load; a hardcoded distance breaks the instant layout shifts.
- **minterpolate / frame-sequence quirks:** preload every frame before wiring scroll (decode jank otherwise); size the canvas in JS not CSS (else blurry); redraw only on integer-frame change. (Building a *demo video* from stills instead? `minterpolate` TRIMS the tail — `ffprobe` real durations before timing math. See `demo-video-pipeline`.)
- **Reduced-motion stranding via late refresh:** when you build the reduced-motion branch, a `ScrollTrigger.refresh()` firing after content/fonts load can leave a pinned section frozen mid-scrub for reduced-motion users. Render final states explicitly in the reduced branch and re-check after refresh — don't trust the first paint.
- **iframe-black screenshots:** a `file://` iframe (or a not-yet-loaded one) screenshots black. Give it load time / serve over http before capture; `pointer-events:none` so scroll passes through.
- **Serial browser discipline:** `close --all` + `sleep 2` between batches; never run parallel agent-browser on one session — captures collide and you verify the wrong frame.
- **Prototype-CDN vs production-bundled:** CDN `<script>` tags are fine for a single-file concept artifact; production React must `npm i gsap lenis`, register inside `useGSAP`/`useLayoutEffect`, and **kill Lenis + every ScrollTrigger on unmount** or route changes leak triggers (the #1 prod bug).
- **`overwrite:"auto"`** on any element multiple tweens target (scrubbed movers, magnetic snap) so queued tweens don't fight on fast scroll. `setStage(0)` / init call once so the pre-scroll state is correct.
- **`@property` is required** for animating a CSS-var angle (border-beam) — a plain custom property won't interpolate.

**ANTI-ANCHOR WARNING:** any reference build you study is a *specific brand's* solution. Study references for craft and the gotchas they survived — never for structure, section order, vocabulary, or palette. If a new build comes out shaped like its reference, the divergence protocol (§2) was skipped. Every brand gets its own skeleton.
