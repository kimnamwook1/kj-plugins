# Doc Body Templates

> Which doc when → [[doc-catalog]] · frontmatter standard & stub rules → [[project-docs-convention]] · tree & naming → [[vault-tree]]

## What this file is

- The **body-section skeletons** for document kinds that have earned one. This is the first such canon (before it, only the frontmatter standard existed — no body templates).
- **Home = here.** A template is a copyable body skeleton, not a separate `.md` on disk. When the scribe creates or fills a stub of a listed kind, it copies the skeleton below into the document body.
- **Frontmatter is not repeated per template** — every document follows the one [[project-docs-convention]] §frontmatter Standard v2; the required keys, shapes, and extensions (multi-instance `id` · optional `history`) live there and only there. Templates below are **body skeletons only** — the former per-template required-key lists left with the v1 deleted fields.

## Scope — only two kinds have a body template

- **DESIGN** and **MILESTONE** only. These are the first (and, for now, the only) kinds with a body skeleton.
- 🔴 **Do not template the other kinds.** A stub pre-filled with empty headings reads as a wall of false facts (empty heading = "there is none"). A kind earns a template only when its body shape is stable and repeated — not preemptively. (The absorbed-section skeletons the 6 pre-created stubs carry are [[doc-catalog]]'s per-row "absorbs" notes, not body templates — a stub still stays H1-only until content arrives.)
- The other kinds stay as a one-line stub until content is written; their structure emerges from [[doc-catalog]] role + [[project-docs-convention]].

## stub rule for templated docs (🔴 read before pre-filling)

- At `status: stub` the body **may** carry the section headings as an empty skeleton — but every section under them stays empty or holds a literal `<!-- TODO -->`.
- **An empty heading means "not yet written", never "none / false".** Never read a blank section as a fact (Core Rule 8).
- **Flip `status: stub` → `draft` the instant any section gains real content.** A stub is "no information" and must never be cited as evidence ([[project-docs-convention]] stub rule).

---

## DESIGN — design-system spec (FRD-grade)

- **Role**: the design-system contract for a UI product — tokens, components, states, interaction rules — **plus links to the SSOT**.
- **SSOT rule → [[project-docs-convention]] §Value Axes, "UI pixels" row — the only original, not restated here.** The pixels/source live at the SSOT; this document holds the **links + the rules the SSOT cannot enforce in prose** (token names, state matrices, interaction invariants). Never paste screenshots as the source of truth — link. This is the **same shape as the API_SPEC repo-mirror pattern** ([[project-docs-convention]] §The Only Exception): the authoritative artifact lives outside the vault; the vault document links and rules, never overrides.
- **Component-confirmation record = 3 layers, one home each**: ① pixels & change history = the SSOT (tool or repo) · ② the confirmed spec = that component's row in §Components + §States & Interactions · ③ the confirmed *why* = the row's Notes + one `history:` line — an ADR when the decision is hard to reverse. 🔴 **No per-component `.md` files** — a second document per component is a second SSOT, and two SSOTs drift.
- **Frontmatter**: §frontmatter Standard v2 ([[project-docs-convention]]) — singleton, so no `id`. Owner routing = the [[doc-catalog]] DESIGN row (a routing label, not a frontmatter field).

```markdown
## Overview
<!-- One paragraph: what product surface this covers, and the design language in one line. -->

## SSOT (design tool or repo)
<!-- Links only. Design tool if one is used; repo component source if code-first (git history = change history). The authoritative pixels/source live there — this doc never overrides them. -->
- Design tool (Figma, Pencil, …): <url>  — or repo component source: <path>
- (component library file, prototype, etc.)

## Design Tokens
<!-- Names + where they resolve, not hardcoded hex scattered in prose. -->
- Color:
- Typography (family · scale · weight):
- Spacing · radius · elevation:

## Components
<!-- Inventory. One row per component with its states. -->
| Component | States | Notes / SSOT link |
|---|---|---|

## States & Interactions
<!-- The rules a static mock can't carry: focus/hover/disabled/loading/error behavior, transitions, motion. -->

## Accessibility & Responsive
<!-- Contrast, focus order, keyboard, breakpoints. -->

## Open questions
<!-- TODO / decisions pending → link ADRs, don't decide here. -->
```

---

## MILESTONE — phased delivery plan ("when what")

- **Role**: the roadmap. Sequences already-defined scope across time. Records **when**, never **what/why** (PRD) or **why-we-decided** (ADR).
- **Boundaries** (owner of overlap — [[doc-catalog]] MILESTONE note): references PRD/FRD scope via wikilinks (never restates it); links ADRs for rationale; leaves fluid task/sprint status to the tracker. This doc is the **durable** plan, not a task mirror. Home = `docs/` root ([[doc-catalog]]).
- **Frontmatter**: §frontmatter Standard v2 ([[project-docs-convention]]) — singleton, so no `id`. Owner routing = the [[doc-catalog]] MILESTONE row (a routing label, not a frontmatter field).

```markdown
## Overview
<!-- What this roadmap covers and the planning horizon. One paragraph. -->

## Milestones
<!-- The durable plan. Scope cells link PRD/FRD; Status points at the tracker, never restates task state. -->
| Milestone | Target | Scope (→ [[PRD]] / [[FRD]]) | Exit criteria | Status (→ tracker) |
|---|---|---|---|---|

## Sequencing rationale
<!-- Why this order. Link ADRs for any hard-to-reverse decision — don't record the decision here. -->

## Dependencies & risks
<!-- Cross-milestone dependencies, external blockers, schedule risks. -->

## Out of scope
<!-- What this roadmap deliberately does not cover (belongs to the tracker or another doc). -->
```
