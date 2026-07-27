# Doc Catalog — Canonical Source for Document Selection

> **The PM selects documents with this table — per task, and for the project onboarding baseline.** At project onboarding the PM delegates pre-creation of **5 tech-design + 1 business = 6** stubs ([[project-docs-convention]]), and their content is filled in as judged by this table. Former standalone kinds live on as **sections** of the 6 (per-row "absorbs" notes below) — split a section into its own file only when it actually grows heavy, never pre-emptively.
>
> - **Naming = abbreviation + full name, everywhere a document is titled** — this table's Document column and every stub H1: `# PRD (Product Requirements Doc — 제품 요구사항)`.
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

**Tech-design documents** — the 5 marked ★stub are pre-created at project creation ([[project-docs-convention]]); the rest are created on trigger

| Document | kind | owner | Location | When (trigger) · absorbed sections | Tier |
|---|---|---|---|---|---|
| **PRD (Product Requirements Doc — 제품 요구사항)** ★stub | `prd` | planning | `docs/tech-design/` | When defining product direction & requirements (early in the project). **References [[BUSINESS]] (§BM · §GTM) via wikilinks.** Absorbs as sections: **§비기능 요구 (NFR)** — performance/availability/security targets that affect the design · **§용어 (Glossary)** — domain terms, accumulated as they become ambiguous | universal |
| **ARCHITECTURE (시스템 설계)** ★stub | `architecture` | architecture | `docs/tech-design/` | When system design begins. Absorbs as sections: **§데이터 모델 (ERD)** — when there is persistent data · **§외부 연동 (Integrations)** — external service contracts. Split a section into its own file only when it actually grows heavy | universal |
| **API_SPEC (API Specification — repo spec 미러)** | `api` | content=backend / sync=scribe (dreaming) | `docs/tech-design/` | When exposing an API/service boundary. ⚠️ **Read-only mirror — SSOT is the repo spec** ([[project-docs-convention]]). **Not pre-created** — dreaming's api-mirror audit generates it once an API exists (a stub mirror of nothing would be noise) | universal |
| **THREAT_MODEL (위협 모델)** ★stub | `threat-model` | security | `docs/tech-design/` | When handling user data or authentication (mandatory once before launch). **Kept independent** — security/evidence character; never folded into another document | universal |
| **CODE_CONVENTION (코드 규약)** ★stub | `code-convention` | architecture | `docs/tech-design/` | When the stack/language is decided (early in the project). Differs per project, so it is not common. Absorbs as a section: **§테스트 규율 (test discipline)** — project-wide test strategy only; per-feature acceptance criteria belong to each FRD | universal |
| **RUNBOOK (배포·운영 절차)** ★stub | `runbook` | devops | `docs/tech-design/` | When there is something to deploy. Absorbs as sections: **§Delivery** — how a change gets from a branch to the trunk, measured (note below) · **§관측 (Observability)** — on entering production · **§재해 복구 (DR)** — when data loss is a business risk · **§마이그레이션 (Migration)** — schema-change/migration procedures | universal |
| **COMPLIANCE (컴플라이언스 — 규제 대응)** | `compliance` | compliance | `docs/tech-design/` | Regulated user data or AI features (regulated/non-trivial projects) | situational |
| **DESIGN (디자인 시스템 스펙 — FRD급)** | `design` | design | `docs/tech-design/` | When the product has a UI. **Design-system spec — FRD-grade**: design tokens · component inventory · states · interaction rules. **SSOT = the design tool if one is used, else the repo component source (code-first — git history = the change history); this document holds the links AND the rules** (body template → [[doc-templates]]) | situational |

> **RUNBOOK §Delivery (absorbs the former `GIT_STRATEGY` file).** Records this project's delivery bucket (from `/brain:onboard` Q1/Q2) + a git-flow pointer + an exceptions line (default "예외: 없음 — 분류표 준수"), **and the measured values below.**
> 🔴 **The git flow is decided by the vault's delivery classification note** — a classification table mapping **project type → flow**. There is no single org-default flow; org is only where documents live (one org legitimately runs different flows per project type). The note's **path differs per vault**: a binding vault keeps it in `000_common/policies/` (e.g. `DELIVERY_STRATEGY.md`); a vault still stabilizing may keep it in `000_common/facts/` as a non-binding reference and promote it to `policies/` when stable. **Never hardcode the path or restate a flow value — refer to "the vault's delivery classification note" and point** (restate → drift).
>
> **The split that keeps the two from drifting: the vault note holds the *policy*, §Delivery holds *what this repo's remote actually enforces*.** Restating a policy value here is drift; recording a measurement is the entire job — a measurement has no second copy to disagree with, because the repo is its own source. So §Delivery owns, for **this** repo:
> - **The PR/MR gate, as measured** — is a pull/merge request structurally required, how many approvals, which merge methods survive, whether any status check actually blocks the merge, and who may bypass. 🔴 **Read it off the host, never off memory or off the workflow file** — a CI workflow proves what *runs*, not what *blocks*. Record the query used, so the next reader can re-run it. **An absent gate is a finding, not a blank**: write "protection: none (measured `<command>`, `<date>`)" rather than leaving the line out.
> - **Branch naming** — the prefixes this repo's branches actually carry, and whether they are a rule or an observation. The *model* (trunk, short-lived branches, merge style) stays the vault note's; the *names* are local.
> - **Branch cleanup judgment** — how "already merged" is decided, which is squash-dependent and therefore per-repo (`git cherry` patch-equivalence, not SHA ancestry, wherever the merge squashes).
>
> **Agent branch names are not this section's call** — the coder's `<type>/<PREFIX>-<number>-<title-slug>` is harness canon (`agents/coder.md` §First action) and applies in every repo the harness runs in. `<type>` is the shared type vocabulary (canon: `docs/git-convention.md` — **never restated here**). §Delivery records the *human* convention alongside it when one exists. **A repo whose humans use type-shaped prefixes too does not merge the two** — the agent format is fixed by the harness, the human one is a measurement, and they coexist unreconciled.

**1 business document** — pre-created as a stub at project creation (5 tech-design + 1 business = **6**)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **BUSINESS (사업 — BM·GTM 통합)** ★stub | `business` | **business** | `docs/business/` | One file, two sections. **§BM (Business Model — 수익 모델)** — when revenue model, cost structure, or unit economics affect product decisions · **§GTM (Go-To-Market — 진입 전략)** — when launch, channel, or positioning decisions are needed. Referenced by the PRD | universal |

**Planning (roadmap)** — **not pre-created** (created on trigger, not part of the 6-stub baseline)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **MILESTONE (마일스톤 — 단계별 딜리버리 로드맵)** | `milestone` | **pm** | `docs/` (root) | When the project needs **phased delivery planning** — sequencing major deliverables/releases across time (the roadmap). Not for a single-shot small tool. Body template → [[doc-templates]] | situational |

> **MILESTONE home = `docs/` root.** The former `docs/planning/` folder is removed (a folder for one file was over-design — KJP-17 partially reversed). Create a `planning/` folder only when a **second** planning document actually appears.

> **MILESTONE boundaries (who owns overlap).** MILESTONE = **"when what"** (timing · sequencing of already-defined scope). It never redefines scope and never records decision rationale.
> - **vs PRD** — PRD owns **"what & why"** (product direction/requirements). MILESTONE references PRD/FRD scope via wikilinks; it never restates it.
> - **vs ADR** — ADR owns **"why we decided X"** (a hard-to-reverse decision). MILESTONE links to ADRs for the *why*; it only carries the *when*.
> - **vs the tracker** — the tracker owns the **fluid task/sprint queue** (status changes often, [[project-docs-convention]] §boundaries). MILESTONE owns the **durable phase/release plan** (stable milestones + exit criteria). The tracker executes against the milestone; the milestone never mirrors task status.

**Project norms, decisions, research**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **POLICY (Project Policy — 프로젝트 공통 규칙)** | `policy` | ID issued by `pm` · owner assigned by the rule's domain (document frontmatter) | `docs/policy/<PREFIX>-POL-0000N.md` | When a rule applies to **2 or more features** (`scope: project`) — criteria, ID, promotion canon: [[project-docs-convention]] | situational |
| **ADR (Architecture Decision Record — 결정 기록)** | `adr` | architecture (ID issued by PM) | `docs/adr/<PREFIX>-ADR-0000N.md` | One per hard-to-reverse code/design decision. 🔴 **Never pre-created** | universal |
| **research (folder)** | folder (free-form) | research | `docs/research/` | When research/benchmarking outputs appear | situational |

**Feature documents** — `docs/feature/<F>/`. Stubs created **at feature kickoff on PM instruction** (not pre-created, [[project-docs-convention]])

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **FRD (Feature Requirements Doc — 기능 요구사항)** | `frd` | planning | `docs/feature/<F>/` | When expanding one PRD feature into an executable spec (per feature). **The "what"** | universal |
| **TDC (Technical Design & Concept — 구현 설계)** | `tdc` | **architecture** | `docs/feature/<F>/` | When expanding the FRD into an implementation approach. **The "how".** Absorbs as a **§Diagrams** section the former `DATA_FLOW` · `SEQUENCE` · `STATE_DIAGRAM` files (only diagrams remained there — "prose goes in the TDC" was already the rule). Diagrams only in §Diagrams; prose only in the prose sections; a state diagram 🔴 only for features with a real state machine (login, payment, orders, etc.). Canon: [[project-docs-convention]] §TDC | universal |
| **POLICY (Feature Policy — 기능 한정 규칙)** | `policy` | ID issued by `pm` · owner assigned by the rule's domain (document frontmatter) | `docs/feature/<F>/policy/` | When a rule applies **to this feature only** (`scope: feature`) — [[project-docs-convention]] | situational |

**On-demand**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **knowledge note** | `lesson`\|`gotcha`\|`decision`\|`reference` | scribe (via PM Handoff) | `knowledge/` | Whenever knowledge with reuse value emerges (on-demand) | situational |
