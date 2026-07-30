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
mkdir -p "$V/sessions/nested" "$V/013_selftest/knowledge/nested" \
         "$V/013_selftest/docs/policy" "$V/013_selftest/docs/adr" \
         "$V/013_selftest/docs/tech-design" "$V/014_mirror/docs/tech-design" \
         "$V/000_common/facts" "$V/000_common/facts/machines" \
         "$V/000_common/patterns" "$V/000_common/policies" \
         "$V/999_tools"

session() {  # <basename> <uid> <status>
  printf -- '---\nuid: %s\nproject: selftest\ncreated: 2026-07-18\nupdated: 2026-07-18\nstatus: %s\nwriter: nwkim\n---\n\n## Goal\n' \
    "$2" "$3" > "$V/sessions/$1.md"
}

session CLEAN-20260718-120000 CLEAN-20260718-120000 active          # clean — must stay silent
session BAD-20260718-120001   BAD-20260718-120001   draft           # doc status in a session
session BAD-20260718-120002   BAD-20260718-120002   frozen          # invalid status
session BAD-20260718-120003   BAD-20260718-999999   active          # uid != filename
session BAD-20260718-120004   not-a-uid             active          # malformed uid

# The 3-value vocabulary is active|parked|done (KJP-48). `parked` is first-class — a positive
# fixture in the *quiet* direction only proves the scan ran if something else in the same scan
# fires, which the pair below guarantees: `cancel` is the retired token and must be reported.
session PARKED-20260718-120012 PARKED-20260718-120012 parked        # legal — parked is a session status
session BAD-20260718-120013    BAD-20260718-120013    cancel        # retired vocabulary — must be caught

printf -- '---\nuid: BAD-20260718-120005\ncreated: 2026-07-18\nstatus: active\n---\n' \
  > "$V/sessions/BAD-20260718-120005.md"                            # missing project/updated/writer
printf -- '# just a body\n' > "$V/sessions/BAD-20260718-120006.md"   # no frontmatter
printf -- '---\ntitle: sessions index\n---\n' > "$V/sessions/index.md"  # excluded (TOC)
# _index.md is the same folder-TOC rule under its other name — broken as a session on purpose
# (no uid/status), so silence can only mean the exclusion held.
printf -- '---\ntitle: sessions toc\n---\n' > "$V/sessions/_index.md"   # excluded (TOC, _index form)

# Quoted scalars must NOT be false positives (regression: `status: "active"` blocked --strict).
session QUOTED-20260718-120007 '"QUOTED-20260718-120007"' '"active"'
printf -- '---\nuid: QUOTED-20260718-120008\nproject: s\ncreated: c\nupdated: u\nstatus: %s\nwriter: n\n---\n' \
  "'done'" > "$V/sessions/QUOTED-20260718-120008.md"

# CRLF file — must be parsed, not misreported as "no frontmatter". Its status is invalid,
# so this is a positive fixture: CR mishandling would change the message, not just silence it.
printf -- '---\r\nuid: CRLF-20260718-120009\r\nproject: s\r\ncreated: c\r\nupdated: u\r\nstatus: frozen\r\nwriter: n\r\n---\r\n' \
  > "$V/sessions/CRLF-20260718-120009.md"

# The schema placeholder: deliberately broken three ways (placeholder uid, placeholder status,
# missing writer) so "silent" can only mean the exclusion held, not that the fixture was clean.
printf -- '---\nuid: YYYYMMDD-HHMMSS\nproject: <project-slug>\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\nstatus: <active|parked|done>\n---\n' \
  > "$V/sessions/sample-session.md"

# Nested sessions are out of scope (-maxdepth 1). Broken on purpose so that dropping
# -maxdepth 1 makes it surface and kills the assert below.
printf -- '# no frontmatter\n' > "$V/sessions/nested/NESTED-20260718-120010.md"

# Dreaming reports: uid = YYYYMMDD-HHMMSS without PREFIX by canon (dreaming/SKILL.md §Report
# format). Clean one must stay silent; the PREFIX-shaped one is the positive fixture — dropping
# the session_type branch makes the clean one fire and kills the assert pair below.
printf -- '---\nuid: 20260719-005513\nproject:\nsession_type: dreaming\ncreated: 2026-07-19\nupdated: 2026-07-19\nstatus: done\nwriter: scribe\n---\n' \
  > "$V/sessions/20260719-005513.md"
printf -- '---\nuid: DRM-20260719-005514\nproject:\nsession_type: dreaming\ncreated: 2026-07-19\nupdated: 2026-07-19\nstatus: done\nwriter: scribe\n---\n' \
  > "$V/sessions/DRM-20260719-005514.md"                             # dreaming uid must NOT carry a PREFIX

# Knowledge: one positive (missing title) fixture per scanned directory, so that dropping any
# single directory from the scan scope kills a specific assert.
printf -- '---\ntype: gotcha\ntitle: a real title\n---\n' > "$V/013_selftest/knowledge/good.md"
printf -- '---\ntype: gotcha\nuid: X\n---\n' > "$V/013_selftest/knowledge/no-title.md"
printf -- '---\ntype: gotcha\n---\n' > "$V/013_selftest/knowledge/index.md"      # excluded (meta)
printf -- '---\ntype: gotcha\n---\n' > "$V/013_selftest/knowledge/0.rejected.md" # excluded (meta)
printf -- '---\ntype: gotcha\n---\n' > "$V/013_selftest/knowledge/nested/deep-no-title.md"  # out of scope
printf -- '---\nkind: fact\n---\n'    > "$V/000_common/facts/facts-no-title.md"
printf -- '---\nkind: pattern\n---\n' > "$V/000_common/patterns/patterns-no-title.md"
printf -- '---\nkind: policy\n---\n'  > "$V/000_common/policies/policies-no-title.md"
# facts/machines/ is nested under facts/ (depth 2) — only reachable because validate.sh adds it
# as an explicit scan root. Positive fixture: reverting that expansion drops it from scope and
# kills the assert below, while the deeper project nested/ note stays out of scope regardless.
printf -- '---\nkind: fact\n---\n'     > "$V/000_common/facts/machines/machine-no-title.md"
# Named misc-*, not tool-*: since KJP-44 a `tool-*.md` under facts/ would contradict the canon
# (tool inventories live in 999_tools/). This fixture only has to be a titled facts note.
printf -- '---\ntitle: a titled fact\n---\n' > "$V/000_common/facts/misc-x.md"

# 999_tools/ — machine-global tool inventory (KJP-44). It sits on BOTH sides of a deliberate
# scope split, so it takes fixtures in both directions:
#   · knowledge-title scan (the recall mirror) — IN scope, because recall scans it as a [C]
#     source. Dropping the KDIRS root kills the no-title assert below.
#   · shared-surface wikilink scan — OUT of scope, because the folder is gitignored and no
#     teammate ever pulls it. Adding it to SDIRS makes wl-tools.md fire and kills its quiet assert.
# Note it reaches KDIRS only via its own explicit root: the [0-9][0-9][0-9]_* sweep demands a
# knowledge/ subfolder, which this folder deliberately does not have.
printf -- '---\nkind: fact\n---\n'              > "$V/999_tools/tools-no-title.md"
printf -- '---\ntitle: MCP inventory\n---\n'    > "$V/999_tools/tool-mcp.md"
printf -- '---\nkind: fact\n---\n'              > "$V/999_tools/index.md"   # excluded (meta) — same rule as knowledge/
printf -- '---\ntitle: tool note citing a session\n---\n[[KJP-20260718-120011]]\n' \
  > "$V/999_tools/wl-tools.md"

# Session-uid wikilinks on the shared surface. One positive fixture per scan root, so
# dropping any root from the scope kills a specific assert. Every fixture carries a
# `title:` so it stays silent for the knowledge-title rule, and the docs-tree ones carry
# `status: draft` so the docs-status rule stays quiet too — only the wikilink rule can speak.
printf -- '---\nstatus: draft\ntitle: doc with a session link\n---\n[[KJP-20260718-120000]] is the source.\n' \
  > "$V/013_selftest/docs/wl-doc.md"                                   # NNN_*/docs — bare uid
printf -- '---\nstatus: draft\ntitle: doc with a path-form link\n---\nsee [[sessions/KJP-20260718-120001]] and [[KJP-20260718-120002|the session]]\n' \
  > "$V/013_selftest/docs/wl-path.md"                                  # path prefix + alias form
printf -- '---\ntitle: knowledge with a session link\nsource_sessions: [KJP-20260718-120003]\n---\nbody cites [[KJP-20260718-120003#Progress]]\n' \
  > "$V/013_selftest/knowledge/wl-know.md"                             # NNN_*/knowledge — heading form
printf -- '---\ntitle: nested knowledge with a session link\n---\n[[KJP-20260718-120004]]\n' \
  > "$V/013_selftest/knowledge/nested/wl-nested.md"                    # recursion: nested is IN scope here
printf -- '---\ntitle: common fact with a session link\n---\n![[KJP-20260718-120005]]\n' \
  > "$V/000_common/facts/wl-common.md"                                 # 000_common — embed form
printf -- '---\ntitle: common root note\n---\ndream report [[20260719-005513]]\n' \
  > "$V/000_common/wl-dreaming.md"                                     # 000_common root + PREFIX-less uid

# Legal shared-surface references, all in one file. Two of these are load-bearing beyond
# "no false positive":
#   · the `history:` line reproduces the v2 template (project-docs-convention §frontmatter
#     Standard v2: `{ at, change, ticket }` — the KJP-39-era `session:` key is banned
#     outright now), so the fixture fails the moment that template regresses;
#   · `source_sessions:` pins the underscore guard — the session-key rule must not match
#     the key "session" inside "source_sessions" (a knowledge-axis key, legal as plain uid);
#   · `[[<PREFIX>-ADR-0000N]]` / `[[<ID>]]` are vault-internal doc-to-doc links that
#     project-docs-convention mandates — they must never be caught by the wikilink rule.
printf -- '---\nstatus: draft\ntitle: doc citing sessions correctly\nsource_sessions: [KJP-20260718-120006]\nhistory:\n  - { at: 2026-07-26T12:00:00, change: one line, ticket: "KJP-41" }\n---\nsee 20260719-005514 plus [[another-note]], [[KJP-ADR-00001]], [[KJP-POL-00002]]\n' \
  > "$V/013_selftest/docs/wl-plain.md"

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
# status: required on every non-meta docs file; vocabulary = stub|draft|approved|deprecated
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
# their index/_index carry the folder's `next_id:` counter instead. Both folder forms and
# both index spellings get one fixture each, PASS and FAIL paired.
printf -- '---\nstatus: draft\nid: KJP-POL-00001\n---\nrule\n' > "$V/013_selftest/docs/policy/KJP-POL-00001.md"
printf -- '---\nstatus: draft\n---\nrule\n'                    > "$V/013_selftest/docs/policy/KJP-POL-00002.md"  # missing id
printf -- '---\nnext_id: 3\n---\n'                             > "$V/013_selftest/docs/policy/index.md"          # counter present — quiet
printf -- '---\nstatus: draft\n---\ndecision\n'                > "$V/013_selftest/docs/adr/KJP-ADR-00001.md"     # missing id
printf -- '---\ntitle: adr toc\n---\n'                         > "$V/013_selftest/docs/adr/_index.md"            # missing next_id (_index form)
# API_SPEC mirror contract: `source:` + `readonly: true`. PASS and FAIL live in two projects
# because the singleton filename can exist only once per docs tree.
printf -- '---\nstatus: draft\nsource: repo/openapi.yaml\nreadonly: true\nsynced: 2026-07-28T10:00:00\n---\nmirror\n' \
  > "$V/013_selftest/docs/tech-design/API_SPEC.md"
printf -- '---\nstatus: draft\n---\nmirror\n' > "$V/014_mirror/docs/tech-design/API_SPEC.md"

# A session note may wikilink other sessions — sessions/ is outside the shared surface
# and deliberately outside this scan. Otherwise-valid so only the wikilink rule could
# speak; it must not.
session WL-20260718-120014 WL-20260718-120014 active
printf -- 'follows [[KJP-20260718-120000]] and [[sessions/KJP-20260718-120001]]\n' \
  >> "$V/sessions/WL-20260718-120014.md"

# ---------------------------------------------------------------- run
# Findings (stdout) and warns (stderr) are separate channels by design — captured
# separately so each can be asserted, and so warns never pollute the findings asserts.
REPORT="$(/bin/bash "$VALIDATE" "$V" 2>/dev/null)"; rc=$?
WARNS="$(/bin/bash "$VALIDATE" "$V" 2>&1 >/dev/null)"
echo "--- report ---"; printf '%s\n' "$REPORT"; echo "--- asserts ---"

assert_exit    "default mode exits 0 even with findings" 0 "$rc"

# rules fire
assert_match   "doc status in session note is caught"        'BAD-20260718-120001.md:6: document status "draft"'
assert_match   "invalid status is caught"                    'BAD-20260718-120002.md:6: invalid status "frozen"'
assert_match   "retired status cancel is caught"             'BAD-20260718-120013.md:6: retired status "cancel"'
assert_match   "uid/filename mismatch is caught"             'BAD-20260718-120003.md:2: uid .* does not match filename'
assert_match   "malformed uid is caught"                     'BAD-20260718-120004.md:2: uid is not <PREFIX>-YYYYMMDD-HHMMSS'
assert_match   "missing key: project"                        'BAD-20260718-120005.md:1: missing frontmatter key: project'
assert_match   "missing key: updated"                        'BAD-20260718-120005.md:1: missing frontmatter key: updated'
assert_match   "missing key: writer"                         'BAD-20260718-120005.md:1: missing frontmatter key: writer'
assert_match   "missing frontmatter entirely is caught"      'BAD-20260718-120006.md:1: no YAML frontmatter'
assert_match   "CRLF file is parsed, not misread"            'CRLF-20260718-120009.md:6: invalid status "frozen"'
assert_no_match "CRLF file is not misreported as headerless" 'CRLF-20260718-120009.md:1: no YAML frontmatter'
assert_no_match "dreaming report uid without PREFIX is legal" '20260719-005513\.md'
assert_match   "dreaming uid with a PREFIX is caught"        'DRM-20260719-005514.md:2: dreaming uid is not YYYYMMDD-HHMMSS'

# knowledge scope — one positive per directory pins the scope
assert_match   "project knowledge dir is scanned"            'knowledge/no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/facts is scanned"                 'facts/facts-no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/facts/machines is scanned"        'machines/machine-no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/patterns is scanned"              'patterns/patterns-no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/policies is scanned"              'policies/policies-no-title.md:1: missing frontmatter key: title'
assert_match   "999_tools is scanned (recall mirror)"        '999_tools/tools-no-title.md:1: missing frontmatter key: title'

# session-uid wikilinks on the shared surface — one positive per scan root
assert_match   "docs/: bare session wikilink is caught"      'docs/wl-doc.md:5: session uid wikilink on the shared surface: \[\[KJP-20260718-120000\]\]'
assert_match   "docs/: sessions/-prefixed link is caught"    'docs/wl-path.md:5: .*\[\[sessions/KJP-20260718-120001\]\]'
assert_match   "alias form (uid pipe label) is caught"       'docs/wl-path.md:5: .*\[\[KJP-20260718-120002|the session\]\]'
assert_match   "knowledge/: heading form is caught"          'knowledge/wl-know.md:5: .*\[\[KJP-20260718-120003#Progress\]\]'
assert_match   "wikilink scan recurses into nested/"         'knowledge/nested/wl-nested.md:4: .*\[\[KJP-20260718-120004\]\]'
assert_match   "000_common: embed form (bang-link) is caught" 'facts/wl-common.md:4: .*\[\[KJP-20260718-120005\]\]'
assert_match   "000_common root + PREFIX-less dreaming uid"  'wl-dreaming.md:4: .*\[\[20260719-005513\]\]'

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
assert_match   "adr/: _index.md without next_id is caught"   'adr/_index.md:1: missing next_id:'
assert_no_match "policy/: index.md with next_id passes"      'policy/index.md'
assert_match   "API_SPEC mirror: missing source is caught"   '014_mirror/docs/tech-design/API_SPEC.md:1: missing source:'
assert_match   "API_SPEC mirror: missing readonly is caught" '014_mirror/docs/tech-design/API_SPEC.md:1: API_SPEC mirror without readonly: true'
assert_no_match "API_SPEC mirror: source + readonly pass"    '013_selftest/docs/tech-design/API_SPEC.md'

SAVED_REPORT="$REPORT"; REPORT="$WARNS"
assert_match   "docs fm: unknown key warns on stderr"        'fm-legacy.md:2: unknown docs frontmatter key: kind'
assert_no_match "docs fm: session key is never demoted to a warn" 'session key in docs frontmatter'
assert_match   "docs fm: date-only updated warns on stderr"  'fm-legacy.md:5: date-only updated'
assert_match   "docs fm: quoted unknown key still warns"     'fm-qsession.md:4: unknown docs frontmatter key: kind'
assert_no_match "docs fm: datetime updated never warns"      'fm-v2.md'
assert_no_match "docs fm: sessions/ placeholder is outside the docs scan" 'sample-session.md'
REPORT="$SAVED_REPORT"

# quiet cases
assert_no_match "plain uid + v2 history: template pass"      'wl-plain.md'
assert_no_match "non-uid wikilinks are not flagged"          'another-note'
# Pattern is anchored to the wikilink message — the id/next_id fixtures above legitimately
# put KJP-ADR/KJP-POL filenames into the findings stream, and must not trip this assert.
assert_no_match "ADR/policy doc wikilinks are not session uids" 'wikilink on the shared surface: .*KJP-\(ADR\|POL\)'
assert_no_match "session wikilinks inside sessions/ are legal" 'WL-20260718-120014'
assert_no_match "clean session note produces no finding"     'CLEAN-20260718-120000'
assert_no_match "parked is a legal session status"           'PARKED-20260718-120012'
assert_no_match "quoted scalars are not false positives"     'QUOTED-20260718-12000[78]'
assert_no_match "sessions/index.md is excluded"              'sessions/index.md'
assert_no_match "sessions/_index.md is excluded (TOC rule)"  'sessions/_index.md'
assert_no_match "sample-session.md placeholder is excluded"  'sample-session.md'
assert_no_match "nested session is out of scope"             'NESTED-20260718-120010'
assert_no_match "nested knowledge note is out of scope"      'deep-no-title.md'
assert_no_match "knowledge index.md is excluded"             'knowledge/index.md'
assert_no_match "knowledge 0.* meta file is excluded"        '0.rejected.md'
assert_no_match "titled knowledge note produces no finding"  'knowledge/good.md'
assert_no_match "000_common facts note with title is quiet"  'misc-x.md'
assert_no_match "999_tools note with title is quiet"         'tool-mcp.md'
assert_no_match "999_tools index.md is excluded (meta rule)" '999_tools/index.md'
# The load-bearing one for the scope split: 999_tools is gitignored, so it is NOT the shared
# surface and a session wikilink there is legal. Adding it to SDIRS makes this line fire.
assert_no_match "999_tools is outside the shared-surface scan" 'wl-tools.md'

# Scan counts are reported, so a collapsed scan is visible rather than silent. The exact
# numbers are asserted (not just "some count"): 15 sessions (12 + 2 dreaming + 1 wikilink
# fixture; index/_index/sample excluded); 13 knowledge = 3 project (good + no-title +
# wl-know; index/0.*/nested excluded) + 3 facts + 1 machines + 1 pattern + 1 policy
# + 1 common-root note + 3 tools (999_tools, index.md excluded);
# 34 shared = 20 docs-tree files (19 under 013 + the 014_mirror API_SPEC — no exclusions on
# this surface) + 7 knowledge + 7 under 000_common; 20 docs = the same docs-tree files
# counted again by the docs frontmatter scan (3 wl-* · 10 fm-* · 2 API_SPEC · policy/ 3 ·
# adr/ 2 — index/_index counted here: meta files skip rules, not the scan).
# 🔴 The asymmetry is the KJP-44 scope split, and the two numbers pin both halves: 999_tools
# raises the knowledge count (recall mirror) and leaves the shared count untouched (gitignored,
# so not the shared surface). Moving it to the wrong scan breaks whichever number it lands on.
# The common-root note (`wl-dreaming.md`) counts from the vault-paths change on: the common
# layer is scanned recursively now, because its sub-axes are not the same shape in every vault.
# The old scan named `{facts,patterns,policies}` and so silently skipped notes sitting at the
# common root — a gap, not a rule. Measured on the real beafter vault: every other count is
# byte-identical before and after (19 sessions, 102 knowledge, 321 shared, 24 issues).
assert_match   "scanned counts appear in the summary"        '(15 sessions, 13 knowledge, 34 shared, 20 docs)'

# --strict blocks
/bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1; rc=$?
assert_exit "--strict exits 1 when there are findings" 1 "$rc"

# The vault above has many findings, so the assert just made cannot say *which* rule
# blocked. This isolated vault has exactly one finding — a shared-surface wikilink —
# so it pins that the new rule alone is enough to fail --strict.
W="$(mktemp -d -t brain-selftest-wl)"; mkdir -p "$W/sessions" "$W/013_wl/docs"
printf -- '---\nstatus: draft\n---\n[[KJP-20260718-120000]]\n' \
  > "$W/013_wl/docs/only.md"
REPORT="$(/bin/bash "$VALIDATE" "$W")"; rc=$?
assert_exit  "wikilink-only vault exits 0 in default mode" 0 "$rc"
assert_match "wikilink is the only finding in that vault"  'validate.sh: 1 issue(s) (0 sessions, 0 knowledge, 1 shared, 1 docs)'
/bin/bash "$VALIDATE" "$W" --strict > /dev/null 2>&1
assert_exit  "a wikilink finding alone fails --strict" 1 $?
rm -rf "$W"

# unreadable file becomes a finding rather than a silent stderr warning
CHMOD_OK=1
printf -- '---\nuid: LOCKED-20260718-120011\nproject: s\ncreated: c\nupdated: u\nstatus: active\nwriter: n\n---\n' \
  > "$V/sessions/LOCKED-20260718-120011.md"
chmod 000 "$V/sessions/LOCKED-20260718-120011.md" 2>/dev/null || CHMOD_OK=0
[ -r "$V/sessions/LOCKED-20260718-120011.md" ] && CHMOD_OK=0   # running as root defeats the test
if [ "$CHMOD_OK" -eq 1 ]; then
  REPORT="$(/bin/bash "$VALIDATE" "$V" 2>/dev/null)"
  assert_match "unreadable file is reported as a finding" 'LOCKED-20260718-120011.md:1: cannot read file'
  /bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1
  assert_exit  "--strict fails on an unreadable file" 1 $?
else
  echo "skip — unreadable-file asserts (chmod ineffective; running as root?)"
fi
chmod 644 "$V/sessions/LOCKED-20260718-120011.md" 2>/dev/null
rm -f "$V/sessions/LOCKED-20260718-120011.md"

# path robustness: trailing slashes and glob metacharacters must not collapse the scan
for suffix in "" "/" "//"; do
  REPORT="$(/bin/bash "$VALIDATE" "$V$suffix" 2>/dev/null)"
  assert_match "knowledge scan survives vault path suffix '$suffix'" 'facts/facts-no-title.md'
done
GP="$(mktemp -d -t brain-selftest-glob)"; G="$GP/my[vault]"
mkdir -p "$G/000_common/facts" "$G/sessions"
printf -- '---\nkind: fact\n---\n' > "$G/000_common/facts/glob-no-title.md"
REPORT="$(/bin/bash "$VALIDATE" "$G")"
assert_match "knowledge scan survives glob metachars in vault path" 'glob-no-title.md'
rm -rf "$GP"

# env seam: BRAIN_TOOLS_REL overrides manifest/default, the same contract as BRAIN_COMMON_REL.
# Pointing it at a folder that does not exist empties the tools root *silently* — the
# 999_tools fixture drops out of the knowledge scan, nothing warns, every other scan survives.
REPORT="$(BRAIN_TOOLS_REL=no-such-tools /bin/bash "$VALIDATE" "$V" 2>&1)"
assert_no_match "BRAIN_TOOLS_REL override drops the tools root" 'tools-no-title.md'
assert_no_match "an absent tools override stays silent"         'no-such-tools'
assert_match    "other scans survive the tools override"        'facts/facts-no-title.md'

# empty vault: no files at all — must not blow up, and must show a zero scan count
E="$(mktemp -d -t brain-selftest-empty)"; mkdir -p "$E/sessions"
REPORT="$(/bin/bash "$VALIDATE" "$E" 2>&1)"; rc=$?
assert_exit  "empty vault exits 0" 0 "$rc"
assert_match "empty vault reports a zero scan count" '(0 sessions, 0 knowledge, 0 shared, 0 docs)'
/bin/bash "$VALIDATE" "$E" --strict > /dev/null 2>&1
assert_exit  "empty vault exits 0 even under --strict" 0 $?
rm -rf "$E"

# restructured vault: `.brain-paths` moves the two tree axes, and every scan must follow.
# This is the layout that used to return a silent zero — the whole reason vault-paths.sh exists.
R="$(mktemp -d -t brain-selftest-restructured)"
mkdir -p "$R/sessions" "$R/_primary/patterns" "$R/_primary/_company/machines" \
         "$R/projects/013_restructured/knowledge" "$R/projects/013_restructured/docs" \
         "$R/999_Archive" "$R/_templates/machines" "$R/gear"
printf -- 'common_root: _primary\nprojects_root: projects\ntools_root: gear\n' > "$R/.brain-paths"
# tools_root moves the tools layer like the other two axes — a no-title note under gear/
# pins that the manifest key is followed (the default 999_tools is pinned by the main vault).
# gear/ raises only the knowledge count: the tools layer is never on the shared surface.
printf -- '---\nkind: fact\n---\n'     > "$R/gear/rs-tools-no-title.md"
printf -- '---\nkind: pattern\n---\n'  > "$R/_primary/patterns/rs-pattern-no-title.md"
printf -- '---\nkind: fact\n---\n'     > "$R/_primary/_company/machines/rs-nested-no-title.md"
printf -- '---\nkind: fact\n---\n'     > "$R/_primary/_company/_index.md"        # excluded (meta)
printf -- '---\nkind: lesson\n---\n'   > "$R/projects/013_restructured/knowledge/rs-know-no-title.md"
printf -- '---\nkind: fact\n---\n'     > "$R/999_Archive/rs-archived-no-title.md"   # excluded (retired)
printf -- '---\nkind: fact\n---\n'     > "$R/_templates/machines/hardware.md"       # excluded (skeleton)
# The docs frontmatter scan resolves its roots through the same manifest — a session key
# under projects/<NNN_*>/docs must be found, or the scan silently missed the moved tree.
printf -- '---\nstatus: draft\nhistory:\n  - { at: 2026-07-28T10:00:00, change: x, session: "RS-20260718-120000" }\n---\n' \
  > "$R/projects/013_restructured/docs/rs-fm-session.md"
REPORT="$(/bin/bash "$VALIDATE" "$R" 2>&1)"
assert_match    "restructured: common root under _primary is scanned"   'rs-pattern-no-title.md'
assert_match    "restructured: nested common subtree is scanned"        'rs-nested-no-title.md'
assert_match    "restructured: projects/ NNN_* knowledge is scanned"    'rs-know-no-title.md'
assert_match    "restructured: docs frontmatter scan follows the manifest" 'rs-fm-session.md:4: session key in docs frontmatter'
assert_match    "restructured: manifest tools_root is followed"         'rs-tools-no-title.md:1: missing frontmatter key: title'
assert_no_match "restructured: _index.md is excluded (meta rule)"       '_index.md'
assert_no_match "restructured: 999_Archive is excluded"                 'rs-archived-no-title.md'
assert_no_match "restructured: _templates skeletons are excluded"       '_templates/machines/hardware.md'
assert_no_match "restructured: no missing-root warning when it resolves" 'common root not found'
assert_match    "restructured: scan is not silently empty"              '(0 sessions, 4 knowledge, 5 shared, 1 docs)'

# a manifest pointing at a root that does not exist must say so, not scan zero in silence
printf -- 'common_root: nope\n' > "$R/.brain-paths"
REPORT="$(/bin/bash "$VALIDATE" "$R" 2>&1)"
assert_match    "missing common root warns on stderr"                   'common root not found'
rm -rf "$R"

# the real 2026-07 tree: `common_root: org`, a folder holding only an `_index.md` TOC, and no
# tools root at all. The tools layer is machine-global and git-untracked, so a vault without
# it is a *legal* state — absence must be silent (no warning, unlike the common root) and must
# not collapse any other scan.
R2="$(mktemp -d -t brain-selftest-org)"
mkdir -p "$R2/sessions" "$R2/org/patterns" "$R2/org/empty-axis"
printf -- 'common_root: org\n' > "$R2/.brain-paths"
printf -- '---\nkind: pattern\n---\n'   > "$R2/org/patterns/org-no-title.md"
printf -- '---\ntitle: axis toc\n---\n' > "$R2/org/empty-axis/_index.md"     # excluded (meta)
REPORT="$(/bin/bash "$VALIDATE" "$R2" 2>&1)"; rc=$?
assert_exit     "org vault: exits 0" 0 "$rc"
assert_match    "org vault: common root under org/ is scanned"          'org-no-title.md:1: missing frontmatter key: title'
assert_no_match "org vault: _index-only folder stays quiet"             'empty-axis'
assert_no_match "org vault: absent tools root is silent (legal state)"  '999_tools'
assert_no_match "org vault: no missing-root warning at all"             'not found'
assert_match    "org vault: counts"                                     '(0 sessions, 1 knowledge, 2 shared, 0 docs)'
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
mkdir -p "$DV/013_drift/docs/tech-design" "$DV/013_drift/docs/pricebook" "$DV/sessions"

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
mkdir -p "$DV2/014_real/docs/tech-design" "$DV2/014_real/docs/business" "$DV2/sessions"
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
mkdir -p "$DV3/013_clean/docs" "$DV3/sessions"
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
