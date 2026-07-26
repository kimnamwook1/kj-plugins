# brain

**A memory harness for Claude Code.** Session capture → knowledge promotion → recall, on an
Obsidian-compatible vault, orchestrated through a PM-and-workers model.

The root metaphor is the human memory system: the **hippocampus** makes fast, lossy episodic
captures; **sleep consolidation** replays, prunes, and converts them into semantic memory; the
**neocortex** holds that semantic long-term memory; and retrieval works by **cue-based recall**.
brain maps each stage onto a concrete mechanism — session notes, the Dreaming skill, a layered
knowledge vault, and a trigger-first recall step at session start.

## Why

Three observations drive the design:

1. **Agents forget everything between sessions.** Every session starts from zero; the same
   mistakes recur, the same environment facts get re-derived, and the same dead ends get
   re-explored. brain makes each session leave a durable, structured trace.
2. **Knowledge that exists but isn't retrieved doesn't exist.** Capture without recall is a
   write-only archive. brain treats retrieval as a first-class problem: notes are written
   trigger-first (when does this apply?), and a recall step primes every new session with the
   knowledge and past mistakes relevant to the work at hand.
3. **Personas are dead.** Giving agents characters ("you are a meticulous senior engineer…")
   does not survive contact with real work. What actually survives is **context isolation,
   runtime permissions, and the brief.** So brain ships three worker *profiles* differing only
   in isolation and permissions, and scopes every task with a brief — not a personality.

Beneath these sits one operating principle: **fast-lossy capture + periodic consolidation.**
Real-time writing is kept cheap and imperfect — if capture is heavy, it stops happening. The
hard work (dedup, re-layering, staleness) is deferred to a periodic batch job (Dreaming),
exactly as the brain defers consolidation to sleep.

## Architecture

```
                 ┌────────────────────────────────────────────────┐
                 │           Vault (Obsidian-compatible)          │
                 │                                                │
                 │  000_common/          NNN_<project>/           │
                 │    facts/ patterns/     knowledge/  docs/      │
                 │    policies/                                   │
                 │  999_tools/           ← machine-global, ignored│
                 │  sessions/<uid>.md    ← episodic capture       │
                 └───────▲───────────────────────────┬────────────┘
                         │ writes                    │ recall at session start
                         │ (scribe briefs only)      │ (grep priming, trigger-first)
                         │                           ▼
  ┌──────────────┐    ┌────────────────────────────────────────────┐
  │ CLAUDE.local │───▶│              PM (main session)             │
  │ .md (router, │    │  decomposes → delegates → aggregates       │
  │ PM role stmt)│    │  Handoffs → reports; commits at            │
  └──────────────┘    │  session boundaries (git = SOT)            │
                      └────────┬──────────────────────▲────────────┘
                               │ briefs               │ Handoffs
                               ▼                      │
                      ┌────────────────────────────────────────────┐
                      │       Workers (subagents, 3 profiles)      │
                      │        worker  ·  coder  ·  verifier       │
                      └────────────────────────────────────────────┘
```

Two layers, deliberately separated:

| Layer | What it does | Mechanism |
|---|---|---|
| **Write** (accumulate, organize) | session capture → knowledge promotion → human-readable docs | the vault + PM/scribe governance |
| **Read** (retrieve, recall) | query accumulated memory at low token cost | recall step (grep priming, trigger-first) + router pointers in `CLAUDE.local.md` |

The vault is always the system of record; read-side indexing can additionally be delegated to an
external read-only index, but nothing on the read side ever owns content.

Brain-to-harness mapping (the design-consistency anchor):

| Brain | This harness |
|---|---|
| Working memory | LLM context / the live session |
| **Hippocampus** — fast, lossy episodic encoding | session notes + `## Progress` (Done/Mistake/Fixed/Learned/Outputs) |
| **Sleep consolidation** — replay, pruning, episodic→semantic | **Dreaming skill** (periodic batch) |
| **Neocortex** — semantic long-term memory | `knowledge/` (per project) + `000_common/` (patterns/facts) |
| **Cue-based recall** | recall step at session start + router pointers (trigger-first) |
| **Synaptic pruning** (forgetting) | Dreaming staleness flags |
| Episodic vs semantic separation | sessions (episodic) vs knowledge (semantic); promotion = the episodic→semantic conversion |

## Install & Quickstart

```
# 1. Install the plugin
/plugin marketplace add kimnamwook1/kj-plugins   # the marketplace repo
/plugin install brain

# 2. Structure setup (once per project)
/brain:init      # writes CLAUDE.md (shared brain config + PM role + worker profiles,
                 # committed) and CLAUDE.local.md (vault-root + router, gitignored) at the
                 # project root, and scaffolds the vault; an existing vault is adopted, not
                 # recreated (structure diff is reported; migration only with your approval)

# 3. Content setup (once per project)
/brain:onboard   # 5-question interview (ticket system · goal · stack · regulation · deploy
                 # target) — fills stub docs to draft for answered questions only — plus a
                 # measured environment check → 999_tools/ inventories + facts/machines/

# 4. Daily loop — one verb, one skill
/brain:ss        # start a NEW tracked session — recall injects relevant knowledge and past
                 # Mistakes into the session Context. Never resumes, never scans for parked
                 # sessions, never even mentions them
/brain:sr        # resume a parked session — the only path back into one; status parked → active,
                 # re-presents goal, latest progress and recall priming (screen-only)
/brain:sl        # list open sessions (parked + active) — read-only, writes nothing, adopts nothing
/brain:sh        # park a session (handoff) — pending markers scanned, knowledge promoted,
                 # status active → parked; sr resumes it later
/brain:sc        # complete a session — closing entry, status → done, promotions finalized

# 5. Periodically
/brain:dreaming  # batch consolidation — dedup proposals, staleness flags, second-stage
                 # promotion to common/patterns, structure audits, recall-layer refresh
```

## Schema check (`scripts/validate.sh`)

The conventions are enforced by documented discipline; this script is the machine-checkable
subset. Runs on macOS stock bash 3.2 with only POSIX userland — `awk` and `find` do the work,
plus `mktemp` `basename` `sort` `wc` `tr` `cat` `rm`. No python/jq/yq, no associative arrays,
no `mapfile`, no `find -printf`, no `grep -P`.

```
scripts/validate.sh <vault-root>            # warn report — findings do not fail the run
scripts/validate.sh <vault-root> --strict   # exits 1 on any finding (CI / pre-commit)
```

Exit codes: `0` clean or warn-only · `1` findings under `--strict` · `2` usage error
(missing/unknown argument, root not a directory, `mktemp` failure). `2` is a *broken run*,
not a clean one — CI should treat it as failure in both modes.

What it checks — **sessions** (`sessions/*.md`, top level only; `index.md` and the
`sample-session.md` schema placeholder excluded, since neither is a session): the six required
frontmatter keys (`uid` `project` `created` `updated` `status` `writer`), `uid` matching
`<PREFIX>-YYYYMMDD-HHMMSS` **and** the filename, and `status` being exactly one of
`active|parked|done` (a document status such as `draft` leaking into a session note is called
out specifically, as is the retired `cancel` — whose message carries the migration instruction:
an abandoned session is `done` + an `abandoned` tag). **Knowledge notes** — the top level of each `NNN_<project>/knowledge/` and
of `000_common/{facts,patterns,policies}/` and of `999_tools/`: `title:` present. Subdirectories
are not scanned, matching the flat scan in
`skills/_session-shared/recall.md`, which also supplies the `index.md` + `0.*` meta exclusion —
with one surgical exception, `000_common/facts/machines/`, added as an explicit scan root
(one note per machine, which recall reads). This scan is the recall mirror, so it tracks recall's
roots exactly; `999_tools/` is here because recall scans it as a `[C]` source.

**Session-uid wikilinks on the shared surface** — every `*.md` under `NNN_*/docs/`,
`NNN_*/knowledge/` and `000_common/` (recursive, no meta-file exclusion): a `[[…]]` whose
target is a session uid is a finding. Canon is `docs/versioning-convention.md` §Share scope —
`sessions/` sits outside the team-shared surface and a team vault gitignores it, so the link
dangles in a teammate's vault; a shared note cites a session as **plain uid text**. Catches
`[[uid]]`, `[[sessions/uid]]`, `[[uid|alias]]`, `[[uid#heading]]`, `![[uid]]`, for both the
`<PREFIX>-YYYYMMDD-HHMMSS` form and the PREFIX-less dreaming-report form. 🔴 **`sessions/`
itself is not scanned** — a session's own wikilinks are its record, and neither is `999_tools/`,
which is gitignored and therefore not shared surface at all. Wikilinks between vault
*documents* (`[[<PREFIX>-ADR-0000N]]`, `[[<ID>]]`) are untouched; only session targets are
banned.

Every run prints the scanned file counts (`OK — no issues (22 sessions, 271 knowledge, 640
shared)`) so a collapsed scan is visibly different from a clean vault — "OK" alone cannot
distinguish the two.
Unreadable files are reported as findings rather than skipped, so `--strict` cannot pass a file
it never read. Output is `file:line: message`, so editors and terminals can jump straight to it.

`scripts/validate-selftest.sh` builds a throwaway vault of deliberately broken fixtures and
asserts the rules fire — run it after touching the validator. Its assert set is mutation-tested:
each scope boundary is pinned by a *positive* fixture, because a lone "no finding here" assert
cannot distinguish "scanned and clean" from "never scanned". Known limits are recorded as
`ponytail:` comments in the validator (duplicate keys are last-wins, the uid check is shape-only,
symlinks are skipped) — they are accepted, not unnoticed.

## The vault

Canonical tree, paths, and naming rules live in `docs/vault-tree.md` — summary only:

```
<vault-root>/
  000_common/            # cross-project knowledge
    facts/               #   environment facts incl. machines/ (measured, not remembered)
    patterns/            #   distilled cross-project lessons (promoted by Dreaming)
    policies/            #   org-wide norms (mandatory; wins document conflicts)
    dream-log.md         #   incremental baseline for the next Dreaming run
  NNN_<project>/         # one folder per project (NNN = 001–899 project band, slug = identity)
    index.md             #   project hub — pointer index + project PREFIX
    knowledge/           #   project-scoped reusable knowledge (semantic, atomic notes)
    docs/                #   official docs — tech-design/ · adr/ · research/ · business/
                         #   policy/ · feature/<F>/ (FRD · TDC — diagrams live in its
                         #   §Diagrams — · feature policies)
  999_tools/             # machine-global tool inventory — git-untracked, 9xx = reserved band
    tool-{mcp,skill,cli,plugin}.md
  sessions/
    <uid>.md             # one file per session (episodic); uid = PREFIX-YYYYMMDD-HHMMSS
```

`000_common/` is *vault* scope ("common to every project here"); `999_tools/` is *machine* scope
("true of this box, whatever vault you opened"). Keeping tool inventories on the vault axis gave
N vaults N diverging copies of one truth — measured 2026-07-25, the same `tool-mcp.md` was 31KB in
one vault and 3KB in another. `machines/` stays under `facts/`: machine *configuration* is a vault
fact (which boxes this vault's work runs on), machine *tool surface* is not.

The `9xx` band is reserved for vault infrastructure and is **never** allocated to a project — the
`[0-9]*_*` glob matches it, so anything computing the next project number must exclude it or the
next project becomes `1000_`.

The three axes of `000_common/`:

| Axis | Answers | Nature |
|---|---|---|
| `facts/` | what is true here | environment facts — measured, dated (`verified:`) |
| `patterns/` | what works | reusable techniques distilled across projects |
| `policies/` | what is mandatory | norms with teeth — highest precedence in document conflicts |

## Worker profiles

Three profiles in `agents/`, differing only in isolation and permissions:

| Profile | Enforcement | Use for |
|---|---|---|
| `worker` | default toolset | any brief — the default profile; scribe (recording) briefs run on it too |
| `coder` | `isolation: worktree` | implementation briefs — TDD, official-docs-first, in an isolated git worktree |
| `verifier` | `disallowedTools: Write, Edit, NotebookEdit` | verification/review/disproof briefs — report-only, reproduction + evidence |

- **Ticket loop**: non-trivial tickets run plan → code (`coder`) → verify (`verifier`); small
  changes go direct on a single `worker`.
- **A `coder`'s first action is a base check, before any brief work.** The harness cuts the
  worktree branch from `origin/<branch>`, not from local `main`, so a stale base is the default
  — behind with no local commits, the coder resets to the integration branch itself; behind
  *with* commits, it stops and reports. The `Agent` tool takes no name parameter, so the coder
  also creates its own `<type>/<PREFIX>-<number>-<title-slug>` branch and reports it on the first line
  of `Outputs` — the PM merges by name, then deletes with `git branch -d` (never `-D`) so an
  unmerged branch cannot be dropped. Canon → `agents/coder.md`, `docs/versioning-convention.md`.
- **A `coder`'s last action is a PR — but only if the remote demands one.** Whether a change
  needs a pull request is measured off the host, not chosen: query *both* classic branch
  protection and rulesets (either can gate, and a repo can fail the first while the second
  makes a PR mandatory). No gate → the coder stops at the branch and the PM merges locally.
  A gate → the coder pushes its own topic branch and opens a **draft** PR, which it cannot
  merge; the PM verifies and flips it to ready. Content = whoever did the work, release = the
  PM, the same axis as `Docs draft`. Canon → `docs/versioning-convention.md` §Pull / merge
  requests.
- **Nested spawning**: workers may spawn sub-workers when parallelism, isolation, or a
  fresh-eyes verification pays off. Reports flow upward only (recursive star) — a sub-worker
  reports to its parent, never sideways.
- **Personas are briefs, not agents.** Labels like `scribe` name a *kind of brief*, not a
  resident agent. Every worker is scoped by the brief it receives: Goal, constraints, context
  pointers, DoD.
- **Handoff format (fixed)**: `Done / Mistake / Fixed / Learned / Outputs / Risks / Next / Ask`
  (+ optional `Docs draft` — a worker-authored document draft; the scribe copies it verbatim,
  never authors). Workers never write to the vault directly — deliverables travel by Handoff,
  and the PM delegates recording to a scribe brief.

## Conventions (docs/)

Eight convention documents define the system; each fact has exactly one home:

| Document | Defines |
|---|---|
| `docs/vault-tree.md` | the canonical vault tree, paths, and naming rules |
| `docs/sessions-note-convention.md` | session note schema — file-per-session, frontmatter, the 3-value `status` |
| `docs/knowledge-convention.md` | the atomic, trigger-first knowledge note format |
| `docs/knowledge-escalate-convention.md` | the 3-stage promotion topology (episodic → semantic) |
| `docs/memory-control-convention.md` | Handoff format, recall, Dreaming, and scribe governance |
| `docs/versioning-convention.md` | git = SOT, commit-only lifecycle, push only on explicit request, PR path measured off the remote |
| `docs/project-docs-convention.md` | doc frontmatter standard, stub rules, policy system, ID minting, conflict precedence |
| `docs/doc-catalog.md` | which document to create when — grade, trigger, owner label |

### Ownership boundary — plugin vs vault

The plugin owns **rules**; a vault owns **content**. One plugin serves every vault; the vaults
themselves stay separate on purpose — git, dev, and ops strategy legitimately differ per vault,
so merging them is not a fix for anything.

| Layer | What | Owner | Shared across vaults |
|---|---|---|---|
| **Rules** | session schema · promotion gate · the 3 `status` values · doc frontmatter · conflict precedence | `brain/` (this plugin) | yes — one copy for all vaults |
| **Content** | git/dev/ops strategy · infra facts · knowledge notes · policies · session records | vault `000_common/` + `NNN_<project>/` | no — per vault |

Rule: **a vault `index.md` points at a rule, it never restates one.** An index that repeats a
threshold, a status set, or a naming rule is a fork waiting to happen — the copy ages, and the
work downstream follows the aged copy rather than the canon.

Pointer form, as used in `000_common/policies/index.md`:

```
> canonical (identification · IDs · promotion · precedence) =
>   <home>/.claude/brain-docs/project-docs-convention.md — do not copy here (it drifts).
```

Point at the stable `~/.claude/brain-docs/` symlink, never at the plugin install path
(`skills/init/SKILL.md`) — the install path dies on the next version bump.

The reverse direction is already clean: no org slug, infra host, domain, or account-specific CLI
wrapper appears anywhere under `brain/` (only the plugin manifest's `author` field names a
person). Content does not leak into the rules — only rules leak into vaults, which is exactly
what the pointer rule above closes.

### Single-Source Map (anti-drift)

When the same fact is restated in several documents, changing one desynchronizes the rest —
the number-one failure mode of documentation systems. Rule: each fact below is **defined in
exactly one canonical place**; every other document points at it ("canonical: X") instead of
restating it. The Dreaming drift-lint periodically scans for restatements and contradictions
against this map.

**Scope: this map binds vault scaffolds too** — `index.md` files and any other generated vault
text are documents for drift-lint purposes. Every canonical home below is a plugin doc, and per
the ownership boundary no vault path can become one; a vault file restating a value in this
table is a finding, not a convenience.

| Fact | Canonical (defined only here) | Pointers only (no restating) |
|---|---|---|
| Session schema (file-per-session · frontmatter · 3-value status) | `docs/sessions-note-convention.md` | root index · `skills/ss`·`sr` · dreaming |
| Vault tree, paths, naming rules | `docs/vault-tree.md` | doc-catalog · `/brain:init` |
| External ticket system = canonical work queue | PM role statement (`CLAUDE.md`, written by `/brain:init`) | sessions-note-convention |
| Promotion two-gate judgment (score sum ≥ 3 + verdict enum `promote/already_known/not_durable/unsupported` · reject-log) | `skills/_session-shared/knowledge-promotion.md` | knowledge-escalate-convention · `skills/sh`·`sc` · dreaming |
| Human sign-off gate for `common/policies/` (agents draft, the user signs) | `docs/knowledge-escalate-convention.md` | knowledge-promotion · `skills/sh`·`sc` · dreaming |
| Third-time test (reject-log recurrence → rule) | `skills/dreaming/SKILL.md` §3 | knowledge-promotion |
| Feedback counters (`recalled:`/`useful:` · once-per-session marker · no auto-delete) | `docs/knowledge-convention.md` §Feedback counters | recall · `skills/ss`·`sh`·`sc` · dreaming (`sr` re-presents recall but bumps nothing) |
| Session-Mistake recurrence scan (similarity test · cap · suppression keys) | `skills/dreaming/SKILL.md` §3 | knowledge-convention (`source_items` fallback) |
| dream-log format (run heading · project field · cumulative read) | `skills/dreaming/SKILL.md` §7 | root index · vault-tree |
| Recall (grep priming · source_location · related 1-hop) | `skills/_session-shared/recall.md` | `skills/ss`·`sr` · memory-control-convention |
| Open-session scan + summary extract (`status: active\|parked` × `project` · `\|\| :` loop terminator) | `skills/_session-shared/active-sessions.md` | `skills/sl`·`sr` |
| git = SOT · commit-only lifecycle | `docs/versioning-convention.md` | `skills/ss`·`sh`·`sc` · decision history (WHY only) |
| PR/MR path (gate measured off the remote · draft by coder · ready by PM · topic-branch push carve-out) | `docs/versioning-convention.md` §Pull / merge requests | `agents/coder.md` §Last action · doc-catalog (§Delivery records the measured values) |
| Agent branch naming (`<type>/<PREFIX>-<number>-<title-slug>` · type from the shared vocabulary) | `agents/coder.md` §First action | `docs/versioning-convention.md` §Worktree integration order · doc-catalog §Delivery (human prefixes only) |
| Type vocabulary (the 11 types themselves) | `~/.claude/skills/at/SKILL.md` §타입 접두어 규약 (vault mirror: `000_common/policies/TYPE_VOCABULARY.md`) | 🔴 **never restated in this repo** — `agents/coder.md` · `docs/versioning-convention.md` · doc-catalog all point, none copy |
| Session lifecycle (start / resume / list / park / complete) | `skills/ss`·`sr`·`sl`·`sh`·`sc` | sessions-note-convention · dreaming |
| Doc frontmatter standard (id · status · owner · scope · history) | `docs/project-docs-convention.md` | doc-catalog |
| Stub pre-creation and stub rules | `docs/project-docs-convention.md` | doc-catalog · `/brain:init` |
| Policy system (identification · IDs · promotion) | `docs/project-docs-convention.md` | doc-catalog · dreaming |
| ID minting (`<PREFIX>-<TYPE>-0000N` · next_id) | `docs/project-docs-convention.md` | PM role statement · dreaming |
| API_SPEC mirror rule (sole exception to "repo = code only") | `docs/project-docs-convention.md` | doc-catalog · dreaming |
| Document conflict precedence | `docs/project-docs-convention.md` | PM role statement · all workers |
| Doc selection by kind (grade · trigger · owner) | `docs/doc-catalog.md` | `/brain:init` · PM role statement |

## Design principles

- **One canonical source + pointers.** Facts live in one place; everything else links. Drift
  is a lint failure, not a fact of life.
- **Trigger-first.** Recall is symptom-driven, so notes lead with *when they apply* (the
  trigger), not with what they conclude.
- **Small docs.** Large documents don't get read — by humans or by agents with token budgets.
  Split by concern, keep each unit loadable.
- **stub = no information.** A `status: stub` document must never be cited as evidence — an
  empty heading means "not written yet", not "there is none". Filling it flips it to `draft`.
- **Measurements over memory.** Environment facts come from commands (`command -v`, live
  checks), carry a `verified:` date, and are never asserted from recollection.
- **Fail-visible over fail-silent.** Rejected knowledge promotions go to a reject-log instead
  of vanishing; Dreaming proposes destructive changes instead of silently applying them;
  blocked hooks explain themselves.

## FAQ / Notes

- **Why two config files?** Both load every session, and `/brain:init` manages only its own
  marker-delimited block in each, so your other notes survive. `CLAUDE.md` is committed —
  the shareable half (org · project · prefix · ticket-system identifier, PM role statement,
  worker profiles) reaches every teammate; it is never gitignored. `CLAUDE.local.md` stays
  gitignored — `vault-root` differs per person even on a team, and the router is
  machine-absolute paths. Real credentials go in neither file (separate env).
- **Existing vault? Team-shared vault?** `/brain:init` detects an existing directory and
  switches to adopt mode: it diffs the structure against the canonical tree, reports
  mismatches, and migrates only with explicit approval. Cross-machine sync is a git merge
  layer; within a machine, concurrency is scribe discipline — no locks, the PM serializes
  delegation.
- **The force-delegate hook is opt-in.** Wire `hooks/force-delegate.sh` into PreToolUse
  (matcher `Edit|Write`) only if you want the "PM doesn't write files" rule enforced by
  machinery instead of discipline. Escape hatch: `FORCE_DELEGATE_OFF=1`.
- **Language.** Generated artifacts (docs, notes, scaffolds) default to English. Skill
  descriptions carry Korean trigger phrases alongside English so invocation works naturally
  in both languages; agent profiles are English-only (they are spawned by the PM, not by
  user phrasing).

## License

TBD.
