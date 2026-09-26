# Design workflow evaluation briefs

Use these after changing design guidance or when calibrating a new model/runtime. Run the brief through the active Steps 2–7 and relevant skills. Start each case from its declared state; preserve unrelated user work. A dry reasoning exercise can test prompt interpretation, but visual quality requires an actual rendered output and interaction quality requires exercising it.

Record for each run: date, model/runtime, skill revisions, starting project, reference observations, component feasibility, decisions, output paths, viewport/input modes, visual result, interaction result, and limits. Use PASS / MISS / NOT RUN separately for the two results. Do not turn a screenshot, self-score or task-plan response into a claim that the whole case passed.

## Case 1 — professional planning workspace

**Brief:** Retrofit an existing desktop planning app. Users cannot tell where to start, the interface has too many equally prominent boxes, and the sidebar competes with the work. They request a restrained Linear-like workspace. Retain its data and the ability to inspect the full project map.

**Starting state:** A functioning sidebar, project header, stage list/map switch, inspector and local persistence. No new backend is required.

**Expected process:** Inspect relevant reference workspace states. Record a concrete hierarchy and interaction contract. Verify the existing stack/components. Build the project entry → next-stage action → artifact/review slice before restyling every screen. Keep intentional maps available rather than replacing every view with a table.

**Exercise:** First visit, populated project, empty project, long project title, many stages, narrow window, keyboard navigation, pane reopen and existing saved data.

**Visual PASS evidence:** Actual renders show clear location, lower-emphasis navigation, task-focused content, readable density and an obvious next action consistent with the selected reference. Borders and containers have a stated purpose.

**Interaction PASS evidence:** The next-stage action opens the correct existing stage, selected context survives navigation, map/list controls work and the retrofit preserves saved records.

**Failure examples:** A mandatory gradient or display-font pairing; a new hero section in the work area; unchanged grouping with different colors; claiming visual acceptance from a successful build.

## Case 2 — IDE-style planning composer and model picker

**Brief:** Replace a cramped form-like chat panel with an IDE-style composer. It must use real detected runtime capabilities. One runtime advertises models; another supports only its default; a third is unavailable. Preserve unsent drafts and keep planning separate from execution.

**Starting state:** Existing message storage, send/stop transport and scoped runtime discovery. Model names are supplied by the real host or explicitly labeled fixture.

**Expected process:** Inspect the actual composer and open model menu references. Choose compatible components before implementation. Build one working writing surface with context and nearby controls; use progressive disclosure for diagnostic detail. If a requested dependency cannot be installed, report the constraint and verify an authorized fallback without claiming the package was installed.

**Exercise:** Search by label, no results, clear search, ArrowUp/Down, Home/End, Enter, Escape, outside click, disabled runtime, long model label, failed discovery, project switch while a request is pending, streaming, stop, multiline input, draft retention, resize/expand and subsequent rerender.

**Visual PASS evidence:** Writing is primary; models are readable; keyboard focus is visible independently of the selected-model mark; the menu stays attached to its trigger while filtering and inside the available viewport.

**Interaction PASS evidence:** Disabled or invented models cannot be chosen, actual selection persists for the correct project, closing restores sensible focus, outside dismissal does not steal focus, drafts survive updates, and expanded width survives the next render. A real response is required only when claiming that integration works; simulated data stays labeled.

**Failure examples:** Decorative attachment or microphone controls; hardcoded model availability; invisible keyboard highlight; fallback described as shadcn installation; a panel that snaps back during streaming; tiny clipped composer at narrow width.

## Case 3 — complex operational form

**Brief:** Design a multi-section project setup form for desktop and touch use. Users enter a project name, select an existing folder, choose tools, and review the result. Folder inspection can fail, finish late, or be cancelled. They must be able to save a draft and return.

**Starting state:** Existing validated setup state and bounded read-only inspection. No source writes or external account setup are authorized by filling the form.

**Expected process:** Map entry, next action, dependencies, recovery and completion. Inspect an appropriate form/wizard reference. Prototype input → asynchronous check → recovery → review with realistic content before scaling the component system.

**Exercise:** Required field missing, long text, invalid path, picker cancellation, failed inspection, path changed while inspecting, Back/Next, save-and-close, resume, keyboard-only use, narrow screen and text scaling.

**Visual PASS evidence:** Grouping and hierarchy explain what is needed now; labels and error messages remain readable; advanced configuration does not overwhelm the primary flow; focus is not obscured.

**Interaction PASS evidence:** The original project stays unchanged, late results cannot attach to a different selection, Back/Cancel semantics are explicit, entered values survive recoverable errors, and the final summary matches the saved choices.

**Failure examples:** Every field wrapped in a separate card; data lost on redraw; a cancelled or stale inspection treated as success; tutorial progress treated as approved setup; a fake disabled control used as completion evidence.

## Cross-case regression rules

- The brief, platform and reference contract determine the design; no universal font ban, decorative background or animation requirement.
- A named library is a verified dependency choice, not a quality score.
- Repeated keyboard interactions stay immediate; custom motion needs a purpose and reduced-motion behavior.
- Check the actual render and the actual behavior independently.
- Honor the existing step gates and explicit delegation. Do not add surprise approval stops or invent user acceptance.
- Keep findings actionable with a `Before | After | Why` table and evidence paths.

These briefs are supplied for execution. Their presence does not mean all three have been run or passed.
