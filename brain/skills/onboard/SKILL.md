---
name: onboard
description: Project content interview — asks 5 questions (ticket system, goal, stack, regulation, deployment), fills stub documents to draft only as far as answers were given, and creates/updates the facts tool inventory via the step 6 environment check (live measurement). Use when the user says "onboard", "project interview", "fill in the docs", "프로젝트 인터뷰", "문서 채우기". Prerequisite is a completed init — structure setup is init.
---

# onboard — Project Interview (content filling)

Fills **content** into the structure init laid down — get answers through an interview, then fill **only what was answered** via worker briefs, stub→draft. Canonical document selection & owner labels = `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` · canonical vault-write governance = `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Prerequisite

The brain config must be present across the two config files: `CLAUDE.md` `## brain config` (org, project, prefix, ticket-system) + `CLAUDE.local.md` (vault-root, Router). Pre-split projects may still hold everything in `CLAUDE.local.md` — both files load merged, so read both. **If missing, stop and point the user to `/brain:init` first** — do not write to arbitrary paths.

## Steps

**Steps 1–5 = 5 questions — ask them all at once** (use AskUserQuestion). Ask in the user's language:

1. **Do you use an external ticket system?** — Huly · Jira · Linear · GitHub Issues · none
2. **What is the goal?** — what you are building and why
3. **Is the tech stack decided?** Plus three sub-questions — two delivery-classification ones (they decide `RUNBOOK` §Delivery) and one design-tooling one:
   - **Q1 — Who controls deployment?** *I control* (server · web · GitOps · self-host) or *someone else controls* (store review · shipped binary — mobile app, browser extension, other **client artifacts**).
   - **Q2 — Real-user SaaS?** *SaaS* or *personal / internal*. **Only applies to the "I control (server)" bucket** (Axis 2 of the vault's delivery classification note).
   - **Q3 — Do you use a design tool?** (tool-neutral — never suggest a specific tool) *Yes, <name>* → that link becomes `DESIGN` §SSOT · *No* → repo code-first (the repo component source is the SSOT). Only relevant for UI products — skip for headless projects.
4. **Any regulation or sensitive data?** — personal data, payments, AI disclosure
5. **Any deployment target?**

6. **Environment check — measurement, not interview.** Delegate as **one** `worker` brief — investigate via commands and create/update the notes below (canonical tree vault-tree.md). **Idempotent** — refresh existing notes with live measurements and stamp `verified: <date>`.
   - Investigation → note mapping, **two destinations by scope**:
     - **machine *configuration* → `000_common/facts/`** — OS, hostname, main tools → `machines/<hostname>.md`. Which boxes this vault's work runs on is a vault fact.
     - **tool *surface* → `999_tools/`** — MCP inventory (`claude mcp list` and the like) → `tool-mcp.md` · skill list → `tool-skill.md` · installed CLIs (batched `command -v`) → `tool-cli.md` · plugin list → `tool-plugin.md`. These describe `~/.claude/**`, which is machine-global and belongs to no vault (vault-tree.md §`999_tools/`).
   - 🔴 **Do not write tool inventories into `000_common/facts/`.** That is vault scope; two vaults on one machine then keep two copies of one truth and they drift (measured 2026-07-25: 31KB vs 3KB for the same `tool-mcp.md`). If `/brain:init` has not created `999_tools/` yet, have the brief create it **and** add the vault `.gitignore` entry before writing — the notes are machine-local and must never reach the shared surface.
   - `organization.md` comes **from interview answers**, not measurement (org info around question ②).
   - Rationale: **tools go unused not because the inventory is missing but because it is not recalled** — creation is measurement (this step), recall is the router (the tool-inventory line `/brain:init` put into CLAUDE.local.md), checking is worker discipline (worker).

7. **Answer → application mapping**:
   - **① Ticket system** → update `ticket-system` in `CLAUDE.md` (brain config; pre-split projects: wherever the key currently lives). **Identifier only** — real credentials go in neither CLAUDE file (separate env, e.g. `~/.config/claude/huly.env`). If there is a system, confirm the project identifier and MCP availability, and record the session `related_ticket` mapping (which system's issue IDs get written) in the brain config. If none, `ticket-system: none` — manage via session To-Dos only.
   - **② Goal** → `PRD` (planning brief). If a revenue model is mentioned, also `BUSINESS` §BM.
   - **③ Stack** → `CODE_CONVENTION` · `ARCHITECTURE` (architecture brief) · **`RUNBOOK` §Delivery** (devops label). Classify from Q1/Q2 and record the bucket in `RUNBOOK` §Delivery:
     - Q1 *I control* + Q2 *SaaS* → **server-SaaS** · Q1 *I control* + Q2 *personal/internal* → **server-personal** · Q1 *someone else controls* → **client** (Q2 skipped).
     - Recording the bucket gives the stub real content — the same write flips `RUNBOOK` `status: stub → draft` (stub rule, `docs/project-docs-convention.md`; the init-seeded §Delivery pointer alone does not clear stub — the bucket does).
     - 🔴 **Never hardcode a git-flow value.** The flow is decided by **the vault's delivery classification note** — a classification table mapping project type → flow (org is only where documents live; there is no single org-default flow). The note's path differs per vault (binding: `000_common/policies/`, e.g. `DELIVERY_STRATEGY.md` · stabilizing: a non-binding reference in `000_common/facts/`, promoted when stable) — resolve it in this vault and make `RUNBOOK` §Delivery **point**; never restate the flow or the bucket rules (restate → drift).
     - **Q3 (design tool)** → recorded when `DESIGN` gets created (UI products — `DESIGN` stays situational): tool named → that link seeds `DESIGN` §SSOT · none → the repo component source is the SSOT (code-first; git history = change history). Body canon: `docs/doc-templates.md`.
   - **④ Regulation** → decides the priority of `COMPLIANCE` · `THREAT_MODEL`.
   - **⑤ Deployment** → `RUNBOOK`.

8. **Fill only what was answered** — delegate the corresponding stub→draft filling as worker briefs. Include the **verbatim answers** in the brief, and follow the doc-catalog.md **owner column** for per-document labels. Once filled, change frontmatter to `status: draft` immediately (stub rule).
   - **If unknown, mark "TBD" — keep the stub. Never force-fill** (stub = no-information rule, project-docs-convention.md).

9. **Report** — list of filled documents + remaining stubs + paths of the notes created/updated by the environment check (both destinations — `000_common/facts/` and `999_tools/`).
