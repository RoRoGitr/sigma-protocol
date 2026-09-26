---
name: arcads-api
description: >-
  Concrete backend adapter for the Arcads external API — generate AI video and
  image ad creatives via Seedance 2.0, Sora 2, Veo 3.1, Kling, Grok Video,
  Nano Banana, and gpt-image-2. Handles HTTP Basic auth, the poll-until-ready
  pattern, credit estimation, and session folder management. Use when the user
  mentions Arcads, external-api.arcads.ai, Seedance, Veo, Kling, Nano Banana,
  Sora, or needs to generate marketing creative through the Arcads platform.
  Symmetric with higgsfield-generate — both are interchangeable video backends.
---

This skill is the Arcads API backend adapter. It wraps the `https://external-api.arcads.ai` endpoints behind a consistent interface so the `ad-creative-generation` umbrella skill can call it interchangeably with `higgsfield-generate` or `media-generation`.

## When to use this skill

Trigger on phrases like:

- "generate via Arcads" / "use Arcads for this"
- "Seedance video" / "Veo ad" / "Kling clip" / "Nano Banana image"
- "gpt-image-2 ad" / "ChatGPT Image ad creative"
- "UGC selfie-style with Seedance" / "premium product reveal"

Do not use this skill to deploy the finished creative to Meta — that is `meta-ad-builder`. Do not use it to add captions — that is `ad-caption-video`.

## Configuration

- **Base URL:** `https://external-api.arcads.ai` (or override with `ARCADS_BASE_URL`).
- **Auth:** HTTP Basic. Two options:
  - **Option A (preferred):** Set `ARCADS_BASIC_AUTH` to the pre-encoded header value from the Arcads dashboard (e.g. `Basic <YOUR_BASE64_CREDENTIALS>`). This avoids encoding edge cases.
  - **Option B:** Set `ARCADS_API_KEY` as the HTTP Basic username with an empty password. Most HTTP clients turn that into the same `Authorization: Basic` header as Option A once base64-encoded — prefer Option A to avoid encoding edge cases.
- **Never** print API keys, commit `.env`, or paste keys into chat or tracked context files.

### If credentials are missing or the API returns 401/403

1. Confirm `.env` exists (copy from your repo's `.env.example`).
2. Ask the user to paste `ARCADS_BASIC_AUTH` or `ARCADS_API_KEY` **only inside `.env`** — not in chat.
3. Confirm `.gitignore` excludes `.env` before proceeding.

## Model stack (dated 2026-06)

> **Note:** verify current model availability against the Arcads dashboard or docs — the model lineup changes between releases. The names below reflect the 2026-06 API surface; newer models may have different enum values.

See `references/model-stack.md` for the full table with endpoint, payload fields, and duration rules. Summary:

| Model | Type | Primary use |
|---|---|---|
| `seedance-2.0` | Video | UGC selfie-style, product hero, studio lookbook, feature walkthrough, premium reveal |
| `sora2` | Video | Cinematic narrative, text-driven story arcs |
| `veo31` | Video | High-fidelity photoreal video; auto-determines length |
| `kling-3.0` | Video | B-roll clips (5s or 10s) |
| `grok-video` | Video | Alternative cinematic backend |
| `nano-banana-2` | Image | Default photoreal still (up to 14 refs) |
| `nano-banana` | Image | Nano Banana Pro — higher fidelity, photorealism, slower |
| `gpt-image-2` | Image | Typography-heavy, UI-mimicry, dense text (max 5 refs on Arcads) |

### Endpoint mapping

All video models use `POST /v2/videos/generate` with the `model` field set to the enum above. Still images use `POST /v2/images/generate`.

**Primary video endpoint:** `POST /v2/videos/generate` with body `CreateVideoDto`:
- `model` (required): one of the video model enums above
- `prompt` (required): the visual + dialogue description
- `duration` (model-dependent): Seedance 2.0 accepts 4–15s integers; Sora 2 accepts `[4, 8, 12, 16, 20]`; Veo 3.1 auto-determines
- `resolution`: `"720p"` (default) or `"480p"`
- `aspectRatio`: `"9:16"` (vertical, default for social) or `"16:9"`
- `referenceImages`: array of `filePath` strings (presigned upload — see below)
- `audioEnabled` (Seedance 2.0 only): boolean
- `projectId`: the session project ID for dashboard organization

**Image endpoint:** `POST /v2/images/generate`:
- `model`: `"nano-banana-2"`, `"nano-banana"`, or `"gpt-image-2"`
- `prompt`: image description
- `aspectRatio`: `"1:1"`, `"16:9"`, `"9:16"` (Arcads-supported ratios; `gpt-image-2` max 5 refs)
- `referenceImages`: array of presigned `filePath` strings

## Poll-until-ready pattern

All generation calls are async. After a successful `POST`, poll until the asset is ready:

- **Video:** `GET /v1/videos/{videoId}` until `status: "generated"` or `status: "failed"`
- **Image / asset:** `GET /v1/assets/{id}` until `status: "generated"` or `status: "failed"`

Poll both concurrently when multiple assets are in flight. On `"failed"`, read the error and determine whether to retry with a revised prompt or surface to the user.

## Reference image upload (presigned URL flow)

Arcads uses a two-step upload for reference images:

1. `POST /v1/file-upload/get-presigned-url` → returns `{presignedUrl, filePath}`
2. `PUT` the raw file bytes to `presignedUrl`
3. Pass the `filePath` string in the `referenceImages` array of the generation request

**Each `filePath` is single-use.** Re-using a `filePath` across multiple generation calls returns `HTTP 500 UNKNOWN_ERROR`. Upload fresh references for each generation call.

**Pre-process reference images before upload:**
- If the longest side is below 1024 px, upscale to 1080 px longest side with Lanczos resampling (preserve aspect ratio).
- Convert to RGB JPEG (quality 90–95) to strip alpha channels and keep payload size manageable.
- Arcads rejects images below minimum resolution with `422 — The provided image is too small`.

## Session folder (dashboard organization)

At the start of each generation session, create a dated folder so all generated assets are findable in the Arcads dashboard:

1. `GET /v1/products` — resolve the target product ID.
2. `GET /v1/products/{productId}/folders` — check if `"API - {YYYY-MM-DD}"` already exists; reuse it if so.
3. Otherwise: `POST /v1/folders` then `POST /v1/projects` to create the folder and project.
4. Store the `projectId` for the session and pass it in every generation call that accepts it. For asset types that don't accept `projectId` directly, call `POST /v1/assets/add-to-project` after generation.

## Credit estimation (mandatory before generating)

Before any generation call, calculate and present the estimated credit cost. Do not generate until the user confirms.

**Cost data sources (priority order):**
1. `logs/arcads-api.jsonl` — historical actual `creditsCharged` values for previous calls with matching config. Grep for entries with the same `model`, `duration`, `resolution`, `referenceImagesCount`. (The `logs/` directory is gitignored — it holds your usage history; never commit it.)
2. Project `MASTER_CONTEXT.md` → "Credit costs" section if present.
3. Ask the user and record the answer in `MASTER_CONTEXT.md`.

Never invent numbers. Always cite the source ("from logs entry YYYY-MM-DD" or "from MASTER_CONTEXT.md rate table").

Present as:
```
Estimated credit cost:
  Seedance 2.0 (15s i2v) × 2 variants = ~1.8 credits   (from logs 2026-06-01)
  ─────────────────────────
  Estimated total: ~1.8 credits
⚠ Estimate only — confirm in the Arcads platform if precision matters.
Proceed? (yes/no)
```

## Dialogue confirmation gate (mandatory for video with speech)

Before generating any video where the AI character speaks:

1. Extract all dialogue lines from the prompt and present them as a numbered list separate from the visual description.
2. Count spoken words and verify they fit the target duration at ~2.5 words/second.
3. Ask for explicit dialogue approval before proceeding to credit confirmation and generation.

Format:
```
Dialogue (please confirm before generating)
  1. [HOOK]    "Opening line here."
  2. [DEMO]    (silent beat — no dialogue)
  3. [VERDICT] "Closing line here."

Total spoken words: ~18  |  Target: 10s  |  Fits: yes
Approve this dialogue? (yes / edit / rewrite)
```

This gate is separate from the credit confirmation — both must be satisfied before firing.

## Script-length → duration selection

Use spoken word count to pick the correct `duration` value. Average pace: ~2.5 words/second.

| Model | Duration options | Word limit |
|---|---|---|
| Seedance 2.0 | 4–15s (continuous integer) | 36 words max before offering to split |
| Sora 2 | 4, 8, 12, 16, 20 s | 48 words max |
| Veo 3.1 | Auto-determined | ~20 words before truncation risk |
| Kling / B-roll | 5 or 10 s | Silent — no speech in b-roll |

For scripts that exceed the model's maximum: offer to split at natural sentence boundaries and generate each segment separately, then stitch with ffmpeg.

## Veo 3.1: `startFrame` vs `referenceImages`

These two fields are mutually exclusive — never use both in the same call.

- **`startFrame`** (presigned `filePath`): Use when the user provides an image of a person or scene they want the video to start from. The video animates from this exact frame.
- **`referenceImages`** (array of `filePath`): Use for style, mood, or tone references — not as the literal first frame.

Default rule: a single reference photo of a person → use `startFrame`. Explicit style board → use `referenceImages`.

## Generated image QA (mandatory for still images)

After each still image reaches `status: generated`, inspect the output for:

- Extra or missing hands/fingers
- Distorted, duplicated, or merged facial features
- Garbled or unreadable text (when text was requested)
- Impossible anatomy or stray limbs

If defects are found, regenerate with a revised prompt that explicitly corrects the issue. Do not resend the identical payload expecting a different result.

Retry cap: 2 additional attempts (3 total). After the cap, surface the best attempt to the user.

## Errors

| Code | Cause / fix |
|---|---|
| 401/403 | Invalid credentials — fix `ARCADS_BASIC_AUTH` or `ARCADS_API_KEY` in `.env` |
| 404 | Wrong UUID — re-fetch the resource list |
| 422 | Validation or moderation — tighten prompt; check required enum values for `aspectRatio` and `duration` |
| 500 UNKNOWN_ERROR | Often a stale presigned `filePath` being reused — upload fresh references per generation |

## File locations

| File | Purpose |
|---|---|
| `src/skills/arcads-api/SKILL.md` | This file |
| `src/skills/arcads-api/references/model-stack.md` | Full model table with endpoints, payload fields, duration rules (dated 2026-06) |

## Related skills

- `ad-creative-generation` — umbrella orchestrator that calls this skill
- `higgsfield-generate` — symmetric video backend (global skill)
- `meta-ad-builder` — deploy finished creatives as Meta ads
- `ad-image-prompting` — static ad image prompt library
- `ad-caption-video` — burn captions onto finished video

## Quality gates

- [ ] `.env` verified with `ARCADS_BASIC_AUTH` or `ARCADS_API_KEY` before any call.
- [ ] Session folder created (dated project in Arcads dashboard).
- [ ] Prompt shown to user and approved before generating.
- [ ] Credit estimate presented and confirmed before firing.
- [ ] Dialogue gate passed for any video with speech.
- [ ] `startFrame` vs `referenceImages` decision made correctly for Veo 3.1.
- [ ] Reference images pre-processed (1080px longest side, RGB JPEG).
- [ ] Fresh presigned upload per generation call — never reuse `filePath`.
- [ ] Generated images inspected via QA loop (cap 2 fix rounds).
- [ ] All assets assigned to session project via `add-to-project`.
