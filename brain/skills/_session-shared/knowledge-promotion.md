# Reference: Promotion ① (shared procedure)

> The **promotion ①** procedure — session → `p_memory`. The **PM (main session)** running `sc` reads this document with Read and performs it as written. Not executed standalone.
> **Executor = PM** — reads, detects, and judges only; **all vault writes are delegated to the scribe worker** (see "Write boundary" below).
> Note form: `docs/knowledge-convention.md` · promotion topology: `docs/knowledge-escalate-convention.md`.
> 🔴 **`sc` is the only caller.** `sh` parks a session and **does not promote** — promotion happens once, at close.

## What gets promoted

Session Progress is the **time axis** — for continuing this work right now. A memory note is the **topic axis** — needed again in other work. Two things clear that bar, and they are the two this procedure looks for:

- **what the user corrected** — the AI was wrong about something and the user said so;
- **what the AI admitted was its own mistake and then recovered from.**

There is **no score, no weight, and no threshold.** Sameness against an existing note is decided **by content**: matching filenames or titles only narrow the candidate set, and if a number, path, version, or condition disagrees it is different knowledge — a separate note, not a merge.

Keep capture cheap. Deep dedup and tidying are `dreaming`'s batch job — write roughly rather than forcing perfect dedup.

## Write boundary — all vault writes go to scribe (important)

> **PM = read, detect, judge only. Every write of vault content is delegated to the scribe worker. The calling skill hands over a recording brief — what, to which path, with what content.** (Canonical governance: `docs/memory-control-convention.md` §Governance)

- **Vault writes = all through the single scribe**: memory notes · `_index.md` (folder TOC) · **plus session Progress · park/closing entries · frontmatter — all of it**. (The sole exception = `git add`·`git commit` — a commit is boundary recording, not content authorship, so it is the PM's job; `docs/git-convention.md`.)
- **The PM does judgment only**: selects what is worth promoting · decides what gets recorded where → hands that decision over as a **scribe recording brief**.
- **No worker talks to scribe directly** — only the PM sees the overlap between two writes.
- **Delegation runs through the `Agent` tool**: spawn recording (scribe) briefs with `subagent_type: worker` (depending on the plugin install form, `brain:worker` — verify after install and update this line). Code implementation briefs go to `coder`; verification/review to `verifier`.

> ⚠ **Do not split the boundary on the grounds that "it is more efficient for the PM to write session Progress directly"** — the moment there are two scribes, the same file gets silently clobbered. Same-machine concurrency has no locks; **the single scribe plus the PM's overlap arbitration is the only defense** (`docs/memory-control-convention.md` §Governance · `docs/git-convention.md`).

## Steps

1. **Select (PM, no approval gate)** — go through the conversation for the two kinds above. **No AskUserQuestion — no user approval is requested.** Compare each candidate against the existing slugs in `<project>/p_memory/`; same subject ⇒ mark it as an update to that note rather than a new one.

2. **Delegate to the scribe worker** — spawn a subagent with the `Agent` tool and hand it a **recording brief** (`scribe` = a worker given a recording brief — a label, not a resident agent). What goes into the brief:
   - **Context**: `vault-root` (the value in the project `CLAUDE.local.md`, recorded by `/brain:init` — no hardcoding) · `project` · the session file path · the current local datetime (`YYYY-MM-DDTHH:MM:SS`).
   - **Every selected item verbatim** — no compression, no paraphrase. scribe is a verbatim scribe.
   - **Glossary anchoring — the existing note list (guards `related:` against silent forks)**: attach the `summary` list recall already injected from `p_memory/_index.md` and `neocortex/_index.md`. **Reuse that — build no separate glossary scan** (cost stays 0). Instruction to scribe: **the new note's wording must reuse an existing term from this list verbatim** where one applies — only natural case correction is allowed; no paraphrase, abbreviation, or rename of an existing entry. Coin a new term **only after confirming it is absent from the list**. One concept spelled three ways (`Cloudflare Tunnel`/`cf tunnel`/`CF Tunnel`) silently splits the graph.
   - **Where it goes**: `<project>/p_memory/<pp>_<slug>.md`, in the note form of `docs/knowledge-convention.md` (4 keys, `## Trigger` / `## Insight` / `## Why`). **update-over-create** — if a similar note exists, **update with `Edit`, never `Write`** (`Write` on an existing note discards whatever a concurrent session put there, while `Edit`'s `old_string` is a compare-and-swap that fails loudly instead; `Write` is only for a note that does not exist yet).
   - **`_index.md` in the same commit** — append or update the line `- [[<pp>_<slug>]] — <summary>` in `p_memory/_index.md` (a legacy `index.md` counts as its equal — `docs/vault-tree.md`). 🔴 recall injects `_index.md` and nothing else, so an index that is a commit behind makes recall lie about what exists.
   - **`related:` stays `[]`.** Linking is `dreaming`'s job (promotion ②), not this procedure's.
   - **Nothing is written back into the session** — no promotion marker, no backlink, no counter. raw stays raw (`docs/vault-tree.md` §Layers).
   - **scribe returns**: every vault path it wrote (notes · `_index.md`). The calling skill stages exactly those and nothing else. If a return omits a path, ask that scribe — never widen the pathspec to compensate.

3. **`<common_root>/` is never a destination here.** The unattended cycle may not write the fact record at all, and the refusal is enforced by path, twice (`docs/vault-tree.md` §Write permission). An item that reads as an org-wide obligation is still promoted as ordinary project knowledge; turning it into a norm is a user action, not a promotion.

## Forbidden

- **No CLI writes** — every promotion write goes through the `Write`/`Edit` tools (canon: `vault-io.md` §1, alongside this file). And pointing that write at vault content happens **only inside a scribe worker's brief** — the PM does not write directly even though it has the tool (single-scribe discipline, "Write boundary" above). Do not bypass; delegate.
- Never record secret values in plaintext.
- Never copy a note body into the session, or a session line into a note as provenance metadata.
