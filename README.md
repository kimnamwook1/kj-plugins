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
/brain:init       # once per project — writes CLAUDE.local.md, scaffolds the vault
/brain:onboard    # once per project — 5-question interview fills the stub docs

/brain:ss         # start a session (resumes a parked one if there is any)
/brain:sh         # park it — knowledge promotion + a Progress entry, status stays active
/brain:sc         # close it out

/brain:dreaming   # batch consolidation: staleness flags, index repair, cross-project promotion
```

Full documentation, design rationale, and the vault conventions live in
[`brain/README.md`](./brain/README.md).

## Repo layout

```
.claude-plugin/marketplace.json   # marketplace manifest
brain/                            # the plugin
  .claude-plugin/plugin.json
  skills/                         # ss · sh · sc · init · onboard · dreaming
  agents/                         # worker · coder · verifier profiles
  docs/                           # vault conventions (the canon)
  scripts/                        # validate.sh — vault schema checker
  hooks/
```

## Vault schema check

`brain` ships a dependency-free checker for the vault it writes to:

```
brain/scripts/validate.sh <vault-root>            # warn report, exit 0
brain/scripts/validate.sh <vault-root> --strict   # exit 1 on any finding
```

Details in [`brain/README.md`](./brain/README.md#schema-check).

## License

Not yet specified.
