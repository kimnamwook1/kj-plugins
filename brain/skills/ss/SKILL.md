---
name: ss
description: Start a NEW vault-tracked work session as a single file — mint the filename, write the session note with `status: active`, and inject the folder indexes into `## Recall`. Always creates; never resumes. Use when the user says "ss", "session start", "세션 시작", "세션 만들어", "새 세션", "작업 시작 기록", or is about to start tracked work. To resume a parked session use sr; to see which sessions are parked use sl.
argument-hint: "[project] [title...]"
---

# ss — Session Start (new session only)

> **When in doubt, present the fork first.** If context or arguments are too thin to be sure the user really wants to *start a new* session, present a one-liner and get their pick: which do you want — `ss` (start new) / `sr` (resume a parked one) / `sl` (just list what is parked) / `sh` (park/handoff) / `sc` (complete)?

Creates a session in the vault as a **single file**. A session is a self-contained episodic capture — schema canon is `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`; tree/naming is `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md`.

## Where this skill fits in the workflow

**One verb, one skill.** `ss` creates and only creates.

1. **`ss`** (this skill) — create the session file, `status: active`, inject recall.
2. **`sr`** — resume a parked session. **The only path back into one.**
3. **`sl`** — list parked sessions, read-only.
4. **`sh`** — when pausing/handing off work: scan pending markers, add a park entry to `## Progress`. **`status: active` → `parked`.** Park does not promote.
5. **`sc`** — when closing work: closing entry + **`status: done`** (an abandoned session is `done` + an `abandoned` tag — there is no `cancel`).

> **`ss` never scans for parked sessions and never announces them (KJP-43).** Measured 2026-07-25 on the reference vault: 11 of 11 projects held exactly one open session, so a project-scoped scan matched on essentially every invocation — a fork question, a ~6 KB extract per candidate, and a user round-trip charged to someone who asked to *start* something. Not even a "N parked sessions exist" line belongs here. Someone who wants to resume types `sr`.

> **Common to all session skills — executor = PM (main session), vault content writes = the `scribe` worker.** The PM does **reading, detection, judgment** — filename minting (`date`) · existence checks · user Q&A · performing recall (read) · **deciding what to record**. Creating/modifying vault files is **delegated to the `scribe` worker via a writing brief** (`Agent` tool — specify "what · to which path · with what content"). `scribe` is not a resident agent but a subagent handed a writing brief. Governance canon: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md` · commit discipline: `${CLAUDE_SKILL_DIR}/../../docs/git-convention.md`.

## Resolving Vault·Project

1. **Resolve VAULT** — `VAULT` = the `vault-root` value defined in the project's `CLAUDE.local.md`. **If missing, ask the user for the vault root and point them to `/brain:init` onboarding** — never write to an arbitrary path.

2. **Resolve project** — if a first argument is given, that is the project override. Otherwise Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md` and resolve by its rules (config `project:` first, then cwd). If inference fails, do not guess — ask the user.

3. **Verify the vault exists** — check that `VAULT` is a directory. **If not**: inform the user and stop — "The vault doesn't exist yet. Create it with `/brain:init`, or use a different path?" — never write to some other vault on your own.

4. **Ensure the project folder** (idempotent) — create the project folder if missing. Do not depend on onboarding (`/brain:init`) — sessions must not be blocked. **The PM only does existence checks and next-number computation (reads); creation is delegated to `scribe`.**

   **(a) PM — existence check + number computation (read-only):**
   ```bash
   # Where project folders live is a per-vault fact (`.brain-paths` → projects_root), not a literal here:
   # in one vault they sit at the vault root, in another under `projects/`. Hardcoding it is what made this
   # lookup return nothing after a restructure — the session then created a duplicate project folder.
   . "${CLAUDE_SKILL_DIR}/../../scripts/vault-paths.sh"   # → brain_project_dir · brain_next_project_num · BRAIN_PROJECTS
   # Both helpers exclude the reserved `9xx` infra band (`999_tools` and the like) — numeric-prefixed, but not
   # projects (vault-tree.md §Reserved number bands). Without that a project slugged `tools` resolves straight
   # onto `999_tools/` and scribe writes its knowledge into the gitignored tool inventory; and the number
   # computation yields next=**1000**, a 4-digit prefix the `NNN_` convention does not allow (measured).
   PROJDIR=$(brain_project_dir "<project>")               # existing NNN_<project>, empty if absent
   if [ -z "$PROJDIR" ]; then
     PROJDIR="$BRAIN_PROJECTS/$(brain_next_project_num)_<project>"   # always NNN_-prefixed. Plain names forbidden.
   fi
   # hub TOC = _index.md (canonical); a legacy index.md is its equal — accept either (vault-tree.md)
   [ -d "$PROJDIR/p_memory" ] && { [ -f "$PROJDIR/_index.md" ] || [ -f "$PROJDIR/index.md" ]; } && echo OK || echo NEEDS_SCRIBE
   ```
   > The `printf '%03d'` above is **for computing a variable** (not a file write) — no redirection. Computation is a read, so the PM may do it.

   **(b) If `NEEDS_SCRIBE`, delegate to `scribe`** — writing brief (what the PM decides and hands over):
   - `vault-root`: `<VAULT>` · `project`: `<project>` · the resolved `PROJDIR` path (the `NNN_<project>` computed above).
   - What to create: directory `<PROJDIR>/p_memory/` (plus its `_index.md`) · file `<PROJDIR>/_index.md` (only if missing — a legacy `<PROJDIR>/index.md` counts as the hub, never create `_index.md` beside it; content = project hub — one-line definition + `PREFIX: <value>` + table-of-contents pointers only, canon `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` §Project hub). The PM confirms the PREFIX value with the user and puts it in the brief (suggested default = uppercase abbreviation of the project slug).
   - **Idempotent** — if it already exists, `scribe` does nothing (no overwriting).
   - Use the path `scribe` returns as `PROJDIR` for the later steps.

## Steps

1. **Settle title·goal** — if argument text remains, that is the goal; otherwise take it from the session goal the user stated.

   > **No worktree question (KJP-42).** A PM session always runs in the current working tree. Isolation is the **`coder` agent's** job and is already automatic via its `isolation: worktree` frontmatter — asking here duplicated a decision nobody makes at session start. `git_worktree` **stays in the schema** (it can carry a coder's worktree path when something later records one), but **`ss` always writes it empty**.

2. **Write the session file** — **filename minting·field collection = PM (reads), the file Write is delegated to `scribe`.**

   **(a) PM — filename mint + field collection (read-only):**
   - **PREFIX** — Read the project prefix recorded in the project hub `<PROJDIR>/_index.md` (or the legacy `<PROJDIR>/index.md`, where that is the hub). If missing, confirm with the user and include writing it into the hub in the (b) brief.
   - **filename = `<PREFIX>_YYYYMMDD_<slug>.md`** (canon: sessions-note-convention). There is no `uid:` key — the filename *is* the identifier. `<slug>` is a short kebab-case reduction of the session Goal (≤5 words, ASCII-safe); `<PREFIX>` carries global wikilink uniqueness.
   - 🔴 **Same day + same slug is forbidden** — uniqueness is a **creation-time check**, not a timestamp guarantee. If the path already exists, do not silently suffix it: report the collision and ask the user for a distinguishing slug.
   ```bash
   name="<PREFIX>_$(date +%Y%m%d)_<slug>"
   [ -e "$VAULT/hippocampus/$name.md" ] && echo "COLLISION: $name.md — ask the user for a different slug" || echo "OK"
   ```
   - Sessions created before 0.2.0 use the retired `<PREFIX>-YYYYMMDD-HHMMSS.md` shape. **They are not renamed** — same-day collisions make 3 groups of them indistinguishable (measured 2026-08-05: 9 groups / 23 files). Both shapes coexist in `hippocampus/`; `sr`/`sl` read the frontmatter, not the filename.
   - Collect the current CC session id **if obtainable** (otherwise leave the list empty).

   **(b) Delegate to `scribe`** — "Write `<VAULT>/hippocampus/<name>.md` **exactly per the schema below** (a single file, not a folder)". Pass the settled values in the brief (project·updated·related_ticket·cc_session_ids·Goal text). Schema/frontmatter canon = `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`:
   ```markdown
   ---
   status: active
   project: <project>
   updated: <YYYY-MM-DDTHH:MM:SS>
   related_ticket: <system>:<id>
   cc_session_ids:
     - <current CC session id; leave the list empty if unavailable>
   ---

   ## Goal
   <the user's goal — smallest achievable unit>

   ## Recall
   <!-- step 3 injects the folder indexes here -->

   ## To-Do-List
   -

   ## Progress
   <!-- By date, newest on top. Headings: ### YYYY-MM-DD → #### Done/Mistake/Learned/Outputs -->
   ```
   - **5 keys, all of them.** `uid` · `created` · `writer` · `tags` are retired — never write them.
   - `cc_session_ids:` = one line with the current CC session id. If unobtainable, leave the list empty.
   - Use the session file path `scribe` returns in the step-4 report.

3. **Recall injection** — **performing it (read) = PM, injecting it (write) = `scribe` delegation.**
   - **(a) PM — perform recall (read)**: Read `${CLAUDE_SKILL_DIR}/../_session-shared/recall.md` and execute it. `VAULT` and `<project>` must already be set. It injects every relevant `_index.md` whole — no goal string, no ranking, no cap. **Always report the file count and total bytes**, 0 included.
   - **(b) Delegate to `scribe` — inject (write)**: inject the recall output into `## Recall` of the file created in step 2. Brief: target path · the block body · **append to the `## Recall` section only; other sections and frontmatter unchanged**.
   - Steps 2 and 3 **may be merged into a single `scribe` call** (specify file creation + Recall injection together) — fewer round trips.

4. **Report** — report the created session path (`<VAULT>/hippocampus/<name>.md`) plus project·vault, and the recall file count and byte total.

## Hard rules

- **Create only. `ss` never resumes and never lists.** No parked-session scan, no fork question, **not even a "you have N parked sessions" notice** — that is `sr` and `sl` (KJP-43). If the user actually wanted to resume, name `sr` and stop; do not resume from here.
- **The session file is created with `Write`, never `obsidian create`** — canon: `${CLAUDE_SKILL_DIR}/../_session-shared/vault-io.md` (§1 write rule · §2 why `create` is banned · §3 which CLI this is). **The party doing that write is the `scribe` worker** — the PM never writes vault **content** directly (governance canon: memory-control-convention §Governance).
- **Write only under the `vault-root` in `CLAUDE.local.md`** — any other path or other vault is off-limits.
- **The `status` vocabulary is exactly:** `active` / `parked` / `done` (3 values). **`ss` only ever writes `active`** — `parked` is `sh`'s, `done` is `sc`'s. Other states (abandoned·pending-verification·blocked) go in the Progress entry or as open `## To-Do-List` items, not in status.
- **Session = a single file** — `hippocampus/<PREFIX>_YYYYMMDD_<slug>.md`. Not a folder.
