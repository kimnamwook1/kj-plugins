# Versioning (git-centric)

> Document conventions → [[project-docs-convention]] · tree → [[vault-tree]]

- **git = SOT + version control** — history, diff, revert, blame, **rollback**: all git.
- **Cross-device sync uses a single channel only** — if two systems both sync across devices, conflicts follow (`git pull` = dirty/merge conflicts).
- **Two concurrency layers**: within a machine = `scribe` discipline (no locks — the PM delegates without overlap) / between machines = git merge (member integration).
- **Committer = the PM**, timing = the session lifecycle (handoff · complete). `scribe` never commits — a commit swallows the whole repo, sweeping in other `scribe` workers' unfinished work.
- **No auto-commits** — committing via per-write hooks (PostToolUse) turns history into tool-call-level noise and erases revert points.
- **Push only when the user explicitly says so.**

## Exception to the PM No-Write Rule

- **`git add` and `git commit` are done by the PM.** The PM never writes vault **content** (that's `scribe`). A commit is not content authorship but a **boundary record**, and since a commit swallows the whole repo, only the one who sees the whole can do it safely.
