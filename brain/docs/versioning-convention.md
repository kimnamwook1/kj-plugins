# Versioning (git-centric)

> Document conventions → [[project-docs-convention]] · tree → [[vault-tree]]

- **git = SOT + version control** — history, diff, revert, blame, **rollback**: all git.
- **Share scope** — the team-shared surface is project trees (`NNN_*/`) + `000_common/`; **`sessions/` sits outside it** — an episodic log scoped to the individual, not the team. Defining that scope is separate from enforcing it: **whether to commit sessions is a per-vault choice** — a team-shared vault gitignores `sessions/` (episodic logs are personal, never pushed), a solo vault may track them (the commit doubles as backup). Because a session can be absent from the shared surface, shared notes reference sessions as **plain uid text, never `[[wikilink]]`** (a session wikilink dangles in any teammate's vault that lacks it).
- **Cross-device sync uses a single channel only** — if two systems both sync across devices, conflicts follow (`git pull` = dirty/merge conflicts).
- **Two concurrency layers**: within a machine = `scribe` discipline (no locks — the PM delegates without overlap) / between machines = git merge (member integration).
- **Committer = the PM**, timing = the session lifecycle (handoff · complete). `scribe` never commits — a commit swallows the whole repo, sweeping in other `scribe` workers' unfinished work.
- **No auto-commits** — committing via per-write hooks (PostToolUse) turns history into tool-call-level noise and erases revert points.
- **Push only when the user explicitly says so.**

## Worktree integration order (PM)

**Confirm the merge, then delete. Never the reverse.**

1. **`git worktree remove <path>`** — a branch checked out in a worktree cannot be deleted at all, so this comes first.
2. **Merge** the coder's conventional branch (`<PREFIX>-<number>-<title-slug>`, reported on the first line of the Handoff's `Outputs`) into the integration branch.
3. **Delete with `git branch -d` — never `-D`.** `-d` refuses a branch that is not fully merged, so the tool enforces step 2 before step 3 on its own; that refusal *is* the confirmation. `-D` deletes the guard along with the branch, and an unmerged commit becomes unreachable the instant its last ref is gone.
4. The harness's leftover **`worktree-agent-<hash>`** branch goes the same way. It carries no commits of its own — it points at the base, an ancestor of the integration branch — so plain `-d` takes it, no force needed.

- Measured 2026-07-26 (KJP-45), all four behaviors: `-d` on a worktree-checked-out branch → `error: cannot delete branch … used by worktree at …`; `-d` on an unmerged branch → `error: the branch … is not fully merged`; `-D` on the same → deleted, commit orphaned; `-d` on an empty harness-style branch → deleted.
- **Why this is canon and not a preference** — 2026-07-25: a coder's base had diverged, the fast-forward failed, and cleanup deleted the branch **first**. Recovery came down to naming the commit object by hash.
- **A stale coder base is structural here, not carelessness.** Worktree branches are cut from `origin/<branch>` (measured 2026-07-26 — `branch: Created from origin/main` in the branch's own reflog), and this canon pushes only on the user's word, so `origin/` lags every local commit **by design**. The coder-side base check (`agents/coder.md` §First action) is the standing counterweight — **do not "fix" this by auto-pushing**, which would trade a checkable staleness for an unasked-for publish.

## Exception to the PM No-Write Rule

- **`git add` and `git commit` are done by the PM.** The PM never writes vault **content** (that's `scribe`). A commit is not content authorship but a **boundary record**, and since a commit swallows the whole repo, only the one who sees the whole can do it safely.
