# Knowledge Layer (neocortex = semantic long-term memory)

> Tree & naming → [[vault-tree]] · sessions → [[sessions-note-convention]]

## Note Form — atomic + trigger-first (optimal for LLM recall)
Recall is symptom-driven, so **the trigger goes first**.
```
---
type: lesson | gotcha | decision | reference
title: <title containing the trigger>
uid: <anchor; same generator as session uids>
created / updated           # updated (new writes) = YYYY-MM-DDTHH:MM:SS local; date-only = legacy-legal — format canon: [[sessions-note-convention]]
projects: [x, y]            # tags, not folders (cross-membership allowed)
source_sessions: [uid...]   # vertical backlink: source sessions (required). Plain uid strings — a session may sit outside the shared surface (a team vault gitignores sessions/; per-vault choice), so never `[[wikilink]]` a session from a knowledge note (body included); it dangles for any teammate who lacks it
source_items: ["<verbatim line>", ...]   # item-level provenance (optional) — the raw Mistake/Learned line(s) this note restates, verbatim. See §Item-level provenance
related: [[note-a]], [[note-b]]   # horizontal links: topical neighbor Knowledge (planted by the scribe worker at promotion)
status: fresh | stale?      # flagged by Dreaming
recalled: N                 # feedback counter (optional, default 0) — sessions this note was injected into. See §Feedback counters
useful: N                   # feedback counter (optional, default 0) — sessions where it actually helped. See §Feedback counters
---
## Trigger   when this becomes relevant (symptom/situation)
## Insight   the core reusable knowledge
## Why       rationale + sources
```
- **1 note = 1 reusable claim** (atomic). No essays.
- **update-over-create**: if similar, don't create anew — add nuance to the existing note (living note). **Tooling follows from this**: edit an existing note with `Edit` (its `old_string` is a compare-and-swap — safe against a concurrent session), and reserve `Write` for a note that does not exist yet (`Write` on an existing note silently discards whatever a concurrent edit put there).
- **Horizontal links are the precondition for recall** — `source_sessions` (vertical) alone gives weak topic-to-topic connectivity. At promotion, weave adjacent Knowledge into `related` (when not merging). Explicit links only — with weak links, every recall tool fails at multi-hop recall. **Orphans (0 inbound) and missing cross-refs are audited & reinforced by Dreaming**.

## Feedback counters — `recalled:` / `useful:` (canonical here — KJP-7)

Promotion used to be one-way: nothing fed back whether recalled knowledge actually helped. Two optional integer frontmatter fields close that loop.

- **Semantics**: `recalled:` = number of sessions this note was **injected** into (appeared in the session's `## Context` recall block). `useful:` = number of sessions where it was **actually used** (PM judgment at park/close). `useful ≤ recalled` by construction.
- **Absence = 0 (fallback).** Both fields are optional; pre-KJP-7 notes carry neither. Every reader — the recall ranker's W_CONFIDENCE term (`skills/_session-shared/recall.md` §ranker), Dreaming — treats a missing field as 0. **Never backfill `recalled: 0` across existing notes** — the field appears on a note at its first bump.
- **Who updates**: `sh`/`sc` only, inside their existing scribe delegation. The PM reads the session's `## Context` recall block (the canonical injected-notes record — `recall.md` §Injection), judges which notes were actually used, and briefs scribe to bump `recalled:` on every injected note and `useful:` on the used subset.
- **Edit-based (+1 on the literal current value)**: `recalled: 2` → `recalled: 3` via `Edit` — the `old_string` is a compare-and-swap, so a concurrent bump fails loudly instead of losing a count. Absent field → insert the line with value 1 (anchor on an existing frontmatter line, e.g. `status:`).
- **Once per session — marker-guarded.** scribe appends one marker line at the end of the session's recall block: `<!-- counters: recalled@YYYY-MM-DD · useful: <note-basename>, … -->`. Marker present ⇒ `recalled:` is already counted for this session (never re-bumped — parks repeat, injection happened once). A later `sh`/`sc` may still **top-up `useful:`** for notes newly judged used and not yet in the marker's list — scribe extends the marker line with the same Edit discipline.
- **Scope**: note paths in the recall block (`[K]`·`[C]`·`[X]` lines) — **except the common layer's normative axis** (`*policies*` directory segments — identification canon: [[vault-tree]] §The common layer), the signature tier no agent writes, counters included (`knowledge-escalate-convention`; a policies note is simply not counted). `[M]` lines point at **session files, not notes** — never counted, never marked.
- 🔴 **No automatic deletion from counters — ever.** A low `useful`/`recalled` ratio has exactly two consequences: **ranking demotion** (the ranker's W_CONFIDENCE term is `useful`-based, so unhelpful notes sink on their own) and a **Dreaming rewrite·merge-candidate flag** (proposal only — dreaming §1). It never deletes, deprecates, or auto-archives a note — a note can sit at `useful: 0` for years and still be the one that prevents a production incident.

## Item-level provenance — `source_items:` (KJP-9)

- **What**: the verbatim raw line(s) — session `#### Mistake` / `#### Learned` text — that this note restates. `source_sessions` answers *which session*; `source_items` answers *which exact line*, making the note comparable against session text (Dreaming's Mistake-recurrence scan matches candidate lines against it — canon: `skills/dreaming/SKILL.md` §3).
- **Who writes**: scribe at promotion — the promotion brief already carries every Learned item verbatim, so this is a copy, not a rewrite (`skills/_session-shared/knowledge-promotion.md` Step 2). On update-over-create, append the new source line; never rewrite existing entries.
- **Fallback — pre-existing notes have no `source_items`** (none in the vault carried it at introduction). A note without the field can only be matched at **uid granularity** via `source_sessions`; item-level comparison and item-level suppression are **not possible** for it — any scan consuming this field must know that and say so, not guess (dreaming §3 states the consequence).

## `common/` = 3 Axes (origin, lifespan, and trust model each differ)

Layer flow — locations are canon in [[vault-tree]] (§The common layer owns the `*policies*` identification · §The candidates layer, the pool):

```
<project>/knowledge/  ─▶  candidates/ (cross-project candidate pool — pre-gate)  ─▶  common layer (facts = topic folder · norms = *policies* folder)
```

- The three axes below are **conceptual**; on disk only the norms axis is identified structurally (a `*policies*` directory segment — canon: [[vault-tree]]). Every other common-layer folder is a free topic folder on the facts tier, and the `facts/`·`patterns/`·`policies/` columns are the default example, not required folder names.
- **`candidates/` notes use this same note form** — no separate schema; the path is the state. Gate & routing: [[knowledge-escalate-convention]].

| | A. `facts/` (facts) | B. `patterns/` (distilled lessons) | C. `policies/` (norms) |
|---|---|---|---|
| Content | infra · credential locations · CLI inventory · accounts · conventions | lessons & patterns shared across projects | org-wide binding norms every project must follow — origin-agnostic |
| Question asked | "what is true" | "what works well" | "what must be done" |
| Origin | environment/world — written directly or auto-derived | upward distillation of project Knowledge (promotion) | set directly by decision — external mandate (law/reg/cert) **or** self-imposed org invariant |
| Verification | "still true?" (checkable against reality) | "still best?" (judgment) | "still in force?" (whether the mandate or org decision still holds) |
| Binding force | none (descriptive) | none (advisory) | yes (no project exceptions) |
| staleness | fast → rescan | slow | slow (only when the mandate/decision changes) |

- **Why split off the 3rd axis**: facts are *facts*, patterns are *techniques*, policies are *norms*. "What is true" and "what must be done" differ in both verification method and binding force — mix norms into facts and "checking against reality" becomes impossible (a norm is an ought, not a reality); mix them into patterns and advice becomes indistinguishable from obligation.
