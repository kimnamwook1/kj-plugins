# Doc Body Templates

> Which doc when → [[doc-catalog]] · frontmatter standard & stub rules → [[project-docs-convention]] · tree & naming → [[vault-tree]]

## What this file is

- The **body-section skeletons** for document kinds that have earned one. This is the first such canon (before it, only the frontmatter standard existed — no body templates).
- **Home = here.** A template is a copyable body skeleton, not a separate `.md` on disk. When the scribe creates or fills a stub of a listed kind, it copies the skeleton below into the document body.
- **Frontmatter is not repeated per template** — every document follows the one [[project-docs-convention]] frontmatter standard. Each template lists only its **required frontmatter keys**; the shapes live in that convention.

## Scope — only two kinds have a body template

- **DESIGN** and **MILESTONE** only. These are the first (and, for now, the only) kinds with a body skeleton.
- 🔴 **Do not template the other ~22 kinds.** A stub pre-filled with empty headings reads as a wall of false facts (empty heading = "there is none"). A kind earns a template only when its body shape is stable and repeated — not preemptively.
- The other kinds stay as a one-line stub until content is written; their structure emerges from [[doc-catalog]] role + [[project-docs-convention]].

## stub rule for templated docs (🔴 read before pre-filling)

- At `status: stub` the body **may** carry the section headings as an empty skeleton — but every section under them stays empty or holds a literal `<!-- TODO -->`.
- **An empty heading means "not yet written", never "none / false".** Never read a blank section as a fact (Core Rule 8).
- **Flip `status: stub` → `draft` the instant any section gains real content.** A stub is "no information" and must never be cited as evidence ([[project-docs-convention]] stub rule).

---

## DESIGN — design-system spec (FRD-grade)

- **Role**: the design-system contract for a UI product — tokens, components, states, interaction rules — **plus links to the external SSOT**.
- **External SSOT = Figma / Pencil.** The pixels live there; this document holds the **links + the rules a Figma file cannot enforce in prose** (token names, state matrices, interaction invariants). Never paste screenshots as the source of truth — link.
- **Required frontmatter keys**: `kind: design` · `title` · `project` · `status` · `owner: design` · `updated` · `history`. (Singleton — no `id`. No `scope`/`feature`.)

```markdown
## Overview
<!-- One paragraph: what product surface this covers, and the design language in one line. -->

## External SSOT (source of truth)
<!-- Links only. The authoritative pixels live here — this doc never overrides them. -->
- Figma / Pencil: <url>
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
- **Boundaries** (owner of overlap — [[doc-catalog]] MILESTONE note): references PRD/FRD scope via wikilinks (never restates it); links ADRs for rationale; leaves fluid task/sprint status to the tracker. This doc is the **durable** plan, not a task mirror.
- **Required frontmatter keys**: `kind: milestone` · `title` · `project` · `status` · `owner: pm` · `updated` · `history`. (Singleton — no `id`.)

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
