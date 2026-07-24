---
name: sc
description: Close a work session — flip status to done (cancel if abandoned), write the closing entry, and finalize knowledge promotion. Use when the user says "sc", "session complete", "세션 종료", "세션 완료", "이 작업 끝", "마감", "세션 닫기". If just pausing to resume later, use sh instead of sc.
argument-hint: "[session-file?]"
---

# sc — Session Complete

> **When in doubt, present the fork first.** If context or arguments are too thin, present a one-liner and get their pick: which do you want — `ss` (start) / `sh` (park/handoff) / `sc` (complete)?

**Closes** a work session. This is a hard-to-reverse state transition, so do not skip the confirmation steps below before transitioning.

## Write boundary — common to the 3 session skills

All three of `ss` · `sh` · `sc` share **executor = PM (main session), vault content writes = the `scribe` worker** (a subagent handed a writing brief — not resident). The PM does **reading·detection·judgment** — session discovery (`find`/`grep`), user Q&A, **deciding what to record** — and directly executes **the vault git commit (⑦)** (commit executor = PM, canon: `${CLAUDE_SKILL_DIR}/../../docs/versioning-convention.md`). Every step that leaves vault content — closing entry · `status` transition · frontmatter · knowledge-promotion finalization · `knowledge/index.md` — is **delegated to `scribe`** — a discipline (recording consistency + main-context economy), with governance canon at `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Hard rule — the sh vs sc boundary

- **Only this skill flips `status` to `done` (or `cancel`).** Closure only.
- If the work isn't ending — just pausing to resume later — stop here and point to `sh`. Park keeps `status: active`.

## Flow

### ① Settle the target session
Settle the `status: active` session worked on in this conversation (`<VAULT>/sessions/<uid>.md`). If a session file path was given as an argument, use that. If no session is clear from the conversation, present the project's `status: active` candidates and let the user choose (no guessing). (`VAULT` = the `vault-root` in the project's `CLAUDE.local.md` — if missing, ask the user and point to `/brain:init`. If project inference is needed, Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md`.)

### ② Pending-marker scan
Grep the target session for pending markers:
```bash
# zsh: a glob with no match errors out → enumerate with find
find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null \
  -exec grep -nH 'USER-COMMENT\|NEEDS USER INPUT\|TODO\|FIXME\|NEEDS CLARIFICATION' {} +
```
If markers remain, do not close as-is — ask:
> N unresolved markers remain (list locations·content). Close anyway? (y/n)
On n, stop and point to marker handling or `sh` (park).

### ③ Confirm the closure mode — done vs cancel
- Goal achieved, normal closure → `done`.
- Goal **abandoned·dropped** (not continuing) → `cancel`.
- **Verification/review still pending but the work itself is finished** → set status to `done`, leave the remaining verification items open in the session `## To-Do-List`, and add `needs-review` to `tags`. (The status vocabulary is only the 3 values `active|done|cancel` — pending-verification is a tag/To-Do-List matter, not a status.)

Judge done/cancel from the session's open To-Dos and the user's stated closure intent; if ambiguous, confirm with the user.

### ④ Knowledge promotion (finalize mode, `scribe` delegation)
Read `${CLAUDE_SKILL_DIR}/../_session-shared/knowledge-promotion.md` and execute it. **Delegate to the `scribe` worker** for **automatic promotion** (`scribe` selects via the score gate, no approval asked). Same as park (`sh`) — closure adds no approval gate (automatic; dedup is Dreaming's job).

**Policy signature batch** — the one exception: if `scribe` returns `common-policy candidates`, present **the whole list once** here (knowledge-promotion Step 4) and hand only the approved ones to a follow-up `scribe` brief writing `000_common/policies/`. `common/policies/` is the sole tier no agent may write on its own — **agents draft, the user signs** (`${CLAUDE_SKILL_DIR}/../../docs/knowledge-escalate-convention.md`). No candidates → no prompt; **never ask per item.**

Writing the promoted notes · appending one line to `knowledge/index.md` · logging non-promoted items to `0.rejected.md` are **all done by `scribe`** (the skill passes only the raw Learned lines plus `vault-root`·`project`·`uid`·today's date). Use the **promoted note titles** `scribe` returns in ⑤'s `→ promoted: [[…]]` links — so the links point to notes that actually exist.

### ④b Document check (detection + routing only — no auto-writing, no new files)
If this session's `Outputs` touched **architecture, API surface, deployment, or schema**, pick the affected document(s) from `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` and either (a) fold the document update into the outgoing ⑤·⑥ `scribe` brief (content = what the Handoff actually produced, routed per the catalog's owner label) or (b) leave it as an open item in the session `## To-Do-List`. Never fabricate document content the session did not produce — generating content that doesn't exist is fabrication, not recall (`skills/dreaming/SKILL.md` §stub-scan). This check lives in `sc` only — park (`sh`) is frequent and cheap; closure is the natural document boundary.

### ⑤·⑥ Closing entry + frontmatter transition (`scribe` delegation — together in one call)
Both touch the same file (`<VAULT>/sessions/<uid>.md`) and the **executor is `scribe`**, so **delegate them in a single `scribe` call** (calling separately reopens the same file and only adds round trips). The skill **decides the content and hands it over**; `scribe` writes.

**Writing brief — hand the following to `scribe` as-is:**

- **Target file**: `<VAULT>/sessions/<uid>.md` (the path settled in ①)
- **Context**: `vault-root` · `project` · session `uid` · today's date · the ③ verdict (`done` / `cancel`, whether verification is pending)
- **(⑤) Closing Progress entry** — insert **at the top of** `## Progress` (newest-on-top). Canonical `#### ` structure (canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`). The `(completed)` heading suffix is the closure token from the status-suffix vocabulary (canon: sessions-note-convention §Progress entry status suffix) — used for `done` and `cancel` alike; never put a non-status description in the suffix.
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
- **(⑥) Frontmatter update**:
  - Flip `status:` to `done` (or `cancel`). Replace **only the `status:` line inside the frontmatter block** — the body Progress may also contain the string `status:`, so a naive global replace misfires.
  - `updated:` to today. (Legacy fields like `end_date`/`start_date`/`date` are not in the schema — do not create them.)
  - If ③ judged verification pending, add `needs-review` to `tags:`.
- **Return requirement**: the recorded file path + the final `status` value.

⚠ The `status` transition happens **only in this delegation** — the PM does not patch it directly with `sed`/redirection (vault content writes belong to `scribe`, as a discipline).

### ⑦ git commit (vault snapshot — commit-only, executor = PM)
The PM commits the vault directly **after** the ④·⑤·⑥ `scribe` writes are done — **record → commit order** (committing first leaves the just-written closing entry·`status` transition out of the snapshot). Commit executor = PM is canon (versioning-convention — a commit is not content authorship but a **boundary record**, and it swallows the whole repo, so only whoever sees the whole can do it safely. `scribe` never commits).

- **Check the message convention before committing (no guessing)** — read **that vault's existing convention first** with `git -C "$VAULT" log --oneline -10` and follow it (conventions differ per vault). The following is only the shape used when no convention exists, not a mandated format:
  ```bash
  git -C "$VAULT" add -- <paths…> && git -C "$VAULT" commit -q -m "session <uid>: completed — <one-line gist>"
  ```
- **Stage only the paths this session wrote — `git add -A` is forbidden.** One vault is shared by concurrent sessions of other projects; `-A` sweeps their in-flight work into this session's commit under this session's message.
- **The pathspec = what the scribes returned** — the ⑤·⑥ session file `<VAULT>/sessions/<uid>.md` + the ④ promoted note paths + `<project>/knowledge/index.md`·`0.rejected.md` when touched. If a return omitted a path, ask that scribe; never widen the pathspec to compensate.
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

- **`obsidian create` / `obsidian-cli create` CLI is absolutely forbidden** — `Write`/`Edit` tools only (duplicate-file bug). **An existing file is changed with `Edit`; `Write` is for creating a file that does not exist yet** — `Edit`'s `old_string` is a compare-and-swap, so if a concurrent session moved the anchor the edit fails loudly instead of silently swallowing their work. The party doing that write is the `scribe` worker.
- Touch only **the paths under `vault-root` in `CLAUDE.local.md` + the `<project>/knowledge/` that `scribe` writes during promotion**. All other folders·other vaults are off-limits.
- **The `status` vocabulary is exactly** `active` / `done` / `cancel`. Pending-verification·blocked go in tags/`## To-Do-List` open items, not in status.
