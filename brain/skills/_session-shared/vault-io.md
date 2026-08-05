# Reference: Vault I/O — what may touch the vault, and how (shared rule)

> Which tool is allowed to **write** vault content, and which `obsidian` CLI surfaces are allowed to **read** it. Single source for the whole harness — **`ss` · `sr` · `sc` · `knowledge-promotion.md` · `dreaming` point here and never restate the rule.** Not executed standalone; there is no procedure to run, only a boundary to obey.
> Registered in `README.md` §Single-Source Map. Two different programs share the name "obsidian CLI" — §3 tells them apart before anything else here makes sense.

## 1. Writes — `Write`/`Edit` tools only

- **Every write of vault content goes through the `Write`/`Edit` tools. No CLI, no shell redirect, no `append`.** `Edit` changes a file that exists; `Write` is only for a file that does not exist yet.
- 🔴 **The reason is `Edit`'s `old_string`, which is a compare-and-swap.** If a concurrent session moved the anchor, the edit **fails loudly** instead of silently swallowing that session's work. `Write` on an existing file has no such check — it discards whatever landed there since you last read it.
- **The party doing the write is the `scribe` worker.** The PM (main session) does not write vault content directly even though it holds the tool — single-scribe discipline (canon: `docs/memory-control-convention.md` §Governance). Do not bypass; delegate.

## 2. The `obsidian` CLI — `create` is banned, reads are not

**`obsidian create` is forbidden for vault content**, and the precise reason matters because it is narrower than "the CLI is buggy":

- 🔴 **Without the `overwrite` flag, a name collision silently produces `X 1.md`.** It does not fail, and it does not overwrite — it forks the note under a new name, and the write you thought you made is sitting in a file nobody reads. Measured 2026-07-27 (Obsidian 1.12.7): the same `create name="_zz-cli-test"` run twice yields `Created: _zz-cli-test.md` then `Created: _zz-cli-test 1.md`; adding `overwrite` yields `Overwrote:`.
- **The official docs do not warn about this.** `obsidian.md/help/cli` documents `overwrite` only as "Overwrite if file exists" — the silent-fork behavior on collision is undocumented, so it will not be discovered by reading the reference. That is why it is written down here.
- **`overwrite` is not the fix.** It trades a silent fork for a silent clobber, which is the exact failure §1 exists to prevent. The rule stays: writes go through `Write`/`Edit`.
- **Same ban, same reason, for any other mutating subcommand** — `append` · `delete` · `property:set` · `property:remove` · `base:create`. None of them compare-and-swap.

**Read, search, and link-diagnostic subcommands are allowed and encouraged** — they mutate nothing:

- 🔴 **`unresolved` · `orphans` · `deadends` are the canonical verdict on link integrity.** They run Obsidian's own link resolver, which is the same one that decides whether a link works in the app. Nothing else in this harness gets a vote.
  - `unresolved` — broken wikilinks. `verbose` adds the **source file**, so a broken link can be traced to the note holding it.
  - `orphans` — notes with no incoming links (the input `skills/dreaming/SKILL.md` §The three operations · **Link** runs on; that section names `unresolved`·`orphans`·`deadends` as the canonical verdict).
  - `deadends` — notes with no outgoing links.
  - `total` on any of the three returns just the count.
- 🔴 **Never count links with a regex — it over-counts, and not by a little.** A naive `\[\[[^]]+\]\]` sweep matches TOML array-of-tables inside fenced code blocks and `\|`-escaped wikilinks in table cells. Reproduced 2026-07-27 on this vault: `[[tool.uv.index]]`, `[[tool.mypy.overrides]]`, and `[[synology-nas/software\|software]]` all match, none is a broken link. A regex cannot resolve a link, so it cannot answer whether one is broken.
- **Counts are vault state and rot fast — take the measurement, do not quote one from here.** Recorded only to show the commands return real data: 2026-07-27, vault `techtainment`, `unresolved total` = 206 · `orphans total` = 234 · `deadends total` = 393.
- **Also non-mutating and useful:** `search` / `search:context` · `backlinks` · `property:read` · `bases` · `vault info=`.

```bash
obsidian unresolved total          # broken-link count
obsidian unresolved verbose        # broken links + the file each one sits in
obsidian orphans total             # notes nothing links to
obsidian deadends total            # notes that link to nothing
```

- **A read subcommand piped into `head` can look like a hang.** The CLI ignores the resulting `SIGPIPE` and keeps running; the command is fine, the pipe closed early. Redirect to a file, or bound it with `timeout`, rather than concluding the CLI is broken.

## 3. Two different programs, one name

- **Obsidian's built-in CLI** — the `obsidian` command, shipped inside the app (`/Applications/Obsidian.app/Contents/MacOS/obsidian` on macOS), **Obsidian 1.12+**, documented at `obsidian.md/help/cli`. **This is the one present in this environment**, and the one §2 describes.
- **The third-party `obsidian-cli`** — a separate project with a separate command name. **Not installed here** (`which obsidian-cli` → not found, measured 2026-07-27). Earlier canon banned `obsidian-cli create` and thereby banned a program nobody had, while the tool that actually had the collision behavior went unnamed.
- **Check the running version with `obsidian version`, never the app bundle.** Obsidian updates its runtime without replacing the installer, so `Info.plist` lags: measured 2026-07-27, `CFBundleShortVersionString` = `1.11.7` while `obsidian version` = `1.12.7 (installer 1.11.7)`. The CLI tracks the runtime.
