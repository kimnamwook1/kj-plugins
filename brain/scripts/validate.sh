#!/bin/bash
# validate.sh — brain vault schema linter.
#
#   validate.sh <vault-root> [--strict]
#
# Checks session-note frontmatter (required keys, uid format, uid/filename match,
# status vocabulary) and knowledge-note `title:`. Reports as `file:line: message`.
# Findings alone never fail the run (exit 0); --strict turns any finding into exit 1.
# Usage errors (bad args / unreadable root / mktemp failure) exit 2 in both modes.
#
# Portability: macOS stock bash 3.2 + POSIX find/awk only. No associative arrays,
# no mapfile, no `find -printf`, no `grep -P`, no python/jq/yq.
set -u

STRICT=0
VAULT=""
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help) echo "usage: validate.sh <vault-root> [--strict]"; exit 0 ;;
    -*) echo "validate.sh: unknown option: $arg" >&2; exit 2 ;;
    *) VAULT="$arg" ;;
  esac
done

[ -n "$VAULT" ] || { echo "usage: validate.sh <vault-root> [--strict]" >&2; exit 2; }
[ -d "$VAULT" ] || { echo "validate.sh: not a directory: $VAULT" >&2; exit 2; }

OUT="$(mktemp -t brain-validate)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
LIST="$(mktemp -t brain-validate-list)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
trap 'rm -f "$OUT" "$LIST"' EXIT

# The vault path is only ever passed to find as a *start path*, never spliced into a
# -path/-name glob — so trailing slashes and glob metacharacters in the path (`my[vault]`)
# cannot silently collapse a scan to zero files. Every glob pattern below is a literal
# owned by this script. Directory scoping uses -mindepth/-maxdepth instead of -path.

# Shared awk prelude: strip CR (CRLF files would otherwise fail every `$0 == "---"`
# test and be misreported as "no frontmatter"), and unquote scalar values so that
# `status: "active"` is not a false positive. unq() peels one matched layer of ' or ".
AWK_PRELUDE='
  function unq(s,   f, l, q) {
    q = sprintf("%c", 39)
    if (length(s) < 2) return s
    f = substr(s, 1, 1); l = substr(s, length(s), 1)
    if ((f == "\"" && l == "\"") || (f == q && l == q)) return substr(s, 2, length(s) - 2)
    return s
  }
'

# ---------------------------------------------------------------- session notes
# Excluded alongside index.md because neither is a session: index.md is the folder TOC, and
# sample-session.md is the schema placeholder — its uid/status are literal `<active|done|cancel>`
# specimens, so validating it would flag the spec itself forever and make --strict unusable.
# ponytail: if this exclusion list grows past these two, that is the signal to promote it to a
# convention (a `meta:` frontmatter flag or a naming rule) instead of extending the -name chain.
find "$VAULT/sessions" -maxdepth 1 -type f -name '*.md' \
  ! -name 'index.md' ! -name 'sample-session.md' 2>/dev/null | sort > "$LIST"
n_sessions="$(wc -l < "$LIST" | tr -d ' ')"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" -v base="$(basename "$f" .md)" "$AWK_PRELUDE"'
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { fm = 0; fmend = 1; next }
    # ponytail: duplicate keys are last-wins (`status: frozen` then `status: active` passes).
    # A real parser would reject the duplicate; not worth the weight for hand-written frontmatter.
    fm && match($0, /^[A-Za-z_][A-Za-z0-9_]*:/) {
      k = substr($0, 1, RLENGTH - 1)
      v = substr($0, RLENGTH + 1)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      seen[k] = 1; ln[k] = NR; val[k] = unq(v)
    }
    END {
      if (!fmend) { print file ":1: no YAML frontmatter"; exit }

      n = split("uid project created updated status writer", req, " ")
      for (i = 1; i <= n; i++)
        if (!(req[i] in seen)) print file ":1: missing frontmatter key: " req[i]

      if ("uid" in seen) {
        u = val["uid"]
        # dreaming reports are cross-project batches: uid = YYYYMMDD-HHMMSS, no PREFIX by canon
        # (dreaming/SKILL.md §Report format). Same shape-only + filename-match discipline.
        if (val["session_type"] == "dreaming") {
          if (u !~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]$/)
            print file ":" ln["uid"] ": dreaming uid is not YYYYMMDD-HHMMSS: " u
          else if (u != base)
            print file ":" ln["uid"] ": uid \"" u "\" does not match filename \"" base "\""
        }
        # ponytail: shape-only check — TST-20261345-996699 (month 13, day 45) passes.
        # Calendar validation in awk costs more than the class of typo it would catch.
        else if (u !~ /^[A-Z][A-Z0-9]*-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9]$/)
          print file ":" ln["uid"] ": uid is not <PREFIX>-YYYYMMDD-HHMMSS: " u
        else if (u != base)
          print file ":" ln["uid"] ": uid \"" u "\" does not match filename \"" base "\""
      }

      if ("status" in seen) {
        s = val["status"]
        if (s != "active" && s != "done" && s != "cancel") {
          if (s ~ /^(stub|draft|approved|deprecated|stale)$/)
            print file ":" ln["status"] ": document status \"" s "\" used in a session note (session status = active|done|cancel)"
          else
            print file ":" ln["status"] ": invalid status \"" s "\" (expected active|done|cancel)"
        }
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

# -------------------------------------------------------------- knowledge notes
# Collect the scan roots as directories, then hand them to find as start paths.
# Indexed arrays are bash 3.2-safe (only *associative* arrays are 4.0+).
KDIRS=()
while IFS= read -r d; do
  [ -d "$d/knowledge" ] && KDIRS[${#KDIRS[@]}]="$d/knowledge"
done < <(find "$VAULT" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9]_*' 2>/dev/null | sort)
for sub in facts patterns policies; do
  [ -d "$VAULT/000_common/$sub" ] && KDIRS[${#KDIRS[@]}]="$VAULT/000_common/$sub"
done
# facts/machines/ is the one nested knowledge subtree recall reads (one note per machine),
# so add it as an explicit scan root. -maxdepth 1 (below) is kept, so arbitrary deeper nesting
# — and project knowledge/ subfolders — stay out of scope. Surgical, not a blanket recurse.
[ -d "$VAULT/000_common/facts/machines" ] && KDIRS[${#KDIRS[@]}]="$VAULT/000_common/facts/machines"

# An empty array expanded under `set -u` is an unbound-variable error in bash 3.2 — guard it.
if [ ${#KDIRS[@]} -eq 0 ]; then
  : > "$LIST"
else
  # Meta-file exclusion (`index.md` + `0.*`) mirrors skills/_session-shared/recall.md:11-14.
  find "${KDIRS[@]}" -maxdepth 1 -type f -name '*.md' \
    ! -name 'index.md' ! -name '0.*' 2>/dev/null | sort > "$LIST"
fi
n_knowledge="$(wc -l < "$LIST" | tr -d ' ')"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" '
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }
    fm && /^title:[ \t]*[^ \t]/ { ok = 1 }
    END { if (!ok) print file ":1: missing frontmatter key: title" }
  ' "$f"
done < "$LIST" >> "$OUT"

# ------------------------------------------------------------------------ report
# The scanned counts print on every run so a collapsed scan (0 files) is visibly
# different from a clean vault — "OK" on its own cannot distinguish the two.
#
# ponytail: known limits, all judged not worth the weight for a real vault —
#   · symlinked notes are skipped (`-type f`); use `find -L` if vaults ever use links.
#   · filenames containing newlines break the line-based file list and counts.
#   · `awk -v base=...` interprets backslash escapes, so a filename with a backslash
#     reaches awk mangled (the uid/filename comparison may misreport).
scanned="$n_sessions sessions, $n_knowledge knowledge"
count="$(wc -l < "$OUT" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
  echo "validate.sh: OK — no issues ($scanned) $VAULT"
  exit 0
fi

cat "$OUT"
echo "validate.sh: $count issue(s) ($scanned) $VAULT"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
