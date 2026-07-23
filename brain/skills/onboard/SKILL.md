---
name: onboard
description: Project content interview — asks 5 questions (ticket system, goal, stack, regulation, deployment), fills stub documents to draft only as far as answers were given, and creates/updates the facts tool inventory via the step 6 environment check (live measurement). Use when the user says "onboard", "project interview", "fill in the docs", "프로젝트 인터뷰", "문서 채우기". Prerequisite is a completed init — structure setup is init.
---

# onboard — Project Interview (content filling)

Fills **content** into the structure init laid down — get answers through an interview, then fill **only what was answered** via worker briefs, stub→draft. Canonical document selection & owner labels = `${CLAUDE_SKILL_DIR}/../../docs/doc-catalog.md` · canonical vault-write governance = `${CLAUDE_SKILL_DIR}/../../docs/memory-control-convention.md`.

## Prerequisite

`CLAUDE.local.md` must contain `## brain config` (vault-root, project, prefix). **If missing, stop and point the user to `/brain:init` first** — do not write to arbitrary paths.

## Steps

**Steps 1–5 = 5 questions — ask them all at once** (use AskUserQuestion). Ask in the user's language:

1. **Do you use an external ticket system?** — Huly · Jira · Linear · GitHub Issues · none
2. **What is the goal?** — what you are building and why
3. **Is the tech stack decided?** Plus two delivery-classification sub-questions (they decide `GIT_STRATEGY`):
   - **Q1 — Who controls deployment?** *I control* (server · web · GitOps · self-host) or *someone else controls* (store review · shipped binary — mobile app, browser extension, other **client artifacts**).
   - **Q2 — Real-user SaaS?** *SaaS* or *personal / internal*. **Only applies to the "I control (server)" bucket** (DELIVERY_STRATEGY §2, Axis 2).
4. **Any regulation or sensitive data?** — personal data, payments, AI disclosure
5. **Any deployment target?**

6. **Environment check — measurement, not interview.** Delegate as **one** `worker` brief — investigate via commands and create/update the `000_common/facts/` notes (canonical tree vault-tree.md). **Idempotent** — refresh existing notes with live measurements and stamp `verified: <date>`.
   - Investigation → note mapping: OS, hostname, main tools → `machines/<hostname>.md` · MCP inventory (`claude mcp list` and the like) → `tool-mcp.md` · skill list → `tool-skill.md` · installed CLIs (batched `command -v`) → `tool-cli.md` · plugin list → `tool-plugin.md`
   - `organization.md` comes **from interview answers**, not measurement (org info around question ②).
   - Rationale: **tools go unused not because the inventory is missing but because it is not recalled** — creation is measurement (this step), recall is the router (the tool-inventory line `/brain:init` put into CLAUDE.local.md), checking is worker discipline (worker).

7. **Answer → application mapping**:
   - **① Ticket system** → update `ticket-system` in `CLAUDE.local.md`. If there is a system, confirm the project identifier and MCP availability, and record the session `related_ticket` mapping (which system's issue IDs get written) in the brain config. If none, `ticket-system: none` — manage via session To-Dos only.
   - **② Goal** → `PRD` (planning brief). If a revenue model is mentioned, also `BM`.
   - **③ Stack** → `CODE_CONVENTION` · `ARCHITECTURE` (architecture brief) · `GIT_STRATEGY` (devops label). Classify from Q1/Q2 and record the bucket in `GIT_STRATEGY`:
     - Q1 *I control* + Q2 *SaaS* → **server-SaaS** · Q1 *I control* + Q2 *personal/internal* → **server-personal** · Q1 *someone else controls* → **client** (Q2 skipped).
     - 🔴 **Never hardcode a git-flow value.** The org default flow is keyed by the brain-config `org` and defined in the common policy `DELIVERY_STRATEGY` (`000_common/policies/`) §0; the bucket rules are §1–3. The `GIT_STRATEGY` stub **points** at that policy — it never restates the flow or the bucket rules (restate → drift).
   - **④ Regulation** → decides the priority of `COMPLIANCE` · `THREAT_MODEL`.
   - **⑤ Deployment** → `RUNBOOK`.

8. **Fill only what was answered** — delegate the corresponding stub→draft filling as worker briefs. Include the **verbatim answers** in the brief, and follow the doc-catalog.md **owner column** for per-document labels. Once filled, change frontmatter to `status: draft` immediately (stub rule).
   - **If unknown, mark "TBD" — keep the stub. Never force-fill** (stub = no-information rule, project-docs-convention.md).

9. **Report** — list of filled documents + remaining stubs + paths of facts notes created/updated by the environment check.
