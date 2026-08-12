# Doc Catalog — Canonical Source for Document Selection

> **The PM selects documents with this table — per task, and for the project onboarding baseline.** At project onboarding the PM delegates pre-creation of **1 `business/` + 4 `develop/` = 5** stubs ([[project-docs-convention]]), and their content is filled in as judged by this table. Former standalone kinds live on as **sections** of the 5 (per-row "absorbs" notes below) — split a section into its own file only when it actually grows heavy, never pre-emptively.
>
> - **Naming = abbreviation + full name, everywhere a document is titled** — this table's Document column and every stub H1: `# PRD (Product Requirements Doc — 제품 요구사항)`.
> - **tier = universal (baseline)**: laid down by default for any non-trivial project.
> - **tier = situational**: created only when the trigger actually occurs.
> - Location conventions: project-wide = `docs/` · **per-feature = one file in `docs/develop/feature/`, no per-feature folder** (feature lives **under** `develop/`) · project memory = `p_memory/` · vault-wide memory = `neocortex/` · project hub = root `_index.md` (a legacy `index.md` is recognized as its equal — [[vault-tree]]) · the vault's fact record = the common root. (Structure & naming canon: [[vault-tree]])
> - **owner = a PM routing label — not a frontmatter field.** It is the brief-routing *default*, and **this table is its only original** (re-judged by the PM at brief time — [[project-docs-convention]] §deleted fields). The label names a brief, not a resident agent — spawn defaults to `worker`; only code-implementation documents get `coder`.
> - **The owner column feeds the brief's DoD** — the PM writes "update document X" into the DoD of the brief the owner label routes ([[project-docs-convention]] §Rules that outlived their fields).
> - **kind = a vocabulary label in this table — not a frontmatter field either.** Derivation canon: [[project-docs-convention]] §kind ← path matrix (the sole copy — never restate it here).
> - **All documents follow the [[project-docs-convention]] frontmatter standard v2** — `status: created|draft|approved|deprecated` (the only required key) + optional `history`. 🔴 **`status: created` means "no information" — never cite as evidence. The moment it gains content, switch to `draft`.**
> - **ID issuance for multi-instance documents (ADR — the only one) = the PM issues in advance** ([[project-docs-convention]] §ID Issuance). Workers never pick their own numbers. 🔴 **`<PREFIX>-POL-0000N` is retired (KJP-79)** — a policy is not a file, so it has no document ID; its `## POL-NNN` heading is a serial *within* `P_POLICY.md`, still PM-issued (row below).

## Selection Table

**Project hub**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **Project hub** | `project` | pm | root `_index.md` | Once at onboarding. **One-line definition + PREFIX + TOC pointers only** — no content prose (`_index.md` pointer principle, [[vault-tree]]) | universal |

**Core documents** (`docs/business/` · `docs/develop/`) — the 5 marked ★stub here are pre-created at project creation ([[project-docs-convention]]); the 6th slot was `BUSINESS`, retired by KJP-86, and **it stays empty — the baseline is 5 (KJP-85)**. `MARKETING` inherited `BUSINESS`'s GTM content but not its stub seat: GTM is not needed at project creation. The rest are created on trigger

| Document | kind | owner | Location | When (trigger) · absorbed sections | Tier |
|---|---|---|---|---|---|
| **PRD (Product Requirements Doc — 제품 요구사항)** ★stub | `prd` | planning | `docs/business/` | When defining product direction & requirements (early in the project). **Links to [[MARKETING]] for GTM.** Absorbs as sections: **§BM (Business Model — 수익 모델)** — the only original for pricing · tiers · unit economics ([[project-docs-convention]] §Value Axes); anchor heading = contract, never renamed · **§비기능 요구 (NFR)** — performance/availability/security targets that affect the design · **§용어 (Glossary)** — domain terms, accumulated as they become ambiguous | universal |
| **ARCHITECTURE (시스템 설계)** ★stub | `architecture` | architecture | `docs/develop/` | When system design begins. Absorbs as sections: **§데이터 모델 (ERD)** — when there is persistent data · **§외부 연동 (Integrations)** — external service contracts. Split a section into its own file only when it actually grows heavy | universal |
| **API_SPEC (API Specification — repo spec 미러)** | `api` | content=backend / sync=PM 위임 동기화 워커 (🔴 **dreaming 아님**) | `docs/develop/` | When exposing an API/service boundary. ⚠️ **Read-only mirror — SSOT is the repo spec** ([[project-docs-convention]]). **Not pre-created** — the sync worker generates it once an API exists (a stub mirror of nothing would be noise). 🔴 **Never by dreaming** — `docs/` is outside the unattended cycle's write scope ([[vault-tree]] §Write permission) | universal |
| **THREAT_MODEL (위협 모델)** ★stub | `threat-model` | security | `docs/develop/` | When handling user data or authentication (mandatory once before launch). **Kept independent** — security/evidence character; never folded into another document | universal |
| **CODE_CONVENTION (코드 규약)** ★stub | `code-convention` | architecture | `docs/develop/` | When the stack/language is decided (early in the project). Differs per project, so it is not common. Absorbs as a section: **§테스트 규율 (test discipline)** — project-wide test strategy only; per-feature acceptance criteria belong to each feature document §Acceptance | universal |
| **RUNBOOK (배포·운영 절차)** ★stub | `runbook` | devops | `docs/develop/` | When there is something to deploy. Absorbs as sections: **§Delivery** — how a change gets from a branch to the trunk, measured (note below) · **§관측 (Observability)** — on entering production · **§재해 복구 (DR)** — when data loss is a business risk · **§마이그레이션 (Migration)** — schema-change/migration procedures. **All 4 sections record verification command + output (excerpt)** — §Delivery's measurement pattern extended to every section. 🔴 **No standalone date fields (`last-verified` and kin)** — a date is subordinate metadata of a recorded output, never a claim on its own | universal |
| **COMPLIANCE (컴플라이언스 — 규제 대응)** | `compliance` | compliance | `docs/business/` | Regulated user data or AI features (regulated/non-trivial projects) | situational |
| **DESIGN (디자인 시스템 스펙 — 기능 명세급)** | `design` | design | `docs/develop/` | When the product has a UI. **Design-system spec — feature-document-grade** (the depth of one feature spec, not of a one-line pointer): design tokens · component inventory · states · interaction rules. **SSOT rule → [[project-docs-convention]] §Value Axes, "UI pixels" row — the only original, not restated here** (body template → [[doc-templates]]) | situational |

> **RUNBOOK §Delivery (absorbs the former `GIT_STRATEGY` file).** Records this project's delivery bucket (from `/brain:onboard` Q1/Q2) + a git-flow pointer + an exceptions line (default "예외: 없음 — 분류표 준수"), **and the measured values below.**
> 🔴 **The git flow is decided by the vault's delivery classification note** — a classification table mapping **project type → flow**. There is no single org-default flow; org is only where documents live (one org legitimately runs different flows per project type). The note's **path differs per vault**: a binding vault keeps it in the common layer's **normative tier** (e.g. `DELIVERY_STRATEGY.md`); a vault still stabilizing may keep it in any descriptive topic folder as a non-binding reference and move it into the normative tier when stable (common-layer location = the vault's `.brain-paths` manifest — [[vault-tree]]). 🔴 **The normative tier is a directory segment *containing* `policies` — glob `*/*policies*/*`, never an exact folder name** ([[vault-tree]] §The common layer): `policies` and `org_policies` have both been measured on the same vault and neither is canon. The descriptive tier has no reserved name at all — sub-axes are the vault's own, so there is no `facts/` to point at. **Never hardcode either spelling or restate a flow value — refer to "the vault's delivery classification note" and point** (restate → drift).
>
> **§배포 `### 환경` — 브랜치↔환경 매핑은 여기가 정본이다 (2026-08-03 신설).** 환경 **수·티어**는 공통층 배포 분류가 정하지만(서버-SaaS = stage+prod 등), **어느 브랜치가 어느 환경으로 배포되는지는 레포의 배선**이라 어디에도 없었다. 🔴 **브랜치 이름과 환경 이름은 같지 않다** — 실측: `dev` 브랜치가 `stage` 환경으로 배포되는 형태가 실재한다. 이름이 다르면 추론이 불가능하므로 표로 적는다.
>
> ```markdown
> ### 환경
> | 환경 | 배포 트리거 | 승격 조건 | 되돌리기 |
> |---|---|---|---|
> | stage | `dev` 브랜치 push | 개인 브랜치(`dev-<이름>`) → `dev` 머지 시 | 직전 커밋 재배포 |
> | prod  | `main` 브랜치 push | `dev` → `main` 머지 + 사람 승인 | 직전 태그 재배포 |
> ```
>
> 행 수·이름 전부 프로젝트마다 다르다 — 이 표는 예시이고 실제 값으로 갈아끼운다. 태그 기반 배포면 트리거 열에 `v*` 태그를 적는다. **사람 작업 브랜치 접두어(`dev-<이름>` 등)도 여기 측정치로 기록**하고, 에이전트 브랜치(canon `docs/git-convention.md`)와 공존시킨다 — 통합하지 않는다.

> **The split that keeps the two from drifting: the vault note holds the *policy*, §Delivery holds *what this repo's remote actually enforces*.** Restating a policy value here is drift; recording a measurement is the entire job — a measurement has no second copy to disagree with, because the repo is its own source. So §Delivery owns, for **this** repo:
> - **The PR/MR gate, as measured** — is a pull/merge request structurally required, how many approvals, which merge methods survive, whether any status check actually blocks the merge, and who may bypass. 🔴 **Read it off the host, never off memory or off the workflow file** — a CI workflow proves what *runs*, not what *blocks*. Record the query used, so the next reader can re-run it. **An absent gate is a finding, not a blank**: write "protection: none (measured `<command>`, `<date>`)" rather than leaving the line out.
> - **Branch naming** — the prefixes this repo's branches actually carry, and whether they are a rule or an observation. The *model* (trunk, short-lived branches, merge style) stays the vault note's; the *names* are local.
> - **Branch cleanup judgment** — how "already merged" is decided, which is squash-dependent and therefore per-repo (`git cherry` patch-equivalence, not SHA ancestry, wherever the merge squashes).
>
> **Agent branch names are not this section's call** — the coder's `<type>/<PREFIX>-<number>-<title-slug>` is harness canon (`agents/coder.md` §First action) and applies in every repo the harness runs in. `<type>` is the shared type vocabulary (canon: `docs/git-convention.md` — **never restated here**). §Delivery records the *human* convention alongside it when one exists. **A repo whose humans use type-shaped prefixes too does not merge the two** — the agent format is fixed by the harness, the human one is a measurement, and they coexist unreconciled.

**1 more business document** — GTM strategy, split out of the retired `BUSINESS` (KJP-86)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **MARKETING (마케팅 전략 — GTM)** | `marketing` | **business** | `docs/business/` | When launch, channel, or positioning decisions are needed. 🔴 **Pricing/tier literals never live here** — the only original is [[PRD]] §BM and this document links to it. Absorbs as sections: **§포지셔닝 · 메시징** — a competitor gets a line, never a chapter · **§홍보 자산 인덱스** — the real copy/social/PR assets are deliverables outside the vault, so this holds the index table only | situational |

> **`BUSINESS` is retired (KJP-86, 2026-08-12).** Its two sections went to the separate homes the canonical tree already names: **§BM → [[PRD]] §BM** (pricing · tiers · unit economics — the [[project-docs-convention]] §Value Axes home) and **§GTM → `MARKETING.md`**. One file carrying both was the 0.1.5 model; the 0.2.0 §트리 supersedes it.
>
> ✅ **`MARKETING` is not an init scaffold target — settled on the `skills/init` §4 axis (KJP-85, 2026-08-12).** That card decided the document *identity*; this one decided the seat. **`MARKETING` is situational**, created on trigger like `MILESTONE` · `COMPLIANCE` · `DESIGN`, so the pre-created baseline is **5** and `BUSINESS`'s slot stays empty. A market-entry strategy is not something a project has at creation time; a PRD is.

**Planning (roadmap)** — **not pre-created** (created on trigger, not part of the 5-stub baseline)

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **MILESTONE (마일스톤 — 단계별 딜리버리 로드맵)** | `milestone` | **pm** | `docs/business/` | When the project needs **phased delivery planning** — sequencing major deliverables/releases across time (the roadmap). Not for a single-shot small tool. Body template → [[doc-templates]] | situational |

> **MILESTONE home = `docs/business/`** (canonical tree — [[vault-tree]]). A roadmap is a business-axis document, not a develop-axis one. The former `docs/planning/` folder stays removed (a folder for one file was over-design — KJP-17 partially reversed): a **second** planning document joins MILESTONE in `business/` rather than reviving it.

> **MILESTONE boundaries (who owns overlap).** MILESTONE = **"when what"** (timing · sequencing of already-defined scope). It never redefines scope and never records decision rationale.
> - **vs PRD** — PRD owns **"what & why"** (product direction/requirements). MILESTONE references PRD/feature scope via wikilinks; it never restates it.
> - **vs ADR** — ADR owns **"why we decided X"** (a hard-to-reverse decision). MILESTONE links to ADRs for the *why*; it only carries the *when*.
> - **vs the tracker** — the tracker owns the **fluid task/sprint queue** (status changes often, [[project-docs-convention]] §boundaries). MILESTONE owns the **durable phase/release plan** (stable milestones + exit criteria). The tracker executes against the milestone; the milestone never mirrors task status.

**Project norms, decisions, research**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **P_POLICY (Project Policy — 프로젝트 공통 규칙)** | `policy` | clause number assigned by `pm` · owner assigned by the rule's domain (routing label — not frontmatter) | `docs/develop/P_POLICY.md` — **one file per project**, one `## POL-NNN` heading per rule, cited as `[[P_POLICY#POL-003]]` | When a rule applies to **2 or more features**. A single-feature rule stays in that feature's own §Rules — there is no policy folder at either tier. Canon: [[project-docs-convention]] §Policy System | situational |
| **ADR (Architecture Decision Record — 결정 기록)** | `adr` | architecture (ID issued by PM) | `docs/adr/<PREFIX>-ADR-0000N.md` | One per hard-to-reverse code/design decision. 🔴 **Never pre-created** | universal |
| **resources (folder)** | folder (free-form) | research | `docs/resources/` | When research or benchmarking outputs, meeting records, or reference material appear. Free-form, and **not a recall target** | situational |

**Feature document** — **one file per feature**, `docs/develop/feature/<pp>_<slug>_0000N.md`. Created **at feature kickoff on PM instruction** (not pre-created, [[project-docs-convention]])

| Document | kind | owner | Location | When (trigger) · absorbed sections | Tier |
|---|---|---|---|---|---|
| **Feature (기능 명세 — FRD+TDC 통합)** | `feature` | planning (§Design half: **architecture**) | `docs/develop/feature/` | When expanding one PRD feature into an executable spec (per feature). **Carries both the "what" and the "how" in one file** — §Why · §Scope · §Rules · §Acceptance, then §Design. Absorbs as its **§Design** section the former `TDC`, and with it the older `DATA_FLOW` · `SEQUENCE` · `STATE_DIAGRAM` files; a state diagram 🔴 only for features with a real state machine (login, payment, orders, etc.). **ADR promotion test: if reverting the decision would break payments, data, or an external contract — promote it to an ADR.** Canon: [[project-docs-convention]] §The feature document | universal |

> **`FRD` and `TDC` are retired as separate documents (KJP-84, 2026-08-12).** The design canon (`.artifact/brain-0.2.0.html` §트리 · §양식 feature) carries one merged file per feature and no per-feature folder, and the vault already held three of them (`RSS_ui-redesign_00001` · `PNF_status-cascade_00001` · `MOSH_host-key-trust_00001`, measured 2026-08-12) — this catalog was the last document still describing the folder-plus-two-files model. **The kinds `frd` and `tdc` retire with the files**: kind is derived from a path, and one path cannot yield two kinds ([[project-docs-convention]] §kind ← path matrix). **Owner stays split across the halves, not across files** — the planning brief owns the requirement sections and the architecture brief owns §Design, both editing one document.

**On-demand**

| Document | kind | owner | Location | When (trigger) | Tier |
|---|---|---|---|---|---|
| **memory note** | *(no kind key — 4 keys only)* | scribe (via PM Handoff) | `p_memory/` | At session close, from what the user corrected and what the AI got wrong ([[knowledge-escalate-convention]]) | situational |
