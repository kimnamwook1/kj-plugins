---
name: dreaming
description: Batch consolidation of the memory vault (second-brain) — refine notes to form, link related notes, and promote knowledge that stands in two projects up to the vault-wide tier. Inputs are p_memory and neocortex only; sessions are neither read nor written. Real-time capture stays cheap and messy; the hard consolidation is batched here. Use when the user says "dreaming", "수면 통합", "볼트 정리", "지식 dedup", "메모리 consolidate/통합", "볼트 유지보수", "낡은 지식 정리", or on a periodic schedule. Destructive changes (merge·delete·move) are proposal-only — never overwrites memory automatically.
---

# Dreaming — vault sleep consolidation

`sc` triggers it at session close. Capture is deliberately cheap and imperfect so that it actually happens; this skill is what pays that debt back, periodically.

## Inputs — `p_memory` and `neocortex` only

🔴 **Sessions are neither read nor written.** raw and wiki do not reference each other ([[vault-tree]] §Layers), so `hippocampus/` is outside this skill in both directions — no Mistake scan, no session report, no marker written back into a session file.

The vault-root comes from the project's `CLAUDE.local.md` (recorded by `/brain:init` — never hardcoded). With multiple vaults, iterate over each. **Tree axes are per-vault**: resolve them through `${CLAUDE_SKILL_DIR}/../../scripts/vault-paths.sh`, which reads each vault's own `.brain-paths`. Never write a layout name as a literal.

## The three operations

| Operation | What it does | Boundary |
|---|---|---|
| **Refine** | Conform notes to the form, cut padding, fold duplicate paragraphs together, even out the formatting | **Facts do not change.** Code blocks · commands · paths · error messages · numbers · versions · negations stay exactly as they were. Extract those values before and after the edit and compare them — if even one disappeared, cancel the write. |
| **Link** | Find related notes and join them with `related`. Undirected. | 🔴 **No new shortcut between notes already connected.** If A–B and B–C exist, do not add A–C — two hops already reach it, and without this rule links grow quadratically with the note count. |
| **Promotion ②** | The same knowledge standing in two different projects moves to `neocortex/NEO-<slug>.md`, and the original is removed | **Sameness is judged by content.** Matching filenames or titles only narrow the candidate set. If a number, path, version, or condition disagrees it is different knowledge — link it, do not move it. |

Promotion ② is a **three-line operation** and the file is otherwise byte-identical — `git mv`, append to `aliases`, insert `projects`. The body is not edited. Canon: [[knowledge-escalate-convention]].

## Rules

| Item | Rule |
|---|---|
| **Concurrency** | An atomic lock at the vault root. If a run is already going, skip. `p_memory` of any project with an `active` session is left out of the scan. |
| **Isolation** | Work in a separate git worktree and integrate with `merge --ff-only`. On failure, discard the result and do not advance the cursor. |
| **Commit** | One run = one commit. |
| **Revert** | `git revert`. Record the reverted combination and never build it again. |
| **Judgment** | Run the same judgment twice; if the answers differ, leave it alone. |
| **Scan** | Incremental. The cursor is the last successful commit. |
| **Paths** | `<common_root>/` is refused twice — once before the write and once before the commit. The path is read from `.brain-paths`, never matched as a literal (a vault whose value is `personal` would otherwise be undefended). |

## Absolute principle — never silently overwrite memory

The biggest risk is bad consolidation polluting memory, and a wrong merge or delete is hard to undo.

- **Destructive changes (merge · delete · move) are proposal-only** — apply after user/PM approval. Auto-apply only what is low-risk and lossless: dead-link fixes and adding a missing `related` link.
- **Incremental** — only what changed since the last run. Reprocessing everything is slow and only raises the pollution risk.

## dream-log

One file, appended to: `neocortex/dream-logs.md`. No folder, no `_index.md`, no `.base`. Frontmatter is one key; the body is bullets with no headings.

```markdown
---
updated: YYYY-MM-DDTHH:MM:SS
---

- [YYYY-MM-DD]-<what the run did, 1–3 lines>
- [YYYY-MM-DD]-<what the run did, 1–3 lines>
```

🔴 **A dream-log line carries no ID.** Do not mint one. The date prefix and the file's append order are the whole addressing scheme.

The write itself is delegated to the scribe worker like every vault write ([[memory-control-convention]] §Governance).

## Forbidden

- **No automatic application** of destructive changes — propose, then apply on approval.
- **Never record secret values in the vault** — locations and conventions only, never values.
- **No CLI writes** → `Write`/`Edit` tools only. Canon: `skills/_session-shared/vault-io.md` §1–2. The `obsidian` CLI's **read** side is open to this skill and is where link-integrity input comes from — `unresolved` · `orphans` · `deadends` are the canonical verdict, so do not hand-roll a regex scan for the linking pass.
- **Never touch a session file** — not to read, not to mark, not to annotate.
