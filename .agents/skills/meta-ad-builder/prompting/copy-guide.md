# Meta ad copy guide

How to write the body / title / description copy that `deploy-ad.py` rotates via `TEXT_LIQUIDITY`. These frameworks are distilled from high-volume paid-social accounts. They are *structures*, not scripts — always rewrite for the actual brand, product, and audience in front of you.

## The output shape

`deploy-ad.py --copy-file` reads this JSON:

```json
{
  "bodies":       ["body 1", "body 2", "body 3", "body 4", "body 5"],
  "titles":       ["title 1", "title 2", "title 3", "title 4", "title 5"],
  "descriptions": ["description 1", "description 2", "description 3"]
}
```

**Proven shape: 5 bodies / 5 titles / 3 descriptions.** Meta mixes and matches them per impression via `TEXT_LIQUIDITY`. Give it real variety — five near-identical bodies waste the liquidity.

- **Titles:** short (≈40 chars), headline energy — an eye-catch, not a sentence.
- **Descriptions:** shortest line (≈30–50 chars), a supporting proof point.
- **Bodies:** the primary copy — each one a genuinely different *bet*, not an edit of the others.

## The 5-body framework set

Write one body per angle so the five are genuinely different bets.

### 1. The Reveal / Story

First person, present tense — "here's what just happened." Walk through the concrete sequence of events. Highest-context variant; let it run long. This is the variant that converts people who already have a mild problem awareness.

### 2. The Math / Before-and-After

Quantify the old way vs the new way. Old workflow as a list of timed steps → total; new workflow → total. Numbers do the persuading. Specificity beats adjectives — "$150M in spend", "47 variations in 20 minutes", "430+ members" outperform vague claims.

### 3. The Fresh Hook

An angle nobody else is running. Lead with a pattern-breaking line that reframes the category. Example structure: "[Bold contrarian claim]. [One-line explanation]. [Evidence]." This variant wins on audiences who are bored of the category's standard positioning.

### 4. The Ultra-Short CTA

Tight and punchy. One claim, a few arrow bullets, one call to action. This is the variant that wins on cold traffic and short-attention placements (Reels, Stories). Keep it under 100 words total.

### 5. The Authority / Community

Lead with credibility (years of experience, spend managed, member count, results) and describe what the audience joins or gets access to. Works well when the audience values peer belonging or professional credibility.

### Additional angles (swap in when they fit the offer)

- **Tool-Stack Reveal** — name the exact tools/process, make the mechanism transparent.
- **Mechanism / Curriculum Reveal** — show *how* it works or what's inside (module list, process steps).
- **Objection-Handler** — name the most common doubt directly, then dismantle it.

## Structural conventions

- **Choppy line breaks.** Short lines and frequent paragraph breaks (`\n\n`) — it reads as native social copy, not a press release.
- **Arrow bullets.** Use `→` for feature/benefit lists; it scans fast in-feed.
- **Close with a CTA line.** Every body ends on the action: `Get inside →`, `See the workflow →`, or a comment CTA.
- **Comment CTA for Reels-style placements.** "Comment WORD and I'll send you the link" — match the keyword to the video's spoken CTA if there is one.
- **Specificity beats adjectives.** Concrete numbers and named outcomes, not "amazing results."
- **One offer, one link.** All five bodies point at the same destination URL.

## Modeling on winning copy

When `pull-top-ads.py` output is available, read the `copy` field of the top ads first. Identify *why* each winner works — the hook pattern, the proof points, the CTA style — and carry those patterns into the new variants. Mirror the voice; do not copy the text. New creative + proven copy DNA is the goal.

## Titles and descriptions

**Titles:** five short headlines, each pairing naturally with the offer. Cover different angles: outcome-focused, identity-focused ("Join the …"), and direct CTA ("Comment WORD for the Link").

**Descriptions:** three short supporting lines: a social-proof stat, the mechanism or what's included, and a value framing. Keep them skimmable.

## Compliance notes

If the offer touches credit, employment, housing, or social issues, the ad set and campaign must declare a **Special Ad Category** and targeting is restricted — see `reference/meta-api-cheatsheet.md` §3.4. Copy that makes income or results claims may require disclaimers. Flag this to the user rather than guessing.
