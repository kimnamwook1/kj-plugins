#!/bin/bash
# value-axis-drift.sh — value-axis literal drift detector (pricing · tiers).
#
#   value-axis-drift.sh <vault-root> [--strict] [--convention <file>]
#
# Finds pricing/tier LITERALS sitting outside their declared home (3-way agreement
# 2026-07-29 §4 — the machine teeth for the value-axis declaration; measured
# high-frequency drift: price·tier literals duplicated into PRD·ARCHITECTURE).
#
# SSOT: the rule data — which axis is in force and where its only original lives — is
# READ from the §Value Axes table of project-docs-convention.md on every run. This
# script carries NO axis table of its own: an inlined copy would itself be a fourth
# canon original, the exact disease this detector exists to catch. The canon path
# resolves relative to this script (../docs/project-docs-convention.md), so the same
# sibling file is found whether the script runs from the repo or from an installed
# cache; --convention overrides for tests and nonstandard installs. A canon without
# the pricing row exits 2 LOUD — silently scanning nothing is how a moved SSOT hides.
#
# Report-only, never an autofix (silent or otherwise): each finding is
#   <file>:<line>: value-axis drift (<axis>): "<literal>" — delete and replace with a
#   [[<HOME>]] <section> link (the only original: <home>)
# The delete/replace is a human/PM edit. This script never writes to the vault.
#
# Excluded from scanning (the home is the original, not drift — both shapes derived
# from the table's home column, e.g. BUSINESS §BM ⇒ BUSINESS.md + docs/business/):
#   · any file named <HOME>.md, and everything under docs/<home-lowercase>/
#   · fenced code blocks (```/~~~) and inline `code` spans — quoting a value as an
#     example is not keeping a second original (pinned by validate-selftest fixtures)
#   · YAML frontmatter
#
# 🔴 Out of scope by decision: SEMANTIC duplication — the same norm restated in prose
# (e.g. a security normative statement recorded in three documents). Judging "this
# sentence means that policy" is semantics, not pattern matching; that audit belongs
# to the value-axis declaration + PM mediation, never to this script.
#
# Findings alone never fail the run (exit 0); --strict turns any finding into exit 1.
# Usage errors (bad args / unreadable root / missing axis row / mktemp) exit 2.
#
# Portability: macOS stock bash 3.2 + POSIX find/awk only. No associative arrays,
# no mapfile, no `grep -P`, no bc.
set -u

USAGE="usage: value-axis-drift.sh <vault-root> [--strict] [--convention <file>]"
STRICT=0
VAULT=""
CONV=""
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --convention)
      [ $# -ge 2 ] || { echo "value-axis-drift.sh: --convention needs a file argument" >&2; exit 2; }
      shift; CONV="$1" ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    -*) echo "value-axis-drift.sh: unknown option: $1" >&2; exit 2 ;;
    *) VAULT="$1" ;;
  esac
  shift
done

[ -n "$VAULT" ] || { echo "$USAGE" >&2; exit 2; }
[ -d "$VAULT" ] || { echo "value-axis-drift.sh: not a directory: $VAULT" >&2; exit 2; }

HERE="$(cd "$(dirname "$0")" && pwd)"
[ -n "$CONV" ] || CONV="$HERE/../docs/project-docs-convention.md"
[ -r "$CONV" ] || { echo "value-axis-drift.sh: cannot read the axis declaration: $CONV" >&2; exit 2; }

# ------------------------------------------------- rule data: the §Value Axes table
# First `|` row containing "pricing" INSIDE the section — rows after the next `## `
# heading are someone else's table, not rule data. Runs before vault-paths so a dead
# canon pointer fails on its own message, not on tree noise.
axis_row="$(awk '
  /^##[ \t]+Value Axes/     { sect = 1; next }
  sect && /^## /            { sect = 0 }
  sect && /^\|/ && /pricing/ { print; exit }
' "$CONV")"
if [ -z "$axis_row" ]; then
  echo "value-axis-drift.sh: no pricing row in §Value Axes of $CONV — the axis declaration moved; fix the pointer (--convention), never inline the table here" >&2
  exit 2
fi

AXIS="$(printf '%s\n' "$axis_row"      | awk -F'|' '{ s = $2; gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); print s }')"
HOME_SPEC="$(printf '%s\n' "$axis_row" | awk -F'|' '{ s = $3; gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); print s }')"
if [ -z "$AXIS" ] || [ -z "$HOME_SPEC" ]; then
  echo "value-axis-drift.sh: malformed pricing row in $CONV: $axis_row" >&2
  exit 2
fi

# Home column ⇒ the replacement hint and both exclusion shapes. `BUSINESS §BM` yields
# hint `[[BUSINESS]] §BM`, home file `BUSINESS.md`, home tree `docs/business/`.
HOME_DOC="${HOME_SPEC%% *}"
case "$HOME_SPEC" in
  *" "*) HINT="[[${HOME_DOC}]] ${HOME_SPEC#* }" ;;
  *)     HINT="[[${HOME_DOC}]]" ;;
esac
HOME_LC="$(printf '%s' "$HOME_DOC" | tr '[:upper:]' '[:lower:]')"

# Tree axes come from the vault's own manifest, never from literals here — see vault-paths.sh.
# shellcheck source=vault-paths.sh
. "$HERE/vault-paths.sh"

OUT="$(mktemp -t brain-drift)"       || { echo "value-axis-drift.sh: mktemp failed" >&2; exit 2; }
LIST="$(mktemp -t brain-drift-list)" || { echo "value-axis-drift.sh: mktemp failed" >&2; exit 2; }
trap 'rm -f "$OUT" "$LIST"' EXIT

# Scope = NNN_*/docs/** recursive, minus the home. The home exclusion filters with
# awk index()/substr() — literal substring tests — so nothing read from the canon is
# ever spliced into a find glob or a regex (same discipline as validate.sh start paths).
DDIRS=()
while IFS= read -r d; do
  [ -d "$d/docs" ] && DDIRS[${#DDIRS[@]}]="$d/docs"
done < <(brain_projects)

if [ ${#DDIRS[@]} -eq 0 ]; then
  : > "$LIST"
else
  find "${DDIRS[@]}" -type f -name '*.md' 2>/dev/null \
    | awk -v seg="/docs/$HOME_LC/" -v homefile="/$HOME_DOC.md" '
        index($0, seg) == 0 && substr($0, length($0) - length(homefile) + 1) != homefile
      ' | sort > "$LIST"
fi
n_docs="$(wc -l < "$LIST" | tr -d ' ')"

# ------------------------------------------------------------------- the detectors
# The detectors are MECHANISM (what a pricing/tier literal looks like); the table
# above is the RULE DATA (that the axis is in force, and where the original lives).
# Multibyte symbols (₩ € £ ¥, 한글) ride as alternation literals, never bracket
# members — a byte-oriented awk would explode a bracketed multibyte char into its
# bytes (measured on awk 20200816; alternation matches the whole sequence).
while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" -v axis="$AXIS" -v home="$HOME_SPEC" -v hint="$HINT" '
    BEGIN {
      # currency symbol + amount ($9.99 · ₩12,000 · € 5)
      PRICE_SYM  = "(\\$|₩|€|£|¥)[ ]?[0-9][0-9,.]*"
      # amount + currency word. The amount must END on a digit ("9,900원", "5만원") —
      # a bare `[0-9,.]*` would let "그림 3. 원인" match through the ". " gap.
      PRICE_WORD = "[0-9]([0-9,.]*[0-9])?[ ]?(원|만원|억원|달러|KRW|USD|EUR|JPY)"
      # currency code + amount (USD 12)
      PRICE_CODE = "(KRW|USD|EUR|JPY)[ ]?[0-9]"
      # tier-name + plan-word adjacency, both scripts. Adjacency is the false-positive
      # guard: "플랜" or "plan" alone is prose, next to a tier name it is a tier literal.
      NAME    = "([Ff]ree|[Bb]asic|[Ss]tarter|[Pp]ro|[Pp]remium|[Pp]lus|[Ee]nterprise)"
      TIER_EN = "(^|[^A-Za-z])" NAME "[- ]([Tt]iers?|[Pp]lans?)([^A-Za-z]|$)"
      TIER_KO = "(무료|유료|베이직|스타터|프로|프리미엄|엔터프라이즈)[ ]?(티어|플랜|요금제)"
      # tier ladders written as lists: Free/Pro/Enterprise, Free · Pro
      TIER_LS = "(^|[^A-Za-z])" NAME "[ ]?(/|·)[ ]?" NAME "([^A-Za-z]|$)"
      NPAT = 6
      pat[1] = PRICE_SYM; pat[2] = PRICE_WORD; pat[3] = PRICE_CODE
      pat[4] = TIER_EN;   pat[5] = TIER_KO;    pat[6] = TIER_LS
    }
    { sub(/\r$/, "") }
    # YAML frontmatter — out of scope (only a body literal is a kept second original).
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---"      { fm = 0; next }
    fm                     { next }
    # fenced code blocks — example context, not drift
    /^[ \t]*(```|~~~)/     { fence = !fence; next }
    fence                  { next }
    {
      s = $0
      # inline `code` spans — replaced by a single space, not deleted: outright removal
      # could butt-join the surrounding text into a literal that was never written.
      while (match(s, /`[^`]+`/))
        s = substr(s, 1, RSTART - 1) " " substr(s, RSTART + RLENGTH)
      for (i = 1; i <= NPAT; i++) {
        t = s
        while (match(t, pat[i])) {
          m = substr(t, RSTART, RLENGTH)
          gsub(/^[ \t]+/, "", m); gsub(/[ \t]+$/, "", m)
          print file ":" NR ": value-axis drift (" axis "): \"" m "\" — delete and replace with a " hint " link (the only original: " home ")"
          t = substr(t, RSTART + RLENGTH)
        }
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

# ------------------------------------------------------------------------ report
# The scan count prints on every run so a collapsed scan (0 docs) is visibly different
# from a clean vault — same contract as validate.sh.
count="$(wc -l < "$OUT" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
  echo "value-axis-drift.sh: OK — no drift ($n_docs docs) $VAULT"
  exit 0
fi

cat "$OUT"
echo "value-axis-drift.sh: $count finding(s) ($n_docs docs) $VAULT"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
