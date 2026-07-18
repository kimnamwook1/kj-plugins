# Reference: Knowledge Promotion (shared procedure)

> The **Knowledge Promotion** procedure shared by `sh` and `sc`. The **PM (main session)** running the calling skill reads this document with Read and performs it as written. Not executed standalone.
> **Executor = PM** — reads, detects, and judges only; **all vault writes are delegated to the scribe worker** (see "Write boundary" below).
> Canonical note schema: `docs/knowledge-convention.md` · canonical promotion topology: `docs/knowledge-escalate-convention.md`.
> **What this document is canonical for**: the score gate (sum ≥ 3) · the reject-log format (canonical map in `README.md`).

## Why separate

Session Progress is the **time axis** — for continuing this work right now. knowledge is the **topic axis** — needed again in other work. The intuition for sorting Learned items:

> Will this content be needed again three months from now in completely different work?

Intuition is only framing — **the gate is decided by score** (subjective → quantitative):

| Axis | Range | Meaning |
|---|---|---|
| **Reusability** | 0–2 | 0=this task only · 1=recurs in this project · 2=multiple tasks/projects |
| **Failure-prevention value** | 0–2 | 0=none · 1=prevents time waste/gotchas · 2=repeated mistakes/data loss/security (Mistake bonus) |
| **Source confidence** | 0–1 | 0=guess/unverified · 1=execution-verified/backed by docs |

- **Sum ≥ 3 → promote** (project knowledge). A verified repeated mistake (0+2+1) and something reused and verified (2+0+1) both pass.
- **Sum < 3 → reject-log** (no promotion; Step below). Speculative one-offs go here. **Record instead of discarding** — audit + Dreaming recurrence signal.

## Write boundary — all vault writes go to scribe (important)

> **PM = read, detect, judge only. Every write of vault content is delegated to the scribe worker. The calling skill hands over a recording brief — what, to which path, with what content.** (Canonical governance: `docs/memory-control-convention.md` §Governance)

- **Vault writes = all through scribe, the single scribe**: knowledge notes · `index.md` · `0.rejected.md` · **plus session Progress · park/closing entries · frontmatter · To-Do-List — all of it**. (The sole exception = `git add`·`git commit` — a commit is boundary recording, not content authorship, so it is the PM's job; `docs/versioning-convention.md`.)
- **The PM (executor of this procedure) does judgment only**: selects promotion candidates · decides what gets recorded where → hands that decision over as a **scribe recording brief**. (The score gate is **applied** by scribe exactly per the Steps below — the judgment logic itself is unchanged.)
- That is, in this procedure the PM (a) **delegates** the `Learned` items to scribe, (b) scribe auto-selects and promotes via the score gate, and (c) inserting the returned backlinks into the session's Learned is **also delegated to scribe**. The PM writes no vault files directly, **and asks for no approval** (sole exception: the `common/policies/` signature batch — Step 4).
- **Delegation runs through the `Agent` tool**: spawn recording (scribe) briefs with `subagent_type: worker` (depending on the plugin install form, `brain:worker` — verify after install and update this line). Code implementation briefs go to `coder`; verification/review to `verifier`.

> ⚠ **Do not split the boundary on the grounds that "it is more efficient for the calling skill (PM) to write session Progress directly"** — the moment there are two scribes, the same file gets silently clobbered. Same-machine concurrency has no locks; **the single scribe plus the PM's overlap arbitration is the only defense** (`docs/memory-control-convention.md` §Governance · `docs/versioning-convention.md`).

## Steps

1. **Automatic promotion (no approval gate)** — **delegate** this conversation's `Learned` to scribe; scribe applies the **score gate ("Why separate" above, sum ≥ 3)** to each item and **auto-promotes only what passes**. **No AskUserQuestion — no user approval is requested.** Keep capture cheap; dedup and junk cleanup are Dreaming's (batch) job ("do not force perfect dedup — write roughly, Dreaming cleans up", `docs/knowledge-escalate-convention.md`). **Below-bar items (< 3) are not discarded — append one line to `<project>/knowledge/0.rejected.md`** (audit + Dreaming recurrence signal).
   > v1 is **flat knowledge** (project-scoped) — `common/` (facts·patterns·policies) tiering belongs to Dreaming (secondary promotion; `docs/knowledge-escalate-convention.md`). Even when something is clearly cross-project, in v1 it still goes to `<project>/knowledge/`.
   > 🔴 **Sole exception — `common/policies/` is never written automatically** (canon: `docs/knowledge-escalate-convention.md` §common/policies). An item that reads as **obligation** (external mandate — law·regulation·certification·org-wide must) is promoted on its normal tier as usual **and additionally returned as a `common-policy candidate`**; the calling skill collects them and presents **one batch** for the user's signature (`skills/sh`·`sc`). **Agents draft; the user signs.** Everything else stays automatic — the score gate is unchanged.

2. **Delegate to the scribe worker** — spawn a subagent with the `Agent` tool and hand it a **recording brief** (`scribe` = a worker given a recording brief — a label, not a resident agent; `docs/memory-control-convention.md`). What goes into the brief:
   - **Context**: `vault-root` (the value defined in the project `CLAUDE.local.md` — recorded by `/brain:init` onboarding. No hardcoding) · `project` · session `uid` · today's date.
   - **Every `Learned` item** (verbatim — no compression, no paraphrase. scribe = verbatim scribe). scribe selects via the **score gate (sum ≥ 3)** — promote what passes, reject-log the rest.
   - **Scope instruction**: "perform the knowledge promotion" — the scope this procedure requires is promotion. Session Progress, park/closing entries, and frontmatter are **also written by scribe** — the calling skill passes that content in its own recording brief (it may be merged into this promotion brief or be a separate scribe worker — the calling skill's document decides. But if the same file is touched, **merge into one worker** — only the PM can see the overlap).
   - Have scribe write each passing item in `docs/knowledge-convention.md` format (trigger-first atomic note) to `<vault-root>/<project>/knowledge/`, **update-over-create** (if a similar note exists, find it via grep and update — v1 grep; **update with `Edit`, never `Write`** — `Write` on an existing note discards whatever a concurrent session put there, while `Edit`'s `old_string` is a compare-and-swap that fails loudly instead. `Write` is only for a note that does not exist yet), append one line to `<project>/knowledge/index.md`, and add the session uid backlink to `source_sessions` (vertical) plus `related` lateral links to adjacent knowledge.
   - **Obligation test (the basis for the return below)**: mark any item phrased as an **external mandate** — law·regulation·certification·org-wide must, as opposed to advice·preference·technique — as a `common-policy candidate`. Independent of the score gate: the item is still promoted or reject-logged as usual, and the mark is purely additive.
   - **Below-bar items** get one line appended to `<vault-root>/<project>/knowledge/0.rejected.md` — **reject-log format (canonical = this document)**: `- <YYYY-MM-DD> · reuse/prevent/conf=a/b/c(=sum) · "<verbatim Learned>" · <session uid>`. Plain uid, **no `[[ ]]`** — the log is team-shared while sessions/ is gitignored (versioning-convention §Share scope). The log has no `title:`, so recall (title grep) does not pick it up. **Dreaming re-reads this log under the third-time test** — the same item logged **≥2 times** becomes a re-promotion proposal, so a below-bar item is deferred, not dead. **Canon for that scan is `skills/dreaming/SKILL.md` §3 — do not infer its rules or scope from this line.**
   - **scribe returns**: the list of `→ promoted: [[Note Title]]` backlinks for created/updated notes + **every vault path it wrote** (notes · `index.md` · `0.rejected.md`) — the calling skill stages exactly those and nothing else — + reject count + **`common-policy candidates`** (the items marked by the obligation test — verbatim text + the note they landed in; **scribe writes nothing to `000_common/policies/`**).

3. **Replace, do not duplicate** — put the backlinks scribe returned onto the session's corresponding `Learned` lines: `→ promoted: [[Note Title]]`. **This replacement is also a session-file write → delegate to scribe** (the PM writes no vault content — "Write boundary" above). The PM only briefs "which backlink goes onto which `Learned` line". Never copy knowledge note bodies into the session.

4. **Policy signature batch (only when `common-policy candidates` came back)** — the PM presents the **whole list at once**, **immediately after the promotion delegation returns** (AskUserQuestion suits it; the calling skill may already have folded Step 3 into a later delegation, so do not tie this to a step number). **Per-item interrupts are forbidden** — one batch per promotion point, or none at all. Approved items go to a **follow-up scribe brief** writing them to `<vault-root>/000_common/policies/` (`docs/knowledge-convention.md` format + one line in that folder's `index.md`); unapproved ones **stay as project knowledge — nothing is discarded and nothing is re-asked**. With no candidates, this step produces no prompt.

## Forbidden

- **No `obsidian-cli create`** → the `Write`/`Edit` tools only (`Edit` for an existing file, `Write` only to create one). And pointing that write at vault content happens **only inside a scribe worker's brief** — the PM (main session) does not write directly even though it has the tool (single-scribe discipline, "Write boundary" above). Do not bypass; delegate.
- Never record secret values in plaintext.
- The old claude-obsidian procedures (`/save`·`allocate-address.sh`·`legacy-pages.txt`·`concepts/meta/entities`·`log.md`·`hot.md`) are **not used** — in the new vault graphify is the read index (`README.md` §Architecture); no need to reinvent hand-rolled index/log. Only the one-line folder `index.md` append.
