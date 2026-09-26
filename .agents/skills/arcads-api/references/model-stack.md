# Arcads model stack reference (dated 2026-06)

> This file reflects the Arcads external API model lineup as of 2026-06.
> Model availability and enum values change between Arcads releases.
> **Verify current availability against the Arcads dashboard or docs before relying on a specific model.**

## Video models (`POST /v2/videos/generate`)

All video models share the same primary endpoint. Set the `model` field to the enum value below.

| Model | `model` enum | Duration options | Aspect ratios | Primary use |
|---|---|---|---|---|
| Seedance 2.0 | `"seedance-2.0"` | 4–15 s (continuous integer) | `"9:16"`, `"16:9"` | UGC selfie-style, product hero, studio lookbook, feature walkthrough, premium product reveal |
| Sora 2 | `"sora2"` | `[4, 8, 12, 16, 20]` s | `"9:16"`, `"16:9"` | Cinematic narrative, text-driven story arcs |
| Veo 3.1 | `"veo31"` | Auto-determined (~8s typical) | `"9:16"`, `"16:9"` | High-fidelity photoreal video; animated lifestyle scenes |
| Kling 3.0 | `"kling-3.0"` | `[5, 10]` s | `"9:16"`, `"16:9"` | B-roll clips, ambient product footage (no speech) |
| Grok Video | `"grok-video"` | Varies — see Arcads docs | `"9:16"`, `"16:9"` | Alternative cinematic backend |

### Seedance 2.0 — additional fields

Seedance 2.0 accepts extra input modes:

- `referenceImages` (array of presigned `filePath` strings, max 3): image-to-video — provide visual references. **Mutually exclusive with `referenceVideos`.**
- `referenceVideos` (array of presigned `filePath` strings): video-to-video style transfer. **Mutually exclusive with `referenceImages`.**
- `referenceAudios` (array of presigned `filePath` strings): background music or voice reference. Can be combined with either image or video refs.
- `audioEnabled` (boolean): whether to generate audio in the output.

**Confirmed as of 2026-04:** combining `referenceImages` + `referenceVideos` in the same request returns `HTTP 500 UNKNOWN_ERROR`. Pick one.

Default settings: `resolution: "720p"`, `aspectRatio: "9:16"`. Use `"480p"` only for cheap test generations.

### Veo 3.1 — `startFrame` vs `referenceImages`

Mutually exclusive. See `SKILL.md` for the decision rule.

## Image models (`POST /v2/images/generate`)

| Model | `model` enum | Reference image limit | Primary use |
|---|---|---|---|
| Nano Banana 2 | `"nano-banana-2"` | Up to 14 refs | Default photoreal still; multi-ref character/product composites |
| Nano Banana Pro | `"nano-banana"` | Up to 14 refs | Higher fidelity photorealism — slower and higher cost |
| gpt-image-2 | `"gpt-image-2"` | Max 5 refs (Arcads hard cap) | Typography-heavy, dense text, UI-mimicry (iOS dialogs, chat threads, comparison tables) |

Supported `aspectRatio` for all image models on Arcads: `"1:1"`, `"16:9"`, `"9:16"`. Ratios like `"2:3"`, `"4:5"` are not supported at this endpoint.

## Other endpoints

| Flow | Endpoint |
|---|---|
| B-roll clip | `POST /v1/b-roll` (Kling- or Nano-Banana-powered — see Arcads docs for routing) |
| Scene generation | `POST /v1/scene` |
| Talking avatar / script | `POST /v1/scripts` then `POST /v1/scripts/{id}/generate` |
| Sora 2 remix of existing asset | `POST /v1/sora2/remix/video` |

## Polling endpoints

| Asset type | Poll endpoint | Terminal statuses |
|---|---|---|
| Video | `GET /v1/videos/{videoId}` | `"generated"`, `"failed"` |
| Image / asset | `GET /v1/assets/{id}` | `"generated"`, `"failed"` |

## Asset project assignment

After generation, verify each asset is in the session project:

```
POST /v1/assets/add-to-project
Body: { "assetId": "...", "projectId": "..." }
```

This applies to every generated asset — including failed QA attempts and intermediate stills used as starting frames for video.
