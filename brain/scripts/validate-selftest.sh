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
mkdir -p "$V/sessions/nested" "$V/013_selftest/knowledge/nested" "$V/013_selftest/docs" \
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
# `title:` so it stays silent for the knowledge-title rule and only the wikilink rule
# can speak.
printf -- '---\ntitle: doc with a session link\n---\n[[KJP-20260718-120000]] is the source.\n' \
  > "$V/013_selftest/docs/wl-doc.md"                                   # NNN_*/docs — bare uid
printf -- '---\ntitle: doc with a path-form link\n---\nsee [[sessions/KJP-20260718-120001]] and [[KJP-20260718-120002|the session]]\n' \
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
#   · the `history:` line reproduces the corrected `project-docs-convention.md:26` template
#     (KJP-39 root cause — the template used to *prescribe* the wikilink), so the fixture
#     fails the moment that template regresses to `[[…]]`;
#   · `[[<PREFIX>-ADR-0000N]]` / `[[<ID>]]` are vault-internal doc-to-doc links that
#     project-docs-convention:61·73·98 mandate — they must never be caught by this rule.
printf -- '---\ntitle: doc citing sessions correctly\nsource_sessions: [KJP-20260718-120006]\nhistory:\n  - { date: 2026-07-26, change: one line, by: scribe, session: "KJP-20260718-120007" }\n---\nsee 20260719-005514 plus [[another-note]], [[KJP-ADR-00001]], [[KJP-POL-00002]]\n' \
  > "$V/013_selftest/docs/wl-plain.md"

# A session note may wikilink other sessions — sessions/ is outside the shared surface
# and deliberately outside this scan. Otherwise-valid so only the wikilink rule could
# speak; it must not.
session WL-20260718-120014 WL-20260718-120014 active
printf -- 'follows [[KJP-20260718-120000]] and [[sessions/KJP-20260718-120001]]\n' \
  >> "$V/sessions/WL-20260718-120014.md"

# ---------------------------------------------------------------- run
REPORT="$(/bin/bash "$VALIDATE" "$V")"; rc=$?
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
assert_match   "docs/: bare session wikilink is caught"      'docs/wl-doc.md:4: session uid wikilink on the shared surface: \[\[KJP-20260718-120000\]\]'
assert_match   "docs/: sessions/-prefixed link is caught"    'docs/wl-path.md:4: .*\[\[sessions/KJP-20260718-120001\]\]'
assert_match   "alias form (uid pipe label) is caught"       'docs/wl-path.md:4: .*\[\[KJP-20260718-120002|the session\]\]'
assert_match   "knowledge/: heading form is caught"          'knowledge/wl-know.md:5: .*\[\[KJP-20260718-120003#Progress\]\]'
assert_match   "wikilink scan recurses into nested/"         'knowledge/nested/wl-nested.md:4: .*\[\[KJP-20260718-120004\]\]'
assert_match   "000_common: embed form (bang-link) is caught" 'facts/wl-common.md:4: .*\[\[KJP-20260718-120005\]\]'
assert_match   "000_common root + PREFIX-less dreaming uid"  'wl-dreaming.md:4: .*\[\[20260719-005513\]\]'

# quiet cases
assert_no_match "plain uid + corrected history: template pass" 'wl-plain.md'
assert_no_match "non-uid wikilinks are not flagged"          'another-note'
assert_no_match "ADR/policy doc wikilinks are not session uids" 'KJP-\(ADR\|POL\)-0000'
assert_no_match "session wikilinks inside sessions/ are legal" 'WL-20260718-120014'
assert_no_match "clean session note produces no finding"     'CLEAN-20260718-120000'
assert_no_match "parked is a legal session status"           'PARKED-20260718-120012'
assert_no_match "quoted scalars are not false positives"     'QUOTED-20260718-12000[78]'
assert_no_match "sessions/index.md is excluded"              'sessions/index.md'
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
# fixture); 12 knowledge = 3 project (good + no-title + wl-know; index/0.*/nested excluded)
# + 3 facts + 1 machines + 1 pattern + 1 policy + 3 tools (999_tools, index.md excluded);
# 17 shared = 3 docs + 7 knowledge (all meta files and nested/ included — no exclusions on
# this surface) + 7 under 000_common.
# 🔴 The asymmetry is the KJP-44 scope split, and the two numbers pin both halves: 999_tools
# raises the knowledge count (recall mirror) and leaves the shared count untouched (gitignored,
# so not the shared surface). Moving it to the wrong scan breaks whichever number it lands on.
assert_match   "scanned counts appear in the summary"        '(15 sessions, 12 knowledge, 17 shared)'

# --strict blocks
/bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1; rc=$?
assert_exit "--strict exits 1 when there are findings" 1 "$rc"

# The vault above has many findings, so the assert just made cannot say *which* rule
# blocked. This isolated vault has exactly one finding — a shared-surface wikilink —
# so it pins that the new rule alone is enough to fail --strict.
W="$(mktemp -d -t brain-selftest-wl)"; mkdir -p "$W/sessions" "$W/013_wl/docs"
printf -- '---\ntitle: the only finding in this vault\n---\n[[KJP-20260718-120000]]\n' \
  > "$W/013_wl/docs/only.md"
REPORT="$(/bin/bash "$VALIDATE" "$W")"; rc=$?
assert_exit  "wikilink-only vault exits 0 in default mode" 0 "$rc"
assert_match "wikilink is the only finding in that vault"  'validate.sh: 1 issue(s) (0 sessions, 0 knowledge, 1 shared)'
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
  REPORT="$(/bin/bash "$VALIDATE" "$V")"
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
  REPORT="$(/bin/bash "$VALIDATE" "$V$suffix")"
  assert_match "knowledge scan survives vault path suffix '$suffix'" 'facts/facts-no-title.md'
done
GP="$(mktemp -d -t brain-selftest-glob)"; G="$GP/my[vault]"
mkdir -p "$G/000_common/facts" "$G/sessions"
printf -- '---\nkind: fact\n---\n' > "$G/000_common/facts/glob-no-title.md"
REPORT="$(/bin/bash "$VALIDATE" "$G")"
assert_match "knowledge scan survives glob metachars in vault path" 'glob-no-title.md'
rm -rf "$GP"

# empty vault: no files at all — must not blow up, and must show a zero scan count
E="$(mktemp -d -t brain-selftest-empty)"; mkdir -p "$E/sessions"
REPORT="$(/bin/bash "$VALIDATE" "$E" 2>&1)"; rc=$?
assert_exit  "empty vault exits 0" 0 "$rc"
assert_match "empty vault reports a zero scan count" '(0 sessions, 0 knowledge, 0 shared)'
/bin/bash "$VALIDATE" "$E" --strict > /dev/null 2>&1
assert_exit  "empty vault exits 0 even under --strict" 0 $?
rm -rf "$E"

# usage errors exit 2 (documented separately from the findings exit codes)
/bin/bash "$VALIDATE" > /dev/null 2>&1;                  assert_exit "no argument exits 2" 2 $?
/bin/bash "$VALIDATE" "$V/nope" > /dev/null 2>&1;        assert_exit "nonexistent root exits 2" 2 $?
/bin/bash "$VALIDATE" "$V" --bogus > /dev/null 2>&1;     assert_exit "unknown option exits 2" 2 $?

echo "---"
if [ "$fails" -eq 0 ]; then echo "validate-selftest: all assertions passed"; exit 0; fi
echo "validate-selftest: $fails assertion(s) failed"; exit 1
