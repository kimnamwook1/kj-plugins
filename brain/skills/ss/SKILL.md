---
name: ss
description: Start a vault-tracked work session as a single file. If a parked (in-progress) session exists, asks whether to resume it; otherwise creates a new one and injects related knowledge and past Mistakes into Context via recall. Use when the user says "ss", "session start", "세션 시작", "세션 만들어", "작업 시작 기록", or is about to start tracked work. Paired with sh (park/handoff) and sc (complete).
argument-hint: "[project] [title...]"
---

# ss — Session Start

> **When in doubt, present the fork first.** If context or arguments are too thin to be sure the user really wants to *start* a session, present a one-liner and get their pick: which do you want — `ss` (start) / `sh` (park/handoff) / `sc` (complete)?

Creates a session in the vault as a **single file**. A session is a self-contained episodic capture — schema canon is `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`; tree/naming is `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md`.

## Where this skill fits in the workflow

1. **`ss`** (this skill) — create the session file, `status: active`, inject recall.
2. **`sh`** — when pausing/handing off work: scan pending markers, promote knowledge, add a park entry to `## Progress`. **status stays active.**
3. **`sc`** — when closing work: closing entry + `status: done` (`cancel` if abandoned).

> **Common to all three skills — executor = PM (main session), vault content writes = the `scribe` worker.** The PM does **reading, detection, judgment** — session discovery (`find`/`grep`) · uid minting (`date`) · existence checks · user Q&A · performing recall (read) · **deciding what to record**. Creating/modifying vault files is **delegated to the `scribe` worker via a writing brief** (`Agent` tool — specify "what · to which path · with what content"). `scribe` is not a resident agent but a subagent handed a writing brief. Governance canon: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md` · commit discipline: `${CLAUDE_SKILL_DIR}/../../docs/versioning-convention.md`.

## Resolving Vault·Project

1. **Resolve VAULT** — `VAULT` = the `vault-root` value defined in the project's `CLAUDE.local.md`. **If missing, ask the user for the vault root and point them to `/brain:init` onboarding** — never write to an arbitrary path.

2. **Resolve project** — if a first argument is given, that is the project override. Otherwise Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md` and resolve by its rules (config `project:` first, then cwd). If inference fails, do not guess — ask the user.

3. **Verify the vault exists** — check that `VAULT` is a directory. **If not**: inform the user and stop — "The vault doesn't exist yet. Create it with `/brain:init`, or use a different path?" — never write to some other vault on your own.

4. **Ensure the project folder** (idempotent) — create the project folder if missing. Do not depend on onboarding (`/brain:init`) — sessions must not be blocked. **The PM only does existence checks and next-number computation (reads); creation is delegated to `scribe`.**

   **(a) PM — existence check + number computation (read-only):**
   ```bash
   PROJDIR=$(find "$VAULT" -maxdepth 1 -type d -name "*_<project>" 2>/dev/null | head -1)   # existing NNN_<project>
   if [ -z "$PROJDIR" ]; then
     # `[0-9]*_*` counts every numeric-prefixed folder — including `000_common`. Numbering is max-based,
     # so common (000) is the minimum and never bumps the number, and with zero projects next=001.
     n=$(find "$VAULT" -maxdepth 1 -type d -name '[0-9]*_*' 2>/dev/null | sed 's|.*/||;s|_.*||' | sort -n | tail -1)
     next=$(printf '%03d' $((10#${n:-0} + 1)))
     PROJDIR="$VAULT/${next}_<project>"   # project folders are **always NNN_-prefixed** (next number, 3 digits). Plain names forbidden.
   fi
   [ -d "$PROJDIR/knowledge" ] && [ -f "$PROJDIR/index.md" ] && echo OK || echo NEEDS_SCRIBE
   ```
   > The `printf '%03d'` above is **for computing a variable** (not a file write) — no redirection. Computation is a read, so the PM may do it.

   **(b) If `NEEDS_SCRIBE`, delegate to `scribe`** — writing brief (what the PM decides and hands over):
   - `vault-root`: `<VAULT>` · `project`: `<project>` · the resolved `PROJDIR` path (the `NNN_<project>` computed above).
   - What to create: directory `<PROJDIR>/knowledge/` · file `<PROJDIR>/index.md` (only if missing; content = project hub — one-line definition + `PREFIX: <value>` + table-of-contents pointers only, canon `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` §Project hub). The PM confirms the PREFIX value with the user and puts it in the brief (suggested default = uppercase abbreviation of the project slug).
   - **Idempotent** — if it already exists, `scribe` does nothing (no overwriting).
   - Use the path `scribe` returns as `PROJDIR` for the later steps.

## Steps

1. **Find in-progress (parked) sessions** — **before** creating anything, look for an active session in this project worth resuming. **This step is the system's only active-session detection point** (no SessionStart hook) — skip it and parked sessions are silently forgotten. In `<VAULT>/sessions/*.md`, match **both** frontmatter `status: active` + `project: <project>`:
   ```bash
   # zsh: a glob with no match errors out → enumerate with find (safe even on an empty vault)
   find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null | while read -r f; do
     grep -q '^status: active' "$f" && grep -qE "^project:[[:space:]]*<project>[[:space:]]*$" "$f" && echo "$f"
   done
   ```
   > dreaming reports (`session_type: dreaming`) also live in `sessions/` but **never match here** — they are written with `status: done` and an empty `project:`, so they fail both conditions (dreaming §Report format).

2. **Fork — resume vs create:**

   **0 matches** → go straight to creating a new session (step 4).

   **1+ matches** → present them and ask. **Extract each candidate with `awk` — never Read a session file whole.** Sessions accrete Progress entries and reach 90 KB+; the extract is ~6 KB:
   ```bash
   # `## Goal` + `## To-Do-List` + the newest Progress entry only.
   # Section-scoped on purpose: `### Recall` lives under `## Context`, so a bare `grep '^### '`
   # would grab it instead of the newest Progress entry.
   awk '/^## /{s=$0;n=0} s~/^## (Goal|To-Do-List)$/{print;next} s=="## Progress"{if(/^### /)n++; if(n<=1)print}' "$f"
   ```
   List each candidate's `## Goal` · uid (date) · a one-line summary of the **latest (topmost) Progress entry**:
   > This project (`<project>`) has N sessions in progress:
   > 1. `<goal summary>` (`<uid>`) — <latest Progress one-liner>
   >
   > Resume one (by number), or open a new session?

   - **Resume (number picked)** → step 3. **Do not create a new file.**
   - **New** → step 4.

3. **Resume — adopt the existing session** — adopt the chosen session as the current work session. No new file. Summarize its `## Goal` + **latest Progress entry** + `## To-Do-List` **from the step-2 awk extract — do not Read the file again**, and announce "resuming from here". `status` stays `active`. Then:
   - **PM (read)** — collect the current CC session id **if obtainable** (if the harness exposes no value, treat it as absent).
   - **Delegate the frontmatter update to `scribe`** — writing brief:
     - Target: the adopted `<VAULT>/sessions/<uid>.md`.
     - Prepend the current CC session id **to the top of** the `cc_session_ids:` list (entries formatted `- <id>`). **If there is no id, do not touch this field.** (Preserves CC session history that vanishes on every resume.)
     - Update `updated:` to today.
     - **Keep** `status: active` (no change). All other fields and body unchanged.
   - **★ Recall injection (required on resume too)** — the **PM directly performs** `${CLAUDE_SKILL_DIR}/../_session-shared/recall.md` via Read (a read) — **first `export GOAL="<the adopted session's ## Goal>"`** so the ranker's `${GOAL:?}` guard (recall.md:18) is satisfied (`VAULT`·`PROJDIR`·`<project>` are already set) — and **presents the accumulated memory relevant to the session goal alongside the resume summary** (this project's knowledge · common facts/patterns/policies · cross-project notes · past Mistakes · 1-hop related) — live priming. Do not overwrite the session note's `## Context` — **resume recall is screen-output only, no vault write** (no `scribe` delegation needed). **If resume skips recall, priming at resumption is zero** — this step closes that gap. (Screen-only also means: the resume re-presentation extends neither the session's injected-notes record — the creation-time `## Context` recall block — nor any `recalled:` counter; feedback counters count injection once per session, `docs/knowledge-convention.md` §Feedback counters.)
   **Stop here** — do not run the new-session creation below.

4. **Settle title·goal** (when creating new) — if argument text remains, that is the goal; otherwise take it from the session goal the user stated.

   **4a. Ask about a worktree fork** (**git repos only**) — first `git rev-parse --is-inside-work-tree 2>/dev/null`.
   - If **not** a git repo, **silently skip** this substep (no noise).
   - If it is a git repo, ask in one line:
     > Run this session in an isolated worktree, or stay in the current working tree?
     - **Current tree** → proceed to step 5 as-is. `git_branch` = current branch (`git rev-parse --abbrev-ref HEAD`), `git_worktree` = empty.
     - **worktree** → call the `EnterWorktree` tool with `name: <title-slug>` (kebab) — worktree creation + session switch in one shot. Record the reported worktree path in the `git_worktree` field and the branch in `git_branch` (step 5). (The user explicitly choosing "worktree" is the legitimate trigger for using `EnterWorktree`.)

5. **Write the session file** (when creating new) — **uid minting·field collection = PM (reads), the file Write is delegated to `scribe`.**

   **(a) PM — uid mint + field collection (read-only):**
   - **PREFIX** — Read the project prefix recorded in the project hub `<PROJDIR>/index.md`. If missing, confirm with the user and include writing it into the hub in the (b) brief.
   - **uid = `<PREFIX>-YYYYMMDD-HHMMSS`** (canon: sessions-note-convention):
   ```bash
   uid="<PREFIX>-$(date +%Y%m%d-%H%M%S)"
   whoami                                        # → writer: (the human user)
   git rev-parse --abbrev-ref HEAD 2>/dev/null   # → git_branch:
   ```
   - Collect the current CC session id **if obtainable** (otherwise leave the list empty).

   **(b) Delegate to `scribe`** — "Write `<VAULT>/sessions/<uid>.md` **exactly per the schema below** (a single file, not a folder)". Pass the settled values in the brief (uid·project·git_branch·git_worktree·created/updated·writer·cc_session_ids·Goal text). Schema/frontmatter canon = `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md`:
   ```markdown
   ---
   uid: <uid>
   project: <project>
   git_branch: <current branch or empty>
   git_worktree: <worktree path or empty>
   created: <YYYY-MM-DD>
   updated: <YYYY-MM-DD>
   status: active
   writer: <the actual human user, e.g. whoami output>
   cc_session_ids:
     - <current CC session id; leave the list empty if unavailable>
   related_ticket:
   tags: []
   ---

   ## Goal
   <the user's goal — smallest achievable unit>

   ## Context
   <!-- Why this goal. The Recall block below is v1 grep priming (step 6) -->

   ## To-Do-List
   -

   ## Progress
   <!-- By date, newest on top. Headings: ### YYYY-MM-DD → #### Done/Mistake/Fixed/Learned/Outputs -->
   ```
   - `writer:` = `whoami` (or `git config user.name`) output — this is the **human user** (not an agent).
   - `cc_session_ids:` = one line with the current CC session id. If unobtainable, leave the list empty.
   - Use the session file path `scribe` returns in the step-7 report.

6. **Recall injection** — **performing it (read) = PM, injecting it (write) = `scribe` delegation.**
   - **(a) PM — perform recall (read)**: **First `export GOAL="<the session goal settled in step 4>"`** — symmetric with `VAULT`; recall.md's ranker hard-requires it via a `${GOAL:?}` guard (recall.md:18), and `VAULT`·`PROJDIR`·`<project>` must already be set (recall.md:4 prerequisites). Then Read `${CLAUDE_SKILL_DIR}/../_session-shared/recall.md` and execute it. Gather the relevant accumulated memory (this project's knowledge + **common facts/patterns/policies** + **cross-project (`projects:`) notes** + past Mistakes + **1-hop related** · prefer graphify if wired · include **source_location**) and **compose** a concise recall block. If there is nothing, **move on quietly** with "no relevant accumulated memory (fresh vault)" (no delegation).
   - **(b) Delegate to `scribe` — inject (write)**: inject the recall block above into `## Context` of the `<VAULT>/sessions/<uid>.md` created in step 5. Brief: target path · the recall block body (settled by the PM) · **append to the `## Context` section only; other sections and frontmatter unchanged**. **This injected block is the canonical "notes injected this session" record** — each line already carries its source path (`recall.md` §Injection), so no separate list is kept; `sh`/`sc` later read this block to bump the injected notes' `recalled:`/`useful:` feedback counters (canon: `${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters). Keep the one-line-per-item · source-path format intact — it is what the counter step parses.
   - Steps 5 and 6 **may be merged into a single `scribe` call** (specify file creation + Context injection together) — fewer round trips.

7. **Report** — report the adopted (resumed) or created session path (`<VAULT>/sessions/<uid>.md`) plus project·vault. If a worktree was created, its path too. If recall injected anything, one line on the gist.

## Hard rules

- **`obsidian create` / `obsidian-cli create` CLI is absolutely forbidden** — duplicate-file bug. `Write`/`Edit` tools only. **An existing file is changed with `Edit`; `Write` is for creating a file that does not exist yet** — `Edit`'s `old_string` is a compare-and-swap, so if a concurrent session moved the anchor the edit fails loudly instead of silently swallowing their work. **The party doing that write is the `scribe` worker** — the PM never writes vault **content** directly (governance canon: memory-control-convention §Governance).
- **Write only under the `vault-root` in `CLAUDE.local.md`** — any other path or other vault is off-limits.
- **The `status` vocabulary is exactly:** `active` / `done` / `cancel` (3 values). Other states (pending-verification·blocked) go in `tags` or as open `## To-Do-List` items, not in status.
- **Session = a single file** — `sessions/<uid>.md` (uid = `<PREFIX>-YYYYMMDD-HHMMSS`). Not a folder.
