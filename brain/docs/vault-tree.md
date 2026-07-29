# Vault Tree

`index.md` must act as a pointer index — a table of contents only. An existing `_index.md` is recognized as its equal — same folder-TOC role, underscore form (scanners exclude both as TOC, not notes — `scripts/vault-paths.sh` `brain_find_notes`).

## Tree axes — the manifest decides; the diagram is the default

🔴 **Where each axis actually lives is decided by the vault, not by this canon.** The manifest `<vault>/.brain-paths` declares the roots (`common_root` · `projects_root` · `tools_root`), and `scripts/vault-paths.sh` is the single resolver every scanner sources — keys, defaults, and resolver functions live in that script's header, the sole copy; never restate the defaults elsewhere. Absent file or absent key = the default, so a vault that never restructured needs no manifest and matches the diagram below exactly. A restructured vault re-points the axes instead of forking this canon — e.g. `common_root: org` + `projects_root: projects` keeps its common layer at `org/` and its project folders under `projects/`.

**Default layout** — what the axes resolve to with no `.brain-paths`. An example, not a location canon:

```
<Vault root>/
  index.md                           
  000_common/                            # cross-project knowledge — the common root (common_root)
    index.md
    facts/                           #   A. environment facts — created/updated by onboard step 6 from live measurement
      index.md
      organization.md                #     organization info (interview)
      user.md                        #     user — preferences & conventions
      machines/                      #     one note per machine (<hostname>.md — lowercase-kebab; OS, key tools)
      claude-code/                   #     CC notes by topic
    patterns/                        #   B. upward-distilled lessons (promoted by Dreaming)
    policies/                        #   C. org-wide binding norms (every project; origin-agnostic)
      COMPLIANCE.md                   
    dream-log.md                     #   Dreaming run log — incremental baseline for the next dream
  NNN_<project>/                   # per project (number = sort order, identifier is the slug) — under projects_root (default: the vault root)
    index.md                         # = project hub; record the project prefix here
    knowledge/                       # reusable knowledge scoped to this project (semantic)
      index.md
      *.md                           
    docs/                            # official documents
      index.md
      MILESTONE.md                   # NOT pre-created — "when what" phased delivery plan, docs/ root (a planning/ folder only if a 2nd planning doc appears)
      tech-design/                   # pre-created stubs = the 5 below marked ★
        index.md
        PRD.md                       # ★ + §비기능 요구(NFR) · §용어(Glossary)
        ARCHITECTURE.md              # ★ + §데이터 모델(ERD) · §외부 연동(Integrations) — split a section out only when it grows heavy
        CODE_CONVENTION.md           # ★ + §테스트 규율 (project-wide test discipline)
        RUNBOOK.md                   # ★ + §Delivery(구 GIT_STRATEGY) · §관측(Observability) · §재해 복구(DR) · §마이그레이션(Migration)
        THREAT_MODEL.md              # ★ independent — security/evidence character
        API_SPEC.md                  # NOT pre-created — repo-spec read-only mirror; dreaming api-mirror generates it once an API exists
        COMPLIANCE.md                # situational — compliance for this project
        DESIGN.md                    # situational — design-system spec (tokens·components·states·interactions) + SSOT links (design tool, or repo component source when code-first)
      adr/                           #   standalone evidence of hard-to-reverse decisions <PREFIX>-ADR-0000N.md
      research/                      #   research outputs (free-form)
      business/
        BUSINESS.md                  # ★ one file, two sections — §BM · §GTM
      policy/                        # promotion tier for cross-feature product rules; project-wide norms <PREFIX>-POL-0000N.md — criteria & ID issuance: project-docs-convention
      feature/                       # per-feature design (FRD·TDC — diagrams live in TDC §Diagrams)
        <feature>/                        
          FRD.md
          TDC.md                     # prose sections + §Diagrams (absorbed the former DATA_FLOW·SEQUENCE·STATE_DIAGRAM files)
          policy/                    # rules that apply to this feature only (path = tier: feature)
  999_tools/                         # machine-global tool inventory — the tools root (tools_root) · git-untracked. Reserved band (see below)
    index.md
    tool-mcp.md                      #   MCP server inventory
    tool-skill.md                    #   skill inventory
    tool-cli.md                      #   CLI inventory
    tool-plugin.md                   #   plugin inventory
  sessions/                          # outside the team share (NNN_*/ + 000_common); committing it is a per-vault choice
    index.md                         # session table of contents
    <uid>.md                         # session = one file (episodic). uid = PROJECT_PREFIX-YYYYMMDD-HHMMSS
    assets/                          # (optional) shared raw images & video
```

## The tools root (`999_tools/` by default) — machine-global, not vault-scoped

**The axis is scope of truth, and the root is what separates it.** The common root (`000_common/` by default) means "common to every project *in this vault*"; the tools root (`999_tools/` by default) means "true of *this machine*, whatever vault you opened". Tool inventories are the second kind — they describe `~/.claude/**`, which no vault owns.

- **Why it was split out (measured 2026-07-25).** Two vaults on one machine each recorded the same tool surface under their own common layer's `facts/`, and the copies diverged by an order of magnitude (`tool-mcp.md` 31KB vs 3KB). Storing a machine-global fact on a vault-scoped axis makes N vaults into N conflicting inventories, and nothing can arbitrate them — each is "correct" for its own scope.
- **Git-untracked.** The contents are machine-local, so they never belong on the shared surface (`versioning-convention.md` §Share scope). A teammate pulling your MCP list gets a fact about *your* laptop. Registered in the vault's `.gitignore` at `/brain:init` — **before** `/brain:onboard` step 6 first populates it, because a gitignore added after the first commit does not un-commit anything.
- **Populated by measurement only** — `/brain:onboard` step 6, never by hand and never from memory.

**Why `machines/` stays in the common layer's `facts/`.** Machine *configuration* is a vault fact (which boxes this vault's work runs on — one note per machine, and a vault legitimately spans several); tool *surface* is machine-global (what is installed on the box you are typing on right now). One is a roster the vault keeps, the other is the state of one machine — different scopes, so different homes.

## Reserved number bands

The `NNN_` prefix sorts the project space (`projects_root` — the vault root in the default layout), but not every numeric-prefixed folder is a project. Two bands are reserved, and **only `001`–`899` is the project range**:

| Band | Meaning | Example |
|---|---|---|
| `000` | vault-wide common knowledge | `000_common/` |
| `001`–`899` | **projects** — the only band `/brain:ss` allocates from | `<projects_root>/013_kj-plugins/` |
| `900`–`999` | vault infrastructure — not a project, never allocated to one | `999_tools/` |

The bands are a default-layout property — there the common root (`000`) and vault infrastructure (`9xx`) share the `NNN_` namespace with projects. A manifest pointing `common_root`/`tools_root` elsewhere removes the squatters but not the reservation; the resolver (`scripts/vault-paths.sh` `brain_projects`) excludes the `9xx` band and drops the common root either way.

🔴 **Anything scanning for *project* folders must exclude the reserved bands, not just the common root.** The `[0-9]*_*` glob matches every band, and `000_common` used to be safe only by accident — max-based numbering ignores the minimum. A `9xx` folder breaks that accident from the other end: measured on a fixture, `999_tools/` drove `/brain:ss`'s next-project number to **`1000`**, a 4-digit prefix the `NNN_` convention does not allow. Consumers and their guards: `skills/ss/SKILL.md` §Ensure the project folder (number computation **and** `*_<project>` lookup — a project slugged `tools` otherwise resolves to `999_tools/`) · `skills/sr/SKILL.md` (same lookup) · `scripts/validate.sh` (guarded already — it requires a `knowledge/`/`docs/` subfolder, which no `9xx` folder has).

## Naming Conventions

- **folders = lowercase**
  - e.g. `docs/` · `docs/feature/` · `docs/policy/` · `docs/business/`
- **required document files = uppercase**
  - `PRD.md` · `FRD.md` · `BUSINESS.md` · `RUNBOOK.md`
  - Exception: documents under `research/` may be lowercase.
- **machine notes = `<hostname>.md`, lowercase-kebab**
  - `facts/machines/kj-mac-mini-m4.md` — a knowledge/fact note, so lowercase; not an uppercase document file (`COMPLIANCE.md`).
  - frontmatter = same schema as other facts notes: `title` (required) plus `uid` · `created` · `status` · `projects`. Reference: `<common_root>/facts/machines/kj-mac-mini-m4.md`.
  - this canon gap is why two vaults stored one machine under divergent case/schema.
- **multi-word filenames = `UPPER_SNAKE`**
  - `THREAT_MODEL.md` · `CODE_CONVENTION.md` · `API_SPEC.md`
- **folder index = `index.md`** — an existing `_index.md` is recognized as its equal
