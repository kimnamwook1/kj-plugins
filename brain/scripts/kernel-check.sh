#!/bin/bash
# kernel-check.sh — agent-definition KERNEL block drift detector.
#
#   kernel-check.sh [<agents-dir>]
#
# Checks that every agent definition under <agents-dir> (default: ../agents relative to
# this script) carries a `## KERNEL-BEGIN` … `## KERNEL-END` block, and that every one of
# those blocks is BYTE-IDENTICAL to the others. Reports as `file:line: message`; a block
# that differs also prints the line-level `diff` against the reference.
#
# Why this exists: the 4 agent profiles (worker · coder · verifier · researcher) each carry
# the same shared-discipline lines, DELIBERATELY duplicated. An agent definition cannot
# include or import another file — the harness injects only the definition itself — so the
# duplication is forced, not sloppy. Forced duplication always drifts. This script is the
# only defense: it turns "they must stay identical" from a hope into a check.
#
# 🔴 Why NOT a validate.sh check: validate.sh:30 is `usage: validate.sh <vault-root>` — it
# takes a VAULT and nothing else, and every scan it runs is rooted there. `agents/*.md` lives
# in the plugin repo, not in any vault. Bolting a repo scan onto a vault linter would give it
# two unrelated roots and one exit code covering both. Separate tool, separate root.
#
# Exit codes: 0 = every block present and identical · 1 = one or more findings · 2 = usage
# error (bad args, unreadable directory, mktemp failure).
# 🔴 Deliberate divergence from validate.sh/value-axis-drift.sh, which need `--strict` to
# turn findings into exit 1. There is no non-strict reading of KERNEL drift: two agents
# disagreeing about shared discipline is already the breakage, never a stylistic warning.
# So there is no --strict flag — findings always fail.
#
# The scanned file count prints on EVERY run, pass or fail, and a scan that found ZERO agent
# definitions is itself a finding, never a silent pass — same contract as validate.sh's
# report, hardened one notch: "all N blocks agree" is vacuously true when N is 0, and that
# is exactly how a moved directory or a renamed extension hides.
#
# Portability: macOS stock bash 3.2 + POSIX find/awk/diff only. No associative arrays,
# no mapfile, no `grep -P`, no jq/python.
set -u

USAGE="usage: kernel-check.sh [<agents-dir>]"
DIR=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) echo "$USAGE"; exit 0 ;;
    -*) echo "kernel-check.sh: unknown option: $arg" >&2; exit 2 ;;
    *) DIR="$arg" ;;
  esac
done

# Default = the sibling agents/ directory, resolved from this script's own location, so the
# same relative pair is found whether the script runs from the repo or from an installed
# plugin cache (value-axis-drift.sh resolves its canon pointer the same way).
if [ -z "$DIR" ]; then
  HERE="$(cd "$(dirname "$0")" && pwd)" || { echo "kernel-check.sh: cannot resolve script directory" >&2; exit 2; }
  DIR="$HERE/../agents"
fi
[ -d "$DIR" ] || { echo "kernel-check.sh: not a directory: $DIR" >&2; exit 2; }

OUT="$(mktemp -t brain-kernel-out)"   || { echo "kernel-check.sh: mktemp failed" >&2; exit 2; }
LIST="$(mktemp -t brain-kernel-list)" || { echo "kernel-check.sh: mktemp failed" >&2; exit 2; }
STAT="$(mktemp -t brain-kernel-stat)" || { echo "kernel-check.sh: mktemp failed" >&2; exit 2; }
REF="$(mktemp -t brain-kernel-ref)"   || { echo "kernel-check.sh: mktemp failed" >&2; exit 2; }
CUR="$(mktemp -t brain-kernel-cur)"   || { echo "kernel-check.sh: mktemp failed" >&2; exit 2; }
trap 'rm -f "$OUT" "$LIST" "$STAT" "$REF" "$CUR"' EXIT

# The directory is only ever passed to find as a *start path*, never spliced into a -path or
# -name glob — so a trailing slash or a glob metacharacter in the path (`my[agents]`) cannot
# silently collapse the scan to zero files. Every glob below is a literal owned by this script.
find "$DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort > "$LIST"
n_agents="$(wc -l < "$LIST" | tr -d ' ')"

# Block extractor. CR is stripped before every comparison — a CRLF file would otherwise fail
# `$0 == "## KERNEL-BEGIN"` on every line and be misreported as "no KERNEL block". The CR is
# stripped from the block BODY too, so a CRLF file and an LF file holding the same block
# compare equal: line endings are a checkout artifact, not a discipline difference.
#
# Emits one status line on stdout: `<state> <nlines> <beginline>`; the block body goes to the
# file named by -v out. `> (out)` is parenthesized on purpose — bare `print $0 > out` parses
# as a comparison in POSIX awk.
AWK_EXTRACT='
  { sub(/\r$/, "") }
  $0 == "## KERNEL-BEGIN" {
    nbegin++
    if (nbegin == 1) { inblk = 1; beginline = NR }
    next
  }
  $0 == "## KERNEL-END" {
    nend++
    if (inblk) inblk = 0
    next
  }
  inblk { print $0 > (out); nlines++ }
  END {
    if (nbegin == 0 && nend == 0)   st = "none"
    else if (nbegin == 0)           st = "orphan-end"
    else if (nend == 0)             st = "unterminated"
    else if (nbegin > 1 || nend > 1) st = "duplicate"
    else                            st = "ok"
    print st " " nlines+0 " " beginline+0
  }
'

# ------------------------------------------------------- pass 1: extract + pick reference
# The reference is simply the first file in sorted order that has a well-formed block. There
# is no "master" agent by design: KERNEL is a consensus, not a hierarchy, so any well-formed
# block is as good a yardstick as any other. Which one gets picked only changes which side of
# the diff each line lands on, never whether a finding is raised.
REFFILE=""
REFLINES=0
: > "$STAT"
while IFS= read -r f; do
  if [ ! -r "$f" ]; then
    printf '%s\n' "unreadable 0 0 $f" >> "$STAT"
    continue
  fi
  : > "$CUR"
  res="$(awk -v out="$CUR" "$AWK_EXTRACT" "$f")"
  st="${res%% *}"
  rest="${res#* }"
  nlines="${rest%% *}"
  beginline="${rest##* }"
  printf '%s\n' "$st $nlines $beginline $f" >> "$STAT"
  if [ "$st" = "ok" ] && [ -z "$REFFILE" ]; then
    cp "$CUR" "$REF"
    REFFILE="$f"
    REFLINES="$nlines"
  fi
done < "$LIST"

# ------------------------------------------------------------------ pass 2: judge + report
# Findings are counted here rather than by `wc -l` on the report, because a drift finding is
# multi-line (its diff hangs under it) and line-counting would inflate the total.
findings=0
while IFS= read -r line; do
  st="${line%% *}"
  r1="${line#* }"; nlines="${r1%% *}"
  r2="${r1#* }";  beginline="${r2%% *}"
  f="${r2#* }"
  case "$st" in
    unreadable)
      echo "$f:1: cannot read file (permission or broken link)" >> "$OUT"
      findings=$((findings + 1)) ;;
    none)
      echo "$f:1: missing KERNEL block — every agent definition must carry the shared discipline verbatim between '## KERNEL-BEGIN' and '## KERNEL-END'" >> "$OUT"
      findings=$((findings + 1)) ;;
    orphan-end)
      echo "$f:1: '## KERNEL-END' with no '## KERNEL-BEGIN' — the block opener is missing or misspelled" >> "$OUT"
      findings=$((findings + 1)) ;;
    unterminated)
      echo "$f:$beginline: '## KERNEL-BEGIN' is never closed — add '## KERNEL-END' after the shared discipline" >> "$OUT"
      findings=$((findings + 1)) ;;
    duplicate)
      echo "$f:$beginline: more than one KERNEL marker pair — exactly one block per agent definition" >> "$OUT"
      findings=$((findings + 1)) ;;
    ok)
      [ "$f" = "$REFFILE" ] && continue
      : > "$CUR"
      awk -v out="$CUR" "$AWK_EXTRACT" "$f" > /dev/null
      if ! diff "$REF" "$CUR" > /dev/null 2>&1; then
        echo "$f:$beginline: KERNEL block differs from the reference ($REFFILE) — the duplication has drifted; restore it byte-for-byte" >> "$OUT"
        echo "    ('<' = reference $REFFILE · '>' = this file)" >> "$OUT"
        diff "$REF" "$CUR" 2>/dev/null | sed 's/^/    /' >> "$OUT"
        findings=$((findings + 1))
      fi ;;
  esac
done < "$STAT"

# 🔴 A scan that matched nothing is a finding, not a pass. "All blocks agree" is vacuously
# true across zero files, so without this the script would print OK for a moved directory,
# a renamed extension, or a typo'd argument — reporting the absence of evidence as evidence
# of absence, which is the exact failure mode it was written to prevent.
if [ "$n_agents" -eq 0 ]; then
  echo "$DIR:1: no agent definitions found (*.md, maxdepth 1) — the scan matched nothing, which is not the same as everything passing" >> "$OUT"
  findings=$((findings + 1))
fi

# ------------------------------------------------------------------------------- report
if [ "$findings" -eq 0 ]; then
  echo "kernel-check.sh: OK — $n_agents agents, KERNEL identical ($REFLINES lines)"
  exit 0
fi

cat "$OUT"
echo "kernel-check.sh: $findings finding(s) ($n_agents agents scanned) $DIR"
exit 1
