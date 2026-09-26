---
name: ad-image-prompting
description: >-
  Ad-specific static image and thumbnail prompting — 37 validated prompt
  templates (T1–T39), three always-on safety suffixes, backend selection rules,
  and style recipes for chatgpt-image-ad, nano-banana, claymation, Pixar-style,
  and YouTube thumbnail CTR formulas. Use when the user asks to make a static
  image ad, generate a thumbnail, pick an image ad template, prompt an AI image
  model for advertising creative, or add to the template library. Complements
  (does not replace) the global marketing:ai-image-prompt and
  marketing:15-thumbnail-prompts skills — this skill is the ad-specific
  prompting layer with brand-fidelity and Meta-placement constraints.
---

This skill is the prompting intelligence layer for static ad image and thumbnail generation. It owns the validated template library, backend selection rules, always-on safety suffixes, and style-specific prompting recipes. It does not call any API directly — it produces the prompt and hands off to the correct backend skill (`arcads-api` or `media-generation`).

## When to use this skill

Trigger on phrases like:

- "which template fits my ad idea?" / "pick a template for this brief"
- "make a static image ad" / "generate a [format] ad image"
- "Apple Notes ad" / "comparison table ad" / "editorial article ad"
- "claymation style ad" / "Pixar 3D animated ad" / "lifestyle product ad"
- "YouTube thumbnail" / "thumbnail variations" / "CTR thumbnail formula"
- "add a new template to the library" / "clone this ad into a template"

Do **not** use this skill to generate the image — that is `arcads-api` or `media-generation`. Do **not** use it to deploy the image as a Meta ad — that is `meta-ad-builder`.

**Relationship to the marketing plugin** (these resolve via the `marketing:` plugin command namespace, not the flat skills pool):
- `marketing:ai-image-prompt` — general AI image generation guidance. This skill is the *ad-specific* superset with 37 rendering-tested templates, Meta placement constraints, brand-fidelity anchoring, and the three safety suffixes.
- `marketing:15-thumbnail-prompts` — general thumbnail prompting. This skill extends that with the 5 CTR-formula framework and the character-likeness alignment rules for person-centric thumbnails.

## Backend selection

Before generating, select the model based on the creative goal.

| The brief calls for... | Use |
|---|---|
| iOS mock-ups, Apple Notes lists, comparison tables, fake search results, Slack snapshots, chat threads, ChatGPT conversations, dense text / UI-mimicry | `gpt-image-2` |
| Handheld whiteboard signs, napkin testimonials, sticky-note + product flatlays, lifestyle scenes, OOH photography, photoreal product composites, multi-reference blending | `nano-banana` (Nano Banana 2 default; Nano Banana Pro for highest fidelity) |
| Ambiguous? | Look up the template in `prompting/prompt-library.md` and read its `Model notes:` block — every entry recommends one or the other. |

For video-to-static pipelines (Pixar-style, claymation): use `gpt-image-2` for the storyboard stills (strong text and UI fidelity), then animate via `arcads-api` Seedance 2.0.

## Always-on safety suffixes

Append these three guards to every prompt **before sending it to the backend** (`arcads-api` / `media-generation`). This is a prompting skill — it does not generate, so nothing auto-applies them; you append them. See `prompting/safety-suffixes.md` for the full text.

1. **`NO_CHROME_SUFFIX`** — strips iOS device chrome, platform brand-rows, post body/caption text, link-card footers, engagement rows, action buttons, Story chrome, platform tab bars. Forces the output to be the **standalone ad creative** (the static image an advertiser uploads), not a screenshot of how it displays in-feed. Override with `--allow-chrome` only when the ad's concept explicitly requires simulated platform chrome.

2. **`SAFE_ZONE_SUFFIX`** — forces all text, headlines, CTAs, table headers, sign/board content, product wordmarks, and key focal subjects into the central 84% of the canvas (~8% padding on every edge). Backgrounds and divider lines may bleed; text and focal elements must not touch or extend off any edge. Eliminates the "clipped headline" failure mode.

3. **`GLYPH_SAFETY_SUFFIX`** — forbids emoji and unicode glyphs inside body-text blocks (chat bubbles, comment threads, ChatGPT responses, dense paragraphs). Enforces the exact count of conversation elements the prompt specifies. Emoji are allowed in headlines and short large-text positions where the prompt explicitly calls for them.

Do not remove these suffixes silently. If a model follows them so literally the layout becomes stiff, use `--no-safe-zone` or `--allow-chrome` per run and document why.

## The template library

`prompting/prompt-library.md` ships with **37 rendering-tested full prompts** (tags T1 through T39, with intentional gaps at T16 and T22). *Rendering-tested* means each prompt was checked for clean output on gpt-image-2 and/or nano-banana — it is not a paid-media performance claim. Every entry has:

- **When to use** — positioning fit and audience match
- **Aspect ratio** — recommended canvas
- **Reference image** — what to pass as the brand-fidelity anchor
- **Variables** — the placeholder schema
- **Template prompt** — the full validated prompt in a fenced code block
- **Model notes** — known strengths and limits for each backend on this template

**The template library is the first place to look.** Match the user's brief to a template, fill the `{placeholder}` variables, and generate. Writing a prompt from scratch is the fallback when nothing in the library matches.

For backend support on specific aspect ratios, see the compatibility table in `prompting/prompt-library.md` → "Aspect-ratio compatibility" section.

## Standard workflow

1. **Match to a library template.** Read `prompting/prompt-library.md`. If the brief maps onto an existing template, use it.
2. **Select the backend.** Read the template's `Model notes:`. Default: `gpt-image-2` for typography-heavy, `nano-banana` for photoreal.
3. **Fill placeholders.** Swap `{brand.name}`, `{brand.color_primary}`, `{ad.headline}`, etc. with the user's brand. Show the rewritten prompt and ask for approval.
4. **Show the generation cost estimate** (read from credit logs or `MASTER_CONTEXT.md` rate table). Wait for confirmation.
5. **Generate** via the appropriate backend skill (`arcads-api` or `media-generation`).
6. **Visual QA.** Read each output image. Check for: garbled small text (most common `gpt-image-2` failure), extra fingers / wrong limb count (`nano-banana` failure), wordmark drift, wrong text count, UI proportion drift. Regenerate with a revised prompt if defective (cap 2 retries).
7. **Hand off** the image paths to `meta-ad-builder` for upload and ad creation, or deliver to the user.

## Style recipe summaries

These are prompt-writing recipes for common ad visual styles. Full guides live in the templates.

### Claymation / Aardman-style

Multi-step: (1) write a cast sheet (protagonist + supporting character + narrator voice); (2) generate ChatGPT Image 2 storyboard stills (max 5 reference images) — fall back to Nano Banana Pro for close-ups if clay texture flattens; (3) animate stills via Seedance 2.0 image-to-video; (4) stitch clips with ffmpeg (optional `fps=12` for stop-motion judder); (5) add captions via `ad-caption-video`.

Key prompt elements: `"claymation aesthetic"`, `"Aardman-style stop-motion"`, `"hand-sculpted plasticine"`, `"textured clay surface"`, `"vibrant saturated colors"`, `"rounded forms"`, `"stop-motion feel"`.

### Pixar-style 3D animated

Multi-step: (1) lock cast sheet; (2) ChatGPT Image 2 storyboard stills per beat (max 5 refs); (3) Seedance 2.0 image-to-video per beat with `startFrame`; (4) ffmpeg stitch + captions.

Key prompt elements: `"Pixar 3D animation aesthetic"`, `"subsurface scattering on skin"`, `"cinematic lighting with soft shadows"`, `"anthropomorphized character"`, `"vibrant but harmonious palette"`.

### YouTube thumbnail (CTR formulas)

Five proven high-CTR formulas:

1. **Branding / peace-sign** — subject with brand assets, clean background, title text across the top in massive bold letters.
2. **Real vs AI comparison** — split panel: left = "real" reference, right = AI-generated equivalent.
3. **Terminal flow** — subject alongside a visible terminal / code editor screen showing the process.
4. **Reaction shock** — subject with an exaggerated surprised or shocked expression, pointing to the reveal.
5. **Before/after split** — vertical split panel showing two states of the same subject or product.

**Critical for person-centric thumbnails:** include a character likeness block in the prompt:
```
[Subject description: build, hair, distinguishing features], exact likeness anchored
by [N] reference images from multiple angles. No generic face substitution.
```

Pass 5+ reference photos of the subject from different angles. With fewer than 5 references, the model generalizes to a generic approximation of the person.

**Title text convention:** `"Across the top in massive bold [color] block letters with thick [color] outline reads: [TITLE TEXT]"`. Keep title text under 6 words for readability at thumbnail size.

**Always include:**
- `"YouTube thumbnail, 16:9 landscape"`
- `"Avoid: distorted face, extra fingers, hands visible, blurry logos, generic face"`

## Template library entry format

When adding a new template to `prompting/prompt-library.md`, use the skeleton in `prompting/template-format.md`. Key rules:

- Tag format: `T<n> — <short noun phrase describing the format, not the content>`
- New templates start at T40 (next available after the seeded T1–T39)
- Every entry must include `Model notes:` for each backend it was validated against
- The template prompt must specify the aspect ratio at the top and describe the output as a standalone creative (not a platform screenshot)

## File locations

| File | Purpose |
|---|---|
| `src/skills/ad-image-prompting/SKILL.md` | This file |
| `src/skills/ad-image-prompting/prompting/prompt-library.md` | 37 validated ad image templates (T1–T39) |
| `src/skills/ad-image-prompting/prompting/safety-suffixes.md` | Three always-on prompt guards |
| `src/skills/ad-image-prompting/prompting/template-format.md` | Skeleton for new library entries |

## Quality gates

- [ ] Template library consulted before writing a fresh prompt.
- [ ] Backend selected based on the template's `Model notes:` block.
- [ ] Prompt shown to user and approved before generating.
- [ ] Credit cost estimate confirmed before firing.
- [ ] Three safety suffixes active (NO_CHROME, SAFE_ZONE, GLYPH_SAFETY).
- [ ] Visual QA run on each output — defects corrected with revised prompt (max 2 retries).
- [ ] Finished image paths handed to `meta-ad-builder` — not uploaded directly from this skill.
