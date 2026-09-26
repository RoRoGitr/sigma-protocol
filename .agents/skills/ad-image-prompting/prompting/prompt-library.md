# Image-ad prompt library

Validated, parameterizable prompt templates for generating standalone Meta ad creatives. Pair each with a brand product reference image via `--image-ref` for brand fidelity.

**Hard rule:** every prompt in this library produces a *standalone* image upload — no iOS chrome, no platform UI, no brand-row, no link card, no engagement counts. Those are added by Meta when displaying the ad.

**The script auto-appends three always-on safety suffixes** to every prompt. See [safety-suffixes.md](safety-suffixes.md):
1. **`NO_CHROME_SUFFIX`** — strips iOS chrome, platform brand-rows, post text, link-card footers, engagement rows, action buttons, comment input, tab bars, Story chrome.
2. **`SAFE_ZONE_SUFFIX`** — forces all text/headlines/CTAs/focal subjects to fit within the central 84% of the canvas (8% padding from every edge). Backgrounds may bleed; text and focal elements may not.
3. **`GLYPH_SAFETY_SUFFIX`** — forbids emoji and unicode glyphs inside body-text blocks; enforces the exact count of conversation elements the prompt specifies.

**Reference image:** unless noted otherwise, pass a clean product hero shot (white-background product photo of the brand's packaging). The reference is the brand-fidelity anchor; the prompt is the format.

**Model portability:** every entry includes a `Model notes` block:
- **`gpt-image-2`** — strong text fidelity, dense small-text rendering, faithful UI mimicry (iOS, Slack, Google search, comparison tables). Best for typography-heavy templates.
- **`nano-banana`** (Nano Banana 2 / Nano Banana Pro) — strong photorealism, multi-image reference blending, character continuity. Weaker on dense small text.

When a template renders cleanly on both backends, the entry says `both: clean`.

---

## Aspect-ratio compatibility (read before picking a template)

Each template recommends an aspect ratio in its **Aspect ratio:** field. Not every ratio is renderable on every backend.

| Ratio | Natively supported at the Arcads image endpoint? |
|---|---|
| `1:1`, `16:9`, `9:16` | ✅ — gpt-image-2 and nano-banana both accept these |
| `2:3`, `3:2`, `4:5` (Meta feed-portrait), `5:4`, `3:4`, `4:3`, `21:9` | ❌ — generate at the nearest supported ratio and post-crop |

> **Single source of truth for Arcads ratio support: [`arcads-api/references/model-stack.md`](../../arcads-api/references/model-stack.md).** Arcads currently accepts only `1:1` / `16:9` / `9:16` at the image-generate endpoint (both models). Verify against live Arcads docs before relying on any other ratio — sending an unsupported `aspectRatio` fails the generation call.

**Decision tree when a template's recommended ratio isn't one of the three supported:**
1. Generate at the nearest supported ratio — `9:16` for tall, `1:1` for square-ish, `16:9` for wide.
2. Post-crop to the target ratio (e.g. `4:5` Meta feed-portrait, `1.91:1` link) in the `meta-ad-builder` step.

---

## How to use this file

Find the matching template below, **check the aspect-ratio table against the backend you're using**, then replace `{placeholder}` variables and invoke the appropriate backend with the filled prompt + the brand's reference image.

**Variable conventions:**
- `{brand.name}` — wordmark text on the product label
- `{brand.color_primary}` — primary brand color hex
- `{brand.product_description}` — one-line how-the-product-looks
- `{brand.competitor_category}` — what the brand is replacing/winning against
- `{brand.tagline}` — the brand's short value prop
- Template-specific variables defined per section.

---

## T1 — Apple Notes listicle aesthetic

**When to use:** emotional / sentimental product positioning, "things I love about X" voice, brands targeting older or wellness-conscious audiences. Reads like a real customer's private list.

**Aspect ratio:** `2:3` (Meta feed-portrait friendly without iOS device frame)

**Reference image:** clean product hero (helps brand-color drift in the rare emoji that gets a brand cue)

**Variables:**
- `{notes_title}` — bold black title (≤40 chars, may end with brand-relevant emoji)
- `{date_string}` — small grey timestamp under the header (e.g. "March 14, 2026 at 6:42 AM")
- `{checklist_items[]}` — 8-12 items, each conversational + 1-2 emoji decorations, optional date suffix

**Template prompt:**
```
2:3 portrait static ad creative — a clean Apple Notes app aesthetic mock-up rendered as a standalone image, edge-to-edge, on a pure white #FFFFFF background. The aesthetic mimics the look of a personal note in Apple Notes, but this is the upload-ready ad creative itself, not a phone screenshot.

Top of the image (taking ~10% height): an Apple Notes navigation header. Left: orange "< Notes" back-chevron + label in SF Pro semibold. Center: two orange icons — a forward-arrow circle (redo) and a circular refresh arrow. Right: a share-square icon and an ellipsis-in-circle icon, both grey. Hairline grey divider beneath.

Centered just below the header, in small grey SF Pro: "{date_string}"

Then bold black SF Pro title (large, ~32pt feel): "{notes_title}"

Then a vertical list of {N} unchecked checklist items. Each row: a hollow grey circle bullet on the left, then the item text in regular black SF Pro with emoji decorations interleaved. Items (verbatim):
{checklist_items_numbered}

Generous vertical spacing, items left-aligned with consistent left padding from the bullet.

Bottom of the image (~6% height): an Apple Notes toolbar with four icons evenly spaced — orange checklist/list icon (active), camera icon, "A" inside a circle (text style), and a pencil-edit-square icon.

The composition reads as a calm, honest personal note — like a real customer's private journal entry — but rendered as a standalone ad creative ready to upload. No keyboard, no selection state, no device chrome.
```

**Example fill** (supplement brand):
- `{notes_title}` = `Why I Switched My Morning Stack 🌿`
- `{date_string}` = `March 14, 2026 at 6:42 AM`
- `{checklist_items}` = 10 items: `Less time meal-prepping ⏱️🥗`, `No more 12-pill morning stack 💊→🌱`, `Travel-friendly sachets ✈️🍃`, `Easier to actually drink 💚`, `Backed by clinical research 🔬`, `Endorsed by people I trust 👥`, `One scoop, one minute ⏲️`, `Flavor I don't gag on 🫐`, `Fewer "did I take my vitamins?" thoughts 🧠`, `More energy by 10am ⚡`

**Model notes:**
- **gpt-image-2:** clean. Renders SF Pro feel + emoji in checklist items reliably. Preferred backend for this template.
- **nano-banana:** mixed. Header chrome (orange "Notes" chevron, toolbar icons) sometimes drifts; emoji rendering inside list items is less faithful. Use only if gpt-image-2 unavailable.

---

## T2 — Editorial article hero

**When to use:** credibility-led ads — "[respected publication] covers brand X." High-trust audiences, science-backed products. The publication logo functions as a third-party endorsement.

**Aspect ratio:** `1:1` (Meta feed standard)

**Reference image:** clean product hero (for the inset product shot in the photo block)

**Variables:**
- `{publication}` — publication wordmark (`FORBES`, `WIRED`, `Vogue`, `The Wall Street Journal`)
- `{headline}` — bold editorial headline, 8-15 words, declarative
- `{subcopy}` — 1-2 sentence editorial sub-copy expanding the headline
- `{photo_subject_description}` — what's shown in the bottom 55%
- `{tagline}` — short brand promise on the bottom band (≤4 words)
- `{band_color}` — brand-color hex for the bottom band

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — an editorial / publication-style ad image. Standalone, ready to upload as a Meta ad creative. White inner background.

Top-left: "{publication}" wordmark in chunky bold black serif on a small white box (the publication's logo, treated as a credibility stamp).

Headline below the logo, large bold black sans-serif tight tracking: "{headline}"

Sub-copy below the headline, regular weight black sans-serif: "{subcopy}"

Hero photograph occupies the bottom ~55% of the image: {photo_subject_description}. Premium product photography, soft natural light.

Across the very bottom of the image, an inset {band_color} band about 12% tall, containing white sans-serif headline "{tagline}" left-aligned, with a small white "Learn more >" pill on the right edge.

The composition is the standalone ad creative — editorial layout that reads as a publication-co-signed brand piece. No social platform UI of any kind.
```

**Example fill** (supplement brand):
- `{publication}` = `FORBES`
- `{headline}` = `How This Greens Powder Became the One Doctors Actually Recommend`
- `{subcopy}` = `Most multivitamins fail bioavailability tests. This brand built theirs around what your body can actually absorb.`
- `{tagline}` = `Greens, simplified.`
- `{band_color}` = `#1A4731`

**Model notes:**
- **gpt-image-2:** clean. Publication wordmark legibility is strong; subhead reads at small size.
- **nano-banana:** clean for the photograph block; weaker on subhead text legibility at 1:1 — consider scaling subhead text up or shipping at 2:3.

---

## T3 — Story tweet + UGC composite

**When to use:** authority endorsements paired with UGC-style customer footage. Story-format placements (Reels/Stories), high social-proof angle.

**Aspect ratio:** `9:16` (Stories / Reels)

**Reference image:** product hero (for the product visible in the UGC photo)

**Variables:**
- `{authority_name}` — full name of the quoted authority
- `{authority_handle}` — Twitter/X handle
- `{authority_face_description}` — 1-line face description for the small profile photo
- `{tweet_body}` — multi-line tweet text with value-prop bullets
- `{ugc_subject}` — what the UGC photo shows
- `{ugc_overlay_text}` — the black-rectangle text label across the UGC photo
- `{cursive_line}` — italic teaser line above the LEARN MORE

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge. Standalone — this image gets uploaded directly as the Story ad asset.

Background: soft cream / warm grey gradient ~#F2EEE6, full bleed.

Upper-mid composition: a screenshot-style Twitter/X post card, white rounded-corner card with thin shadow, occupying roughly 55-60% of the width on the left side, vertically positioned in the upper third:
- Top of card: small round profile photo of {authority_face_description}, "{authority_name}" in bold black + a small blue-check verified mark, "{authority_handle}" in grey beneath.
- Tweet text in black sans-serif: "{tweet_body}"

To the right of the tweet card, slightly overlapping its right edge: a vertical 9:16-cropped photo of {ugc_subject}, soft window-light morning kitchen background. Across the lower-mid of the photo, a black rounded-rectangle overlay text label: "{ugc_overlay_text}" in white sans-serif.

Below the tweet+photo composite, in the lower third of the image:
- A faint cursive italic line in black: "{cursive_line}"
- Below that, centered, in cursive blue script: "🔗 LEARN MORE"

The composition is the static Story ad creative ONLY. No iOS device chrome, no Story progress bars, no story header, no swipe-up arrows.
```

**Model notes:**
- **gpt-image-2:** clean for the tweet card text + handle. Strong here.
- **nano-banana:** mixed — the UGC photo block looks great, but tweet text legibility drops. Preferred approach: generate the UGC photo block with nano-banana separately, then composite via gpt-image-2 for final assembly.

---

## T4 — Fake Google search mosaic

**When to use:** "as the internet says..." angle. Implicit social proof from search results aesthetic + media logos. Wellness, supplement, beauty categories where consumers actively Google solutions.

**Aspect ratio:** `9:16`

**Reference image:** clean product hero with multiple SKUs visible (the 2×2 grid uses 4 product variations)

**Variables:**
- `{search_query}` — the query in the search bar
- `{grid_tile_descriptions[]}` — 4 product-photo descriptions, one per tile, sharing a soft tonal background
- `{publication_logos[]}` — 4 publication wordmarks for the bottom row
- `{accent_color_family}` — the soft tonal background for the grid (e.g. `cream-to-sage`, `pink-to-lavender`)

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge. A "fake Google search results" aesthetic rendered as a standalone upload-ready image. White inner background fading to soft {accent_color_family} at the bottom 30%.

Top of the image (~6% height): a thin top app row — a small grey hamburger-menu icon on the left; centered, the multicolor "Google" wordmark in standard Google Sans typeface; on the right, a small color microphone icon.

Below that: a rounded-pill grey search bar with a magnifier icon on the left and the text "{search_query}" in standard sans-serif.

Below the search bar: a horizontal tab row "All  Videos  Images  News  Maps  Books" with "All" underlined in faint blue, others in muted grey. Hairline divider beneath.

Main area: a 2x2 grid of square image search results with subtle rounded corners and small gaps between them. All four tiles share a soft {accent_color_family} background:
- Top-left: {grid_tile_descriptions[0]}
- Top-right: {grid_tile_descriptions[1]}
- Bottom-left: {grid_tile_descriptions[2]}
- Bottom-right: {grid_tile_descriptions[3]}

Below the grid, soft {accent_color_family} area at the bottom: in small spaced caps "AS SEEN ON" in muted grey, then a horizontal row of four publication wordmarks: {publication_logos joined with comma}.

The composition reads as a believable "Google search results page" rendered as a standalone static ad creative. No iOS device chrome.
```

**Model notes:**
- **gpt-image-2:** clean. Google wordmark colors stay faithful; publication wordmarks crisp.
- **nano-banana:** publication wordmarks drift — letters get re-spaced. Pass each publication as a `--image-ref` if pixel-perfect logo accuracy matters.

---

## T5 — Comparison table (light)

**When to use:** clinical/feature-led brand differentiation against a generic category competitor. Best for products with clear feature-superiority claims (clinical research, certifications, ingredient counts).

**Aspect ratio:** `2:3` (Meta tall feed)

**Reference image:** product hero showing the brand's primary SKU(s)

**Variables:**
- `{brand.name}` — the wordmark text in the header
- `{brand.product_image_description}` — what the brand's product looks like (1-line)
- `{competitor_category}` — what the brand is being compared against
- `{competitor_image_description}` — generic stand-in product (1-line, deliberately unbranded)
- `{brand.color_primary}` — header text color hex
- `{row_accent_color}` — soft tint for alternating rows
- `{rows[]}` — 6 rows of `{label, brand_value, competitor_value}` — values are `green ✓`, `red ✗`, or text

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620 — a clean, edge-to-edge comparison-table ad image. Standalone, ready to upload as a Meta ad creative. White background.

Header section (top ~22% of the image):
- Left side: bold {brand.color_primary} sans-serif headline in two stacked lines: "{brand.name} vs. {competitor_category}"
- Right side, on the same vertical band: two product photos in a row — {brand.product_image_description} on the left, {competitor_image_description} on the right.
- Hairline thin grey divider beneath the header.

Comparison table (bottom ~78% of the image): six rows, each spanning the full width, with alternating row backgrounds — {row_accent_color} for odd rows and white for even rows. Each row has three columns: label (left, ~50% width), {brand.name} column (~25%), and competitor column (~25%).

{rows_rendered_with_label_brand_competitor}

Typography is clean modern sans-serif throughout. Iconography is consistent — same green-circle ✓ and red-circle ✗ across all check rows.

This is the standalone ad creative — only the comparison table and product header. No surrounding social platform UI.
```

**Model notes:**
- **gpt-image-2:** clean. Strong text legibility in table rows, consistent ✓/✗ glyph rendering.
- **nano-banana:** clean structurally but small row labels can lose sharpness at 2:3. Consider shipping at 1:1 with fewer rows if using nano-banana.

---

## T6 — Comparison table (dark, hooky)

**When to use:** stop-the-scroll dark-mode creative. More provocative tone than T5 — leads with "this RUINS X" hook. Strong for SaaS/info-product/supplement brands willing to be confrontational with the category.

**Aspect ratio:** `2:3`

**Reference image:** product hero (for the right-side icon in the VS row)

**Variables:**
- `{hook_line_1}` — top line, white, large (e.g. `This RUINS`)
- `{hook_line_2}` — bottom line, white with one accent word in double-braces (e.g. `Your {{Greens}} Powder`)
- `{competitor_label}` — short caption under the left "VS" tile
- `{brand.name}` — the wordmark on the right tile
- `{brand.color_primary}` — accent color for highlights and brand-column outline
- `{table_columns}` — three column names
- `{table_rows[]}` — 5 rows of `{metric_label, competitor_value, brand_value}` — brand value in accent color

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a dark-mode comparison ad image. Standalone, upload-ready as a Meta ad creative. Near-black background ~#0A1A12 with a subtle radial deep-{brand.color_primary} glow at the center.

Top text in chunky white sans-serif (large), stacked across two lines centered horizontally: "{hook_line_1}" on line 1, "{hook_line_2}" on line 2 — the word(s) marked with double-braces in {hook_line_2} are colored bright vivid green ~#3FCB7E, the rest white.

Centered below the headline, a row of three small rounded-square icons:
- Left tile: black background with stylized competitor graphic, captioned "{competitor_label}" beneath.
- Middle: a small angled bright-green "VS" badge in a parallelogram shape.
- Right tile: {brand.color_primary} background with white "{brand.name}" wordmark stamped boldly.

Below the icons, a dark comparison table with thin light-grey grid lines:
- Header row in regular grey caps: {table_columns[0]} | {table_columns[1]} | {table_columns[2]}
- The "{brand.name}" column is outlined with a thin bright-green border framing it.
{table_rows_rendered}

Numbers in monospace feel; labels in regular sans-serif.

The composition is the standalone dark-mode ad creative ONLY — no surrounding platform UI.
```

**Model notes:**
- **gpt-image-2:** clean. Strong on dark-mode UI, accent-color word highlighting, monospace numbers.
- **nano-banana:** clean for the headline and "VS" tile row; small numbers in the table can blur. Reduce table to 4 rows for nano-banana.

---

## T7 — Handwritten whiteboard sign (handheld)

**When to use:** UGC-authenticity angle. A real-looking human holds a whiteboard or napkin with a handwritten endorsement. High-trust, pattern-interrupt in a feed full of polished creative.

**Aspect ratio:** `9:16` (Stories/Reels) or `4:5` (feed-portrait — nano-banana preferred)

**Reference image:** lifestyle portrait of the subject holding an object (for likeness anchoring); product hero as second ref

**Variables:**
- `{subject_description}` — who holds the sign (gender, approximate age, vibe — no named real people)
- `{sign_type}` — `whiteboard`, `napkin`, `sticky note`, `piece of paper`
- `{sign_lines[]}` — 3-5 lines of handwritten text (keep each under 30 chars)
- `{background_description}` — setting (kitchen counter, home office desk, gym locker room)
- `{product_description}` — the product in the subject's other hand or nearby

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge. Standalone image uploaded as the Story ad creative.

A {subject_description} stands in {background_description}, holding a {sign_type} in one hand and {product_description} in the other.

On the {sign_type} in large authentic handwritten marker text, the following lines appear exactly:
Line 1: "{sign_lines[0]}"
Line 2: "{sign_lines[1]}"
Line 3: "{sign_lines[2]}"
{sign_lines[3-4] if provided}

Handwriting is energetic but legible — the kind of writing you'd see on a real whiteboard, not calligraphy. The {sign_type} fills roughly 55% of the image width, well within the safe zone.

Soft natural window light. The subject's expression is warm and direct — looking at camera. No surrounding social platform UI.
```

**Model notes:**
- **gpt-image-2:** strong for text on the sign. Can struggle with hand anatomy — check carefully.
- **nano-banana:** excellent for the person + setting; sign text may drift or misspell. Best approach: nano-banana for the person/setting, gpt-image-2 if text legibility is the priority.

---

## T8 — Sticky note + product flatlay

**When to use:** "this is my daily stack" aesthetic. Product photography with a personal-note overlay. Great for supplement, beauty, and wellness categories that benefit from an at-home warmth feel.

**Aspect ratio:** `1:1`

**Reference image:** product hero (white background, all SKUs); second ref: the sticky-note color reference if brand-specific

**Variables:**
- `{product_items}` — list of 3-5 product items in the flatlay
- `{surface_description}` — surface and background (e.g. `warm oak wooden desk, morning window light`)
- `{sticky_note_color}` — sticky note color hex or descriptor (e.g. `soft sage green`)
- `{sticky_note_lines[]}` — 3-5 lines of casual handwritten text on the note
- `{accent_props}` — 1-3 small accent props (e.g. `small white ceramic mug, scattered green leaves, a white pen`)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a product flatlay ad image. Standalone, ready to upload as a Meta ad creative.

Background: {surface_description}. The surface fills the full canvas edge-to-edge.

Main flatlay arrangement: {product_items} arranged in a natural, slightly asymmetric lay from center-left to center-right. Accent props: {accent_props}.

Slightly above center, a {sticky_note_color} sticky note sits casually on the surface (slightly tilted). On the sticky note, in warm casual handwriting:
Line 1: "{sticky_note_lines[0]}"
Line 2: "{sticky_note_lines[1]}"
Line 3: "{sticky_note_lines[2]}"

Soft morning light from the left. Shadows are real but soft. Products are fully visible, labels readable. The composition reads as a genuine "this is what I use every day" lifestyle flatlay. No social platform UI.
```

**Model notes:**
- **gpt-image-2:** mixed for the flatlay photography itself; strong for the handwritten text on the sticky note. Use for copy-forward variants.
- **nano-banana:** excellent for the flatlay photography and product styling; sticky note text may drift. Pass the sticky note as a ref image for best results.

---

## T9 — Slack conversation mock-up

**When to use:** B2B/SaaS angle. "Our team loves this." A 2-3 message Slack thread endorsement. High credibility for productivity/software/professional categories.

**Aspect ratio:** `2:3` or `1:1`

**Reference image:** product or SaaS UI screenshot (for the screen visible in message or linked preview)

**Variables:**
- `{channel_name}` — Slack channel name (e.g. `#general`, `#team-wins`)
- `{messages[]}` — 3 messages, each with: `{name}`, `{avatar_description}`, `{time}`, `{text}`
- `{emoji_reaction_line}` — the emoji reactions on the last message (e.g. `🙌 4  ❤️ 2  ✅ 3`)

**Template prompt:**
```
2:3 portrait static ad creative — a clean Slack conversation mock-up rendered as a standalone ad image on a pure white background. Edge-to-edge. This is the upload-ready creative, not a screenshot of a phone.

Header row: Slack logo (multicolor hashtag icon + wordmark "Slack") on white. Hairline grey divider.

Channel header: bold black "{channel_name}" in medium-weight sans-serif. Small grey member count indicator.

Three Slack messages in sequence, spaced naturally:

Message 1:
- Left: small round avatar ({messages[0].avatar_description})
- "{messages[0].name}" in bold black, then "{messages[0].time}" in muted grey
- Message text: "{messages[0].text}"

Message 2:
- Left: small round avatar ({messages[1].avatar_description})
- "{messages[1].name}" in bold black, then "{messages[1].time}" in muted grey
- Message text: "{messages[1].text}"

Message 3:
- Left: small round avatar ({messages[2].avatar_description})
- "{messages[2].name}" in bold black, then "{messages[2].time}" in muted grey
- Message text: "{messages[2].text}"

Below message 3: a row of emoji reaction pills: {emoji_reaction_line}

Bottom of the image: a message-input bar with a placeholder in grey "Message {channel_name}".

The composition is the standalone ad creative — a clean Slack UI simulation. No iOS device chrome, no surrounding social platform UI.
```

**Model notes:**
- **gpt-image-2:** clean. Dense text in message bodies renders reliably. Preferred for this template. Cap each message at 25 words.
- **nano-banana:** message text loses sharpness beyond 3 lines. Use only for Slack-aesthetic backgrounds with minimal text.

---

## T10 — ChatGPT conversation (single exchange)

**When to use:** "I asked AI and here's what it said" angle. Works for any product that benefits from an implied authority endorsement via a simulated AI recommendation.

**Aspect ratio:** `2:3` or `1:1`

**Reference image:** product hero (for the product visible in the chat screenshot or referenced in response)

**Variables:**
- `{user_prompt}` — the user's question to the AI (1-2 sentences)
- `{ai_response_paragraphs[]}` — 2-3 short paragraphs of the AI response (keep each under 40 words)
- `{response_lists}` — optional: a short bulleted list in the response (3-5 items)

**Template prompt:**
```
2:3 portrait static ad creative — a clean ChatGPT conversation mock-up rendered as a standalone ad image on a white background. Edge-to-edge.

Header: standard ChatGPT interface top bar — "ChatGPT" in bold black, small "3.5" or "4" model tag. Horizontal hairline divider.

User message (right-aligned, dark grey rounded bubble):
"{user_prompt}"

AI response (left-aligned, white background, no bubble border):
[GPT icon — small teal-green circle with white "G" glyph]

{ai_response_paragraphs[0]}

{ai_response_paragraphs[1] if provided}

{response_lists formatted as plain bullet-point list with "• " prefix, no emoji in the list itself}

The text is clean black sans-serif, legible at ad size. No trailing text after the response (no "Regenerate response" button, no message input). The composition is the standalone ad creative ONLY. No iOS device chrome.
```

**Model notes:**
- **gpt-image-2:** clean for the chat UI chrome and text legibility. Apply GLYPH_SAFETY_SUFFIX carefully — suppress emoji inside the AI response text. Preferred backend.
- **nano-banana:** UI chrome drifts (GPT icon shape, top bar layout). Use only if gpt-image-2 unavailable; reduce response to 1 short paragraph.

---

## T11 — OOH / billboard photography

**When to use:** scale/reach signaling. "Look, we're everywhere" angle. Works well as social proof in competitive categories and for brands actively running out-of-home campaigns or wanting that impression.

**Aspect ratio:** `1:1` or `9:16`

**Reference image:** brand logo/wordmark reference + product hero

**Variables:**
- `{billboard_headline}` — the headline on the billboard (≤8 words)
- `{billboard_tagline}` — secondary line (optional, ≤6 words)
- `{billboard_color}` — dominant billboard background color hex
- `{location_description}` — the OOH setting (e.g. `New York Times Square, evening, rain-wet streets, yellow cabs`, `Los Angeles freeway overpass, golden hour`)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a photorealistic out-of-home advertisement photography scene. Standalone upload-ready Meta ad creative.

Scene: {location_description}. Photographic quality — this looks like a real press shot taken from the street or a news photo.

Centered in the scene: a large billboard or wall mural showing a {billboard_color} background with the brand creative:
- Big bold white headline: "{billboard_headline}"
- Below: smaller white tagline: "{billboard_tagline}" (if provided)
- Brand product visible on the billboard (the product from the reference image)

The surrounding environment is vivid and real — real street life, real light. The billboard is the natural focal point but fits into the scene.

The composition is the standalone ad creative — a photorealistic OOH scene. No social platform UI.
```

**Model notes:**
- **gpt-image-2:** strong for the billboard text legibility, weaker for photorealistic street backgrounds. Best when the billboard is the primary element.
- **nano-banana:** excellent for photorealistic street scenes and golden-hour/night-time environments. Billboard text may drift — keep headline under 6 words. Preferred backend for immersive scene quality.

---

## T12 — YouTube thumbnail (branding formula)

**When to use:** YouTube thumbnails, high-CTR formula 1 (brand/peace-sign). Subject with brand assets, clean background, massive title text.

**Aspect ratio:** `16:9` (YouTube thumbnail standard)

**Reference image:** 5+ reference photos of the subject from multiple angles (critical for likeness accuracy)

**Variables:**
- `{subject_description}` — physical description of the subject (build, hair, distinguishing features)
- `{brand_asset_description}` — what brand-related items the subject holds or wears
- `{background_description}` — clean or gradient background
- `{title_text}` — ≤6 words in massive bold letters across the top
- `{title_color}` — title text color (e.g. `white`, `yellow`)
- `{outline_color}` — thick text outline color (e.g. `black`, `dark blue`)

**Template prompt:**
```
YouTube thumbnail, 16:9 landscape, 1280x720, edge-to-edge — a high-CTR YouTube thumbnail. Standalone image ready to upload as the video thumbnail.

Background: {background_description} — clean and uncluttered.

Centered or slightly right-of-center: {subject_description}, exact likeness anchored by the reference images from multiple angles. No generic face substitution. The subject wears or holds {brand_asset_description}. Expression: confident, direct, slight smile.

Across the top of the thumbnail in massive bold {title_color} block letters with thick {outline_color} outline: "{title_text}"

The text is large enough to read as a mobile thumbnail (~75% of screen height or more). Font weight: 900 or ultra-bold.

Avoid: distorted face, extra fingers, hands visible, blurry logos, generic face substitution.

This is the standalone thumbnail creative. No social platform UI.
```

**Model notes:**
- **gpt-image-2:** strong for the title text legibility and outline. Mixed for face likeness if under 3 reference images. Preferred backend for text-forward thumbnails.
- **nano-banana:** excellent for face likeness with 5+ reference images. Title text may drift — keep to ≤5 words. Preferred backend for likeness-first thumbnails.

---

## T13 — "Before / after" split panel

**When to use:** transformation-led products. Clear visual contrast between two states — before and after using the product. Supplement, skincare, fitness, education categories.

**Aspect ratio:** `1:1` or `4:5` (nano-banana preferred for 4:5)

**Reference image:** product hero; optionally a "before" lifestyle photo

**Variables:**
- `{before_description}` — what the left panel shows (the "before" state)
- `{after_description}` — what the right panel shows (the "after" state)
- `{before_label}` — text label on the left panel (e.g. `Before`)
- `{after_label}` — text label on the right panel (e.g. `After`, or `30 Days Later`)
- `{divider_style}` — how panels split (e.g. `clean vertical white line`, `diagonal slash`, `arrows pointing right`)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a before/after split-panel ad image. Standalone, ready to upload as a Meta ad creative.

The canvas is split vertically into two equal panels with {divider_style} as the divider.

Left panel — "{before_label}":
{before_description}. Slightly desaturated, softer lighting.

Right panel — "{after_label}":
{after_description}. Vibrant, bright, warm lighting.

Each panel has a bold label in the {before_label} / {after_label} text positioned in the upper area of its panel — white text with dark outline, large enough to read at thumbnail size.

The overall composition is energetic, the contrast between panels is immediately obvious. The standalone ad creative only — no social platform UI.
```

**Model notes:**
- **gpt-image-2:** clean for the text labels and split panel structure. Panel content can be generic-looking for photoreal subjects.
- **nano-banana:** excellent for the photoreal "before" and "after" scenes. Text labels may need the SAFE_ZONE_SUFFIX enforced extra-firmly. Preferred for lifestyle/person-centric before/afters.

---

## T14 — Fake Slack team conversation

**When to use:** B2B / SaaS / agency products where the buyer's "moment of consideration" happens in a work context. Also works for wellness brands with a "team / colleague recommendation" angle.

**Aspect ratio:** `1:1`

**Reference image:** product hero (used for color cues in the green CTA pill)

**Variables:**
- `{channel_name}` — Slack channel (e.g. `#wellness-team`, `#growth`, `#founders`)
- `{messages[]}` — 3 messages, each `{author_name, role, time, message_text}`. Avoid emoji in message text (see known issue)
- `{cta_text}` — pill button text (e.g. `TRY {brand.name} →`)
- `{cta_color}` — brand-color hex for the CTA pill

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a fake Slack-style team conversation rendered as a standalone ad creative. EXACTLY THREE messages, no more, no fewer.

Top section (~10% height): a Slack-style window header bar — deep aubergine / dark plum background ~#3F0E40 spanning the full canvas width. Left edge: three small rounded dots (red / yellow / green window controls). To the right of the dots, a small back arrow + forward arrow + clock-history icon, then a centered rounded grey search-bar pill containing a small magnifier icon and the word "Search". Far right: a small cartoon profile avatar (~24px).

Below the header, a thin grey divider, then the main chat content area (white background ~#FFFFFF, ~90% of the canvas):

Channel header row: in bold black sans-serif (~22pt), left-aligned, with comfortable padding from the canvas left edge: "{channel_name}" with a small dropdown chevron beside it. Far right (with safe-zone padding from canvas right edge): a small "12" face-pile of three tiny avatar circles + member count.

Below the channel header, a vertical thread of EXACTLY THREE messages. Each message has the same row structure: avatar on left, message content on right. Plain text only — NO emoji, NO unicode symbols, NO special characters in the message bodies.

MESSAGE 1:
- Avatar (left, ~44px rounded square): illustrated cartoon figure of a smiling brunette woman.
- Right of avatar: bold black "{messages[0].author_name} ({messages[0].role})" + small grey "{messages[0].time}" beside it.
- Below the name row: regular black sans-serif text in a single paragraph: "{messages[0].message_text}"

MESSAGE 2:
- Avatar (left): illustrated cartoon woman with red hair.
- Right of avatar: bold black "{messages[1].author_name} ({messages[1].role})" + small grey "{messages[1].time}".
- Below: regular black sans-serif: "{messages[1].message_text}"

MESSAGE 3:
- Avatar (left): same brunette cartoon as Message 1.
- Right of avatar: bold black "{messages[2].author_name} ({messages[2].role})" + small grey "{messages[2].time}".
- Below: regular black sans-serif: "{messages[2].message_text}"

Below the third message, with comfortable vertical spacing, centered horizontally and well within the safe zone (at least 10% padding from the canvas bottom): a large pill-shaped CTA button with rounded corners, {cta_color} fill, containing bold WHITE uppercase sans-serif text "{cta_text}".

The composition reads as a believable Slack team-chat snapshot — but rendered as a standalone static ad creative. No additional UI: no Slack sidebar (no workspace switcher, no channel list, no DM list), no message-input box at the bottom of the chat, no app navigation, no iOS or desktop OS chrome.

EXACTLY three messages — do not invent a fourth. Plain text only — no emoji or special glyphs in the message bodies.
```

**Note:** the script's global `GLYPH_SAFETY_SUFFIX` strips emoji from message bodies and enforces the "exactly N messages" count — you don't need to repeat those constraints in the prompt.

**Model notes:**
- **gpt-image-2:** clean. Slack UI mimicry is strong. **Preferred backend.**
- **nano-banana:** weaker on the channel header + message body text. Use only if gpt-image-2 unavailable.

---

## T15 — Ingredient list + collage (left/right split)

**When to use:** ingredient-forward consumables — supplements, food, drinks, beauty. Visual proof that the labeled ingredients are real / present / sourced.

**Aspect ratio:** `1:1`

**Reference image:** brand product hero (the actual product image is reproduced on the right)

**Variables:**
- `{ingredients[]}` — 4-6 ingredient names, plain text, premium typography (no emoji needed)
- `{ingredient_visuals[]}` — for each ingredient, a 1-line visual description for the right-side collage tile (e.g. `extreme close-up of vibrant green spirulina powder texture`)
- `{brand.product_description}` — how the product looks (pulled from the reference image)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a clean ingredient-breakdown ad layout. Standalone, ready to upload as a Meta ad creative. Soft cream / warm off-white background ~#F5F1EA.

LEFT HALF (~55% width): a vertical list of five ingredient names, generously spaced, each on its own line, with a thin hairline grey horizontal divider beneath each. Typography: clean black sans-serif (Inter / Söhne feel), regular weight, ~28-32pt size, left-aligned. The list reads top-to-bottom:

{ingredients[0]}
———————————
{ingredients[1]}
———————————
{ingredients[2]}
———————————
{ingredients[3]}
———————————
{ingredients[4]}

(After each ingredient name, the thin grey hairline runs to the right edge of the left half.)

RIGHT HALF (~45% width): a vertical photo collage that visually represents each ingredient, rendered as a tall stack of small rectangular product photographs flowing into the brand product itself. Stack reads top to bottom:
- Top tile: {ingredient_visuals[0]}
- Tile 2: {ingredient_visuals[1]}
- Tile 3: {ingredient_visuals[2]}
- Tile 4: {ingredient_visuals[3]}

These four small ingredient tiles are stacked vertically inside a tall vertical "window" cut-out shape on the right.

Just to the right of (or overlapping the bottom of) the collage stack: the actual brand product — {brand.product_description}, standing upright, occupying the bottom-right portion of the frame. The product slightly overlaps the ingredient-stack column, creating depth. Soft natural daylight, premium product photography aesthetic.

The composition reads as: list of what's inside on the left, visual proof of those ingredients flowing into the product on the right.

No additional text, no logos beyond the brand wordmark on the product.
```

**Model notes:**
- **nano-banana:** strong on the photo-collage half (ingredient texture rendering). **Preferred backend.**
- **gpt-image-2:** clean for the typography list; photo-collage tiles can feel slightly composited.

---

## T17 — Stacked-bar with vs without comparison

**When to use:** data-viz framing of the brand's value prop. Reads as objective even though it's editorial. Strong for productivity, wellness, finance, time-saving brands where the "without" side has many discrete failure modes.

**Aspect ratio:** `2:3`

**Reference image:** product hero (informs brand color for the winning bar)

**Variables:**
- `{header_label}` — top label both columns share (e.g. `Time spent`, `Money spent`, `Brain space`)
- `{winning_bar_color}` — soft tone for the brand's solid bar (e.g. mint-sage `#D4E8D4`)
- `{winning_bar_text}` — short phrase centered in the brand bar (e.g. `feeling great`, `actually working`)
- `{losing_segments[]}` — EXACTLY 5 short pain-point labels (top to bottom), each on a different soft pastel. Be explicit: "five segments only, no more."
- `{brand.name}` and `{competitor_label}` — column footers

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a clean data-visualization-style "with brand vs without brand" stacked-bar comparison. Standalone ad creative, ready to upload. Pure white background.

The image is split into TWO equal-width columns side by side, with a thin grey hairline vertical divider between them.

EACH column has the EXACT same outer structure: header label "{header_label}" at top, single tall vertical bar in the middle, footer label at bottom. Bars in both columns are EXACTLY the same total height.

LEFT COLUMN — winning side:
- Top label: "{header_label}" in regular black sans-serif (~22pt)
- Single tall rectangular bar (filling ~75% of column height), filled SOLID with one soft {winning_bar_color} color. NO segments, NO divisions inside this bar — it is one solid rectangle. Centered vertically inside the bar, in dark sans-serif: "{winning_bar_text}"
- Bottom label: "with {brand.name}" in regular black sans-serif

RIGHT COLUMN — losing side:
- Top label: "{header_label}" in regular black sans-serif (same size)
- Single tall rectangular bar (same height/width as left), divided into EXACTLY FIVE horizontal segments stacked top-to-bottom. The bar must contain FIVE segments, no more, no fewer — do not add a sixth segment.
- The five segments are equal height, each labeled with a short pain-point text centered inside, in dark text. From TOP to BOTTOM:
  1. {losing_segments[0].color} — "{losing_segments[0].label}"
  2. {losing_segments[1].color} — "{losing_segments[1].label}"
  3. {losing_segments[2].color} — "{losing_segments[2].label}"
  4. {losing_segments[3].color} — "{losing_segments[3].label}"
  5. {losing_segments[4].color} — "{losing_segments[4].label}"
- Bottom label: "without {brand.name}" in regular black sans-serif

Five segments only on the right bar. Solid color block on the left bar. Both columns within the central 84% safe zone with comfortable padding from canvas edges. Headers and footers fully visible.

Modern minimal data-viz aesthetic — clean, Apple-Health-inspired. No additional text, no logos overlay, no UI chrome.
```

**Model notes:**
- **gpt-image-2:** clean. Geometric shapes + text labels render reliably.
- **nano-banana:** clean for the bars; small segment labels can blur. Bump pastel tones higher-contrast if using nano-banana.

---

## T18 — Flowchart "old way" vs "new way"

**When to use:** workflow / habit transformation. Best when the brand replaces a complicated process with a simple one. Strong for SaaS, supplements, productivity, info-products.

**Aspect ratio:** `1:1`

**Reference image:** product hero (drives the brand color in the new-way pill + box borders)

**Variables:**
- `{old_way_steps[]}` — 5 short pain-point steps for the old-way column (each ≤4 words). Last step is a "give up" / failure state.
- `{new_way_steps[]}` — 3 short steps for the new-way column (≤6 words each). Ends with the brand's outcome.
- `{closing_outcome}` — short bold tagline beneath the new-way chain (e.g. `Calm Consistency`, `Just one step`)
- `{brand.color_primary}` — for the new-way header pill + box borders

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a side-by-side hand-drawn-feel flowchart comparing "The Old Way" to "The New Way" as two contrasting workflows. Standalone ad creative, ready to upload. Cream / off-white background ~#F5F1EA.

LEFT HALF (~48% width) — "The Old Way":
- Header: a black rounded-rectangle pill at the top with white sans-serif text "The Old Way"
- Below it: a vertical chain of 5 small rectangular outlined boxes connected by thin black arrow lines pointing down, each box containing a short pain-point label in plain black sans-serif:
  1. {old_way_steps[0]}
  2. {old_way_steps[1]}
  3. {old_way_steps[2]}
  4. {old_way_steps[3]}
  5. {old_way_steps[4]}
- The bottom box has a small crossed-out icon next to it (or text "Give Up")
- The arrows are slightly wonky, hand-drawn-feel — gives "messy chaotic process" energy

RIGHT HALF (~48% width) — "The New Way":
- Header: a {brand.color_primary} rounded-rectangle pill at the top with white sans-serif text "The New Way"
- Below it: a shorter vertical chain of just 3 rounded-rectangle boxes connected by clean smooth arrow lines pointing down, each in a soft tone with darker border, containing:
  1. {new_way_steps[0]}
  2. {new_way_steps[1]}
  3. {new_way_steps[2]}
- Below the chain: a small flourish / star icon, and bold text "{closing_outcome}"
- The arrows here are clean and confident — gives "simple effective process" energy

Between the two halves, a thin vertical hairline grey divider runs top to bottom.

The flowchart has a hand-drawn / sketched feel (slight wobble in lines, irregular pen strokes) but stays clearly readable. All text labels are in plain black sans-serif inside their boxes — short phrases, no emoji.

No additional text, no logos overlay, no UI chrome.
```

**Model notes:**
- **gpt-image-2:** clean. Diagrammatic layout + small step labels render reliably.
- **nano-banana:** acceptable; the hand-drawn arrow feel between boxes is sometimes too clean. Add "wobbly, marker-drawn, imperfect line weight" to the prompt for nano-banana.

---

## T19 — Fake AirDrop dialog (with before/after)

**When to use:** stop-the-scroll iOS modal pattern. The AirDrop dialog is so familiar that users instinctively look at it. Pair with a before/after to deliver the value prop in one glance. Strong for transformation-led brands (apparel, fitness, supplements, beauty, finance).

**Aspect ratio:** `1:1`

**Reference image:** product hero (only used for color cues in the after photo)

**Variables:**
- `{prompt_question}` — the dialog's two-line subhead, ending with the brand cue (e.g. `Looking to feel like yourself again? Try {brand.name}.`)
- `{before_subject_description}` — what the left photo shows (the "before" pain state)
- `{after_subject_description}` — what the right photo shows (the "after" branded state)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a fake Apple AirDrop dialog mockup floating on a soft blurred background. Standalone ad creative, ready to upload.

Background: soft blurred neutral grey-beige photographic background ~#C9C6C0 (the look of a hand-held phone background, slightly out of focus, with no recognizable elements). The blurred background fills the entire canvas.

Centered in the canvas, occupying the central 80% width and 90% height: a white rounded-corner rectangular dialog card with subtle shadow. Inside the card, top to bottom:

1. Top section (~18% of card height): centered title "AirDrop" in bold black SF Pro Display, large (~52pt feel). Beneath the title, in regular black SF Pro at smaller size, two short stacked lines, centered:
   {prompt_question}

2. Middle section (~62% of card height): a horizontal split-screen photo, two equal-width images side by side with a thin white vertical divider between them. LEFT: {before_subject_description}. RIGHT: {after_subject_description}.

3. Bottom section (~20% of card height): a thin grey hairline divider across the card width, then two button areas split evenly with a thin vertical hairline between them. Left button: "Decline" in light blue (~#3B82F6) SF Pro regular weight. Right button: "Accept" in bold dark blue (~#1E3A8A) SF Pro Semibold.

The dialog card is clean and pixel-faithful to a real iOS AirDrop dialog. Comfortable safe-zone padding from canvas edges (~10% on all sides).

No additional text, no logos overlay, no iOS status bar / chrome around the dialog. Just the dialog card floating on the soft blurred background.
```

**Model notes:**
- **gpt-image-2:** clean. iOS dialog UI mimicry is strong. **Preferred backend.**
- **nano-banana:** the buttons can drift in color/position; iOS-modal proportions slip. Use gpt-image-2 unless unavailable.

---

## T20 — IG Story Q&A sticker over lifestyle photo

**When to use:** UGC / influencer authority — feels like a real creator answering a real question. Pair with an aspirational lifestyle background to bake the brand into the lifestyle the user wants.

**Aspect ratio:** `9:16`

**Reference image:** product hero (helps the answer text reference the actual product accurately)

**Variables:**
- `{lifestyle_photo_description}` — the full-bleed background (sunset coastline, mountain trail, kitchen at golden hour, etc.)
- `{question}` — the white-card question text (1-2 lines, conversational, ≤80 chars)
- `{answer}` — typewriter-style multi-line answer in 4 short lines, mentioning the brand naturally
- `{cta_text}` — bottom pill CTA (e.g. `🔗 SHOP NOW`)

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge — an Instagram Story-style "Ask me anything!" Q&A sticker overlaid on a beautiful lifestyle photograph. Standalone ad creative.

Background: {lifestyle_photo_description}. The photograph fills the canvas edge-to-edge with no border.

Overlaid on the upper third of the canvas, centered horizontally: a rectangular composite "AMA sticker + answer" element, occupying about 70% of the canvas width:

A. The TOP part is the IG Story "Ask me anything!" question sticker — a stacked two-block element:
   - Top block: a black rounded-rectangle bar containing centered white bold sans-serif text "Ask me anything!"
   - Bottom block (attached directly below the top): a white rounded-rectangle (matched corners) containing centered bold black sans-serif text in 2-3 lines: "{question}"
   - The two blocks visually read as a stacked sticker, cohesive unit.

B. Just below the sticker (with a small gap), the answer is rendered as a typewriter-style monospace text overlay on a translucent white panel, multi-line, centered horizontally with comfortable safe-zone padding from the canvas edges:
   "{answer}"

Bottom of the canvas (~10% from the bottom edge, well within safe zone): a small white rounded-pill CTA containing dark sans-serif text "{cta_text}". Centered horizontally.

The composition reads as a real "creator IG Story moment" — but rendered as the standalone ad creative. No iOS status bar, no Story progress bars, no story header at top, no swipe arrows at bottom, no home indicator, no tab nav.
```

**Model notes:**
- **nano-banana:** strong on the lifestyle-photo full-bleed background. **Preferred backend.**
- **gpt-image-2:** clean for the Q&A sticker UI, weaker on the photographic background realism.

---

## T21 — Handwritten testimonial on napkin / paper

**When to use:** UGC raw-and-real aesthetic. Reads as authentic creator content, not branded. Best for brands with a "friend recommendation" angle.

**Aspect ratio:** `2:3`

**Reference image:** product hero (used for the small product element placed near the napkin)

**Variables:**
- `{handwritten_message}` — multi-line cursive ink text, friend-to-friend voice, ending with the brand mention
- `{table_setting}` — what's around the napkin (cafe table, kitchen counter, marble countertop)
- `{product_element_description}` — the single product cue placed near the napkin (a sachet, a bottle, packaging glimpse)
- `{cta_color}` — color for the bottom shop-now pill

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a real-world tabletop photograph of a paper napkin with hand-written ink testimonial, set on a casual restaurant or kitchen table. Standalone ad creative, ready to upload.

Setting: a top-down, slightly angled photograph of {table_setting}. Centered in the frame: a folded white paper napkin (or a square white napkin laid flat), with hand-written black ink message scrawled across it in slightly imperfect cursive / casual handwriting. The handwriting is clearly readable but organic — uneven baseline, occasional ink bleed, real-pen-on-paper texture.

The hand-written message reads (verbatim, multi-line, allowing for natural line breaks):
"{handwritten_message}"

Surrounding the napkin on the table, casually placed (NOT staged): {product_element_description}.

Lighting: soft warm natural daylight from upper-left, casting gentle shadows. The aesthetic is homemade / UGC — like someone genuinely scribbled their thoughts at a coffee shop. NOT styled product photography.

Bottom 10% of the canvas (within safe-zone padding from bottom edge): a small white rounded-pill CTA containing {cta_color} bold sans-serif text "🔗 SHOP NOW" with a small link-chain icon, centered horizontally.

The composition feels like an organic post a friend would share — casual, lived-in, real.

No additional text, no logos overlay, no UI chrome.
```

**Model notes:**
- **nano-banana:** strong. Photoreal table + handwritten cursive ink is in its wheelhouse. **Preferred backend.**
- **gpt-image-2:** acceptable; handwriting can feel slightly font-like rather than organic.

---

## T23 — POV calendar timeline of pain points

**When to use:** relatability humor for time-pressed audiences (founders, parents, students). The brand emerges in the last calendar block as the relief. Strong scroll-stopper.

**Aspect ratio:** `1:1`

**Reference image:** product hero (only color cues)

**Variables:**
- `{pov_headline}` — two-line "POV: A [target customer]'s [domain] schedule" (e.g. `POV: A burned-out founder's daily energy schedule`)
- `{calendar_blocks[]}` — EXACTLY 8 events, top-to-bottom: 6 pain-points + 1 sliver "lunch / break / promise" + 1 final brand-arrival event. Each has color, title, and time range.
- `{time_axis_labels[]}` — 8 labels, each appearing exactly once (do NOT duplicate any label like "3 PM" twice)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a fake Apple Calendar app screenshot styled as a "POV: a [target customer]'s calendar" relatable-pain-point ad. Standalone ad creative, ready to upload. Pure white background.

Top of the canvas (~14% height, within safe-zone padding from top): a centered headline in bold black sans-serif (~32pt feel) across two stacked lines:
"{pov_headline}"

Below the headline, occupying the central ~80% of canvas: a calendar timeline view rendered as Apple Calendar dark mode (rounded-corner black panel with thin border). Inside the panel, a left-side time axis runs vertically with EXACTLY these eight labels stacked top-to-bottom (each label appears EXACTLY ONCE — do NOT duplicate any label):

{time_axis_labels[0]}
{time_axis_labels[1]}
{time_axis_labels[2]}
{time_axis_labels[3]}
{time_axis_labels[4]}
{time_axis_labels[5]}
{time_axis_labels[6]}
{time_axis_labels[7]}

Each time label sits beside a thin grey horizontal divider running across the panel.

Time-blocked event boxes fill the calendar in the right ~85% of the panel. Each event is a rounded rectangle with a soft pastel fill color and a thicker colored left-border accent. Each event contains, top to bottom: a bold colored title line, then a small clock icon + time-range label in muted text. Plain text only — NO emoji.

EXACTLY EIGHT event blocks, top to bottom — no more, no fewer:

1. {calendar_blocks[0].color} fill: "{calendar_blocks[0].title}" — "{calendar_blocks[0].time_range}"
2. {calendar_blocks[1].color} fill: "{calendar_blocks[1].title}" — "{calendar_blocks[1].time_range}"
3. {calendar_blocks[2]} (thin sliver — small text only, no time row)
4. {calendar_blocks[3].color} fill: "{calendar_blocks[3].title}" — "{calendar_blocks[3].time_range}"
5. {calendar_blocks[4].color} fill: "{calendar_blocks[4].title}" — "{calendar_blocks[4].time_range}"
6. {calendar_blocks[5].color} fill: "{calendar_blocks[5].title}" — "{calendar_blocks[5].time_range}"
7. {calendar_blocks[6]} (thin sliver — small text only, no time row)
8. {calendar_blocks[7].color} fill: "{calendar_blocks[7].title}" — "{calendar_blocks[7].time_range}"

The visual joke: every event until the last one is a relatable pain. The last event is the brand showing up.

Calendar panel sits centered with comfortable safe-zone padding from canvas edges (~8%). Headline at top fully visible, bottom of calendar panel doesn't touch the bottom edge of the canvas. Time labels in the left axis appear EXACTLY ONCE each — no duplicates.

No additional text, no logos overlay, no UI chrome.
```

**Model notes:**
- **gpt-image-2:** clean. Calendar UI mimicry + small block labels are reliably legible.
- **nano-banana:** block labels at small size blur; time-axis labels can repeat. **gpt-image-2 strongly preferred.**

---

## T24 — Phone-in-phone Reel composite

**When to use:** "watch this Reel" pattern — the canvas itself looks like a Reel still, with a phone-frame inset showing UGC. Strong when paired with intrigue overlay text ("Watch this BEFORE…", "What I tried after…"). Works for personality-led / influencer brands.

**Aspect ratio:** `9:16`

**Reference image:** product hero (used for the brand-pattern background and the product visible in the UGC photo)

**Variables:**
- `{background_pattern}` — repeating wordmark / branded backdrop (e.g. low-opacity brand wordmark on deep brand color)
- `{ugc_subject}` — what the inset photo shows (creator with product, mid-action, golden hour, etc.)
- `{overlay_text}` — black rounded-rectangle text label across the UGC photo (e.g. `Watch this BEFORE / your morning coffee`)
- `{cta_color}` — color for the bottom CTA bar
- `{cta_text}` — bottom CTA text (e.g. `Learn more`)

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge — a "phone-in-phone" composite where the canvas itself appears to be an Instagram Reel-style scene, with a stylized smartphone-frame inset in the center holding the actual ad creative content. Standalone ad creative, ready to upload.

Background: a deep saturated solid color fills the entire 9:16 canvas ({background_pattern.color}). Subtle pattern: faint brand wordmark text repeats across the background at a consistent angle (~15° clockwise rotation), with low opacity (~15%) — creating a textured "branded backdrop" feel without being too busy.

Centered in the canvas (occupying the central ~65% width, ~70% height — well within safe-zone padding): a portrait-oriented smartphone frame mockup rendered as a clean rounded-rectangle device shape (slightly tilted ~5° clockwise for dynamism, with a subtle drop shadow). The phone frame contains a vertical 9:16 image inside its screen — the ACTUAL ad content:

INSIDE THE PHONE SCREEN:
- A real-feeling UGC selfie photograph: {ugc_subject}
- Across the lower-mid of the photo, a black rounded-rectangle overlay text label with white bold sans-serif: "{overlay_text}"

Across the bottom 14% of the entire canvas (NOT inside the phone — overlaid on the background, with comfortable safe-zone padding from the bottom edge): a horizontal CTA bar in {cta_color} spanning the full canvas width, containing white bold sans-serif text "{cta_text}" left-aligned, with a small white right-arrow ">" on the right edge.

The composition reads as a Reel preview where someone is showing a phone screen. No iOS status bar, no Reel UI (no IG header, like buttons, comment count), no home indicator.
```

**Model notes:**
- **both: clean.** Phone-frame mockup renders well on both. nano-banana edges ahead if the UGC inset is realistic.

---

## T25 — Newspaper crossword puzzle

**When to use:** clever editorial brand-puzzle moment. Plays well in lifestyle / wellness categories where a "Sunday morning, coffee and crossword" association is on-brand.

**Aspect ratio:** `1:1`

**Reference image:** product hero (props the small product accent)

**Variables:** `{newspaper_masthead}` (e.g. "The {brand.name} Daily"), `{date_string}`, `{across_clues[]}`, `{down_clues[]}`, `{filled_words[]}` (3-4 short crossing words, ≤5 letters each so each grid cell stays large enough to render legibly)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a top-down photograph of a fake newspaper page featuring a small partially-filled crossword puzzle, displayed on a wooden coffee-shop table with subtle props. Standalone ad creative.

The newspaper page fills ~75% of the frame, slightly tilted. Cream/beige aged-newsprint texture and crisp serif typography. Subtle warm shadow from morning daylight. Surrounding the newspaper on the wood surface: a small white cup of coffee with steam (top-right corner of frame), a few loose brand product travel sachets scattered along the top and right edges of the frame, and a brand product pouch tucked into the bottom-right corner.

Newspaper layout, top to bottom:

- Masthead: "{newspaper_masthead}" in classic black serif, large, with a horizontal rule beneath
- Sub-header: "{date_string}" in small italic serif

- Centered crossword grid: a SMALL 5x5 square grid (only 25 cells total — keep it small so each cell is large enough that letters render legibly). Cells alternate between black squares (separators) and white squares with bold black UPPERCASE Helvetica-style letters inside. Each white cell contains EXACTLY ONE big bold black capital letter, rendered at large readable size (~50pt feel inside its cell).

- The grid has THREE filled-in words crossing each other:
  {filled_words[0]} (horizontal)
  {filled_words[1]} (vertical, intersecting {filled_words[0]})
  {filled_words[2]} (vertical, intersecting {filled_words[0]})

  Adjust if the geometry doesn't fit exactly — the goal is THREE fully-spelled crossing words rendered with ONE big crisp letter per cell, all clearly legible. Black squares fill any cells without letters.

- To the right of the grid, a numbered clue list in small black sans-serif:
  ACROSS:
  {across_clues}

  DOWN:
  {down_clues}

- Faint brand wordmark watermark at the bottom-right corner of the page in light grey

Photographic style: warm editorial, real newsprint texture, "good morning, coffee + paper" lifestyle moment. The crossword is small but the letters in each cell are big and crisp.
```

**Note:** Keep the grid SMALL (5x5 max) and use only 3-4 short crossing words. Letters in tiny crossword cells garble; a small grid with big letters renders clean.

**Model notes:**
- **gpt-image-2:** acceptable. Strict 5x5 grid with big letters still requires explicit prompting; even then expect 10-15% iteration to land clean.
- **nano-banana:** weaker — letters in grid cells reliably scramble. Use gpt-image-2 unless you accept iteration cost.

---

## T26 — Cash register receipt

**When to use:** product-as-receipt joke. List the brand's "benefits received" as itemized line items + total. Strong for "you get [list]" value-prop positioning.

**Aspect ratio:** `1:1`

**Reference image:** product hero (sits beside the receipt as a real-world prop)

**Variables:** `{store_header}` (multi-line header for the receipt), `{date_line}`, `{benefits[]}` (each `{label, value}` like `ENERGY  FREE`), `{total_line}` (e.g. "ONE GREAT DAY"), `{footer_text}`

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a top-down photograph of a long thermal-printer cash register receipt, slightly crumpled and curled at the bottom edge, lying on a clean cream/beige flat surface. The brand product sits to the right of the receipt as a real-world prop. Standalone ad creative.

Receipt details:
- White thermal paper, slightly textured, long and narrow (about 35% of canvas width, full canvas height plus a curl at the bottom)
- Header in monospaced black caps: "{store_header}"
- A "BENEFITS RECEIVED" label in bold caps
- Itemized list in monospace, each line: benefit name (left) and value (right):
  {benefits rendered as monospace left-right pairs}
  ----------------------------
  SUBTOTAL              FREE
  TAX                   FREE
  ----------------------------
  TOTAL: {total_line}
- Below the total, a faux barcode (vertical black lines) and small footer text: "{footer_text}"

The brand product sits casually beside the receipt on the right side of the canvas, well within safe-zone padding.

Soft warm natural light from upper-left, gentle shadow under both the receipt and the product. Editorial flat-lay aesthetic, premium-wellness vibe.
```

**Model notes:**
- **nano-banana:** strong on the receipt photo realism. Monospace text legibility holds at this scale.
- **gpt-image-2:** clean for the monospace text; receipt photo can feel composited. Either backend works.

---

## T27 — Handwritten founder letter

**When to use:** intimate brand storytelling. Founder voice, mission, gratitude, or insider-first-batch moment. Premium DTC brands use this to humanize at scale.

**Aspect ratio:** `2:3`

**Reference image:** product hero (placed beside the letter as a desk prop)

**Variables:** `{letter_body}` (handwritten cursive, 6-10 short lines max — keep it sparse), `{founder_name}`, `{footer}` (URL + role)

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a top-down photograph of a handwritten founder's letter on cream stationery, with the brand product and a fountain pen as props on a warm walnut wood desk. Standalone ad creative.

Composition:
- Background: a warm walnut wood desk surface, slightly textured grain, with a leather notebook visible at the very edge (top-left corner) and a small chart/document peeking from the bottom-right corner.
- Centered: a single piece of cream/off-white stationery (~70% of canvas width, slightly tilted ~3° clockwise), with a printed brand wordmark in the top-left corner of the page.
- A black ink fountain pen rests across the bottom-right corner of the letter.
- One coffee-cup ring stain in faint brown on the bottom-left corner of the paper (organic detail).
- A handwritten letter in flowing dark-blue ink cursive fills the page. The handwriting is realistic, slightly imperfect, with natural ink flow and varying line weights. The letter reads (verbatim):

"{letter_body}"

To the right of the letter (lower-right area, partially overlapping the page edge): the brand product standing upright with its wordmark visible, alongside a travel sachet or secondary SKU beside it.

Soft warm side lighting from the upper-left, casting gentle shadows. The composition feels like a thoughtful, personal founder's gesture — premium and intimate, not staged.
```

**Note:** Both models partially garble handwritten cursive — keep letter content under 10 lines and accept that 2-3 words may shift. The aesthetic and intent come through; word-perfect handwriting is hard.

**Model notes:**
- **nano-banana:** strong on the desk-photo realism; cursive imperfection feels organic.
- **gpt-image-2:** cursive can feel slightly font-like. Pass an actual handwriting sample as `--image-ref` to anchor the script style.

---

## T28 — Dating app swipe card (Hinge-style)

**When to use:** brand personality / "what we're about" angle. Treats the brand as a dateable persona. Strong for personality brands and lifestyle products.

**Aspect ratio:** `2:3`

**Reference image:** product hero (the photo on the profile card)

**Variables:** `{brand_age_label}` (e.g. "{brand.name}, 75" — using ingredient count as age), `{location_line}` (e.g. "Foundational Nutrition · Here for the long haul"), `{prompts[]}` (2 prompt+answer pairs in Hinge style)

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a fake Hinge-style dating app profile card with the brand product as the "match" subject. Standalone ad creative. Soft cream/off-white background ~#F8F5F0 fills the entire canvas.

The image renders ONE single profile card, centered, occupying ~85% of the canvas with comfortable safe-zone padding. The card has rounded corners and a subtle drop shadow.

Card content, top to bottom:

1. Header bar (~6% of card height): bold black sans-serif "{brand_age_label}". Below: a small black location pin glyph + light grey text "{location_line}"

2. Hero image (~50% of card height): a clean editorial photograph of the brand product. Soft cream background, premium product photography. A small grey heart icon sits in the bottom-right corner of the photo (the Hinge "like a photo" indicator).

3. Below the photo, two stacked Hinge-style answer prompts. Each prompt has: a small light-grey label, then below the label, a black sans-serif answer in larger type. The two prompts read:

PROMPT 1:
Label: "{prompts[0].label}"
Answer: "{prompts[0].answer}"

PROMPT 2:
Label: "{prompts[1].label}"
Answer: "{prompts[1].answer}"

Each prompt has a small grey heart icon in its bottom-right corner.

4. Bottom of card (~10% height): two large circular buttons side by side, centered horizontally with a gap between them. Left button: white circle with grey "X" inside (Pass). Right button: pink-purple gradient circle with white "♥" inside (Like).

The composition reads as a real Hinge profile, but rendered as a standalone ad creative.
```

**Model notes:**
- **gpt-image-2:** clean. App UI mimicry is strong. **Preferred backend.**
- **nano-banana:** acceptable; the X / ♥ buttons can drift.

---

## T29 — TikTok creator video screenshot

**When to use:** UGC creator energy. "Influencer holding the product mid-explanation" with chunky white-on-black caption text + comments overlay sliding up from the bottom. Native to TikTok/Reels.

**Aspect ratio:** `9:16`

**Reference image:** product hero

**Variables:** `{creator_description}` (1-line — age, energy, setting), `{caption_text}` (3-4 short lines, white on black rounded-rectangles), `{comments[]}` (2 fake comments with @handle + body + heart count)

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge — a fake TikTok video screenshot with a creator holding the product, captions, and a comments overlay. Standalone ad creative.

The full canvas is filled with a vertical TikTok-style video frame. Background: {creator_description}, cinematic shallow depth of field, the background is softly blurred.

Overlaid on the video, lower-mid area, in the chunky angled white-text-on-black-rounded-rectangles aesthetic typical of TikTok captions:
"{caption_text}"

In the lower third of the canvas (below the captions, above the comments overlay), an OVERLAY panel rendered in semi-transparent dark grey appears to be the comments section sliding up from the bottom. Inside the panel, two visible comments rendered top to bottom:

Comment 1:
- Small circular avatar (cartoon person)
- "@{comments[0].handle}"
- Comment text: "{comments[0].body}"
- Below: a small heart icon and "{comments[0].count}"

Comment 2:
- Small circular avatar
- "@{comments[1].handle}"
- Comment text: "{comments[1].body}"
- Below: heart icon and "{comments[1].count}"

The composition reads as an organic TikTok creator post — but rendered as a standalone ad creative. No iOS chrome, no TikTok navigation tabs at the bottom, no like/share/comment side rail beyond the comments overlay panel.
```

**Model notes:**
- **nano-banana:** strong on the creator photograph (mid-action, natural lighting). **Preferred backend** for the photo half.
- **gpt-image-2:** clean for the caption rectangles + comments overlay. Hybrid approach: generate the creator photo with nano-banana, then composite captions with gpt-image-2 if you want both.

---

## T30 — Billboard / OOH placement mockup

**When to use:** "we're a real brand" credibility through scale. Subway, transit, or street billboard imagery. Gives the brand the gravitas of an OOH campaign.

**Aspect ratio:** `1:1`

**Reference image:** product hero (small product photo at the bottom of the billboard)

**Variables:** `{environment}` (e.g. "modern subway platform"), `{billboard_headline}` (2 stacked lines, bold sans), `{billboard_subcopy}`, `{brand.color_primary}` (billboard background), `{brand.url}`

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a photograph of a real-world out-of-home billboard or subway/bus-stop digital ad placement featuring the brand. Standalone ad creative.

Setting: {environment}, slightly out of focus with cinematic depth of field. Soft atmospheric lighting, with a few blurred silhouettes of pedestrians walking past.

Centered in the frame: a large rectangular vertical digital billboard (transit-style display), occupying ~70% of canvas width and ~80% of canvas height. The billboard has a thin dark frame with a clean lit display face inside.

Inside the billboard display:
- Background: {brand.color_primary}, edge-to-edge inside the frame
- Top-left corner: small white brand wordmark
- Center, large bold white sans-serif headline (~40% of billboard height) in two stacked lines: "{billboard_headline}"
- Below the headline, slightly smaller white sans-serif: "{billboard_subcopy}"
- Bottom-center: a clean photograph of the brand product set.
- Very bottom: small white URL "{brand.url}"

The billboard is brightly lit (slight glow on the surrounding wall), set into a real-world environment with motion-blurred passers-by and atmospheric background. Premium DTC OOH aesthetic.
```

**Model notes:**
- **nano-banana:** strong on environmental photo realism (motion blur, transit lighting). **Preferred backend.**
- **gpt-image-2:** clean for the billboard typography content; environment realism slightly composited.

---

## T31 — Scratch-off lottery ticket

**When to use:** novelty / interactive feel. Treats the brand's benefits as "scratch to win" panels. Tactile, fun, distinctive.

**Aspect ratio:** `2:3`

**Reference image:** product hero (one of the 6 panels shows the actual product photo)

**Variables:** `{ticket_title}` (e.g. "Match to Foundational Nutrition"), `{benefit_panels[]}` (5 panels, each `{icon, label}`), `{footer_line}` (e.g. "$0 LOSING TICKETS. EVERY SCOOP WINS."), `{ticket_serial}`

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a top-down photograph of a physical scratch-off lottery ticket on a slightly textured surface, with scratched-off silver foil flakes scattered around it. Standalone ad creative.

Background: a soft greige textured surface (like brushed concrete or matte cardstock). Faint silver scratch-off flakes dust the surface around the ticket.

Centered: a single rectangular scratch-off card (~75% of canvas width, slightly tilted ~3° clockwise), thick cardstock with rounded corners, a faint paper texture. The ticket has a deep brand-color border (~5% of card width) framing the central content.

Ticket content, top to bottom:
- Top header bar: white box containing "BRAND PRESENTS" in small brand-color caps, a small icon, and serial number "{ticket_serial}"
- Title: "{ticket_title}" in bold dark serif (large)
- Centered: a 3x2 grid of six square panels — five of them are silver scratch-off panels (with realistic foil texture, partially scratched away revealing icons + words underneath), one is a clean white panel containing the brand product photo.

The five scratched-off icons reveal in white circles with dark icons + caps labels beneath:
1. Top-left: {benefit_panels[0].icon} icon, label "{benefit_panels[0].label}"
2. Top-middle: {benefit_panels[1].icon} icon, label "{benefit_panels[1].label}"
3. Top-right: {benefit_panels[2].icon} icon, label "{benefit_panels[2].label}"
4. Bottom-left: {benefit_panels[3].icon} icon, label "{benefit_panels[3].label}"
5. Bottom-middle: {benefit_panels[4].icon} icon, label "{benefit_panels[4].label}"
6. Bottom-right: clean white panel with the brand product photo

- Below the grid, large bold serif: "WIN ALL FIVE = {ticket_title}"
- Footer text in small caps: "{footer_line}"
- Bottom-right corner: a small round coin prop photographed beside the ticket

Soft top-down lighting, slight shadow under the card. Tactile, real-world product-photography aesthetic.
```

**Model notes:**
- **nano-banana:** strong on the foil/scratch-off material texture. **Preferred backend.**
- **gpt-image-2:** clean for the icon labels + ticket typography; foil texture feels slightly flat.

---

## T32 — Pain-point checklist + product

**When to use:** problem-aware audiences. Lead with their pain via an unchecked-checkbox list, deliver the product as the answer below.

**Aspect ratio:** `1:1`

**Reference image:** product hero

**Variables:** `{headline}` (2-line bold all-caps question or statement), `{checklist_items[]}` (exactly 5 unchecked items, each conversational), `{tagline}` (1 closing line in bold serif), `{footer_url_line}`

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a clean editorial layout with a bold pain-point headline at top, an unchecked checklist of relatable pain points in the middle, the brand product photo in the lower portion, and a calm tagline + brand wordmark at bottom. Standalone ad creative. Pure white background.

Top section (~22% height): a centered bold black sans-serif headline in two stacked lines, large (~60pt feel), tight tracking:
"{headline}"

Middle section (~32% height, generous vertical spacing): a vertical list of EXACTLY FIVE checklist items, each row consisting of a hollow grey square checkbox on the left + the question text in regular black sans-serif. Items (verbatim):
☐ {checklist_items[0]}
☐ {checklist_items[1]}
☐ {checklist_items[2]}
☐ {checklist_items[3]}
☐ {checklist_items[4]}

Lower section (~32% height): a clean centered editorial photograph of the brand product. Soft natural light, premium product photography.

Bottom section (~14% height): centered, two stacked lines of black text:
- Line 1: bold serif: "{tagline}"
- Line 2: smaller regular sans-serif: "{footer_url_line}"

All text and product within the central 84% safe zone. Modern, premium, calm aesthetic.
```

**Model notes:**
- **both: clean.** Minimal layout, large text, single product hero — neither model struggles.

---

## T33 — Bold typography hero quote

**When to use:** stop-the-scroll brutalist statement. Strong for declarative or contrarian brand voice. Type IS the visual.

**Aspect ratio:** `1:1`

**Reference image:** product hero (small product accent in the lower-right)

**Variables:** `{statement}` (3-line punchy declaration in chunky condensed sans, ~140pt feel, period at the end), `{supporting_text}` (3-4 short lines in the lower-left), `{brand.color_primary}` (canvas background), `{type_color}` (cream off-white that contrasts the brand color)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a bold editorial typography hero with a punchy three-line statement filling most of the canvas, a small product photo as a footnote, and minimal supporting text. Standalone ad creative.

Background: {brand.color_primary}, edge-to-edge, with a subtle radial darker vignette centered on the canvas.

Top 60% of the canvas: a HUGE bold sans-serif statement (~140pt feel — chunky, condensed, brutalist) in {type_color}, stacked across three lines, left-aligned with consistent left margin (~10% from canvas left edge):

"{statement}"

Each line is a full uppercase sentence-fragment. The third line ends with a period. Letter-spacing is tight, line-height is tight (lines almost touch). The TYPE is the hero — not centered, intentionally left-aligned.

A small hand-drawn arrow ({type_color} outline, slightly wobbly, marker-style) curves down-right from the period at the end of the last line, pointing toward the lower-right corner of the canvas where the product sits.

Bottom-right corner (~28% of canvas, fully within safe zone): a clean editorial photograph of the brand product — the product with its wordmark visible, slightly tilted, with a faint soft drop shadow. The product is photographed against the same brand-color background, color-matched.

To the left of the product (lower-left quadrant), in {type_color} sans-serif at smaller size (~28pt), three short stacked lines:
"{supporting_text}"

Modern, brutalist-meets-premium typography aesthetic. The type makes the joke; the product punctuates it.
```

**Model notes:**
- **gpt-image-2:** clean. Type-led layouts are its strength. **Preferred backend.**
- **nano-banana:** condensed-sans letterforms drift; tight letter-spacing slips. Use gpt-image-2 for this template.

---

## T34 — iMessage conversation (with rich link card)

**When to use:** "friend recommended it" social proof. Pixel-faithful iOS Messages screenshot, including a rich link preview card embedded in the conversation.

**Aspect ratio:** `9:16`

**Reference image:** product hero (used in the rich link preview card)

**Variables:** `{contact_name}`, `{messages[]}` (4 bubbles total: 2 incoming grey, 2 outgoing blue including 1 with a rich link card preview), `{rich_card.url}`, `{rich_card.title}`, `{rich_card.description}`

**Template prompt:**
```
9:16 portrait static ad creative, 1080x1920, edge-to-edge — a fake iOS Messages app conversation thread with EXACTLY FOUR message bubbles (two from a friend, two replies — the second reply is a rich link card). Standalone ad creative. Pure white background ~#FFFFFF.

Top of the canvas (~10% height): a Messages app conversation header — centered, a small circular contact avatar (~40px) with a letter inside, then below it the contact name "{contact_name}" in regular black SF Pro, then below in smaller grey: "Today {messages[0].time}". NO iOS status bar, NO back button.

Below the header, an EXACT FOUR-bubble vertical chat sequence with comfortable spacing between bubbles. Plain text only, no emoji, no special glyphs.

BUBBLE 1 (incoming, left-aligned):
- Light grey rounded bubble (~#E9E9EB) with black sans-serif text inside:
  "{messages[0].text}"

BUBBLE 2 (outgoing reply, right-aligned, blue):
- iMessage blue bubble (~#0B93F6) with white sans-serif text inside:
  "{messages[1].text}"

BUBBLE 3 (outgoing follow-up, right-aligned): a "rich link preview" attachment card embedded as a message — white rounded card with a thin grey border. Inside the card top to bottom:
- Small editorial photograph of the brand product
- Below the photo, a thin hairline divider, then small black text:
  Title: "{rich_card.url}"
  Subtitle: "{rich_card.description}"

BUBBLE 4 (incoming, left-aligned):
- Light grey bubble:
  "{messages[3].text}"

Below the conversation, a thin grey divider, then a Messages app input row: rounded grey input pill containing the placeholder text "iMessage" in light grey, with a small camera icon on the left and a microphone icon on the right.

The composition reads like a real iPhone Messages screenshot — but rendered as a standalone ad creative. NO iOS status bar, NO home indicator, NO Messages tab bar at the bottom.
```

**Model notes:**
- **gpt-image-2:** clean. iOS Messages UI mimicry is strong, rich-link card renders faithfully. **Preferred backend.**
- **nano-banana:** the rich-link card and iMessage chrome can drift in proportion. Use gpt-image-2.

---

## T35 — Magazine cover

**When to use:** premium brand spotlight. Editorial magazine masthead with the product as the cover hero. Pairs well with wellness, fashion, lifestyle categories.

**Aspect ratio:** `2:3`

**Reference image:** product hero (the cover photograph)

**Variables:** `{magazine_title}` (e.g. "VITALITY"), `{issue_subbar}` (e.g. "THE WELLNESS ISSUE · SUMMER 2026 · ISSUE 16"), `{cover_lines[]}` (3-4 cover-line headlines stacked down the left edge, each with a topic + 1-line description), `{spotlight_badge_text}`, `{bottom_band_text}` (italic serif, 2 lines)

**Template prompt:**
```
2:3 portrait static ad creative, 1080x1620, edge-to-edge — a fake premium wellness magazine cover with the brand product as the hero. Standalone ad creative.

Layout reads as a magazine cover from top to bottom:

TOP MASTHEAD (~14% height): the magazine title "{magazine_title}" in a chunky bold serif logo, large, centered, in black. Just beneath it in smaller all-caps serif: "{issue_subbar}". A thin horizontal hairline divider beneath.

LEFT EDGE (~30% width, vertical column of cover-line text):
{cover_lines rendered as stacked bold headline + smaller description pairs, separated by em-dashes}

CENTER (the hero): a large editorial photograph of the brand product occupying the center-right of the cover (~50% of canvas width). Soft natural daylight. The product is the visual focal point of the cover.

UPPER-RIGHT CORNER overlay: a small circular badge in a complementary color, with white serif text inside reading: "{spotlight_badge_text}"

BOTTOM (~14% height): an inset cream band edge-to-edge, with centered serif italic text in dark brand color:
"{bottom_band_text}"

The aesthetic is glossy premium magazine — Vogue / Goop / Real Simple feel.
```

**Model notes:**
- **both: clean.** Both render the masthead + cover photo well. nano-banana edges ahead on hero photo richness.

---

## T36 — Lifestyle "operator's daily kit" flatlay

**When to use:** "what's in my bag/desk" lifestyle association. Curated flatlay of the brand product alongside aspirational everyday-carry items, each labeled with a small annotation. Strong for premium DTC trying to attach to a target audience's identity.

**Aspect ratio:** `1:1`

**Reference image:** product hero (centerpiece of the flatlay)

**Variables:** `{surface_color}` (typically charcoal-black or warm walnut), `{items[]}` (6-8 EDC items each with `{description, position, label}`), `{center_caption}` (small product label under the centerpiece)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a top-down "what's on my desk" lifestyle flatlay with the brand product as the centerpiece, surrounded by curated everyday-carry items each connected to a small annotation label. Standalone ad creative.

Background: {surface_color} surface, edge-to-edge, with subtle texture.

Centerpiece: the brand product — its primary SKU with wordmark visible, alongside its secondary SKU or shaker bottle, sitting roughly center-canvas.

Surrounding the product in a balanced top-down composition (each item separated by negative space and casually arranged, not perfectly grid-aligned):
{items rendered as natural positions: top-left, top-right, right side, bottom-right, bottom-left, left side, far-left}

For each surrounding item, a thin white hairline annotation line extends from the item to a small white sans-serif text label positioned near the canvas edge (well within safe zone). Labels:
{items[].label for each item}

Center label, just under the product itself: a small white sans-serif title in two stacked lines: "{center_caption}"

Soft cinematic top-down lighting from upper-left, gentle shadows beneath each object. The composition reads as a curated "operator's daily kit" — every item tagged. Premium-DTC editorial aesthetic.
```

**Model notes:**
- **nano-banana:** strong on flatlay realism + material differentiation (leather, metal, fabric textures). **Preferred backend.**
- **gpt-image-2:** clean for the annotation labels; flatlay can feel slightly synthetic.

---

## T37 — Weather-app forecast UI

**When to use:** "your day on the brand" wellness narrative styled as a weather forecast. Each "hour" is a brand-driven outcome (Clear Strategy, Stress-Free Sunset, etc.). Distinctive and on-trend.

**Aspect ratio:** `1:1`

**Reference image:** product hero

**Variables:** `{headline}` (2-line "0% Stress." style), `{forecast_columns[]}` (5 columns, each `{time, icon_shape, condition_label, subtitle}`)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a fake "Weather forecast" UI styled as a wellness/energy daily forecast for the brand. Standalone ad creative. Soft cream / warm off-white background ~#F5F1EA.

Top section (~22% height): a small grey caps label "FORECAST SOURCE" in muted text, then below a centered bold black sans-serif headline (~50pt feel) in two stacked lines:
"{headline}"

Below the headline, a thin grey hairline divider running across most of the canvas width.

Middle section (~46% height): a horizontal hourly weather-forecast strip — five evenly-spaced columns, each containing top-to-bottom: a time label (small grey sans), a small soft-color weather-style icon (stylized minimal vector-style), a short weather-style condition label in black sans-serif, an even smaller subtitle in light grey. The five columns:

Column 1: "{forecast_columns[0].time}"  {forecast_columns[0].icon_shape} icon  "{forecast_columns[0].condition_label}"  "{forecast_columns[0].subtitle}"
Column 2: "{forecast_columns[1].time}"  {forecast_columns[1].icon_shape} icon  "{forecast_columns[1].condition_label}"  "{forecast_columns[1].subtitle}"
Column 3: "{forecast_columns[2].time}"  {forecast_columns[2].icon_shape} icon  "{forecast_columns[2].condition_label}"  "{forecast_columns[2].subtitle}"
Column 4: "{forecast_columns[3].time}"  {forecast_columns[3].icon_shape} icon  "{forecast_columns[3].condition_label}"  "{forecast_columns[3].subtitle}"
Column 5: "{forecast_columns[4].time}"  {forecast_columns[4].icon_shape} icon  "{forecast_columns[4].condition_label}"  "{forecast_columns[4].subtitle}"

(Render the icons as SHAPES, not literal emoji — stylized minimal vector glyphs in soft pastel colors.)

Lower section (~28% height): a clean editorial photograph of the brand product, centered, well within the safe zone. Soft natural light, premium product photography.

Bottom (~4% height): centered, small black sans-serif: "{brand.name} — {brand.url}"

The composition reads like a calm, designed weather-app forecast widget, but the data is "your day on {brand.name}." Modern minimal aesthetic.
```

**Model notes:**
- **gpt-image-2:** clean. UI mimicry + icon rendering reliable.
- **nano-banana:** icons can drift toward emoji-style instead of vector shapes; column labels at small size blur.

---

## T38 — Big stat hero with chart

**When to use:** data-led credibility. Lead with a giant percentage/number, support with a minimal line chart, anchor with the product. Strong for outcome-driven brands (supplements, productivity, finance).

**Aspect ratio:** `1:1`

**Reference image:** product hero (right side of the canvas)

**Variables:** `{stat_value}` (e.g. "-37%" — the giant headline number in chunky condensed sans), `{stat_subhead}` (2-line bold black, e.g. "LESS STRESS. / MORE FOCUS."), `{stat_caption}` (1-line explanation), `{chart_axis_labels}` (e.g. weekly markers), `{benefit_icon_rows}` (3 small icon+label rows)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a bold statistic-led ad with a giant percentage headline, a small minimal chart underneath, and the product to the side. Standalone ad creative. Pure white background.

Top-left occupying ~50% width and ~50% height: a HUGE bold dark sans-serif statistic "{stat_value}" rendered in a chunky modern condensed sans (~180pt feel), with all characters full-size. Letter-spacing is tight.

Below the giant number, in slightly smaller bold black sans-serif (~36pt), a stacked two-line statement:
"{stat_subhead}"

Below that, in regular black sans-serif at smaller size (~16pt), a single explanatory line:
"{stat_caption}"

Below the explanatory line, a SMALL clean line-chart visualization (~30% of canvas width): a horizontal axis with tick labels ({chart_axis_labels}), a vertical axis with a soft grid, and a single brand-color line descending from the upper-left to the lower-right with small dot markers at each tick. A single emphasized "{stat_value}" label at the lowest point (small white pill on the line). Below the chart, three tiny stacked icon+caption rows: {benefit_icon_rows[0]}, {benefit_icon_rows[1]}, {benefit_icon_rows[2]} with small icons preceding each.

Right side of the canvas (~40% width, vertically centered): a clean editorial photograph of the brand product. The product is photographed against a faintly cream background that fades into the white canvas, with subtle drop shadow.

Bottom (~6% height): small black sans-serif "{brand.name} · {brand.url}" centered.

Modern data-led editorial design. The big number is the hero; the chart proves it; the product is the deliverable.
```

**Model notes:**
- **gpt-image-2:** clean. Strong on the stat number + chart axis labels.
- **nano-banana:** stat number renders fine at giant size; chart axis labels can blur. Acceptable.

---

## T39 — Museum exhibit display

**When to use:** "the brand as cultural artifact" prestige play. Treats the product as an art piece on a plinth with a museum placard. Aspirational, premium, tongue-in-cheek.

**Aspect ratio:** `1:1`

**Reference image:** product hero (placed on the plinth)

**Variables:** `{placard_title}` (e.g. "BRAND NEXT GEN"), `{placard_subtitle}` (e.g. "Foundational Nutrition, 2026"), `{placard_body}` (2-4 sentence "museum label" describing the artifact in dry institutional voice)

**Template prompt:**
```
1:1 static ad creative, 1080x1080, edge-to-edge — a photograph of the brand product displayed on a polished plinth in a hushed art-gallery / museum interior, with a small placard wall-mounted to the right. Standalone ad creative.

Setting: a clean, minimal modern art-gallery interior — pale beige or off-white wall (~#EDEAE3) extending across the canvas, smooth concrete or polished hardwood floor (visible at the bottom edge of the canvas), soft directional spot-lighting from above. Subtle architectural elements (a faint corner edge, a hint of a doorway in the deep background) add depth, but the wall is the dominant background element.

Center-left of the canvas: a slim rectangular plinth (warm walnut-wood top, deep matte charcoal sides), about 18% of canvas height, photographed from a slight 3/4 angle. On the plinth, dramatically lit from above: the brand product — the primary SKU with wordmark visible and a small secondary SKU beside it. A soft warm spot-light highlight catches the top of the product, casting a gentle elongated shadow on the plinth surface.

Right of center, mounted on the wall at eye-level: a small white rectangular gallery placard (~22% of canvas width, ~28% of canvas height) with a thin grey border. Inside the placard, formal museum-label typography:
- Top line, small caps black serif: "BRAND —"
- Title line, black serif (~22pt): "{placard_title}"
- Subtitle: "{placard_subtitle}"
- Body, small black sans-serif:
  "{placard_body}"
- Bottom right corner of placard, faint italic: "On loan from {brand.url}"

Cinematic museum lighting: a soft warm pool of light around the plinth, rest of the canvas falling slightly into ambient light. The composition treats the product as art — quiet, premium, almost reverent. Photographic style is clean editorial, like a real gallery installation shot.
```

**Note:** Both models partially garble the small placard body text. Keep it under 4 sentences and the title/subtitle will stay crisp.

**Model notes:**
- **nano-banana:** strong on the gallery photo + plinth lighting. **Preferred backend** for the environment.
- **gpt-image-2:** clean for the placard typography; gallery realism slightly composited.

---

## Adding new templates

When a new ad reference is worth turning into a template, reverse-engineer it by hand (skeleton in [template-format.md](template-format.md)):

1. Generate a faithful reproduction with `--image-ref` set to the original reference (round 1).
2. Strip the chrome from the prompt and re-run (round 2) — verify the standalone creative still reads correctly.
3. Identify what's brand-specific vs. structural; replace brand-specific bits with `{placeholder}` variables.
4. Write a brand example fill against a different brand to verify the template generalizes.
5. Test against **both** target models and write a `Model notes` line for each — say where each shines, where each struggles.
6. Append the section to this file with: when-to-use, aspect ratio, reference image guidance, variable schema, template prompt, example fill, model notes, and path to the validated example.

New templates start at **T40** (T1–T39 are the seeded library, with intentional gaps at T16 and T22). Use the skeleton in `template-format.md`. Validate against the model you intend to ship on before committing the entry.

## Known rendering limits (mitigated by always-on suffixes)

- **Dense small text still garbles** even with the glyph-safety suffix — true on both gpt-image-2 and nano-banana, especially in chat bubbles, table rows, calendar blocks, ChatGPT responses. Keep body-text blocks SPARSE — 3-4 short lines max for chat/response bubbles, large readable size. The fix is fewer words, not more rules.
- **Reference image bleeds.** When the reference is a product hero, the model sometimes draws extra product shots into negative space even when not requested. Usually harmless; constrain with "NO additional product shots beyond the one described" if it's a problem.
- **Tall content + 1:1 canvas = clipping.** Even with `SAFE_ZONE_SUFFIX`, a held-up board / letter sign / portrait product really benefits from a tall aspect ratio (`2:3` or `9:16`). Pick the canvas to match the focal subject's proportions.

**Solved by the always-on suffixes (no longer need to call out per template):**
- ~~iOS chrome / Sponsored badges / engagement rows leak in~~ — handled by `NO_CHROME_SUFFIX`
- ~~Headlines clipping at edges~~ — handled by `SAFE_ZONE_SUFFIX`
- ~~Emoji in chat bubbles becomes glyph soup~~ — handled by `GLYPH_SAFETY_SUFFIX`
- ~~Phantom 3rd comment / extra Slack message appears~~ — handled by `GLYPH_SAFETY_SUFFIX` count constraint
