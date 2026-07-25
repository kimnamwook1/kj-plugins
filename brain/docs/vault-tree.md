# Vault Tree

`index.md` must act as a pointer index — a table of contents only.

```
<Vault root>/
  index.md                           
  000_common/                            # cross-project knowledge
    index.md
    facts/                           #   A. environment facts — created/updated by onboard step 6 from live measurement
      index.md
      organization.md                #     organization info (interview)
      user.md                        #     user — preferences & conventions
      machines/                      #     one note per machine (<hostname>.md — lowercase-kebab; OS, key tools)
      tool-mcp.md                    #     MCP server inventory
      tool-skill.md                  #     skill inventory
      tool-cli.md                    #     CLI inventory
      tool-plugin.md                 #     plugin inventory
      claude-code/                   #     CC notes by topic
    patterns/                        #   B. upward-distilled lessons (promoted by Dreaming)
    policies/                        #   C. org-wide binding norms (every project; origin-agnostic)
      COMPLIANCE.md                   
    dream-log.md                     #   Dreaming run log — incremental baseline for the next dream
  NNN_<project>/                   # per project (number = sort order, identifier is the slug)
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
          policy/                    # rules that apply to this feature only (scope: feature)
  sessions/                          # outside the team share (NNN_*/ + 000_common); committing it is a per-vault choice
    index.md                         # session table of contents
    <uid>.md                         # session = one file (episodic). uid = PROJECT_PREFIX-YYYYMMDD-HHMMSS
    assets/                          # (optional) shared raw images & video
```

## Naming Conventions

- **folders = lowercase**
  - e.g. `docs/` · `docs/feature/` · `docs/policy/` · `docs/business/`
- **required document files = uppercase**
  - `PRD.md` · `FRD.md` · `BUSINESS.md` · `RUNBOOK.md`
  - Exception: documents under `research/` may be lowercase.
- **machine notes = `<hostname>.md`, lowercase-kebab**
  - `facts/machines/kj-mac-mini-m4.md` — a knowledge/fact note, so lowercase; not an uppercase document file (`COMPLIANCE.md`).
  - frontmatter = same schema as other facts notes: `title` (required) plus `uid` · `created` · `status` · `projects`. Reference: `000_common/facts/machines/kj-mac-mini-m4.md`.
  - this canon gap is why two vaults stored one machine under divergent case/schema.
- **multi-word filenames = `UPPER_SNAKE`**
  - `THREAT_MODEL.md` · `CODE_CONVENTION.md` · `API_SPEC.md`
- **folder index = `index.md`**
