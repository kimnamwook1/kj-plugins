# Project Docs

> Tree & naming → [[vault-tree]] · document selection → [[doc-catalog]] · body templates (DESIGN·MILESTONE) → [[doc-templates]]

## Version Control
- [[versioning-convention]]

## Core Rules
- **living doc** (no v1/v2 copies).
- **linking docs** (link to each other as needed)

## frontmatter Standard (all Docs documents)

```yaml
id: <PREFIX>-<TYPE>-0000N   # multi-instance documents (POL·ADR etc.) only. Omitted for singleton documents (PRD·ARCHITECTURE…)
kind: prd | frd | tdc | adr | policy | ...   # document kind (doc-catalog "kind" column)
title: <document title>
project: <project-slug>
status: stub | draft | approved | deprecated
owner: <label>              # responsible for updating this document (for brief routing — not a resident agent)
scope: project | feature    # policy only
feature: <feature-name>      # only when scope: feature (+ feature documents FRD·TDC etc.)
updated: YYYY-MM-DD
tags: []
history:
  - { date: YYYY-MM-DD, change: <one line>, by: <agent>, session: "[[PROJECT_PREFIX-YYYYMMDD-HHMMSS]]" }
```

- **`session:` is the session uid verbatim** — `PROJECT_PREFIX-YYYYMMDD-HHMMSS`. Never abbreviate (if wikilinks don't match actual filenames, they all break). Canon → [[sessions-note-convention]]
- **owner rule**: **work is not accepted as complete without updating the documents you own.**
- **stub rule**: **treat as "no information" — never cite as evidence.** **The moment content is filled in, switch to `draft` immediately**.

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

| Answer | Location | frontmatter |
|---|---|---|
| **Yes** | `<project>/docs/policy/` | `scope: project` |
| **No** | `<project>/docs/feature/<F>/policy/` | `scope: feature` + `feature: <F>` |
| (shared across all projects) | `common/policies/` | 3-axis definition → [[knowledge-convention]] |

- **ID = `<PREFIX>-POL-0000N`** — **a single per-project sequence. Independent of tier/location, and immutable.**
- **Never put the feature name in the filename or ID.** Tier is expressed solely by the frontmatter `scope`. (Baking the feature name into the ID means the ID changes on promotion → every reference breaks. ID immutability is the mechanism that lets promotion finish as **a file move alone**.)
- **FRD·TDC never copy policy values** — reference only via `[[<ID>]]` wikilinks.
- **Promotion** → [[knowledge-escalate-convention]]
- **No separate policy changelog document** — history lives in `history:` + git.

## ID Issuance (shared by multi-instance documents: POL · ADR …)

- **Format `<PREFIX>-<TYPE>-0000N`** (project PREFIX · document TYPE · 5-digit serial).
- **Issuer = the PM, in advance.** Read the **frontmatter `next_id`** of that type's folder `index.md`, assign +1, then update `next_id`. Workers never pick their own numbers (collisions under concurrent work).
- **Verification = Dreaming** — detects duplicates, gaps, and regressions in batch and **reports** them.
- **Dreaming never issues IDs**
- **`next_id` home = that type's folder `index.md`** — POL: `<project>/docs/policy/index.md`, ADR: `<project>/docs/adr/index.md`.
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

## What Not to Put in the Vault (boundaries)

Only **memory and design documents** live in this vault. Keep the two classes below in their own canonical homes and never copy them here (drift prevention):

- **Documents that live in the repo** — `README` · `SETUP` · `CONTRIBUTING` · `CHANGELOG` · `CLAUDE.md` · test code · **user-facing legal** (terms of service, privacy policy). Versioned and shipped alongside the code.
- **Things that live in the tracker** — tasks · bugs · roadmap · sprints. For execution items whose status changes often, the tracker is canonical. (Per-project tracker: session frontmatter `related_ticket`)

### The Only Exception — the API_SPEC Mirror

**`docs/tech-design/API_SPEC.md` is the sole exception to the "repo = code only" principle.**

- **SSOT = the repo's OpenAPI/JSON Schema** (CI-linted). The vault document is a **read-only mirror** — preservation against folder deletion + a wikilink target inside the vault.
- Mirror frontmatter: `source: <repo path>` · `synced: <datetime>` · `readonly: true` (⚠️ **informational — hooks do not enforce it**).
- 🔴 **When working from the API contract, always read the repo's spec. The vault mirror is for viewing only, up to 24h stale.**
- Why the exception: the contract must be verified next to the code (CI), yet the vault's design documents need a target their links can point at. **The mirror is the cost of bridging those two, and that is why "read-only" is the condition** — the moment you edit the mirror, the exception turns into drift.
