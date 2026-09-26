---
name: media-generation
description: "Generate images and videos using Gemini API — Nano Banana Pro for 4K images, Veo 3.1 for 8s video clips with audio"
triggers:
  - image
  - banner
  - thumbnail
  - video-gen
  - generate-media
---

# Media Generation Skill

Generate professional images and videos using the Gemini API. Covers prompt engineering, API integration, brand consistency, and output management for Nano Banana Pro (images) and Veo 3.1 (video).

## When to Invoke

- Creating banners, thumbnails, or social media images
- Generating short video clips for content
- Producing brand-consistent visual assets
- Creating promotional materials
- Generating visual content from text descriptions

---

## Image Generation — Nano Banana Pro

### Overview

Nano Banana Pro (Gemini 3 Pro Image) generates 4K images with:
- Accurate text rendering
- Photo-realistic and stylized outputs
- Consistent brand application
- Multiple aspect ratios

### API Call

```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "Generate an image: [YOUR PROMPT HERE]"
      }]
    }],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"]
    }
  }'
```

### Prompt Engineering for Images

#### Structure

```
[Subject] + [Style] + [Details] + [Composition] + [Technical]
```

#### Examples

| Use Case | Prompt Pattern |
|----------|---------------|
| **Banner** | "Professional banner for [topic], [brand colors], modern minimalist style, 16:9 aspect ratio, clean typography" |
| **Thumbnail** | "YouTube thumbnail showing [subject], bold text '[TITLE]', high contrast, vibrant colors, 1280x720" |
| **Social Card** | "Instagram post graphic for [topic], square format, [brand colors], modern flat design" |
| **Product Shot** | "Product photo of [item] on [background], studio lighting, professional photography style" |
| **Abstract Art** | "Abstract geometric pattern using [colors], suitable for background, high resolution" |

#### Aspect Ratios

| Use Case | Ratio | Pixels |
|----------|-------|--------|
| YouTube Thumbnail | 16:9 | 1280x720 |
| Instagram Post | 1:1 | 1080x1080 |
| Instagram Story | 9:16 | 1080x1920 |
| Twitter Header | 3:1 | 1500x500 |
| Discord Banner | 16:9 | 960x540 |
| LinkedIn Cover | 4:1 | 1584x396 |

#### Negative Prompts

When you want to exclude elements:
```
"..., avoid text overlays, no watermarks, no borders"
```

---

## Video Generation — Veo 3.1

### Overview

Veo 3.1 generates 8-second video clips with:
- 720p, 1080p, or 4K resolution
- Native audio generation
- Camera movement control
- Style transfer support

### API Call

```bash
curl -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/veo-3.1:generateContent" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: ${GEMINI_API_KEY}" \
  -d '{
    "contents": [{
      "parts": [{
        "text": "[SCENE DESCRIPTION]"
      }]
    }],
    "generationConfig": {
      "videoDuration": "8s",
      "resolution": "1080p"
    }
  }'
```

Note: Exact API format may change. Check current Gemini API docs before making calls.

### Prompt Engineering for Video

#### Structure

```
[Scene] + [Action] + [Camera Movement] + [Style] + [Audio Direction]
```

#### Camera Movements

| Movement | Description | Use For |
|----------|-------------|---------|
| Static | No movement | Product showcase |
| Pan left/right | Horizontal sweep | Revealing scenes |
| Tilt up/down | Vertical sweep | Architecture, tall subjects |
| Dolly in/out | Move toward/away | Dramatic emphasis |
| Zoom in/out | Lens zoom | Drawing attention |
| Tracking | Follow subject | Action sequences |
| Orbit | Circle around subject | 360-degree showcase |

#### Examples

```
"Slow dolly forward through a modern office space with natural lighting,
soft ambient music, warm color palette, 1080p"

"Product showcase: sleek smartphone rotating on a white pedestal,
studio lighting with soft shadows, orbit camera, 4K"
```

---

## Output Management

### Staging Directory

```
docs/generated-media/staging/YYYY-MM-DD-[slug].png
docs/generated-media/staging/YYYY-MM-DD-[slug].mp4
docs/generated-media/approved/    (moved after user approval)
```

### Metadata File

For each generated asset, create a companion `.json`:

```json
{
  "filename": "2026-02-11-discord-banner.png",
  "type": "image",
  "model": "nano-banana-pro",
  "prompt": "The exact prompt used for generation",
  "created": "2026-02-11T10:30:00Z",
  "status": "staging",
  "dimensions": "1920x1080",
  "purpose": "Discord server banner"
}
```

---

## Brand Consistency

When brand guidelines exist in the project:

1. **Read brand docs**: Check for `DESIGN-SYSTEM.md`, `BRAND-GUIDELINES.md`, or design tokens
2. **Extract brand elements**: Primary colors (hex), fonts, logo usage rules, imagery style
3. **Include in prompts**: Reference brand colors by hex, specify approved styles
4. **Verify output**: Compare generated assets against brand guidelines before approval

## API Key Setup

1. Go to https://aistudio.google.com/apikey
2. Click "Create API Key"
3. Select or create a Google Cloud project
4. Enable billing (required for Nano Banana Pro + Veo 3.1)
5. Store as `GEMINI_API_KEY` environment variable

## Pricing (Approximate)

| Model | Cost | Notes |
|-------|------|-------|
| Nano Banana Pro | ~$0.04/image | Varies by resolution |
| Veo 3.1 | ~$0.25/video | 8-second clip |

Always inform the user about costs before generating.
