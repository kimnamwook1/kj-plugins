# Reference: Open-session scan (shared procedure)

> The open-session discovery + summary-extract procedure shared by **`sl`** (list, read-only) and **`sr`** (resume). Single source — **never inline a copy of these snippets into a skill document.** Not executed standalone.
> Prerequisites: `VAULT` (vault root — the `vault-root` value in the project `CLAUDE.local.md`. No hardcoding) · `<project>` (slug, resolved via `project-inference.md`).
> `ss` (new-session creation) **does not use this document** — it never scans for open sessions. That is the split: **one verb, one skill** (`ss` create · `sr` resume · `sl` list).

## 1. Scan — find open sessions (`active` + `parked`)

A session is **open** when its frontmatter `status:` is `active` (running) **or** `parked` (suspended) — the two non-terminal values of the 3-value vocabulary (canon: `docs/sessions-note-convention.md`). `done` is the only closed one. Match **both** an open `status:` and `project:` — one file per session, `<VAULT>/sessions/*.md`.

**Both values, always. Scanning only `parked` is a bug** — a session interrupted without `sh` (crash, closed terminal, forgotten park) never got its `parked` write and would become unreachable by `sr`, which is the one recovery path back into it.

```bash
# zsh: a glob with no match errors out → enumerate with find (safe even on an empty vault).
PROJ_RE="${PROJ_RE:-<project>}"   # project slug. Set PROJ_RE='.*' to sweep every project (`sl all`).

find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null | while read -r f; do
  grep -q '^session_type: dreaming' "$f" && continue
  st=$(sed -n 's/^status:[[:space:]]*//p' "$f" | head -1 | tr -d '"'\''[:space:]')
  case "$st" in active|parked) ;; *) continue ;; esac
  grep -qE "^project:[[:space:]]*${PROJ_RE}[[:space:]]*$" "$f" && echo "$st	$f" || :
done
```

- **The scan emits `<status>\t<path>`**, not a bare path — §3 has to render the two states differently, and re-grepping `status:` per candidate would read every file a second time.
- The `sed | head -1` takes the **first** `status:` line: `## Progress` bodies contain the literal string `status:`, and only the frontmatter one is at the top. The `tr` strips quotes so `status: "parked"` matches (same class of false negative `validate.sh`'s `unq()` handles).

- **`|| :` at the end of the loop body is load-bearing — do not drop it (KJP-41).** A `while` loop's exit status is the exit status of the **last command of its last iteration**. Without the terminator, a final non-matching `grep -q` returns 1 → the pipeline returns 1 → the whole snippet exits 1 on a perfectly normal run. Measured on a fixture vault: 0 matches → `exit=1`, **and 2 matches → `exit=1` as well** (the last file scanned was a non-match), i.e. the false positive is not limited to the empty case.
  - **Re-measured after the KJP-48 `active|parked` rewrite** — the added `case … continue` does *not* absorb the bug: last file = another project's open session → `with=0 / without=1` (still broken without the terminator); last file = `done` (hits `continue`) → `0/0`; empty vault → `0/0`. The terminator is what makes the first case safe.
- **The `session_type: dreaming` skip is defense in depth.** dreaming reports live in `sessions/` but are written `status: done` + empty `project:` (`skills/dreaming/SKILL.md` §Report format), so they already fail the two conditions — *except* under `PROJ_RE='.*'`, where the empty `project:` value matches. Mirrors the same guard in `recall.md` [M]. Never rely on one of the two alone. Fixture-verified 2026-07-25: a `status: active` + empty-`project:` dreaming report is excluded under **both** `PROJ_RE=<project>` and `PROJ_RE='.*'`.
- **⚠ Do not "fix" the `while read` loops in `_session-shared/recall.md`** (lines 47·55·61·67). Those sit inside a `{ … } | awk | sort | head` pipeline, so the exit status is the tail's, not the loop's. Adding `|| :` there changes nothing and only adds noise.

## 2. Summary extract — one candidate at a time

**Never `Read` a session file whole.** Sessions accrete `## Progress` entries and reach 90 KB+; this extract is ~6 KB.

```bash
# `## Goal` + `## To-Do-List` + the newest Progress entry only.
# Section-scoped on purpose: `### Recall` lives under `## Context`, so a bare `grep '^### '`
# would grab it instead of the newest Progress entry.
awk '/^## /{s=$0;n=0} s~/^## (Goal|To-Do-List)$/{print;next} s=="## Progress"{if(/^### /)n++; if(n<=1)print}' "$f"
```

Frontmatter scalars a caller may also want (`uid`, `project`, `updated`) come from a one-line grep — not another Read:

```bash
grep -m1 '^uid:' "$f"; grep -m1 '^project:' "$f"; grep -m1 '^updated:' "$f"
```

## 3. Presentation — one line per candidate

Render each candidate as **one line**: **state** · `<uid>` · `## Goal` one-liner · the **newest (topmost) Progress entry** summarized in a clause.

```
1. [parked] `<goal one-liner>` (`<uid>`, updated <updated>) — <newest Progress one-liner>
2. [active] `<goal one-liner>` (`<uid>`, updated <updated>) — <newest Progress one-liner>
```

- **The state marker is required, and it comes from the §1 scan's `<status>` column** — the frontmatter value, never inferred from the Progress suffix (KJP-48). `[parked]` = suspended by `sh`, resumable as intended. `[active]` = still marked running — either the session in this very conversation, or one interrupted without `sh`. The distinction is the whole reason `parked` became a status, so **a list that renders both the same is a bug**.
- **Order: `updated:` descending (most recently touched first)**, numbered from 1. `find` returns directory order, which is arbitrary — both callers must sort, so that a number the user picks in `sl` means the same session in `sr`. State does **not** affect ordering — mixing a state sort into it would break that number agreement.
- Under `PROJ_RE='.*'` prefix each line with its `project:` value, otherwise the list is ambiguous.
- The newest `### YYYY-MM-DD` heading may also carry a `(parked)` / `(completed)` suffix. It is **history, not state** — quote it inside the Progress clause if useful, but the `[state]` marker is what the frontmatter says (canon: `docs/sessions-note-convention.md` §Progress entry status suffix).

> Marker: `<!-- active-sessions: shared scan + extract · status active|parked × project · dreaming skip · `|| :` loop terminator (KJP-41) · used by sl + sr only -->`
