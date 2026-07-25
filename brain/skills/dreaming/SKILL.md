---
name: dreaming
description: Batch maintenance of the memory vault (second-brain) — dedup/merge of accumulated knowledge, staleness flags, secondary promotion (project knowledge → common/patterns), structural audits (stub-scan·api-mirror·id-audit·policy-promotion-scan), recall-layer refresh (router pointer proposals·Facts). Real-time capture stays cheap and messy; the hard consolidation is batched here periodically. Use when the user says "dreaming", "수면 통합", "볼트 정리", "지식 dedup", "메모리 consolidate/통합", "볼트 유지보수", "낡은 지식 정리", or on a periodic schedule. Destructive changes (merge·delete) are proposal-only — never overwrites memory automatically.
---

# Dreaming — Vault Sleep Consolidation (batch maintenance)

## Why this skill exists
The memory harness **deliberately keeps capture cheap and imperfect** — during a session the scribe worker writes things down duplicates and all, and is never forced into perfect tidiness. That keeps capture friction low so records actually get made (force it and it won't be followed). This skill is what cleans up that messiness **periodically** — like a brain consolidating·pruning waking experience during sleep (`README.md` §Architecture, brain-to-harness mapping: fast-lossy capture + periodic consolidation). **Without Dreaming the vault rots with duplicates and stale claims.** Hence the division of labor between capture (real-time) and refinement (batch).

## When it runs
- On a periodic schedule or explicit user invocation.
- It pays off once sessions·knowledge have accumulated somewhat. **A nearly empty vault has nothing to do** — in that case report briefly "nothing to clean up" and stop (don't manufacture work).

## Target vault
The vault-root defined in the project's `CLAUDE.local.md` (recorded by `/brain:init` onboarding — no hardcoding). With multiple business vaults, iterate over each.

## Absolute principle — never silently overwrite memory
Dreaming's biggest risk is **bad consolidation polluting memory.** A wrong merge/delete is hard to undo. Hence two core guardrails:
- **Destructive changes (merge·delete·move) are proposal-only.** Apply after user/PM approval. **Auto-apply only what is low-risk·lossless** — dead-link fixes, adding missing cross-links, setting `status: stale?` flags.
- **Incremental.** Don't grind the whole vault every time — only what **changed·aged since the last dream.** Full reprocessing is slow and only raises the pollution risk. (Explicit detect-only full-scan carve-outs exist — §0.)

## Procedure

### 0. Scope — only changes since the last dream
Read the last dream date from `<vault>/000_common/dream-log.md` (if absent, first run = everything is in scope — format canon: §7). Narrow the target to knowledge·Facts `updated:` since then, plus newly created sessions. This is the incremental baseline.

**Full-scan carve-outs (explicit exceptions to the incremental baseline)** — three §3 scans deliberately read their **whole corpus**, not the increment: the reject-log comb (third-time test), the skill-tag grep, and the **session-Mistake recurrence scan**. Recurrence is by definition cross-run — an incremental slice can never count it. This carve-out does not dent the §Absolute-principle guardrail, because the incremental rule guards two things and only one applies: **(a) pollution risk — does not apply here**: all three scans are detect·propose only, with no write path into the scanned files, so the pollution surface the rule protects against does not exist; **(b) cost — handled per-scan**: the two greps are trivially cheap, and the recurrence scan carries its own hard cap (§3). Everything else in this skill stays on the incremental baseline.

### 1. Dedup / Consolidation (proposal)
Find similar notes within the same project's `knowledge/` (grep titles·`## Trigger`; similarity query if graphify is wired). For duplicates·partial overlaps, produce a **merge proposal**: which note to merge into, what survives, what remains as nuance. **No automatic merging** — if conditional differences are lost (e.g. a Mistake's subtle situational difference), the knowledge lies. On approval, merge and leave a backlink at the original's location.

**Orphan·cross-ref check (linking = the precondition for recall, borrowed from claude-obsidian wiki-lint):** for pairs from the similarity scan that are "related but not merge-worthy", **reinforce** `related` lateral links (low-risk → auto-add). Flag notes with **zero inbound links (orphans)** — knowledge that has only `source_sessions` (vertical) and no `related` (lateral) is isolated and never surfaces in recall. scribe plants `related` in real time at promotion (`docs/knowledge-convention.md`), but Dreaming periodically catches omissions·isolation. Big restructurings to resolve orphans are proposals; adding a one-line cross-link is automatic.

**Net-help flag (KJP-7)** — notes whose `recalled:` keeps climbing while `useful:` stays 0 (field absent = 0; canon: `docs/knowledge-convention.md` §Feedback counters) are prime **rewrite·merge candidates**: they surface in recall yet never help, which usually means wrong `title:`/`## Trigger` wording or a note that should fold into a neighbor — surface them into this section's proposals. 🔴 **A low `useful`/`recalled` ratio never deletes, deprecates, or auto-archives a note** — ranking demotion (recall's `useful`-based W_CONFIDENCE term, which happens by itself) and this proposal flag are the only permitted consequences.

### 2. Staleness flags (automatic, low-risk)
- **knowledge**: claims unreferenced for N months (default 6) or with an old `updated` → mark frontmatter `status: stale?`. **Not deletion** — just a marker for "is this still the best?" re-review.
- **Facts**: entries whose `verified:` date is old or that may have changed when checked against `source:` → `status: stale?` + a re-verification proposal. **Facts are value-copies with high drift risk, so rescanning them is this skill's core duty** ("is it still true?" — checkable against reality). Auto-derived Facts (e.g. the CLI inventory) are rescanned and actually updated.

### 3. Secondary promotion (proposal)
Find patterns in project `knowledge/` that **recur across multiple projects** (quantitative gate = **recurrence in ≥3 projects**, canon: `docs/knowledge-escalate-convention.md`). scribe sees only one session and cannot see cross-project recurrence — only Dreaming, which sees the whole, catches it. **Propose escalating** such notes to `common/patterns/` + add missing cross-links. On approval, move them and leave a link on the project side. (The gate is numeric to cut curation labor.)
- **`common/policies/` is out of scope for this escalation** — patterns never become policies (`docs/knowledge-escalate-convention.md`). If a candidate **this section surfaces** is phrased as an external mandate (the obligation test of `skills/_session-shared/knowledge-promotion.md` §Steps 2), it goes to §7 `## For PM` as a **`common-policy candidate`** batched with the rest, never moved automatically: **agents draft, the user signs.**
- **Third-time test (reject-log recurrence scan)** — comb `<project>/knowledge/0.rejected.md` (the whole file) for the same item recurring **≥2 times** (similar raw text). **Two occurrences make the third a rule** — the primary gate (sum < 3) sees only one session and can underrate reusability, so recurrence is itself the reuse signal. **Propose such items as re-promotion candidates** (scribe turns them into proper knowledge notes); detection·proposal only. Mark handled lines in the log (prefix `~`) so the next dream doesn't re-propose them.
- **Session Mistake recurrence scan (content similarity — KJP-9; deferral lifted).** Deferred in 0.1.2 because sessions carry no handled-marker, so recurrence could be counted but never closed out; the two missing preconditions now exist — **dream-log suppression keys** (§7 format) supply the close-out, and knowledge-note **`source_items`** (`docs/knowledge-convention.md` §Item-level provenance) supplies item-level comparison — so the scan is live. Comb session `#### Mistake` blocks for the **same mistake recurring in ≥2 distinct sessions** (third-time-test precedent: two occurrences make the third a rule) and **propose** — detection·proposal only, and 🔴 **never mark, edit, or annotate a session file** (non-negotiable; close-out lives in the dream-log, below). This is a **different scan** from the structured-signal tag count in the next bullet: that counts a **machine string** (`[skill:…]` exact tag), this judges **content similarity** — never merge the two.
  - **Corpus & guards**: full `sessions/` scan (§0 carve-out — detect·propose only, capped below). Inherit both `recall.md` [M] guards: **skip `session_type: dreaming` files**, and read `^project:` per file — recurrence is counted **within one project only** (skip files with an empty `project:`; a cross-project pattern is §3 secondary promotion's axis, not this scan's), and every proposal and dream-log key line **carries its `<project>`**.
  - **Cap (the O(N²) bound)**: similarity is pairwise, so the candidate set is hard-capped at the **newest `DREAM_MISTAKE_N` (default 30) Mistake lines per project** (newest by session `updated:`) — the recall `RECALL_N` cap precedent (enforced by code, not eyeballed). 30 ⇒ ≤435 pair checks per project; older lines age out of the scan rather than growing it.
  - **Similarity test — one test for counting AND suppression, by design**: normalize both lines (lowercase · non-alphanumerics → space · distinct tokens ≥2 chars, the recall-overlap normalization) and call them the same mistake when shared-token count ÷ the smaller token set ≥ **0.6**. Deterministic, grep/awk-grade, no embeddings. 🔴 **Symmetry rule**: suppression-key matching uses **exactly this test at exactly this threshold** — a fuzzy count closed out by exact-string matching would resurrect every paraphrase as a "new" recurrence.
  - **Close-out (dream-log, never sessions)**: each reported group writes one suppression-key line into this run's dream-log entry — `- mistake-recur · <project> · rep="<normalized text of the newest member>" · n=<count> · sessions: <uid, uid, …>` (plain uids, no `[[ ]]`). Later runs read the **whole log cumulatively (§7)** and skip any group matching a recorded key (same similarity test); if a group **grew** past its recorded `n`, re-propose as an update and refresh that key line's `n`·uid list (the skill-proposals refresh precedent — never a duplicate line). The user marks a handled key with the `~` prefix (reject-log precedent); `~`-keys still suppress.
  - **Existing-note check (`source_items`, with fallback)**: before proposing a new note, test the group against existing notes. A note whose `source_items` contains a matching line (same similarity test) means the knowledge **exists but recall failed to surface it** → route as a **recall-fix signal** (the structured-signal bullet's `already_known` retrieval-defect diagnostic, below), not a new-note proposal. **Fallback**: a note without `source_items` (every pre-KJP-9 note) can only be matched at **uid granularity** via `source_sessions` — if a group member's session uid appears there, flag the group "possibly already distilled (uid-level match only)"; item-level confirmation and item-level suppression are **not possible** for such notes, and the proposal must say so instead of guessing.
  - **Machine boundary (stated limitation, not solved here)**: `sessions/` may be local-only·gitignored while the dream-log lives on the shared surface (`docs/versioning-convention.md` §Share scope — per-vault choice). Counts are therefore **per-machine observations, not vault-global truths**: another machine's key line may cite session uids this machine cannot see (expected — never "correct" or prune it), and one mistake split across two machines' sessions under-counts until sessions themselves are shared.
- **Structured-signal aggregation (reject reason codes · skill-step Mistake tags)** — two fields coded at write time precisely so this batch can tally them without judgment calls; both are plain greps. Deliberately one clause — it is the same move twice (free text → coded field → deterministic batch tally).
  - **Reject reason codes** — tally the unhandled `0.rejected.md` lines (without `~`) by their `<reason>` code (`already_known` · `not_durable` · `unsupported` — line format canon: `skills/_session-shared/knowledge-promotion.md`). **Key diagnostic — a topic recurring as `already_known`: the note exists, yet sessions keep re-learning it ⇒ recall failed to surface it. That is a retrieval defect, not a capture defect** — report it to §7 `## For PM` as a recall-fix signal (candidate fixes: the note's `title:`/`## Trigger` wording, missing `related:` links). `not_durable` recurrence is exactly the third-time test's input (above); `unsupported` recurrence flags verification debt — worth a re-verification To-Do, never a promotion.
  - **Skill-step Mistake tags** — count session `#### Mistake` lines carrying the optional `[skill:<skill>§<step>]` tag (schema: `docs/sessions-note-convention.md`), grouped by **exact tag string**. Full grep over `sessions/` like the third-time test's whole-file comb — a tag grep is cheap enough to exempt from §0's incremental scope. **Threshold: the same tag on ≥2 distinct sessions** (the third-time-test precedent — two occurrences make the third a rule) → produce a **skill-improvement proposal** in `<vault>/000_common/skill-proposals.md` (a runtime output written by scribe like every vault write — not a repo file): one `## [skill:<skill>§<step>]` section per tag, containing **current wording** (quoted verbatim from the skill file) / **proposed wording** / **evidence: session uid list** (plain uids, no `[[ ]]`). If the section already exists, refresh its uid list — never duplicate the section; skip `~`-prefixed (handled) sections. Surface new/updated proposals in §7 `## For PM`.
  - 🔴 **No auto-apply path — absent by design, not by omission.** Nothing in this skill (nor any agent) edits a skill file from a proposal; **the pipeline terminates at the proposal file.** The user reads it, applies the wording by hand, then marks the section `~` (or deletes it). This is the §Absolute-principle propose·approve rule applied to the harness's own procedures.

### 4. Recall-layer refresh
Memory lives only if it gets pulled out — this step keeps recall current.
- **Router vault-pointer update proposal**: **propose updates** to the vault pointers in the project's `CLAUDE.local.md` router (the thin router/hot-cache auto-loaded every session) to match the current knowledge·Facts indexes — **it is a local file (outside the vault·project root), so no automatic edits; apply after user approval.** **Pointers only, no content** (token economy) — "what exists and how to query it" + the few Facts that are always needed.
- **Facts inventory rescan** (tied to step 2).
- **Folder `index.md` (TOC) creation·refresh + consistency check**: re-ensure every folder has an `index.md` — create for new folders, refresh existing ones to the current contents (wikilinks to files·subfolders). **Fixing dead wikilinks that point to nonexistent filenames is low-risk automatic.** **Also check that index wording doesn't contradict the actual structure** — e.g. sessions are per-`<uid>.md` files, so if an index describes them as folders, correct it (spec drift = real recall cost). scribe appends in real time, but Dreaming periodically catches omissions·drift. Exclude `.obsidian`.
- **Document drift-lint (against the canon map)**: scan·flag documents that **restate·contradict** any fact in `README.md` §Single-Source Map against its single canon (borrowed from claude-obsidian wiki-lint "stale claims"). E.g. if git=SOT reads "RS-SOT" somewhere, or sessions are described as "per-folder" somewhere, catch it. Pointer substitution is a low-risk proposal; big restructurings are proposal-only.
- **graphify incremental reindexing (if wired)**: at the end of Dreaming, incrementally reindex stable knowledge·outputs with `graphify --update` — **binding capture (real-time) and index refresh (batch) into one rhythm.** Churn-heavy sessions are reindexed here periodically, not every time.

### 5. Structural·consistency audit (detect·report centric — does not fix)

The four below run **within the §0 scope (changes since the last dream), not as a full scan**. All four **do no creation·numbering·moving** — they detect and surface to §7 `## For PM` only. Record each item in the §Report format's `## Tasks` as `ok/fail/skipped` + count.

- **stub-scan** — pick out only *referenced* stubs. Grep documents with `status: stub`, then count inbound wikilinks (`[[...]]`) across the whole vault for each filename·title. **Inbound ≥1 = a stub someone is waiting on** → report as fill-priority. Stubs with 0 inbound block no one, so count only (low priority) — **except** stubs older than N days (default 30, by frontmatter `updated:`), which are reported too: a freshly scaffolded stub has 0 inbound by construction, so age is the only signal it has been forgotten.
  > **Dreaming does not fill stubs** — generating content that doesn't exist is not recall but **fabrication**. List only, to the PM.
- **api-mirror** — sync the repo spec → vault `<project>/docs/tech-design/API_SPEC.md` mirror (location canon: `docs/vault-tree.md` · mirror-rule canon: `docs/project-docs-convention.md` §The Only Exception). **SSOT = the repo; the vault is a mirror.** Mirror frontmatter carries `source:` (repo path·URL) · `synced:` (sync date) · `readonly: true`.
  - If the repo spec is newer than the mirror → **update the mirror** (repo→vault is one-way, hence lossless = safe to auto-apply).
  - If the mirror shows signs of hand edits (`readonly: true` yet changed after `synced:`) → **flag only**. **Never flow vault-side edits back** into the repo (SSOT inversion = silent pollution).
  - If the repo is unreachable (no path·no permission), `skipped` + reason.
- **id-audit** — verify issued ids (`<PREFIX>-<TYPE>-0000N`) for **duplicates** (same id in 2+ places) and **gaps** (sequence holes). 🔴 **Dreaming does not issue ids — detect·report only.** If dreaming fills empty numbers, two parties issue concurrently and collide (issuing party = PM pre-issuance, canon: `docs/project-docs-convention.md` §ID Issuance).
- **policy-promotion-scan** — detect when a policy set in one feature **has also been applied to a 2nd feature** (feature-local → cross-reuse signal = `scope: feature` → `project` promotion candidate). Report such items as **`project-policy candidates`** awaiting user approval — `<project>/docs/policy/`, a **different axis** from §3's `common-policy candidates` (org-wide `000_common/policies/`); both land in `## For PM`, so never merge the two lists (detection=Dreaming / approval=user — canon: `docs/knowledge-escalate-convention.md` · criteria: `docs/project-docs-convention.md` §Policy System). **No automatic moves** — policy sits high in the document-conflict priority (`docs/project-docs-convention.md` §Document Conflict Precedence), so a wrong promotion silently overrides other judgments. Same discipline as §3 (secondary promotion): propose·approve.

### 6. Metrics snapshot (harness observability)
See in numbers whether the architecture actually works (no metrics = no knowing). **Create no new event log — everything derives-on-read from existing SOTs** (anti-drift). Count each metric within scope (§0, since the last dream):

| Metric | Source | Method |
|---|---|---|
| Delegations | external ticket system | cards that passed In Progress·Done (per-project tracker MCP, if reachable) |
| Rework/reopen | external ticket system | Done→In Progress transitions (work item activity) |
| Promoted notes | `<project>/knowledge/` | new/updated notes in scope |
| Rejects | `<project>/knowledge/0.rejected.md` | unhandled lines (without `~`), tallied per `<reason>` code |
| Skill-tagged Mistakes | `sessions/` `#### Mistake` lines | `[skill:…]` tag count per exact tag (§3 aggregation) |
| Mistake-recurrence groups | `sessions/` `#### Mistake` lines | §3 recurrence scan — groups with ≥2 distinct sessions, per project, within the `DREAM_MISTAKE_N` cap |
| Stale flags | `<project>/knowledge/` | grep `status: stale?` |
| recall injections | session recall blocks | injected titles across in-scope sessions |

- If the tracker is unreachable (no tool), those two rows are `n/a`; vault-derived only.
- Append the results to the dream-log below as a `## Metrics` table — trends emerge as dreams accumulate.

### 7. Report + dream-log record
- Present **proposals** (merge·secondary promotion·re-verification) to the user/PM — apply only what is approved. AskUserQuestion multiple-choice works well.
- List the **auto-applied low-risk items** (dead-link·cross-link·staleness flags).
- Record this dream in `<vault>/000_common/dream-log.md`: date, scan scope, proposal/application summary, **the §6 metrics table**. This becomes the next dream's incremental baseline.
- Leave an **execution report** as `<vault>/sessions/<uid>.md` — format is the §Report format below (fixed).

**dream-log format (canonical here — the file had no canon before KJP-9; grounded on the live file's existing shape, this only adds the per-item project field and the cumulative-read rule):**

```markdown
# Dream Log — <vault name>

## YYYY-MM-DD — <run label>     ← one `## ` heading per run, newest at top
**scan scope**: <increment window + which §0 carve-out full scans ran>
<auto-applied / approved / held-flagged summaries — per-item bullets>
- mistake-recur · <project> · rep="…" · n=… · sessions: …    ← §3 suppression keys (`~` prefix = handled)
<the §6 `## Metrics` table>
```

- **Run separation = the date heading, newest at top** — §0 reads the newest heading's date as the incremental baseline. Label wording inside an entry follows the live file's existing convention; the *structure* above (run heading · scope · summaries · metrics) is what is canonical.
- 🔴 **Project field on every project-scoped item line.** The dream-log is **one vault-wide file** — without a `<project>` field on item lines (suppression keys, per-project proposals), entries from different projects cross-match: project A's mistake key would suppress an identically-worded (but independently made) mistake in project B. Vault-level lines (e.g. common/ maintenance) need no field.
- 🔴 **Cumulative read.** Consumers other than §0's baseline-date read — above all the §3 suppression-key match — read **the whole log, every run entry**, not just the newest: keys and flags accumulate across runs, and the newest entry alone is not the state.

## Report format (fixed)

Every dream run leaves an execution report at `<vault>/sessions/<uid>.md` (**writing is delegated to the scribe worker** — the vault's single scribe, `docs/memory-control-convention.md` §Governance).

- **uid = `YYYYMMDD-HHMMSS`** — the **same timestamp axis** as session uids (`PROJECT_PREFIX-YYYYMMDD-HHMMSS`, canon: `docs/sessions-note-convention.md`). A dreaming report does not invent a separate uid axis — but a dream is a cross-project batch, so it has no `project:` and therefore no PROJECT_PREFIX prefix.
- **Reuse** the existing session frontmatter, adding two fields: `session_type` · `result`.

```markdown
---
uid: <YYYYMMDD-HHMMSS>
project:
git_branch:
git_worktree:
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
status: done
result: success | partial | failed
session_type: dreaming
writer: scribe
cc_session_ids:
related_ticket:
tags: [dreaming]
---

## Summary
overall / started–ended / duration

## Tasks
| # | task | status(ok/fail/skipped) | count | detail |

## Failures
task / error / suspected cause / retry: yes|no

## For PM
action-needed items only (stubs to fill, promotions awaiting approval, failures to retry)
```

### 🔴 Field rules — violate them and recall silently gets polluted

- **`status` and `result` are different axes.** `status` is by vault hard rule **only the 3 values `active|parked|done`** (canon: `docs/sessions-note-convention.md`) — putting `success|failed` there violates the hard rule, and writing either **open** value (`active` or `parked`) makes **`sl`/`sr` list the dreaming report as a "session to resume"** (the shared scan — `skills/_session-shared/active-sessions.md` §1 — accepts both). A dream is a finished batch, so **always `status: done`** — the one closed value, and the only one that keeps the report out of that scan (even if interrupted: done + `result: partial|failed`). Success/failure is expressed **only via `result`**.
- **Leave `project:` empty.** A dream is a **cross-project** batch over the whole vault and belongs to no single project — a value there would be false, and it would also match the `recall.md` [M] Mistake scan (`^project: <project>` matching) and **pollute recall**. `status: done` blocks the `sl`/`sr` open-session scan, but **the [M] scan looks only at `project:`** — which is why, so this blank isn't the sole defense, a `session_type: dreaming` skip guard was also placed in `recall.md` [M] **and in `active-sessions.md` §1** (the latter matters because `sl all` widens the project filter to `.*`, where an empty `project:` would otherwise match). **Never rely on just one of these.**
- **Do not use a `#### Mistake` heading.** The [M] scan scrapes `#### Mistake` blocks. Sticking to the schema above (`## Failures`) naturally avoids it, but if failures get renamed to "Mistake", dream failures **masquerade as past work mistakes** in recall.
- **`writer: scribe`** — unlike a human session's `writer:` (= `whoami`, an actual person), a dream report is machine-generated, so it carries the scribe-worker label (`scribe`). This difference is intentional.

## v1 scope (now)
grep-based (graphify later). dedup·staleness·secondary promotion·CLAUDE.local.md Router pointer regeneration·**structural audit (§5)**·**metrics snapshot (§6)**. Scheduling lives outside this skill (cron/loop). **Early on the vault is small and there is almost nothing to do — that is normal.** The value grows as the vault accumulates.

## Forbidden
- **No automatic application** of destructive changes (merge·delete·move) — propose·approve.
- **Never record secret values in the vault** — even during Facts rescans, locations·conventions only, never values.
- `obsidian-cli create` forbidden → Write/Edit tools only.
