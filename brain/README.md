# brain

**A memory harness for Claude Code.** Session capture → knowledge promotion → recall, on an
Obsidian-compatible vault, orchestrated through a PM-and-workers model.

The root metaphor is the human memory system — fast, lossy episodic capture; sleep-time
consolidation; semantic long-term memory; cue-based recall. In 0.3.0 that mapping is carried by
**two flat folders and two frontmatter keys** — `sessions/`, `memory/`, `scope`, `kind` — not by
a folder taxonomy. Session notes are the episodic layer, `memory/` is the semantic layer,
Dreaming is the sleep-time batch, and the recall step at session start is the cue.

## Why

1. **Agents forget everything between sessions.** Every session starts from zero; the same
   mistakes recur, the same environment facts get re-derived, the same dead ends get re-explored.
   brain makes each session leave a durable, structured trace.
2. **Knowledge that exists but isn't retrieved doesn't exist.** Capture without recall is a
   write-only archive. Every memory note's `summary` line carries both a trigger ("when does this
   apply?") and a claim, and a bounded recall step primes every new session with exactly the
   index rows scoped to the current project — so the agent knows what exists and opens only what
   it needs.
3. **Personas are dead.** What survives contact with real work is **context isolation, runtime
   permissions, and the brief** — so brain ships worker *profiles* differing only in isolation
   and permissions, and scopes every task with a brief, not a personality.

Beneath these sits one operating principle: **fast-lossy capture + periodic consolidation.**
Real-time writing stays cheap; the hard work (dedup, refinement, cross-project promotion) is
deferred to a batch job (Dreaming), exactly as the brain defers consolidation to sleep.

## Five design principles

1. **Bounded injection** — recall has a hard 8 KiB cap; overflow is truncated and reported.
2. **The PM writes directly** — no scribe relay. Vault writes (sessions, `memory/`) are the PM's
   own `Write`/`Edit` calls; workers hand results up through Handoffs.
3. **Single source of truth** — every format lives in exactly one canon file; skills read it,
   they don't copy it (copies drift).
4. **Fail-visible** — counters are always printed; zero is reported as zero, never as silence.
5. **Explicit declaration** — identifiers (`project:`, `ticket-prefix:`) come from declared
   config, never derived from paths or folder names.

## The vault — two flat layers

```
<vault>/                 # vault root = org boundary (one vault per org)
  sessions/              # session notes — outside git (vault .gitignore), volatile layer
  memory/                # all knowledge, one flat tree — no folder hierarchy
    _index.md            # single shared index: - [[<stem>]] (kjp, org) — <summary>
```

- A **session note** (`<project>_<YYYYMMDD>_<slug>.md`) has 5 frontmatter keys
  (`status: active|parked|done` · `project` · `updated` · `related_ticket` · `cc_session_ids`)
  and 4 fixed sections: `## Goal` · `## Recall` · `## To-Do` · `## Progress`.
- A **memory note** (`<topic-kebab>.md`) has 4 frontmatter keys (`summary` · `scope` · `kind` ·
  `updated`) and 2 sections: `## Insight` · `## Why`. The distinguishing axes are frontmatter,
  not folders: `scope` lists the projects a note applies to (`org` = company-wide; two or more
  entries = cross-project knowledge), `kind` is `fact` or `policy`.
- **Promotion, two gates**: ① at session close (`sc`) the PM writes what the session taught into
  `memory/` + the index, in the same commit; ② Dreaming widens a note's `scope` by one line when
  another project confirms the same lesson. No file moves, no link rewiring.
- Vault prose is bullet-only — one line, one fact. Writes go through `Write`/`Edit` only
  (`Edit`'s old_string is a compare-and-swap).

## Skills (8)

| Skill | Does | Never does |
|---|---|---|
| `/brain:init` | Structure setup, once per project — AGENTS.md + CLAUDE.md marker block (byte-identical), `CLAUDE.local.md` (`vault-root:`, one key), vault scaffold (`sessions/` + `memory/` + `_index.md`), .gitignore | content interview |
| `/brain:onboard` | Grill-style content interview — one question at a time with a recommended answer, measured answers over asked ones, documents created lazily in repo `docs/` as answers firm up, ADRs behind a triple gate, open questions become tickets | batch questionnaires, stub pre-creation |
| `/brain:ss` | Start a NEW session — uniqueness check before create (collision → asks for a slug), recall injection (≤ 8 KiB) into `## Recall` | resuming, scanning for parked sessions |
| `/brain:sr` | Resume a parked session — pick, adopt, status → active; re-injects Goal + open To-Dos + the latest Progress entry only | creating |
| `/brain:sl` | List open sessions — read-only, one line each | writing, adopting |
| `/brain:sh` | Park a session — Progress entry (`parked`, with a `next` line), status → parked | promoting knowledge (that is `sc`'s alone) |
| `/brain:sc` | Close a session — status → done, promotion gate ① into `memory/`, doc routing to repo `docs/`, then a one-line Dreaming suggestion (`미통합 N건`) | running Dreaming itself |
| `/brain:dreaming` | Batch consolidation — Refine (facts unchanged) + promotion gate ② (scope widening); vault lock, incremental cursor, 1 run = 1 commit; destructive changes are proposal-only | touching sessions, auto-applying merges/deletes |

## Agents (4)

| Profile | Role | Boundary |
|---|---|---|
| `worker` | General ticket/brief execution | shared KERNEL |
| `coder` | Implementation only | `isolation: worktree` (off when Orca opened the workspace worktree — one isolation owner) |
| `verifier` | Verification, review, refutation | report-only (`disallowedTools: Write, Edit, NotebookEdit`) |
| `researcher` | External evidence gathering | report-only; primary sources first, counter-evidence mandatory |

All four share a byte-identical **KERNEL block**: the brief is the whole scope, measure before
asserting, cite evidence per claim, never write the vault (results flow up as a fixed 7-section
Handoff — vault writes are the PM's), reports flow upward only.

## Hooks & scripts

Two hook events, four scripts — bash 3.2 + POSIX, zero dependencies, `file:line: message`
output, scan counters always printed, each with a fixture-based selftest.

| Piece | Does |
|---|---|
| `SessionStart` hook | re-links `~/.claude/brain-docs` → plugin `docs/`, then `brain-check.sh --quiet` (findings only; silence = pass) |
| `PostToolUse` hook (Edit\|Write\|NotebookEdit) | runs `brain-check.sh` only when the target is AGENTS.md / CLAUDE.md / `agents/*.md` — findings to stderr + exit 2 |
| `hooks/brain-check.sh` | block-comparison checker — AGENTS.md ↔ CLAUDE.md marker blocks byte-identical; the 4 agents' KERNEL blocks byte-identical; zero files scanned = a finding |
| `scripts/brain-validate.sh` | schema linter — vault mode (session/memory keys, status and kind vocabularies, Progress heading and category grammar, index integrity, contamination patterns) + repo mode (docs frontmatter, ADR IDs, COMPLIANCE §Legal Sources, value-axis drift) |
| `scripts/brain-recall` | on-demand query — `brain-recall <query> [--scope <id>] [-n N]`, grep over `summary` lines, top-N note bodies (default 3); read-only. The consumption path for non-Claude agents (codex, grok) |
| `scripts/brain-canon` | canon section extractor — `brain-canon <key>[,<key>...]` prints only the `memory.md` sections a skill needs. Skills stopped reading the canon whole: 13.5 KB → 3.4–7.9 KB per session, single source preserved |

There are no write-blocking hooks — the PM writing directly is the design, so nothing needs to
force delegation.

## Canon (3 + annex)

Served at the stable path `~/.claude/brain-docs/` (symlinked to the plugin's `docs/` at session
start). Every file opens by naming its consumers.

| File | Owns |
|---|---|
| `memory.md` | vault structure · note schemas (the single copy of the session 4-section format) · scope/kind · promotion gates · recall spec · dreaming guardrails |
| `project-docs.md` | repo `docs/` tree · POL/FEAT/ADR file naming · feature §FRD/§TDC · COMPLIANCE §Legal Sources · policy precedence (vault `kind: policy, scope: [org]` > repo POL) + override records |
| `git-convention.md` | commit-type vocabulary (11) · the one notation table for ticket/commit/PR/branch/worktree · worktree integration order · PR gate measurement |
| `security-audit.md` (annex, non-canon) | read by `verifier` on security briefs only |

A worked sample of the repo `docs/` tree (fictional project *vidnote*) lives in
[`docs-samples/`](./docs-samples/) — a reference snapshot, not canon.

## Ownership

- **The plugin owns rules** — schemas, formats, vocabularies, checkers. Upgrading the plugin
  upgrades the rules everywhere at once.
- **The vault owns content** — your sessions and knowledge. Nothing in the plugin ever contains
  your data; nothing in the vault defines a format.
- Between them, the repo owns documents: anything reviewed with a code PR lives in repo `docs/`;
  anything learned in a session lives in vault `memory/`. Knowledge files in the repo are
  forbidden.

## Install

```
/plugin marketplace add kimnamwook1/kj-plugins
/plugin install brain
```

Then `/brain:init` once per project, `/brain:onboard` for the content interview, and the daily
loop is `ss` / `sr` / `sl` / `sh` / `sc` with `/brain:dreaming` when `sc` suggests it.
