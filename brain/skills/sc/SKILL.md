---
name: sc
description: Close a work session — flip status to done, write the closing entry, and finalize knowledge promotion. An abandoned session closes as done plus an abandoned tag; there is no cancel status. Use when the user says "sc", "session complete", "세션 종료", "세션 완료", "이 작업 끝", "마감", "세션 닫기". If just pausing to resume later, use sh instead of sc.
argument-hint: "[session-file?]"
---

# sc — Session Complete

> **When in doubt, present the fork first.** If context or arguments are too thin, present a one-liner and get their pick: which do you want — `ss` (start new) / `sr` (resume a parked one) / `sl` (just list what is open) / `sh` (park/handoff) / `sc` (complete)?

**Closes** a work session. This is a hard-to-reverse state transition, so do not skip the confirmation steps below before transitioning.

## Write boundary — common to the 3 session skills

All three of `ss` · `sh` · `sc` share **executor = PM (main session), vault content writes = the `scribe` worker** (a subagent handed a writing brief — not resident). The PM does **reading·detection·judgment** — session discovery (`find`/`grep`), user Q&A, **deciding what to record** — and directly executes **the vault git commit (⑦)** (commit executor = PM, canon: `${CLAUDE_SKILL_DIR}/../../docs/git-convention.md`). Every step that leaves vault content — closing entry · `status` transition · frontmatter · knowledge-promotion finalization · `knowledge/_index.md` — is **delegated to `scribe`** — a discipline (recording consistency + main-context economy), with governance canon at `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Hard rule — the sh vs sc boundary

- **Only this skill writes `status: done`.** Closure only, and `done` is the only value it ever writes (KJP-48 retired `cancel`).
- If the work isn't ending — just pausing to resume later — stop here and point to `sh`. Park writes `status: parked`, which keeps the session open for `sr`.

## Flow

### ① Settle the target session
Settle the open (`status: active` or `parked`) session worked on in this conversation (`<VAULT>/sessions/<uid>.md`). If a session file path was given as an argument, use that. If no session is clear from the conversation, present the project's open candidates — both states, via the shared scan (`${CLAUDE_SKILL_DIR}/../_session-shared/active-sessions.md` §1, state marker included) — and let the user choose (no guessing). **Closing a `parked` session directly is normal** — work often turns out to be finished only after it was parked, and requiring an `sr` round-trip first would buy nothing. (`VAULT` = the `vault-root` in the project's `CLAUDE.local.md` — if missing, ask the user and point to `/brain:init`. If project inference is needed, Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md`.)

### ② Pending-marker scan
Grep the target session for pending markers:
```bash
# zsh: a glob with no match errors out → enumerate with find. index.md/_index.md = folder TOCs, not sessions — exclude both spellings.
find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" ! -name "_index.md" 2>/dev/null \
  -exec grep -nH 'USER-COMMENT\|NEEDS USER INPUT\|TODO\|FIXME\|NEEDS CLARIFICATION' {} +
```
If markers remain, do not close as-is — ask:
> N unresolved markers remain (list locations·content). Close anyway? (y/n)
On n, stop and point to marker handling or `sh` (park).

### ③ Confirm closure — the status is always `done`; the *outcome* goes in tags

**Every closure writes `status: done`.** There is no second closing value to choose between (KJP-48): `status` answers "is this session still open", and a closed session is closed whether or not its goal was reached. Outcome lives in `tags:`.

- Goal achieved, normal closure → `done`, no outcome tag.
- Goal **abandoned·dropped** (not continuing) → `done` + **`abandoned`** in `tags:`. Say why in the ⑤ closing entry's `**Final state:**` line — the tag marks it, the entry explains it. **Never `status: cancel`** — retired; `validate.sh` reports it.
- **Verification/review still pending but the work itself is finished** → `done`, leave the remaining verification items open in the session `## To-Do-List`, and add `needs-review` to `tags`.

The status vocabulary is only the 3 values `active|parked|done` — abandonment, pending-verification and blocked are all tag/`## To-Do-List` matters, not statuses.

Judge the outcome tag from the session's open To-Dos and the user's stated closure intent; if ambiguous, confirm with the user. **The abandoned/achieved call is the only judgment here — never let ambiguity about it stall the closure itself**, since the status is `done` either way.

### ④ Knowledge promotion (finalize mode, `scribe` delegation)
Read `${CLAUDE_SKILL_DIR}/../_session-shared/knowledge-promotion.md` and execute it. **Delegate to the `scribe` worker** for **automatic promotion** (`scribe` selects via the two-gate judgment, no approval asked). Same as park (`sh`) — closure adds no approval gate (automatic; dedup is Dreaming's job).

**Policy signature batch** — the one exception: if `scribe` returns `common-policy candidates`, present **the whole list once** here (knowledge-promotion Step 4) and hand only the approved ones to a follow-up `scribe` brief writing the vault common layer's `policies/` (`BRAIN_COMMON/policies` — `.brain-paths`, resolved by `scripts/vault-paths.sh`). `common/policies/` is the sole tier no agent may write on its own — **agents draft, the user signs** (`${CLAUDE_SKILL_DIR}/../../docs/knowledge-escalate-convention.md`). No candidates → no prompt; **never ask per item.**

Writing the promoted notes · appending one line to `knowledge/_index.md` (legacy `index.md` equal — vault-tree.md) · logging non-promoted items to `0.rejected.md` are **all done by `scribe`** (the skill passes only the raw Learned lines plus `vault-root`·`project`·`uid`·the current local datetime — `YYYY-MM-DDTHH:MM:SS`, what `updated:` stamps take). Use the **promoted note titles** `scribe` returns in ⑤'s `→ promoted: [[…]]` links — so the links point to notes that actually exist.

**Feedback counters (same delegation — KJP-7)** — the PM extracts the injected-note list from the session's `## Context` recall block (the canonical injected-notes record — `recall.md` §Injection; grep, read-only) and judges **which of those notes were actually used this session**. The brief has `scribe` bump `recalled:` +1 on every injected note and `useful:` +1 on the used subset — Edit-based (+1 on the literal current value; absent field → insert at 1), **once per session**, guarded by the Context counter-marker line (a prior `sh` may already have written it — then only the `useful:` top-up applies). Semantics·marker format·exclusions (`[M]` session lines · the common layer's `policies/` — `BRAIN_COMMON/policies`) canon: `${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters. The marker line itself lands in `## Context` through the ⑤·⑥ brief (the session file is that delegation's scope).

### ④b Document check (detection + routing only — no auto-writing; a new file only from a Handoff draft)
If this session's `Outputs` touched **architecture, API surface, deployment, or schema**, pick the affected document(s) from `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` and either (a) fold the document update into the outgoing ⑤·⑥ `scribe` brief (content = what the Handoff actually produced, routed per the catalog's owner label) or (b) leave it as an open item in the session `## To-Do-List`. **If a worker Handoff carried a `Docs draft` section** (worker/coder profiles — canon: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md` §Handoff Format), the scribe brief carries that draft **verbatim** — the PM routes, never rewrites (scribe copies, never authors). **Any document update or creation folded into the brief also appends its frontmatter `history:` row** (the ⑤·⑥ brief's docs-`history:` bullet — canon: `${CLAUDE_SKILL_DIR}/../../docs/project-docs-convention.md` §history). **A draft for a document that does not exist yet rides the same brief** — the PM checks the catalog trigger and the scribe brief creates the file (`Write`); a new document comes only from a draft the session actually produced, never as an empty stub. Never fabricate document content the session did not produce — generating content that doesn't exist is fabrication, not recall (`skills/dreaming/SKILL.md` §stub-scan). This check lives in `sc` only — park (`sh`) is frequent and cheap; closure is the natural document boundary.

### ⑤·⑥ Closing entry + frontmatter transition (`scribe` delegation — together in one call)
Both touch the same file (`<VAULT>/sessions/<uid>.md`) and the **executor is `scribe`**, so **delegate them in a single `scribe` call** (calling separately reopens the same file and only adds round trips). The skill **decides the content and hands it over**; `scribe` writes.

**Writing brief — hand the following to `scribe` as-is:**

- **Target file**: `<VAULT>/sessions/<uid>.md` (the path settled in ①)
- **Context**: `vault-root` · `project` · session `uid` · the current local datetime (`YYYY-MM-DDTHH:MM:SS`) · the ③ verdict (which outcome tags apply — `abandoned` and/or `needs-review`; the status is `done` regardless)
- **(⑤) Closing Progress entry** — insert **at the top of** `## Progress` (newest-on-top). Canonical `#### ` structure (canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`). The `(completed)` heading suffix is the closure token from the status-suffix vocabulary (canon: sessions-note-convention §Progress entry status suffix) — **the same token for an abandoned closure as for an achieved one** (the suffix records that the session closed; *how it went* is the `abandoned` tag plus the `**Final state:**` line). Never put a non-status description in the suffix.
  ```markdown
  ### YYYY-MM-DD (completed)
  **Final state:** final state / verification result (one line).
  #### Done
  - What was ultimately achieved.
  #### Learned
  - Promoted items are links only: → promoted: [[Note Title]]
  #### Outputs
  - `path/to/output` — what it is
  ```
  (Include Mistake/Fixed if this closing session has any; omit otherwise. The Learned links must match the note titles `scribe` actually promoted in ④.)
- **`## Context` counter marker**: if ④ bumped feedback counters, append (or extend, via Edit) the counter-marker line at the end of the recall block — format canon: `${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters. Touch nothing else in Context.
- **(⑥) Frontmatter update**:
  - Flip `status:` to `done`. Replace **only the `status:` line inside the frontmatter block** — the body Progress may also contain the string `status:`, so a naive global replace misfires. The prior value may be `active` **or** `parked`; both close to `done`.
  - `updated:` to the current local datetime (`YYYY-MM-DDTHH:MM:SS` — canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md` §updated). (Legacy fields like `end_date`/`start_date`/`date` are not in the schema — do not create them.)
  - Add the ③ outcome tags to `tags:` — `abandoned` if the goal was dropped, `needs-review` if verification is pending. Neither, either, or both.
- **Docs `history:` row (only when this session modified a project `docs/` document — a ④b update or creation riding this brief included)**: for each such document, append one row to its frontmatter `history:` — `- {at: <datetime>, change: <one line>, ticket: <related ticket — omit when none>}` (canon: `${CLAUDE_SKILL_DIR}/../../docs/project-docs-convention.md` §history — frontmatter v2's only provenance channel, so a skipped row leaves the edit unattributable; `history.session` is banned, the session uid stays out).
- **Return requirement**: the recorded file path + the final `status` value + any docs paths that received a `history:` row.

⚠ The `status` transition happens **only in this delegation** — the PM does not patch it directly with `sed`/redirection (vault content writes belong to `scribe`, as a discipline).

### ⑦ git commit (vault snapshot — commit-only, executor = PM)
The PM commits the vault directly **after** the ④·⑤·⑥ `scribe` writes are done — **record → commit order** (committing first leaves the just-written closing entry·`status` transition out of the snapshot). Commit executor = PM is canon (git-convention — a commit is not content authorship but a **boundary record**, and it swallows the whole repo, so only whoever sees the whole can do it safely. `scribe` never commits).

- **Check the message convention before committing (no guessing)** — read **that vault's existing convention first** with `git -C "$VAULT" log --oneline -10` and follow it (conventions differ per vault). The following is only the shape used when no convention exists, not a mandated format:
  ```bash
  git -C "$VAULT" add -- <paths…> && git -C "$VAULT" commit -q -m "session <uid>: completed — <one-line gist>"
  ```
- **The pathspec = what the scribes returned** — the ⑤·⑥ session file `<VAULT>/sessions/<uid>.md` + the ④ promoted note paths + `<project>/knowledge/_index.md`·`0.rejected.md` when touched + the ④ counter-bumped note paths (these may sit outside `<project>/` — `[C]`/`[X]` notes). If a return omitted a path, ask that scribe; never widen the pathspec to compensate.
- **Leave every other dirty file dirty** — do not stage, stash, or revert anything outside that list, however unrelated-looking the diff. It is another session's unfinished work.
- **Read `git -C "$VAULT" status --porcelain` before staging.** If dirty files reach beyond this session's own paths, say so in ⑧ (`N files dirty across M directories — staged only this session's`) and stage from the pathspec anyway. A report, not a gate — never block the closure on it.
- **commit-only — `git push` is forbidden.** The vault carries session raw text (repo names·SHAs·infra topology·secret candidates) verbatim. Local commit is where this skill's job ends; **remote exposure is the user's call** — even on an explicit user request this skill does not push automatically.
- **On "nothing to commit", move on quietly** (not a failure). Same if the vault is not a git repo — just mention it in ⑧.
- **Scope is `$VAULT` only** — pinned via `git -C "$VAULT"`. Do not touch other repos or paths outside the vault.

If the commit fails or is skipped for any reason, **do not block the closure itself** — the record already landed in the vault in ④·⑤·⑥. Just report the uncommitted state in ⑧.

### ⑧ Confirmation output
```
Session closed: <VAULT>/sessions/<uid>.md (status: done) · vault committed
```
(If ⑦ was skipped, replace `· vault committed` with `· vault uncommitted (manual commit needed)`.)

## Hard rules

- **The closing writes go through `Write`/`Edit`, never a CLI write** — canon: `${CLAUDE_SKILL_DIR}/../_session-shared/vault-io.md` §1. The party doing that write is the `scribe` worker.
- Touch only **the paths under `vault-root` in `CLAUDE.local.md` + the `<project>/knowledge/` that `scribe` writes during promotion**. All other folders·other vaults are off-limits.
- **The `status` vocabulary is exactly** `active` / `parked` / `done`. Abandoned·pending-verification·blocked go in tags/`## To-Do-List` open items, not in status.
