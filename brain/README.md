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
   indexes of the memory accumulated around this work — so the agent knows what exists and
   opens only what it needs.
3. **Personas are dead.** Giving agents characters ("you are a meticulous senior engineer…")
   does not survive contact with real work. What actually survives is **context isolation,
   runtime permissions, and the brief.** So brain ships three worker *profiles* differing only
   in isolation and permissions, and scopes every task with a brief — not a personality.

Beneath these sits one operating principle: **fast-lossy capture + periodic consolidation.**
Real-time writing is kept cheap and imperfect — if capture is heavy, it stops happening. The
hard work (folding duplicates together, linking, re-tiering) is deferred to a periodic batch job
(Dreaming), exactly as the brain defers consolidation to sleep.

## Architecture

```
                 ┌────────────────────────────────────────────────┐
                 │           Vault (Obsidian-compatible)          │
                 │                                                │
                 │  <common_root>/       <projects_root>/NNN_<p>/ │
                 │    fact record          p_memory/  docs/       │
                 │  neocortex/           ← vault-wide knowledge   │
                 │  <tools_root>/        ← machine-global, ignored│
                 │  hippocampus/*.md     ← episodic capture       │
                 └───────▲───────────────────────────┬────────────┘
                         │ writes                    │ recall at session start
                         │ (scribe briefs only)      │ (folder indexes, whole)
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
                      │ worker · coder · verifier · researcher     │
                      └────────────────────────────────────────────┘
```

Three roots in that box are **per-vault facts** — common · projects · tools — declared in
`<vault>/.brain-paths` and resolved by `scripts/vault-paths.sh`; `neocortex/` and `hippocampus/`
are root-fixed and take no manifest key (see *The vault* below).

Two layers, deliberately separated:

| Layer | What it does | Mechanism |
|---|---|---|
| **Write** (accumulate, organize) | session capture → knowledge promotion → human-readable docs | the vault + PM/scribe governance |
| **Read** (retrieve, recall) | query accumulated memory at low token cost | recall step (the folder indexes, injected whole) + router pointers in `CLAUDE.local.md` |

The vault is always the system of record; read-side indexing can additionally be delegated to an
external read-only index, but nothing on the read side ever owns content.

Brain-to-harness mapping (the design-consistency anchor):

| Brain | This harness |
|---|---|
| Working memory | LLM context / the live session |
| **Hippocampus** — fast, lossy episodic encoding | `hippocampus/` session notes + `## Progress` (Done/Mistake/Fixed/Learned/Outputs) |
| **Sleep consolidation** — replay, pruning, episodic→semantic | **Dreaming skill** (periodic batch) |
| **Neocortex** — semantic long-term memory | `p_memory/` (per project) + `neocortex/` (vault-wide) + the common layer (the fact record) |
| **Cue-based recall** | recall step at session start + router pointers (trigger-first) |
| **Synaptic pruning** (forgetting) | Dreaming folds duplicates together and proposes deletions (never applies them) |
| Episodic vs semantic separation | the raw layer (`hippocampus/`) vs the wiki layer; promotion = the episodic→semantic conversion. 🔴 **The two never point at each other** — nothing is written back into a session |

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
                 # measured environment check → tools-root inventories + the common layer's
                 # machines/ notes

# 4. Daily loop — one verb, one skill
/brain:ss        # start a NEW tracked session — recall injects the relevant folder indexes
                 # into the session's `## Recall`. Never resumes, never scans for parked
                 # sessions, never even mentions them
/brain:sr        # resume a parked session — the only path back into one; status parked → active,
                 # re-presents goal, latest progress and recall priming (screen-only)
/brain:sl        # list open sessions (parked + active) — read-only, writes nothing, adopts nothing
/brain:sh        # park a session (handoff) — pending markers scanned, knowledge promoted,
                 # status active → parked; sr resumes it later
/brain:sc        # complete a session — closing entry, status → done, promotions finalized

# 5. Periodically
/brain:dreaming  # batch consolidation — refine (fold duplicates, facts unchanged), link
                 # (`related`, never a shortcut across two hops), promotion ② (p_memory →
                 # neocortex). Sessions are neither read nor written
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

It runs **four scans**, in this order.

**① Sessions** — the raw layer, `hippocampus/*.md`, top level only (the folder TOC —
`_index.md`, legacy `index.md` — and the `sample-session.md` schema placeholder excluded, since
none is a session). **Five required frontmatter keys**: `status` · `project` · `updated` ·
`related_ticket` · `cc_session_ids` (`updated` carries a full `YYYY-MM-DDTHH:MM:SS` local
datetime; date-only = legacy-legal, format canon `docs/sessions-note-convention.md`). `status`
must be exactly one of `active|parked|done` — a document status such as `draft` leaking into a
session note is called out specifically, as is the retired `cancel`, whose message carries the
migration instruction (an abandoned session is `done` + an `abandoned` tag).

🔴 **There is no identity key, and therefore no identity check.** The filename *is* the
session's identifier, so `uid` · `created` · `writer` are **retired keys** and each is reported
with its own migration instruction. That check exists because "missing key" can say nothing
about a key that is *present and no longer meant to be* — a vault that never dropped them would
otherwise pass in silence.

**Session filenames — two shapes coexist, on purpose.** New sessions are
`<PREFIX>_YYYYMMDD_<slug>.md`, made unique by a **creation-time** check: same day + same slug is
refused, and `ss` asks for a distinguishing slug rather than suffixing silently. Pre-0.2.0
sessions keep the retired `<PREFIX>-YYYYMMDD-HHMMSS.md` shape and are **never renamed** —
measured 2026-08-05, 9 groups / 23 files share a project+day and 3 of those groups are
indistinguishable by any field, so a rename cannot preserve identity. The validator therefore
checks **no filename shape at all**; every consumer reads the frontmatter instead. Canon:
`docs/sessions-note-convention.md`.

**② Wiki notes** — `summary:` present and non-empty, plus **ten retired keys** detected by name
(`uid` `title` `type` `tags` `dri` `species` `source_sessions` `source_items` `recalled`
`useful`). `title:` is a *rename* — `summary:` inherits its seat, because recall injects
`_index.md` and nothing else, and every line there is `- [[stem]] — <summary>`; a note without
one is invisible to every future session rather than merely untitled. The other nine are retired
outright: 0.2.0 wiki frontmatter is `summary` · `updated` · `related` · `aliases`, plus
`projects` on `neocortex/`. Scan roots, all resolved through the vault's `.brain-paths` manifest
(`scripts/vault-paths.sh`): each project folder's `p_memory/`, `neocortex/`, and the tools root —
**top level only**, subdirectories deliberately out of scope — plus the common layer, which
**recurses** instead, because its sub-axes are not the same shape in every vault and enumerating
them here would put the tree back into the script. The common layer's exclusions (meta files,
`_templates/`, archives, dreaming logs) live in `brain_find_notes`, the sole copy.

**③ Session-uid wikilinks on the shared surface** — every `*.md` under each project folder's
`docs/` and `p_memory/` and the whole common layer (roots per `.brain-paths`; recursive, and
**no** meta-file exclusion — a dangling link in `index.md` breaks for a teammate exactly like
one in a note). A `[[…]]` whose target is a session uid is a finding. Canon is
`docs/git-convention.md` §Share scope — `hippocampus/` is git-untracked in 0.2.0, so the link
dangles in any vault that lacks that session; a shared note cites a session as **plain uid
text**. Catches `[[uid]]`, `[[hippocampus/uid]]` (any path prefix), `[[uid|alias]]`,
`[[uid#heading]]`, `![[uid]]`.

> ⚠ **The shape it looks for is the legacy `<PREFIX>-YYYYMMDD-HHMMSS` one (PREFIX optional), and
> that is deliberate, not a stale pattern.** 0.2.0 filenames are `<PREFIX>_YYYYMMDD_<slug>`, so
> this scan now catches *migration-era* links rather than links a fresh vault could produce.

🔴 Not scanned here: `hippocampus/` itself (a session's own wikilinks are its record, and no one
else ever pulls the file); the tools root (gitignored machine-local content — outside the shared
surface by definition, so this is not a scope divergence); and `neocortex/`, which **is**
tracked and shared — that one is a known gap, scope left as the 0.2.0 migration found it rather
than reasoned about, flagged in the script to revisit when the dangling-link check lands.
Wikilinks between vault *documents* (`[[<PREFIX>-ADR-0000N]]`, `[[<ID>]]`) are untouched; only
session targets are banned.

**④ Docs frontmatter (v2)** — `NNN_*/docs/**`, recursive. Findings (blocked by `--strict`): a
`session:` key anywhere in the frontmatter, in any YAML shape and quoted or not — `hippocampus/`
is git-untracked, so even a plain uid is a reference no teammate can resolve, and team provenance
rides the history `ticket:` instead; `status:` absent or outside
`created|draft|approved|deprecated` (meta files exempt — they are folder TOCs, not body
documents); the v1 history subkeys `date:`/`by:`, which hid inside `- { … }` entries where the
top-level key regex could not see them; `docs/adr/` body files without `id:` and
its folder index without `next_id:`; `API_SPEC.md` without `source:` + `readonly: true`.
**Warns** (stderr only, never a finding, never a `--strict` failure): unknown top-level keys, and
an `updated:` that is not a full datetime. The retired docs status `stub` gets its own migration
message — a pre-created empty document is `created`.

Every run prints **all four** scanned file counts, so a collapsed scan is visibly different from a
clean vault — "OK" alone cannot distinguish the two. Measured on the selftest fixture vault:

```
validate.sh: 52 issue(s) (12 sessions, 17 knowledge, 35 shared, 20 docs) <root>
```

Unreadable files are reported as findings rather than skipped, so `--strict` cannot pass a file
it never read. Output is `file:line: message`, so editors and terminals can jump straight to it.

`scripts/validate-selftest.sh` builds a throwaway vault of deliberately broken fixtures and
asserts the rules fire — run it after touching the validator. Its assert set is mutation-tested:
each scope boundary is pinned by a *positive* fixture, because a lone "no finding here" assert
cannot distinguish "scanned and clean" from "never scanned". Known limits are recorded as
`ponytail:` comments in the validator (duplicate keys are last-wins, the wikilink scan has no
fenced-code-block awareness, symlinks are skipped) — they are accepted, not unnoticed.

## The vault

Canonical tree, paths, and naming rules live in `docs/vault-tree.md` — the summary below shows
the **shape**, with each movable axis written as the manifest key that resolves it:

```
<vault-root>/
  .brain-paths           # the axis manifest — init's first vault write (schema_version + roots)
  <common_root>/         # the fact record — kept current by measurement, not by promotion.
                         # Topics are free; only a *policies* directory segment is structural
                         # (the normative axis). The unattended cycle may not write here
    machines/            #   one note per machine, filename = lowercase hostname
    policies/            #   binding norms — highest precedence in document conflicts
  neocortex/             # vault-wide knowledge — root-fixed, recall target
    NEO-<slug>.md        #   no numbers; the filename is the identity, old names go to aliases:
    dream-logs.md        #   dreaming's run log — one file, appended to
  <projects_root>/
    NNN_<project>/       # one folder per project (NNN = 001–899 project band, slug = identity)
      _index.md          #   project hub — pointer index + project PREFIX
      p_memory/          #   project knowledge (semantic, atomic notes) — recall target
        <pp>_<slug>.md
      docs/              #   official docs — business/ · develop/ · adr/ · resources/ ·
                         #   develop/P_POLICY.md (project rules, one `## POL-NNN` each) ·
                         #   develop/feature/<F>/ (FRD · TDC — diagrams live in its §Diagrams)
  <tools_root>/          # machine-global tool inventory — opt-in (onboard step 6) ·
                         # git-untracked, 9xx = reserved band
    tool-{mcp,skill,cli,plugin}.md
  hippocampus/           # sessions (raw, episodic) — git-untracked, never a recall target
    <PREFIX>_YYYYMMDD_<slug>.md   # one file per session; same day + same slug is refused
    <PREFIX>-YYYYMMDD-HHMMSS.md   # pre-0.2.0 shape — kept as-is, never renamed
```

Where three of those axes actually live is a per-vault fact, not canon: `<vault>/.brain-paths`
(plain `key: value` lines — `common_root` · `projects_root` · `tools_root`) re-points the common,
projects, and tools roots, and `scripts/vault-paths.sh` is the single resolver every scanner
sources. A vault that never restructured needs no manifest; a restructured one declares, e.g.,
`common_root: org` + `projects_root: projects`. **Keys, defaults, and resolver functions live in
that script's header — the sole copy, which is why no default path literal appears in this
file.** `neocortex/` and `hippocampus/` are **root-fixed** and carry no manifest key: a
restructured vault moves its common and projects roots and still keeps both exactly here.

The common layer is *vault* scope ("common to every project here"); the tools root is *machine*
scope ("true of this box, whatever vault you opened"). Keeping tool inventories on the vault axis
gave N vaults N diverging copies of one truth — measured 2026-07-25, the same `tool-mcp.md` was
31KB in one vault and 3KB in another. `machines/` stays in the common layer for the mirror-image
reason: machine *configuration* is a vault fact (which boxes this vault's work runs on), machine
*tool surface* is not. The tools root is **opt-in** — created only by `/brain:onboard` step 6 on
machines that want inventories; absence is legal and scanners skip it silently, the deliberate
opposite of a missing common root, which is loud.

The `9xx` band is reserved for vault infrastructure and is **never** allocated to a project — the
`[0-9]*_*` glob matches it, so anything computing the next project number must exclude it or the
next project becomes `1000_`.

Inside the common layer, exactly one thing is structural (canon: `docs/vault-tree.md`):

| Kind | How it is identified | Nature |
|---|---|---|
| **Norms** | any note whose path holds a **directory segment containing `policies`** — glob `*/*policies*/*` | mandatory; highest precedence in document conflicts |
| **Everything else** | every other folder — free-form topic folders, named however the vault likes | descriptive facts — measured, dated (`verified:`) |

Segment-*contains*, not exact-name: measured 2026-07-27, a restructured vault split `policies/`
into `org_policies/{compliance,secret_management,service_operation}/`, and an exact-match glob
silently demoted every policy note to the descriptive tier.

## Worker profiles

Four profiles in `agents/`, differing only in isolation and permissions:

| Profile | Enforcement | Use for |
|---|---|---|
| `worker` | default toolset | any brief — the default profile; scribe (recording) briefs run on it too |
| `coder` | `isolation: worktree` | implementation briefs — TDD, official-docs-first, in an isolated git worktree |
| `verifier` | `disallowedTools: Write, Edit, NotebookEdit` | verification/review/disproof briefs — report-only, reproduction + evidence |
| `researcher` | `disallowedTools: Write, Edit, NotebookEdit` | external-evidence research only — searches outside the repo (in-repo search is `Explore`). Scope gate first, primary sources, disproof duty, citation = URL + access date + version |

- **Ticket loop**: non-trivial tickets run plan → code (`coder`) → verify (`verifier`); small
  changes go direct on a single `worker`.
- **A `coder`'s first action is a base check, before any brief work.** The harness cuts the
  worktree branch from `origin/<branch>`, not from local `main`, so a stale base is the default
  — behind with no local commits, the coder resets to the integration branch itself; behind
  *with* commits, it stops and reports. The `Agent` tool takes no name parameter, so the coder
  also creates its own `<type>/<PREFIX>-<number>-<title-slug>` branch and reports it on the first line
  of `Outputs` — the PM merges by name, then deletes with `git branch -d` (never `-D`) so an
  unmerged branch cannot be dropped. Canon → `agents/coder.md`, `docs/git-convention.md`.
- **A `coder`'s last action is a PR — but only if the remote demands one.** Whether a change
  needs a pull request is measured off the host, not chosen: query *both* classic branch
  protection and rulesets (either can gate, and a repo can fail the first while the second
  makes a PR mandatory). No gate → the coder stops at the branch and the PM merges locally.
  A gate → the coder pushes its own topic branch and opens a **draft** PR, which it cannot
  merge; the PM verifies and flips it to ready. Content = whoever did the work, release = the
  PM, the same axis as `Docs draft`. Canon → `docs/git-convention.md` §Pull / merge
  requests.
- **Nested spawning**: workers may spawn sub-workers when parallelism, isolation, or a
  fresh-eyes verification pays off. Reports flow upward only (recursive star) — a sub-worker
  reports to its parent, never sideways.
- **Personas are briefs, not agents.** Labels like `scribe` name a *kind of brief*, not a
  resident agent. Every worker is scoped by the brief it receives: Goal, constraints, context
  pointers, DoD.
- **Handoff format (fixed)**: `Done / Mistake / Learned / Outputs / Risks / Next / Ask` (+ optional `Docs draft`). `Fixed` was removed in the 0.2.0 KERNEL — it is the flip side of `Mistake`, and one item is a per-spawn cost. The session note's `#### Fixed` under `## Progress` is a different thing and stays.
  (+ optional `Docs draft` — a worker-authored document draft; the scribe copies it verbatim,
  never authors). Workers never write to the vault directly — deliverables travel by Handoff,
  and the PM delegates recording to a scribe brief.

## Conventions (docs/)

Nine convention documents define the system; each fact has exactly one home:

| Document | Defines |
|---|---|
| `docs/vault-tree.md` | the canonical vault tree, paths, layers, write permission, and naming rules |
| `docs/sessions-note-convention.md` | session note schema — filename = identity, the 5 frontmatter keys, the 3-value `status` |
| `docs/knowledge-convention.md` | the atomic, trigger-first memory note format (`p_memory` · `neocortex`) |
| `docs/knowledge-escalate-convention.md` | the 2-stage promotion topology (episodic → semantic), judged by content |
| `docs/memory-control-convention.md` | Handoff format, recall, Dreaming, and scribe governance |
| `docs/git-convention.md` | type vocabulary, surface notation, branch/worktree naming, share scope, PR path measured off the remote |
| `docs/project-docs-convention.md` | doc frontmatter standard, pre-creation rules, policy system, ID minting, conflict precedence |
| `docs/doc-catalog.md` | which document to create when — grade, trigger, owner label |
| `docs/doc-templates.md` | body templates — only the two kinds that have one (`DESIGN` · `MILESTONE`) |

### Ownership boundary — plugin vs vault

The plugin owns **rules**; a vault owns **content**. One plugin serves every vault; the vaults
themselves stay separate on purpose — git, dev, and ops strategy legitimately differ per vault,
so merging them is not a fix for anything.

| Layer | What | Owner | Shared across vaults |
|---|---|---|---|
| **Rules** | session schema · promotion gate · the 3 `status` values · doc frontmatter · conflict precedence | `brain/` (this plugin) | yes — one copy for all vaults |
| **Content** | git/dev/ops strategy · infra facts · knowledge notes · policies · session records | vault common layer + project folders (roots per `.brain-paths`) | no — per vault |

Rule: **a vault folder TOC (`_index.md`; legacy `index.md`) points at a rule, it never restates one.** An index that repeats a
threshold, a status set, or a naming rule is a fork waiting to happen — the copy ages, and the
work downstream follows the aged copy rather than the canon.

Pointer form, as used in the common layer's `policies/_index.md`:

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
restating it.

🔴 **This map is enforced by review, not by a scanner — do not expect a job to catch a violation
for you.** Exactly one slice of it is machine-checked: `scripts/value-axis-drift.sh` (report-only)
reads `docs/project-docs-convention.md` §Value Axes as its SSOT and flags pricing/tier *literals*
living outside their home. Everything else — a norm restated in prose, a threshold copied into a
second document — is caught by the declaration above plus PM mediation. `dreaming` is **not** an
enforcement path here: it reads and writes the memory layers only, never `docs/`.

**Scope: this map binds vault scaffolds too** — `_index.md` files (and legacy `index.md`) and any
other generated vault text count as documents for this rule. Every canonical home below is a
plugin doc, and per the ownership boundary no vault path can become one; a vault file restating a
value in this table is a finding, not a convenience.

| Fact | Canonical (defined only here) | Pointers only (no restating) |
|---|---|---|
| Session schema (filename = identity · the 5 frontmatter keys · 3-value status · retired keys) | `docs/sessions-note-convention.md` | vault-tree · `skills/ss`·`sr`·`sl` · validate |
| Vault tree, paths, layers, naming rules | `docs/vault-tree.md` | doc-catalog · `/brain:init` |
| Tree axis roots (`common_root` · `projects_root` · `tools_root` — keys · defaults · resolver) | `scripts/vault-paths.sh` (values: each vault's `.brain-paths`) | vault-tree · validate · recall · `skills/ss`·`sr` |
| Write permission — the unattended cycle may never write the common root (refused twice) | `docs/vault-tree.md` §Write permission | `hooks/org-guard.sh` · knowledge-promotion · knowledge-escalate-convention · dreaming |
| External ticket system = canonical work queue | PM role statement (`CLAUDE.md`, written by `/brain:init`) | sessions-note-convention |
| Promotion ① procedure (what gets promoted · 🔴 **no score, no weight, no threshold** · sameness judged by content) | `skills/_session-shared/knowledge-promotion.md` | knowledge-escalate-convention · `skills/sc` (`sh` parks and does **not** promote) |
| Promotion topology (2 stages · ① `sc` · ② `dreaming` · what does not ride the ladder) | `docs/knowledge-escalate-convention.md` | knowledge-promotion · `skills/sc` · dreaming |
| dream-log (one appended file at `neocortex/dream-logs.md` · no IDs · one frontmatter key) | `skills/dreaming/SKILL.md` §dream-log | vault-tree · active-sessions |
| Recall — what is scanned and what is not (`_index.md` only · no ranking · **no cap on how much is injected**, a separate matter from that file's own size limit · no candidate selection) | `skills/_session-shared/recall.md` | `skills/ss`·`sr` · memory-control-convention |
| Open-session scan + summary extract (`status: active\|parked` × `project` · `\|\| :` loop terminator) | `skills/_session-shared/active-sessions.md` | `skills/sl`·`sr` |
| Vault I/O boundary (writes = `Write`/`Edit` only · `obsidian create` banned for the silent `X 1.md` fork · CLI reads·link diagnostics allowed, `unresolved`/`orphans`/`deadends` canonical) | `skills/_session-shared/vault-io.md` | `skills/ss`·`sr`·`sc` · knowledge-promotion · dreaming |
| git = SOT · commit-only lifecycle | `docs/git-convention.md` | `skills/ss`·`sh`·`sc` · decision history (WHY only) |
| PR/MR path (gate measured off the remote · draft by coder · ready by PM · topic-branch push carve-out) | `docs/git-convention.md` §Pull / merge requests | `agents/coder.md` §Last action · doc-catalog (§Delivery records the measured values) |
| Agent branch naming (`<type>/<PREFIX>-<number>-<title-slug>` · type from the shared vocabulary) | `agents/coder.md` §First action | `docs/git-convention.md` §Worktree integration order · doc-catalog §Delivery (human prefixes only) |
| Type vocabulary + surface notation + branch/worktree naming | `docs/git-convention.md` (promoted into the harness 2026-07-28 — a distributed plugin cannot depend on a user's personal `at` skill; that skill and any vault mirror now point here) | `agents/coder.md` · `docs/git-convention.md` · doc-catalog point, none copy |
| Session lifecycle (start / resume / list / park / complete) | `skills/ss`·`sr`·`sl`·`sh`·`sc` | sessions-note-convention · active-sessions |
| Doc frontmatter standard (id · status · owner · scope · history) | `docs/project-docs-convention.md` | doc-catalog |
| Pre-creation rules (the 6 pre-created documents, written as `status: created`) | `docs/project-docs-convention.md` §stub Pre-creation Rules | doc-catalog · `/brain:init` |
| Policy system (identification · IDs · promotion) | `docs/project-docs-convention.md` | doc-catalog |
| ID minting (`<PREFIX>-<TYPE>-0000N` · next_id · issued by the PM in advance) | `docs/project-docs-convention.md` §ID Issuance | PM role statement · validate (**presence only** — duplicate/gap detection has no owner, stated as a known gap) |
| API_SPEC mirror rule (sole exception to "repo = code only") | `docs/project-docs-convention.md` | doc-catalog (generated and re-synced by a **PM-delegated sync worker** — 🔴 never `dreaming`, which cannot write `docs/` at all) |
| Document conflict precedence | `docs/project-docs-convention.md` | PM role statement · all workers |
| Doc selection by kind (grade · trigger · owner) | `docs/doc-catalog.md` | `/brain:init` · PM role statement |

## Design principles

- **One canonical source + pointers.** Facts live in one place; everything else links. Drift
  is a lint failure, not a fact of life.
- **Trigger-first.** Recall is symptom-driven, so notes lead with *when they apply* (the
  trigger), not with what they conclude.
- **Small docs.** Large documents don't get read — by humans or by agents with token budgets.
  Split by concern, keep each unit loadable.
- **A pre-created document is not evidence.** A `status: created` document must never be cited
  as one — an empty heading means "not written yet", not "there is none". Filling it flips it to
  `draft`. (`stub` was this status until 2026-08-02; the validator reports a surviving one with
  its own migration message.)
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
