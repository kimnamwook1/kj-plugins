---
name: sl
description: List parked (in-progress) work sessions — read-only. Scans the vault for `status: active` session notes and prints goal, uid, and latest progress, one line each. Writes nothing and adopts nothing. Use when the user says "sl", "세션 목록", "열린 세션", "파킹된 세션", "뭐 하다 말았지", "what was I working on". To actually resume one use sr; to start a new session use ss.
argument-hint: "[project|all]"
---

# sl — Session List

Shows what is parked. **Read-only** — no vault write, no `scribe` delegation, no session adopted.

> **One verb, one skill.** `ss` = create only · `sr` = resume · **`sl` = list only** · `sh` = park · `sc` = close. Because `ss` no longer announces parked sessions, this skill is how you find out what is open — and it costs nothing to run.

> **Executor = PM (main session), and it stays there.** Every other session skill delegates its writes to `scribe`; this one has no writes to delegate. **Spawning `scribe` from `sl` is a bug, not a nicety.**

## Resolving Vault·Project

1. **Resolve VAULT** — `VAULT` = the `vault-root` value defined in the project's `CLAUDE.local.md`. **If missing, ask the user for the vault root and point them to `/brain:init` onboarding** — never read an arbitrary path.
2. **Resolve scope** — from the argument:
   - **no argument** → the current project. Read `${CLAUDE_SKILL_DIR}/../_session-shared/project-inference.md` and resolve by its rules (config `project:` first, then cwd). If inference fails, do not guess — **fall back to `all` and say so** (this skill is read-only, so a too-wide list is harmless; a wrong guess is not).
   - **`all`** → every project in the vault (`PROJ_RE='.*'`).
   - **any other value** → that project slug.
3. **Verify the vault exists** — if `VAULT` is not a directory, stop and tell the user to run `/brain:init`. **Create nothing.**

## Steps

1. **Scan** — Read `${CLAUDE_SKILL_DIR}/../_session-shared/active-sessions.md` and run its **§1 scan** with `PROJ_RE` set per the scope above. Do not inline your own copy of the loop; the `|| :` loop terminator there is load-bearing (KJP-41) and its absence made this exact scan exit 1 on a clean run.

   **0 matches** → one line: "No parked sessions in `<scope>`." Then stop.

2. **Extract each candidate** — with **§2 of the shared document (`awk`) — never `Read` a session file whole.** Sessions reach 90 KB+; the extract is ~6 KB, and this skill exists partly so that cost is paid only when the user asked for the list.

3. **Print** — per **§3** of the shared document (which fixes the ordering: `updated:` descending), one line per session:
   ```
   1. `<goal one-liner>` (`<uid>`, updated <updated>) — <newest Progress one-liner>
   ```
   - Under `all`, prefix each line with its `project:` value.
   - If the newest `### YYYY-MM-DD` heading carries a `(parked)` suffix, surface it (vocabulary canon: `${CLAUDE_SKILL_DIR}/../../docs/sessions-note-convention.md` §Progress entry status suffix).
   - Close with one line: "Resume one with `sr`; start a new session with `ss`."

## Hard rules

- **Read-only, absolutely.** No `Write`, no `Edit`, no `scribe` brief, no frontmatter touch — not even `updated:`. Listing is not using.
- **Never adopt a session.** Printing a session does not make it the current one; that is `sr`, and it takes an explicit user pick.
- **Never create a session.** If the list is empty, say so and stop — do not helpfully fall through into `ss`.
- **Never `Read` a session file whole** — the shared `awk` extract only.
