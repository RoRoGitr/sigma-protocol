# GROK-X-RESEARCH

**Date:** 2026-09-19 (America/Bogota)  
**Cutoff:** 2026-09-19 23:59:59 -05. Later material is labeled outside cutoff.  
**Seat:** Grok 4.6 xhigh; native X tools (`x_keyword_search`, `x_semantic_search`, `x_user_search`, `x_thread_fetch`). Ordinary web used only to verify linked primary repos/docs after an X hit.  
**Scope:** all 18 Build Track stages (0–15 including 1.5 and 11.5), compared to the local 91-gate refresh in `GATES.json` and the four `*-RESEARCH.md` reports.  
**This is not implementation.** `GATES.json` was not edited.

Native X is the discovery lane. Engagement is discovery context, not proof. Release announcements, beta status, methods, heuristics, and vendor claims are marked separately.

---

## Verdict

The local refresh already has the right architecture: keep Hormozi/Dunford/JTBD/Shape Up/Patton/WCAG/DTCG as libraries, keep TasteCode/Pen.dev/Eve/Hermes/OpenClaw optional, keep Designscape unresolved, and do not make any agent protocol mandatory. Native X on 2026-09-19 **confirms** those boundaries and adds a small set of dated corrections — not a new methodology.

The material additions from this lane:

1. **TasteCode public launch is 2026-09-18**, from the two maintainers, with GitHub `0.1.0-beta.7`. Design Agent is still beta. A Codex plugin is **in progress**, not shipped. Do not raise TasteCode to a required Step 5/9 host.
2. **Pen.dev shipped a new agentic canvas on 2026-09-17** (import site → iterate → push to code). Supports the existing Canvas track. Copy-as-HTML exists; SVG export is **planned**, not shipped.
3. **Claude Code v2.1.277 (2026-09-18)** reads `AGENTS.md` only when `CLAUDE.md` is absent. Sigma’s tracked `CLAUDE.md` pointer to `AGENTS.md` is the correct pattern; deleting `CLAUDE.md` would skip Claude-specific surfaces.
4. **ACP v2 remains draft** (Zed, 2026-07-21). MCP 2026-07-28 is a release candidate with a stateless core. A2A 1.0 exists. These are different layers. None should become ordinary-product defaults.
5. **Hormozi has no 2026 replacement book or Value Equation rewrite on his official X.** `$100M Money Models` launch posts are August 2025. 2026 Hormozi posts are recycled clips plus one retention heuristic (2026-03-23).
6. **Designscape is still unresolved as a Sigma design product.** Exact-name X search returns the ET DesignScape architecture/realty summit, not a coding-agent tool.

---

## How this compares to the local refresh

| Existing report | X confirmation | Delta |
|---|---|---|
| `DESIGN-RESEARCH.md` — TasteCode optional early-beta host; Taste Skill portable v2 experimental; Pen.dev canvas; Designscape unresolved | Confirmed by maintainer posts + official repos | Add: 2026-09-18 launch thread, Design Agent **beta**, Codex plugin **WIP**, Pen.dev 2026-09-17 canvas, unpublished “new method” article |
| `COMMERCIAL-RESEARCH.md` — Money Models Aug 2025; Torres CDH still core; Dunford current; Shape Up/Patton retain | Confirmed. Dunford/Cagan bios say they left X | Add: Torres 2026 OST-eval article; Hormozi retention clip is heuristic; no 2026 Hormozi book |
| `ARCHITECTURE-RESEARCH.md` — Eve optional preview; ACP ≠ A2A ≠ MCP; OpenClaw/Hermes not primitives | Confirmed by owner accounts | Add: Eve “one minute” deploy (2026-08-28); ACP v2 draft (Zed); OpenClaw 2026.9.5 (2026-09-19); Hermes plugin catalog (2026-09-16); Vercel Agent Plugins (2026-08-06) |
| `FOUNDATION-RESEARCH.md` — AGENTS.md canonical; skills progressive disclosure; Markdown is not an atomic claim | Confirmed | Add: Claude 2.1.277 AGENTS.md **fallback**, not override; Warp Scorers as optional eval pattern; Linear Agent is a product, not a TASKS.md lock |

---

## Batch findings

### Batch 1 — Steps 0 / 12 / 13 (discovery, context, skills)

**Claude Code now has an official AGENTS.md fallback.** Primary source, not an X rumor:

- GitHub release `v2.1.277`, 2026-09-18 18:06 UTC: <https://github.com/anthropics/claude-code/releases/tag/v2.1.277>
- Quote from the release notes: “Added AGENTS.md support: in a project with no CLAUDE.md, Claude Code reads AGENTS.md instead; change it under Project instructions in `/config` (not yet on Bedrock, Vertex or Foundry).”
- Same release isolates subagent results under a header so child output cannot pass as session instructions.

X commentary on 2026-09-19 Bogota evening (still inside cutoff; timestamps are 2026-09-20 02:48–04:19 UTC = 2026-09-19 21:48–23:19 -05) restates that fallback. Example: <https://x.com/vraj_ai/status/2101519045036265723>. Unattributed “Shopify CEO will ban Claude Code” posts were **not** found on `@tobi`. Treat those as noise.

**Implication for Sigma:** keep `AGENTS.md` as the single instruction surface and keep the thin `CLAUDE.md` pointer. If `CLAUDE.md` exists, Claude Code **does not** auto-read `AGENTS.md`. A pointer file is the interoperability mechanism, not a duplicate policy store. Bedrock/Vertex/Foundry still need `CLAUDE.md`.

**Agent Skills / plugins (methods, not mandates):**

- Vercel official, 2026-08-06: Agent Plugins, “open standard for extending agents. Supports Agent Skills and MCP.” Collaborators named: AWS, VS Code, Cursor, GitHub, OpenAI. <https://x.com/vercel/status/2085398393179005223> → <https://vercel.com/blog/introducing-agent-plugins>
- Practitioner method (not a spec): a skill is not a long prompt; it needs trigger, procedure, references, and a verifiable artifact. <https://x.com/cu30rry_/status/2100755685768417628>
- Warp Scorers (2026-09-17): LLM-as-judge over past agent sessions to improve skills/AGENTS.md. Vendor product. <https://x.com/warpdotdev/status/2100623731294978243> quoted by <https://x.com/BHolmesDev/status/2100685115097587940>
- MCP Skills-extension commentary (2026-09-19) is **not** an official MCP post. Do not graduate it into a required Step 13 output.

**Keep:** progressive disclosure (`name`/`description` first), host-specific fields as adapters, risk-proportional evals instead of a universal 10-prompt/95 score, supply-chain pin/license/checksum.

### Batch 2 — Steps 1 / 1.5 (Hormozi, discovery, positioning, offers)

**Hormozi / Acquisition.com — no new 2026 framework.**

| Kind | Evidence | Call |
|---|---|---|
| Release announcement | `$100M Money Models` live on YouTube, 2025-08-16. <https://x.com/AlexHormozi/status/1956749809865687219> | Last official book launch found. Matches `COMMERCIAL-RESEARCH.md`. |
| Recycled clip / vendor outcome | `@acq_official` 2026-06-08/10 restates Offers pricing and “business of businesses.” <https://x.com/acq_official/status/2063908970528641151> | Not a new method. |
| Heuristic | Retention over acquisition, 2026-03-23. <https://x.com/AlexHormozi/status/2035996696522678300> | Practitioner guidance. Not a churn-curve law. Already flagged in commercial research. |
| Recycled clip | 2026-09 Hormozi timeline is motivation (tradeoffs, courage, “main character armor”). Latest sampled: <https://x.com/AlexHormozi/status/2100951565125435901> (2026-09-18) | Do not treat as Value Equation v2. |

No official Acquisition.com post through cutoff announced a post-Money-Models book or a rewritten Value Equation.

**Torres — method still Continuous Discovery Habits; 2026 adds AI-product evals.**

- 2026 reading group of the 5-year-old book; Chapter 9 still assumption tests, story mapping, pre-mortems. <https://x.com/ttorres/status/2084326935224566030> (2026-08-03)
- 2026-09-16: customer complaint about an AI-generated opportunity-solution tree led to 4 eval metrics and 16 experiment variations. Claim type: **method** for evaluating AI-generated OSTs, not a replacement for interviewing. <https://x.com/ttorres/status/2100273316451721304>
- 2026-05-19: “Teresa Bot,” Vistaly partnership, context engineering / evals as a discovery-engineering habit. <https://x.com/ttorres/status/2056785459917857193>

**Dunford, Cagan, Moesta, Ulwick — no 2026 X method drops.**

| Person | Handle | X status at cutoff | Finding |
|---|---|---|---|
| April Dunford | `@aprildunford` | Bio: “Not active on X - find me on LinkedIn.” Keyword search since 2025: **no results** | Keep *Obviously Awesome* / *Sales Pitch* from official site. X is not a current source. |
| Marty Cagan | `@cagan` | Bio: “I'm no longer active on this platform.” Keyword search since 2025: **no results** | Do not cite 2026 X. |
| Bob Moesta | `@bmoesta` | Latest 2026 post (2026-01-13) is a LinkedIn strategy article, not a JTBD rewrite. JTBD keyword since 2025: **no results** | Switching interviews remain the method. |
| Tony Ulwick | `@Ulwick` | Latest sampled posts are 2023 | ODI remains the quantitative JTBD fork. Do not rank outcomes from a handful of interviews. |

**Keep / revise:** Step 1 still needs job/context/trigger/outcome plus an assumption register. Label Hormozi as heuristic. Do not invent a 2026 Hormozi “Money Models 2.” Add Torres’ OST-eval habit as optional when Step 1 uses AI to draft opportunity trees.

### Batch 3 — Steps 2 / 8 / 11 / 14 / 15 (Eve, Hermes, OpenClaw, protocols, harness)

**Protocols are still three different things.** X in 2026 makes the collision worse, which is why the architecture report’s layer map should stay.

| Acronym | Owner post / spec | What it is | Sigma treatment |
|---|---|---|---|
| **ACP** (Agent Client Protocol) | Zed, 2026-07-21: “ACP v2 is available as a **draft**.” <https://x.com/zeddotdev/status/2079616812505801130>. Zed, 2026-06-10: Xcode, JetBrains, Zed use ACP to talk to agents. <https://x.com/zeddotdev/status/2064818600658010463> | Editor/client ↔ coding-agent session | Optional IDE boundary. **v2 is draft.** Not agent-to-agent. |
| **MCP** | Practitioner discussion of MCP **2026-07-28** RC: stateless core, stronger OAuth. Not an official `@modelcontextprotocol` post in this sample. Security commentary: handle-as-auth is not ownership. <https://x.com/nick_white/status/2100614419814268954> | Model ↔ tools/resources | Use when the project needs tools. Not a default architecture. |
| **A2A** | Spec cited as v1.0.0 at <https://a2a-protocol.org/latest/specification/>. X hits are practitioners, not a 2026 rewrite. | Independently deployed agents | Only for remote agent task exchange. |
| Other “ACP” | <https://x.com/mreferre/status/2100869482033856525> (2026-09-18): “ACP may mean Agent Client Protocol, Agent Communication Protocol, Agent Commerce Protocol.” | Name collision | Always spell **Agent Client Protocol** in gates. |

**Vercel eve — optional durable-agent framework, still not a Next.js replacement.**

- Launch, 2026-06-17: “Introducing eve, an agent framework. Like Next.js, for agents.” <https://x.com/vercel/status/2067180054979936413> → <https://vercel.com/blog/introducing-eve>
- 2026-08-28: “Ship a new eve agent in one minute” from `vercel.com/new/agent` (prompt, models, MCP, deploy). <https://x.com/vercel/status/2093364921073549667>
- Customer story that Ora’s agents “run on eve” is a **vendor outcome claim**.

**Hermes Agent (Nous Research) — active product, vendor claims, not a Sigma primitive.**

- Plugin catalog, 2026-09-16: 4 official + 96 community plugins, reviewed. <https://x.com/NousResearch/status/2100266421020152114> → <https://hermes-agent.nousresearch.com/docs/plugins>
- Business/Enterprise, 2026-09-14. <https://x.com/NousResearch/status/2099599032037388404>
- Refactoring blog, 2026-09-15: “1,393 subagents… 34.4% smaller… nearly $2m.” <https://x.com/NousResearch/status/2099984561451028913> → **vendor outcome claim**, not a method Sigma should copy as a number.

**OpenClaw — rapid external runtime, 2026-09-19 release inside cutoff.**

- `@openclaw` bio: 501(c)(3). Product: personal AI on your machine.
- 2026.9.5, 2026-09-19 03:28 UTC: atomic updates, plugin hot reload, conversation sharing, specialist-agent setup, 4,179 PRs / 502 contributors. <https://x.com/openclaw/status/2101151415301456082> → <https://docs.openclaw.ai/releases/2026.9.5>
- “Death of the Meat Proxy” / Multiplayer Mode (2026-09-18) is a **product feature announcement** (shared sessions, permissions, handoffs). Not a reason to require OpenClaw.

**Keep:** Step 2 agent-runtime applicability (`none` / embedded / internal / independently deployed). Step 14 split coding-host vs product runtime. Step 15 versioned OTel + workflow/task correlation. No X post supplied a new OpenTelemetry GenAI convention that should replace the architecture report’s “version the telemetry vocabulary” item.

**Harness detail worth adopting as a check, not a vendor:** Claude Code 2.1.277’s “subagent results cannot pass as the session’s own instructions.” That is the same class of control as Eve’s “delegation is not an approval boundary.”

### Batch 4 — Steps 3 / 4 / 5 / 6 / 7 (TasteCode, TasteSkill, Pen.dev, Designscape)

Exact-name lookups, as required.

#### TasteCode — official repo <https://github.com/Leonxlnx/tastecode>

**Release announcement (method + beta status):** Leon Lin `@LexnLin`, 2026-09-18 07:00 UTC. Thread: <https://x.com/LexnLin/status/2100842256630534283>

- TasteSkill was the portable frontend-skill product.
- TasteCode is a **desktop app for coding agents** with Design Mode.
- Open source; uses existing AI subscriptions.
- Thread details: Codex + Claude Code + Grok in one workspace; terminal, browser preview, diffs, checkpoints.
- Public beta: **Windows and macOS Apple Silicon**. “Still early.”
- Download/releases linked: <https://github.com/Leonxlnx/tastecode/releases>
- Product Hunt launch the same day.

Co-maintainer `@blueemi99` parallel launch: <https://x.com/blueemi99/status/2100842260455981535> — “open-source ADE,” Design Agent, Codex/Claude/Grok, no extra cost. GitHub: <https://github.com/Leonxlnx/tastecode>. Product Hunt Astra Challenge submission.

GitHub README (verified after the X hit): **early beta `0.1.0-beta.7`**. Local-first security. Provider capabilities differ; unavailable controls are hidden. Design Agent docs exist at `docs/DESIGN-AGENT.md`. Apache-2.0.

**Limits (do not wash these out):**

| Claim | Kind | Evidence |
|---|---|---|
| Design Agent one-shot websites | Vendor demo / beta | `@blueemi99` 2026-09-18: “This website was made with Astra using TasteCode Design Agent, one-shot… still a beta version.” <https://x.com/blueemi99/status/2100842261177336092>. `@LexnLin` 2026-09-19 21:56 UTC (19:56 -05, inside cutoff): Astra medium + Design Agent coffee-shop site. <https://x.com/LexnLin/status/2101430146238484731> |
| Codex plugin | In progress, not shipped | `@LexnLin` 2026-09-19 15:56 UTC: “we are also working on a tastecode codex plugin.” <https://x.com/LexnLin/status/2101339660546916703> |
| 100 GitHub stars / Product Hunt | Launch metric, not quality | `@LexnLin` 2026-09-18 15:01 UTC. <https://x.com/LexnLin/status/2100963356689547669> |
| “New method… 100% free, opensource” for frontier-model frontends | **Unpublished** | Promised 2026-09-08 <https://x.com/LexnLin/status/2097348843201343941>; still “will do a more detailed post/article on that soon” on 2026-09-18 <https://x.com/LexnLin/status/2100852504430862412>. Do not add a gate for an unpublished method. |
| Extra providers (Pi, OpenCode, Cursor, Devin…) | Poll, not a release | `@blueemi99` 2026-09-18. <https://x.com/blueemi99/status/2101004607908389272> |

`@_TasteSkill` is the product account (695 followers). It did not carry the launch thread; the maintainers did.

#### TasteSkill — official repo <https://github.com/Leonxlnx/taste-skill>

Portable Agent Skills. Default install `design-taste-frontend` is **v2 experimental**. v1 preserved. `gpt-taste` for GPT/Codex. Install via `npx skills add`. MIT. Matches `DESIGN-RESEARCH.md` and the local pin note (upstream e79ca9ec… on 2026-09-16).

X does not replace that pin. Do not float an unpinned “always latest v2” into Step 3 DNA.

#### Pen.dev — `@pendev` / founder `@tomkrcha`

**Release announcement:** Tom Krcha, 2026-09-17 13:00 UTC. <https://x.com/tomkrcha/status/2100570466692071493>

> Introducing the new https://www.pen.dev/ an agentic canvas for building bold ideas. Never start from scratch. Import any website or webapp to the canvas, iterate, and push back to code. Update or download today.

Follow-ups inside cutoff:

- WebMCP exists on `https://app.pen.dev/new` (2026-09-18). <https://x.com/tomkrcha/status/2101095185514131589>
- Copy as HTML “does a decent job today” for web; **separate SVG pipeline is planned**. <https://x.com/pendev/status/2097515646401798423> (2026-09-09)
- Large-canvas performance work (10k+ photos) is an engineering claim, 2026-09-09.

This supports DESIGN-RESEARCH’s Canvas track. It does not make Pen.dev the only visual-first tool.

#### Designscape — unresolved

Exact-name native X search (`Designscape OR "design scape" OR DesignScape`, Latest, limit 10) returned **only** ET DesignScape Summit & Awards 2026 (Indian built-environment conference, Gurugram, 30 September). Example: <https://x.com/Realty_Et/status/2100869313238593634> → <https://realty.economictimes.indiatimes.com/designscape>

Semantic search for “Designscape AI design tool” did **not** surface a coding-agent product of that name. Hits were DESIGN.md collections, generic design-agent pitches, and unrelated tools.

Do not substitute Flint, Awesome-design-md, Taste Labs, Claude Design, or Stitch. Keep the name unresolved until a canonical URL is supplied.

### Batch 5 — Step 9 (landing page, customer language, conversion)

No new conversion law appeared on X.

- **Joanna Wiebe `@copyhackers`:** 2026 posts are role-and-AI commentary (innovate your role; AI replacing tasks). Latest sampled 2026-09-17. No new MECLABS-style formula. Keyword search for landing/VOC since 2025 returned nothing; a bare `from:copyhackers` did.
- **Peep Laja `@peeplaja`:** Wynter still sold as ICP/message-research infrastructure. 2026-09-10: “Any company can get data for original research in under 48h using Wynter.” **Vendor claim.** 2026-08-21 joke about waiting on message-test results confirms the product still is message testing. <https://x.com/peeplaja/status/2090849875864817788>
- Pen.dev import-any-website + Copy as HTML is a **design-to-render** path, not a message-evidence path. Keep Step 9’s message/hypothesis gate **before** visual direction.

**Keep:** one primary action, VOC with provenance, no fabricated diary quotes, formulas as heuristics, rendered proof for PASS.

### Batch 6 — Steps 10 / 11.5 (shaping, story mapping, handoff, reservation)

- **Jeff Patton `@jeffpatton`:** 2025-11-13 still teaching story mapping in a product-operating-model class. <https://x.com/jeffpatton/status/1989016764794171539>. No 2026 replacement method found.
- **Ryan Singer / Shape Up:** `from:ryansinger` returned **no results** in this seat. Absence of X posts is not a new Shape Up edition. Keep Basecamp primary text.
- **Linear `@linear`:** 2026 agent features (draft projects, custom environments, browser use) are **product announcements**, not a protocol for Markdown queue reservation. <https://x.com/linear/status/2097329426388205943>
- **Reservation semantics:** no owner post showed that a Markdown file is an atomic claim. Practitioner notes that match the foundation report: reserve before assign; one write-only status row; branch-and-merge / worktree as isolation — all **leads**, not Sigma primitives. Example: <https://x.com/CLEMENTAIEXPERT/status/2101024071618117809>

**Keep:** appetite as time budget; INVEST as checklist; TASKS.md as queue; **selection ≠ reservation**; `QUEUE_ONLY` unless a coordinator/lock/tracker claim exists.

---

## Gate-level recommendations

Only concrete keep/revise/reject items. Do not edit `GATES.json` from this file.

| Gate ID(s) | Current method | Source | What changed | Keep / revise / reject | Acceptance evidence |
|---|---|---|---|---|---|
| `0-environment-setup.gate-1` | Sigma runtime-health on canonical surfaces | Claude Code v2.1.277 release 2026-09-18 | Host instruction files now differ by presence of `CLAUDE.md` vs `AGENTS.md` | **Revise** (already proposed as project baseline; add host-file probe) | Record which instruction files exist, which host loaded them, and the Claude fallback rule. Dirty checkout and HEAD as already required. |
| `0-environment-setup.gate-2` | Research stack full/reduced/blocked | TasteCode + Pen.dev maintainer posts 2026-09-17/18 | Optional design hosts are real and beta | **Revise** | Source-quality matrix includes Pen.dev / Taste Skill / TasteCode **only if present**. Missing tool → reduced, not blocked. No vendor is required. |
| `1-ideation.gate-1` | JTBD + Hormozi + Torres | Torres 2026-09-16 OST-eval post; Hormozi 2026 clips | AI-drafted opportunity trees need evals; Hormozi X is not a new framework | **Keep, revise** | Locked job/context/trigger/outcome; assumption register; if an OST was model-generated, record eval/repair. Do not cite 2026 Hormozi clips as discovery method. |
| `1-ideation.gate-4` / value proposition | Hormozi Value Equation | No 2026 rewrite on `@AlexHormozi` | Equation remains a heuristic | **Keep** | Each term has proof or is labeled heuristic. Money Models stays the 2025 book, not a 2026 sequel. |
| `1.5-offer-architecture.gate-1`–`gate-3` | Hormozi Offers/Leads/Money Models; Dunford | Money Models launch posts Aug 2025; Dunford inactive on X | No later official Hormozi book found on X | **Keep** | Dated source IDs. Price bands remain hypotheses. Dunford sourced from books/site, not X. |
| `2-architecture.gate-2` / `gate-4` | C4 + “Agentic Overlay” | Eve launch; ACP v2 draft; MCP/A2A distinction; OpenClaw 2026.9.5 | Overlay still sounds mandatory | **Revise** (already in architecture research) | Applicability decision `none\|embedded\|internal\|independent`. Protocol map spells **Agent Client Protocol** vs MCP vs A2A. Eve/Hermes/OpenClaw only with version, preview/beta, and exit criteria. |
| `5-wireframe-prototypes.gate-1` | Track select; Claude Design historically default | TasteCode launch thread; Pen.dev 2026-09-17 | Visual-first tools multiplied; all optional | **Revise** | Operator selects Direct / Canvas (Pen.dev or other) / Taste-assisted. TasteCode is an **optional host**, beta `0.1.0-beta.7`, Windows/macOS Apple Silicon. Not a required artifact format. |
| `5-wireframe-prototypes.gate-3` / `gate-4` | Per-flow visual approval | Design Agent still beta; one-shot demos are vendor claims | Do not treat a Design Agent MP4 as review evidence | **Keep, sharpen** | Human approval + committed artifact + tool/model/auth metadata. Demo videos are not acceptance. |
| `6-design-system.*` / `7-interface-states.*` | DTCG + WCAG; Claude Design import | No X source displaced DTCG 2025.10 or WCAG 2.2 | — | **Keep** | Token file + rendered components; WCAG criteria IDs. Visual import is artifact-neutral. |
| `8-technical-spec.gate-1` | Visual source detection | Pen.dev / TasteCode now named hosts | Claude Design must not be the only Track A | **Revise** | Visual-source registry: path, tool, version/date, viewports, approval. Tool is not a runtime dependency. |
| `9-landing-page.gate-3` | Copy system; 5-second / MECLABS | Copyhackers/Wynter X: no new law; Wynter is vendor research | — | **Keep, revise** | Message hierarchy + claim/proof + experiment plan. Formulas stay heuristics. Wynter/equivalent allowed; no fabricated VOC. |
| `9-landing-page.gate-4` / `gate-5` | Creative direction + template | Pen.dev canvas + TasteCode Design Agent | Rendering tools are not conversion evidence | **Revise** | Message gate before visual. Record tool, export (HTML exists; SVG planned), human approval. |
| `10-feature-breakdown.gate-1`–`gate-3` | Patton + Shape Up + INVEST | Patton still teaching story maps; no Singer X | — | **Keep** | Appetite is a time budget. Opportunity-to-slice trace. No new shaping framework from X. |
| `11-prd-generation.gate-2` | Executable PRD + independent verifier | Claude 2.1.277 subagent-output isolation; Eve typed children | Agent features need side-effect evals | **Keep, revise** | Pin model/tool versions. Verifier can be deterministic. Child output must be schema-bounded so it cannot become policy. |
| `11.5-task-handoff.gate-1`–`gate-3` | TASKS.md queue; selection ≠ claim | Linear Agent features ≠ Markdown lock; practitioner collision posts | — | **Keep, revise** | PASS only with a demonstrated reservation (tracker/lock/coordinator) **or** explicit `QUEUE_ONLY`. Do not advertise overnight autonomy from Markdown. |
| `12-context-engine.gate-1` / `gate-3` / `gate-5` | AGENTS.md synthesis; CLAUDE.md pointer | Claude Code v2.1.277 | Fallback is **only** when `CLAUDE.md` is missing | **Keep pointer; revise probe** | Fresh-session receipts: Claude with pointer file; Claude without `CLAUDE.md`; Codex; note Bedrock/Vertex/Foundry gap. Do not delete `CLAUDE.md`. |
| `13-skillpack-generator.gate-2` / `gate-4` | TDD-for-skills; portable SKILL.md | Vercel Agent Plugins; Warp Scorers; Taste Skill v2 experimental | Eval products exist; none is mandatory | **Keep, revise** | `skills-ref`/host validator; pin + license; risk-proportional evals. Optional plugin standard. Taste Skill remains a pinned adapter, not DNA. |
| `14-agent-runtime-bootstrap.gate-1`–`gate-3` | Host detect; Magentic patterns; MAESTRO | Eve/Hermes/OpenClaw/ACP v2 draft | Coding host ≠ product runtime | **Revise** | Manifest: host, task primitive, approval at effect boundary, typed child results. ACP/MCP/A2A recorded only when applicable. OpenClaw/Hermes/Eve optional with threat review. |
| `15-observability-contract.gate-1` / `gate-2` | Per-feature contracts; OTel | No owner OTel rewrite on X this window | — | **Keep** | Versioned GenAI conventions; workflow/task/agent correlation; eval telemetry ≠ production traces. |

### Stay unchanged (counterevidence)

- HITL one-gate-per-phase and “silence ≠ yes.”
- Hormozi Value Equation as a **heuristic**, Money Models as the 2025 third book.
- Dunford five-component positioning (X is not where she publishes now).
- Shape Up appetite; Patton story mapping.
- WCAG 2.2 as conformance target; DTCG 2025.10 as token interchange.
- Designscape **unresolved** — do not invent a product.
- No mandatory Eve, Hermes, OpenClaw, ACP, MCP, A2A, TasteCode, or Pen.dev for ordinary products.
- Local `design-taste` remains a Sigma adaptation of a pinned Taste Skill commit, not a live-at-HEAD install.
- Unpublished LexnLin “new frontend method” article — not a gate.

### Explicitly reject as gate inputs

- Hormozi 2026 motivational clips as methodology updates.
- TasteCode Design Agent one-shot videos as conversion or visual-acceptance proof.
- Hermes “$2m engineering hours” / “1,393 subagents” as a required orchestration pattern.
- OpenClaw PR/contributor counts as production-readiness.
- Wynter “48h original research” as a guaranteed lift.
- Unattributed “Shopify will ban Claude Code” posts (`from:tobi` returned no AGENTS.md hits).
- ET DesignScape Summit as a Sigma design dependency.
- Any third expansion of the acronym ACP without spelling Agent Client Protocol.

---

## Coverage of all 18 stages

| Stage | Native X coverage | Disposition vs local refresh |
|---|---|---|
| 0 Environment setup | AGENTS.md host behavior; optional design-tool discovery | Revise probes; keep Sigma bootloader |
| 1 Ideation | Hormozi, Torres, Moesta/Ulwick/Cagan handles | Keep methods; no 2026 Hormozi rewrite |
| 1.5 Offer architecture | Money Models 2025 launch still last book; Dunford off X | Keep; date the sources |
| 2 Architecture | Eve, ACP/MCP/A2A, OpenClaw, Hermes | Revise applicability/protocol map (already planned) |
| 3 UX Design | Taste Skill v2; TasteCode not a UX method | Keep DNA; Taste as instruction layer |
| 4 Flow Tree | No displacing method on X | Keep |
| 5 Wireframe prototypes | TasteCode launch; Pen.dev canvas | Revise tool-neutral tracks |
| 6 Design system | No DTCG displacement | Keep |
| 7 Interface states | No WCAG displacement | Keep |
| 8 Technical spec | Eve/MCP; visual-source registry | Revise visual source; keep stack conditional |
| 9 Landing page | Copyhackers/Wynter/Pen.dev | Keep message-first; tool-neutral render |
| 10 Feature breakdown | Patton; no Shape Up X | Keep |
| 11 PRD generation | Subagent isolation; evals | Keep verifier; extend agent evals |
| 11.5 Task handoff | Linear Agent ≠ Markdown lock | Keep QUEUE_ONLY vs reservation |
| 12 Context engine | Claude 2.1.277 AGENTS.md fallback | Keep pointer; revise host probe |
| 13 Skillpack | Agent Plugins; Scorers; Taste Skill pin | Keep portable core; pin supply chain |
| 14 Runtime bootstrap | Eve/Hermes/OpenClaw/ACP v2 draft | Keep optional; split host vs product |
| 15 Observability | No owner OTel rewrite in this X window | Keep versioned contracts |

---

## Unsearched or unresolved

- **Designscape identity** — still unresolved after exact-name native X + semantic search. Academic DesignScape and EU Designscapes remain the only documented namesakes in prior research; X added only the ET realty summit.
- **LexnLin unpublished frontend method / article** — promised, not posted by cutoff.
- **TasteCode Codex plugin** — announced as in progress; no release post.
- **Official `@modelcontextprotocol` account posts** for the 2026-07-28 RC — this seat used practitioner X plus the architecture report’s primary spec links, not an owner tweet.
- **Ryan Singer / Basecamp 2026 Shape Up X** — handle search returned no posts; primary text remains Basecamp.
- **April Dunford and Marty Cagan 2026 work** — they are not publishing on X; LinkedIn/site were out of this native-X mandate except as already captured in `COMMERCIAL-RESEARCH.md`.
- **OpenTelemetry GenAI convention version bumps** — no owner X post found in this window that should change Step 15 beyond “version the vocabulary.”
- **Numeric conversion guarantees, churn curves, and “$2m saved” claims** — left as vendor/practitioner claims.
- **Bedrock/Vertex/Foundry AGENTS.md behavior** — official changelog says not yet; not re-probed live in this seat.
- **TasteCode in-app update path / unsigned Windows SmartScreen** — documented on GitHub README, not independently executed here.

Posts after 2026-09-19 23:59:59 -05 would be outside cutoff. None of the owner launch posts relied on here fall outside. Some AGENTS.md commentary tweets carry 2026-09-20 02:48–04:19 UTC timestamps; those are still 2026-09-19 evening Bogota and were used only as discovery pointers to the 2026-09-18 GitHub release.

---

## Native X search log (abridged)

Every row is a live Grok native X call unless marked web-verify. Full query text, tool, and result class:

| # | Tool | Query / id | Window / mode | Result class |
|---|---|---|---|---|
| 1 | `x_keyword_search` | `from:LexnLin TasteCode` | Latest | 3 maintainer posts 18–19 Sep 2026 |
| 2 | `x_user_search` | `LexnLin` | — | `@LexnLin` Leon Lin |
| 3 | `x_user_search` | `blueemi99` | — | `@blueemi99` bluedev |
| 4 | `x_user_search` | `TasteSkill` | — | `@_TasteSkill` |
| 5 | `x_user_search` | `pen.dev` | — | `@pendev` |
| 6 | `x_keyword_search` | `from:AlexHormozi since:2026-01-01` | Latest | Recycled clips, no new book |
| 7 | `x_keyword_search` | `from:AcquisitionCom OR from:acquisition.com "$100M" OR "Money Models" since:2025-08-01` | Latest | `@acq_official` restates Offers; Money Models not re-launched |
| 8 | `x_keyword_search` | `from:ttorres ("continuous discovery" OR "opportunity solution" OR "assumption test") since:2025-01-01` | Latest | CDH reading group + OST evals |
| 9 | `x_keyword_search` | `from:aprildunford (positioning OR "Obviously Awesome" OR "Sales Pitch") since:2025-01-01` | Latest | **No results** |
| 10 | `x_keyword_search` | `from:cagan (discovery OR "product discovery" OR "continuous discovery") since:2025-01-01` | Latest | **No results** |
| 11 | `x_keyword_search` | `from:LexnLin (TasteSkill OR "taste skill" OR tasteskill)` | Latest | Launch thread + unpublished-method promise |
| 12 | `x_keyword_search` | `from:_TasteSkill` | Latest | Product account, not the launch thread |
| 13 | `x_keyword_search` | `from:blueemi99 (TasteCode OR TasteSkill OR tasteskill OR tastecode)` | Latest | Co-maintainer launch + Design Agent beta |
| 14 | `x_keyword_search` | `from:pendev` | Latest | Canvas launch + HTML export notes |
| 15 | `x_keyword_search` | `Designscape OR "design scape" OR DesignScape` | Latest | ET DesignScape Summit only |
| 16–25 | `x_user_search` | Dunford, Cagan, Moesta, Ulwick, Krcha, Copyhackers, Laja, Patton, OpenClaw, Hermes Agent | — | Handles + bios (Dunford/Cagan inactive) |
| 26 | `x_keyword_search` | `from:bmoesta (JTBD OR switching OR "jobs to be done") since:2025-01-01` | Latest | **No results** |
| 27 | `x_keyword_search` | `from:Ulwick (JTBD OR ODI OR "jobs to be done") since:2025-01-01` | Latest | **No results** |
| 28 | `x_keyword_search` | `from:copyhackers (landing OR message OR VOC OR "voice of customer") since:2025-01-01` | Latest | **No results** |
| 29 | `x_keyword_search` | `from:peeplaja (Wynter OR "message test" OR landing) since:2025-01-01` | Latest | Vendor research claims |
| 30 | `x_keyword_search` | `from:jeffpatton ("story map" OR "story mapping" OR shaping) since:2025-01-01` | Latest | 2025 class still teaching maps |
| 31 | `x_keyword_search` | `from:tomkrcha (pen.dev OR pendev OR canvas) since:2026-08-01` | Latest | 2026-09-17 launch |
| 32 | `x_keyword_search` | `from:AlexHormozi ("Money Models" OR "Value Equation" OR "Grand Slam" OR "$100M Offers") since:2025-08-01` | Latest | Aug 2025 launch only |
| 33 | `x_keyword_search` | `from:openclaw` | Latest | 2026.9.5 + multiplayer |
| 34 | `x_keyword_search` | `from:vercel (Eve OR "introducing eve" OR "durable agent") since:2026-01-01` | Latest | Eve launch + one-minute ship |
| 35 | `x_keyword_search` | `("Agent Client Protocol" OR "ACP v2" OR agentclientprotocol) since:2026-01-01` | Latest | Zed draft v2; name collision |
| 36 | `x_keyword_search` | `from:copyhackers` | Latest | AI-role clips, no new formula |
| 37 | `x_keyword_search` | `from:bmoesta` | Latest | Jan 2026 LinkedIn, not JTBD rewrite |
| 38 | `x_keyword_search` | `from:Ulwick` | Latest | 2023 last sampled |
| 39 | `x_keyword_search` | `from:NousResearch (Hermes OR "Hermes Agent") since:2026-01-01` | Latest | Plugin catalog + vendor refactor claim |
| 40 | `x_keyword_search` | `("Agent Skills" OR agentskills) (SKILL.md OR specification) since:2026-01-01` | Latest | Practitioner skill-authoring; Warp Scorers |
| 41 | `x_keyword_search` | `("context engineering" OR AGENTS.md) (skills OR Claude OR Codex) since:2026-06-01` | Latest | Claude AGENTS.md commentary (cutoff-edge UTC) |
| 42 | `x_keyword_search` | `from:vercel A2A OR MCP OR "agent protocol" since:2026-01-01` | Latest | Eve MCP + Agent Plugins |
| 43 | `x_keyword_search` | `from:ryansinger ("Shape Up" OR appetite OR shaping) since:2025-01-01` | Latest | **No results** |
| 44 | `x_keyword_search` | `(task reservation OR "claim task" OR "TASKS.md" OR "agent handoff") (Linear OR worktree) since:2026-01-01` | Latest | Practitioner isolation notes |
| 45 | `x_semantic_search` | TasteCode desktop app Design Mode TasteSkill Leon Lin launch | 2026-08-01 → 2026-09-19 | Launch thread + Taste Skill star posts |
| 46 | `x_keyword_search` | `("AGENTS.md") (Claude Code OR "claude code") (v2.1.277 OR fallback OR CLAUDE.md) since:2026-09-15` | Latest | Commentary pointing at 2.1.277 |
| 47 | `x_keyword_search` | `from:AnthropicAI OR from:claudeai OR from:ClaudeAI (skills OR AGENTS.md OR "Agent Skills") since:2026-06-01` | Latest | Cowork/Salesforce skills; **no AGENTS.md owner tweet** |
| 48 | `x_keyword_search` | `from:zeddotdev OR from:agentclientprot (ACP OR "Agent Client Protocol") since:2026-01-01` | Latest | ACP v2 draft; registry |
| 49 | `x_keyword_search` | `from:a2aproject OR "A2A protocol" OR "Agent2Agent" (specification OR 1.0) since:2026-01-01` | Latest | Spec citations, not a rewrite |
| 50 | `x_keyword_search` | `from:modelcontextprotocol OR "MCP 2026" OR "MCP release candidate" since:2026-06-01` | Latest | Practitioner RC discussion |
| 51 | `x_keyword_search` | `from:AlexHormozi (retention OR churn) since:2026-03-01 until:2026-04-01` | Latest | 2026-03-23 retention heuristic |
| 52 | `x_keyword_search` | `from:wynter_com OR from:peeplaja ("message test" OR "message testing" OR VOC OR "customer language") since:2026-01-01` | Latest | Message-test product still live |
| 53 | `x_keyword_search` | `from:LexnLin ("new method" OR article OR "frontend designs") since:2026-09-01` | Latest | Method still unpublished |
| 54 | `x_semantic_search` | Designscape AI design tool or design agent product not architecture summit | 2025-01-01 → 2026-09-19 | No canonical Designscape product |
| 55 | `x_thread_fetch` | `2100842256630534283` | — | Full TasteCode launch thread |
| 56 | `x_keyword_search` | `from:alexalbert__ OR from:bcherny OR from:ClaudeCode (AGENTS.md OR "2.1.277") since:2026-09-15` | Latest | **No results** |
| 57 | `x_keyword_search` | `from:tobi (AGENTS.md OR CLAUDE.md) since:2026-09-01` | Latest | **No results** |
| 58 | `x_thread_fetch` | `2100570466692071493` | — | Pen.dev launch |
| 59 | `x_thread_fetch` | `2079616812505801130` | — | ACP v2 draft |
| 60 | `x_thread_fetch` | `2085398393179005223` | — | Vercel Agent Plugins |
| 61 | `web_search` | Claude Code 2.1.277 AGENTS.md changelog | ordinary web verify | GitHub release 2026-09-18 |
| 62 | `web_fetch` | https://github.com/Leonxlnx/tastecode | ordinary web verify | `0.1.0-beta.7`, Design Mode, local-first |
| 63 | `web_fetch` | https://github.com/Leonxlnx/taste-skill | ordinary web verify | v2 experimental default |
| 64 | `x_keyword_search` | `(OpenTelemetry OR "gen_ai" OR "agent traces") (eval OR observability) since:2026-06-01` | Latest | No owner convention bump |
| 65 | `x_keyword_search` | `from:linear (agent OR "task claim" OR reservation OR worktree) since:2026-01-01` | Latest | Agent product features, not queue locks |
| 66 | `x_keyword_search` | `from:ryansinger` | Latest | **No results** |
| 67 | `x_semantic_search` | how coding agents should claim or reserve tasks without colliding in a shared queue | 2026-01-01 → 2026-09-19 | Practitioner reservation/isolation |
| 68 | `web_fetch` | https://github.com/anthropics/claude-code/releases/tag/v2.1.277 | ordinary web verify | Official AGENTS.md fallback text |

Empty-result queries are evidence (inactive authors / no matching posts), not failed tools.

---

## Completion

Native X research for this brief is complete. Reports:

- `docs/audits/methodology-refresh-2026-09-19/GROK-X-ACK.md`
- `docs/audits/methodology-refresh-2026-09-19/GROK-X-RESEARCH.md` (this file)
- `docs/audits/methodology-refresh-2026-09-19/GROK-X-STATUS.md`
