# Project Docs

> Tree & naming → [[vault-tree]] · document selection → [[doc-catalog]] · body templates (DESIGN·MILESTONE) → [[doc-templates]]

## Version Control
- [[git-convention]]

## Core Rules
- **living doc** (no v1/v2 copies).
- **linking docs** (link to each other as needed)

## frontmatter Standard v2 (all Docs body documents)

```yaml
# ── base: every docs body document ──
status: created | draft | approved | deprecated   # the only required key
updated: YYYY-MM-DDTHH:MM:SS                   # scribe machine-stamp (local time, same basis as session uids — format & legacy rule: [[sessions-note-convention]])

# ── multi-instance extension: ADR (the only multi-instance kind) ──
id: <PREFIX>-ADR-0000N                         # required & immutable — one decision = one file, and links must survive

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
| `scope` / `feature` | the path is the tier. Policy has only one tier per project (`develop/P_POLICY.md`), so there is nothing left for a `scope` field to say |
| `tags` | no consumer |
| `description` | first paragraph under the H1 |
| `history.session` | banned outright (§history & session linkage below) |
| `history.by` | git author |

**Absence semantics:**

| Case | Meaning |
|---|---|
| `status` absent | illegal |
| `id` absent on a multi-instance document (ADR) | illegal |
| any other key absent | normal (derived or defaulted) |
| unknown key present | **warn only — never a hard fail** (protects documents imported from outside, e.g. open-source) |

🔴 **The docs layer has no retired-key *finding*, and that is a decision — not a hole (KJP-89, 2026-08-12).** A deleted key from the table above (`kind`·`title`·`owner`…) lands in the row directly above: warn on stderr, never a finding. Do not "fix" this by promoting the unknown-key warn or by porting the wiki layer's retired-key check down here. Three reasons, each measured:

- **Docs migration is "no longer written", never a forced rewrite.** The wiki layer's retired-key check exists because one bulk sweep had to reach ~560 notes this system authored, and there a *stale* key means the sweep missed a file (`scripts/validate.sh` §wiki retired keys — the comment there also warns that deleting the retired strings deletes the detector). A docs document may be **imported from outside**, so an old key is a legitimate artifact rather than a missed sweep. The boundary is already pinned by fixture: `scripts/validate-selftest.sh` §docs frontmatter v2 carries a legacy `kind`/`title`/`owner` document that must warn on stderr **and** stay out of the findings stream.
- **Promotion is not proportionate.** Measured on the real vault 2026-08-12: **42 unknown-key warnings across the docs layer, and 0 of them are a retired key.** They are live kind-specific fields (`related_ticket`·`screen_id`·`summary`·`adr_number`·`methodology`…). Promoting the warn turns a 0-true-positive rule into 42 findings, which is how a gate gets ignored.
- 🔴 **Retired-ness in docs is per-kind, so there is no single list to hold.** The same string is live in one kind and retired in another: the transcript's **feature** template declares `version:` and `species:` as live fields, while its **ADR** template lists both as retired. `title` is sharper still — it is a *finding* on the wiki layer and must **never** be one here. A merged list erases exactly those distinctions.

### kind ← path matrix

🔴 **This matrix lives here and only here — never replicate it in another document or a script** (a second copy is a second thing to drift).

| Path | kind |
|---|---|
| `docs/business/<SINGLETON>.md` | singleton filename mapping: `PRD.md`→`prd` · `MARKETING.md`→`marketing` · `MILESTONE.md`→`milestone` · `COMPLIANCE.md`→`compliance` |
| `docs/develop/<SINGLETON>.md` | singleton filename mapping: `ARCHITECTURE.md`→`architecture` · `API_SPEC.md`→`api` · `THREAT_MODEL.md`→`threat-model` · `CODE_CONVENTION.md`→`code-convention` · `RUNBOOK.md`→`runbook` · `DESIGN.md`→`design` · `P_POLICY.md`→`policy` |
| `docs/develop/feature/<pp>_<slug>_0000N.md` | `feature` |
| `docs/adr/*` | `adr` |
| `docs/resources/**` | free-form (no kind) |

- **Path vs an explicit field: the path wins.** A leftover `kind:`/`scope:` disagreeing with the path is stale metadata, not a second truth.
- **`frd` and `tdc` are retired as separate kinds (KJP-84, 2026-08-12).** The two documents merged into one file, and a kind is derived from a path — one path cannot yield two kinds without the matrix becoming undecidable. The merged file's kind is `feature`, which is also what its folder and its `species:` already call it. Nothing mechanical moved with them: `validate.sh` never matched a feature path (its only path arms are `docs/adr/` and `docs/develop/API_SPEC.md`), so `kind` here is documentation vocabulary and this row is its only home.

### history & session linkage

- 🔴 **The `session` key is banned in docs frontmatter altogether** — not merely the wikilink form; the key itself, plain identifier included. `hippocampus/` sits outside git ([[vault-tree]] §Layers), so even a plain filename is a reference no teammate can resolve. Enforced by `scripts/validate.sh`.
- **Team provenance = `ticket`** in `history` entries — a tracker ID resolves for everyone.
- **Session↔document linkage lives in the vault boundary commit message** (the PM's commit names the session) — canon: [[git-convention]].
- **Memory notes point at no session either.** raw and wiki do not reference each other, and `source_sessions` is retired ([[knowledge-convention]]).

### Rules that outlived their fields

- **owner rule (moved)**: the former "your own documents unupdated = work not complete" rule left with the `owner` field — **it now rides as brief DoD wording** (the PM writes the document update into the brief's DoD; routing default = the [[doc-catalog]] owner column).
- **stub rule**: **treat as "no information" — never cite as evidence.** **The moment content is filled in, switch to `draft` immediately**.

## Value Axes — one value kind, one home

**Other documents never copy a value — they link to its original.**

| Value kind | The only original |
|---|---|
| pricing · tiers · unit economics | PRD §BM |
| security normative statements | a `## POL-NNN` clause in `docs/develop/P_POLICY.md` |
| threat · mitigation tables | THREAT_MODEL |
| logical data model | ARCHITECTURE §데이터 모델 |
| physical schema | repo `migrations/` / schema |
| API contract | repo machine-readable spec (API_SPEC is a mirror) |
| UI pixels | design tool or component code (DESIGN holds links + rules) |

The pricing/tier *literal* axis is machine-checked: `scripts/value-axis-drift.sh <vault-root>` reads this table as its SSOT and reports (report-only) literals living outside their home (KJP-58). Semantic duplication — a norm restated in prose — remains this declaration + PM mediation.

🔴 **The pricing home moved from `BUSINESS §BM` to `PRD §BM` when KJP-86 dissolved `BUSINESS.md`, and that widened the drift scan on purpose — 126 → 151 docs, 19 → 28 findings (measured 2026-08-12).** It is not a broken exclusion, and re-narrowing it would re-hide a live violation. The detector excludes the home in two shapes, `<HOME>.md` anywhere and the `docs/<home-lowercase>/` tree, because a home may be a file or a folder. Under `BUSINESS` the second shape resolved to `docs/business/` — the whole folder — only because the home document happened to carry its folder's name. That coincidence, never a decision, also excluded `COMPLIANCE` · `MILESTONE` · `MARKETING` from pricing checks. `PRD` names no folder, so only `PRD.md` is excluded now and the other 25 files in the tree are scanned for the first time. **All 9 new findings are price literals in one file — `MARKETING.md`, the document the split created — which is drift by this very table: GTM copy links to `PRD §BM`, it does not restate the prices.**

> An earlier note here (KJP-86) held the row stale on the reading that the widening was the exclusion *breaking*, and deferred the edit until `value-axis-drift.sh` could be changed alongside it. That reading was tested and did not hold: the 25 extra files are not a leak, they are the folder that was never anyone's home, and the script needed no change at all — its two-shape derivation is already correct for a home that is a file. The four self-test assertions were re-pinned instead, one of them inverted into a positive fixture so the old blanket exemption cannot return quietly.

## stub Pre-creation Rules

- **Pre-created = 5** — 1 in `business/` (`PRD`) + 4 in `develop/` (`ARCHITECTURE` · `CODE_CONVENTION` · `RUNBOOK` · `THREAT_MODEL`). **At project onboarding the PM delegates pre-creating all of them as `status: created`.** Former standalone kinds live on as sections of these 5 ([[doc-catalog]] per-row "absorbs" notes) — split a section into its own file only when it actually grows heavy.
  - **`BUSINESS` left the list with KJP-86, and `MARKETING` did not take its seat.** The split sent business-model content to `PRD §BM` and GTM content to `MARKETING.md`, and **GTM is not something a project needs at creation time** — the same reason `MILESTONE` · `COMPLIANCE` · `DESIGN` are situational. A PRD is universal; a market-entry strategy is not. `MARKETING.md` is created on trigger, like the rest of them.
- **`API_SPEC` is not pre-created** — it is a read-only repo-spec mirror (§The Only Exception below), generated and re-synced by a **PM-delegated sync worker** once an API exists. 🔴 **Never by `dreaming`** — the unattended cycle writes only `hippocampus/` · `<project>/p_memory/` · `neocortex/`, and `docs/` is written solely by an AI acting on a user instruction ([[vault-tree]] §Write permission). `COMPLIANCE` · `DESIGN` · `MILESTONE` · `MARKETING` stay situational (created on trigger).
- **Feature document set = 1** (the merged `feature` file — FRD+TDC in one document) — **not pre-created.** Created **at feature kickoff on PM instruction**. Not created at project creation or when onboarding an existing system (you don't yet know what the features will be). There is no per-feature folder either: one feature = one file directly under `docs/develop/feature/` ([[vault-tree]] §tree). A rule that applies to this feature alone stays in the feature's own §Rules — there is no per-feature `policy/` folder (§Policy System).
- **ADRs are never pre-created** — one is created only when a meaningful decision actually occurs: **the PM delegates it as a recording brief carrying the `architecture` owner label** (a brief label, not a resident agent — workers never write the vault directly; [[memory-control-convention]] §Governance. ID issued by the PM). An empty ADR is harmful — a false signal that "a decision happened".
- The catalog lists more kinds than get pre-created (situational + trigger-generated + the feature set). **Only 5 are pre-created** — do not conflate the two numbers.

## The feature document — the "what" and the "how" in one file

**`FRD` and `TDC` are one document (KJP-84, 2026-08-12).** The design canon merged them: `docs/develop/feature/<pp>_<slug>_0000N.md`, `species: Feature — 기능 명세 (FRD+TDC 통합)`. Section order carries the old split — **what** (§Why · §Scope · §Rules · §Acceptance) then **how** (§Design). The two never were separate audiences here; a reader who needs the rules also needs the design.

- **Role of the §Design half**: implementation approach · interfaces · trade-offs · **lightweight decisions**. 🔴 **Never bury major decisions in it — split them out as ADRs and link** — an ADR is standalone evidence of a hard-to-reverse decision; mixed into a document, it cannot be found.
- **Diagrams live in §Design**, which absorbed the former `DATA_FLOW` · `SEQUENCE` · `STATE_DIAGRAM` files (only diagrams remained there once prose was banned from them). A state diagram 🔴 only for features with a real state machine (login, payment, orders, etc.) — otherwise omit it.
- **Reference direction (one-way)**: `feature → (ADR · policy)`. Never create reverse references — with a cycle, which one is upstream disappears (the conflict order ("Document Conflict Precedence" below) stops working). The former `FRD → TDC` leg is gone: it was an edge between two files that are now one.

> **Non-code decisions** (stack, vendor, scope) go to a memory note in `p_memory/`, not an ADR — only code/design decisions get an ADR.

## Policy System

**Home = one file per project: `<project>/docs/develop/P_POLICY.md`.** Situational — created when the first project-wide rule actually exists. It is **not** one of the 5 pre-created stubs.

**The (single) inclusion criterion**: *"Does this rule apply to **2 or more features**?"*

| Answer | Where it goes |
|---|---|
| **Yes** | a `## POL-NNN` clause inside `docs/develop/P_POLICY.md` |
| **No** | that feature's own document, §Rules — no policy file and no policy folder |
| (shared across all projects) | the common root's `*policies*` directory — normative-axis identification → [[vault-tree]] §The common layer |

- **One rule = one `## POL-NNN <title>` heading.** `NNN` is a **serial within the file** (read the last heading, add 1), issued by the PM. It is **not** a `<PREFIX>-…` document ID — see §ID Issuance.
- **Reference = the `[[P_POLICY#POL-003]]` anchor**, which is the citation unit for rank 2 of §Document Conflict Precedence. **A feature document never copies policy values** — it links to the anchor.
- **No folder, no file-per-policy, no `id:` frontmatter, no `next_id` counter.** The former two-tier folder model (`docs/policy/` + `docs/feature/<F>/policy/`) is **retired — KJP-79, 2026-08-12**. Grounds: the design canon (`.artifact/brain-0.2.0.html` §트리) carries only `develop/P_POLICY.md`, and the vault's 9 project-tier + 1 feature-tier policy folders held **`_index.md` and nothing else** (measured 2026-08-12 — zero body documents, so nothing needed migrating).
- 🔴 **Escalation, not promotion — and only outward, to the common layer.** When a clause overlaps an org-wide norm, **do not restate it**: raise it into the common root's `*policies*`, or leave a pointer. **This is a PM judgment, never an automatic ladder** — the common layer is a fact record maintained by measurement, *not* a promotion tier, and the unattended cycle (`sc` · `dreaming`) may never write there ([[knowledge-escalate-convention]] §What does not ride this ladder). Within a project there is nothing to promote *between*: one file is the only tier.
- **Splitting is a size decision, not a tier decision.** When the file grows heavy, split it and the clause heading becomes the filename naturally. Callers cite the `POL-NNN` anchor, so their links survive the split.
- **No separate policy changelog document** — history lives in `history:` + git.

## ID Issuance (multi-instance documents — ADR is the only one)

- **Format `<PREFIX>-<TYPE>-0000N`** (project PREFIX · document TYPE · 5-digit serial).
- **Issuer = the PM, in advance.** Read the **frontmatter `next_id`** of that type's folder TOC — `_index.md` first; where absent, a legacy `index.md` is recognized as its equal — assign +1, then update `next_id`. Workers never pick their own numbers (collisions under concurrent work).
- **Verification = `scripts/validate.sh`** — two units, both of it. Per file: `id:` required on an ADR body document, `next_id:` required on `docs/adr/`'s index. Per folder (the ADR ID audit, KJP-83): **duplicate ids**, **holes in the issued sequence**, and a **`next_id` that is not ahead of the highest issued id**. Findings in default mode, `--strict` blocks.
  - **The two directions of `next_id` drift are judged differently, on purpose.** Above highest + 1 = numbers issued and their records not written yet — that is issuance *in advance*, which this section prescribes, so it is silent. At or below the highest = the next number handed out is one a file already holds, a duplicate that has not happened yet — that is the finding.
  - **A hole is judged against 1, not against the lowest id present.** Measured 2026-08-12: every ADR folder with no files carries `next_id: 1`, so serial 1 is always the first number a counter hands out and a hole beneath the lowest file is a consumed number rather than numbering that began later.
  - **A number carried only by a filename still counts as consumed.** `<PREFIX>-ADR-0000N.md` with no `id:` key is already reported by the presence check; calling its number a hole too would name the wrong defect twice.

- 🔴 **The unattended cycle (`sc` · `dreaming`) is not that owner and never could be.** It writes only `hippocampus/` · `<project>/p_memory/` · `neocortex/` ([[vault-tree]] §Write permission), and it neither reads nor writes `docs/adr/` at all ([[knowledge-escalate-convention]] §What does not ride this ladder). The audit lives in the linter for that reason — a gate the PM runs, not a background cycle.
- **`next_id` home = that type's folder `_index.md`** (absent → a legacy `index.md` is its equal — folder-TOC equivalence: [[vault-tree]]) — ADR: `<project>/docs/adr/_index.md`. **That is the only `next_id` in the vault.**
- **ADRs are collected in `docs/adr/` — never placed in feature folders.** Why: ① ADRs that **attach to no feature** — stack choices, infra decisions — would have nowhere to go ② when a feature is scrapped, its decision record gets buried with it — an ADR is standalone evidence of "why we decided this" and outlives the feature. (A third reason once read "`docs/policy/` has the same shape, so the rule stays unified" — that folder is retired, and the first two reasons carry the rule on their own.)
- If an ADR relates to a feature, reference it from that feature's document via a `[[<PREFIX>-ADR-0000N]]` wikilink. **Never move the file into `feature/`.**

#### `<PREFIX>-POL-0000N` is retired (KJP-79, 2026-08-12)

Policy no longer takes a document ID **because it no longer has documents.** A `<PREFIX>-…-0000N` ID identifies a *file*; a policy is now a `## POL-NNN` heading inside `develop/P_POLICY.md` (§Policy System). Recorded so nobody re-derives the old scheme:

- **`NNN` is a file-internal serial, not an issued ID.** Its uniqueness scope is the one file, so the project PREFIX adds nothing — `[[P_POLICY#POL-003]]` is already globally unique through the filename.
- **The PM still assigns the number** (canon §양식: "번호 = 파일 내 연번, PM 발급"), but reads it from the last heading in the file rather than from a `next_id` counter. No policy folder exists to hold one.
- **The immutability argument died with its premise.** Immutable POL IDs existed so that *promotion between tiers* could complete as "a file move alone" without breaking references. There are no tiers and no moves left, so the guarantee has nothing to protect.
- **`validate.sh` no longer treats any policy path as multi-instance.** `docs/adr/` keeps both checks unchanged.

## Document Conflict Precedence (PM rule)

The pecking order when documents disagree — the higher one wins:

```
*policies* (vault-global)  >  develop/P_POLICY.md  >  PRD §비기능 요구(NFR)  >  PRD  >  feature
```

- 🔴 **This table is the PM's arbitration tool — not for workers.** Worker instructions carry only one line: "on conflict, don't judge on your own — report to the PM". Hand workers the pecking order and it becomes "I won, so ignore that one", and fixing the losing document never happens.
- 🔴 **A conflict is usually a signal that one of the two is wrong.** Follow the winner and **fix the loser** — left alone, the next person hits the same conflict again.
- The logic of the order: norms (must be followed) > constraints (the PRD's NFR section) > the product-wide what (PRD) > the one feature's what and how (the feature document). **The lower you go the more concrete it gets, and the concrete never beats the abstract.** (A section outranking the rest of its own document is intentional — a constraint binds the requirements written next to it.)
- **A new rank is added only when a real conflict occurs — one line at a time, never pre-emptively.** The 5-tier order stays as-is; no full-spectrum (12-tier) expansion.
  - 🔴 **It was 6 tiers until KJP-84 merged FRD and TDC**, which collapsed the last two into one rank — a document cannot outrank itself. The count changed because a document disappeared, **not** because a rank was judged unnecessary; that is still something only a real conflict may do.

## What Not to Put in the Vault (boundaries)

Only **memory and design documents** live in this vault. Keep the two classes below in their own canonical homes and never copy them here (drift prevention):

- **Documents that live in the repo** — `README` · `SETUP` · `CONTRIBUTING` · `CHANGELOG` · `CLAUDE.md` · test code · **user-facing legal** (terms of service, privacy policy). Versioned and shipped alongside the code.
- **Things that live in the tracker** — tasks · bugs · roadmap · sprints. For execution items whose status changes often, the tracker is canonical. (Per-project tracker: session frontmatter `related_ticket`)

#### `legal/` is a repo folder, not a vault folder (KJP-85, 2026-08-12)

The 0.2.0 design canon (`.artifact/brain-0.2.0.html` §트리) placed terms-of-service / privacy-policy under a **vault** `docs/business/legal/`, contradicting the `user-facing legal` boundary above. **This rule wins; the canon's tree was corrected in the same commit.** Recorded so the rule is not quietly deleted the next time the two are compared:

- **This document is the arbitration authority** (`CLAUDE.md` §PM role points conflict resolution here). A design artifact cannot silently overturn the document that defines what wins.
- **The exception list below is closed at one member** — promoting `legal/` to a second mirror would first have to overturn "the sole exception", and nothing argues for that.
- **The drift reason is strongest here, not weakest.** The canon's own legal template requires an `effective:` date. Two copies of a document carrying a legal effective date is a liability, not an inconvenience — the operative terms are the *published* ones, so citing a vault copy means citing the wrong terms.
- **The canon was not even describing a mirror** — it called the vault path the "공개 게시 원본" (the original for publication), so the API_SPEC exception could not have rescued it.
- **Measured 2026-08-12** — `legal/` existed in 0 of the techtainment vault's 13 projects, and 0 `TERMS*`/`PRIVACY*` files. No migration cost.
- **The template survives; only the home moved.** The `<법적 문서>.md` skeleton (including `effective:`) stays canon and is authored **in the repo**. The vault's `COMPLIANCE.md` links to the repo path / published URL per item and never copies the body.

### The Only Exception — the API_SPEC Mirror

**`docs/develop/API_SPEC.md` is the sole exception to the "repo = code only" principle.**

- **SSOT = the repo's OpenAPI/JSON Schema** (CI-linted). The vault document is a **read-only mirror** — preservation against folder deletion + a wikilink target inside the vault.
- Mirror frontmatter → §frontmatter Standard v2 mirror extension (`source` · `readonly: true` required, `synced` optional). `readonly` is ⚠️ **informational — hooks do not enforce it**.
- 🔴 **When working from the API contract, always read the repo's spec. The vault mirror is for viewing only, up to 24h stale.**
- Why the exception: the contract must be verified next to the code (CI), yet the vault's design documents need a target their links can point at. **The mirror is the cost of bridging those two, and that is why "read-only" is the condition** — the moment you edit the mirror, the exception turns into drift.
