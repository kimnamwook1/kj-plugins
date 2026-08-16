# kj-plugins

koreanjoker's Claude Code plugin marketplace.

## Install

```
/plugin marketplace add kimnamwook1/kj-plugins
/plugin install brain
```

## Plugins

| Plugin | What it does |
|---|---|
| [**brain**](./brain) | A memory harness for Claude Code — session capture → knowledge promotion → recall, on an Obsidian-compatible vault, orchestrated through a PM-and-workers model. |

### brain — quick tour

```
/brain:init       # once per project — AGENTS.md + CLAUDE.md marker block, CLAUDE.local.md
                  # (vault-root), vault scaffold (sessions/ + memory/ + _index.md)
/brain:onboard    # once per project — grill-style interview: one question at a time,
                  # measured answers, documents created lazily in repo docs/

/brain:ss         # start a NEW session (creates only — never resumes, never scans)
/brain:sr         # resume a parked session — the only path back into one; status → active
/brain:sl         # list open sessions (parked + active) — read-only
/brain:sh         # park it — Progress entry, status → parked (no promotion; that is sc's)
/brain:sc         # close it out — status → done, knowledge promoted to memory/,
                  # then a one-line dreaming suggestion

/brain:dreaming   # batch consolidation — refine + cross-project scope promotion;
                  # destructive changes are proposal-only
```

Full documentation, design rationale, and the vault conventions live in
[`brain/README.md`](./brain/README.md).

## Repo layout

```
.claude-plugin/marketplace.json   # marketplace manifest
brain/                            # the plugin
  .claude-plugin/plugin.json
  skills/                         # ss · sr · sl · sh · sc · init · onboard · dreaming
  agents/                         # worker · coder · verifier · researcher
  docs/                           # the canon: memory.md · project-docs.md · git-convention.md
                                  #   (+ security-audit.md, annex)
  docs-samples/                   # sample repo docs/ tree (fictional project vidnote) — not canon
  scripts/                        # brain-check.sh · brain-validate.sh · brain-recall
  hooks/                          # SessionStart · PostToolUse (config/agent files only)
```

## Schema check

`brain` ships dependency-free checkers (bash 3.2 + POSIX):

```
brain/scripts/brain-check.sh                       # marker-block / KERNEL byte comparison
brain/scripts/brain-validate.sh <vault-root>       # vault mode — session/memory schema lint
brain/scripts/brain-validate.sh <repo-root> --repo # repo mode — docs frontmatter · ADR IDs ·
                                                   #   COMPLIANCE §Legal Sources
```

Details in [`brain/README.md`](./brain/README.md).

## License

Not yet specified.
