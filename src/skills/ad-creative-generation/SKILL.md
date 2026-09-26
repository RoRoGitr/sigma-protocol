---
name: ad-creative-generation
description: >-
  Orchestrate the full ad creative production pipeline — from brief to
  platform-ready asset — using interchangeable generation backends. Use when
  the user asks to make an ad, generate ad creative, produce a video ad,
  build a static image ad, create UGC content, or deploy a finished creative
  to Meta. Routes to the right backend (Arcads API, Higgsfield, or generic
  media-generation), applies the generate → score → fix loop, and hands off
  to meta-ad-builder for deployment.
---

This skill is the orchestration entry point for ad creative production. It does not call any generation API directly — instead it coordinates three interchangeable backends behind one interface, applies a scoring loop, and routes finished assets to the deploy and captioning layers.

## When to use this skill

Trigger on phrases like:

- "make me an ad" / "generate ad creative" / "build a video ad"
- "create a UGC clip" / "product showcase video" / "brand hero loop"
- "static image ad" / "run a Meta ad with this creative"
- "cinematic ad" / "lifestyle ad" / "thumbnail for this ad"

Do not use this skill to write ad copy in isolation — that is handled by `meta-ad-builder`. Do not use it to add captions after the fact — that is `ad-caption-video`. This skill is the creative production layer.

## Backend decision tree

Choose the generation backend based on the output type and available tooling. Backends are interchangeable — the same brief can be routed to whichever is configured.

| Goal | Primary backend | Fallback |
|---|---|---|
| Typography-heavy static image (iOS mock-up, comparison table, chat thread, fake search, Apple Notes) | Arcads API → `gpt-image-2` via `arcads-api` skill | Generic image gen via `media-generation` skill |
| Photoreal / lifestyle static image (handheld sign, product flatlay, whiteboard testimonial) | Arcads API → Nano Banana via `arcads-api` skill | Generic image gen via `media-generation` skill |
| Cinematic video ad (product reveal, brand manifesto, narrative arc) | Arcads API → Seedance 2.0 / Veo 3.1 / Kling via `arcads-api` skill | Higgsfield → Seedance/Kling via `higgsfield-generate` skill |
| Brand hero loop (15–30s product showcase for dark landing pages) | Higgsfield via `higgsfield-generate` skill | Arcads API video models |
| UGC selfie-style (authentic phone-camera testimonial feel) | Arcads API → Seedance 2.0 UGC formula via `arcads-api` skill | Higgsfield |
| Multi-image reference blending (character + product + scene) | Arcads API → Nano Banana 2 (default; up to 14 refs) via `arcads-api` skill | Higgsfield multi-ref; if neither is configured, flag to the user — no equivalent local backend |

**Backend selection rule:** if the user has Arcads API credentials configured, default to `arcads-api` for all generation. If they have only Higgsfield credentials, route video to `higgsfield-generate` and static images to `media-generation`. Never hard-require a single provider — the goal is an output, not a specific vendor.

## Generate → score → fix loop

Apply this loop to every generation run before handing off to deploy or captions.

### Round 1: Generate candidates

1. Identify the creative goal (static image / video / thumbnail).
2. Read the relevant prompting guide (`ad-image-prompting` for static; the backend skill for video).
3. Compose the prompt following the template library or a fresh structure.
4. Request the user's confirmation on the prompt before generating (show the filled prompt, get approval).
5. Fire N variants (default 2–3; ask if unspecified).

### Round 2: Score against the creative rubric

For each candidate:

| Criterion | Pass condition |
|---|---|
| **Brand fidelity** | Product / wordmark / color matches the reference image |
| **Text legibility** | All copy reads cleanly at thumbnail size; no garbled glyphs |
| **Anatomy** | Correct limb count; no fused or duplicate features |
| **Composition** | Primary subject and headline fit within the central 84% of canvas |
| **Creative impact** | Stops the scroll; differentiated from generic AI output |

Mark each criterion PASS / FAIL. If any criterion FAILs, continue to Round 3.

### Round 3: Fix and regenerate

For each failed criterion, revise the prompt to explicitly address the defect. Examples:

- Garbled text → add explicit text-fidelity guard: `"render body-text as plain words only — no emoji or unicode inside text blocks"`
- Wrong hand anatomy → add: `"anatomically correct hands — exactly two hands, five fingers each"`
- Subject clipped → add: `"all focal subjects and text must fit within the central 84% of the canvas (8% padding on each side)"`

Cap at 2 fix rounds per variant. If defects persist after the cap, surface the best attempt to the user with a clear note and ask how to proceed.

## Transparent-video trick (brand hero loops on dark pages)

When producing video for a landing page with a dark background and the source video has an opaque background, apply this composite technique to make the video read as transparent:

1. **Generate the video** on a dark solid background (deep black or very dark navy — avoid pure `#000000` which can confuse luma detection).
2. **Composite on a dark canvas:** place the video over the target dark background color in your compositor.
3. **Apply screen blend mode** to the video layer. Screen blend mode mathematically eliminates the dark background while preserving the lit subject — dark pixels become transparent, light pixels are preserved.
4. **Boost contrast** on the video layer (contrast +20–30%) to sharpen the subject edge against the background.
5. **Feather a luma mask** around the subject boundary (soft edge, 3–8px blur) to eliminate any halo artifacts from the screen blend.
6. **Export as WebM with alpha** if the final format supports it; otherwise export the composited MP4 over the page background.

This technique avoids the need for a true green-screen key and works reliably when the video background is substantially darker than the subject. The darker the backing, the cleaner the composite — a dark navy backing produces better results than mid-grey.

## File locations

| Skill | Purpose | Path |
|---|---|---|
| `arcads-api` | Arcads API backend adapter (Seedance, Veo, Kling, Nano Banana, gpt-image-2) | `src/skills/arcads-api/SKILL.md` |
| `higgsfield-generate` | Higgsfield video/image generation backend | Global skills: `higgsfield-generate` |
| `media-generation` | Generic image/video generation (fallback) | Global skills: `media-generation` |
| `meta-ad-builder` | Deploy finished creatives as Meta ads | `src/skills/meta-ad-builder/SKILL.md` |
| `ad-image-prompting` | Static ad image prompt library and templates | `src/skills/ad-image-prompting/SKILL.md` |
| `ad-caption-video` | Burn captions onto finished ad video | `src/skills/ad-caption-video/SKILL.md` |

## Workflow summary

```
Brief → backend selection → prompt from ad-image-prompting template (or fresh) →
generate N candidates → score → fix defects (cap 2 rounds) →
user approves → hand off:
  ├─ static image → meta-ad-builder (upload + copy + deploy PAUSED)
  └─ video → [ad-caption-video if voiceover] → meta-ad-builder (deploy PAUSED)
```

## Quality gates

- [ ] Backend selected and credentials verified before generating.
- [ ] Prompt shown to user and approved before API call.
- [ ] Credit / generation cost estimate confirmed before firing.
- [ ] All candidates scored against the 5-criterion rubric.
- [ ] Fix rounds applied for any FAIL criteria (max 2 per variant).
- [ ] Transparent-video composite applied if deploying to a dark landing page.
- [ ] Finished assets handed to `meta-ad-builder` — never launch spending ads from this skill.
