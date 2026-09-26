---
name: ad-caption-video
description: >-
  Burned-in caption pipeline for paid-social video ads — HyperFrames + Whisper
  transcription + ffmpeg chroma-key compositing. Use when the user has a
  finished MP4 with a voiceover and wants timed, styled captions added for
  silent-autoplay feed performance. Trigger phrases: "add captions to this
  video", "burn in captions", "caption this ad", "silent autoplay captions",
  "caption the claymation / Pixar / UGC video".
---

This skill adds burned-in, reading-phrase-grouped captions to a finished video ad. It does not produce video; it operates on the MP4 output of `ad-creative-generation`, `arcads-api`, or any other source.

## When to use this skill

Trigger on:

- "add captions to this video" / "burn in subtitles"
- "caption this ad" / "make it readable with sound off"
- "silent autoplay captions" / "caption the claymation / Pixar / UGC ad"
- Any finished MP4 with a voiceover that needs to run on silent autoplay (Instagram Feed, Facebook Feed, TikTok, Reels)

**When NOT to use:**
- Source video has burned-in subtitles already — do not double-caption.
- Source has no audio track (purely visual with music only, no speech/VO).
- Caller wants per-word kinetic captions (adapt step 3 to emit per-word groups — everything else stays the same).

## Why HyperFrames + chroma-key, not ffmpeg `subtitles=` / `drawtext`

Homebrew's `ffmpeg` formula ships without `libass` + `libfreetype` — the filters are silently absent and `ffmpeg -vf subtitles=...` returns `No such filter`. The HyperFrames chroma-key approach sidesteps this entirely.

Additionally, HyperFrames renders captions in a real browser: real web fonts, real `text-stroke`, real GSAP animations per phrase, per-emphasis styling. `drawtext` cannot match this for production quality.

## Trim before captioning — mandatory rule

**If the source video has any beats with VO followed by dead visual space, trim those beats BEFORE captioning.**

Re-encode each beat to `vo_dur + 0.5s`, re-concat, then transcribe. Whisper timestamps applied to the tightened master line up correctly; timestamps from a dead-space master drift when the source is later trimmed. This is the single most common cause of caption drift complaints.

## The pipeline (5 steps)

### Step 1: Initialize the captioning project

```bash
cd path/to/<run-id>/                        # folder that holds the final .mp4
npx --yes hyperframes@0.6.73 init <run-id>-captions
cp final/<source-video>.mp4 <run-id>-captions/source.mp4
```

### Step 2: Transcribe with Whisper at the right model size

Wrong model selection is the primary cause of drifty captions.

| Source audio | Use | Why |
|---|---|---|
| Pure speech, no music | `small.en` | Fast, accurate |
| Speech mixed with background music (typical ad) | **`medium.en`** | `small.en` biases word boundaries when music interferes — 100-300 ms per-word drift |
| Multilingual | `medium` or `large-v3` (no `.en`) | `.en` models translate non-English audio silently |
| Produced track with full instrumentation + vocals | `large-v3` or API | Even `medium.en` may misalign |

```bash
npx --yes hyperframes@0.6.73 transcribe source.mp4 --model medium.en
```

Output: `transcript.json` — flat array of `{text, start, end}` per word.

**Quality check (mandatory):** grep for `♪` and `�` tokens. If >20% of entries are music notes or obvious nonsense words, re-run with a larger model.

### Step 3: Group words into reading phrases

Word-by-word captions are exhausting to read. Group into 3-5 word phrases that break on punctuation. See `prompting/guide.md` for the full `build_groups.py` script to commit into the project.

Emphasis classes for hand-tagging groups:
- `normal` — default white text
- `comedic` — slightly larger, warm color, snappier ease
- `brand` — alternate color, for brand name mentions
- `product` — largest, for pricing/quantity callouts

### Step 4: Write the composition

**Critical: do NOT put `<video>` or `<audio>` elements in the composition.** HyperFrames wraps any `class="clip"` element in a managed timing wrapper that injects its own positioning/sizing styles — the wrapper for `<audio>` reserves an ~80 px layout block at the bottom of the stage, producing a hard black bar in the render.

Instead: render captions over a **chroma-key magenta** (`#ff00ff`) background, composite the source video underneath in ffmpeg post. See `prompting/guide.md` for the full `index.html` skeleton with GSAP timing, caption positioning, and emphasis CSS.

Caption timing rule: the GSAP `inStart` formula uses `g.start` directly — no lead-in offset. A 60 ms in-animation is the only anticipation needed. Lead-in offsets cause perceptible drift.

### Step 5: Render + chroma-key composite

```bash
cd <run-id>-captions
npm run check       # 0 errors expected (the 1 contrast warning against magenta is fine)
npm run render      # outputs renders/<project>_<timestamp>.mp4

# Composite:
ffmpeg -y \
  -i ../final/<source-video>.mp4 \
  -i renders/<latest-render>.mp4 \
  -filter_complex "[1:v]chromakey=0xff00ff:0.10:0.05[caps];[0:v][caps]overlay=0:0[vout]" \
  -map "[vout]" -map "0:a" \
  -c:v libx264 -preset medium -crf 18 -c:a copy -pix_fmt yuv420p \
  ../final/<source-video>-with-captions.mp4
```

`chromakey=0xff00ff:0.10:0.05` — similarity 0.10 (how close to magenta to key out), blend 0.05 (edge softness). These values are tuned: they cleanly remove magenta without eating into the white text stroke.

`-c:a copy` carries the source audio through untouched — narration, BGM, and ducking mix from the source video are preserved.

## Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| ~80 px black bar at bottom of render | `<audio>` or `<video>` with `class="clip"` in the composition — HyperFrames reserves layout space | Remove those elements; use the chroma-key composite-in-post pattern |
| Captions drift 100-300 ms per word | Used `small.en` on audio with background music | Re-transcribe with `medium.en` |
| Captions fire ~50-150 ms early | GSAP `inStart` formula has a lead-in like `g.start - 0.05` | Use `g.start` directly; the 60 ms animation duration is the only anticipation needed |
| Captions feel laggy on the eye | In-animation duration too long (140+ ms with `back.out`) | Drop to 60 ms with `power2.out`; use `back.out(1.3)` only for emphasis classes |
| `ffmpeg -vf subtitles=...` fails with "No such filter" | Homebrew ffmpeg lacks libass | Use the HyperFrames chroma-key pipeline instead |
| Pixel positions off by 1-2 px after chroma-key | Source video resolution does not match composition `data-width`/`data-height` | Verify with `ffprobe -select_streams v:0 -show_entries stream=width,height` |
| Captions visible during a burned-in CTA overlay window | Caption Y position collides with overlay | Lift captions during that time range: `wrap.style.top = (g.start >= CTA_START ? Y_LIFTED : Y_DEFAULT) + "px"` |

## File layout convention

```
<run-id>/
├── final/
│   ├── <source-video>.mp4                     ← input
│   └── <source-video>-with-captions.mp4       ← output of step 5
└── <run-id>-captions/                         ← the hyperframes project
    ├── index.html
    ├── source.mp4
    ├── transcript.json                        ← whisper output
    ├── groups.json                            ← reading phrases
    ├── build_groups.py
    └── renders/                               ← timestamped intermediate mp4s
```

## File locations

| File | Purpose |
|---|---|
| `src/skills/ad-caption-video/SKILL.md` | This file |
| `src/skills/ad-caption-video/prompting/guide.md` | Full pipeline guide — `build_groups.py`, `index.html` skeleton, GSAP timing, ffmpeg commands |

## Quality gates

- [ ] Source video trimmed to remove dead space BEFORE transcribing.
- [ ] Whisper model selected based on audio type (speech-only vs. music-mixed vs. multilingual).
- [ ] Quality check passed: `transcript.json` contains <20% music-note or nonsense tokens.
- [ ] No `<video>` or `<audio>` elements in the HyperFrames composition.
- [ ] Composition `data-width`/`data-height` matches source video resolution exactly.
- [ ] `npm run check` exits with 0 errors (1 magenta contrast warning is expected and harmless).
- [ ] `chromakey=0xff00ff:0.10:0.05` values preserved unless explicitly tested with different values.
- [ ] Final output reviewed: captions sync to audio, no magenta fringing, no black bar, no drift.
