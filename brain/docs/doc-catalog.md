# Doc Catalog — Canonical Source for Document Selection

> **The PM selects documents with this table — per task, and for the project onboarding baseline.** At project onboarding the PM delegates pre-creation of **17 tech-design + 2 business = 19** stubs (**full scaffold**, [[project-docs-convention]]), and their content is filled in as judged by this table.
>
> - **tier = universal (baseline)**: laid down by default for any non-trivial project.
> - **tier = situational**: created only when the trigger actually occurs.
> - Location conventions: project-wide = `docs/` · **per-feature = `docs/feature/<F>/`** (feature lives **under** docs) · reusable knowledge = `knowledge/` · project hub = root `index.md` · shared across all projects = `common/`. (Structure & naming canon: [[vault-tree]])
> - **owner = a PM routing label** — which brief that document's updates ride on. Not a resident agent. The label names a brief — spawn defaults to `worker`; only code-implementation documents get `coder`.
> - **The owner column = the single party responsible for updating that document.** 🔴 **Work is not accepted as complete unless you update the documents you own** ([[project-docs-convention]]).
> - **All documents follow the [[project-docs-convention]] frontmatter standard** — `status: stub|draft|approved|deprecated` · `owner` · `history`. 🔴 **`status: stub` means "no information" — never cite as evidence. The moment it gains content, switch to `draft`.**
> - **ID issuance for multi-instance documents (POL·ADR) = the PM issues in advance** ([[project-docs-convention]]). Workers never pick their own numbers.

## Selection Table

**Project hub**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **Project hub** | `type: project` | pm | root `index.md` | Once at onboarding. **One-line definition + PREFIX + TOC pointers only** — no content prose (index.md pointer principle, [[vault-tree]]) | universal |

**17 tech-design documents** — all pre-created as stubs at project creation ([[project-docs-convention]])

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **PRD** | `prd` | planning | `docs/tech-design/` | When defining product direction & requirements (early in the project). **References BM·GTM via wikilinks** | universal |
| **NFR** | `nfr` | architecture / planning | `docs/tech-design/` | When performance/availability/security targets affect the design | universal |
| **ARCHITECTURE** | `architecture` | architecture | `docs/tech-design/` | When system design begins | universal |
| **ERD** | `erd` | backend / architecture | `docs/tech-design/` | When there is persistent data (DB) | universal |
| **API_SPEC** | `api` | content=backend / sync=scribe (dreaming) | `docs/tech-design/` | When exposing an API/service boundary. ⚠️ **Read-only mirror — SSOT is the repo spec** ([[project-docs-convention]]) | universal |
| **THREAT_MODEL** | `threat-model` | security | `docs/tech-design/` | When handling user data or authentication (mandatory once before launch) | universal |
| **FULL_TEST_PLAN** | `test-plan` | qa | `docs/tech-design/` | When a verification strategy is needed before implementation starts | universal |
| **GLOSSARY** | `glossary` | planning | `docs/tech-design/` | When domain terms become ambiguous (maintained from the start) | universal |
| **CODE_CONVENTION** | `code-convention` | architecture | `docs/tech-design/` | When the stack/language is decided (early in the project). Differs per project, so it is not common | universal |
| **GIT_STRATEGY** | `git-strategy` | devops | `docs/tech-design/` | When a repo comes into existence. Default is trunk-based, but **a project may carve out exceptions**, so it is not common | universal |
| **RUNBOOK** | `runbook` | devops | `docs/tech-design/` | When there is something to deploy | universal |
| **OBSERVABILITY** | `observability` | devops | `docs/tech-design/` | When entering production | situational |
| **COMPLIANCE** | `compliance` | compliance | `docs/tech-design/` | Regulated user data or AI features (regulated/non-trivial projects) | situational |
| **DR** | `dr` | devops | `docs/tech-design/` | When data loss is a business risk (enterprise/prod) | situational |
| **INTEGRATION** | `integration` | backend / architecture | `docs/tech-design/` | When external service integrations appear | situational |
| **DESIGN** | `design` | design | `docs/tech-design/` | When the product has a UI. **Design-system spec — FRD-grade**: design tokens · component inventory · states · interaction rules. **External SSOT = Figma/Pencil; this document holds the links AND the rules** (body template → [[doc-templates]]) | situational |
| **MIGRATION** | `migration` | backend / devops | `docs/tech-design/` | When schema changes or data migrations occur | situational |

**2 business documents** ★new — pre-created as stubs at project creation (17 tech-design + 2 business = **19**)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **BM** | `bm` | **business** | `docs/business/` | When revenue model, cost structure, or unit economics affect product decisions. Referenced by the PRD | universal |
| **GTM** | `gtm` | **marketing** | `docs/business/` | When launch, channel, or positioning decisions are needed. Referenced by the PRD | universal |

**Planning (roadmap)** — **not pre-created** (created on trigger, not part of the 19-stub baseline)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **MILESTONE** | `milestone` | **pm** | `docs/planning/` | When the project needs **phased delivery planning** — sequencing major deliverables/releases across time (the roadmap). Not for a single-shot small tool. Body template → [[doc-templates]] | situational |

> **MILESTONE boundaries (who owns overlap).** MILESTONE = **"when what"** (timing · sequencing of already-defined scope). It never redefines scope and never records decision rationale.
> - **vs PRD** — PRD owns **"what & why"** (product direction/requirements). MILESTONE references PRD/FRD scope via wikilinks; it never restates it.
> - **vs ADR** — ADR owns **"why we decided X"** (a hard-to-reverse decision). MILESTONE links to ADRs for the *why*; it only carries the *when*.
> - **vs the tracker** — the tracker owns the **fluid task/sprint queue** (status changes often, [[project-docs-convention]] §boundaries). MILESTONE owns the **durable phase/release plan** (stable milestones + exit criteria). The tracker executes against the milestone; the milestone never mirrors task status.

**Project norms, decisions, research**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **POLICY (project)** | `policy` | ID issued by `pm` · owner assigned by the rule's domain (document frontmatter) | `docs/policy/<PREFIX>-POL-0000N.md` | When a rule applies to **2 or more features** (`scope: project`) — criteria, ID, promotion canon: [[project-docs-convention]] | situational |
| **ADR** | `adr` | architecture (ID issued by PM) | `docs/adr/<PREFIX>-ADR-0000N.md` | One per hard-to-reverse code/design decision. 🔴 **Never pre-created** | universal |
| **research (folder)** | folder (free-form) | research | `docs/research/` | When research/benchmarking outputs appear | situational |

**Feature documents** — `docs/feature/<F>/`. Stubs created **at feature kickoff on PM instruction** (not pre-created, [[project-docs-convention]])

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **FRD** | `frd` | planning | `docs/feature/<F>/` | When expanding one PRD feature into an executable spec (per feature). **The "what"** | universal |
| **TDC** ★new | `tdc` | **architecture** | `docs/feature/<F>/` | When expanding the FRD into an implementation approach. **The "how"** — see the section below | universal |
| **DATA_FLOW** | `data-flow` | architecture / backend | `docs/feature/<F>/` | When the feature moves data. **Prose goes in the TDC; this holds the diagram** | universal |
| **SEQUENCE** | `sequence` | architecture / backend | `docs/feature/<F>/` | When multiple components interact. **Prose goes in the TDC** | universal |
| **STATE_DIAGRAM** | `state-diagram` | architecture / backend | `docs/feature/<F>/` | 🔴 **Only for features with a real state machine** (login, payment, orders, etc.). Otherwise **keep as stub** | situational |
| **POLICY (feature)** | `policy` | ID issued by `pm` · owner assigned by the rule's domain (document frontmatter) | `docs/feature/<F>/policy/` | When a rule applies **to this feature only** (`scope: feature`) — [[project-docs-convention]] | situational |

**On-demand**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **knowledge note** | `lesson`\|`gotcha`\|`decision`\|`reference` | scribe (via PM Handoff) | `knowledge/` | Whenever knowledge with reuse value emerges (on-demand) | situational |
