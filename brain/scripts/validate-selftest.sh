#!/bin/bash
# validate-selftest.sh — builds a throwaway vault of deliberately broken fixtures and
# asserts that each validate.sh rule fires (and that excluded/out-of-scope files stay quiet).
# No test framework: fixtures + grep asserts. Exit 0 = all assertions passed.
#
# Assert discipline: every scope boundary is pinned by a *positive* fixture (a violation that
# must be reported), so narrowing the scope kills an assert instead of silently passing.
# A lone assert_no_match cannot tell "scanned and clean" from "never scanned" — that is a
# vacuous assert, and it is how a collapsed scan hides.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="${VALIDATE_SH:-$HERE/validate.sh}"   # overridable so mutation tests can point elsewhere
V="$(mktemp -d -t brain-selftest)" || exit 2
trap 'rm -rf "$V"' EXIT

fails=0
assert_match() {   # <desc> <grep-pattern>
  if printf '%s\n' "$REPORT" | grep -q -- "$2"; then echo "ok   — $1"
  else echo "FAIL — $1  (no line matching: $2)"; fails=$((fails + 1)); fi
}
assert_no_match() {
  if printf '%s\n' "$REPORT" | grep -q -- "$2"; then echo "FAIL — $1  (unexpected line matching: $2)"; fails=$((fails + 1))
  else echo "ok   — $1"; fi
}
assert_exit() {    # <desc> <expected> <actual>
  if [ "$2" -eq "$3" ]; then echo "ok   — $1"
  else echo "FAIL — $1  (expected exit $2, got $3)"; fails=$((fails + 1)); fi
}

# ---------------------------------------------------------------- fixtures
# The common root is manifest data, never a literal in this file: 0.2.0 `init` writes
# `common_root: org` into `.brain-paths`, and every fixture vault below declares it the same way
# a real vault does. `neocortex/` and `hippocampus/` take no manifest key — they are root-fixed
# (vault-paths.sh manifests only the axes that move between vaults).
COMMON=org
mkdir -p "$V/hippocampus/nested" "$V/013_selftest/p_memory/nested" \
         "$V/013_selftest/docs/policy" "$V/013_selftest/docs/adr" \
         "$V/013_selftest/docs/tech-design" "$V/014_mirror/docs/tech-design" \
         "$V/$COMMON/facts" "$V/$COMMON/facts/machines" \
         "$V/$COMMON/patterns" "$V/$COMMON/policies" \
         "$V/999_tools" "$V/neocortex"
# `schema_version` rides along because this vault models a *correct* 0.2.0 manifest — it is the
# negative fixture for the schema_version check, and the positives live in their own vault below.
printf -- 'schema_version: 2\ncommon_root: %s\n' "$COMMON" > "$V/.brain-paths"

# 0.2.0 session frontmatter = 5 keys, none of them an identity or authorship field: the filename
# carries identity (`uid` retired) and git carries authorship (`writer` retired).
session() {  # <basename> <status>
  printf -- '---\nstatus: %s\nproject: selftest\nupdated: 2026-07-18T12:00:00\nrelated_ticket: huly:KJP-1\ncc_session_ids: [cc-selftest]\n---\n\n## Goal\n' \
    "$2" > "$V/hippocampus/$1.md"
}

session CLEAN-20260718-120000 active          # clean — must stay silent
session BAD-20260718-120001   draft           # doc status in a session
session BAD-20260718-120002   frozen          # invalid status

# The 3-value vocabulary is active|parked|done (KJP-48). `parked` is first-class — a positive
# fixture in the *quiet* direction only proves the scan ran if something else in the same scan
# fires, which the pair below guarantees: `cancel` is the retired token and must be reported.
session PARKED-20260718-120012 parked        # legal — parked is a session status
session BAD-20260718-120013    cancel        # retired vocabulary — must be caught

printf -- '---\nstatus: active\n---\n' \
  > "$V/hippocampus/BAD-20260718-120005.md"   # missing project/updated/related_ticket/cc_session_ids
printf -- '# just a body\n' > "$V/hippocampus/BAD-20260718-120006.md"   # no frontmatter
# 0.2.0 `_index.md` carries no frontmatter at all, which is exactly what makes it a broken
# *session* — silence can only mean the exclusion held, never that the fixture was clean.
# Its link dangles on purpose, so the file is broken for the _index scan too: hippocampus/ is the
# raw layer and no recall target, so it is outside BOTH scans, and both silences are load-bearing.
printf -- '- [[ghost-session]] — dangles, and is scanned by neither rule\n' > "$V/hippocampus/_index.md"  # excluded (TOC, canonical form)
# index.md is the legacy spelling of the same folder-TOC rule (canon flip 2026-07-30:
# _index.md canonical, index.md recognized as its equal) — kept as the legacy fixture that
# pins both spellings.
printf -- '- [[ghost-session]] — dangles, and is scanned by neither rule\n' > "$V/hippocampus/index.md"   # excluded (TOC, legacy form)

# Quoted scalars must NOT be false positives (regression: `status: "active"` blocked --strict).
session QUOTED-20260718-120007 '"active"'
printf -- '---\nstatus: %s\nproject: s\nupdated: u\nrelated_ticket: t\ncc_session_ids: [c]\n---\n' \
  "'done'" > "$V/hippocampus/QUOTED-20260718-120008.md"

# CRLF file — must be parsed, not misreported as "no frontmatter". Its status is invalid,
# so this is a positive fixture: CR mishandling would change the message, not just silence it.
printf -- '---\r\nstatus: frozen\r\nproject: s\r\nupdated: u\r\nrelated_ticket: t\r\ncc_session_ids: [c]\r\n---\r\n' \
  > "$V/hippocampus/CRLF-20260718-120009.md"

# Retired 0.1.x session keys still sitting in a frontmatter that is otherwise complete — the
# migration safety net. Without a positive fixture here, a vault that never dropped `uid:`
# would pass silently, which is the whole failure mode the retired-key check exists to catch.
printf -- '---\nstatus: active\nproject: s\nupdated: u\nrelated_ticket: t\ncc_session_ids: [c]\nuid: RETIRED-20260718-120016\ncreated: 2026-07-18\nwriter: nwkim\n---\n' \
  > "$V/hippocampus/RETIRED-20260718-120016.md"

# The schema placeholder: deliberately broken three ways (placeholder status, missing
# related_ticket, missing cc_session_ids) so "silent" can only mean the exclusion held.
printf -- '---\nstatus: <active|parked|done>\nproject: <project-slug>\nupdated: YYYY-MM-DDTHH:MM:SS\n---\n' \
  > "$V/hippocampus/sample-session.md"

# Nested sessions are out of scope (-maxdepth 1). Broken on purpose so that dropping
# -maxdepth 1 makes it surface and kills the assert below.
printf -- '# no frontmatter\n' > "$V/hippocampus/nested/NESTED-20260718-120010.md"

# wiki layer: one positive (missing summary) fixture per scanned directory, so that dropping any
# single directory from the scan scope kills a specific assert.
printf -- '---\nsummary: a real one-liner\n---\n' > "$V/013_selftest/p_memory/good.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/013_selftest/p_memory/no-summary.md"
# `summary:` present but empty is the same hole as absent — recall's whole search surface is that
# one line, so a key with nothing after it buys the note nothing. Positive fixture for the
# non-empty-value half of the rule; without it the check could degrade to a key-presence test.
printf -- '---\nsummary:\nupdated: 2026-07-18\n---\n' > "$V/013_selftest/p_memory/empty-summary.md"
# The folder TOC — excluded from the *note* scan (it is not a note), and the sole input of the
# _index scan (it is the only thing recall injects). Lines 1-4 are heading/prose/blank: not TOC
# entries, so they must stay quiet. Line 5 is the canonical form. 6 dangles. 7 uses a hyphen where
# canon writes an em dash. 8 has no summary after the dash. 9 is a bullet with no wikilink at all.
# Line numbers are load-bearing for the asserts below, so new entries only ever append.
# Lines 14-17 exist for the coverage rule's sake, not their own: every wiki note in this folder is
# listed here so that the note keeps failing exactly one rule (the discipline stated at the top of
# this file). Without them the coverage rule would speak about fixtures built for other rules, and
# the filename-anchored quiet asserts below would stop meaning what they say.
cat > "$V/013_selftest/p_memory/_index.md" <<'EOF'
# p_memory — 목차

Intro prose is not a TOC entry.

- [[good]] — a real one-liner
- [[ghost-note]] — points at a file that is not there
- [[good]] - hyphen where canon writes an em dash
- [[good]] —
- a bullet carrying no wikilink
- [[가]] — non-ASCII stem, exists
- [[나]] — non-ASCII stem, exists
- [[다]] — non-ASCII stem, exists
- [[라]] — non-ASCII stem, exists
- [[no-summary]] — indexed, so only the summary rule can speak about it
- [[empty-summary]] — indexed, so only the summary rule can speak about it
- [[wl-pmem]] — indexed, so only the wikilink rule can speak about it
- [[retired-keys]] — indexed, so only the retired-key rule can speak about it
EOF
# 🔴 Locale regression (KJP-74). Under a UTF-8 collation locale macOS `sort -u` treats these four
# stems as EQUAL and keeps one — measured 2026-08-05: `가 나 다 라` deduplicates to a single line,
# so three live notes vanish from the target set and their index lines are reported as dangling.
# The four files below exist; the assert is that none of them is ever called dangling. Without
# `LC_ALL=C` on the target-set sort (validate.sh) this fails with three findings.
for _k in 가 나 다 라; do
  printf -- '---\nsummary: non-ASCII stem fixture\n---\n' > "$V/013_selftest/p_memory/$_k.md"
done
# 🔴 Index coverage (KJP-82) — the dangling rule read backwards. Both notes are complete and
# summarised and sit in a scanned folder, so every other rule is silent about them: only the
# coverage rule can speak, which is what makes the two asserts unambiguous.
# `마` is the non-ASCII half. The four stems above are indexed and must stay quiet, and a quiet
# assert cannot by itself tell "compared and found covered" from "never compared at all" — this
# one fires, so the non-ASCII comparison is pinned in both directions.
printf -- '---\nsummary: a summarised note that no index names\n---\n' > "$V/013_selftest/p_memory/orphan.md"
printf -- '---\nsummary: non-ASCII stem that no index names\n---\n'    > "$V/013_selftest/p_memory/마.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/013_selftest/p_memory/0.rejected.md"    # excluded (meta)
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/013_selftest/p_memory/nested/deep-no-summary.md"  # out of scope
# Retired 0.1.x wiki keys, all ten in one note. `summary:` is present, so only the retired-key
# check can speak here — and one assert per key means dropping any single key from the check's
# target list kills a specific assert rather than silently shrinking the net.
printf -- '---\nsummary: a note still carrying 0.1.x keys\nuid: KJP-20260718-120018\ntitle: old title\ntype: gotcha\ntags: [a]\ndri: nwkim\nspecies: lesson\nsource_sessions: [KJP-20260718-120019]\nsource_items: [x]\nrecalled: 3\nuseful: 1\n---\nbody\n' \
  > "$V/013_selftest/p_memory/retired-keys.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/$COMMON/facts/facts-no-summary.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/$COMMON/patterns/patterns-no-summary.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/$COMMON/policies/policies-no-summary.md"
# facts/machines/ is nested under facts/ (depth 2) — only reachable because validate.sh scans
# the common layer recursively. Positive fixture: reverting that drops it from scope and
# kills the assert below, while the deeper project nested/ note stays out of scope regardless.
printf -- '---\nupdated: 2026-07-18\n---\n' > "$V/$COMMON/facts/machines/machine-no-summary.md"
# Coverage positive in the common layer, one folder deep: its sibling above is covered by a
# vault-relative line in facts/_index.md and this one by nothing, so the pair proves the subtree
# resolution actually ran rather than silently marking the whole folder covered.
printf -- '---\nsummary: a nested note that no index names\n---\n' > "$V/$COMMON/facts/machines/machine-orphan.md"
# Named misc-*, not tool-*: since KJP-44 a `tool-*.md` under facts/ would contradict the canon
# (tool inventories live in the tools root). This fixture only has to be a summarised facts note.
printf -- '---\nsummary: a summarised fact\n---\n' > "$V/$COMMON/facts/misc-x.md"
# The common layer's own TOC. The _index scan reaches it only because that layer is walked
# recursively (facts/ is depth 1 under the common root) — dropping the recursion kills this assert.
# Line 5 is the vault-relative entry shape, the way a subtree index covers notes in a child folder
# that has no index of its own (measured in the real vault 2026-08-05: `org/machines/_index.md`
# names `org/machines/clients/*/…` and nothing else covers those eight notes).
printf -- '- [[misc-x]] — a summarised fact\n- [[facts-ghost]] — points at a file that is not there\n- [[facts-no-summary]] — indexed, so only the summary rule can speak about it\n- [[wl-common]] — indexed, so only the wikilink rule can speak about it\n- [[%s/facts/machines/machine-no-summary]] — vault-relative form, covering a child folder\n' \
  "$COMMON" > "$V/$COMMON/facts/_index.md"
# The common root's own TOC. `patterns/` and `policies/` hold notes but no index of their own, so
# they are covered from here by the vault-relative form — the second real-vault shape, and the
# reason coverage may not be judged folder-locally.
printf -- '- [[wl-dreaming]] — indexed, so only the wikilink rule can speak about it\n- [[%s/patterns/patterns-no-summary]] — vault-relative form, child folder with no index of its own\n- [[%s/policies/policies-no-summary]] — vault-relative form, child folder with no index of its own\n' \
  "$COMMON" "$COMMON" > "$V/$COMMON/_index.md"

# neocortex/ — vault-wide knowledge, root-fixed (no manifest key) and IN the wiki lint scope
# alongside p_memory (canon: the wiki layer is p_memory + neocortex). The no-summary fixture is
# what proves the root is scanned at all; dropping the root kills it.
printf -- '---\nupdated: 2026-07-18\n---\n'           > "$V/neocortex/NEO-no-summary.md"
printf -- '---\nsummary: vault-wide knowledge\n---\n' > "$V/neocortex/NEO-good.md"
printf -- '- [[NEO-good]] — vault-wide knowledge\n- [[NEO-ghost]] — points at a file that is not there\n- [[NEO-no-summary]] — indexed, so only the summary rule can speak about it\n- [[wl-neo]] — indexed, so only the wikilink rule can speak about it\n' \
  > "$V/neocortex/_index.md"   # excluded from the note scan (meta) · IS the _index scan's input
# dream-logs.md is dreaming's run log, not a note: single-file accumulation whose frontmatter is
# one key (`updated`). It must be excluded, or every real vault reports a phantom missing summary.
printf -- '---\nupdated: 2026-07-18T10:00:00\n---\n\n- [2026-07-18]-ran a cycle\n' > "$V/neocortex/dream-logs.md"

# The tools root (`999_tools/` by default) — machine-global tool inventory (KJP-44). It sits on
# BOTH sides of a deliberate scope split, so it takes fixtures in both directions:
#   · wiki summary scan (the recall mirror) — IN scope, because recall scans it as a source.
#     Dropping the KDIRS root kills the no-summary assert below.
#   · shared-surface wikilink scan — OUT of scope, because the folder is gitignored and no
#     teammate ever pulls it. Adding it to SDIRS makes wl-tools.md fire and kills its quiet assert.
# Note it reaches KDIRS only via its own explicit root: the [0-9][0-9][0-9]_* sweep demands a
# p_memory/ subfolder, which this folder deliberately does not have.
printf -- '---\nupdated: 2026-07-18\n---\n'      > "$V/999_tools/tools-no-summary.md"
printf -- '---\nsummary: MCP inventory\n---\n'   > "$V/999_tools/tool-mcp.md"
printf -- '- [[tool-mcp]] — MCP inventory\n- [[tool-ghost]] — points at a file that is not there\n- [[tools-no-summary]] — indexed, so only the summary rule can speak about it\n- [[wl-tools]] — indexed, so only the coverage rule stays quiet about it\n' \
  > "$V/999_tools/_index.md"  # excluded from the note scan (meta) — same rule as p_memory/
printf -- '---\nsummary: tool note citing a session\n---\n[[KJP-20260718-120011]]\n' \
  > "$V/999_tools/wl-tools.md"

# neocortex/ does NOT follow that split — it is git-tracked and pulled like any project folder, so
# its axis is the shared surface and a session wikilink there dangles for a teammate exactly as one
# in docs/ does. It sat outside the scan only because step 6 of the 0.2.0 migration renamed that
# scan without extending it; KJP-65 is the decision that extends it (scope extends on decision, not
# by drift). wl-neo.md is now a positive fixture: dropping the root from SDIRS kills this assert.
printf -- '---\nsummary: neo note citing a session\n---\n[[KJP-20260718-120017]]\n' \
  > "$V/neocortex/wl-neo.md"

# Session-uid wikilinks on the shared surface. One positive fixture per scan root, so
# dropping any root from the scope kills a specific assert. Every wiki-layer fixture carries a
# `summary:` so it stays silent for the summary rule, and the docs-tree ones carry
# `status: draft` so the docs-status rule stays quiet too — only the wikilink rule can speak.
printf -- '---\nstatus: draft\n---\n[[KJP-20260718-120000]] is the source.\n' \
  > "$V/013_selftest/docs/wl-doc.md"                                   # NNN_*/docs — bare uid
printf -- '---\nstatus: draft\n---\nsee [[hippocampus/KJP-20260718-120001]] and [[KJP-20260718-120002|the session]]\n' \
  > "$V/013_selftest/docs/wl-path.md"                                  # path prefix + alias form
printf -- '---\nsummary: p_memory note with a session link\n---\nbody cites [[KJP-20260718-120003#Progress]]\n' \
  > "$V/013_selftest/p_memory/wl-pmem.md"                              # NNN_*/p_memory — heading form
printf -- '---\nsummary: nested note with a session link\n---\n[[KJP-20260718-120004]]\n' \
  > "$V/013_selftest/p_memory/nested/wl-nested.md"                     # recursion: nested is IN scope here
printf -- '---\nsummary: common fact with a session link\n---\n![[KJP-20260718-120005]]\n' \
  > "$V/$COMMON/facts/wl-common.md"                                    # common layer — embed form
printf -- '---\nsummary: common root note\n---\ndream report [[20260719-005513]]\n' \
  > "$V/$COMMON/wl-dreaming.md"                                        # common root + PREFIX-less uid

# Legal shared-surface references, all in one file. Two of these are load-bearing beyond
# "no false positive":
#   · the `history:` line reproduces the v2 template (project-docs-convention §frontmatter
#     Standard v2: `{ at, change, ticket }` — the KJP-39-era `session:` key is banned
#     outright now), so the fixture fails the moment that template regresses;
#   · `cc_session_ids:` pins the underscore guard — the session-key rule must not match the
#     key "session" inside a longer key. It replaces the retired `source_sessions:` here: the
#     guard needs a live 0.2.0 key, or the fixture pins the rule with a token nobody writes;
#   · `[[<PREFIX>-ADR-0000N]]` / `[[<ID>]]` are vault-internal doc-to-doc links that
#     project-docs-convention mandates — they must never be caught by the wikilink rule.
printf -- '---\nstatus: draft\ncc_session_ids: [cc-20260718-120006]\nhistory:\n  - { at: 2026-07-26T12:00:00, change: one line, ticket: "KJP-41" }\n---\nsee 20260719-005514 plus [[another-note]], [[KJP-ADR-00001]], [[KJP-POL-00002]]\n' \
  > "$V/013_selftest/docs/wl-plain.md"

# ------------------------------------------------- docs-layer indexes + the project hub (KJP-82)
# 🔴 The scope correction this card is, and the measurement that forced it. `recall.md:13` is
# `find "$PROJDIR" -name '_index.md'` — recursive and unfiltered — so every index under a project
# folder is injected text, the docs TOCs and the project hub included (real vault 2026-08-11:
# 106 injected per that command, 13 of them linted). A line naming a file that is not there is the
# same false inventory the wiki-layer rule exists to catch, and nothing else could see it.
# What does NOT carry over is the line form, which is why the whole tree was excluded before: a
# docs TOC legitimately opens with frontmatter and prose, writes a hyphen, names a non-note file,
# and omits the summary. So the form rule stays on the wiki layer and this fixture is its guard —
# every bullet below violates that form, and reporting any of them is what would make the new
# check ignorable. Line numbers are load-bearing for the asserts; new entries only ever append.
cat > "$V/013_selftest/docs/_index.md" <<'EOF'
---
next_id: 7
---

# docs — 목차

Intro prose, which a docs TOC is allowed to carry.

- [[ghost-doc]] — dangles, and docs TOCs ARE in the dangling scan now
- [[fm-v2]] - hyphen where the wiki canon writes an em dash
- [[fm-legacy]]
- `rdb-schema.sql` — a bullet naming a non-note file
- [[013_selftest/docs/tech-design/API_SPEC]] — vault-relative form, resolves
EOF

# The project hub. It sits in no other scan at all — one level above docs/, outside the wiki roots,
# outside the shared-surface sweep — so the `docs indexes` count is the only number that can show
# it was read, and this dangling link the only assert that can prove it.
cat > "$V/013_selftest/_index.md" <<'EOF'
# selftest — 프로젝트 허브

한 줄 정의 + PREFIX + TOC 포인터 (doc-catalog.md) — prose, not entries.

- [[ghost-hub]] — dangles, and the hub IS scanned
- [[013_selftest/docs/fm-v2]] — vault-relative form, resolves
- **[[013_selftest/docs/fm-legacy]]** bold, no em dash — a real hub shape, not a finding
EOF

# Recursion one folder deep, the KJP-74 locale regression on the docs side, and the `../` form.
# The two non-ASCII stems exist and must never be called dangling; lines 5 and 7 fire, so neither
# quiet pair can be the silence of a scan that never reached this folder.
# Lines 6-7 are the `../` pair: Obsidian resolves relative addressing inside a wikilink, so the
# one that lands on a real file must stay quiet and the one that lands on nothing must still fire.
for _k in 문서가 문서나; do
  printf -- '---\nstatus: draft\n---\nbody\n' > "$V/013_selftest/docs/tech-design/$_k.md"
done
cat > "$V/013_selftest/docs/tech-design/_index.md" <<'EOF'
# tech-design — 목차

- [[문서가]] — non-ASCII stem, exists
- [[문서나]] — non-ASCII stem, exists
- [[ghost-nested-doc]] — dangles, one folder deep
- [[../fm-v2]] — ../ addressing, resolves to the docs root
- [[../ghost-updir]] — ../ addressing that lands on nothing
EOF

# p_memory/ subfolders are the wiki layer's own scope decision (-maxdepth 1), and this card does not
# reopen it: the docs scan excludes the p_memory tree outright rather than reaching in through the
# back door. The link dangles, so silence can only mean that exclusion held.
printf -- '- [[ghost-nested-pmem]] — dangles; p_memory/ subfolders are out of both index scans\n' \
  > "$V/013_selftest/p_memory/nested/_index.md"

# Docs frontmatter v2 (project-docs-convention §frontmatter Standard v2). The session key
# is banned in docs frontmatter *as a key* — plain uid included — so both YAML shapes are
# positive fixtures (inline map line 5, top-level line 6). Unknown keys are the opposite
# severity: stderr warn only, never a finding (--strict must not fail on an imported doc),
# pinned by fm-legacy below staying out of the findings stream while warning on stderr.
printf -- '---\nstatus: draft\nupdated: 2026-07-28T10:00:00\nhistory:\n  - { at: 2026-07-28T10:00:00, change: adds x, session: "KJP-20260718-120000" }\nsession: KJP-20260718-120000\n---\nbody\n' \
  > "$V/013_selftest/docs/fm-session.md"
printf -- '---\nstatus: draft\nupdated: 2026-07-28T10:00:00\nhistory:\n  - { at: 2026-07-28T10:00:00, change: one line, ticket: "KJP-41" }\n---\nv2 body citing KJP-20260718-120000 as plain text.\n' \
  > "$V/013_selftest/docs/fm-v2.md"                                    # clean v2 — must stay silent
# Legacy v1 doc: deleted keys (kind/title/owner) + date-only `updated`. Migration is
# "no longer written", never a forced rewrite — so none of this may become a finding.
printf -- '---\nkind: prd\ntitle: legacy doc\nstatus: approved\nupdated: 2026-07-18\nowner: planning\n---\nlegacy body.\n' \
  > "$V/013_selftest/docs/fm-legacy.md"

# Docs frontmatter v2 — coverage extension (status · history subkeys · id · next_id · mirror).
# status: required on every non-meta docs file; vocabulary = created|draft|approved|deprecated
# (doc-catalog.md). Three findings shapes (absent, foreign value, session vocabulary) plus a
# quoted-scalar pass — the same regression class the session scan already pins.
printf -- '---\nupdated: 2026-07-28T10:00:00\n---\nbody\n'  > "$V/013_selftest/docs/fm-nostatus.md"
printf -- '---\nstatus: frozen\n---\nbody\n'                > "$V/013_selftest/docs/fm-badstatus.md"
printf -- '---\nstatus: active\n---\nbody\n'                > "$V/013_selftest/docs/fm-sessionstatus.md"
printf -- '---\nstatus: "draft"\n---\nbody\n'               > "$V/013_selftest/docs/fm-quoted.md"
# v1 history subkeys hide where the top-level key regex cannot see — inside the `- { ... }`
# inline map and the indented block entry. Both shapes are positive fixtures (date: + by:).
printf -- '---\nstatus: draft\nhistory:\n  - { date: 2026-07-18, by: koreanjoker, change: adds x }\n  - at: 2026-07-19T10:00:00\n    by: someone\n    change: y\n---\nbody\n' \
  > "$V/013_selftest/docs/fm-v1hist.md"
# Verifier bypasses (2026-07-29), both pinned so they stay closed:
#   · flow-style history keeps its entries in the *value* of the `history:` line itself,
#     which the entry-line branch never saw; `"by":` doubles as the quoted-key spelling
#     inside an entry.
#   · quoted top-level keys (`"session":`) dodged the session ban AND the key collector —
#     a quoted key is the same key: known ones must register (`"status":` here, or a false
#     missing-status fires) and unknown ones must still warn (`"kind":`).
printf -- '---\nstatus: draft\nhistory: [{ at: 2026-07-20T10:00:00, date: 2026-07-18, "by": kim }]\n---\nbody\n' \
  > "$V/013_selftest/docs/fm-flowhist.md"
printf -- '---\n"status": draft\n"session": KJP-20260718-120000\n"kind": prd\n---\nbody\n' \
  > "$V/013_selftest/docs/fm-qsession.md"
# docs/policy/ · docs/adr/ — body files need `id:` (multi-instance, PM-issued, immutable);
# their _index/index carry the folder's `next_id:` counter instead. Both folder forms and
# both TOC spellings get one fixture each, PASS and FAIL paired — canonical `_index.md`
# passes, the legacy `index.md` fixture pins that the old spelling is still checked.
printf -- '---\nstatus: draft\nid: KJP-POL-00001\n---\nrule\n' > "$V/013_selftest/docs/policy/KJP-POL-00001.md"
printf -- '---\nstatus: draft\n---\nrule\n'                    > "$V/013_selftest/docs/policy/KJP-POL-00002.md"  # missing id
printf -- '---\nnext_id: 3\n---\n'                             > "$V/013_selftest/docs/policy/_index.md"         # counter present — quiet (canonical form)
printf -- '---\nstatus: draft\n---\ndecision\n'                > "$V/013_selftest/docs/adr/KJP-ADR-00001.md"     # missing id
printf -- '---\ntitle: adr toc\n---\n'                         > "$V/013_selftest/docs/adr/index.md"             # missing next_id (legacy form)
# API_SPEC mirror contract: `source:` + `readonly: true`. PASS and FAIL live in two projects
# because the singleton filename can exist only once per docs tree.
printf -- '---\nstatus: draft\nsource: repo/openapi.yaml\nreadonly: true\nsynced: 2026-07-28T10:00:00\n---\nmirror\n' \
  > "$V/013_selftest/docs/tech-design/API_SPEC.md"
printf -- '---\nstatus: draft\n---\nmirror\n' > "$V/014_mirror/docs/tech-design/API_SPEC.md"

# A session note may wikilink other sessions — hippocampus/ is outside the shared surface
# and deliberately outside this scan. Otherwise-valid so only the wikilink rule could
# speak; it must not.
session WL-20260718-120014 active
printf -- 'follows [[KJP-20260718-120000]] and [[hippocampus/KJP-20260718-120001]]\n' \
  >> "$V/hippocampus/WL-20260718-120014.md"

# ---------------------------------------------------------------- run
# Findings (stdout) and warns (stderr) are separate channels by design — captured
# separately so each can be asserted, and so warns never pollute the findings asserts.
REPORT="$(/bin/bash "$VALIDATE" "$V" 2>/dev/null)"; rc=$?
WARNS="$(/bin/bash "$VALIDATE" "$V" 2>&1 >/dev/null)"
echo "--- report ---"; printf '%s\n' "$REPORT"; echo "--- asserts ---"

assert_exit    "default mode exits 0 even with findings" 0 "$rc"

# rules fire
assert_match   "doc status in session note is caught"        'BAD-20260718-120001.md:2: document status "draft"'
assert_match   "invalid status is caught"                    'BAD-20260718-120002.md:2: invalid status "frozen"'
assert_match   "retired status cancel is caught"             'BAD-20260718-120013.md:2: retired status "cancel"'
assert_match   "missing key: project"                        'BAD-20260718-120005.md:1: missing frontmatter key: project'
assert_match   "missing key: updated"                        'BAD-20260718-120005.md:1: missing frontmatter key: updated'
assert_match   "missing key: related_ticket"                 'BAD-20260718-120005.md:1: missing frontmatter key: related_ticket'
assert_match   "missing key: cc_session_ids"                 'BAD-20260718-120005.md:1: missing frontmatter key: cc_session_ids'
assert_match   "missing frontmatter entirely is caught"      'BAD-20260718-120006.md:1: no YAML frontmatter'
assert_match   "CRLF file is parsed, not misread"            'CRLF-20260718-120009.md:2: invalid status "frozen"'
assert_no_match "CRLF file is not misreported as headerless" 'CRLF-20260718-120009.md:1: no YAML frontmatter'
assert_no_match "retired uid is not a required key"          'missing frontmatter key: uid'
assert_no_match "retired writer is not a required key"       'missing frontmatter key: writer'
assert_no_match "retired created is not a required key"      'missing frontmatter key: created'

# retired keys, raw layer — a key that is present and no longer meant to be. One assert per key,
# so dropping any one of them from the check's target list kills a specific assert.
assert_match   "raw: retired uid is caught"                  'RETIRED-20260718-120016.md:7: retired key "uid"'
assert_match   "raw: retired created is caught"              'RETIRED-20260718-120016.md:8: retired key "created"'
assert_match   "raw: retired writer is caught"               'RETIRED-20260718-120016.md:9: retired key "writer"'

# retired keys, wiki layer — the ten 0.1.x keys. `title` carries the rename instruction, the
# other nine the deletion instruction, so both message shapes are pinned.
assert_match   "wiki: retired uid is caught"                 'retired-keys.md:3: retired key "uid"'
assert_match   "wiki: retired title says renamed to summary" 'retired-keys.md:4: retired key "title" (renamed — the one-line summary: is its replacement)'
assert_match   "wiki: retired type is caught"                'retired-keys.md:5: retired key "type"'
assert_match   "wiki: retired tags is caught"                'retired-keys.md:6: retired key "tags"'
assert_match   "wiki: retired dri is caught"                 'retired-keys.md:7: retired key "dri"'
assert_match   "wiki: retired species is caught"             'retired-keys.md:8: retired key "species"'
assert_match   "wiki: retired source_sessions is caught"     'retired-keys.md:9: retired key "source_sessions"'
assert_match   "wiki: retired source_items is caught"        'retired-keys.md:10: retired key "source_items"'
assert_match   "wiki: retired recalled is caught"            'retired-keys.md:11: retired key "recalled"'
assert_match   "wiki: retired useful is caught"              'retired-keys.md:12: retired key "useful"'
# The note has a summary, so the summary rule cannot be what is speaking above — without this
# the ten asserts could pass on a note that was simply broken in a different way.
assert_no_match "wiki: a summarised note is not asked for a summary" 'retired-keys.md:1: missing frontmatter key: summary'

# wiki scope — one positive per directory pins the scope
assert_match   "project p_memory dir is scanned"             'p_memory/no-summary.md:1: missing frontmatter key: summary'
assert_match   "common facts/ is scanned"                    'facts/facts-no-summary.md:1: missing frontmatter key: summary'
assert_match   "common facts/machines is scanned"            'machines/machine-no-summary.md:1: missing frontmatter key: summary'
assert_match   "common patterns/ is scanned"                 'patterns/patterns-no-summary.md:1: missing frontmatter key: summary'
assert_match   "common policies/ is scanned"                 'policies/policies-no-summary.md:1: missing frontmatter key: summary'
assert_match   "tools root is scanned (recall mirror)"       '999_tools/tools-no-summary.md:1: missing frontmatter key: summary'
assert_match   "neocortex/ is scanned (wiki layer)"          'neocortex/NEO-no-summary.md:1: missing frontmatter key: summary'
# An empty value is the same hole as an absent key — the summary line IS recall's search surface.
assert_match   "wiki: an empty summary: value is still missing" 'empty-summary.md:1: missing frontmatter key: summary'

# `_index.md` line format + dangling links. recall injects the folder indexes and nothing else,
# so an index pointing at a file that is not there makes recall lie and no other check can see it.
# One positive per scanned root, so dropping any root from the scope kills a specific assert.
assert_match   "index: p_memory/_index dangling link is caught"  'p_memory/_index.md:6: dangling _index link: \[\[ghost-note\]\]'
assert_match   "index: neocortex/_index is scanned"              'neocortex/_index.md:2: dangling _index link: \[\[NEO-ghost\]\]'
assert_match   "index: tools root _index is scanned"             '999_tools/_index.md:2: dangling _index link: \[\[tool-ghost\]\]'
assert_match   "index: common layer _index is scanned"           'facts/_index.md:2: dangling _index link: \[\[facts-ghost\]\]'
# line-form violations — one assert per shape, so relaxing any part of the form kills a specific one
assert_match   "index: hyphen where canon writes an em dash"     'p_memory/_index.md:7: malformed _index line'
assert_match   "index: an entry with no summary text"            'p_memory/_index.md:8: malformed _index line'
assert_match   "index: a bullet carrying no wikilink"            'p_memory/_index.md:9: malformed _index line'
# the quiet half — a canonical entry, and the non-entry lines an index legitimately carries
assert_no_match "index: the canonical entry line is quiet"       'p_memory/_index.md:5'
assert_no_match "index: heading/prose/blank lines are not entries" 'p_memory/_index.md:[1-4]:'
assert_no_match "index: a link that resolves is never dangling"  'dangling _index link: \[\[good\]\]'
# 🔴 Locale regression guard (KJP-74) — one assert per stem, so a partial collapse still fails.
assert_no_match "index: non-ASCII stem 가 resolves"              'dangling _index link: \[\[가\]\]'
assert_no_match "index: non-ASCII stem 나 resolves"              'dangling _index link: \[\[나\]\]'
assert_no_match "index: non-ASCII stem 다 resolves"              'dangling _index link: \[\[다\]\]'
assert_no_match "index: non-ASCII stem 라 resolves"              'dangling _index link: \[\[라\]\]'
assert_no_match "index: a resolving link is not dangling (neocortex)" 'dangling _index link: \[\[NEO-good\]\]'
# scope boundary. hippocampus/ is the raw layer and never a recall target; its fixture carries a
# dangling link, so silence can only mean the boundary held.
assert_no_match "index: hippocampus/ TOCs are outside the scan"  'ghost-session'

# ------------------------------------------------- docs-layer indexes + project hub (KJP-82)
# Dangling links only. One positive per scanned shape, so dropping any part of the scope kills a
# specific assert rather than quietly shrinking the net.
assert_match   "docs index: the docs TOC is scanned for dangling links" 'docs/_index.md:9: dangling _index link: \[\[ghost-doc\]\]'
assert_match   "docs index: the project hub is scanned"                 '013_selftest/_index.md:5: dangling _index link: \[\[ghost-hub\]\]'
assert_match   "docs index: the scan recurses into docs subfolders"     'tech-design/_index.md:5: dangling _index link: \[\[ghost-nested-doc\]\]'
# 🔴 The exclusion this card had to keep alive rather than kill. Every bullet in that docs TOC
# breaks the wiki line form (hyphen · no summary · no wikilink at all) and the file opens with
# frontmatter and prose. Measured 2026-08-11: 85 of the real vault's docs index lines would be
# reported under the wiki form, against a canon that does not exist for this layer
# (knowledge-convention.md §summary governs memory notes; doc-catalog.md says only "TOC pointers").
# A check with 85 false positives is a check everyone learns to ignore.
assert_no_match "docs index: the wiki line form is never applied to a docs TOC" 'docs/_index.md:[0-9]*: malformed'
assert_no_match "docs index: the hub's prose is never a line-form finding"      '013_selftest/_index.md:[0-9]*: malformed'
# The quiet half of the dangling rule, one assert per resolution shape, each paired with a firing
# link in the same file — so silence here cannot be the silence of a scan that never ran.
assert_no_match "docs index: a resolving bare stem is not dangling"           'dangling _index link: \[\[fm-v2\]\]'
assert_no_match "docs index: a resolving vault-relative link is not dangling" 'dangling _index link: \[\[013_selftest/'
# 🔴 Locale regression (KJP-74) on the docs side — one assert per stem, so a partial collapse of
# the target set still fails. Their firing neighbour ghost-nested-doc keeps the pair honest.
assert_no_match "docs index: non-ASCII stem 문서가 resolves" 'dangling _index link: \[\[문서가\]\]'
assert_no_match "docs index: non-ASCII stem 문서나 resolves" 'dangling _index link: \[\[문서나\]\]'
# Boundaries that this card does NOT move. Both fixtures dangle, so silence can only mean the
# exclusion held: the raw layer stays out, and p_memory/ subfolders stay the wiki layer's call.
assert_no_match "docs index: p_memory/ subfolders are in neither index scan" 'ghost-nested-pmem'
# Relative addressing inside a wikilink. Obsidian follows `../`, so a docs TOC that uses it is
# legal and must not read as dangling — while a `../` link that genuinely leaves the vault or
# names nothing must still fire. Measured 2026-08-11: zero instances in the real vault's index
# list lines today, which is exactly why the pair below is fixture-pinned rather than assumed.
assert_no_match "docs index: a ../ link that resolves is not dangling" 'dangling _index link: \[\[\.\./fm-v2\]\]'
assert_match    "docs index: a ../ link that resolves to nothing fires" 'tech-design/_index.md:7: dangling _index link: \[\[\.\./ghost-updir\]\]'

# Index coverage (KJP-82) — the same relation read backwards. A dangling link makes recall believe
# in a note that is not there; an uncovered note makes recall never learn that a real one exists.
# The second is the quieter failure: the file is intact and every other rule passes.
assert_match   "coverage: an unindexed p_memory note is caught"  'p_memory/orphan.md:1: uncovered note: \[\[orphan\]\]'
assert_match   "coverage: an unindexed non-ASCII stem is caught" 'p_memory/마.md:1: uncovered note: \[\[마\]\]'
assert_match   "coverage: the common layer is in coverage scope" 'facts/machines/machine-orphan.md:1: uncovered note: \[\[machine-orphan\]\]'
# The quiet half, one assert per resolution shape. Each is paired with a positive above — the
# bare-stem shape with orphan.md, the vault-relative shape with machine-orphan.md in the very same
# folder — so silence here cannot be the silence of a scan that never ran.
assert_no_match "coverage: a bare-stem line covers its own folder"       'p_memory/good.md:1: uncovered note'
assert_no_match "coverage: a vault-relative line covers a child folder"  'machine-no-summary.md:1: uncovered note'
assert_no_match "coverage: a child folder with no index is covered from above" 'patterns-no-summary.md:1: uncovered note'
assert_no_match "coverage: the common root's own note is covered"        'wl-dreaming.md:1: uncovered note'
# 🔴 Locale regression, coverage side (the KJP-74 class). The four stems are indexed and must be
# recognised as covered; one assert per stem, so a partial collapse of the covered set still fails.
# 마 above is the paired positive that keeps these four from being vacuous.
assert_no_match "coverage: indexed non-ASCII stem 가 is covered"  '가.md:1: uncovered note'
assert_no_match "coverage: indexed non-ASCII stem 나 is covered"  '나.md:1: uncovered note'
assert_no_match "coverage: indexed non-ASCII stem 다 is covered"  '다.md:1: uncovered note'
assert_no_match "coverage: indexed non-ASCII stem 라 is covered"  '라.md:1: uncovered note'
# Exclusions — the same set the note scan uses, since coverage asks its question about exactly the
# files that scan collects. Each excluded file below is genuinely named by no index, so widening
# the note set would make it fire.
assert_no_match "coverage: an index is not a note"               '_index.md:1: uncovered note'
assert_no_match "coverage: 0.* meta files are not notes"         '0.rejected.md:1: uncovered note'
assert_no_match "coverage: dream-logs.md is not a note"          'dream-logs.md:1: uncovered note'
assert_no_match "coverage: nested p_memory stays out of scope"   'deep-no-summary.md:1: uncovered note'
# Scope boundaries, the same two trees the dangling scan excludes. Both hold unindexed files
# (every hippocampus/ session, every docs/ document), so silence can only mean the boundary held.
assert_no_match "coverage: hippocampus/ is outside the coverage scan" 'hippocampus/.*uncovered note'
assert_no_match "coverage: docs/ is outside the coverage scan"        'docs/.*uncovered note'

# session-uid wikilinks on the shared surface — one positive per scan root
assert_match   "docs/: bare session wikilink is caught"      'docs/wl-doc.md:4: session uid wikilink on the shared surface: \[\[KJP-20260718-120000\]\]'
assert_match   "docs/: hippocampus/-prefixed link is caught" 'docs/wl-path.md:4: .*\[\[hippocampus/KJP-20260718-120001\]\]'
assert_match   "alias form (uid pipe label) is caught"       'docs/wl-path.md:4: .*\[\[KJP-20260718-120002|the session\]\]'
assert_match   "p_memory/: heading form is caught"           'p_memory/wl-pmem.md:4: .*\[\[KJP-20260718-120003#Progress\]\]'
assert_match   "wikilink scan recurses into nested/"         'p_memory/nested/wl-nested.md:4: .*\[\[KJP-20260718-120004\]\]'
assert_match   "common layer: embed form (bang-link) caught" 'facts/wl-common.md:4: .*\[\[KJP-20260718-120005\]\]'
assert_match   "common root + PREFIX-less uid"               'wl-dreaming.md:4: .*\[\[20260719-005513\]\]'
assert_match   "neocortex/ is on the shared surface too"     'neocortex/wl-neo.md:4: .*\[\[KJP-20260718-120017\]\]'

# docs frontmatter — session key = finding (both YAML shapes); unknown keys = stderr warn
assert_match   "docs fm: inline-map session key is caught"   'fm-session.md:5: session key in docs frontmatter'
assert_match   "docs fm: top-level session key is caught"    'fm-session.md:6: session key in docs frontmatter'
assert_no_match "docs fm: clean v2 frontmatter passes"       'fm-v2.md'
assert_no_match "docs fm: legacy keys + date-only updated are never findings" 'fm-legacy.md'

# docs frontmatter — v2 coverage extension: status · history subkeys · id/next_id · mirror
assert_match   "docs fm: missing status is caught"           'fm-nostatus.md:1: missing frontmatter key: status'
assert_match   "docs fm: foreign status value is caught"     'fm-badstatus.md:2: invalid docs status "frozen"'
assert_match   "docs fm: session vocabulary in docs status"  'fm-sessionstatus.md:2: session status "active" used in a docs document'
assert_no_match "docs fm: quoted status is not a false positive" 'fm-quoted.md'
assert_match   "docs fm: v1 history date: in inline map"     'fm-v1hist.md:4: v1 history key "date:"'
assert_match   "docs fm: v1 history by: in inline map"       'fm-v1hist.md:4: v1 history key "by:"'
assert_match   "docs fm: v1 history by: in block entry"      'fm-v1hist.md:6: v1 history key "by:"'
assert_match   "docs fm: v1 history date: in flow style"     'fm-flowhist.md:3: v1 history key "date:"'
assert_match   "docs fm: quoted by: in flow style"           'fm-flowhist.md:3: v1 history key "by:"'
assert_match   "docs fm: quoted session key is caught"       'fm-qsession.md:3: session key in docs frontmatter'
assert_no_match "docs fm: quoted status registers as status" 'fm-qsession.md:1: missing frontmatter key: status'
assert_match   "policy/: missing id is caught"               'policy/KJP-POL-00002.md:1: missing id:'
assert_match   "adr/: missing id is caught"                  'adr/KJP-ADR-00001.md:1: missing id:'
assert_no_match "policy/: id present passes"                 'KJP-POL-00001.md'
assert_match   "adr/: legacy index.md without next_id is caught" 'adr/index.md:1: missing next_id:'
assert_no_match "policy/: _index.md with next_id passes"     'policy/_index.md'
assert_match   "API_SPEC mirror: missing source is caught"   '014_mirror/docs/tech-design/API_SPEC.md:1: missing source:'
assert_match   "API_SPEC mirror: missing readonly is caught" '014_mirror/docs/tech-design/API_SPEC.md:1: API_SPEC mirror without readonly: true'
assert_no_match "API_SPEC mirror: source + readonly pass"    '013_selftest/docs/tech-design/API_SPEC.md'

SAVED_REPORT="$REPORT"; REPORT="$WARNS"
assert_match   "docs fm: unknown key warns on stderr"        'fm-legacy.md:2: unknown docs frontmatter key: kind'
assert_no_match "docs fm: session key is never demoted to a warn" 'session key in docs frontmatter'
assert_match   "docs fm: date-only updated warns on stderr"  'fm-legacy.md:5: date-only updated'
assert_match   "docs fm: quoted unknown key still warns"     'fm-qsession.md:4: unknown docs frontmatter key: kind'
assert_no_match "docs fm: datetime updated never warns"      'fm-v2.md'
assert_no_match "docs fm: hippocampus/ placeholder is outside the docs scan" 'sample-session.md'
REPORT="$SAVED_REPORT"

# quiet cases
assert_no_match "plain uid + v2 history: template pass"      'wl-plain.md'
assert_no_match "non-uid wikilinks are not flagged"          'another-note'
# Pattern is anchored to the wikilink message — the id/next_id fixtures above legitimately
# put KJP-ADR/KJP-POL filenames into the findings stream, and must not trip this assert.
assert_no_match "ADR/policy doc wikilinks are not session uids" 'wikilink on the shared surface: .*KJP-\(ADR\|POL\)'
assert_no_match "session wikilinks inside hippocampus/ are legal" 'WL-20260718-120014'
assert_no_match "clean session note produces no finding"     'CLEAN-20260718-120000'
assert_no_match "parked is a legal session status"           'PARKED-20260718-120012'
assert_no_match "quoted scalars are not false positives"     'QUOTED-20260718-12000[78]'
assert_no_match "hippocampus/_index.md is excluded (TOC rule)"  'hippocampus/_index.md'
assert_no_match "hippocampus/index.md is excluded (legacy TOC)" 'hippocampus/index.md'
assert_no_match "sample-session.md placeholder is excluded"  'sample-session.md'
assert_no_match "nested session is out of scope"             'NESTED-20260718-120010'
assert_no_match "nested p_memory note is out of scope"       'deep-no-summary.md'
# Anchored to the note-scan message, not the filename: since the _index scan landed, a folder TOC
# legitimately appears in the findings stream under its own rules. What must never happen is a TOC
# being asked for a note's frontmatter.
assert_no_match "p_memory _index.md is excluded from the note scan" 'p_memory/_index.md:1: missing frontmatter key: summary'
assert_no_match "p_memory 0.* meta file is excluded"         '0.rejected.md'
assert_no_match "summarised p_memory note produces no finding" 'p_memory/good.md'
assert_no_match "common facts note with summary is quiet"    'misc-x.md'
assert_no_match "tools note with summary is quiet"           'tool-mcp.md'
assert_no_match "tools _index.md is excluded from the note scan" '999_tools/_index.md:1: missing frontmatter key: summary'
# The load-bearing one for the scope split: the tools root is gitignored, so it is NOT the shared
# surface and a session wikilink there is legal. Adding it to SDIRS makes this line fire.
assert_no_match "tools root is outside the shared-surface scan" 'wl-tools.md'
assert_no_match "neocortex note with summary is quiet"       'NEO-good.md'
assert_no_match "neocortex _index.md is excluded from the note scan" 'neocortex/_index.md:1: missing frontmatter key: summary'
# dream-logs.md is dreaming's run log, not a note — it has no summary and must never be asked
# for one. Its exclusion is by name, so a real vault does not report a phantom finding.
assert_no_match "neocortex dream-logs.md is excluded"        'dream-logs.md'

# Scan counts are reported, so a collapsed scan is visible rather than silent. The exact
# numbers are asserted (not just "some count"), recomputed by hand for the 0.2.0 fixture set:
#   12 sessions — CLEAN · BAD-1 · BAD-2 · PARKED-12 · BAD-13 · BAD-5 · BAD-6 · QUOTED-7 ·
#     QUOTED-8 · CRLF-9 · RETIRED-16 · WL-14 (index/_index/sample excluded; nested out of scope)
#   25 wiki — 11 p_memory (good + no-summary + empty-summary + wl-pmem + retired-keys + orphan
#     + the four non-ASCII stems 가/나/다/라 (locale regression, KJP-74) + 마 (its coverage twin);
#     _index/0.*/nested excluded)
#     + 8 common (3 facts + 2 machines + 1 pattern + 1 policy +
#     1 common-root note; the two _index files excluded) + 3 neocortex (NEO-no-summary + NEO-good +
#     wl-neo; _index/dream-logs excluded) + 3 tools (_index.md excluded)
#   5 wiki indexes — the folder TOCs the note scan just excluded, counted by the scan that owns
#     them: p_memory/_index + neocortex/_index + 999_tools/_index + org/facts/_index + org/_index
#   5 docs indexes — every index under a project folder that the wiki scan does not own (KJP-82):
#     013_selftest/_index (the hub) + docs/_index + docs/policy/_index + docs/adr/index (legacy
#     spelling) + docs/tech-design/_index. 🔴 The hub is in NO other count — it is above docs/ and
#     outside every wiki root — so this number is the only evidence that half of the scan ran.
#     p_memory/nested/_index is excluded here and out of scope there, which is what its own
#     dangling fixture pins.
#   26 entries — distinct link targets harvested from those 5 TOCs, the coverage rule's evidence
#     base. 🔴 It is the one number no other count implies, and the one that separates "every note
#     is indexed" from "the indexes were never parsed": both read as zero findings. 10 from
#     p_memory/_index (good · ghost-note · 가/나/다/라 · no-summary · empty-summary · wl-pmem ·
#     retired-keys — the three repeat [[good]] lines and the link-less bullet add nothing, it is a
#     set) + 4 neocortex + 4 tools + 5 org/facts (4 stems + 1 vault-relative) + 3 org/_index
#     (1 stem + 2 vault-relative)
#   55 shared — 24 docs-tree files (23 under 013 + the 014_mirror API_SPEC; no exclusions on
#     this surface) + 16 p_memory (recursive here, so _index/0.*/nested all count; includes the
#     four non-ASCII stems, 마, orphan and nested/_index) + 10 common (the two _index files count
#     here) + 5 neocortex (whole folder, meta files included). 🔴 The project hub is NOT here:
#     this sweep takes docs/ and p_memory/, and the hub sits one level above both.
#   24 docs — the same 24 docs-tree files counted again by the docs frontmatter scan
#     (3 wl-* · 10 fm-* · 2 API_SPEC · policy/ 3 · adr/ 2 · docs/_index · tech-design/_index ·
#     문서가 · 문서나 — index/_index counted here: meta files skip rules, not the scan).
#     It tracks the docs-tree half of `shared` exactly, and the hub's absence from both is what
#     makes `docs indexes` the only place the hub can appear.
# 🔴 The asymmetry is the KJP-44 scope split, and the two numbers pin both halves: the tools root
# raises the wiki count (recall mirror) and leaves the shared count untouched (gitignored,
# so not the shared surface). Moving it to the wrong scan breaks whichever number it lands on.
# neocortex/ used to be read as the same asymmetry, and KJP-65 ended that: it is git-tracked, so
# it is on the shared surface and now raises BOTH counts. The tools root remains the only root
# that is on one side and not the other, which is what makes the split a decision rather than a
# habit — the two roots differ in git tracking, and nothing else.
# The label is `wiki`, not `knowledge`: that is what the canon calls the layer (vault-tree.md
# §Layers), and this script's own header has said `wiki` since the 0.2.0 pass. The count line is
# the only place the retired word survived.
# The common-root note (`wl-dreaming.md`) counts from the vault-paths change on: the common
# layer is scanned recursively now, because its sub-axes are not the same shape in every vault.
# The old scan named `{facts,patterns,policies}` and so silently skipped notes sitting at the
# common root — a gap, not a rule. Historical measurement, real beafter vault 2026-07, kept
# verbatim because it records what was measured then, not what this fixture set counts now:
# every other count was byte-identical before and after (19 sessions, 102 knowledge, 321 shared,
# 24 issues).
assert_match   "scanned counts appear in the summary"        '(12 sessions, 25 wiki, 5 wiki indexes, 5 docs indexes, 26 entries, 55 shared, 24 docs)'

# --strict blocks
/bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1; rc=$?
assert_exit "--strict exits 1 when there are findings" 1 "$rc"

# The vault above has many findings, so the assert just made cannot say *which* rule
# blocked. This isolated vault has exactly one finding — a shared-surface wikilink —
# so it pins that the new rule alone is enough to fail --strict. It carries no `.brain-paths`
# at all, which doubles as the negative fixture for the schema_version rule: an absent manifest
# is a legal vault (vault-tree.md §Tree axes — absent file or absent key = the default), so a
# second finding appearing here would mean the rule started firing on legal vaults.
W="$(mktemp -d -t brain-selftest-wl)"; mkdir -p "$W/hippocampus" "$W/013_wl/docs"
printf -- '---\nstatus: draft\n---\n[[KJP-20260718-120000]]\n' \
  > "$W/013_wl/docs/only.md"
REPORT="$(/bin/bash "$VALIDATE" "$W")"; rc=$?
assert_exit  "wikilink-only vault exits 0 in default mode" 0 "$rc"
assert_match "wikilink is the only finding in that vault"  'validate.sh: 1 issue(s) (0 sessions, 0 wiki, 0 wiki indexes, 0 docs indexes, 0 entries, 1 shared, 1 docs)'
/bin/bash "$VALIDATE" "$W" --strict > /dev/null 2>&1
assert_exit  "a wikilink finding alone fails --strict" 1 $?
rm -rf "$W"

# unreadable file becomes a finding rather than a silent stderr warning
CHMOD_OK=1
printf -- '---\nstatus: active\nproject: s\nupdated: u\nrelated_ticket: t\ncc_session_ids: [c]\n---\n' \
  > "$V/hippocampus/LOCKED-20260718-120011.md"
chmod 000 "$V/hippocampus/LOCKED-20260718-120011.md" 2>/dev/null || CHMOD_OK=0
[ -r "$V/hippocampus/LOCKED-20260718-120011.md" ] && CHMOD_OK=0   # running as root defeats the test
if [ "$CHMOD_OK" -eq 1 ]; then
  REPORT="$(/bin/bash "$VALIDATE" "$V" 2>/dev/null)"
  assert_match "unreadable file is reported as a finding" 'LOCKED-20260718-120011.md:1: cannot read file'
  /bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1
  assert_exit  "--strict fails on an unreadable file" 1 $?
else
  echo "skip — unreadable-file asserts (chmod ineffective; running as root?)"
fi
chmod 644 "$V/hippocampus/LOCKED-20260718-120011.md" 2>/dev/null
rm -f "$V/hippocampus/LOCKED-20260718-120011.md"

# path robustness: trailing slashes and glob metacharacters must not collapse the scan
for suffix in "" "/" "//"; do
  REPORT="$(/bin/bash "$VALIDATE" "$V$suffix" 2>/dev/null)"
  assert_match "wiki scan survives vault path suffix '$suffix'" 'facts/facts-no-summary.md'
done
GP="$(mktemp -d -t brain-selftest-glob)"; G="$GP/my[vault]"
mkdir -p "$G/$COMMON/facts" "$G/hippocampus"
printf -- 'schema_version: 2\ncommon_root: %s\n' "$COMMON" > "$G/.brain-paths"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$G/$COMMON/facts/glob-no-summary.md"
REPORT="$(/bin/bash "$VALIDATE" "$G")"
assert_match "wiki scan survives glob metachars in vault path" 'glob-no-summary.md'
rm -rf "$GP"

# env seam: BRAIN_TOOLS_REL overrides manifest/default, the same contract as BRAIN_COMMON_REL.
# Pointing it at a folder that does not exist empties the tools root *silently* — the
# tools fixture drops out of the wiki scan, nothing warns, every other scan survives.
REPORT="$(BRAIN_TOOLS_REL=no-such-tools /bin/bash "$VALIDATE" "$V" 2>&1)"
assert_no_match "BRAIN_TOOLS_REL override drops the tools root" 'tools-no-summary.md'
assert_no_match "an absent tools override stays silent"         'no-such-tools'
assert_match    "other scans survive the tools override"        'facts/facts-no-summary.md'

# empty vault: no files at all — must not blow up, and must show a zero scan count
E="$(mktemp -d -t brain-selftest-empty)"; mkdir -p "$E/hippocampus"
REPORT="$(/bin/bash "$VALIDATE" "$E" 2>&1)"; rc=$?
assert_exit  "empty vault exits 0" 0 "$rc"
assert_match "empty vault reports a zero scan count" '(0 sessions, 0 wiki, 0 wiki indexes, 0 docs indexes, 0 entries, 0 shared, 0 docs)'
# No `.brain-paths` here either: the schema_version rule must stay silent on a vault that never
# declared a manifest, because every key then resolves to its documented default — a legal vault.
assert_no_match "empty vault: an absent manifest is legal and silent" 'schema_version'
/bin/bash "$VALIDATE" "$E" --strict > /dev/null 2>&1
assert_exit  "empty vault exits 0 even under --strict" 0 $?
rm -rf "$E"

# `.brain-paths` schema_version. A manifest that declares the axes but not which schema they are
# in is the silent-zero hazard vault-paths.sh exists for: a consumer reading it cannot tell a
# 0.2.0 layout from a pre-restructure one, and falls back to the old defaults without a word.
# Three states, three fixtures — absent key, unknown value, declared value — so neither half of
# the rule can be dropped without killing a specific assert.
H="$(mktemp -d -t brain-selftest-schema)"; mkdir -p "$H/hippocampus" "$H/$COMMON"
printf -- 'common_root: %s\nprojects_root: .\n' "$COMMON" > "$H/.brain-paths"
REPORT="$(/bin/bash "$VALIDATE" "$H" 2>/dev/null)"
assert_match    "schema: a manifest without schema_version is caught" '.brain-paths:1: missing schema_version'
printf -- 'schema_version: 99\ncommon_root: %s\n' "$COMMON" > "$H/.brain-paths"
REPORT="$(/bin/bash "$VALIDATE" "$H" 2>/dev/null)"
assert_match    "schema: an unknown schema_version is caught"         '.brain-paths:1: unknown schema_version "99"'
printf -- 'schema_version: 2\ncommon_root: %s\n' "$COMMON" > "$H/.brain-paths"
REPORT="$(/bin/bash "$VALIDATE" "$H" 2>/dev/null)"; rc=$?
assert_no_match "schema: the declared version passes"                 'schema_version'
assert_exit     "schema: a correctly versioned manifest exits 0" 0 "$rc"
rm -rf "$H"

# restructured vault: `.brain-paths` moves the two tree axes, and every scan must follow.
# This is the layout that used to return a silent zero — the whole reason vault-paths.sh exists.
R="$(mktemp -d -t brain-selftest-restructured)"
mkdir -p "$R/hippocampus" "$R/_primary/patterns" "$R/_primary/_company/machines" \
         "$R/projects/013_restructured/p_memory" "$R/projects/013_restructured/docs" \
         "$R/999_Archive" "$R/_templates/machines" "$R/gear" "$R/neocortex"
printf -- 'schema_version: 2\ncommon_root: _primary\nprojects_root: projects\ntools_root: gear\n' > "$R/.brain-paths"
# tools_root moves the tools layer like the other two axes — a no-summary note under gear/
# pins that the manifest key is followed (the default tools root is pinned by the main vault).
# gear/ raises only the wiki count: the tools layer is never on the shared surface.
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/gear/rs-tools-no-summary.md"
# neocortex/ stays at the vault root even when every manifest axis moves — root-fixed by
# design, no neocortex_root key (vault-paths.sh manifests only the axes that move between
# vaults; same class as hippocampus/). This fixture pins that the scan ignores the manifest.
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/neocortex/rs-neo-no-summary.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/_primary/patterns/rs-pattern-no-summary.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/_primary/_company/machines/rs-nested-no-summary.md"
# Excluded from the note scan (meta) and IN the _index scan — its link dangles on purpose, so the
# restructured common layer's TOCs are pinned as reachable through the manifest too.
printf -- '- [[x]] — toc\n'                 > "$R/_primary/_company/_index.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/projects/013_restructured/p_memory/rs-know-no-summary.md"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/999_Archive/rs-archived-no-summary.md"   # excluded (retired)
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R/_templates/machines/hardware.md"         # excluded (skeleton)
# The docs frontmatter scan resolves its roots through the same manifest — a session key
# under projects/<NNN_*>/docs must be found, or the scan silently missed the moved tree.
printf -- '---\nstatus: draft\nhistory:\n  - { at: 2026-07-28T10:00:00, change: x, session: "RS-20260718-120000" }\n---\n' \
  > "$R/projects/013_restructured/docs/rs-fm-session.md"
REPORT="$(/bin/bash "$VALIDATE" "$R" 2>&1)"
assert_match    "restructured: common root under _primary is scanned"   'rs-pattern-no-summary.md'
assert_match    "restructured: nested common subtree is scanned"        'rs-nested-no-summary.md'
assert_match    "restructured: projects/ NNN_* p_memory is scanned"     'rs-know-no-summary.md'
assert_match    "restructured: docs frontmatter scan follows the manifest" 'rs-fm-session.md:4: session key in docs frontmatter'
assert_match    "restructured: manifest tools_root is followed"         'rs-tools-no-summary.md:1: missing frontmatter key: summary'
assert_match    "restructured: root-fixed neocortex is scanned"         'rs-neo-no-summary.md:1: missing frontmatter key: summary'
assert_no_match "restructured: _index.md is excluded from the note scan" '_index.md:1: missing frontmatter key: summary'
assert_match    "restructured: the moved common layer's TOC is scanned" '_company/_index.md:1: dangling _index link: \[\[x\]\]'
assert_no_match "restructured: 999_Archive is excluded"                 'rs-archived-no-summary.md'
assert_no_match "restructured: _templates skeletons are excluded"       '_templates/machines/hardware.md'
assert_no_match "restructured: no missing-root warning when it resolves" 'common root not found'
assert_match    "restructured: scan is not silently empty"              '(0 sessions, 5 wiki, 1 wiki indexes, 0 docs indexes, 1 entries, 6 shared, 1 docs)'

# a manifest pointing at a root that does not exist must say so, not scan zero in silence
printf -- 'schema_version: 2\ncommon_root: nope\n' > "$R/.brain-paths"
REPORT="$(/bin/bash "$VALIDATE" "$R" 2>&1)"
assert_match    "missing common root warns on stderr"                   'common root not found'
rm -rf "$R"

# the real 2026-07 tree: `common_root: org`, a folder holding only an `_index.md` TOC, and no
# tools root at all. The tools layer is machine-global and git-untracked, so a vault without
# it is a *legal* state — absence must be silent (no warning, unlike the common root) and must
# not collapse any other scan.
R2="$(mktemp -d -t brain-selftest-org)"
mkdir -p "$R2/hippocampus" "$R2/$COMMON/patterns" "$R2/$COMMON/empty-axis"
printf -- 'schema_version: 2\ncommon_root: %s\n' "$COMMON" > "$R2/.brain-paths"
printf -- '---\nupdated: 2026-07-18\n---\n' > "$R2/$COMMON/patterns/org-no-summary.md"
printf -- '- [[x]] — axis toc\n'            > "$R2/$COMMON/empty-axis/_index.md"     # excluded (note scan)
REPORT="$(/bin/bash "$VALIDATE" "$R2" 2>&1)"; rc=$?
assert_exit     "org vault: exits 0" 0 "$rc"
assert_match    "org vault: common root under org/ is scanned"          'org-no-summary.md:1: missing frontmatter key: summary'
# A folder holding nothing but a TOC produces no *note* finding — but the TOC itself is still an
# index, and its link dangles, so the two rules speak to the same file for different reasons.
assert_no_match "org vault: _index-only folder is not asked for a summary" 'empty-axis/_index.md:1: missing frontmatter key: summary'
assert_match    "org vault: the _index-only folder's TOC is still scanned" 'empty-axis/_index.md:1: dangling _index link: \[\[x\]\]'
assert_no_match "org vault: absent tools root is silent (legal state)"  '999_tools'
assert_no_match "org vault: no missing-root warning at all"             'not found'
assert_match    "org vault: counts"                                     '(0 sessions, 1 wiki, 1 wiki indexes, 0 docs indexes, 1 entries, 2 shared, 0 docs)'
rm -rf "$R2"

# usage errors exit 2 (documented separately from the findings exit codes)
/bin/bash "$VALIDATE" > /dev/null 2>&1;                  assert_exit "no argument exits 2" 2 $?
/bin/bash "$VALIDATE" "$V/nope" > /dev/null 2>&1;        assert_exit "nonexistent root exits 2" 2 $?
/bin/bash "$VALIDATE" "$V" --bogus > /dev/null 2>&1;     assert_exit "unknown option exits 2" 2 $?

# ---------------------------------------------------------------- value-axis-drift.sh
# KJP-58 — value-axis literal drift detector (pricing · tiers). Fixtures pin the agreed
# teeth (3-way agreement 2026-07-29 §4):
#   · the rule data is READ from the §Value Axes table, never inlined — proven by an
#     alternate-home fixture canon (PRICEBOOK §Rates): the hint text AND the home
#     exclusions must follow the table, so a hardcoded BUSINESS fails both at once;
#   · report-only output — the delete-and-replace-with-link wording, no autofix;
#   · code fences and inline `code` spans are example context, not drift — positive and
#     false-positive cases both pinned (the assert discipline at the top of this file);
#   · a canon without the pricing row exits 2 LOUD — silently scanning nothing is how
#     a moved SSOT would hide.
DRIFT="${DRIFT_SH:-$HERE/value-axis-drift.sh}"
DV="$(mktemp -d -t brain-selftest-drift)"
mkdir -p "$DV/013_drift/docs/tech-design" "$DV/013_drift/docs/pricebook" "$DV/hippocampus"

# Alternate-home fixture canon — same table shape as project-docs-convention §Value Axes,
# different home. The decoy row after the section end pins the section scoping: rule data
# ends where §Value Axes ends.
cat > "$DV/fixture-canon.md" <<'EOF'
# fixture canon
## Value Axes — one value kind, one home
| Value kind | The only original |
|---|---|
| pricing · tiers · unit economics | PRICEBOOK §Rates |
| security normative statements | POL |
## next section
| pricing | NOT-THE-TABLE |
EOF

# One line = one scenario; the line numbers are load-bearing for the asserts below.
# Frontmatter (line 3), fence (line 10), inline code (line 12), and bare plan/원인 prose
# (line 13) are the false-positive half; lines 6-8 and 14 are the positive half.
cat > "$DV/013_drift/docs/tech-design/PRD.md" <<'EOF'
---
status: draft
pricehint: $5 per seat
---

Our price is $9.99/mo for the Pro plan.
국내 가격은 9,900원, 상위는 5만원.
프로 플랜과 무료 티어를 나눈다.
```
price = "$9.99"
```
Set `PRICE=$9.99` and `$1` in the env.
원인 분석과 플랜 수립이 필요하다. The plan is to refactor.
Free/Pro/Enterprise 3단 구성.
EOF

# The home itself is the original, not drift — both exclusion shapes, derived from the
# table's home column: the docs/<home>/ tree and the <HOME>.md filename anywhere.
printf -- '---\nstatus: draft\n---\nrate: $9.99\n'  > "$DV/013_drift/docs/pricebook/rates.md"
printf -- '---\nstatus: draft\n---\nprice $9.99\n'  > "$DV/013_drift/docs/PRICEBOOK.md"

REPORT="$(/bin/bash "$DRIFT" "$DV" --convention "$DV/fixture-canon.md" 2>/dev/null)"; rc=$?
assert_exit     "drift: default mode exits 0 with findings"       0 "$rc"
assert_match    "drift: currency literal in prose is caught"      'PRD.md:6: value-axis drift'
assert_match    "drift: axis label comes from the table"          '(pricing · tiers · unit economics)'
assert_match    "drift: replacement hint reads the table home"    'delete and replace with a \[\[PRICEBOOK\]\] §Rates link'
assert_no_match "drift: rows outside §Value Axes are not rule data" 'NOT-THE-TABLE'
assert_match    "drift: EN tier + plan-word adjacency is caught"  'PRD.md:6: .*Pro plan'
assert_match    "drift: KRW comma literal is caught"              'PRD.md:7: .*9,900원'
assert_match    "drift: 만원 literal is caught"                   'PRD.md:7: .*5만원'
assert_match    "drift: KO tier adjacency is caught"              'PRD.md:8: .*프로 플랜'
assert_match    "drift: KO tier word 티어 is caught"              'PRD.md:8: .*무료 티어'
assert_match    "drift: tier slash-list is caught"                'PRD.md:14: .*Free/Pro'
assert_no_match "drift: frontmatter is not scanned"               'PRD.md:3'
assert_no_match "drift: fenced code block is example context"     'PRD.md:10'
assert_no_match "drift: inline code spans are example context"    'PRD.md:12'
assert_no_match "drift: bare plan/원인 prose is not a literal"    'PRD.md:13'
assert_no_match "drift: home tree docs/pricebook/ is excluded"    'rates.md'
assert_no_match "drift: home file PRICEBOOK.md is excluded"       'PRICEBOOK.md:'
assert_match    "drift: counts appear in the summary"             '7 finding(s) (1 docs)'
/bin/bash "$DRIFT" "$DV" --convention "$DV/fixture-canon.md" --strict >/dev/null 2>&1
assert_exit     "drift: --strict exits 1 on findings"             1 $?

# Default canon resolution — script-relative ../docs/, the real project-docs-convention.
# Pins two things at once: the relative-path seam works from wherever the script lives,
# and the real canon still carries the pricing row with home BUSINESS §BM.
DV2="$(mktemp -d -t brain-selftest-drift2)"
mkdir -p "$DV2/014_real/docs/tech-design" "$DV2/014_real/docs/business" "$DV2/hippocampus"
printf -- '---\nstatus: draft\n---\n티어별 과금은 월 ₩12,000이다.\n' > "$DV2/014_real/docs/tech-design/ARCHITECTURE.md"
printf -- '---\nstatus: draft\n---\n월 ₩12,000 (원본).\n'            > "$DV2/014_real/docs/business/BUSINESS.md"
REPORT="$(/bin/bash "$DRIFT" "$DV2" 2>/dev/null)"; rc=$?
assert_exit     "drift: real canon via script-relative default"    0 "$rc"
assert_match    "drift: real canon row catches the KRW literal"    'ARCHITECTURE.md:4: .*₩12,000'
assert_match    "drift: hint text for the real home"               '\[\[BUSINESS\]\] §BM'
assert_no_match "drift: BUSINESS.md itself is never drift"         'BUSINESS.md:'
assert_no_match "drift: docs/business/ tree is never drift"        'docs/business/'
assert_match    "drift: real-canon vault counts"                   '1 finding(s) (1 docs)'

# Clean vault — OK line with a visible scan count (a collapsed scan must not look clean).
DV3="$(mktemp -d -t brain-selftest-drift3)"
mkdir -p "$DV3/013_clean/docs" "$DV3/hippocampus"
printf -- '---\nstatus: draft\n---\nNo literals here; the plan is to ship.\n' > "$DV3/013_clean/docs/notes.md"
REPORT="$(/bin/bash "$DRIFT" "$DV3" 2>/dev/null)"; rc=$?
assert_exit     "drift: clean vault exits 0"                       0 "$rc"
assert_match    "drift: clean vault reports OK with the scan count" 'OK — no drift (1 docs)'
/bin/bash "$DRIFT" "$DV3" --strict >/dev/null 2>&1
assert_exit     "drift: clean vault exits 0 under --strict"        0 $?

# A canon without the pricing row = the SSOT moved. Loud exit 2, never a zero scan.
printf -- '## Value Axes — one value kind, one home\n| Value kind | The only original |\n|---|---|\n| logical data model | ARCHITECTURE §데이터 모델 |\n' \
  > "$DV/norow-canon.md"
REPORT="$(/bin/bash "$DRIFT" "$DV" --convention "$DV/norow-canon.md" 2>&1 >/dev/null)"; rc=$?
assert_exit     "drift: canon without the pricing row exits 2"     2 "$rc"
assert_match    "drift: the missing-row error is named, not silent" 'no pricing row'

# usage errors exit 2 — same contract as validate.sh
/bin/bash "$DRIFT" > /dev/null 2>&1;             assert_exit "drift: no argument exits 2" 2 $?
/bin/bash "$DRIFT" "$DV" --bogus > /dev/null 2>&1; assert_exit "drift: unknown option exits 2" 2 $?
rm -rf "$DV" "$DV2" "$DV3"

echo "---"
if [ "$fails" -eq 0 ]; then echo "validate-selftest: all assertions passed"; exit 0; fi
echo "validate-selftest: $fails assertion(s) failed"; exit 1
