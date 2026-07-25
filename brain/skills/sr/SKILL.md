---
name: sr
description: Resume a parked (in-progress) work session — find this project's `status: active` sessions, let the user pick one, adopt it as the current session, and re-present its goal, latest progress, and recall priming. Creates nothing. Use when the user says "sr", "재개", "resume", "이어서", "세션 이어", "하던 거 계속". To start a brand-new session use ss; to only see what is parked without adopting anything use sl.
argument-hint: "[project]"
---

# sr — Session Resume

Adopts an existing parked session as the current work session. **Never creates a session file** — if the user wants a new one, that is `ss`.

> **One verb, one skill.** `ss` = create only · **`sr` = resume** · `sl` = list only · `sh` = park · `sc` = close. `ss` no longer asks about resuming, so **this skill is the only path back into a parked session** — and `sl`/`sr` are the only places the parked-session scan lives.

> **Executor = PM (main session), vault content writes = the `scribe` worker.** The PM does **reading, detection, judgment** — session discovery (`find`/`grep`) · user Q&A · performing recall (read) · **deciding what to record**. The one write this skill produces (a frontmatter touch-up) is **delegated to `scribe` via a writing brief** (`Agent` tool — "what · to which path · with what content"). `scribe` is not a resident agent but a subagent handed a writing brief. Governance canon: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Resolving Vault·Project

1. **Resolve VAULT** — `VAULT` = the `vault-root` value defined in the project's `CLAUDE.local.md`. **If missing, ask the user for the vault root and point them to `/brain:init` onboarding** — never read or write an arbitrary path.
2. **Resolve project** — a first argument is the project override. Otherwise Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md` and resolve by its rules (config `project:` first, then cwd). If inference fails, do not guess — ask the user.
3. **Verify the vault exists** — check that `VAULT` is a directory. If not, stop and tell the user to run `/brain:init`. **This skill creates no folders** — a session to resume implies the project folder already exists.
4. **Locate `PROJDIR`** (read-only, needed by recall in step 4):
   ```bash
   PROJDIR=$(find "$VAULT" -maxdepth 1 -type d -name "*_<project>" 2>/dev/null | head -1)
   ```
   If it comes back empty, continue anyway but say so — recall's project-knowledge scan will be empty.

## Steps

1. **Scan for parked sessions** — Read `${CLAUDE_SKILL_DIR}/../_session-shared/active-sessions.md` and run its **§1 scan** with `PROJ_RE=<project>`. Do not inline your own copy of the loop; the `|| :` loop terminator there is load-bearing (KJP-41).

   **0 matches** → stop with one line: "No parked sessions in `<project>`. Start a new one with `ss`." **Do not create anything, and do not fall through to session creation.**

2. **Present the candidates and ask** — extract each with **§2 of the shared document (`awk`) — never `Read` a session file whole.** Render per **§3**, which also fixes the ordering (`updated:` descending) so a number means the same session here as it did in `sl`:
   > `<project>` has N parked sessions:
   > 1. `<goal one-liner>` (`<uid>`, updated `<updated>`) — <newest Progress one-liner>
   >
   > Which do you want to resume? (number, or `ss` to start a new session instead)

   - **Exactly 1 match** → still show the line, but the question collapses to a yes/no: "Resume this one?"
   - **User picks a number** → step 3.
   - **User declines** → stop. Say `ss` starts a new session. Do not start one from here.

3. **Adopt the chosen session** — it becomes the current work session. No new file. Summarize its `## Goal` + **latest Progress entry** + `## To-Do-List` **from the step-2 `awk` extract — do not Read the file again** — and announce "resuming from here". `status` stays `active`.
   - **PM (read)** — collect the current CC session id **if obtainable** (if the harness exposes no value, treat it as absent).
   - **Delegate the frontmatter update to `scribe`** — writing brief:
     - Target: the adopted `<VAULT>/sessions/<uid>.md`.
     - Prepend the current CC session id **to the top of** the `cc_session_ids:` list (entries formatted `- <id>`). **If there is no id, do not touch this field.** (Preserves CC session history that vanishes on every resume.)
     - Update `updated:` to today.
     - **Keep `status: active`** (no change). All other fields and the entire body unchanged — **`sr` adds no Progress entry**; the next `sh`/`sc` writes that.

4. **★ Recall injection — required, screen-output only.** The **PM directly performs** `${CLAUDE_SKILL_DIR}/../_session-shared/recall.md` via Read (a read). **First `export GOAL="<the adopted session's ## Goal>"`** so the ranker's `${GOAL:?}` guard (recall.md:18) is satisfied (`VAULT`·`PROJDIR`·`<project>` are already set from the section above). Present the accumulated memory relevant to the session goal **alongside the resume summary** — this project's knowledge · common facts/patterns/policies · cross-project notes · past Mistakes · 1-hop related — live priming.
   - **Do not overwrite the session note's `## Context`. No vault write, no `scribe` delegation for this step.**
   - **Skip recall and priming at resumption is zero** — that is the entire reason this step exists.
   - Screen-only also means it extends neither the session's injected-notes record (the creation-time `## Context` recall block written by `ss`) nor any `recalled:`/`useful:` counter — feedback counters count injection **once per session** (`${CLAUDE_SKILL_DIR}/../../docs/knowledge-convention.md` §Feedback counters).

5. **Report** — the adopted session path (`<VAULT>/sessions/<uid>.md`) · project · vault · one line on the recall gist if anything was surfaced.

## Hard rules

- **Resume only. Never create a session file here** — no uid minting, no `Write` of `sessions/<uid>.md`. If the user turns out to want a new session, hand off to `ss`.
- **Never change `status`** — a resumed session stays `active`. `done`/`cancel` is `sc`'s job alone.
- **Read sessions with the shared `awk` extract, never whole** — a 90 KB session file read in full is the failure mode this skill was split out to avoid.
- **`obsidian create` / `obsidian-cli create` CLI is absolutely forbidden** — duplicate-file bug. The frontmatter update is an **`Edit`** (compare-and-swap: if a concurrent session moved the anchor the edit fails loudly instead of silently swallowing their work), performed by `scribe` — the PM never writes vault **content** directly (canon: memory-control-convention §Governance).
- **Write only under the `vault-root` in `CLAUDE.local.md`** — any other path or other vault is off-limits.
