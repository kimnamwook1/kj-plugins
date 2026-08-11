---
name: onboard
description: Project content interview — asks 5 questions (ticket system, goal, stack, regulation, deployment), fills stub documents to draft only as far as answers were given, and runs the step 6 environment check (live measurement — machine facts always; the machine-global tool inventory is opt-in, one extra question). Use when the user says "onboard", "project interview", "fill in the docs", "프로젝트 인터뷰", "문서 채우기". Prerequisite is a completed init — structure setup is init.
---

# onboard — Project Interview (content filling)

Fills **content** into the structure init laid down — get answers through an interview, then fill **only what was answered** via worker briefs, stub→draft. Canonical document selection & owner labels = `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` · canonical vault-write governance = `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Prerequisite

The brain config must be present across the two config files: `CLAUDE.md` `## brain config` (org, project, prefix, ticket-system) + `CLAUDE.local.md` (vault-root, Router). Pre-split projects may still hold everything in `CLAUDE.local.md` — both files load merged, so read both. **If missing, stop and point the user to `/brain:init` first** — do not write to arbitrary paths.

## Steps

**Steps 1–5 = 5 questions — ask them all at once** (use AskUserQuestion). Ask in the user's language:

1. **Do you use an external ticket system?** — e.g. Plane · Jira · Linear · GitHub Issues · Huly · none. 🔴 **The list is illustrative, not a menu to pick from** — take whatever the user names. `ticket-system` records a free identifier, nothing validates it against a vendor list, so this line never needs a sweep when a vendor appears or dies.
2. **What is the goal?** — what you are building and why
3. **Is the tech stack decided?** Plus three sub-questions — two delivery-classification ones (they decide `RUNBOOK` §Delivery) and one design-tooling one:
   - **Q1 — Who controls deployment?** *I control* (server · web · GitOps · self-host) or *someone else controls* (store review · shipped binary — mobile app, browser extension, other **client artifacts**).
   - **Q2 — Real-user SaaS?** *SaaS* or *personal / internal*. **Only applies to the "I control (server)" bucket** (Axis 2 of the vault's delivery classification note).
   - **Q3 — Do you use a design tool?** (tool-neutral — never suggest a specific tool) *Yes, <name>* → that link becomes `DESIGN` §SSOT · *No* → repo code-first (the repo component source is the SSOT). Only relevant for UI products — skip for headless projects.
4. **Any regulation or sensitive data?** — personal data, payments, AI disclosure
5. **Any deployment target?**

6. **Environment check — measurement, not interview.** **The tools-layer half is opt-in** — ask **one** extra question first (AskUserQuestion, separate from the 5 above — their structure stays intact): *create/refresh the machine-global tool inventory on this machine?* (needed only on machines you actually work from). *Yes* → include the tools-layer investigation below · *No* → skip that half (the Router line already reads the layer as opt-in — absent folder = skip). The machine-configuration half runs regardless. Then delegate as **one** `worker` brief — investigate via commands and create/update the notes below (canonical tree vault-tree.md · tree axes from the vault's `.brain-paths` manifest, resolver `${CLAUDE_SKILL_DIR}/../../scripts/vault-paths.sh` — `BRAIN_COMMON` · `BRAIN_TOOLS` below; never hardcode the layout). **Idempotent** — refresh existing notes with live measurements and stamp `verified: <date>`.
   - Investigation → note mapping, **two destinations by scope**:
     - **machine *configuration* → the common layer's machines sub-axis** — OS, hostname, main tools → `<machines-dir>/<hostname>.md`, filename = lowercase hostname. Which boxes this vault's work runs on is a vault fact.
       - 🔴 **Resolve `<machines-dir>`, never hardcode it.** The common layer's sub-axes are **the vault's own** (canon `vault-tree.md` §The common layer — only `*policies*` names are normative), so: if a `machines` directory already exists anywhere under `<BRAIN_COMMON>`, write there; otherwise use the default layout's `<BRAIN_COMMON>/machines/`, which is what `/brain:init` scaffolds a `_index.md` into (`init/SKILL.md` step 4).
       - 🔴 **`init` and this step must land in the same folder.** Measured 2026-08-05 (KJP-84): this step named `<BRAIN_COMMON>/facts/machines/` while `init` scaffolded `<BRAIN_COMMON>/machines/`, so the notes fell into a folder with no TOC and the scaffolded TOC stayed empty. recall injects `_index.md` and nothing else — a note outside every index is invisible forever, and no check saw it.
       - **Update that folder's `_index.md` in the same brief** — the writer of a note updates the index in the same commit; there is no after-the-fact regeneration (`vault-tree.md`).
     - **tool *surface* (only when opted in) → the tools layer `<BRAIN_TOOLS>`** (manifest `tools_root`, default `999_tools` — vault-tree.md §The tools root) — MCP inventory (`claude mcp list` and the like) → `tool-mcp.md` · skill list → `tool-skill.md` · installed CLIs (batched `command -v`) → `tool-cli.md` · plugin list → `tool-plugin.md`. These describe `~/.claude/**`, which is machine-global and belongs to no vault.
   - 🔴 **Do not write tool inventories into `<BRAIN_COMMON>` at all.** That is vault scope; two vaults on one machine then keep two copies of one truth and they drift (measured 2026-07-25: 31KB vs 3KB for the same `tool-mcp.md`). **This step owns the layer's creation** — `/brain:init` does not scaffold it (opt-in layer). On a *yes*, have the brief create `<BRAIN_TOOLS>` if absent **and** add the vault `.gitignore` entry (the manifest's `tools_root` value, idempotent — `grep -qxF '<tools_root>/' || echo`; create the ignore file if the vault is a git repo and has none) **before** writing — gitignoring a path after it has been committed does not remove it, and the notes are machine-local and must never reach the shared surface (`git-convention.md` §Share scope).
   - `organization.md` comes **from interview answers**, not measurement (org info around question ②).
   - Rationale: **tools go unused not because the inventory is missing but because it is not recalled** — creation is measurement (this step), recall is the router (the tool-inventory line `/brain:init` put into CLAUDE.local.md), checking is worker discipline (worker).

7. **Answer → application mapping**:
   - **① Ticket system** → update `ticket-system` in `CLAUDE.md` (brain config; pre-split projects: wherever the key currently lives). **Identifier only** — real credentials go in neither CLAUDE file (separate env named for the system in use, e.g. `~/.config/claude/<system>.env`). If there is a system, confirm the project identifier and MCP availability, and record the session `related_ticket` mapping (which system's issue IDs get written) in the brain config. If none, `ticket-system: none` — manage via session To-Dos only.
   - **② Goal** → `PRD` (planning brief). If a revenue model is mentioned, that goes in **`PRD` §BM** — the only original for pricing · tiers · unit economics (`docs/project-docs-convention.md` §Value Axes). GTM/channel content is **`MARKETING.md`**, which is situational and created on trigger, not here.
   - **③ Stack** → `CODE_CONVENTION` · `ARCHITECTURE` (architecture brief) · **`RUNBOOK` §Delivery** (devops label). Classify from Q1/Q2 and record the bucket in `RUNBOOK` §Delivery:
     - Q1 *I control* + Q2 *SaaS* → **server-SaaS** · Q1 *I control* + Q2 *personal/internal* → **server-personal** · Q1 *someone else controls* → **client** (Q2 skipped).
     - Recording the bucket gives the stub real content — the same write flips `RUNBOOK` `status: created → draft` (pre-created rule, `docs/project-docs-convention.md`; the init-seeded §Delivery pointer alone does not clear it — the bucket does).
     - 🔴 **Never hardcode a git-flow value.** The flow is decided by **the vault's delivery classification note** — a classification table mapping project type → flow (org is only where documents live; there is no single org-default flow). The note's path differs per vault (binding: `<BRAIN_COMMON>/policies/`, e.g. `DELIVERY_STRATEGY.md` · stabilizing: a non-binding reference in `<BRAIN_COMMON>/facts/`, promoted when stable) — resolve it in this vault and make `RUNBOOK` §Delivery **point**; never restate the flow or the bucket rules (restate → drift).
     - **Q3 (design tool)** → recorded when `DESIGN` gets created (UI products — `DESIGN` stays situational): tool named → that link seeds `DESIGN` §SSOT · none → the repo component source is the SSOT (code-first; git history = change history). Body canon: `docs/doc-templates.md`.
   - **④ Regulation** → decides the priority of `COMPLIANCE` · `THREAT_MODEL`.
   - **⑤ Deployment** → `RUNBOOK`.

8. **Fill only what was answered** — delegate the corresponding stub→draft filling as worker briefs. Include the **verbatim answers** in the brief, and follow the doc-catalog.md **owner column** for per-document labels. Once filled, change frontmatter to `status: draft` immediately (stub rule), **stamp `updated:` with the write datetime** (`YYYY-MM-DDTHH:MM:SS`, the scribe machine stamp — format canon sessions-note-convention.md), **and append one `history:` entry** — `- { at: <datetime>, change: <one line>, ticket: "…" }`, ticket optional (frontmatter v2 standard, project-docs-convention.md).
   - **If unknown, mark "TBD" — keep the stub. Never force-fill** (stub = no-information rule, project-docs-convention.md).

9. **Report** — list of filled documents + remaining stubs + paths of the notes created/updated by the environment check (the resolved machines sub-axis under `<BRAIN_COMMON>` always — plus that folder's `_index.md`; `<BRAIN_TOOLS>` only when the tool inventory was opted in).
