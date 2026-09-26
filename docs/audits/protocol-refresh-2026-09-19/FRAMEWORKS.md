# Sigma Protocol Framework Audit — 2026-09-19

Scope: bounded review of named sales, content, technical, accessibility, and observability frameworks. Sources are primary where available. `RETAIN` means the local claim is supported; `UPDATE` means the source or version has moved; `UNVERIFIED` means the local claim is promotional, numerical, or lacks a primary source. This is not a claim that every skill in the repository was exhaustively reviewed.

## Sales

### Jason Forrest / Warrior Selling — UPDATE, evidence boundary

Local claim: [`src/skills/05-sales-strategy/SKILL.md:43-63`](../../../src/skills/05-sales-strategy/SKILL.md) calls Forrest the 2025 #1 trainer and summarizes Warrior Selling. FPG’s official page describes Warrior Selling as a Jason Forrest program and repeats its own ranking and participant outcome claims, but those are vendor claims. Keep the program as an optional persona/framework. Do not present rankings, “500% improvement,” or participant percentages as independent evidence. [FPG Warrior Selling](https://fpg.com/sales-and-management-training/warrior-selling/)

### Jill Konrath / SNAP — RETAIN, narrow scope

Local claim: [`src/skills/05-sales-strategy/SKILL.md:44-75`](../../../src/skills/05-sales-strategy/SKILL.md) uses SNAP for busy B2B buyers. Konrath’s official page focuses on reaching busy buyers and preventing stalled decisions. The wording “Straightforward, No-nonsense, Attuned and Practical” on that page is a testimonial, not the method’s acronym definition. Keep it for B2B messaging and buying friction. The “#1 Best Global Trainers 2025” ranking is not established by the official page and should be marked unverified. [SNAP Selling](https://www.jillkonrath.com/snap-selling)

### Jeremy Miner / NEPQ — RETAIN, evidence boundary

Local claim: [`src/agents/sales/jeremy-miner.md:42-55`](../../../src/agents/sales/jeremy-miner.md) assigns Miner structured discovery and problem awareness. 7th Level’s official methodology supports exploratory questions, meeting buyers where they are, and self-persuasion. Keep the question sequence as a sales technique, but treat “largest B2C / fifth-largest B2B” and “science-based” claims as provider claims, not validated outcomes. [7th Level methodology](https://www.7thlevel.com/our-methodology)

### Chris Voss / Black Swan — RETAIN, separate negotiation from discovery

Local claim: [`src/agents/sales/chris-voss.md:42-55`](../../../src/agents/sales/chris-voss.md) uses labels, mirroring, calibrated questions, no-oriented questions, and Ackerman pricing. Black Swan’s own guides support tactical empathy and calibrated what/how questions. Keep this for negotiation and objection handling after discovery; do not treat it as a universal close-rate law. [Black Swan tactical empathy guide](https://info.blackswanltd.com/hubfs/The%20Black%20Swan%20Group%20Leadership%20Guide.pdf)

### Cole Gordon / Josh Braun — UNVERIFIED as empirical frameworks

Local claims: [`src/agents/sales/cole-gordon.md:44-57`](../../../src/agents/sales/cole-gordon.md) and [`src/agents/sales/josh-braun.md:43-61`](../../../src/agents/sales/josh-braun.md) describe high-ticket team building and cold-outreach diagnosis. Official provider pages establish the existence of Closers.io and Braun’s commercial positioning is not a neutral research standard. Keep both as optional practitioner lenses. Remove or label “8-figure closer,” KPI, belief-ladder, and conversion implications as anecdotal unless the task supplies evidence. No independent primary research was found in this pass.

### Sales strategy composite — UPDATE

Local [`src/skills/05-sales-strategy/SKILL.md:19-31`](../../../src/skills/05-sales-strategy/SKILL.md) instructs agents to search “current 2025” rankings and then treats rankings as a landscape. Replace rankings with a dated source register and evidence labels. Frameworks should answer a specific job: SNAP for busy B2B access, NEPQ for exploratory discovery, Voss for negotiation, and practitioner scripts only when the offer and channel fit.

## Content and social

### Gary Vaynerchuk / Content Pyramid — RETAIN, simplify

The official Content Pyramid describes creating core content and distributing derivative pieces across relevant social platforms: [GaryVee Content Model](https://garyvaynerchuk.com/wp-content/uploads/2018/07/GV-Content-Model-1.pdf). Local [`src/skills/13-content-matrix/SKILL.md`](../../../.agents/skills/13-content-matrix/SKILL.md) can retain the repurposing model. Platform-specific posting frequency, hook formulas, and engagement claims must remain hypotheses because the local skill does not cite current platform evidence.

### Social platform guidance — UPDATE, make time-bounded

Local [`.agents/skills/social-content/SKILL.md:43-106`](../../../.agents/skills/social-content/SKILL.md) gives static LinkedIn, X, Instagram, and TikTok guidance. Platform ranking, formats, APIs, recommendation systems, and disclosure rules change frequently. Keep the goal/audience/voice intake and repurposing table; require a current platform source or observed account evidence before asserting algorithmic best practice. Do not encode “current” platform tactics as durable protocol law.

### Sheila Bella — UNVERIFIED practitioner layer

Local [`src/agents/sales/sheila-bella.md:59-76`](../../../src/agents/sales/sheila-bella.md) and related skills use creator inbound, DM, and pricing language. This can remain a persona layer, but the protocol should label its tactics as practitioner guidance. Avoid universal claims about close rates, “85% of the work,” or psychological effects without a dated source and measurable test.

## Technical frameworks

### React — UPDATE

Local [`src/skills/react/SKILL.md:23-25`](../../../src/skills/react/SKILL.md) anchors React 19.2 and React Compiler 1.0. React 19.3 shipped on 2026-09-09 with stable View Transitions and Fragment Refs: [React 19.3](https://react.dev/blog/2026/09/09/react-19-3). Update the version anchor and re-check API examples. Keep compiler guidance conditional on project configuration rather than assuming every app enables it.

### Next.js — UPDATE

Local React skill references Next.js 16 Cache Components. The official Next.js archive reports 16.3.3 as Active LTS on 2026-08-25, and 16.3 adds instant navigation, partial prefetching, agent-ready docs, and browser diagnostics: [Next.js releases](https://nextjs.org/blog). Update version/security checks and make “latest” resolution runtime-driven. Do not hardcode a release number in a long-lived skill without a refresh date.

### Tailwind — UPDATE

Local [`src/skills/design-tokens/SKILL.md:76-83`](../../../src/skills/design-tokens/SKILL.md) correctly describes Tailwind v4 CSS-first `@theme`. Tailwind’s official blog records v4.3 in May 2026 with additional utilities and scrollbar styling: [Tailwind v4.3](https://tailwindcss.com/blog). Keep CSS-first guidance; add a version check and note that v4.3 features are optional rather than assuming them in every project.

### Vitest / Playwright — UPDATE

The blog listing alone does not resolve a reliable latest stable Vitest version. Check a dated release and the project lockfile before changing the local version anchor: [Vitest blog](https://vitest.dev/blog). Vitest 4 made Browser Mode and Playwright provider support more mature. Playwright’s docs require keeping the package and browsers current: [Playwright browsers](https://playwright.dev/docs/browsers). Audit local testing skills for hardcoded versions and make browser installation/version checks explicit.

### Swift / WWDC26 — UPDATE

Apple’s WWDC26 session documents Swift 6.3 and 6.4 improvements: [What’s new in Swift — WWDC26](https://developer.apple.com/videos/play/wwdc2026/262/). Local [`src/skills/apple-native/SKILL.md`](../../../src/skills/apple-native/SKILL.md) and Swift skills should use project toolchain detection, concurrency checks, and availability annotations rather than implying one universal Swift version. Re-run examples against the project’s Xcode/Swift toolchain before changing APIs.

### OWASP MASVS — RETAIN with version check

OWASP’s official MASVS v2.1 release added MASVS-PRIVACY and CycloneDX support: [MASVS v2.1.0](https://mas.owasp.org/news/2024/01/18/masvs-v210-release--masvs-privacy/). Keep the local mobile security categories, but require the selected MASVS version in each audit. Privacy is an app-test baseline and does not replace GDPR, ENISA, or jurisdictional legal review.

### W3C DTCG — UPDATE source status

Local [`src/skills/design-tokens/SKILL.md:32-36`](../../../src/skills/design-tokens/SKILL.md) calls DTCG 2025.10 stable. This should be verified against the DTCG Community Group’s dated publication and not inferred from secondary token tooling. Keep `$value`, `$type`, aliases, and three-tier token guidance only where the target project actually needs portable tokens. Treat tool-specific claims about Style Dictionary, Terrazzo, Figma, or shadcn as separate compatibility checks.

## Observability

### OpenTelemetry — UPDATE GenAI source and stability handling

Local [`src/skills/observability/SKILL.md:678-748`](../../../src/skills/observability/SKILL.md) uses `gen_ai.*` and a pinned semantic-conventions version. OpenTelemetry moved GenAI conventions to a separate repository and now documents semantic-convention version selection, stable/experimental opt-in, and dual emit: [GenAI conventions](https://opentelemetry.io/docs/specs/semconv/gen-ai/), [version selection](https://opentelemetry.io/docs/specs/semconv/configuration/version-selection/). Update links and require an explicit convention version plus privacy decision before recording prompts, completions, or tool results. Keep token, latency, model, and operation telemetry as opt-in fields with redaction.

## Priority ledger

1. Update React anchor to 19.3 and Next.js to the current Active LTS line; run examples against the project lockfile.
2. Replace sales “2025 expert rankings” with source/date/evidence labels.
3. Mark numerical practitioner claims in Hormozi, Forrest, Miner, Cole Gordon, and Sheila Bella material as unverified unless independently measured.
4. Make social-platform guidance time-bounded and evidence-driven.
5. Add OpenTelemetry GenAI convention migration/version selection and prompt-content privacy gates.
6. Keep C4, WCAG 2.2, MASVS 2.1, Tailwind v4 CSS-first, GaryVee content decomposition, and the core sales heuristics, subject to project-fit and version checks.
