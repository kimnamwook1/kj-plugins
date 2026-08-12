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

## Frontmatter must parse — quoting is a wire format, not a style

**A frontmatter block that YAML cannot parse has no keys at all.** Not wrong keys — *no* keys. Obsidian renders the whole block as body text, and every reader (recall, `_index` regeneration, any script) sees a note with no `summary`, no `updated`, no `related`, no `aliases`. This is one rung above every other rule on this page: the rules below describe what the keys should say, and this one decides whether there are keys.

🔴 **The rule, stated on its real axis — the scalar, not the key.** A YAML value must be quoted when it

- **opens with an indicator character** — `` ` `` `@` `%` `,` `*` `]` `}` may never begin a plain scalar, and `[` `{` begin a flow collection that must then close on the same line, or
- **contains a colon followed by a space**, or ends in a colon — YAML reads that second colon as a nested mapping.

Quoting is the whole fix, and it is always available: `summary: "the rule: quote every scalar that carries a colon"`.

**Measured on this vault 2026-08-12 with PyYAML, after the KJP-96 sweep had already repaired 354 wikilinks — 11 blocks still did not parse, none of them for a wikilink reason:**

| Cause | Count | Example |
|---|---|---|
| colon+space in an unquoted scalar | 6 | `summary: …취급하지 않는다: 시크릿…` |
| value opens with a backtick | 3 | ``summary: `df` 만 보고…`` |
| value opens an unclosed `[` | 2 | `summary: [결정] sns 게시 문안 …` |

🔴 **This is why the rule is written to the scalar and not to a key.** [[#`related` — links are the precondition for recall]] regulated one key's wire format, so a sweep that fixed every `related` line in the vault left all 11 of these untouched — same root cause, different key. **Repairing `related` in one of these notes accomplishes nothing**: the block still does not parse, so its `summary` and `updated` still do not exist. The unquoted-wikilink rule below is *one instance* of this section, not a peer of it.

**Layer reach: all three.** Wiki notes, `docs/` documents and session notes alike — YAML syntax does not know which folder it is in. The 11 live cases are all in `p_memory/`, and the rule is still not scoped there, because scoping a syntax rule to the layer where it happened to be found is exactly what produced this section. ⚠️ The *consequences* do differ and are worth knowing: on the wiki layer the note goes invisible to recall; on the docs layer the document loses `status:` and a folder index loses `next_id:`; on the session layer `sl`/`sr` keep working (measured — they grep `^status:` rather than parse), so there the damage is the Obsidian surface alone.

Enforced as a **finding** by `scripts/validate.sh` on every one of those layers. A block that does not parse is a **syntax** defect, which is a different axis from the docs layer's warn-only rule about unknown *keys* ([[project-docs-convention]] §frontmatter Standard v2) — one file can produce both, on both channels.

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

🔴 **Two axes are stacked in that table, and only one of them is this section's.** Row 1 fails to parse, which is [[#Frontmatter must parse — quoting is a wire format, not a style]] speaking — a bare `[[` is just one way to open a flow sequence you never close, and that section owns it. Rows 2 and 3 are this section's own and are **not** parse failures at all: they parse perfectly, into a nested list that is not a link. That is why the general rule cannot replace this one — a checker that only asks "does the block parse" waves row 2 straight through, and row 2 is the silent half that survives every review.

Enforced as a **finding** by `scripts/validate.sh`, on the docs layer as well as this one, for the reason given in the section above.

### Linking rules

- **Undirected.** Only `dreaming` writes them; `sc` always leaves `related: []`.
- 🔴 **No shortcut between notes already connected.** If A–B and B–C exist, do not add A–C — two hops already reach it, and without this rule the link count grows quadratically with the note count.
- Orphans (zero inbound links) are surfaced by dreaming as proposals, never auto-restructured.

## Where a note lives

```
hippocampus/ (raw · not recalled)  ──sc──▶  <project>/p_memory/  ──dreaming──▶  neocortex/
```

`<common_root>/` is a separate axis, not a rung on this ladder: it is a **fact record** maintained by measurement, and the unattended cycle (`sc` · `dreaming`) never writes there ([[vault-tree]] §Write permission). Its `*policies*` directories carry the normative tier — on a contradiction, policies win ([[project-docs-convention]] §Document Conflict Precedence).
