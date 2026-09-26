# Library entry format

Markdown skeleton for an entry in `prompt-library.md`. Match this format exactly when appending new entries so the file stays consistent across both `gpt-image-2` and `nano-banana` consumers.

## Skeleton

```markdown
## {tag} — {one-line title}

**When to use:** {1-2 sentence positioning fit. What kind of ad is this? Who/what is it good for?}

**Aspect ratio:** `{ratio}` ({1-line why — e.g. "Meta feed-portrait friendly", "Stories / Reels"})

**Reference image:** {what kind of `--image-ref` to pass. Examples: "clean product hero (white background, all SKUs visible)", "lifestyle portrait of subject mid-action", "logo + product flatlay"}

**Variables:**
- `{variable_name}` — {description; what kind of value goes in it; format hint if any}
- `{variable_name}` — ...

**Template prompt:**
\`\`\`
{The full prompt text, with {placeholders} embedded. Should produce a standalone ad creative when filled and paired with the reference image. No screenshot/platform chrome.}
\`\`\`

**Example fill** ({brand_name}):
- `{variable_name}` = `{example value}`
- `{variable_name}` = `{example value}`
- ...

**Model notes:**
- **gpt-image-2:** {known strengths/limits with this template}
- **nano-banana:** {known strengths/limits}

---
```

(End every entry with a horizontal rule on its own line so the next entry has visual separation.)

---

## Field-by-field guidance

### `{tag}`

Format: `T<n> — <short noun phrase>`. Continue numbering from the library — if T1–T39 exist, the next is T40. The noun phrase describes the *format*, not the content (e.g. "T40 — Lifestyle hero with overlay text", not "T40 — AG1 morning shaker ad").

### **When to use**

Two ideas: brand/audience fit (product category, positioning angle) and which creative angle (credibility, social proof, comparison, sentimental, etc.). Don't list rules; describe the gut fit.

### **Aspect ratio**

Use values from the compatibility table in `prompt-library.md`. If the template only works at one ratio on one model (e.g. `4:5` only on nano-banana), note the mismatch in **Model notes** so the consuming skill can route correctly.

### **Reference image**

Tell the agent what to pass as the brand-fidelity anchor. The more specific the better:
- `"Clean product hero shot, white background, all SKUs visible"`
- `"Lifestyle portrait, subject mid-action, soft daylight"`
- `"Logo wordmark on neutral background"`

Reference images are how brand identity stays faithful. Vague guidance here causes wrong-looking outputs regardless of prompt quality.

### **Variables**

List every `{placeholder}` in the template prompt. For each:
- What the value represents
- Expected type/format (string, hex code, list, short headline)
- Any constraints (max chars, must be one of an enum)

Standard variable names:

| Variable | Use for |
|---|---|
| `{brand.name}` | Wordmark text (literal letters on the packaging) |
| `{brand.color_primary}` | Primary brand color hex (`#RRGGBB`) |
| `{brand.color_accent}` | Secondary accent color hex |
| `{brand.product_image_description}` | One-line description of the product visible in the ad |
| `{brand.tagline}` | Short brand promise (≤6 words) |
| `{brand.competitor_category}` | What the brand is being compared against |
| `{ad.headline}` | Top-line headline |
| `{ad.subcopy}` | Sub-headline / supporting copy |
| `{ad.body}` | Primary text block |
| `{ad.cta_phrase}` | CTA button text |

For template-specific variables, name them clearly (e.g. `{notes_title}`, `{checklist_items[]}`, `{publication}`, `{band_color}`, `{hook_line_1}`).

### **Template prompt**

The actual prompt body, in a fenced code block. Plug-and-play after variable substitution. Always:

1. **Specify aspect ratio at the top** (e.g. `"1:1 static ad creative, 1080x1080, edge-to-edge"`).
2. **Describe the canvas as standalone** — phrases like `"edge-to-edge"`, `"static ad creative"`, `"the standalone image that would be uploaded as a Meta creative"`.
3. **Explicitly exclude chrome** in a closing sentence: `"No surrounding social platform UI: no brand row, no body copy, no engagement counts, no app navigation, no iOS device chrome."` The auto-suffix is a safety net; the prompt itself should also say it.
4. **Describe regions in vertical order** — top X%, middle, bottom Y%.
5. **Name reference roles when multiple refs are expected.** `"The product visible in image_ref[0] should appear at center"` — models do better when references are addressed by index.

### **Model notes**

For each model the template was validated against (gpt-image-2 and/or nano-banana), give a one-line note:
- Known strength: `"renders dense table text cleanly"`
- Known limit: `"tends to add a 3rd Slack message — keep prompt explicit about exactly N"`
- If both render cleanly: `"both: clean"`
- If template only works on one model: say so explicitly and explain why

---

## Hard rules

- **Never silently overwrite an existing entry.** If the new tag collides, ask before replacing.
- **Append, don't reorder.** New templates go at the bottom of the library, before any footer sections. Don't reshuffle existing entries.
- **Keep entries self-contained.** Don't reference other library entries by tag inside a template prompt. Each entry is readable and usable on its own.
- **Validate against the model you intend to ship on.** A T-entry that only renders cleanly on gpt-image-2 should say so in Model notes — don't claim portability you haven't checked.

## Style notes

- Use `*italic*` for terse asides, `**bold**` only for section labels and key callouts.
- Hex codes go in backticks: `` `#1A4731` ``.
- Use em-dashes `—` (not `--`) for parenthetical asides.
- Wrap variables in single backticks: `` `{brand.name}` ``.
- Code-block fences use triple-backtick with no language tag for prompts.
- The horizontal rule between entries is `---` on its own line, separated by blank lines from neighboring content.
