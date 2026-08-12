# Memory Notes — `p_memory` (project) + `neocortex` (vault-wide)

> Tree & naming → [[vault-tree]] · promotion → [[knowledge-escalate-convention]] · sessions → [[sessions-note-convention]]

Two tiers, one note form. `<projects_root>/NNN_<slug>/p_memory/<pp>_<slug>.md` holds project knowledge; `neocortex/NEO-<slug>.md` holds knowledge that has proven itself in more than one project. Both are recall targets — the raw session layer is not.

## Note form — 4 keys, 3 sections

Recall is symptom-driven, so **the trigger goes first**.

```
---
summary:                     # one line · two components: "when to use it" + "what it claims" · recall's entire search surface
updated: YYYY-MM-DD
related: []                  # sc always writes []. Only dreaming links · no pair already reachable in two hops
                             #   non-empty form → §related (every wikilink is quoted)
aliases: []                  # append the old basename on rename or on promotion ②
---
## Trigger   when this note should come to mind — the opening agent's relevance gate
## Insight   the reusable **claim**. It need not be a solution — a corrected fact belongs here too
## Why       commands · paths · numbers · versions · error messages. The section dreaming's fact-invariance check reads
```

- **Filename is the identity key. No numbers.** The `<pp>` prefix exists for wikilink uniqueness across the vault. Changing tiers is swapping the prefix and moving the file.
- **A note points at no session.** raw and wiki do not reference each other ([[vault-tree]] §Layers).
- **1 note = 1 reusable claim** (atomic). No essays.
- **update-over-create**: if a similar note exists, add nuance to it rather than creating a second one. **Tooling follows from this** — edit an existing note with `Edit` (its `old_string` is a compare-and-swap, safe against a concurrent session), and reserve `Write` for a note that does not exist yet (`Write` on an existing note silently discards whatever a concurrent edit put there).
- **Retired keys — do not reintroduce.** `uid` · `type` · `tags` · `dri` · `species` · `source_sessions` · `source_items` · `recalled` · `useful` · `created` · `writer`. `title` was **renamed** to `summary`, not retired. Freshness is derived from `updated:`, never stored as a status field.

## `summary` — the whole search surface

recall injects `_index.md` only, never note bodies (`skills/_session-shared/recall.md`). Each `_index.md` line is `- [[<filename stem>]] — <summary>`, so **the one `summary` line is everything an agent sees before deciding to open the note**. Write both components: when it applies, and what it asserts. A summary that states only the topic makes the note unfindable.

`_index.md` is a regenerated artifact — never hand-edit it. The canon lives in the note's own frontmatter, and the party that creates or moves a file updates the folder's `_index.md` **in the same commit**.

## `neocortex` — the same keys plus `projects`

```
---
summary:                     # same rule as p_memory
updated: YYYY-MM-DD
projects: []                 # 2+ distinct project slugs that triggered promotion ②
                             #   ⚠ write-once — recorded once at promotion. Never appended to, deleted from, or updated on rename.
                             #      Not "current scope" but a frozen record of the evidence used at that moment
related: []
aliases: []                  # append the pre-promotion basename (<pp>_<slug>)
---
```

Promotion ② is a three-line operation and nothing else — canon: [[knowledge-escalate-convention]].

## `related` — links are the precondition for recall

### Wire format — the quotes are the rule

```yaml
related:
  - "[[note-name]]"
  - "[[other-note]]"
```

Empty stays `related: []`.

🔴 **What makes this correct is the quoting, not the block list.** In YAML `[[` opens a *nested sequence*, so an unquoted wikilink is never a link — and the two ways that fails are nowhere near equally visible. Measured on this vault 2026-08-12 with PyYAML, over the 660 notes carrying frontmatter:

| Written | YAML reads it as | Count | Consequence |
|---|---|---|---|
| `related: [[a]], [[b]]` | **parse error** | 302 | The whole frontmatter fails to parse, so Obsidian renders the block as body text. Loud — this is the form a human finally noticed. |
| `related: [[a]]` | `[['a']]` — a nested list | 52 | Parses fine. No link, no error, no warning anywhere. 🔴 **The dangerous half**: the note looks healthy and its links simply do not exist. |
| `  - [[a]]` (block, no quotes) | `[[['a']]]` | 0 | The same silence one level deeper. Writing a block list buys nothing on its own. |
| `  - "[[a]]"` | `'[[a]]'` — a string Obsidian resolves | 96 | ✅ The form above. |

The rule generalizes past this one key: **any frontmatter value holding a wikilink is quoted, whatever the key is.** `aliases` and `projects` hold plain strings (old basenames, project slugs) and carry no links today — measured 0 — but a link put in either is quoted the same way.

Enforced as a **finding** by `scripts/validate.sh`, on the docs layer as well as this one: a frontmatter that does not parse is a syntax defect, which is a different axis from the docs layer's warn-only rule about unknown *keys* ([[project-docs-convention]] §frontmatter Standard v2).

### Linking rules

- **Undirected.** Only `dreaming` writes them; `sc` always leaves `related: []`.
- 🔴 **No shortcut between notes already connected.** If A–B and B–C exist, do not add A–C — two hops already reach it, and without this rule the link count grows quadratically with the note count.
- Orphans (zero inbound links) are surfaced by dreaming as proposals, never auto-restructured.

## Where a note lives

```
hippocampus/ (raw · not recalled)  ──sc──▶  <project>/p_memory/  ──dreaming──▶  neocortex/
```

`<common_root>/` is a separate axis, not a rung on this ladder: it is a **fact record** maintained by measurement, and the unattended cycle (`sc` · `dreaming`) never writes there ([[vault-tree]] §Write permission). Its `*policies*` directories carry the normative tier — on a contradiction, policies win ([[project-docs-convention]] §Document Conflict Precedence).
