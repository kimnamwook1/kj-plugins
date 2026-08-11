# Vault Tree

The folder TOC is **`_index.md`** — it must act as a pointer index, a table of contents only. A legacy `index.md` is recognized as its equal — same folder-TOC role, pre-flip spelling (decision 2026-07-30); never create `_index.md` beside an existing one (scanners exclude both as TOC, not notes — `scripts/vault-paths.sh` `brain_find_notes`).

## Layers

Fast, lossy capture; periodic consolidation. Capture that is expensive does not happen at all, so the hard work — dedup, re-tiering — is deferred to a batch. 🔴 **Staleness is not on that list**: dreaming's three operations are refine · link · promotion ②, none of which judges staleness, and the criterion for it is still undecided. Naming three things when one of them does not exist is how a doc starts lying (KJP-81).

| Layer | Location | Note |
|---|---|---|
| **raw** | `hippocampus/` | sessions. Outside git. Not a recall target |

🔴 **"Outside git" means the layer has no backup unless the machine has one.** Decided 2026-08-05 (KJP-80): the raw layer stays untracked in every vault — a vault-local exception is *not* the fix — and durability is an **OS-level backup concern** (Time Machine or equivalent), not a git one. This is written here because the previous exception lived only as a `.gitignore` comment, and a bulk migration overwrote it without anyone noticing. Two consequences worth stating plainly: a vault whose machine has no backup **is one disk away from losing every unpromoted Mistake and Learned** (measured on the reference machine that day: zero Time Machine destinations configured), and what survives a loss is exactly what promotion moved into `p_memory/` and `neocortex/` — which is the layer split doing its job, not a gap in it.
| **wiki** | `<project>/p_memory/` | project knowledge |
| | `neocortex/` | vault-wide knowledge |
| | `<common_root>/` | fact record |
| **schema** | each folder's `_index.md` | list + `summary` |

🔴 **raw and wiki do not point at each other.** What is extracted from a session is written fresh into wiki, and **nothing is marked in the session**. Raw stays raw and knowledge stands on its own. The folder names are borrowed from the brain; the metaphor is not a rule.

## Write permission

| Actor | May write |
|---|---|
| unattended cycle (`sc` promotion ① · `dreaming` promotion ②) | `hippocampus/` · `<project>/p_memory/` · `neocortex/` |
| an AI acting on a user instruction | anywhere, `<common_root>/` included |

`<common_root>/` is a **fact record kept current by measurement**. The unattended cycle never writes there — the path is refused twice, once before the write and once before the commit (`hooks/org-guard.sh`). The check reads the path from `.brain-paths`; matching a literal would leave a vault whose value is `personal` undefended.

## Tree axes — the manifest decides; the diagram is the default

🔴 **Where each axis actually lives is decided by the vault, not by this canon.** The manifest `<vault>/.brain-paths` declares the roots (`schema_version` · `common_root` · `projects_root` · `tools_root`), and `scripts/vault-paths.sh` is the single resolver every scanner sources — keys, defaults, and resolver functions live in that script's header, the sole copy; never restate the defaults elsewhere. Absent file or absent key = the default, so a vault that never restructured needs no manifest and matches the diagram below exactly. A restructured vault re-points the axes instead of forking this canon.

**Default layout** — what the axes resolve to. An example, not a location canon:

```
<Vault root>/
  .brain-paths                       # the axis keys — init's very first vault write · includes schema_version
  _index.md
  <common_root>/                     # fact record · the unattended cycle may not write here (§Write permission)
    _index.md
    about/                           #   the person / the company
    machines/                        #   owned hardware & software — one note per machine, filename = lowercase hostname
    network/                         #   network setup
    platforms/                       #   operating platforms & domain knowledge
    policies/                        #   binding norms — the normative axis (§The common layer)
      common_policy.md               #     starts as one file; split inside this folder when it outgrows itself
      _index.md
  neocortex/                         # vault-wide knowledge · recall target
    _index.md
    NEO-<slug>.md                    #   no numbers · the filename is the identity key · old names kept in aliases:
    dream-logs.md                    #   dreaming's run log — one file, appended to
  <projects_root>/NNN_<project>/     # per project (number = sort order, the identifier is the slug)
    _index.md                        # = project hub; record the project prefix here
    p_memory/                        # project knowledge · recall target
      _index.md
      <pp>_<slug>.md                 #   no numbers · the prefix exists for vault-wide wikilink uniqueness
    docs/                            # official documents
      _index.md
      business/                      # pre-created stub = the 1 below marked ★
        _index.md
        PRD.md                       # ★ + §비기능 요구(NFR) · §용어(Glossary) · §BM (pricing · tiers · unit economics)
        MARKETING.md                 # situational — GTM · positioning · channels. Links to PRD §BM,
                                     #   never restates a price (project-docs-convention §Value Axes)
        MILESTONE.md                 # NOT pre-created — "when what" phased delivery plan
        COMPLIANCE.md                # situational — compliance for this project
      develop/                       # pre-created stubs = the 4 below marked ★
        _index.md
        ARCHITECTURE.md              # ★ + §데이터 모델(ERD) · §외부 연동(Integrations)
        CODE_CONVENTION.md           # ★ + §테스트 규율 (project-wide test discipline)
        RUNBOOK.md                   # ★ + §Delivery · §관측(Observability) · §재해 복구(DR) · §마이그레이션
        THREAT_MODEL.md              # ★ independent — security/evidence character
        API_SPEC.md                  # NOT pre-created — repo-spec read-only mirror
        DESIGN.md                    # situational — design-system spec + SSOT links
        P_POLICY.md                  # situational — project rules, one `## POL-NNN` heading each.
                                     #   Single file at this one tier; a single-feature rule goes in
                                     #   that feature's §Rules — project-docs-convention §Policy System
        feature/                     # per-feature spec — one file per feature, no per-feature folder
          <pp>_<slug>_0000N.md       #   FRD+TDC merged into one document (kind `feature`).
                                     #   Slug = the human-readable axis, the number = the immutable id.
                                     #   Diagrams live in its §Design section.
          _index.md
      adr/                           #   standalone evidence of hard-to-reverse decisions <PREFIX>-ADR-0000N.md
      resources/                     #   research · meeting records · reference material (free-form · not a recall target)
  <tools_root>/                      # machine-global tool inventory · opt-in · git-untracked. Reserved band (below)
    _index.md
    tool-mcp.md                      #   MCP server inventory
    tool-skill.md                    #   skill inventory
    tool-cli.md                      #   CLI inventory
    tool-plugin.md                   #   plugin inventory
  hippocampus/                       # sessions · not git-tracked · not a recall target
    _index.md
    <PREFIX>_YYYYMMDD_<slug>.md      # session = one file (episodic). Same day + same slug forbidden.
                                     #   Pre-0.2.0 files keep PROJECT_PREFIX-YYYYMMDD-HHMMSS.md — never renamed.
    assets/                          # (optional) shared raw images & video
```

### This diagram vs the transcript's §트리 — and why no checker compares them (KJP-90)

🔴 **There are two *different* "two trees" problems. Do not merge them.**

| Pair | Relationship | Divergence means |
|---|---|---|
| transcript §트리 **vs** transcript «스킬» `skills/init` §4 skeleton | reach-state vs what `init` **creates** — intentionally different | **by design** — situational documents belong in the first and must not be pre-created (KJP-81; the transcript states it at the §4 card) |
| transcript §트리 **vs** this diagram | canon vs illustration — **not peers** | **omission is legal, contradiction is not** (this section) |

- **Precedence.** The transcript's §트리 is the canonical tree (it says so where it settles document placement). This diagram is declared above as *an example, not a location canon*, so it is deliberately non-exhaustive: **a path missing here is not a defect.** A path that *contradicts* the transcript is.
- ⚠ **Precedence is not blind, because this file also carries measurements the transcript does not.** Where the two disagree on a point this file backs with a dated measurement, the conflict goes to the PM rather than being auto-resolved in the transcript's favour — see [[project-docs-convention]] §Document Conflict Precedence.

**No machine check compares the two, and that absence is a decision (measured 2026-08-12).** A naive name-set diff of the two trees was built and run before deciding: 44 entries vs 42, 33 shared, **19 reported differences of which 3 are real — an 84% false-positive rate**, the same order that made the docs `_index` line-form rule unenforceable (KJP-82: 85 false positives). The 16 non-findings are of three kinds, none fixable by a better parser:

- **Placeholder vocabulary.** The same entry is spelled `<pp>_YYYYMMDD_<slug>.md` there and `<PREFIX>_YYYYMMDD_<slug>.md` here; `NNN_<slug>/` vs `NNN_<project>/`; `<vault>/` vs `<Vault root>/`. Unifying the spellings to enable a checker would mean editing canon to suit a tool.
- **Tokenizer artifacts.** `<Vault root>/` contains a space, so extraction splits it and invents an entry `root>/`.
- 🔴 **Inverted negative markers — the one that makes the whole idea unsafe.** The transcript's tree carries explicit *absence* rows: `✗ legal/ 없음` states that `legal/` **must not exist**. Text extraction reads that as "canon has `legal/`" and reports this file for *missing* it — the checker asserts the exact opposite of what canon says. A gate that inverts canon is worse than no gate.

**What guards this pair instead:** this section. The KJP-83 confusion was never that the trees differed — it was that no reader could tell whether a difference was intentional. That is an epistemic gap, and the fix is the same one KJP-81 used for the other pair: write the relationship down. The 3 real differences that the probe did surface are recorded as findings, not silently patched — see `brain/CHANGELOG.md` 0.2.4 §Changed, the KJP-90 entry.

## The common layer — topics are free; only `*policies*` is structural

🔴 **Canonical home of the normative-axis identification rule** — every consumer points here, none restates it.

The common layer's subfolders are **free-form topic folders**; the diagram's split is the default example, not a location canon. Exactly one thing is structural:

- **Norms (the policies tier)** = any note whose path contains a **directory segment whose name contains `policies`** — glob `*/*policies*/*`. Segment-contains, not exact-name: measured 2026-07-27, a restructured vault split `policies/` into `org_policies/{compliance,secret_management,service_operation}/` and an exact-match glob silently demoted every policy note to the facts tier. A file merely named `…policies….md` does not match; the segment must be a directory.
- **Everything else is descriptive** — non-binding facts, organized by whatever topics the vault likes.

A restructured common layer is legal as-is — e.g. the techtainment vault today (measured 2026-07-30): `common_root: org` with five topic folders `about · machines · networks · org_policies · platforms`. On a contradiction the normative axis wins ([[project-docs-convention]] §Document Conflict Precedence), which is why no agent sets one on its own.

## The tools root — machine-global, opt-in, not vault-scoped

**The axis is scope of truth, and the root is what separates it.** The common root means "common to every project *in this vault*"; the tools root means "true of *this machine*, whatever vault you opened". Tool inventories are the second kind — they describe `~/.claude/**`, which no vault owns.

- **Opt-in — not required vault structure.** The tools layer is a machine-local option: it is **excluded from the `/brain:init` required scaffold**, and only a machine that wants inventories creates it, via `/brain:onboard` step 6 (the `.gitignore` entry is still registered before the first write). **Absence is legal and silent**: the resolver (`scripts/vault-paths.sh`) resolves a missing tools root to the empty string with no warning — deliberately the opposite of the loud missing common root — and every consumer skips the scan.
- **Why it was split out (measured 2026-07-25).** Two vaults on one machine each recorded the same tool surface under their own common layer, and the copies diverged by an order of magnitude (`tool-mcp.md` 31KB vs 3KB). Storing a machine-global fact on a vault-scoped axis makes N vaults into N conflicting inventories, and nothing can arbitrate them — each is "correct" for its own scope.
- **Git-untracked.** The contents are machine-local, so they never belong on the shared surface (`git-convention.md` §Share scope). A teammate pulling your MCP list gets a fact about *your* laptop. Registered in the vault's `.gitignore` at creation — by whoever creates the layer — **before** the first write populates it, because a gitignore added after the first commit does not un-commit anything.
- **Populated by measurement only** — `/brain:onboard` step 6, never by hand and never from memory.

**Why `machines/` stays in the common layer.** Machine *configuration* is a vault fact (which boxes this vault's work runs on — one note per machine, and a vault legitimately spans several); tool *surface* is machine-global (what is installed on the box you are typing on right now). One is a roster the vault keeps, the other is the state of one machine — different scopes, so different homes.

## Reserved number bands

The `NNN_` prefix sorts the project space, but not every numeric-prefixed folder is a project. Two bands are reserved, and **only `001`–`899` is the project range**:

| Band | Meaning | Example |
|---|---|---|
| `000` | vault-wide common knowledge, when the common root sits in the `NNN_` namespace | the common root |
| `001`–`899` | **projects** — the only band `/brain:ss` allocates from | `<projects_root>/013_kj-plugins/` |
| `900`–`999` | vault infrastructure — not a project, never allocated to one | the tools root |

The bands are a default-layout property. A manifest pointing `common_root`/`tools_root` elsewhere removes the squatters but not the reservation; the resolver (`scripts/vault-paths.sh` `brain_projects`) excludes the `9xx` band and drops the common root either way.

🔴 **Anything scanning for *project* folders must exclude the reserved bands, not just the common root.** The `[0-9]*_*` glob matches every band, and a `000`-banded common root used to be safe only by accident — max-based numbering ignores the minimum. A `9xx` folder breaks that accident from the other end: measured on a fixture, a `999`-banded tools root drove `/brain:ss`'s next-project number to **`1000`**, a 4-digit prefix the `NNN_` convention does not allow. Consumers and their guards: `skills/ss/SKILL.md` §Ensure the project folder (number computation **and** `*_<project>` lookup — a project slugged `tools` otherwise resolves to the tools root) · `skills/sr/SKILL.md` (same lookup) · `scripts/validate.sh`.

## Renaming a path term — sweep live pointers only

🔴 **A path-term rename touches only the pointers that still point.** When a folder is renamed (`sessions/` → `hippocampus/`, `knowledge/` → `p_memory/`, `tech-design/` → `develop/`), the old string keeps appearing in prose for reasons that are not pointers, and rewriting those is not consistency — it is **forgery**.

The same string splits five ways, and only the first is in scope:

| Kind | Example | Sweep? |
|---|---|---|
| **live pointer** | a hub index line naming `sessions/KJP-*.md` | ✅ **yes** |
| past incident / measurement record | "the glob mis-staged `…/docs/tech-design/DESIGN.md`" | 🔴 no — that path was the fact at that time |
| external tool's real path | `~/.codex/sessions/` · `~/.grok/sessions/` | 🔴 no — not this vault's namespace |
| code sample inside a note | `"$root"/*/knowledge/*.md` in a glob-bug note | 🔴 no — breaking the sample voids the note |
| the note's own subject | a file named `sessions-gitignore-is-team-share-scope…` | 🔴 no |

Measured 2026-08-11 (vault-wide prose sweep, 54 hits across six retired names, classified line by line): **live pointers 26 · preserve 20 · undecided 4 · false positives 4.** So a blanket substitution would have been wrong on **more than half the hits** — including four that are another tool's real paths, and — the case that settles the rule — **two that are the note warning that path sweeps miss a direction, which quotes the `sessions/` → `hippocampus/` rename as its worked example.** The sweep would have destroyed the note that warns about the sweep.

So: **judge line by line, read the `git diff` with your eyes, and report what was fixed and what was preserved as separate counts.** "Zero occurrences" is the wrong goal; a machine substitution that reaches zero has overwritten history. The same principle already governs recorded measurements elsewhere in this harness — a count captured under an old label stays under that label.

## Naming Conventions

- **folders = lowercase**
  - e.g. `docs/` · `docs/develop/feature/` · `docs/adr/` · `docs/business/`
- **required document files = uppercase**
  - `PRD.md` · `MARKETING.md` · `RUNBOOK.md`
  - Exception: documents under `resources/` may be lowercase.
  - Exception: a `feature/` document is `<pp>_<slug>_0000N.md` — uppercase prefix + **lowercase kebab slug** + serial. It is named for its feature, not for a fixed document role, so the uppercase rule does not reach it (§tree).
- **machine notes = `<hostname>.md`, lowercase-kebab**
  - `<common_root>/machines/kj-mac-mini-m4.md` — a fact note, so lowercase; not an uppercase document file (`COMPLIANCE.md`).
  - frontmatter = the note form of [[knowledge-convention]] (`summary` · `updated` · `related` · `aliases`), plus `verified:` for a measured fact.
  - this canon gap is why two vaults stored one machine under divergent case/schema.
- **multi-word filenames = `UPPER_SNAKE`**
  - `THREAT_MODEL.md` · `CODE_CONVENTION.md` · `API_SPEC.md`
- **memory notes carry no number** — `p_memory` is `<pp>_<slug>.md`, `neocortex` is `NEO-<slug>.md`. Changing tiers swaps the prefix and moves the file; the old name goes to `aliases:` so existing links still open ([[knowledge-convention]]).
- **folder index = `_index.md`** — a legacy `index.md` is recognized as its equal (never both in one folder)
