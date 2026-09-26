# Sigma Protocol refresh — 2026-09-19

Status: LOCAL CHANGES VALIDATED; independent review cleared. Nothing committed, pushed, installed into the operator's global environment, or applied to another project.

Tracking: [DAL-265](https://linear.app/dallion-king/issue/DAL-265/w-protocol-20260919-refresh-sigma-protocol-prompts-frameworks-steps). The user explicitly approved unattended local updates for this run. That approval does not authorize deployment, publishing, spending, or changing other projects.

## Coverage and limits

- All 18 Build Track sources: Steps 0–15, plus conditional 1.5 and 11.5; shared partials, rendered commands and packaged step references.
- 381 unique skill identities: 87 authored skills plus 294 bundled-only skills. The initial bundle had 366; 15 missing authored entries and 25 support files were restored without overwriting existing files.
- Every skill entrypoint was inventoried, metadata-checked and semantically reviewed. The initial focused review covered the prompting, retrofit, technical, commercial and step families; four additional batches covered the remaining 312 skill identities (108,380 source lines). Equal source/bundle copies share the content review. This does **not** independently verify every external claim or package version as current in September 2026. See [COVERAGE.json](COVERAGE.json) for each file's review level and hash.
- 12 authored agent templates and 62 Claude agent/reference files were reviewed. The latter includes a companion reference document; file count is not the number of directly invocable agents.
- Root instructions, README, setup, platform, workflow, path, retrofit-related and runtime documentation were reconciled.
- The 72 Run Track entrypoints (64 steps and 8 orchestrators) were also aligned with the native question contract and validated against their generator.
- Dated dependency snapshots remain historical references. Exact package upgrades and live service behavior must be verified in each consuming project. No source was relabeled current merely by replacing a date.

Baseline: `main` at `651fe48a47d0def670e40da846389f500fff5aa5`. [baseline.json](baseline.json) records existing changes. Thirty-six pre-existing file hashes remained unchanged. The only deliberately changed baseline files were AGENTS.md, CLAUDE.md, and the regenerated Step 4 command; the pre-existing Step 4 source edits were preserved. Three other baseline entries were directories without file hashes.

## Findings and fixes

| ID | Finding | Disposition and evidence |
|---|---|---|
| P01 | Pool sync promoted support Markdown into fake skills and omitted resources | FIXED: real SKILL.md roots, complete support trees, direct-root legacy compatibility; 9 fixture checks |
| P02 | Nested Step 12 include survived rendering while parity passed | FIXED: shared recursive expander, missing/cycle/ambiguous-path errors, full-body parity; 8 fixture checks |
| P03 | Gates named only Claude's question tool | FIXED: native question adapter with ordinary-turn fallback; real answer still required unless explicitly delegated |
| P04 | Repeated stop rules conflicted with unattended approval | FIXED: record run scope once; preserve release/money/destructive boundaries; Claude probes confirmed interpretation |
| P05 | Prompt skill prescribed exposed reasoning transcripts, generic temperature recipes and invented credentials | FIXED: outcome/context/constraints/evidence contract, native tools, measured examples and model-specific settings |
| P06 | Context skill imposed fixed token thresholds and unsafe history assumptions | FIXED: use host pressure signals, preserve constraints/work state, respect provider history contracts |
| P07 | Step 13 described Claude metadata as universal Agent Skills fields | FIXED: portable core separated from host extensions; short descriptions and progressive disclosure |
| P08 | Step 14 embedded one operator's home, harness and permanent model lanes | FIXED: detected runtime and approved task-fit routing; retained deterministic checks, cross-model/coordinator gates and HIGH-RISK operator merge approval |
| P09 | Step 12 treated 32 KiB as a per-file target and could delete user memory files | FIXED: cumulative budget, preserve user policy, no automatic deletion, native import adapter |
| P10 | CLAUDE.md prose pointer did not guarantee shared instructions loaded | FIXED: native @AGENTS.md import plus explicit-read fallback. Root automatic load and nested explicit read passed; nested restricted auto-import did not |
| P11 | README named TASKS.json as the primary handoff | FIXED: TASKS.md primary, JSON optional |
| P12 | Docs conflated authored templates, bundled skills and Claude runtime agents | FIXED: ownership and install surfaces documented; counts come from indexes where practical |
| P13 | Missing CLAUDE.md.example and required external MCP claims | FIXED: active docs/checkers use tracked CLAUDE.md; providers are optional capabilities |
| P14 | Skill catalog omitted bundled-only skills and nested authored categories | FIXED: 381 identities, source precedence, same-pool collision rejection, legacy flat support; catalog fixture |
| P15 | Bundled skill names/descriptions were absent or malformed | FIXED: metadata repaired; both pools validated, including empty/folded descriptions |
| P16 | Global sync validator compared the wrong source hash path | FIXED after independent review; identical files pass, actual drift fails in isolated fixture |
| P17 | Claude clean install omitted bundled-only skills | FIXED: legacy base, bundled pool, then authored source precedence |
| P18 | New installer could overwrite user files or follow linked folders outside target | FIXED after independent review: pre-existing support preservation, same-run overlay precedence, symlink refusal even under force; 17 installer checks |
| P19 | Bundled step skills could shadow Claude commands and invoke themselves | FIXED: Claude and Codex consume valid skill metadata plus bundled references/step.md; actual empty-project Claude probe reached the real contract |
| P20 | Clean index generation assumed ignored .claude/skills directory existed | FIXED: creates output directory; clean fixture covers it |
| P21 | Main installer passed unsupported --yes to Claude installer | FIXED: removed unsupported argument |
| P22 | Three historical authored/bundled content differences persisted | FIXED by clause-aware reconciliation; current mirror report has zero corruption and zero drift |
| P23 | DTCG-compliant example used illegal dotted keys and CSS color strings | FIXED in Step 6 and token skill; structured color/dimension values, type inheritance and correct Community Group status |
| P24 | Accessibility text applied universal penalties and obsolete deadline | FIXED: project/jurisdiction scope; DOJ's extended 2027/2028 dates sourced, automated checks not legal proof |
| P25 | Vitest speed, Cypress replacement and generic framework claims were asserted universally | FIXED: project stack/runner selection and actual evidence, no unsupported performance guarantee |
| P26 | Evolutionary architecture attribution and JTBD methods were conflated | FIXED: Ford/Parsons/Kua attribution; distinguish progress theory, interviews and quantitative ODI |
| P27 | DORA table retained old four-metric/MTTR framing | FIXED: five current delivery measures, deployment rework rate included; reliability separate |
| P28 | Technical skills had stale React/Next configuration and OTel claims | FIXED: React 19.3 stable APIs and reactCompiler key, GenAI schema/version compatibility, privacy preserved; exact upgrades remain project-specific |
| P29 | Commercial skills presented rankings, fictional credentials and universal outcomes as proof | FIXED across 01–23, social and Hormozi: source/date/evidence boundaries, task-specific research and testable hypotheses |
| P30 | Lead scoring still auto-disqualified a price band after Hormozi correction | FIXED after independent review: cohort economics, no price-band-only downgrade |
| P31 | Skills referenced absent helpers, private paths and unsupported retrofit flags | FIXED in targeted prompt/retrofit/research/qualification/authoring skills; no fabricated tool receipts |
| P32 | Agent metadata used unsupported colors, memory:none and embedded writable bypass mode | FIXED: valid colors, omitted disabled persistence, host-controlled permissions; explicit valid model tiers preserved |
| P33 | QA and other agents required absent GitNexus and a frozen review model | FIXED: source-search fallback, detected independent review command; unavailable required reviewer leaves gate open |
| P34 | Seven registry files were allegedly missing | REJECTED: global basename resolver finds them; no duplicate agents created |
| P35 | Fable 5.2 release/capabilities were assumed | UNVERIFIED: official Fable 5.1 and GPT-6 Astra sources found; no invented 5.2 model ID or migration |
| P36 | Linear connector expired | RECOVERED through authenticated Orca integration; task created once |
| P37 | Claude Stop hook could block a valid prose approval pause or unattended run | FIXED: transcript-aware interim/final pauses, direct skill-read fallback and scoped authorization; 30 regression checks cover quoted/fenced text, formatted questions, current command scope and revocations |
| P38 | Shared pass threshold and Step 14 scoring/memory/tool layouts contradicted each other | FIXED: step-specific normalized threshold, 100-point rubric, memory/tool inventories and promotion authority |
| P39 | Partial fragments were indexed as executable commands | FIXED: top-level step sources plus separately authored commands; fixture excludes fragments |
| P40 | next-task selector advertised collision-free claiming without reserving anything | FIXED: truthful read-only selector contract; fleet requires coordinator/atomic reservation |
| P41 | Retention/follow-up/pricing consumers repeated rejected universal Hormozi numerical rules | FIXED: customer cohorts and tested hypotheses; no price-band-only disqualification |
| P42 | All 72 Run Track entrypoints lacked the portable question contract; generator omitted skill names | FIXED: source, generator, command and skill contracts aligned; metadata retained on regeneration |
| P43 | Migration/cleanup recipes used broad staging and reset-hard as recovery | FIXED: owned paths and database-specific rollback evidence; no silent destructive reset |
| P44 | Legal/CRO skills routed to missing resources | FIXED: self-contained bounded workflows and actual installed skill references |
| P45 | Generic tools, private helpers and browser providers were treated as universal | FIXED in affected runtime/workflow skills: capability discovery, explicit gaps and supported fallback |
| P46 | Workflow continuation/validation lagged the active step and handoff contracts | FIXED: TASKS.md primary and canonical Steps 0–15 plus conditional phases |
| P47 | Example security/cost/SaaS artifacts could fabricate live evidence or guarantees | FIXED: explicit illustrative status, scanner/source receipts and no invented product commitments |
| P48 | Bare /docs paths could write to the filesystem root | FIXED in affected artifact read/write recipes; project-root-relative docs paths |
| P49 | Queue acknowledgement assumed unconditional delivery | FIXED: confirmed durable enqueue and provider-specific retry/DLQ/idempotency requirements |

## Research

[Source decisions](SOURCES.md) and [framework review](FRAMEWORKS.md) separate retained methods, changed implementation advice, historical examples and unsupported claims. The review corrected errors in preliminary research before using it: a SNAP testimonial is not its acronym definition, and an ambiguous Vitest blog chronology does not establish a stable release.

Foundational methods were retained where applicable: Hormozi's value framing, C4, Jobs-to-be-Done, Atomic Design, positioning, story mapping, and outcome-led discovery. A practitioner being famous does not make every numerical claim transferable to a project.

## Verification

Full command output and exit codes: [checks/results.json](checks/results.json). Additional installer and mirror-state receipts are in the same directory.

| Suite | Tests / scope | Result |
|---|---:|---|
| bash tests/test_step_partial_expansion.sh | 8 | PASS |
| bash tests/test_sync_skills_to_platforms.sh | 9 | PASS |
| bash tests/test_install_claude_code_skillset.sh | 17 | PASS |
| node tests/test_skill_catalog.mjs | fixture assertions: full pool, nested categories, precedence, empty metadata, sync, collisions, legacy, clean checkout | PASS |
| bash tests/test_validate_mirrors.sh | 14 | PASS |
| bash tests/test_step_skill_gate.sh | 30 | PASS |
| bash tests/test_step_verify_gate.sh | 23 | PASS |
| node --test scripts/tests/test-cascade-registry.mjs scripts/tests/test-ladder-resolution.mjs | 5 | PASS |
| bash tests/test_sigma_upgrade.sh | 6 | PASS |
| bash scripts/audit-platform-parity.sh | all 18 steps and bundled references | PASS |
| node scripts/validate-skills.mjs | 87 authored, 381 bundled, 53 agent references | PASS |
| node scripts/validate-cascade.mjs | department roster/registry/hook routing | PASS |
| node scripts/verify-run-track.mjs --wave=4 | 64 steps + 8 orchestrators, deep scaffolding check | PASS |
| bash scripts/doctor.sh | 8 health gates | PASS |
| shell syntax and git diff --check | touched scripts and working diff | PASS |

The repository's build for these changes is source rendering plus index generation, both run successfully. There is no root application package to build. The upgrade fixture emitted missing-lefthook notices while all six assertions passed; this is not a global hook-installation result.

The mirror checker also reports 174 missing entries across optional local .claude/.codex surfaces. These are not missing bundled files: the .agents pool is complete. Global adapters were intentionally not installed into the user's environment.

## Actual Claude Code checks

Host: Claude Code 2.1.278; responses identify claude-fable-5-1. Tools were constrained to no tools or Read/Grep/Glob, and hooks were disabled for isolated checks.

| Probe | Result |
|---|---|
| Root instruction loading with project settings | PASS: exact backlog paths, approval scope and policy quote |
| Nested restricted automatic import | MISS: pointer visible, shared body absent |
| Nested explicit-read fallback | PASS: read shared AGENTS.md and answered all policy checks |
| Step 11.5 package in an otherwise empty temporary project | PASS: read bundled contract, named TASKS.md and optional JSON, quoted actual gate, identified missing prerequisites |

No-tools probes with every settings source disabled correctly reported UNLOADED; they were diagnostic controls, not protocol acceptance failures. An added-directory flag did not repair nested auto-import. This limitation is documented instead of being presented as a pass. These are bounded behavior probes, not end-to-end execution of all 18 phases or a comparative prompt-quality benchmark.

## Still not certified

- Fable 5.2 availability and behavior.
- Every external framework or version claim across the entire skill corpus; per-file content-review coverage is explicit in COVERAGE.json.
- A full project retrofit, app build, deployment, or all-phase Claude/Codex run in another repository.
- Global installation into the operator's current shared skill environment.

Use the updated local checkout for a scoped retrofit and verify its project-specific prerequisites and runtime receipt. Do not treat this audit as approval to replace user-owned project instructions or upgrade dependencies wholesale.

## Independent review closure

Astra review found and rechecked installer overwrite/precedence/symlink cases, duplicate skill identities, legacy file support, metadata validation, Step 14 gate preservation and lead-qualification consistency. Final verdict: no remaining actionable introduced findings in the reviewed partition. Final targeted installer rerun: `PASS: 17   FAIL: 0`, exit 0.

## Cross-family review follow-through

Claude Fable 5.1 reviewed the runtime changes twice. Its findings led to fixes for the Stop-hook/native-question contract, operator-file preservation, standalone step resources, installed-catalog lookup, per-step thresholds, Step 14 scoring/memory/tool/promotion consistency, command indexing and hook replacement. The second review's remaining transcript edge cases were reproduced and sent through additional fixture checks. These review reports are retained as dated findings; their original open status is superseded by this ledger and later test receipts.

The initial Run Track generator omitted skill names and differed from the authored task-board fallback. Both were aligned without dropping the existing GitHub fallback in projects that do not configure Linear.

Final counted regression assertions: 112 across the eight numbered shell/Node suites, plus the catalog integration fixture and two disposable selector checks. `bash scripts/doctor.sh` returned `All 8 checks green — the install is healthy.` These results concern this local framework checkout, not a deployed product.

Final Astra review: **no remaining actionable findings in the reviewed scope**. The exact fenced-block reproduction now blocks the missing required skill; `bash tests/test_step_skill_gate.sh` returned `RESULT: 30 passed, 0 failed`. No workers remain active.

## Subsequent substantive methodology pass

The user requested a deeper reverse-engineering and framework-source review after this mechanical audit. See [the 91-gate ledger](../methodology-refresh-2026-09-19/GATES.md) and [latest local status](../methodology-refresh-2026-09-19/STATUS.md). The later pass updates step methods and visual-tool flows; this document retains the original pass receipts. Grok-native X research remains access-blocked, and neither pass has been committed or installed globally.
