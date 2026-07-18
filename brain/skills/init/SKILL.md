---
name: init
description: Set up the brain harness structure — creates the project CLAUDE.local.md (PM role text, router) and the vault scaffold. Use when the user says "init", "install the harness", "set up the vault", "하네스 설치", "볼트 세팅". Mechanical structure only — the content interview is onboard.
---

# init — Harness Structure Setup (mechanical)

Sets up the brain harness in a project — **mechanical structure only** (collect values → `CLAUDE.local.md` → vault scaffold). Content (filling documents) is `/brain:onboard`'s job. Canonical tree & naming = `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md` · canonical document list = `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md`.

> **Executor = PM (main session).** `CLAUDE.local.md` lives outside the vault (project root), so the PM writes it directly. **The vault scaffold (step 3) is delegated to a `scribe` worker** — the PM does not write vault content directly (canonical governance: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`).

## Steps

1. **Collect values** — pin down the 4 values via AskUserQuestion (or conversation). No guessing:
   - `org` — business slug
   - `vault-root` — absolute path of the vault. Default suggestion = `~/Documents/Obsidian/second-brain/<org>` — **no trailing slash.** Strip any trailing `/` from what the user supplies before writing it: `vault-root` is compared as a **string prefix** when skills enforce write boundaries (`ss` "Write only under the vault-root", `sc` "Touch only the paths under vault-root"), and `<root>` vs `<root>/` are different strings.
   - `project` — project slug
   - `PREFIX` — 2–4 uppercase letters for uid/ID issuance (suggested default = an uppercase abbreviation of the project slug)

   **Branch — adopt-existing-vault mode**: if `vault-root` is an **already-existing directory**, proceed as adopting an existing vault rather than creating a new one (e.g. a shared company vault the team already uses):
   1. **Structure diff (read-only)** — compare reality against the canonical tree in `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md`: presence of `sessions/` (lowercase) · presence of `000_common/{facts,patterns,policies}` · project folder naming (`NNN_<project>`) · `docs/tech-design/` structure.
   2. **Mismatches are report-only** — present them as a table (e.g. `Sessions/ uppercase — canonical is sessions/`). 🔴 **Migration (rename/move) only after user approval** — a shared vault may be in use by other people. Without approval, leave the existing structure as is, and make the vault paths in the step 2 router point to the **actual paths** (not the canonical tree).
   3. The scaffold (step 3) is idempotent anyway — skip existing entries and create **only what is missing** (anything newly created still uses canonical naming).

   Team-shared context: if the vault is a git repo, synchronization is the git merge layer's job (`versioning-convention.md`, concurrency layer 2) — nothing for init to touch; mention it only.

2. **Create `CLAUDE.local.md`** (project root) — **if it already exists, add/update only the brain block** (replace only what is between the `<!-- brain:begin -->` … `<!-- brain:end -->` markers), **never overwrite the whole file**. The block has 4 sections:

   **`## brain config`** — key-value:
   ```
   vault-root: <absolute path>
   org: <org>
   project: <project>
   prefix: <PREFIX>
   ticket-system: TBD   # settled in /brain:onboard
   ```

   **`## PM role`**
   - Single point of contact — decompose, delegate, aggregate, and report requests.
   - The external ticket system = the canonical work queue. No parallel queue in the vault — session To-Dos are only for chores too small for a card and resume memos.
   - Never write vault content directly — delegate recording via a `scribe` brief. **Commits are the PM's** (boundary recording — canonical versioning-convention.md).
   - Ticket loop — when large, plan (built-in Plan, read-only) → coder → verifier. When small, straight to worker/coder. Exploration and multi-file investigation use built-in Explore (read-only).
   - Brief discipline — specify Goal, constraints, context pointers, DoD. No file overlap between concurrent workers.
   - Document-conflict arbitration — the canonical precedence is `<home>/.claude/brain-docs/project-docs-convention.md` (same expanded-home rule as the Router below).
   - When unsure, vault first — no guessing.

   **`## Router`** — one line for each of the 8 docs below (trigger + path). Point every line at the stable symlink `$HOME/.claude/brain-docs/<doc>.md` — **never** at the plugin install path. The symlink is created and refreshed on every SessionStart by `hooks/hooks.json`, so it tracks the plugin wherever it lives; a hard-coded install path dies on the next version bump or repo move.

   🔴 **Expand the home directory literally.** `CLAUDE.local.md` is read as plain text by the harness — `~` and `$HOME` are **not** guaranteed to expand. Resolve the real home at init time (`echo "$HOME"`) and write the expanded absolute path, e.g. `/Users/<user>/.claude/brain-docs/vault-tree.md`:
   - `vault-tree.md` — when wondering about the vault tree, paths, or naming conventions
   - `sessions-note-convention.md` — session schema, frontmatter, the 3 status values
   - `doc-catalog.md` — which document to create when, owner labels
   - `project-docs-convention.md` — document frontmatter standard, stub rules, ID issuance, document precedence
   - `knowledge-convention.md` — knowledge note format
   - `knowledge-escalate-convention.md` — knowledge promotion gate and scoring
   - `memory-control-convention.md` — Handoff format, recall, scribe governance
   - `versioning-convention.md` — vault git commit discipline

   Also include the vault paths: `<vault-root>/sessions/` (sessions) · `<vault-root>/<NNN>_<project>/knowledge/` (knowledge) · `<vault-root>/<NNN>_<project>/docs/` (documents).

   Plus one tool-inventory line:
   - When wondering which tools, CLIs, or MCPs are available → `<vault-root>/000_common/facts/tool-*.md` (if missing, `/brain:onboard` step 6)

   **`## Worker profiles`**
   - `worker` — default profile for general tickets/briefs (including scribe recording briefs).
   - `coder` — implementation only, worktree isolation.
   - `verifier` — verification, review, disproof; report-only.
   - Start sessions with `/brain:ss`.

3. **Delegate the vault scaffold** — delegate as **one** `scribe` brief. If `<vault-root>` does not exist, confirm creation with the user before proceeding. **Idempotent — skip folders/files that already exist (no overwriting).** What to create (canonical tree vault-tree.md):
   - `000_common/{facts,patterns,policies}/index.md`
   - `<NNN>_<project>/knowledge/index.md` — NNN = the next number (max numeric-prefixed folder + 1, 3 digits — same computation as `/brain:ss` §Ensure the project folder)
   - `<NNN>_<project>/docs/{tech-design,business,policy,adr,research,feature}/index.md`
   - **19 stubs** — 17 tech-design + 2 business. Each file = frontmatter (`status: stub` — the standard is project-docs-convention.md) + H1 **only**. Canonical list doc-catalog.md.
   - `sessions/index.md`
   - Project hub `<NNN>_<project>/index.md` — one-line definition + `PREFIX: <value>` + TOC pointers only (canonical doc-catalog.md §Project hub)
   - Vault root `index.md` — one-line definition + TOC pointers only (index.md pointer principle, vault-tree.md)

4. **Report** — report the list of created/updated paths, and point the user to `/brain:onboard` for the content interview.
