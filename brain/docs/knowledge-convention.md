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
                             #   a memo for a human who remembers it — it does not resolve links (§Filename)
---
## Trigger   when this note should come to mind — the opening agent's relevance gate
## Insight   the reusable **claim**. It need not be a solution — a corrected fact belongs here too
## Why       commands · paths · numbers · versions · error messages. The section dreaming's fact-invariance check reads
```

- **Filename is the identity key. No numbers.** Its form is regulated below (§Filename); changing tiers is swapping the prefix and moving the file.
- **A note points at no session.** raw and wiki do not reference each other ([[vault-tree]] §Layers).
- **1 note = 1 reusable claim** (atomic). No essays.
- **update-over-create**: if a similar note exists, add nuance to it rather than creating a second one. **Tooling follows from this** — edit an existing note with `Edit` (its `old_string` is a compare-and-swap, safe against a concurrent session), and reserve `Write` for a note that does not exist yet (`Write` on an existing note silently discards whatever a concurrent edit put there).
- **Retired keys — do not reintroduce.** `uid` · `type` · `tags` · `dri` · `species` · `source_sessions` · `source_items` · `recalled` · `useful` · `created` · `writer`. `title` was **renamed** to `summary`, not retired. Freshness is derived from `updated:`, never stored as a status field.

## Filename — `<pp>_<slug>.md`, and `<slug>` is the part that was never specified

```
p_memory   <pp>_<slug>.md      <pp>   = the project prefix, verbatim from the project hub
neocortex  NEO-<slug>.md       <slug> = lowercase ASCII kebab — [a-z0-9] words joined by single -
```

- **`<pp>` comes from one place: the `PREFIX:` line in the project hub** `<projects_root>/NNN_<project>/_index.md` (a legacy `index.md` is its equal). That is already the only source any writer is sent to — `skills/ss/SKILL.md` §PREFIX reads the hub and, when the line is missing, asks the user and writes it there rather than inventing one. A hub with no `PREFIX:` line has **no authority to name anything**: the linter reports it once, at the hub, and skips that project's notes rather than repeating one hub defect once per note. (Measured 2026-08-12: all 13 projects declare one, so this is a forward guard — a project folder created before its hub is filled in.)
- **`<slug>` is lowercase ASCII kebab and nothing else.** No spaces, no uppercase, no non-ASCII, no `. , ( ) = · —`, no `/ * :`. Same rule on both tiers — `NEO-<slug>.md` differs from `<pp>_<slug>.md` only in what precedes the slug, never in the slug. This is the spelling the vault already uses everywhere else a `<slug>` appears: `NNN_<slug>/` (`infra-manage`, `youtube-stts`), the `feature/` document's "uppercase prefix + **lowercase kebab slug** + serial" ([[vault-tree]] §Naming Conventions), and the session filename's kebab reduction of the Goal ([[sessions-note-convention]]).

🔴 **Why the prefix is on this layer and not on `docs/` — measured, not aesthetic.** The two layers are addressed differently, so they need different uniqueness. Counted on this vault 2026-08-12 over every `_index.md` and every `related:` block:

| Layer | linked as `[[bare-stem]]` | linked as `[[path/to/doc]]` |
|---|---|---|
| `p_memory/_index.md` | 493 | 0 |
| `p_memory` note frontmatter (`related:`) | 1352 | 38 |
| `docs/_index.md` | 1 | 80 |
| project hub `_index.md` | 0 | 42 |

**p_memory is a flat namespace (98% bare stem); `docs/` is a path namespace (99% qualified).** That is the whole argument: `ARCHITECTURE.md` exists in **11 projects at once** and collides with nothing, because nobody ever writes `[[ARCHITECTURE]]`. A p_memory stem has no such protection — recall injects several projects' `_index.md` into one context, and promotion ② lifts the note into `neocortex/` where it stands beside every other project's. Zero stem collisions today (measured, 480 notes) is the prefix's job being done in advance, not evidence that it is unnecessary.

🔴 **Why the slug may not be a sentence — the filename is a stale copy of `summary:`.** Measured over the 146 sentence-form notes: **123 (84%) are ≥0.95 similar to their own `summary:`, and 119 are byte-identical to it.** The filename is therefore not carrying information; it is carrying a *second, unmaintained* copy of a line that already exists — and the two do not age together:

- **When judgment is revised, `summary:` is rewritten and the filename is not**, because renaming breaks every inbound wikilink. The divergence is largest exactly where it matters most: the single lowest-similarity note in the vault (0.15) is named `Plane 접근은 메인 세션 MCP로 — 별도 Plane CLI 래퍼를 만들지 마라`, and its `summary:` reads `2026-08-11 뒤집힘: … 금지했던 Plane CLI 래퍼를 …`. **The filename is still arguing for a judgment the note itself retracted.**
- **Nobody reads the filename anyway.** recall injects `_index.md` and nothing else, one line per note, `- [[stem]] — <summary>` (§`summary`). The summary is right there next to the stem, so a sentence-shaped stem buys no legibility and costs a duplicate.
- 🔴 **Punctuation the OS rewrites turns the stem into a silent lie.** `/ * :` cannot appear in a filename, so the write path substitutes and the note keeps the *original* text in `summary:`. Both live cases, measured:

  | `summary:` says | the filename says |
  |---|---|
  | `… raw Sessions/*.md 제외 …` | `… raw Sessions-_.md 제외 …` |
  | `… 커밋은 handoff/complete 시점만 …` | `… 커밋은 handoff·complete 시점만 …` |

  The first names a glob that does not exist. The second is worse: `·` is *also* this vault's ordinary separator (`시점만·push`), so the substituted slash is now indistinguishable from an intentional one and cannot be recovered from the filename at all.
- **A sentence runs out of filesystem.** `NAME_MAX` is 255 bytes and Korean costs 3 bytes per character (measured: a 256-byte name fails with `ENAMETOOLONG`). The longest sentence-form name here is **242 bytes — four Korean characters from the ceiling**, and 15 are already past 200. Kebab slugs top out at 78.

Enforced as a **finding** by `scripts/validate.sh` on `p_memory/`, alongside this layer's other findings (retired keys, `related` wire format, index coverage): a stem is this layer's identity key, and an identity defect is not a style opinion. `_index.md` and `0.*` are excluded as meta files, the same exclusion every other wiki scan uses.

### `aliases:` does not rescue a rename — it is a memo, and the links are still yours to rewire

🔴 **Obsidian's resolver does not consult `aliases:`.** That resolver is the canonical verdict on link integrity and the only thing in this harness that gets a vote (`skills/_session-shared/vault-io.md` §2), so a note carrying its own old basename in `aliases:` is, to every link that still names the old stem, simply gone. Measured 2026-08-12 on Obsidian 1.13.6, two independent ways:

- **Probe.** `git mv` on one note took `obsidian unresolved` from 84 to 85. Appending that note's old basename to its own `aliases:` left the count at **85**, and the old stem stayed in the unresolved target list. The probe was reverted. PyYAML parses both frontmatter blocks and returns the alias, so this is the resolver's behaviour and not a spelling defect.
- **The live vault, arrived at separately.** `projects/001_rss-proj/_index.md` has carried `aliases: [rss-proj]` since its `updated: 2026-07-12`. A month later `obsidian unresolved verbose` still reports `rss-proj` as an unresolved target with **14 occurrences**, all of them in that project's own notes.

🔴 **So a rename is finished when the inbound links are rewired, not when the alias is appended.** Keep appending it — on a rename, and on promotion ② where it preserves the pre-promotion `<pp>_<slug>` ([[knowledge-escalate-convention]]) — because a reader who remembers the old name should still find the note. That is the whole of what it buys. The rewrite of the inbound links, and of the `_index.md` line naming the note, lands **in the same commit as the move**. Which pointers are in scope is [[vault-tree]] §Renaming a path term: live pointers only, judged line by line — a path quoted as a past measurement is not one. The bullets above already argue this from the other side, where "renaming breaks every inbound wikilink" is the reason a `summary:` gets revised while its filename is left to rot.

🔴 **`unresolved` counts distinct targets, not occurrences, so it under-reports rename damage — verify against `verbose`, never against the number.** One broken stem moves the counter by 1 however many links point at it: measured the same day, the target `actor-tag-domain-model` carries 27 occurrences across 20 files and contributes exactly 1, and vault-wide the two quantities differ by 5.5× (`skills/_session-shared/vault-io.md` §2). A rename that breaks two dozen links can therefore read as a 1-point regression, or as nothing at all if something else was repaired in the same window. Diff the **target list** out of `obsidian unresolved verbose` across the move and confirm the old stem is absent from it. A total that did not move is not evidence that it is.

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

🔴 **`_index.md` is hand-maintained, and the sentence that stood here said the opposite (corrected 2026-08-12).** It read "a regenerated artifact — never hand-edit it" in the same breath as "the party that creates or moves a file updates it in the same commit." Both cannot hold, and **the regenerator is the half that is false**: after-the-fact index regeneration was retired with the dreaming feature set (KJP-77). `scripts/validate.sh` §index states it where it would matter most — *"Detection only, and it presumes no regenerator … This check never rewrites an index and no message here may imply that something else will."* A worker who obeyed "never hand-edit" left the index stale, which is the exact failure the dangling and coverage checks exist to catch. **So: whoever creates or moves a file writes the line by hand, in the same commit.** The note's own frontmatter stays canon for what the line *says* — an index copies a `summary`, it never authors one.

**That line form is this layer's rule, not the vault's (KJP-82).** It is enforced on the wiki layer alone. A `docs/` TOC is checked for dangling links and nothing else, on purpose: no canon ever stated the form for docs, and measured 2026-08-11, **85 of the real vault's docs index lines would be reported under it**. Enforcing an unwritten rule at that false-positive rate is how a gate gets ignored.

**Frontmatter and headings — what is actually true (measured 2026-08-12, 113 indexes).** A wiki-layer index carries neither and opens straight into its bullets. The rest of the vault is looser and nothing reports it: **26 indexes carry frontmatter** — 13 `docs/adr/` counters (`next_id:`, the issuance record — [[project-docs-convention]] §ID Issuance) and 13 project hubs (`title:`/`updated:`, read by no code) — and **100 of the 113 carry an H1**. 🔴 **Prefer no H1 on a new index; it is not a violation and no check reports one.** recall already prints `### <vault-relative path>` above each injected index (`skills/_session-shared/recall.md`), so an in-file H1 restates the path and nests an H1 under an H3 — but banning it would put 100 live files in violation to buy back one line each, and `validate.sh` §index deliberately grants the opposite ("an index is allowed to introduce itself").

## `neocortex` — the same keys plus `projects`

```
---
summary:                     # same rule as p_memory
updated: YYYY-MM-DD
projects: []                 # 2+ distinct project slugs that triggered promotion ②
                             #   ⚠ write-once — recorded once at promotion. Never appended to, deleted from, or updated on rename.
                             #      Not "current scope" but a frozen record of the evidence used at that moment
related: []
aliases: []                  # append the pre-promotion basename (<pp>_<slug>) — a memo, not a link resolver
---
```

Promotion ② changes three lines inside the note and nothing else. **The note is not the whole operation**: the move renames the file, so the inbound links come with it (§Filename). Canon: [[knowledge-escalate-convention]].

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
