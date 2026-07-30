# Project Docs

> Tree & naming → [[vault-tree]] · document selection → [[doc-catalog]] · body templates (DESIGN·MILESTONE) → [[doc-templates]]

## Version Control
- [[versioning-convention]]

## Core Rules
- **living doc** (no v1/v2 copies).
- **linking docs** (link to each other as needed)

## frontmatter Standard v2 (all Docs body documents)

```yaml
# ── base: every docs body document ──
status: stub | draft | approved | deprecated   # the only required key
updated: YYYY-MM-DDTHH:MM:SS                   # scribe machine-stamp (local time, same basis as session uids — format & legacy rule: [[sessions-note-convention]])

# ── multi-instance extension: POL · ADR ──
id: <PREFIX>-POL-0000N                         # required & immutable — promotion completes as a file move alone

# ── mirror extension: API_SPEC ──
source: <repo path|URL>                        # required — SSOT pointer
readonly: true                                 # required constant
synced: <datetime>                             # optional — generator stamp; freshness is judged against the repo, not this field

# ── optional, any document ──
history:
  - { at: <datetime>, change: <one line>, ticket: "KJP-41" }   # ticket also optional
```

**Everything else is derived — deleted fields (10) and where each one's truth lives:**

| Deleted field | Derived from (the original) |
|---|---|
| `kind` | path + filename (§kind ← path matrix below) |
| `title` | H1 |
| `project` | the project folder — `NNN_<slug>/` under the vault's `projects_root` ([[vault-tree]]) |
| `owner` | doc-catalog default + PM re-judgment at brief time ([[doc-catalog]] — the sole source) |
| `scope` / `feature` | the path is the tier — promotion completes as **one** change (the file move) |
| `tags` | no consumer |
| `description` | first paragraph under the H1 |
| `history.session` | banned outright (§history & session linkage below) |
| `history.by` | git author |

**Absence semantics:**

| Case | Meaning |
|---|---|
| `status` absent | illegal |
| `id` absent on a multi-instance document (POL·ADR) | illegal |
| any other key absent | normal (derived or defaulted) |
| unknown key present | **warn only — never a hard fail** (protects documents imported from outside, e.g. open-source) |

### kind ← path matrix

🔴 **This matrix lives here and only here — never replicate it in another document or a script** (a second copy is a second thing to drift).

| Path | kind |
|---|---|
| `docs/tech-design/<SINGLETON>.md` | singleton filename mapping: `PRD.md`→`prd` · `ARCHITECTURE.md`→`architecture` · `API_SPEC.md`→`api` · `THREAT_MODEL.md`→`threat-model` · `CODE_CONVENTION.md`→`code-convention` · `RUNBOOK.md`→`runbook` · `COMPLIANCE.md`→`compliance` · `DESIGN.md`→`design` (likewise `docs/business/BUSINESS.md`→`business` · `docs/MILESTONE.md`→`milestone`) |
| `docs/feature/<F>/FRD.md` | `frd` |
| `docs/feature/<F>/TDC.md` | `tdc` |
| `docs/policy/<PREFIX>-POL-*` · `docs/feature/<F>/policy/<PREFIX>-POL-*` | `policy` (scope = the path: `docs/policy/` ⇒ project · `feature/<F>/policy/` ⇒ feature) |
| `docs/adr/*` | `adr` |
| `docs/research/**` | free-form (no kind) |

- **Path vs an explicit field: the path wins.** A leftover `kind:`/`scope:` disagreeing with the path is stale metadata, not a second truth.

### history & session linkage

- 🔴 **The `session` key is banned in docs frontmatter altogether** — not merely the wikilink form; the key itself, plain uid included. A team vault gitignores `sessions/` ([[versioning-convention]] §Share scope), so even a plain uid is a reference no teammate can resolve. Enforced by `scripts/validate.sh`.
- **Team provenance = `ticket`** in `history` entries — a tracker ID resolves for everyone.
- **Session↔document linkage lives in the vault boundary commit message** (the PM's commit carries the session uid) — canon: [[versioning-convention]].
- Knowledge notes' `source_sessions` is a **separate axis** (promotion-source tracing) and unchanged — canon: [[knowledge-convention]]. Do not read this ban as applying there.

### Rules that outlived their fields

- **owner rule (moved)**: the former "your own documents unupdated = work not complete" rule left with the `owner` field — **it now rides as brief DoD wording** (the PM writes the document update into the brief's DoD; routing default = the [[doc-catalog]] owner column).
- **stub rule**: **treat as "no information" — never cite as evidence.** **The moment content is filled in, switch to `draft` immediately**.

## Value Axes — one value kind, one home

**Other documents never copy a value — they link to its original.**

| Value kind | The only original |
|---|---|
| pricing · tiers · unit economics | BUSINESS §BM |
| security normative statements | POL (`docs/policy/` or feature policy) |
| threat · mitigation tables | THREAT_MODEL |
| logical data model | ARCHITECTURE §데이터 모델 |
| physical schema | repo `migrations/` / schema |
| API contract | repo machine-readable spec (API_SPEC is a mirror) |
| UI pixels | design tool or component code (DESIGN holds links + rules) |

The pricing/tier *literal* axis is machine-checked: `scripts/value-axis-drift.sh <vault-root>` reads this table as its SSOT and reports (report-only) literals living outside their home (KJP-58). Semantic duplication — a norm restated in prose — remains this declaration + PM mediation.

## stub Pre-creation Rules

- **Pre-created = 6** — 5 in `tech-design/` (`PRD` · `ARCHITECTURE` · `CODE_CONVENTION` · `RUNBOOK` · `THREAT_MODEL`) + 1 in `business/` (`BUSINESS`). **At project onboarding the PM delegates pre-creating all of them as `status: stub`.** Former standalone kinds live on as sections of these 6 ([[doc-catalog]] per-row "absorbs" notes) — split a section into its own file only when it actually grows heavy.
- **`API_SPEC` is not pre-created** — it is a read-only repo-spec mirror (§The Only Exception below); dreaming's api-mirror audit generates it once an API exists. `COMPLIANCE` · `DESIGN` · `MILESTONE` stay situational (created on trigger).
- **Feature document set = 3** (`FRD` · `TDC` + the `policy/` folder) — **not pre-created.** Created **at feature kickoff on PM instruction**. Not created at project creation or when onboarding an existing system (you don't yet know what the features will be).
- **ADRs are never pre-created** — one is created only when a meaningful decision actually occurs: **the PM delegates it as a recording brief carrying the `architecture` owner label** (a brief label, not a resident agent — workers never write the vault directly; [[memory-control-convention]] §Governance. ID issued by the PM). An empty ADR is harmful — a false signal that "a decision happened".
- The catalog lists more kinds than get pre-created (situational + trigger-generated + the feature set). **Only 6 are pre-created** — do not conflate the two numbers.

## TDC — if FRD is the "what", TDC is the "how"

- **Role**: implementation approach · interfaces · trade-offs · **lightweight decisions**. 🔴 **Never bury major decisions in the TDC — split them out as ADRs and link** — an ADR is standalone evidence of a hard-to-reverse decision; mixed into a document, it cannot be found.
- **TDC = prose + §Diagrams in one file**: the data-flow · sequence · state diagrams live **inside the TDC as a `§Diagrams` section** (they absorbed the former `DATA_FLOW` · `SEQUENCE` · `STATE_DIAGRAM` files — only diagrams remained there once prose was banned from them). **Prose (why it flows this way) lives only in the prose sections; §Diagrams holds diagrams only** — scatter prose into diagram captions and the two drift apart. A state diagram 🔴 only for features with a real state machine (login, payment, orders, etc.) — otherwise omit it.
- **Reference direction (one-way)**: `FRD → TDC → (ADR · policy)`. Never create reverse references — with a cycle, which one is upstream disappears (the conflict order ("Document Conflict Precedence" below) stops working).

> **Non-code decisions** (stack, vendor, scope) go to `type: decision` notes in `knowledge/`, not ADRs — only code/design decisions get an ADR.

## Policy System

**The (single) criterion**: *"Does this rule apply to **2 or more features**?"*

| Answer | Location | Tier (path-derived — §kind ← path matrix) |
|---|---|---|
| **Yes** | `<project>/docs/policy/` | project |
| **No** | `<project>/docs/feature/<F>/policy/` | feature |
| (shared across all projects) | `common/policies/` | 3-axis definition → [[knowledge-convention]] |

- **ID = `<PREFIX>-POL-0000N`** — **a single per-project sequence. Independent of tier/location, and immutable.**
- **Never put the feature name in the filename or ID.** Tier is expressed solely by the path (§kind ← path matrix — no `scope` field). (Baking the feature name into the ID means the ID changes on promotion → every reference breaks. ID immutability is the mechanism that lets promotion finish as **a file move alone**.)
- **FRD·TDC never copy policy values** — reference only via `[[<ID>]]` wikilinks.
- **Promotion** → [[knowledge-escalate-convention]]
- **No separate policy changelog document** — history lives in `history:` + git.

## ID Issuance (shared by multi-instance documents: POL · ADR …)

- **Format `<PREFIX>-<TYPE>-0000N`** (project PREFIX · document TYPE · 5-digit serial).
- **Issuer = the PM, in advance.** Read the **frontmatter `next_id`** of that type's folder TOC — `index.md` first; where absent, an existing `_index.md` is recognized as its equal — assign +1, then update `next_id`. Workers never pick their own numbers (collisions under concurrent work).
- **Verification = Dreaming** — detects duplicates, gaps, and regressions in batch and **reports** them.
- **Dreaming never issues IDs**
- **`next_id` home = that type's folder `index.md`** (absent → an existing `_index.md` is its equal — folder-TOC equivalence: [[vault-tree]]) — POL: `<project>/docs/policy/index.md`, ADR: `<project>/docs/adr/index.md`.
- **ADRs are collected in `docs/adr/` — never placed in feature folders.** Why: ① ADRs that **attach to no feature** — stack choices, infra decisions — would have nowhere to go ② when a feature is scrapped, its decision record gets buried with it — an ADR is standalone evidence of "why we decided this" and outlives the feature ③ `docs/policy/` already has the same shape (single per-project sequence + its own folder), so the ID issuance rule stays unified.
- If an ADR relates to a feature, reference it from that feature's `FRD`·`TDC` via a `[[<PREFIX>-ADR-0000N]]` wikilink. **Never move the file into the feature folder.**

## Document Conflict Precedence (PM rule)

The pecking order when documents disagree — the higher one wins:

```
common/policies (global)  >  docs/policy  >  PRD §비기능 요구(NFR)  >  PRD  >  FRD  >  TDC
```

- 🔴 **This table is the PM's arbitration tool — not for workers.** Worker instructions carry only one line: "on conflict, don't judge on your own — report to the PM". Hand workers the pecking order and it becomes "I won, so ignore that one", and fixing the losing document never happens.
- 🔴 **A conflict is usually a signal that one of the two is wrong.** Follow the winner and **fix the loser** — left alone, the next person hits the same conflict again.
- The logic of the order: norms (must be followed) > constraints (the PRD's NFR section) > the what (PRD→FRD) > the how (TDC). **The lower you go the more concrete it gets, and the concrete never beats the abstract.** (A section outranking the rest of its own document is intentional — a constraint binds the requirements written next to it.)
- **A new rank is added only when a real conflict occurs — one line at a time, never pre-emptively.** The 6-tier order stays as-is; no full-spectrum (12-tier) expansion.

## What Not to Put in the Vault (boundaries)

Only **memory and design documents** live in this vault. Keep the two classes below in their own canonical homes and never copy them here (drift prevention):

- **Documents that live in the repo** — `README` · `SETUP` · `CONTRIBUTING` · `CHANGELOG` · `CLAUDE.md` · test code · **user-facing legal** (terms of service, privacy policy). Versioned and shipped alongside the code.
- **Things that live in the tracker** — tasks · bugs · roadmap · sprints. For execution items whose status changes often, the tracker is canonical. (Per-project tracker: session frontmatter `related_ticket`)

### The Only Exception — the API_SPEC Mirror

**`docs/tech-design/API_SPEC.md` is the sole exception to the "repo = code only" principle.**

- **SSOT = the repo's OpenAPI/JSON Schema** (CI-linted). The vault document is a **read-only mirror** — preservation against folder deletion + a wikilink target inside the vault.
- Mirror frontmatter → §frontmatter Standard v2 mirror extension (`source` · `readonly: true` required, `synced` optional). `readonly` is ⚠️ **informational — hooks do not enforce it**.
- 🔴 **When working from the API contract, always read the repo's spec. The vault mirror is for viewing only, up to 24h stale.**
- Why the exception: the contract must be verified next to the code (CI), yet the vault's design documents need a target their links can point at. **The mirror is the cost of bridging those two, and that is why "read-only" is the condition** — the moment you edit the mirror, the exception turns into drift.
