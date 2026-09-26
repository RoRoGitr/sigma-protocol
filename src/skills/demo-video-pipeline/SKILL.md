---
name: demo-video-pipeline
description: "Generate smooth product-demo videos from any web UI using screenshot sequences + ffmpeg motion-compensated interpolation — no screen recorder needed. Deterministic scroll-tour videos: agent-browser captures stills at scroll steps, minterpolate turns them into buttery 30fps scrolling, concat assembles multi-page tours. Use for waitlist/landing demo videos, app tours, release teasers, or whenever native recording is broken/unavailable. Triggers on 'demo video', 'product tour video', 'record the app', 'screen recording', 'waitlist video', 'app teaser'."
department: engineering
triggers:
  - demo video
  - product tour video
  - record the app
  - waitlist video
  - app teaser
  - screenshot to video
---

# Demo-Video Pipeline — screenshots → motion-interpolated tour

Turn any reachable web page into a smooth scrolling product-demo video (for example, a 14s 1080p30 clip from 20 stills of a waitlist page).

## Why not just record?

**agent-browser `record` is NOT viable for tours** (verified failure mode): it attaches to a fresh page context, captures only ~2s regardless of script length, and every `open` navigation kills the prior segment. Screenshot sequences are deterministic, retryable, and each frame is individually verifiable.

## Pipeline (3 stages)

### 1 — Capture stills at scroll steps (agent-browser, ONE batch per page)

~8 frames/page, 350–400px scroll steps, 600ms settle between. State does NOT persist across agent-browser invocations — everything for one page in ONE `batch`:

```bash
mkdir -p /tmp/demo-frames/dash
agent-browser close --all; sleep 2
agent-browser batch "set viewport 1920 1080" \
  "open http://localhost:3000/path/to/page" "wait 3500" \
  "screenshot /tmp/demo-frames/dash/f-01.png" \
  "scroll down 350" "wait 600" "screenshot /tmp/demo-frames/dash/f-02.png" \
  "scroll down 350" "wait 600" "screenshot /tmp/demo-frames/dash/f-03.png" \
  # ... repeat to f-08
```

Repeat per page/scene into separate dirs (`dash/`, `office/`, …). Frame files MUST be sequentially numbered `f-%02d.png` per dir.

### 2 — Per-page clips with motion-compensated interpolation

`minterpolate` synthesizes in-between frames so discrete scroll positions read as continuous smooth scrolling:

```bash
cd /tmp/demo-frames
for p in dash office journal; do
  ffmpeg -y -framerate 1.0 -i $p/f-%02d.png \
    -vf "minterpolate=fps=30:mi_mode=mci:mc_mode=aobmc:vsbmc=1,scale=1920:1080" \
    -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p clip-$p.mp4
done
```

- `-framerate 1.0` = 1s per still → stately pace. 1.6 = snappier teaser.
- **minterpolate TRIMS the tail** — clips come out shorter than frames×rate. Always `ffprobe` actual durations before any downstream timing math.

### 3 — Assemble

```bash
printf "file 'clip-dash.mp4'\nfile 'clip-office.mp4'\nfile 'clip-journal.mp4'\n" > list.txt
ffmpeg -y -f concat -safe 0 -i list.txt -c copy out/demo-v1.mp4
```

Hard cuts between scenes are normal product-demo grammar — ship them. (`xfade` crossfades are possible but filter_complex strings get mangled through shell wrappers/rtk hooks and offsets must be computed from PROBED durations — only attempt when cuts genuinely won't do.)

Final polish if a single source needs speed/pad: `-vf "setpts=PTS/1.4,scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0x04060b" -movflags +faststart`.

## Wiring into a page

```html
<video id="demoVideo" src="assets/demo-v1.mp4" preload="metadata" playsinline loop muted
       aria-label="Product demo"></video>
```

`muted` is mandatory for autoplay policies; `preload="metadata"` keeps the page light; pair with a poster/play-button overlay.

## Gotchas (all hit live)

1. **Never use agent-browser `record` for multi-page tours** (see top) — and even single-page captures only ~2s.
2. **zsh does not word-split unquoted vars** — `for seg in "a b c"; do set -- $seg` leaves `$2` EMPTY in zsh → filenames collapse and overwrite. Write explicit commands or use zsh arrays.
3. **Serial browser discipline**: `close --all` + `sleep 2` between page batches; never parallel agent-browser on one session.
4. **Probe before math**: every ffmpeg timing decision (offsets, total duration) uses `ffprobe -show_entries format=duration` on the real files, never arithmetic from inputs.
5. **Verify the output**: `ffprobe` duration + open the mp4 — a "saved" file can be 2 seconds of nothing.
6. Animated pages: longer `wait` between scroll and screenshot so scroll-triggered animations settle (1200ms+ for GSAP reveal sections).
7. Regenerating after a UI change = rerun stage 1 only; stages 2–3 are mechanical. Keep the capture script in the repo for refresh runs.

## When NOT to use

Talking-head/cursor-interaction demos (needs real recording or Higgsfield/hyperframes), or when an actual video asset pipeline (Higgsfield `generate_video`) is available and the motion needs to be more than scrolling.
