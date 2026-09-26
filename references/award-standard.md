# Award Standard — the shared CRAFT rubric (v1)

**Purpose.** Every Sigma step is held to an *award-grade* bar, and that bar is **scored, not requested**.
This file is the single uniform rubric the `step-verify-gate` (deterministic slice) and the `$holes` /
cross-family judge (semantic slice) apply to every step's output. It exists because the operator kept
hand-injecting "make it award-level" — that instruction is now an enforced gate.

It is versioned here AND referenced from each step's `<verification>` block (a `## CRAFT` table +
`<VERIFY-ASSERT>` lines). Deterministic checks ship first (advisory → blocking per the flip contract);
the semantic checks ride the cross-family judge.

---

## CRAFT score (12–15 pts of each step's 100)

| Dim | What it measures | Tier |
|-----|------------------|------|
| C1 Distinctiveness | No generic tells; the output could only belong to THIS product | deterministic + judge |
| C2 Divergence | Fresh award-tier reference research → 2–3 named directions → operator pick BEFORE build | deterministic (structural) |
| C3 Depth | Every claim cited or labeled assumption; alternatives evaluated (not first-option) | judge |
| C4 Anti-slop language | Zero slop words; concrete over vague; machine-parseable | deterministic + judge |
| C5 Conformance | Output obeys the chosen Design DNA invariants + anti-slop rules (no drift) | deterministic + judge |

**Threshold:** a step fails CRAFT if any **binary-fail** deterministic tell fires, or the judged
dims fall below the step's CRAFT point threshold. Threshold gates the step (advisory until calibrated).

---

## Deterministic anti-slop tells (BINARY FAIL if present) — design steps 3, 5, 6, 7, 9

These are the "AI made it" fingerprints. Their presence in generated design output is an automatic fail
(the `craft_antislop` assertion in `step-verify-gate.cjs` greps for exactly these):

- **Default font:** `font-family: Inter | Roboto | Arial | Helvetica` as the primary face. Use a
  distinctive, characterful pairing derived from the DNA typography invariant.
- **AI-purple:** the violet/indigo palette LLMs default to (`#6d28d9 #7c3aed #8b5cf6 #a855f7 #9333ea
  #7e22ce #6366f1 #818cf8 #a78bfa` and the oklch 270–310 hue band) unless the DNA explicitly chose it.
- **3-equal-cards:** `grid-template-columns: 1fr 1fr 1fr` as the default feature layout.
- **Lorem ipsum / placeholder copy.** Use realistic, product-specific content.
- **Slop CTA / proof copy:** `Get Started`, `Trusted by …`, `Simple, honest pricing`.

(Layout-level tells the deterministic grep can't see reliably — centered-hero + proof-strip + features +
pricing + testimonials as the default page skeleton, round fake numbers like "10,000+ users" — are
scored by the **judge** slice C1c, not this list.)

---

## Divergence-protocol proof (STRUCTURAL) — required before any award-grade design is "done"

The `divergence_proof` assertion checks the evidence that the step did NOT design from memory:

- `docs/design/DNA-REFERENCES.md` exists with **≥3 reference links** and **at least one post-2024 date**
  (fresh, not last year's pattern; sources: Awwwards / Godly / FWA / SiteInspire / Mobbin / Screenlane).
- **2–3 named creative directions** documented (`## Direction …` / "named direction"), each with a
  brand-derived motion metaphor, distinctive type + color story, and a novelty quota.
- An **operator-pick marker** ("Chosen direction:" / "operator pick" / "locked direction") — the human
  chose before the build, not after.

---

## Depth-&-craft (JUDGE) — planning/spec steps 1, 2, 8, 10, 11

Scored by the fresh-context cross-family judge (C1c/C2), never self-attested:

- Every factual claim is **cited** or explicitly **labeled an assumption**.
- **Alternatives were evaluated** — the output is not the first option taken.
- **Zero slop language** (no "leverage / robust / seamless / cutting-edge / delve / dive in").
- **Zero-ambiguity, machine-parseable** — tables/checklists/paths, not prose mush.

---

## How it's wired

- Each step's `<verification>` gets a `## CRAFT (NN pts)` table + a `<VERIFY-ASSERT>` block, e.g. for a
  design step: `craft_antislop <generated-output-glob>` and `divergence_proof docs/design`.
- `step-verify-gate.cjs` derives the deterministic CRAFT result (never self-typed). The judge applies the
  semantic dims against THIS file uniformly.
- Ships **advisory** (reports, doesn't block) until the A5 firing-canary shows clean fires, then flips to
  blocking per the flip contract. Override: `STEP_VERIFY_GATE_OFF=1`.
