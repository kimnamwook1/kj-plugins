#!/bin/bash
# validate.sh — brain vault schema linter.
#
#   validate.sh <vault-root> [--strict]
#
# Checks session-note frontmatter (required keys, uid format, uid/filename match,
# status vocabulary), knowledge-note `title:`, session-uid wikilinks on the
# team-shared surface, and docs frontmatter (`session:` key = violation; unknown
# keys = stderr warn only). Reports as `file:line: message`.
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

# Tree axes come from the vault's own `.brain-paths` manifest (defaults = the pre-restructure
# layout), never from literals here. See scripts/vault-paths.sh for why.
# shellcheck source=vault-paths.sh
. "$(dirname "$0")/vault-paths.sh"

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
# sample-session.md is the schema placeholder — its uid/status are literal `<active|parked|done>`
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
        if (s != "active" && s != "parked" && s != "done") {
          if (s ~ /^(stub|draft|approved|deprecated|stale)$/)
            print file ":" ln["status"] ": document status \"" s "\" used in a session note (session status = active|parked|done)"
          # `cancel` was a session status until KJP-48. Its own message carries the migration
          # instruction, since "invalid" alone would not say what to replace it with.
          else if (s == "cancel")
            print file ":" ln["status"] ": retired status \"cancel\" (session status = active|parked|done; an abandoned session is done + an abandoned tag)"
          else
            print file ":" ln["status"] ": invalid status \"" s "\" (expected active|parked|done)"
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
done < <(brain_projects)
# `999_tools/` = machine-global tool inventory (vault-tree.md §999_tools). recall scans it as a [C]
# source at the facts tier (recall.md source 2), and *this* scan is the recall mirror — so it is a
# scan root here too. It does not arrive via brain_projects: that helper excludes the reserved 9xx
# band outright, and a 9xx folder has no knowledge/ subfolder anyway (measured).
[ -d "$VAULT/999_tools" ] && KDIRS[${#KDIRS[@]}]="$VAULT/999_tools"

: > "$LIST"
# An empty array expanded under `set -u` is an unbound-variable error in bash 3.2 — guard it.
if [ ${#KDIRS[@]} -gt 0 ]; then
  # Project knowledge/ stays -maxdepth 1: its subfolders are deliberately out of scope.
  # Meta-file exclusion (`index.md` + `0.*`) mirrors skills/_session-shared/recall.md:11-14.
  find "${KDIRS[@]}" -maxdepth 1 -type f -name '*.md' \
    ! -name 'index.md' ! -name '_index.md' ! -name '0.*' 2>/dev/null >> "$LIST"
fi
# The common layer recurses instead. Its sub-axes are not the same shape in every vault — flat
# `{facts,patterns,policies}/` in one, `patterns/` plus `_company/<folder>/` in another — so
# enumerating them here would put the tree back into this file. brain_find_notes owns the
# exclusions (meta files, _templates/, archives, dreaming logs).
if [ -n "$BRAIN_COMMON" ]; then
  brain_find_notes "$BRAIN_COMMON" >> "$LIST"
fi
sort -o "$LIST" "$LIST"
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

# ------------------------------------------- session wikilinks on the shared surface
# Canon: versioning-convention.md:6 (§Share scope) + knowledge-convention.md:14
# (`source_sessions`). The shared surface is what a teammate pulls; `sessions/` sits
# outside it and a team vault gitignores it, so a `[[<uid>]]` written on the shared
# surface dangles in any vault that lacks that session. Shared notes cite a session as
# plain uid text — frontmatter and body alike.
#
# Scope = the shared surface itself: NNN_*/docs/**, NNN_*/knowledge/**, and the whole common
# layer (whichever folder `.brain-paths` names — `000_common/` by default).
# 🔴 `sessions/` is deliberately NOT scanned — a session's own wikilinks are its record,
# and the file is never pulled by anyone else.
#
# Two deliberate divergences from the knowledge-title scan above, both because the unit
# differs (that scan checks per-note schema and mirrors what *recall* reads; this one
# checks a tree a teammate *pulls*): it recurses (no -maxdepth), and it excludes no
# meta files — a dangling link in `index.md` or `0.rejected.md` breaks for a teammate
# exactly like one in a note. See knowledge note "validate 스코프는 recall 스코프의
# 미러가 원칙" — divergence by decision, recorded, not drift.
#
# 🔴 `999_tools/` is NOT scanned here, and that is not a mirror divergence — this scan was never the
# recall mirror (the knowledge-title scan above is). Its axis is *share scope*, and `999_tools/` is
# gitignored machine-local content, so it is outside the shared surface by definition: no teammate
# ever pulls it, so no link in it can dangle for one. It needs no exclusion either — it has neither
# docs/ nor knowledge/, so the sweep below never picks it up (measured).
SDIRS=()
while IFS= read -r d; do
  # brain_projects already drops the common root (it matches NNN_ when it sits at the vault
  # root), so its docs/ and knowledge/ are not scanned twice — it is added whole below.
  [ -d "$d/docs" ] && SDIRS[${#SDIRS[@]}]="$d/docs"
  [ -d "$d/knowledge" ] && SDIRS[${#SDIRS[@]}]="$d/knowledge"
done < <(brain_projects)
[ -n "$BRAIN_COMMON" ] && SDIRS[${#SDIRS[@]}]="$BRAIN_COMMON"

# Empty array under `set -u` — same guard as KDIRS above.
if [ ${#SDIRS[@]} -eq 0 ]; then
  : > "$LIST"
else
  find "${SDIRS[@]}" -type f -name '*.md' 2>/dev/null | sort > "$LIST"
fi
n_shared="$(wc -l < "$LIST" | tr -d ' ')"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" '
    BEGIN {
      # Digit runs are spelled out rather than written {8}/{6}: one-true-awk (macOS
      # /usr/bin/awk) has no ERE interval expressions, so a repetition count would not
      # error — it would silently never match. Same discipline as the uid checks above.
      D8 = "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
      D6 = "[0-9][0-9][0-9][0-9][0-9][0-9]"
      # <PREFIX>-YYYYMMDD-HHMMSS; PREFIX optional because dreaming reports carry none
      # (dreaming/SKILL.md §Report format).
      UID = "([A-Z][A-Z0-9]*-)?" D8 "-" D6
      # Covers [[uid]] · [[sessions/uid]] (any path prefix) · [[uid|alias]] ·
      # [[uid#heading]] · ![[uid]] (the leading ! is simply outside the match).
      # `[^]|#]` is POSIX-correct: a `]` right after `^` is a literal.
      # ponytail: no fenced-code-block awareness. A vault doc quoting a violation as an
      # example would be flagged; the conventions live in the plugin, not the vault, so
      # that case has no instance today. Add fence tracking only when one appears.
      LINK = "\\[\\[([^]|#]*/)?" UID "([|#][^]]*)?\\]\\]"
    }
    {
      sub(/\r$/, "")
      s = $0
      while (match(s, LINK)) {
        print file ":" NR ": session uid wikilink on the shared surface: " \
              substr(s, RSTART, RLENGTH) " (cite the session as plain uid text)"
        s = substr(s, RSTART + RLENGTH)
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

# ----------------------------------------------------- docs frontmatter (v2 schema)
# Canon: project-docs-convention.md §frontmatter Standard v2 + §history & session linkage.
# Two rules, two severities — deliberately asymmetric:
#   · `session:` key anywhere in docs frontmatter = a FINDING. Upgraded from the old
#     "no session wikilink" rule: team vaults gitignore sessions/, so even a *plain uid*
#     is a reference no teammate can resolve. Team provenance = history `ticket`; the
#     session uid rides the boundary commit message (versioning-convention.md).
#   · unknown top-level keys = stderr WARN only, never a finding — --strict must not
#     fail on them (protects docs imported from outside; migration off the v1 schema is
#     "no longer written", never a forced rewrite). Known set = the v2 vocabulary only;
#     the kind ← path derivation matrix stays in project-docs-convention (never here).
# Scope = NNN_*/docs/** recursive (the docs trees only — knowledge `source_sessions` is a
# separate, legal axis and its dirs are not scanned). index/_index are folder meta
# (`next_id`, TOC titles), so they skip the unknown-key warn but not the session check.
DDIRS=()
while IFS= read -r d; do
  [ -d "$d/docs" ] && DDIRS[${#DDIRS[@]}]="$d/docs"
done < <(brain_projects)

if [ ${#DDIRS[@]} -eq 0 ]; then
  : > "$LIST"
else
  find "${DDIRS[@]}" -type f -name '*.md' 2>/dev/null | sort > "$LIST"
fi
n_docs="$(wc -l < "$LIST" | tr -d ' ')"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  case "$(basename "$f")" in index.md|_index.md) meta=1 ;; *) meta=0 ;; esac
  awk -v file="$f" -v meta="$meta" '
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }
    fm {
      # Matches the key in every YAML shape: top-level `session:`, nested-map
      # `    session:`, inline-map `{ ..., session: ... }`. The leading class keeps
      # `source_sessions:` (underscore before) and `sessions:` (no colon after
      # "session") out of the match.
      if ($0 ~ /(^|[ \t{,])session:/) {
        print file ":" NR ": session key in docs frontmatter (banned — team provenance = history ticket:, the session uid goes in the boundary commit message)"
        next
      }
      if (!meta && match($0, /^[A-Za-z_][A-Za-z0-9_]*:/)) {
        k = substr($0, 1, RLENGTH - 1)
        if (k !~ /^(status|updated|id|source|readonly|synced|history)$/)
          print file ":" NR ": unknown docs frontmatter key: " k " (warn only — never a finding)" > "/dev/stderr"
      }
    }
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
scanned="$n_sessions sessions, $n_knowledge knowledge, $n_shared shared, $n_docs docs"
count="$(wc -l < "$OUT" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
  echo "validate.sh: OK — no issues ($scanned) $VAULT"
  exit 0
fi

cat "$OUT"
echo "validate.sh: $count issue(s) ($scanned) $VAULT"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
