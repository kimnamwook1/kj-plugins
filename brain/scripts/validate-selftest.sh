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
         "$V/000_common/facts" "$V/000_common/patterns" "$V/000_common/policies"

session() {  # <basename> <uid> <status>
  printf -- '---\nuid: %s\nproject: selftest\ncreated: 2026-07-18\nupdated: 2026-07-18\nstatus: %s\nwriter: nwkim\n---\n\n## Goal\n' \
    "$2" "$3" > "$V/sessions/$1.md"
}

session CLEAN-20260718-120000 CLEAN-20260718-120000 active          # clean — must stay silent
session BAD-20260718-120001   BAD-20260718-120001   draft           # doc status in a session
session BAD-20260718-120002   BAD-20260718-120002   frozen          # invalid status
session BAD-20260718-120003   BAD-20260718-999999   active          # uid != filename
session BAD-20260718-120004   not-a-uid             active          # malformed uid

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
printf -- '---\nuid: YYYYMMDD-HHMMSS\nproject: <project-slug>\ncreated: YYYY-MM-DD\nupdated: YYYY-MM-DD\nstatus: <active|done|cancel>\n---\n' \
  > "$V/sessions/sample-session.md"

# Nested sessions are out of scope (-maxdepth 1). Broken on purpose so that dropping
# -maxdepth 1 makes it surface and kills the assert below.
printf -- '# no frontmatter\n' > "$V/sessions/nested/NESTED-20260718-120010.md"

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
printf -- '---\ntitle: tool inventory\n---\n' > "$V/000_common/facts/tool-x.md"

# ---------------------------------------------------------------- run
REPORT="$(/bin/bash "$VALIDATE" "$V")"; rc=$?
echo "--- report ---"; printf '%s\n' "$REPORT"; echo "--- asserts ---"

assert_exit    "default mode exits 0 even with findings" 0 "$rc"

# rules fire
assert_match   "doc status in session note is caught"        'BAD-20260718-120001.md:6: document status "draft"'
assert_match   "invalid status is caught"                    'BAD-20260718-120002.md:6: invalid status "frozen"'
assert_match   "uid/filename mismatch is caught"             'BAD-20260718-120003.md:2: uid .* does not match filename'
assert_match   "malformed uid is caught"                     'BAD-20260718-120004.md:2: uid is not <PREFIX>-YYYYMMDD-HHMMSS'
assert_match   "missing key: project"                        'BAD-20260718-120005.md:1: missing frontmatter key: project'
assert_match   "missing key: updated"                        'BAD-20260718-120005.md:1: missing frontmatter key: updated'
assert_match   "missing key: writer"                         'BAD-20260718-120005.md:1: missing frontmatter key: writer'
assert_match   "missing frontmatter entirely is caught"      'BAD-20260718-120006.md:1: no YAML frontmatter'
assert_match   "CRLF file is parsed, not misread"            'CRLF-20260718-120009.md:6: invalid status "frozen"'
assert_no_match "CRLF file is not misreported as headerless" 'CRLF-20260718-120009.md:1: no YAML frontmatter'

# knowledge scope — one positive per directory pins the scope
assert_match   "project knowledge dir is scanned"            'knowledge/no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/facts is scanned"                 'facts/facts-no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/patterns is scanned"              'patterns/patterns-no-title.md:1: missing frontmatter key: title'
assert_match   "000_common/policies is scanned"              'policies/policies-no-title.md:1: missing frontmatter key: title'

# quiet cases
assert_no_match "clean session note produces no finding"     'CLEAN-20260718-120000'
assert_no_match "quoted scalars are not false positives"     'QUOTED-20260718-12000[78]'
assert_no_match "sessions/index.md is excluded"              'sessions/index.md'
assert_no_match "sample-session.md placeholder is excluded"  'sample-session.md'
assert_no_match "nested session is out of scope"             'NESTED-20260718-120010'
assert_no_match "nested knowledge note is out of scope"      'deep-no-title.md'
assert_no_match "knowledge index.md is excluded"             'knowledge/index.md'
assert_no_match "knowledge 0.* meta file is excluded"        '0.rejected.md'
assert_no_match "titled knowledge note produces no finding"  'knowledge/good.md'
assert_no_match "000_common facts note with title is quiet"  'tool-x.md'

# Scan counts are reported, so a collapsed scan is visible rather than silent. The exact
# numbers are asserted (not just "some count"): 10 sessions, and 6 knowledge = 2 project
# (good + no-title; index/0.*/nested excluded) + 2 facts + 1 pattern + 1 policy.
assert_match   "scanned counts appear in the summary"        '(10 sessions, 6 knowledge)'

# --strict blocks
/bin/bash "$VALIDATE" "$V" --strict > /dev/null 2>&1; rc=$?
assert_exit "--strict exits 1 when there are findings" 1 "$rc"

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
assert_match "empty vault reports a zero scan count" '(0 sessions, 0 knowledge)'
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
