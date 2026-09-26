# Captioning a finished video — HyperFrames + Whisper + chroma-key workflow

Full implementation guide for the `ad-caption-video` skill. Covers the `build_groups.py` script, `index.html` composition skeleton, GSAP timing constants, ffmpeg chroma-key composite command, and all known pitfalls.

**Prerequisite: trim before captioning.** If the source video has any beats with VO followed by silent visual dead space, trim those beats *before* running this pipeline — re-encode each beat to `vo_dur + 0.5s`, re-concat, and only then transcribe. Whisper timestamps applied to a tightened master line up correctly; timestamps from a dead-space master drift when the source is later trimmed.

---

## Why not ffmpeg `subtitles=` / `drawtext`?

Homebrew's `ffmpeg` formula ships without `libass` + `libfreetype`. The filters are silently absent and `ffmpeg -vf subtitles=...` returns `No such filter`.

HyperFrames renders captions in a real browser: real web fonts, real `text-stroke`, real GSAP animations per phrase, per-emphasis styling. Production quality `drawtext` cannot match.

---

## Step 1: Initialize the project

```bash
cd path/to/<run-id>/
npx --yes hyperframes@0.6.26 init <run-id>-captions
cp final/<source-video>.mp4 <run-id>-captions/source.mp4
```

---

## Step 2: Transcribe

Whisper model selection governs alignment quality:

| Source audio | Model | Why |
|---|---|---|
| Pure speech, no music | `small.en` | Fast, accurate |
| Speech + background music (typical ad) | **`medium.en`** | `small.en` biases word boundaries against music — 100-300 ms per-word drift |
| Multilingual source | `medium` or `large-v3` | `.en` variants translate non-English audio silently |
| Full instrumentation + vocals | `large-v3` or API | Even `medium.en` may misalign |

```bash
cd <run-id>-captions
npx --yes hyperframes@0.6.26 transcribe source.mp4 --model medium.en
```

Output: `transcript.json` — flat array of `{text, start, end}` per word.

Quality check (mandatory before proceeding):

```bash
python3 -c "
import json, sys
data = json.load(open('transcript.json'))
junk = [w for w in data if any(c in w['text'] for c in ['♪', '♫', '\\ufffd'])]
print(f'{len(junk)}/{len(data)} garbage tokens ({100*len(junk)/len(data):.0f}%)')
if len(junk)/len(data) > 0.2:
    print('FAIL: >20% garbage — re-run with larger model')
    sys.exit(1)
print('PASS')
"
```

---

## Step 3: `build_groups.py` — word-level transcript → reading phrases

Commit this file as `build_groups.py` in the captioning project root:

```python
#!/usr/bin/env python3
"""transcript.json (word-level) → groups.json (reading phrases for HyperFrames)."""
import json, re, pathlib

WORDS = json.load(open("transcript.json"))
MAX_CHARS = 22     # characters per group before forcing a break
MAX_WORDS = 5      # words per group before forcing a break
MAX_GAP   = 0.55   # seconds of pause that force a new group

def is_sentence_end(t): return bool(re.search(r'[.!?](?:["\'\)\]])?$', t))
def is_clause_break(t): return bool(re.search(r'[,—:;](?:["\'\)\]])?$|\.\.\.$', t))

groups, cur, cur_chars, last_end = [], [], 0, 0.0
for w in WORDS:
    text = w["text"]
    if not text.strip():
        continue
    gap = w["start"] - last_end if cur else 0
    candidate = cur_chars + (1 if cur else 0) + len(text)
    if cur and (
        (candidate > MAX_CHARS and len(cur) >= 2)
        or len(cur) >= MAX_WORDS
        or gap >= MAX_GAP
    ):
        groups.append(cur)
        cur, cur_chars = [], 0
    cur.append(w)
    cur_chars += len(text) + (1 if cur_chars else 0)
    last_end = w["end"]
    if is_sentence_end(text) or (is_clause_break(text) and len(cur) >= 2):
        groups.append(cur)
        cur, cur_chars = [], 0
if cur:
    groups.append(cur)

out = []
for g in groups:
    text = re.sub(r"\s+([,.;:!?])", r"\1", " ".join(w["text"] for w in g).strip())
    out.append({
        "text":     text,
        "start":    round(g[0]["start"], 2),
        "end":      round(g[-1]["end"], 2),
        "emphasis": "normal",
    })

pathlib.Path("groups.json").write_text(json.dumps(out, indent=2))
print(f"{len(out)} groups → groups.json")
```

Run:

```bash
python3 build_groups.py
```

Then hand-tag emphasis in `groups.json` for key phrases:

| Class | Style | Use for |
|---|---|---|
| `normal` | White, 54px | Default narration |
| `comedic` | Warm yellow, 60px, snappy ease | Punchlines, comedic beats |
| `brand` | Brand purple/pink, 56px | Brand name first mentions |
| `product` | Hot pink/magenta, 62px, largest | Pricing, quantities, key claims |
| `helen` (or character name) | Italic, warm amber, 50px | Dialogue spoken by characters (vs. narrator) |

---

## Step 4: `index.html` — composition skeleton

**Critical: do NOT put `<video>` or `<audio>` elements with `class="clip"` in the composition.** HyperFrames wraps those elements in a managed timing wrapper that reserves an ~80 px layout block at the bottom of the stage, producing a hard black bar in the render. Use chroma-key composite-in-post instead.

Drop this skeleton into the captioning project root as `index.html`. Substitute `__GROUPS_JSON_INLINE__` with the contents of `groups.json` in a build step before running — the skeleton reads `window.__GROUPS__` **synchronously**, so inline the JSON rather than `fetch()`-ing it at runtime (a runtime fetch would leave groups undefined when the timeline builds; only use fetch if you also wrap the timeline setup in an `async` init). Set `data-duration` to the actual source video duration.

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=720, height=1280" />
    <!-- NOTE: add integrity="sha384-..." crossorigin="anonymous" to this tag in production
         to guard against CDN compromise (Subresource Integrity). Generate the hash with:
         curl -s https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js | openssl dgst -sha384 -binary | base64 -->
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.14.2/dist/gsap.min.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@700;800;900&display=swap" rel="stylesheet">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body {
        margin: 0; width: 720px; height: 1280px; overflow: hidden;
        /* Chroma-key magenta — keyed out by ffmpeg post-render. */
        background: #ff00ff;
        font-family: "Outfit", system-ui, sans-serif;
      }
      #stage { position: relative; width: 720px; height: 1280px; }
      #captions { position: absolute; inset: 0; z-index: 10; pointer-events: none; }
      .caption-group {
        position: absolute; left: 50%; transform: translateX(-50%);
        max-width: 660px; width: max-content; text-align: center;
        opacity: 0; visibility: hidden; will-change: transform, opacity;
      }
      .caption-group .line {
        display: inline-block; font-family: "Outfit", sans-serif;
        font-weight: 900; font-size: 54px; line-height: 1.1;
        color: #fff; text-transform: uppercase;
        -webkit-text-stroke: 6px #0e0a06; paint-order: stroke fill;
        text-shadow: 0 5px 14px rgba(0,0,0,.7), 0 2px 4px rgba(0,0,0,.9);
        white-space: pre-wrap;
      }
      .caption-group.emp-comedic .line { font-size: 60px; color: #ffe6a8; }
      .caption-group.emp-brand   .line { font-size: 56px; color: #f7d9ff; -webkit-text-stroke: 6px #3d1648; }
      .caption-group.emp-product .line { font-size: 62px; color: #ffd9f6; -webkit-text-stroke: 6px #3d1648; }
      .caption-group.emp-helen   .line { font-style: italic; font-size: 50px; color: #ffd6a8; -webkit-text-stroke: 5px #2a1808; }
    </style>
  </head>
  <body>
    <div id="stage"
         data-composition-id="main"
         data-start="0"
         data-duration="73.36"
         data-width="720"
         data-height="1280">
      <div id="captions"></div>
    </div>

    <script>
      /* GROUPS data — inline the contents of groups.json here. */
      window.__GROUPS__ = __GROUPS_JSON_INLINE__;
    </script>

    <script>
      window.__timelines = window.__timelines || {};

      /* Y_DEFAULT: caption vertical position in px from top.
         940 ≈ 73% from top (lower third for 9:16 / 1280px height).
         Adjust per project — lift during CTA windows to clear burned-in overlays. */
      const Y_DEFAULT = 940;
      const layer = document.getElementById("captions");

      window.__GROUPS__.forEach((g, gi) => {
        const wrap = document.createElement("div");
        wrap.className = "caption-group emp-" + (g.emphasis || "normal");
        wrap.id = "cg-" + gi;
        wrap.style.top = Y_DEFAULT + "px";
        const line = document.createElement("span");
        line.className = "line";
        line.textContent = g.text;
        wrap.appendChild(line);
        layer.appendChild(wrap);
      });

      const tl = gsap.timeline({ paused: true });

      /* SNAPPY SYNC: caption appears AT the whisper-reported start time (g.start).
         No lead-in offset — the 60 ms in-animation IS the only anticipation.
         Adding a lead-in causes perceptible early-fire drift. */
      window.__GROUPS__.forEach((g, gi) => {
        const el = document.getElementById("cg-" + gi);
        const inDur  = 0.06;   // 60 ms — snappy but not jarring
        const outDur = 0.08;   // 80 ms out
        const prevEnd  = gi > 0 ? window.__GROUPS__[gi - 1].end : 0;
        const inStart  = Math.max(prevEnd + 0.003, g.start);
        const outStart = Math.max(inStart + inDur + 0.02, g.end - outDur - 0.005);
        const ease = (g.emphasis === "comedic" || g.emphasis === "product" || g.emphasis === "brand")
          ? "back.out(1.3)"
          : "power2.out";

        tl.set(el, { visibility: "visible" }, inStart);
        tl.fromTo(el,
          { opacity: 0, scale: 0.97, y: 4 },
          { opacity: 1, scale: 1,    y: 0, duration: inDur, ease },
          inStart
        );
        tl.to(el,
          { opacity: 0, scale: 0.96, y: -6, duration: outDur, ease: "power2.in" },
          outStart
        );
        tl.set(el, { opacity: 0, visibility: "hidden" }, g.end);
      });

      tl.seek(0);
      window.__timelines["main"] = tl;
    </script>
  </body>
</html>
```

Get the source video duration for `data-duration`:

```bash
ffprobe -v error -show_entries format=duration -of csv=p=0 source.mp4
```

---

## Step 5: Render + chroma-key composite

```bash
npm run check
# Expect: 0 errors, 0 warnings. (The 1 contrast warning against magenta is fine — disappears after chroma-key.)

npm run render
# Outputs: renders/<project>_<timestamp>.mp4
# This is fast (~15s, ~2 MB) because it's flat magenta background + caption text only.
```

Composite captions onto the source video:

```bash
ffmpeg -y \
  -i ../final/<source-video>.mp4 \
  -i renders/<latest-render>.mp4 \
  -filter_complex "[1:v]chromakey=0xff00ff:0.10:0.05[caps];[0:v][caps]overlay=0:0[vout]" \
  -map "[vout]" -map "0:a" \
  -c:v libx264 -preset medium -crf 18 -c:a copy -pix_fmt yuv420p \
  ../final/<source-video>-with-captions.mp4
```

Parameters:
- `chromakey=0xff00ff:0.10:0.05` — similarity `0.10` (how close to magenta to remove), blend `0.05` (edge softness). Tuned: removes magenta without eating into the white text stroke. Adjust similarity up (e.g. `0.15`) only if magenta fringing remains; do not exceed `0.20` or text edges will thin.
- `-c:a copy` — carries the source audio untouched; narration, BGM, and ducking mix are preserved.

---

## Adjusting caption position

`Y_DEFAULT = 940` places captions in the lower third (9:16, 1280px height). Adjust for other resolutions:

| Canvas height | Suggested Y_DEFAULT |
|---|---|
| 1280 (9:16 at 720px wide) | 940 |
| 1920 (9:16 at 1080px wide) | 1410 |
| 1080 (1:1 at 1080px) | 790 |
| 720 (16:9 at 1280px wide) | 530 |

To lift captions during a CTA window (to clear a burned-in overlay):

```javascript
// In the forEach loop, before tl.set(...):
const Y = (g.start >= CTA_START_SEC && g.end <= CTA_END_SEC) ? Y_LIFTED : Y_DEFAULT;
wrap.style.top = Y + "px";
```

---

## Pitfall reference

| Symptom | Cause | Fix |
|---|---|---|
| ~80 px black bar at bottom | `<audio>`/`<video>` with `class="clip"` in composition | Remove those elements entirely |
| Captions drift 100-300 ms per word | `small.en` on music-heavy audio | Re-transcribe with `medium.en` |
| Captions fire 50-150 ms early | `inStart` has a lead-in offset | Use `g.start` directly; no lead-in |
| Captions feel laggy | In-animation > 140 ms with `back.out` | Drop to 60 ms `power2.out`; reserve `back.out(1.3)` for emphasis only |
| `ffmpeg subtitles` fails | Homebrew ffmpeg lacks libass | Use HyperFrames chroma-key pipeline |
| Pixel positions off by 1-2 px | Source resolution doesn't match `data-width`/`data-height` | Verify with `ffprobe -select_streams v:0 -show_entries stream=width,height` |
| Captions overlap burned-in CTA | Caption Y collides with overlay | Lift captions during that time range |

---

## When not to use this skill

- Source already has burned-in subtitles — don't double-caption.
- No speech/VO track (music-only video) — Whisper will return garbage.
- Per-word kinetic captions wanted — adapt step 3 to emit per-word groups; everything else stays the same.
- Captions need to drive video timing (caption-reactive transitions) — use an integrated HyperFrames composition instead of the chroma-key post approach.
