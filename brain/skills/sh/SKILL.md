---
name: sh
description: Park (suspend) a work session — not closure. Unconditionally parks the current session — scan pending markers → knowledge promotion + park entry in Progress (all vault content writes delegated to the scribe worker), status flips active → parked. Resume it later with sr. Use when the user says "sh", "handoff", "park", "pause", "핸드오프", "세션 인계", "잠깐 멈춤", "보류". To close a session for good, use sc.
---

# sh — Session Park (Handoff)

> **When in doubt, present the fork first.** If context is too thin, present a one-liner and get their pick: which do you want — `ss` (start new) / `sr` (resume a parked one) / `sl` (just list what is open) / `sh` (park/handoff) / `sc` (complete)?

**Parks (suspends)** the current session — carves the working context into the session file, flips `status` to `parked`, and stops. Getting back in is `sr`, explicitly typed; nothing surfaces the session on its own.

> **Where this skill fits:** common to all three skills (`ss`·`sh`·`sc`) — **executor = PM (main session), vault content writes = the `scribe` worker** (a subagent handed a writing brief — not resident). Governance canon: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Executor and write boundary (must-read)

- **PM (this skill's executor) = reading·detection·judgment + the vault git commit.** Session discovery (`find`) · pending-marker scan (`grep`) · date check (`date`) · user Q&A · **deciding what to record** · **the vault commit (step 7)** are the PM's. (Commit executor = PM — canon: `${CLAUDE_SKILL_DIR}/../../docs/git-convention.md`. A commit is not content authorship but a **boundary record**, and it swallows the whole repo, so only the PM — who sees the whole — can do it safely. `scribe` never commits.)
- **Vault content writes = all delegated to `scribe`.** Park entry · `## To-Do-List` update · frontmatter (`updated`) · knowledge promotion·`knowledge/_index.md` — the PM does not write them directly (discipline — recording consistency + main-context economy).
- **How to delegate**: spawn a subagent with the `Agent` tool and hand it a **writing brief**. What to pass = context (`vault-root` · `project` · session `uid` · the current local datetime — `YYYY-MM-DDTHH:MM:SS`, what `updated:` stamps take) + **what · to which path · with what content**. `scribe` returns the paths·content it recorded.

## Hard rule — the sh vs sc boundary

- **This skill flips status `active` → `parked` (KJP-48).** Park is *suspension/hold*, not closure — and `parked` is the status that says exactly that. Both `active` and `parked` are **open** states, so `sl`/`sr` still find the session; what changes is that "waiting" is now readable from one grep of `^status:` instead of being guessed from the Progress body.
- **`parked` is the only status `sh` ever writes.** Never `done` — **to close a session, use `sc`.** If the session is already `parked` (a second `sh` without an intervening `sr`), the value simply stays `parked`; the park entry is still appended.

## Workflow — unconditional PARK

`sh` takes no arguments and asks no questions — when invoked it **unconditionally parks the current session**. Working context is recorded in the session file itself; resumption is a separate explicit verb, `sr`.

### Steps

1. **Settle the target session** — the open (`status: active`, or `parked` if a previous `sh` already ran) session worked on in this conversation (`<VAULT>/sessions/<uid>.md`). If the user named one, use that. (`VAULT` = the `vault-root` in the project's `CLAUDE.local.md` — if missing, ask the user and point to `/brain:init`.)

2. **Pending-marker scan** (see "Scan for Pending Markers" below) — always run **before** deciding resume actions. **The scan is done by the PM directly** (a read-only `grep` — command below). Organize found markers by location·request·owner and **put them into the `## To-Do-List` items of the step-4 brief** (writing them to the file is `scribe`'s job).

3. **Knowledge promotion (`scribe` delegation, automatic)** (see "Knowledge Promotion" below) — run **before** delegating the park entry. Per the `${CLAUDE_SKILL_DIR}/../_session-shared/knowledge-promotion.md` procedure, **delegate to the `scribe` worker** for **automatic promotion** (`scribe` selects via the two-gate judgment, no approval asked). Put the `→ promoted: [[..]]` backlinks `scribe` returns into the step-4 Learned. (Scope: **knowledge promotion + feedback-counter bumps on the injected notes** (Feedback-counters paragraph below) — `<uid>.md` is delegated separately in step 4.)

   **Policy signature batch** — if `scribe` returns `common-policy candidates`, present **the whole list once** here (knowledge-promotion Step 4) and hand only the approved ones to a follow-up `scribe` brief writing the vault common layer's `policies/` (`BRAIN_COMMON/policies` — `.brain-paths`, resolved by `scripts/vault-paths.sh`). `common/policies/` is the sole tier no agent may write on its own — **agents draft, the user signs** (`${CLAUDE_SKILL_DIR}/../../docs/knowledge-escalate-convention.md`). No candidates → no prompt; **never ask per item.**

   **Feedback counters (same delegation — KJP-7)** — the PM extracts the injected-note list from the session's `## Context` recall block (the canonical injected-notes record — `recall.md` §Injection; grep, read-only) and judges **which of those notes were actually used this session**. The brief has `scribe` bump `recalled:` +1 on every injected note and `useful:` +1 on the used subset — Edit-based (+1 on the literal current value; absent field → insert at 1), **once per session**, guarded by the Context counter-marker line. Semantics·marker format·exclusions (`[M]` session lines · the common layer's `policies/` — `BRAIN_COMMON/policies`) canon: `${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters. The marker line itself lands in `## Context` through the **step-4** brief (the session file is step 4's scope); if the marker already exists, only the `useful:` top-up applies.

4. **Record park entry·To-Do·frontmatter → delegate to `scribe` (one delegation)** — the PM **decides the content**, and **`scribe` writes it**. Insert per the Park Entry Format below at the **top** of `## Progress` (newest on top). Factual, not verbose.

   **Writing brief** (hand over as-is):
   - **Target file**: `<VAULT>/sessions/<uid>.md` (plus, **only when the docs-`history:` bullet below applies**, the project `docs/` documents it names — no other vault files)
   - **`## Progress`**: insert the Park Entry Format block below **at the top** (preserve existing entries, no overwriting). The Learned line includes the step-3 backlinks (`→ promoted: [[..]]`) verbatim.
   - **`## To-Do-List`**: resume actions + the pending markers found in step 2 (Where·What·Who). **If step 5 captured user direction, it goes first.**
   - **`## Context`**: if step 3 bumped feedback counters, append (or extend, via Edit) the counter-marker line at the end of the recall block — format canon: `${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters. Touch nothing else in Context.
   - **frontmatter**: `updated:` to the current local datetime (`YYYY-MM-DDTHH:MM:SS` — canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md` §updated), and **flip `status:` to `parked`**. Replace **only the `status:` line inside the frontmatter block** — the body Progress may also contain the string `status:`, so a naive global replace misfires. **Never `done`** — that is `sc`'s alone.
   - **Docs `history:` row (only when this session modified a project `docs/` document)**: for each such document, append one row to its frontmatter `history:` — `- {at: <datetime>, change: <one line>, ticket: <related ticket — omit when none>}` (canon: `${CLAUDE_SKILL_DIR}/../../docs/project-docs-convention.md` §history — frontmatter v2's only provenance channel, so a skipped row leaves the edit unattributable; `history.session` is banned, the session uid stays out).
   - **Return requirement**: the recorded path + the inserted entry heading + the final `status` value + any docs paths that received a `history:` row.

5. **Capture user direction** — if the user gave intent for the next session, put it **at the front of** `## To-Do-List`. User's words > agent analysis. (The PM captures·judges → ships it in the step-4 brief.)

6. **Frontmatter update** — included in the step-4 delegation (`updated:` = the current local datetime, `status:` → `parked`). The PM does not touch it separately, and never patches `status` with `sed`/redirection — vault content writes belong to `scribe`.

7. **git commit (vault snapshot — commit-only, executor = PM)** — the PM commits directly **after** the step-3·4 `scribe` writes are done (**record → commit order** — committing first leaves the park entry out of the snapshot). The canon for commit executor·timing is git-convention — `scribe` never commits (a commit swallows the whole repo, sweeping in other `scribe` workers' unfinished work too — only the PM, who sees the whole, is safe).

   - **Command**: `git -C "$VAULT" add -- <paths…> && git -C "$VAULT" commit -q -m "<message>"`
     - **The pathspec = what the scribes returned** — the step-4 session file `<VAULT>/sessions/<uid>.md` + the step-3 promoted note paths + `<project>/knowledge/_index.md`·`0.rejected.md` when touched + the step-3 counter-bumped note paths (these may sit outside `<project>/` — `[C]`/`[X]` notes). If a return omitted a path, ask that scribe; never widen the pathspec to compensate.
     - **Leave every other dirty file dirty** — do not stage, stash, or revert anything outside that list, however unrelated-looking the diff. It is another session's unfinished work.
     - **Read `git -C "$VAULT" status --porcelain` before staging.** If dirty files reach beyond this session's own paths, say so in step 8 (`N files dirty across M directories — staged only this session's`) and stage from the pathspec anyway. A report, not a gate — never block the park on it.
     - If none of those paths changed, **do not commit** (no empty commits). If the vault is not a git repo, skip quietly and mention it in step 8.
   - **`git push` is forbidden — commit-only.** No automatic push under any circumstances (only on the user's explicit request). The vault carries repo names·commit SHAs·infra topology·operator metadata (writer·cc_session_ids) verbatim — remote exposure is the user's call.
   - **Message convention — no guessing.** **Before** committing, check **that vault's existing convention** with `git -C "$VAULT" log --oneline -10` and follow it (format·language·prefix differ per vault). Fallback only when no convention is readable: `session <uid>: parked — <one-line gist>`.
   - **Scope is `$VAULT` only** — pinned via `git -C`. Do not touch other repos or paths outside the vault.

8. **Closing notice:**
   > Session parked: `<VAULT>/sessions/<uid>.md` (status: parked)
   >
   > Resume it with `sr`; see everything open with `sl`.
   >
   > (If the work is finished, close it with `sc`, not `sh`.)

## Park Entry Format (Progress structure)

Insert at the **top** of `## Progress` (above existing entries). Follow the canonical `#### ` subheading structure (canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`). The `(parked)` heading suffix is the **per-entry historical record** of this park — kept, but **no longer a machine-judgment source** (KJP-48: state is read from frontmatter `status:`; canon: sessions-note-convention §Progress entry status suffix). A round-count may trail it (`(parked #5)`); never put a non-status description there.

```markdown
### YYYY-MM-DD (parked)
**Stopped at:** exactly where the work stopped (one line).
#### Done
- What was accomplished. Be specific.
#### Mistake
- (if any) mistakes made this time — highest reuse value.
#### Fixed
- (if any) how those mistakes were fixed.
#### Learned
- Pitfalls·constraints·decisions discovered. If promoted: → promoted: [[Note Title]]
#### Outputs
- `path/to/output` — what it is
```

> Resume actions (the old "Next") go in the session `## To-Do-List`, not in this block — `sr` reads that on resumption.
> **Vault binding:** the session file is `<VAULT>/sessions/<uid>.md`, created by `ss` as `status: active` and left by this skill at `status: parked`. git = SOT (git-convention). **Writing this block to the file is `scribe`** (step-4 delegation); **committing is the PM** (step 7 — record then commit, commit-only, no push).

## Key Rules

- **Update the document first** — the vault is the source of truth. The park entry is the permanent record.
- **User direction > agent analysis** — if the user stated the next focus, that wins.
- **Progress = resume data** — canonical structure, canonical location, newest on top.
- **Scan pending markers before resume actions.**

## Before Writing: Scan for Pending Markers

**Always** grep the active session files for pending markers **before** settling the `## To-Do-List` content, so nothing slips silently between sessions. **This scan is read-only, so the PM runs it directly.**

```bash
# zsh: a glob with no match errors out → enumerate with find. index.md/_index.md = folder TOCs, not sessions — exclude both spellings.
find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" ! -name "_index.md" 2>/dev/null \
  -exec grep -nH 'USER-COMMENT\|NEEDS USER INPUT\|TODO\|FIXME\|NEEDS CLARIFICATION' {} +
```

Spell out found markers in `## To-Do-List`: **Where** (file:line/section) · **What** (one-line summary) · **Who** (user approval? agent proceeds?). — The PM organizes; **writing to the file is `scribe`** (shipped in the step-4 brief).

## Knowledge Promotion (before writing the park entry)

Read `${CLAUDE_SKILL_DIR}/../_session-shared/knowledge-promotion.md` and follow it as written. (Summary: **delegate to `scribe` → `scribe` auto-selects·promotes via the two-gate judgment (score gate sum ≥ 3 + similar-note verdict)** (no approval asked — **only `common/policies/` candidates are batched for the user's signature**) → trigger-first notes in `<project>/knowledge/` → the session Learned gets only `→ promoted: [[..]]` links. Dedup is Dreaming's job.)

> The step-3 delegation's scope is **knowledge promotion only** — its scope differs from step 4, so there is no overlap (step 3: `<project>/knowledge/`, step 4: `<VAULT>/sessions/<uid>.md`). The two delegations may be merged into one `scribe` call — specifying both scopes in the brief cuts round trips.
