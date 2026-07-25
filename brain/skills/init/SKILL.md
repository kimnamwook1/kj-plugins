---
name: init
description: Set up the brain harness structure — creates the project CLAUDE.md (shared brain config, PM role, worker profiles) + CLAUDE.local.md (vault-root, router) and the vault scaffold. Use when the user says "init", "install the harness", "set up the vault", "하네스 설치", "볼트 세팅". Mechanical structure only — the content interview is onboard.
---

# init — Harness Structure Setup (mechanical)

Sets up the brain harness in a project — **mechanical structure only** (collect values → `CLAUDE.md` + `CLAUDE.local.md` → vault scaffold). Content (filling documents) is `/brain:onboard`'s job. Canonical tree & naming = `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md` · canonical document list = `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md`.

> **Executor = PM (main session).** `CLAUDE.md` and `CLAUDE.local.md` live outside the vault (project root), so the PM writes them directly. **The vault scaffold (step 4) is delegated to a `scribe` worker** — the PM does not write vault content directly (canonical governance: `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`).

## Steps

1. **Collect values** — pin down the 4 values via AskUserQuestion (or conversation). No guessing:
   - `org` — business slug
   - `vault-root` — absolute path of the vault. Default suggestion = `~/Documents/Obsidian/second-brain/<org>` — **no trailing slash.** Strip any trailing `/` from what the user supplies before writing it: `vault-root` is compared as a **string prefix** when skills enforce write boundaries (`ss` "Write only under the vault-root", `sc` "Touch only the paths under vault-root"), and `<root>` vs `<root>/` are different strings.
   - `project` — project slug
   - `PREFIX` — 2–4 uppercase letters for uid/ID issuance (suggested default = an uppercase abbreviation of the project slug)

   **Branch — adopt-existing-vault mode**: if `vault-root` is an **already-existing directory**, proceed as adopting an existing vault rather than creating a new one (e.g. a shared company vault the team already uses):
   1. **Structure diff (read-only)** — compare reality against the canonical tree in `${CLAUDE_SKILL_DIR}/../../docs/vault-tree.md`: presence of `sessions/` (lowercase) · presence of `000_common/{facts,patterns,policies}` · project folder naming (`NNN_<project>`) · `docs/tech-design/` structure.
   2. **Mismatches are report-only** — present them as a table (e.g. `Sessions/ uppercase — canonical is sessions/`). 🔴 **Migration (rename/move) only after user approval** — a shared vault may be in use by other people. Without approval, leave the existing structure as is, and make the vault paths in the step 2 router point to the **actual paths** (not the canonical tree).
   3. The scaffold (step 4) is idempotent anyway — skip existing entries and create **only what is missing** (anything newly created still uses canonical naming).

   Team-shared context: if the vault is a git repo, synchronization is the git merge layer's job (`versioning-convention.md`, concurrency layer 2) — nothing for init to touch; mention it only.

2. **Create the two config files** (project root) — the brain block is **split by shareability**: `CLAUDE.md` = committed, true for every teammate · `CLAUDE.local.md` = gitignored, machine-specific. For **each** file: **if it already exists, add/update only the brain block** (replace only what is between that file's `<!-- brain:begin -->` … `<!-- brain:end -->` markers), **never overwrite the whole file**.

   ### 2a. `CLAUDE.md` — committed · team-shared (3 sections)

   **`## brain config`** — shared keys only:
   ```
   org: <org>
   project: <project>
   prefix: <PREFIX>
   ticket-system: TBD   # identifier only — settled in /brain:onboard
   ```
   🔴 **Identifiers only, never credentials.** `ticket-system` holds a shareable identifier (system name · workspace · project code). **Real credentials (tokens, keys) go in neither CLAUDE file** — they live in a separate env file (e.g. `~/.config/claude/huly.env`).

   **`## PM role`**
   - Single point of contact — decompose, delegate, aggregate, and report requests.
   - The external ticket system = the canonical work queue. No parallel queue in the vault — session To-Dos are only for chores too small for a card and resume memos.
   - Never write vault content directly — delegate recording via a `scribe` brief. **Commits are the PM's** (boundary recording — canonical versioning-convention.md).
   - Ticket loop — when large, plan (built-in Plan, read-only) → coder → verifier. When small, straight to worker/coder. Exploration and multi-file investigation use built-in Explore (read-only).
   - Brief discipline — specify Goal, constraints, context pointers, DoD. No file overlap between concurrent workers. A brief touching features, architecture, deployment, or schema includes the affected document updates in its DoD (the worker drafts the content — Handoff `Docs draft`; scribe copies; the PM commits).
   - Document-conflict arbitration — the canonical precedence is `~/.claude/brain-docs/project-docs-convention.md`. (🔴 Unlike the 2b Router, do **not** expand the home here — `CLAUDE.md` is committed, so a specific user's absolute home would be wrong for every teammate and leak the path. `~` is fine: this line is a human-readable reference, not a harness-functional path.)
   - When unsure, vault first — no guessing.

   **`## Worker profiles`**
   - `worker` — default profile for general tickets/briefs (including scribe recording briefs).
   - `coder` — implementation only, worktree isolation.
   - `verifier` — verification, review, disproof; report-only.
   - Start sessions with `/brain:ss`.

   ### 2b. `CLAUDE.local.md` — gitignored · machine-local (2 sections)

   Everything here is machine-specific by nature: `vault-root` differs per person **even on a team**, and every Router line is a machine-absolute path (the 🔴 expansion rule below).

   **`## brain config`** — local key only:
   ```
   vault-root: <absolute path>
   ```

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

   **Migration on re-run (pre-split projects)** — projects initialized before the split hold all 4 sections in `CLAUDE.local.md`. No special case needed: each file's brain block is fully regenerated between its own markers, so a re-run writes the shared sections (shared config keys · PM role · Worker profiles) into the `CLAUDE.md` block and leaves only `vault-root` + Router in the `CLAUDE.local.md` block — carrying existing values over (e.g. a settled `ticket-system`) instead of resetting them to defaults. Report the move in step 5.

3. **Protect `CLAUDE.local.md` from git** — the file holds machine-local data (the vault absolute path, machine-absolute Router pointers); it must never be committed. If the project root is a git repo, add it to `.gitignore` **idempotently**. Not a git repo → do nothing (silent skip). Re-running never duplicates the line. 🔴 **Never gitignore `CLAUDE.md`** — it is the shared half and committing it is the point; if `.gitignore` already covers it (explicit entry or pattern), report to the user instead of working around it:
   ```bash
   if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
     grep -qxF 'CLAUDE.local.md' .gitignore 2>/dev/null || echo 'CLAUDE.local.md' >> .gitignore
   fi
   ```

4. **Delegate the vault scaffold** — delegate as **one** `scribe` brief. If `<vault-root>` does not exist, confirm creation with the user before proceeding. **Idempotent — skip folders/files that already exist (no overwriting).** What to create (canonical tree vault-tree.md):
   - `000_common/{facts,patterns,policies}/index.md`
   - `<NNN>_<project>/knowledge/index.md` — NNN = the next number (max numeric-prefixed folder + 1, 3 digits — same computation as `/brain:ss` §Ensure the project folder)
   - `<NNN>_<project>/docs/{tech-design,business,policy,adr,research,feature}/index.md`
   - **6 stubs** — 5 tech-design (`PRD` · `ARCHITECTURE` · `CODE_CONVENTION` · `RUNBOOK` · `THREAT_MODEL`) + 1 business (`BUSINESS`). Each file = frontmatter (`status: stub` — the standard is project-docs-convention.md) + H1 **only**; the H1 carries abbreviation + full name (e.g. `# PRD (Product Requirements Doc — 제품 요구사항)` — naming canon doc-catalog.md). Canonical list doc-catalog.md — former standalone kinds live on as sections of these 6, and `API_SPEC` is **not** pre-created (repo-spec mirror; dreaming generates it once an API exists).
     - **Exception — `RUNBOOK.md` gets a seeded `## Delivery` section** (the rest of the file stays H1-only): a pointer to **the vault's delivery classification note** (the classification table project type → git flow; its path differs per vault — binding vaults keep it in `000_common/policies/`, e.g. `DELIVERY_STRATEGY.md`; a stabilizing vault may hold a non-binding reference in `000_common/facts/`. 🔴 Resolve and point — never hardcode a path as canon and never restate a flow value; restate → drift) + the delivery bucket (**server-SaaS / server-personal / client** — TBD, set at `/brain:onboard` from Q1/Q2) + an exceptions line defaulting to **"예외: 없음 — 분류표 준수"**. This is a factual pointer, not an empty-heading skeleton, so it is exempt from doc-templates.md's "only DESIGN/MILESTONE get a body template" rule. Idempotency unchanged — the skip-if-exists rule above still governs.
   - `sessions/index.md`
   - Project hub `<NNN>_<project>/index.md` — one-line definition + `PREFIX: <value>` + TOC pointers only (canonical doc-catalog.md §Project hub)
   - Vault root `index.md` — one-line definition + TOC pointers only (index.md pointer principle, vault-tree.md)

5. **Report** — report the list of created/updated paths, and point the user to `/brain:onboard` for the content interview.
