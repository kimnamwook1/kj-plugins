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
      tech-design/
        index.md
        API_SPEC.md
        CODE_CONVENTION.md
        GIT_STRATEGY.md  
        ARCHITECTURE.md
        COMPLIANCE.md                # compliance for this project
        DESIGN.md                    # design-system spec (tokens·components·states·interactions) + Figma/Pencil links
        DR.md
        ERD.md
        GLOSSARY.md
        INTEGRATION.md
        MIGRATION.md
        NFR.md
        OBSERVABILITY.md
        PRD.md
        RUNBOOK.md
        FULL_TEST_PLAN.md
        THREAT_MODEL.md
      adr/                           #   standalone evidence of hard-to-reverse decisions <PREFIX>-ADR-0000N.md
      research/                      #   research outputs (free-form)
      business/
        BM.md
        GTM.md
      planning/                      # roadmap axis — spans tech+business, so it sits above the tech/business split. NOT pre-created (created on trigger)
        MILESTONE.md                 # "when what" — phased delivery plan; references PRD/FRD scope + ADRs, never restates them
      policy/                        # promotion tier for cross-feature product rules; project-wide norms <PREFIX>-POL-0000N.md — criteria & ID issuance: project-docs-convention
      feature/                       # per-feature design (FRD·TDC·DATA_FLOW·SEQUENCE·STATE_DIAGRAM)  
        <feature>/                        
          FRD.md
          TDC.md                     # hub for the 3 diagrams — prose lives here only
          DATA_FLOW.md
          SEQUENCE.md
          STATE_DIAGRAM.md
          policy/                    # rules that apply to this feature only (scope: feature)
  sessions/                          # outside the team share (NNN_*/ + 000_common); committing it is a per-vault choice
    index.md                         # session table of contents
    <uid>.md                         # session = one file (episodic). uid = PROJECT_PREFIX-YYYYMMDD-HHMMSS
    assets/                          # (optional) shared raw images & video
```

## Naming Conventions

- **folders = lowercase**
  - e.g. `docs/` · `docs/feature/` · `docs/policy/` · `docs/business/` · `docs/planning/`
- **required document files = uppercase**
  - `PRD.md` · `FRD.md` · `BM.md` · `GTM.md`
  - Exception: documents under `research/` may be lowercase.
- **machine notes = `<hostname>.md`, lowercase-kebab**
  - `facts/machines/kj-mac-mini-m4.md` — a knowledge/fact note, so lowercase; not an uppercase document file (`COMPLIANCE.md`).
  - frontmatter = same schema as other facts notes: `title` (required) plus `uid` · `created` · `status` · `projects`. Reference: `000_common/facts/machines/kj-mac-mini-m4.md`.
  - this canon gap is why two vaults stored one machine under divergent case/schema.
- **multi-word filenames = `UPPER_SNAKE`**
  - `SEQUENCE.md` · `THREAT_MODEL.md` · `DATA_FLOW.md` · `STATE_DIAGRAM.md` · `API_SPEC.md`
- **folder index = `index.md`**
