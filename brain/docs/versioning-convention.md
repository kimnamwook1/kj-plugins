# Versioning (git-centric)

> Document conventions → [[project-docs-convention]] · tree → [[vault-tree]]

- **git = SOT + version control** — history, diff, revert, blame, **rollback**: all git.
- **Share scope** — the team-shared surface is project trees (`NNN_*/`) + `000_common/`; **`sessions/` sits outside it** — an episodic log scoped to the individual, not the team. Defining that scope is separate from enforcing it: **whether to commit sessions is a per-vault choice** — a team-shared vault gitignores `sessions/` (episodic logs are personal, never pushed), a solo vault may track them (the commit doubles as backup). Because a session can be absent from the shared surface, shared notes reference sessions as **plain uid text, never `[[wikilink]]`** (a session wikilink dangles in any teammate's vault that lacks it).
- **Cross-device sync uses a single channel only** — if two systems both sync across devices, conflicts follow (`git pull` = dirty/merge conflicts).
- **Two concurrency layers**: within a machine = `scribe` discipline (no locks — the PM delegates without overlap) / between machines = git merge (member integration).
- **Committer = the PM**, timing = the session lifecycle (handoff · complete). `scribe` never commits — a commit swallows the whole repo, sweeping in other `scribe` workers' unfinished work.
- **No auto-commits** — committing via per-write hooks (PostToolUse) turns history into tool-call-level noise and erases revert points.
- **Push only when the user explicitly says so.**

## Exception to the PM No-Write Rule

- **`git add` and `git commit` are done by the PM.** The PM never writes vault **content** (that's `scribe`). A commit is not content authorship but a **boundary record**, and since a commit swallows the whole repo, only the one who sees the whole can do it safely.
