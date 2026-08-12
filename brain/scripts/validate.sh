#!/bin/bash
# validate.sh — brain vault schema linter.
#
#   validate.sh <vault-root> [--strict]
#
# Checks the vault manifest's `schema_version`, session-note frontmatter (required keys, status
# vocabulary, retired keys) on the raw layer (`hippocampus/`), `summary:` on the wiki layer
# (`p_memory/` + `neocortex/` + the common and tools roots), folder indexes (`_index.md` links that
# name a file that is not there — checked on every index recall injects, docs TOCs and project hubs
# included; plus, on the wiki layer alone, the canonical line form and the inverse question, notes
# no index names), p_memory note filenames (`<pp>_<slug>.md` — the project prefix read from that
# project's hub `PREFIX:` line, plus a lowercase-kebab slug; a hub declaring no prefix is reported
# once at the hub and its notes are skipped, since nothing can say what they should be called),
# unquoted wikilinks in frontmatter (`related: [[a]]` — a nested YAML sequence,
# never a link; the wiki AND docs layers, since a block that does not parse is a syntax defect
# rather than a vocabulary one), frontmatter that does not parse at all (a value opening with a
# YAML indicator, an unclosed flow collection, or an unquoted scalar carrying `: ` — on all three
# layers, since YAML syntax is layer-independent), session-uid wikilinks on the
# team-shared surface, docs frontmatter v2 (`session:` key = violation; `status:`
# required + vocabulary; v1 history subkeys; adr `id:` and index `next_id:`;
# API_SPEC mirror keys; unknown keys and legacy `updated:` formats = stderr warn
# only), and the ADR ID audit over `docs/adr/` (the same ids read across files rather than one at
# a time: duplicate ids, holes in the issued sequence, and a `next_id` that is not ahead of them).
# Reports as `file:line: message`.
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
TARGETS="$(mktemp -t brain-validate-targets)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
# The wiki note list outlives $LIST, which each later scan overwrites: the coverage check needs the
# notes and the indexes in hand at the same time. NCOVER carries one integer back out of awk.
NOTES="$(mktemp -t brain-validate-notes)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
NCOVER="$(mktemp -t brain-validate-ncover)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
# The docs-layer index list is its own file rather than more lines in $LIST: the two lists get
# different rules (see the scope note at the index scan), and $LIST is consumed by the coverage
# check afterwards, which must keep seeing the wiki layer alone.
DOCIDX="$(mktemp -t brain-validate-docidx)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
# The ADR audit's own two files: the `docs/adr/` subset of the docs list (a cross-file question —
# duplicate ids and sequence holes are invisible to a per-file scan), and one integer back out of
# awk, the same seam NCOVER uses.
ADRL="$(mktemp -t brain-validate-adr)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
NADR="$(mktemp -t brain-validate-nadr)" || { echo "validate.sh: mktemp failed" >&2; exit 2; }
trap 'rm -f "$OUT" "$LIST" "$TARGETS" "$NOTES" "$NCOVER" "$DOCIDX" "$ADRL" "$NADR"' EXIT

# ----------------------------------------------------------- the manifest's schema version
# 🔴 One level above every scan below. `.brain-paths` is what tells a consumer where the tree is;
# a manifest that declares the axes but not *which schema* they are in cannot be read safely,
# because "absent key = the documented default" is only sound when the reader knows which
# generation of defaults applies. Without the version the resolver falls back to the
# pre-restructure layout and every scan returns zero — silently, and looking exactly like a clean
# vault. That accident is the reason vault-paths.sh exists at all.
# An absent manifest is a different case and stays silent: a vault that never restructured needs
# none, and every key resolving to its default is then correct by construction
# (vault-tree.md §Tree axes). The expected value lives in vault-paths.sh, the sole home of the
# manifest's keys and their defaults — never a literal here.
if [ -f "$BRAIN_PATHS_FILE" ]; then
  if [ -z "$BRAIN_SCHEMA_VERSION" ]; then
    echo "$BRAIN_PATHS_FILE:1: missing schema_version: (the manifest declares the tree axes but not which schema they are in — a reader cannot tell a current layout from a pre-restructure one, and falls back to the old defaults in silence; add \"schema_version: $BRAIN_SCHEMA_VERSION_EXPECTED\")" >> "$OUT"
  elif [ "$BRAIN_SCHEMA_VERSION" != "$BRAIN_SCHEMA_VERSION_EXPECTED" ]; then
    echo "$BRAIN_PATHS_FILE:1: unknown schema_version \"$BRAIN_SCHEMA_VERSION\" (this resolver understands $BRAIN_SCHEMA_VERSION_EXPECTED — the axis values below may not mean what it assumes)" >> "$OUT"
  fi
fi

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

# 🔴 The unquoted-wikilink rule (KJP-56). One definition, called from the two frontmatter scans
# below (wiki notes and docs) — held here rather than inlined twice, because a wire-format rule
# that exists in two copies is the drift this repo keeps paying for.
#
# What it is: `[[` opening a YAML value is ALWAYS a nested flow sequence, never a link. The two
# failures it produces are wildly different in how loud they are, and only one of them was ever
# noticed by a human — which is the whole argument for a detector. Measured with PyYAML on the
# real vault 2026-08-12:
#   `related: [[a]], [[b]]`  302 files  → ParserError. The frontmatter does not parse at all and
#                                         Obsidian renders the entire block as body text. This is
#                                         the half a person can see, and it is how the card opened.
#   `related: [[a]]`          52 files  → parses, to [['a']]. A nested list. Obsidian resolves no
#                                         link and reports no error; recall sees nothing.
#                                         🔴 Strictly more dangerous than the loud half: there is
#                                         no signal of any kind, so it survives every review.
#   `  - [[a]]`                0 files  → parses, to [[['a']]]. Same silence, one level deeper.
#                                         Zero today; checked because the canon this enforces tells
#                                         writers to use a block list, and dropping the quotes off
#                                         a block item is the next mistake in line.
# Canon for the correct spelling: docs/knowledge-convention.md §related.
#
# Why the pattern takes ANY key rather than a `related|aliases|projects` list: measured on the same
# vault, `related` is the only key that carries the defect today (aliases/projects hold plain
# strings — 0 occurrences), so a key list buys no precision now and needs maintenance later. And
# no key in any of this repo's schemas is a list-of-lists, so a bare `[[` value cannot be correct
# under any of them.
# 🔴 No regex metacharacter for `[` appears anywhere below — the bracket test is substr/==, not a
# pattern. one-true-awk (macOS /usr/bin/awk) is the constraint this file has already been bitten by
# twice (see the resolve() and spelled-out-digit comments), and a literal comparison cannot be the
# next bite. `file` is the caller's -v variable, set by both scans.
# 🔴 The local names are prefixed `fm*` on purpose. awk has no block scope: a function local is
# spelled as an extra parameter, and the docs program this is concatenated into already owns
# globals named `k` and `val`. Plain `k`/`v` locals here would shadow them — harmless only for as
# long as this call stays ahead of their assignment, which is not a property worth depending on.
AWK_BAREWIKI='
  function barewiki(fmline, nr,   fmkey, fmval) {
    if (match(fmline, /^[ \t]*-[ \t]+/)) {
      if (substr(fmline, RLENGTH + 1, 2) == "[[")
        print file ":" nr ": unquoted wikilink in a frontmatter list item (YAML reads it as a nested sequence, not a link — quote it: - \"[[stem]]\")"
      return
    }
    if (!match(fmline, /^[A-Za-z_][A-Za-z0-9_]*:[ \t]*/)) return
    fmval = substr(fmline, RLENGTH + 1)
    if (substr(fmval, 1, 2) != "[[") return
    fmkey = substr(fmline, 1, index(fmline, ":") - 1)
    print file ":" nr ": unquoted wikilink in frontmatter value \"" fmkey "\" (YAML reads it as a nested sequence, not a link — quote each link on its own line: - \"[[stem]]\")"
  }
'

# 🔴 The frontmatter PARSE check (KJP-97) — the case the ponytail note in the docs scan below was
# explicitly waiting for, and the reason that note is updated rather than replaced.
#
# What it is for: `barewiki` above closed ONE spelling of "this block does not parse". After the
# KJP-96 sweep fixed 354 wikilinks, 11 blocks still failed to parse — all of them for reasons that
# have nothing to do with wikilinks. Measured with PyYAML on the real vault 2026-08-12, over the
# 660 frontmatter blocks, by cause:
#   colon+space in an unquoted scalar   6  `summary: …취급하지 않는다: 시크릿…`
#   value opens with a backtick         3  `summary: ``df`` 만 보고…`
#   value opens an unclosed `[`         2  `summary: [결정] sns 게시 문안 …`
# 🔴 Why this is worth its own rule rather than more `related` policing: for those 11 notes
# `summary`, `updated` and `related` do not exist for ANY reader. A block that does not parse is
# rendered by Obsidian as body text in its entirety, so fixing the `related` spelling alone leaves
# the note exactly as invisible as before. Canon: docs/knowledge-convention.md §frontmatter must
# parse — this enforces that section, and §related is one instance of it.
#
# 🔴 Why this is still not a YAML parser — three tests, no state, no lookahead. Each fires only on
# a shape that CANNOT be legal, so the vault decides nothing by luck:
#   1. the value opens with an indicator that may never open a plain scalar (`@%,]}* and a backtick)
#   2. the value opens a flow collection that does not close on the same line
#   3. the value is an unquoted plain scalar carrying `: ` or ending in `:` — YAML reads the second
#      colon as a nested mapping, which is the "mapping values are not allowed here" error
#
# 🔴 The exclusions are measured, not assumed, and are what keep this from false-positiving:
#   · `[` and `{` are NOT flagged on sight. 155 vault values open with `[` and 153 of them are
#     legal flow sequences (`aliases: [a, b]`, `related: []`); only the 2 unclosed ones are the
#     defect. The closing test is the whole discriminator, and dropping it flags 153 healthy files.
#   · A value inside a closed flow collection is left alone even when it carries `: ` — 6 vault
#     files spell `aliases: ["tools: Read 만 보고…", …]`, which parses fine.
#   · `& ! | >` are NOT flagged: anchors, tags and block scalars are legal YAML and PyYAML accepts
#     all four (measured — `summary: |` + an indented `a: b` line parses). A checker that reports
#     legal YAML is the false-positive rate that gets a gate ignored. Zero instances in the vault.
#   · `#` at value position is not flagged either: it parses, to a null value. Silent data loss is
#     a real defect but a DIFFERENT axis (the wiki scan's `summary:` rule already speaks for the
#     one key where it matters), and this rule answers exactly one question — does the block parse.
#   · Only top-level `key:` lines are examined. Indented lines are a block scalar's content or a
#     nested map's body, where every shape above is legal text; skipping them is what makes the
#     block-scalar case correct for free rather than by a second rule.
# ponytail: a legal YAML alias (`summary: *anchor`, requiring an `&anchor` earlier in the same
# block) would false-positive under test 1. Measured 0 anchors and 0 aliases across all 660 blocks,
# and `*` is kept in the set because `summary: *강조* …` — markdown emphasis — is the realistic
# way it appears. Revisit if a real anchor ever lands in frontmatter.
# 🔴 No regex metacharacter for `[`, `]`, `{` or `}` appears below: every test is index()/substr()
# on literal strings, the same discipline barewiki states above, because one-true-awk (macOS
# /usr/bin/awk) is what this file has already been bitten by twice.
# 🔴 Locals are `fm*`-prefixed for the reason barewiki gives: awk has no block scope, and the docs
# program this is concatenated into owns globals named `k`, `v`, `s` and `val`. `fmnr` in
# particular must not be spelled `nr` — the SESSION program owns a global by that name.
AWK_FMPARSE='
  function fmparse(fmline, fmnr,   fmv, fmc, fmz, fmq, fmkey) {
    if (!match(fmline, /^[A-Za-z_][A-Za-z0-9_]*:[ \t]*/)) return
    fmv = substr(fmline, RLENGTH + 1)
    sub(/[ \t]+$/, "", fmv)
    if (fmv == "") return
    fmkey = substr(fmline, 1, index(fmline, ":") - 1)
    fmq = sprintf("%c", 39)
    fmc = substr(fmv, 1, 1)
    fmz = substr(fmv, length(fmv), 1)
    # A quoted scalar is the canonical way to carry any shape below — always legal, always silent.
    if (length(fmv) > 1 && (fmc == "\"" || fmc == fmq) && fmz == fmc) return
    if (index("`@%,]}*", fmc) > 0) {
      print file ":" fmnr ": frontmatter value \"" fmkey "\" opens with the YAML indicator " fmc " (a plain scalar may not start with it, so the whole block fails to parse and every key in it — summary, updated, related — ceases to exist for any reader while Obsidian renders the block as body text; quote the value)"
      return
    }
    if (fmc == "[" && fmz != "]") {
      print file ":" fmnr ": unclosed flow sequence in frontmatter value \"" fmkey "\" ([ opens a YAML sequence that must close on the same line; as written the whole block fails to parse and every key in it is invisible to any reader — quote the value if the bracket is prose)"
      return
    }
    if (fmc == "{" && fmz != "}") {
      print file ":" fmnr ": unclosed flow mapping in frontmatter value \"" fmkey "\" ({ opens a YAML mapping that must close on the same line; as written the whole block fails to parse and every key in it is invisible to any reader — quote the value if the brace is prose)"
      return
    }
    # Closed flow collections and the legal indicators fall out here, before the colon test: the
    # text inside them is already quoted or already structured, and `aliases: ["a: b"]` is correct.
    if (index("[{&!|>#", fmc) > 0) return
    if (index(fmv, ": ") > 0 || fmz == ":")
      print file ":" fmnr ": unquoted frontmatter value \"" fmkey "\" contains a colon+space (YAML reads the second colon as a nested mapping, so the whole block fails to parse and every key in it is invisible to any reader while Obsidian renders the block as body text; quote the value)"
  }
'

# ---------------------------------------------------------------- session notes
# Excluded alongside index.md because none is a session: index.md/_index.md are the folder TOC
# (one rule, two spellings — same pair every scan excludes), and sample-session.md is the schema
# placeholder — its uid/status are literal `<active|parked|done>` specimens, so validating it
# would flag the spec itself forever and make --strict unusable.
# ponytail: if this exclusion list grows past the TOC pair + the placeholder, that is the signal
# to promote it to a convention (a `meta:` flag or a naming rule) instead of extending the chain.
find "$VAULT/hippocampus" -maxdepth 1 -type f -name '*.md' \
  ! -name 'index.md' ! -name '_index.md' ! -name 'sample-session.md' 2>/dev/null | sort > "$LIST"
n_sessions="$(wc -l < "$LIST" | tr -d ' ')"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" "$AWK_PRELUDE$AWK_FMPARSE"'
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { fm = 0; fmend = 1; next }
    # 🔴 The parse check reaches this layer too (KJP-97). Not because the session TOOLING breaks —
    # measured, it does not: `sl`/`sr` read `status:` with grep, never a YAML parser
    # (skills/_session-shared/active-sessions.md), so a session whose block fails to parse still
    # lists and still resumes. It is here because the defect is YAML syntax, which is
    # layer-independent by construction, and because Obsidian renders an unparseable block as body
    # text on every layer alike. Scoping a syntax rule to the layer where it happened to be found
    # is exactly what produced KJP-97: KJP-56 wrote the rule to `related` instead of to scalars,
    # and 11 blocks on another key survived the sweep. Measured cost today: 0 findings here.
    fm { fmparse($0, NR) }
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

      # 0.2.0 raw-layer schema: 5 keys, none of them identity or authorship. `uid` retired
      # (the filename carries identity), `writer` retired (git carries authorship), `created`
      # retired (the first Progress entry dates the session).
      n = split("status project updated related_ticket cc_session_ids", req, " ")
      for (i = 1; i <= n; i++)
        if (!(req[i] in seen)) print file ":1: missing frontmatter key: " req[i]

      # Retired 0.1.x keys. Same shape as the `cancel` message below: "missing key" cannot say
      # anything about a key that is *present and no longer meant to be*, and a vault that never
      # dropped them would otherwise pass in silence. Each message carries its own migration
      # instruction, because "retired" alone would not say where the information went.
      # The `session_type: dreaming` branch died here with `uid`: dreaming no longer writes a
      # session at all — its log is a single accumulating file on the wiki layer.
      nr = split("uid created writer", ret, " ")
      for (i = 1; i <= nr; i++) {
        if (!(ret[i] in seen)) continue
        if (ret[i] == "uid")
          print file ":" ln["uid"] ": retired key \"uid\" (the filename is the identity now — delete the key)"
        else if (ret[i] == "created")
          print file ":" ln["created"] ": retired key \"created\" (the first Progress entry dates the session — delete the key)"
        else
          print file ":" ln["writer"] ": retired key \"writer\" (git carries authorship — delete the key)"
      }

      if ("status" in seen) {
        s = val["status"]
        if (s != "active" && s != "parked" && s != "done") {
          if (s ~ /^(created|draft|approved|deprecated|stale)$/)
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

# ------------------------------------------------------------------- wiki notes
# Collect the scan roots as directories, then hand them to find as start paths.
# Indexed arrays are bash 3.2-safe (only *associative* arrays are 4.0+).
KDIRS=()
while IFS= read -r d; do
  [ -d "$d/p_memory" ] && KDIRS[${#KDIRS[@]}]="$d/p_memory"
done < <(brain_projects)
# Vault-wide knowledge. Root-fixed like the session layer, so no manifest key resolves it
# (vault-paths.sh manifests only the axes that move between vaults) — a restructured vault
# moves its common and projects roots and still keeps `neocortex/` here. It is the wiki layer's
# second half: `p_memory` is what one project knows, `neocortex` is what the vault knows.
[ -d "$VAULT/neocortex" ] && KDIRS[${#KDIRS[@]}]="$VAULT/neocortex"
# The tools root (`999_tools/` by default) = machine-global tool inventory (vault-tree.md
# §The tools root). It is a scan root here because it carries wiki-layer notes that must hold the
# wiki schema — NOT because recall reads it. 🔴 Measured 2026-08-05 (KJP-65): recall 0.2.0 scans
# exactly three places (skills/_session-shared/recall.md — PROJDIR, BRAIN_COMMON, neocortex/_index.md);
# the tools root is not among them. The older "recall scans it, so this is the mirror" claim was false.
# Scan reason and recall reason are different questions, and this root answers only the first.
# It does not arrive via brain_projects: that helper excludes the reserved 9xx band
# outright, and a 9xx folder has no p_memory/ subfolder
# anyway (measured). The root resolves through vault-paths (`tools_root` key / BRAIN_TOOLS_REL);
# empty = the folder is absent, a legal state (machine-global, git-untracked), skipped silently —
# unlike the common root, whose absence is loud.
[ -n "$BRAIN_TOOLS" ] && KDIRS[${#KDIRS[@]}]="$BRAIN_TOOLS"

: > "$LIST"
# An empty array expanded under `set -u` is an unbound-variable error in bash 3.2 — guard it.
if [ ${#KDIRS[@]} -gt 0 ]; then
  # Project p_memory/ stays -maxdepth 1: its subfolders are deliberately out of scope.
  # `dream-logs.md` is dreaming's run log, not a note — it lives in neocortex/ by canon and its
  # frontmatter is one key (`updated`), so scanning it would report a phantom missing summary on
  # every real vault. Excluded by name here, the same way the folder TOCs and reject logs are.
  find "${KDIRS[@]}" -maxdepth 1 -type f -name '*.md' \
    ! -name 'index.md' ! -name '_index.md' ! -name '0.*' ! -name 'dream-logs.md' 2>/dev/null >> "$LIST"
fi
# The common layer recurses instead. Its sub-axes are not the same shape in every vault — flat
# `{facts,patterns,policies}/` in one, `patterns/` plus `_company/<folder>/` in another — so
# enumerating them here would put the tree back into this file. brain_find_notes owns the
# exclusions (meta files, _templates/, archives, dreaming logs).
if [ -n "$BRAIN_COMMON" ]; then
  brain_find_notes "$BRAIN_COMMON" >> "$LIST"
fi
sort -o "$LIST" "$LIST"
n_wiki="$(wc -l < "$LIST" | tr -d ' ')"
# Kept for the coverage check further down, which asks the inverse question about exactly these
# files — copied out rather than re-derived, so the two scans cannot drift into different scopes.
# 🔴 LC_ALL=C, not style: this list is one side of a *set* comparison, and in a collation locale
# that gives a string no primary weight macOS sort treats such strings as EQUAL — `가.md 나.md
# 다.md 라.md` deduplicates to ONE line (the KJP-74 hazard; the same reason the target-set sort
# below pins the locale). Which locale decides it, measured 2026-08-05: `en_US.UTF-8` collapses
# the four to 1, `ko_KR.UTF-8` keeps 4, `C` keeps 4 — so the bite depends on the caller
# environment, and "it passed on my machine" is not evidence either way. There is no `-u` here so
# nothing collapses today; pinning the locale makes the comparison independent of that environment
# and forecloses the reintroduction.
LC_ALL=C sort "$LIST" > "$NOTES"

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" "$AWK_BAREWIKI$AWK_FMPARSE"'
    BEGIN {
      # 🔴 The migration safety net. These ten are the 0.1.x wiki vocabulary; a 0.2.0 note carries
      # four (summary · updated · related · aliases, plus `projects` on neocortex). Sweeping the
      # keys out of hundreds of notes is a bulk edit, and the only thing that catches the files
      # the sweep missed is this check — a missing key is loud, a *stale* key is silent.
      # `title` is a rename (its replacement is `summary`), the other nine are retired outright,
      # so the two carry different instructions.
      # 🔴 Holding the retired strings in code is what makes the check work. A sweep that tries to
      # reach "zero retired terms in scripts/" deletes the detector along with the term.
      n = split("uid title type tags dri species source_sessions source_items recalled useful", ret, " ")
    }
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }   # awk runs END after exit, so the checks below still report
    # `summary:` inherits the seat `title:` held. It is not a rename of a label but of a role:
    # recall injects `_index.md` only, and every line there is `- [[stem]] — <summary>`, so a
    # note without one is invisible to every future session rather than merely untitled.
    fm && /^summary:[ \t]*[^ \t]/ { ok = 1 }
    # Reported as the line is read, not from END: the rule is about the spelling of one line, so
    # the finding has to carry that same line number. No apostrophe may appear in this comment —
    # the awk program is a single-quoted shell string and one would end it (measured, KJP-56).
    fm { barewiki($0, NR) }
    # The 11 blocks the wikilink sweep could not reach — all of them on this layer, all of them on
    # `summary:` (KJP-97). Reported per line for the same reason barewiki is: the rule is about the
    # spelling of one line, so the finding must carry that line number.
    fm { fmparse($0, NR) }
    fm && match($0, /^[A-Za-z_][A-Za-z0-9_]*:/) { at[substr($0, 1, RLENGTH - 1)] = NR }
    END {
      if (!ok) print file ":1: missing frontmatter key: summary"
      for (i = 1; i <= n; i++) {
        if (!(ret[i] in at)) continue
        if (ret[i] == "title")
          print file ":" at["title"] ": retired key \"title\" (renamed — the one-line summary: is its replacement)"
        else
          print file ":" at[ret[i]] ": retired key \"" ret[i] "\" (0.2.0 wiki frontmatter = summary|updated|related|aliases — delete the key)"
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

# -------------------------------------------- p_memory filenames (`<pp>_<slug>.md`)
# 🔴 The rule entered canon 2026-08-05 (KJP-63) and had no detector, so every note written after
# it broke it and nothing anywhere said so. Measured 2026-08-12: **0 of 480** p_memory notes carry
# the prefix, and 146 are whole sentences. A rule that cannot be failed is a rule nobody keeps —
# which is why this scan lands with the canon rather than after it.
#
# Why a filename is this layer's business and not a style opinion: the stem IS the identity key
# here, and the namespace it must be unique in is the whole vault. Measured the same day, p_memory
# is addressed almost entirely by BARE stem (`_index.md`: 493 bare / 0 path-qualified; note
# `related:`: 1352 / 38) while `docs/` is addressed by path (1 / 80) — which is exactly why
# `ARCHITECTURE.md` may sit in 11 projects at once and a p_memory stem may not. recall injects
# several projects' `_index.md` into one context, and promotion ② lifts the note into `neocortex/`
# beside every other project's. Canon: docs/knowledge-convention.md §Filename.
#
# Scope is `p_memory/` alone. `neocortex/` holds the same slug rule under a `NEO-` prefix, and the
# common and tools roots hold neither — one scan per naming authority, so a finding here always
# names the same fix. The other roots are left to the card that measures them.
n_pmem=0
while IFS= read -r pdir; do
  pmem="$pdir/p_memory"
  [ -d "$pmem" ] || continue
  # 🔴 The exclusions are copied from the wiki scan above on purpose, not chosen again. The two
  # scans must see one set of files, so that every note asked for a `summary:` is also asked for
  # its name; a private list here is how the two scopes drift apart in silence. `$LIST` is the
  # shared scratch buffer — the index scan below re-initializes it, as every scan in this file does.
  : > "$LIST"
  find "$pmem" -maxdepth 1 -type f -name '*.md' \
    ! -name 'index.md' ! -name '_index.md' ! -name '0.*' ! -name 'dream-logs.md' 2>/dev/null >> "$LIST"
  # No notes = nothing to name. A project folder with an empty or absent p_memory needs no PREFIX
  # for *this* rule, and reporting one would moralize about a folder the scan never read.
  [ -s "$LIST" ] || continue
  hub="$pdir/_index.md"
  if [ ! -f "$hub" ] && [ -f "$pdir/index.md" ]; then hub="$pdir/index.md"; fi
  # The hub's `PREFIX:` line is the sole source, because it is already the only one a writer is
  # sent to (skills/ss/SKILL.md §PREFIX). First whitespace-delimited token, so a trailing comment
  # cannot become part of the prefix. Anchored at line start: a real hub declares `PREFIX: KJP` in
  # column 1, and hub prose that merely mentions the word is not a declaration.
  pfx=""
  if [ -f "$hub" ]; then
    pfx="$(grep -E '^[[:space:]]*PREFIX:' "$hub" 2>/dev/null | head -1 \
           | sed 's/^[[:space:]]*PREFIX:[[:space:]]*//' | tr -d '\r' | sed 's/[[:space:]].*$//')"
  fi
  # 🔴 One finding at the hub, not N at the notes. Without a PREFIX there is no authority to name
  # anything, so the linter cannot say what any of these files *should* be called — and the fix is
  # one line in one file. Reporting each note instead would bury that fix under its own symptoms
  # and put a number on the report that shrinks only when the hub is repaired anyway.
  if [ -z "$pfx" ]; then
    echo "$hub:1: project hub declares no PREFIX: line (it is the only source for the \`<pp>\` in p_memory/<pp>_<slug>.md and for session filenames, so $(wc -l < "$LIST" | tr -d ' ') note name(s) here cannot be checked or issued — knowledge-convention.md §Filename)" >> "$OUT"
    continue
  fi
  n_pmem=$((n_pmem + $(wc -l < "$LIST" | tr -d ' ')))
  # 🔴 The prefix is compared with substr/==, never spliced into a regex. It is vault data, so a
  # hub carrying `PREFIX: A.B` would otherwise build a pattern that matches names it should not —
  # the same class of bite as the `/`-in-a-bracket-class one this file already carries twice. Only
  # the slug pattern is a regex, and it is a literal owned by this script.
  # LC_ALL=C: measured 2026-08-12 this changes nothing — `[a-z0-9]` never matched Hangul under
  # en_US.UTF-8, ko_KR.UTF-8 or C, and one-true-awk counts bytes in all three. Pinned anyway
  # because a range is a *collation* construct and a locale-aware awk would widen it silently,
  # which is precisely how the KJP-74 sort hazard arrived.
  # 🔴 One finding per file, but it names BOTH halves when both are wrong. The two defects are
  # repaired by one rename, so splitting them into two lines would double the report without
  # adding an action — and reporting only the first would be worse: 480 of 480 notes are missing
  # the prefix, so a first-defect-wins message would have said nothing about the 146 sentence-shaped
  # slugs until a second pass, and a migrator following it literally would produce
  # `KJP_<the whole sentence>.md` and still be wrong. When the prefix is absent the whole stem is
  # the candidate slug, which is what makes the two tests independent rather than sequential.
  LC_ALL=C awk -v pfx="$pfx" '
    { path = $0
      base = path; sub(/^.*\//, "", base)
      stem = base; sub(/[.]md$/, "", stem)
      if (substr(stem, 1, length(pfx)) == pfx && substr(stem, length(pfx) + 1, 1) == "_") {
        pre = 1; rest = substr(stem, length(pfx) + 2)
      } else {
        pre = 0; rest = stem
      }
      keb = (rest ~ /^[a-z0-9]+(-[a-z0-9]+)*$/)
      if (pre && keb) next
      if (!pre && !keb) what = "carries no project prefix, and its slug is not lowercase kebab"
      else if (!pre)    what = "carries no project prefix"
      else              what = "slug is not lowercase kebab: \"" rest "\""
      print path ":1: p_memory filename " what " (expected \"" pfx "_<slug>.md\", <slug> = [a-z0-9] words joined by single hyphens — the stem is the identity key on this layer, is linked by bare stem across projects, and a sentence there is a stale copy of summary:; knowledge-convention.md §Filename)"
    }
  ' "$LIST" >> "$OUT"
done < <(brain_projects)

# ----------------------------------------------------- folder indexes (`_index.md`)
# 🔴 The failure mode this whole layer is built on, and the only one no other check can reach.
# recall injects the folder indexes and nothing else (`skills/_session-shared/recall.md`), so an
# index line naming a file that is not there is not a broken link — it is a **false inventory**.
# Every later session reads the list, believes the note exists, and nothing contradicts it. The
# inverse is loud: a note with no summary is reported by the scan above. This one is silent.
# Line form canon: knowledge-convention.md §summary — `- [[<filename stem>]] — <summary>`.
#
# 🔴 Two scopes, because the two rules answer to different canons (KJP-82):
#   · DANGLING — every index recall injects. That is the whole of `$PROJDIR` plus the common layer
#     and neocortex: `recall.md:13` walks a project folder with an unfiltered
#     `find "$PROJDIR" -name '_index.md'`, so the docs TOCs and the project hub are injected text
#     exactly like `p_memory/_index.md`. Measured on the real vault 2026-08-11: 106 indexes
#     injected by that command, 13 of them linted before this card. A false inventory in the other
#     93 was unreachable by every check in this file.
#   · LINE FORM — the wiki layer only. `- [[stem]] — <summary>` is the *memory-note* canon
#     (knowledge-convention.md §summary), and no canon states it for docs: doc-catalog.md asks a
#     hub for "TOC pointers" and nothing more. A docs TOC legitimately opens with frontmatter and
#     prose, carries `next_id:`, names non-note files, and writes a hyphen — measured 2026-08-11,
#     85 of the real vault's docs index lines would be reported under the wiki form. Enforcing an
#     unwritten rule at that false-positive rate is how a gate gets ignored, which is precisely
#     what the pre-KJP-82 blanket exclusion was protecting. That protection is kept; only the
#     dangling half moved.
# `hippocampus/` stays outside BOTH — the raw layer is never a recall target (vault-tree.md
# §Layers). Every boundary here is pinned by a dangling-link fixture in the self-test, so a scope
# that shrinks kills an assert instead of passing in silence.
# Both spellings are indexes (`_index.md` canonical, `index.md` its legacy equal), the same pair
# every other scan excludes as meta.
#
# 🔴 Detection only, and it presumes no regenerator. An `_index.md` is updated by whoever creates
# or moves the file, in the same commit (knowledge-convention.md); after-the-fact regeneration was
# retired with the dreaming feature set (KJP-77). This check never rewrites an index and no
# message here may imply that something else will.
: > "$LIST"
if [ ${#KDIRS[@]} -gt 0 ]; then
  find "${KDIRS[@]}" -maxdepth 1 -type f \( -name '_index.md' -o -name 'index.md' \) 2>/dev/null >> "$LIST"
fi
if [ -n "$BRAIN_COMMON" ]; then
  # Recursive on the common layer, like the note scan, and carrying the same structural
  # exclusions brain_find_notes owns: an index inside a template folder or an archive is the
  # same class of non-content as a note there.
  find "$BRAIN_COMMON" -type f \( -name '_index.md' -o -name 'index.md' \) \
    ! -path '*/_templates/*' ! -path '*/999_Archive/*' ! -path '*/Archive/*' \
    ! -path '*/_dreaming_logs/*' 2>/dev/null >> "$LIST"
fi
sort -o "$LIST" "$LIST"
n_index="$(wc -l < "$LIST" | tr -d ' ')"

# The docs-layer list: every index under a project folder that the wiki scan does not already own.
# The rule is derived from recall's own walk rather than from a folder-name list, so a new sibling
# of `docs/` is in scope the day it appears instead of the day someone remembers to edit this line.
# `p_memory/` is excluded whole: the wiki scan owns that layer, and its `-maxdepth 1` is a scope
# decision (subfolders deliberately out) that reaching in from here would silently reopen.
# The structural exclusions match the common layer's — an index inside a template folder or an
# archive is the same class of non-content there as here.
: > "$DOCIDX"
while IFS= read -r d; do
  find "$d" -type f \( -name '_index.md' -o -name 'index.md' \) \
    ! -path '*/p_memory/*' ! -path '*/_templates/*' ! -path '*/999_Archive/*' \
    ! -path '*/Archive/*' ! -path '*/_dreaming_logs/*' 2>/dev/null >> "$DOCIDX"
done < <(brain_projects)
sort -o "$DOCIDX" "$DOCIDX"
n_dindex="$(wc -l < "$DOCIDX" | tr -d ' ')"

: > "$TARGETS"
if [ "$n_index" -gt 0 ] || [ "$n_dindex" -gt 0 ]; then
  # Every target the vault can resolve, in the two spellings a wikilink may use: the vault-relative
  # path (`[[org/machines/clients/x/HARDWARE_SPEC]]`) and the bare filename stem (`[[NEO-foo]]`).
  # Built once for the whole run — one tree walk instead of a stat per link.
  # 🔴 `aliases:` is deliberately NOT harvested. A renamed note keeps its old basename there so
  # existing links still open, but knowledge-convention.md requires the folder index to be updated
  # in the *same commit* as the move — so an index line still naming the pre-rename stem is a
  # finding by canon even though Obsidian would happily follow it. Resolving through aliases here
  # would forgive exactly the drift this check exists to catch.
  # ponytail: a partial path (`[[p_memory/good]]`) that is neither the full vault-relative path nor
  # the bare stem is reported as dangling, though Obsidian would resolve it when unique. No
  # instance exists in either measured vault; add suffix matching when one does.
  find "$VAULT" -type f -name '*.md' ! -path '*/.git/*' 2>/dev/null | while IFS= read -r p; do
    # Quoted pattern = literal: an unquoted "$VAULT" here would be read as a glob, and a vault
    # path containing `[` would strip the wrong prefix (the same class of silent collapse the
    # start-path discipline above avoids).
    rel="${p#"$VAULT"}"; rel="${rel#/}"
    base="${p##*/}"
    printf '%s\n%s\n' "${rel%.md}" "${base%.md}"
  # 🔴 LC_ALL=C is load-bearing, not style. Under *some* UTF-8 collation locales macOS `sort -u`
  # treats strings with no primary collation weight as EQUAL and drops all but one. It is
  # locale-specific, not "UTF-8 vs C" — measured 2026-08-05 (KJP-74/82) on the same input
  # `가.md 나.md 다.md 라.md`: **en_US.UTF-8 → 1 line** · ko_KR.UTF-8 → 4 · C → 4. So the hazard
  # depends on the ambient LANG, which is exactly why it cannot be left to the environment. The
  # real vault's 74-file p_memory collapsed to 73 targets, reporting a live note as a dangling
  # `_index` link. The failure is silent, it only bites on non-ASCII names, and it makes a
  # must-be-zero gate unpassable. Byte ordering is what a target *set* needs anyway — this is
  # set membership, not human-facing sort order.
  done | LC_ALL=C sort -u > "$TARGETS"
fi

# `./` and `../` inside a wikilink are addressing relative to the index's own folder. Obsidian
# follows them, so a link that uses them names a real file and must not read as dangling — a false
# dangle is the one failure that gets a gate ignored. Every other spelling is returned untouched:
# a bare stem matches on basename, a rooted path on its vault-relative form, and both are already
# in the target set. Held as a prelude string, like AWK_PRELUDE above, so the scan body below stays
# readable in one piece.
# 🔴 The pattern is a string, not a /literal/: one-true-awk (macOS /usr/bin/awk) cannot parse a `/`
# inside a bracket class, and `[.]` sidesteps the escaping question outright. Same discipline as
# the spelled-out digit runs elsewhere in this file — the portable spelling is the one that fails
# loudly on the wrong awk instead of silently never matching.
AWK_RESOLVE='
  function resolve(t, dir,   parts, n, i, out, m, r) {
    if (t !~ "(^|/)[.][.]?(/|$)") return t
    n = split(dir "/" t, parts, "/")
    for (i = 1; i <= n; i++) {
      if (parts[i] == "" || parts[i] == ".") continue
      if (parts[i] == "..") { if (m > 0) m--; continue }
      out[++m] = parts[i]
    }
    for (i = 1; i <= m; i++) r = (i == 1) ? out[i] : r "/" out[i]
    return r
  }
'

# One index list, checked for links that name a file that is not there — and, when the second
# argument is 1, for the wiki layer's canonical line form as well. Two lists share this body so the
# dangling rule cannot drift into two versions of itself; the scope note above is why only one of
# them carries the form rule.
# `dir` is the index's own vault-relative folder, the base that `../` addressing resolves against.
scan_index_list() {   # scan_index_list <list-file> <check-line-form 0|1>
  while IFS= read -r f; do
    [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
    rel="${f#"$VAULT"}"; rel="${rel#/}"
    case "$rel" in */*) dir="${rel%/*}" ;; *) dir="" ;; esac
    awk -v file="$f" -v targets="$TARGETS" -v form="$2" -v dir="$dir" "$AWK_RESOLVE"'
      BEGIN { while ((getline t < targets) > 0) T[t] = 1; close(targets) }
      { sub(/\r$/, "") }
      # A TOC entry is a list line, and only a list line. Headings, the intro sentence that says what
      # the folder is, and blank lines carry no obligation — an index is allowed to introduce itself.
      # Any bullet, though, is claiming to be an entry, so `*` and `+` bullets are entries too and
      # fail the form: recall reads the whole file, and a half-formed line costs a note its summary.
      /^[ \t]*[-*+][ \t]/ {
        if (form && !match($0, /^- \[\[[^]]+\]\] — [^ ]/))
          print file ":" NR ": malformed _index line (canon: - [[<stem>]] — <summary>): " $0
        s = $0
        while (match(s, /\[\[[^]]+\]\]/)) {
          t = substr(s, RSTART + 2, RLENGTH - 4)
          s = substr(s, RSTART + RLENGTH)
          # `|alias` and `#heading` are addressing, not identity — strip both before resolving.
          p = index(t, "|"); if (p > 0) t = substr(t, 1, p - 1)
          p = index(t, "#"); if (p > 0) t = substr(t, 1, p - 1)
          sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
          if (t == "") continue
          # The raw link text is what the message quotes — that is the string a human has to find
          # and fix in the file, not its resolved form.
          if (!(resolve(t, dir) in T))
            print file ":" NR ": dangling _index link: [[" t "]] (recall injects the folder indexes and nothing else — a line naming a file that is not there is a false inventory no other check can see)"
        }
      }
    ' "$f"
  done < "$1"
}

scan_index_list "$LIST"   1 >> "$OUT"
scan_index_list "$DOCIDX" 0 >> "$OUT"

# ------------------------------------------ index coverage (the scan above, read backwards)
# 🔴 The same relation — index line ↔ note file — and the other direction of failure:
#   · dangling  — an index names a file that is not there. recall believes in a note that does
#                 not exist. Caught above.
#   · uncovered — a note exists and no index names it. recall never learns it is there at all.
# Both make recall lie, and the second is the quieter one by construction: the file is intact,
# its frontmatter is complete, and every other check in this script passes it. Nothing anywhere
# contradicts a note that is simply never mentioned. That is why it needs its own scan and why
# "no findings" from the dangling check alone was never evidence of a sound index.
# KJP-74 regenerated all 19 indexes of the real vault with an LLM worker against exactly one gate,
# the dangling check; this closes the half that migration was never measured against.
#
# Scope is not restated here — it *is* the two lists already built: the wiki note list ($NOTES)
# and the index list ($LIST) the dangling scan just consumed. Same roots, same exclusions
# (`_index.md` · `index.md` · `0.*` · `dream-logs.md`), because it is the same data, not a second
# copy of the rules. `hippocampus/` and `NNN_*/docs/` stay outside for the reasons above.
#
# 🔴 Detection only, and no regenerator is implied. An `_index.md` is updated by whoever creates
# or moves the file, in the same commit (knowledge-convention.md); after-the-fact regeneration was
# retired with the dreaming feature set (KJP-77). The message names the line to add and says who
# adds it, and must never suggest that something else will.
awk -v vault="$VAULT" -v idxlist="$LIST" -v notelist="$NOTES" -v countf="$NCOVER" '
  # Vault-relative key for an absolute path. substr + string equality, never a regex built out of
  # the vault path: that path may carry glob or regex metacharacters (`my[vault]`), and compiling
  # it into a pattern is the same silent-collapse class the start-path discipline above avoids.
  # A trailing slash on the argument leaves a leading `/` behind, so strip any run of them.
  function relkey(p,   r) {
    if (substr(p, 1, length(vault)) == vault) r = substr(p, length(vault) + 1)
    else r = p
    sub("^/+", "", r)
    return r
  }
  # Every wikilink on one index line, resolved and recorded as covered. `line` is a copy, so
  # consuming it here does not disturb the caller.
  function record(line, d,   t, p) {
    while (match(line, /\[\[[^]]+\]\]/)) {
      t = substr(line, RSTART + 2, RLENGTH - 4)
      line = substr(line, RSTART + RLENGTH)
      # `|alias` and `#heading` are addressing, not identity — stripped before resolving,
      # exactly as above.
      p = index(t, "|"); if (p > 0) t = substr(t, 1, p - 1)
      p = index(t, "#"); if (p > 0) t = substr(t, 1, p - 1)
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      if (t == "") continue
      # Two shapes, both measured in the real vault 2026-08-05 (483 bare stems, 8 paths): a bare
      # stem addresses the folder the index sits in, a slash makes it vault-relative. The second
      # is how a subtree index covers children that have no index of their own
      # (`org/machines/_index.md` names `org/machines/clients/*/…`), so coverage may not be judged
      # folder-locally — doing so would report those eight live notes as invisible.
      if (index(t, "/") > 0) covered[t] = 1
      else covered[d "/" t] = 1
    }
  }
  # One index file, harvested into the covered set. An unreadable one contributes nothing and its
  # folder then reads as uncovered; the loop above already reports the unreadable file itself, so
  # the cause is on record rather than left to be inferred from the coverage findings.
  function harvest(idx,   d, line) {
    d = relkey(idx); sub(DIRPART, "", d)
    while ((getline line < idx) > 0) {
      sub(/\r$/, "", line)
      # Only list lines, the same line class the dangling scan reads: canon says a TOC entry IS a
      # list line (knowledge-convention.md), so a stem named in the intro prose is not an entry and
      # buys the note nothing. Malformed entries still count as coverage — the line is already a
      # finding above, and reporting it twice would say the note is missing when the real defect
      # is its separator.
      if (line ~ /^[ \t]*[-*+][ \t]/) record(line, d)
    }
    close(idx)
  }
  BEGIN {
    # Dynamic regex strings, not /literals/: one-true-awk (macOS /usr/bin/awk) cannot parse a `/`
    # inside a bracket class in a regex literal — `/[^/]*$/` is a syntax error there. Same
    # discipline as the spelled-out digit runs in the scans above: the portable spelling is the
    # one that fails loudly on the wrong awk instead of silently never matching.
    DIRPART = "/[^/]*$"; BASEPART = "^.*/"
    while ((getline idx < idxlist) > 0) harvest(idx)
    close(idxlist)
    # Set membership on awk subscripts: byte-exact string keys, no collation, no dedup pass — the
    # KJP-74 hazard has no seat here, and the note list arrives byte-ordered for the same reason.
    for (k in covered) entries++
    printf "%d\n", (entries + 0) > countf
    close(countf)
    while ((getline f < notelist) > 0) {
      k = relkey(f); sub(/\.md$/, "", k)
      if (k in covered) continue
      stem = k; sub(BASEPART, "", stem)
      print f ":1: uncovered note: [[" stem "]] is named by no folder index (recall injects the folder indexes and nothing else — a note none of them names is invisible to every future session, the silent twin of a dangling link; add the line \"- [[" stem "]] — <summary>\" to the index that owns this folder)"
    }
    close(notelist)
  }
' >> "$OUT"
# The evidence base, carried out of awk as one integer. Reported below because it is the only
# number that separates "every note is indexed" from "the indexes were never parsed" — both of
# which produce zero findings here.
n_cover="$(tr -d ' \n' < "$NCOVER")"
[ -n "$n_cover" ] || n_cover=0

# ------------------------------------------- session wikilinks on the shared surface
# Canon: git-convention.md §Share scope. The shared surface is what a teammate pulls;
# `hippocampus/` sits outside it and is git-untracked outright in 0.2.0, so a `[[<uid>]]`
# written on the shared surface dangles in any vault that lacks that session. Shared notes
# cite a session as plain uid text — frontmatter and body alike.
#
# Scope = the shared surface itself: NNN_*/docs/**, NNN_*/p_memory/**, and the whole common
# layer (whichever folder `.brain-paths` names).
# 🔴 `hippocampus/` is deliberately NOT scanned — a session's own wikilinks are its record,
# and the file is never pulled by anyone else.
#
# Two deliberate divergences from the wiki summary scan above, both because the unit
# differs (that scan checks per-note schema and mirrors what *recall* reads; this one
# checks a tree a teammate *pulls*): it recurses (no -maxdepth), and it excludes no
# meta files — a dangling link in `index.md` or `0.rejected.md` breaks for a teammate
# exactly like one in a note. See knowledge note "validate 스코프는 recall 스코프의
# 미러가 원칙" — divergence by decision, recorded, not drift.
#
# 🔴 The tools root is NOT scanned here. Its axis is *share scope*, and the tools root is
# gitignored machine-local content, so it is outside the shared surface by definition: no teammate
# ever pulls it, so no link in it can dangle for one. It needs no exclusion either — it has neither
# docs/ nor p_memory/, so the sweep below never picks it up (measured).
#
# 🔴 `neocortex/` IS scanned here, as of KJP-65. It had been left out for a reason that was never a
# reason — step 6 of the 0.2.0 linter migration renamed this scan without extending it — and the
# axis decides the question outright: neocortex/ is git-tracked and pulled like any project folder,
# so a session wikilink there dangles for a teammate exactly as one in docs/ does. That leaves the
# tools root as the only root in the wiki-schema scan and outside this one, which is what keeps
# the split a decision rather than a habit: the two roots differ in git tracking and nothing else.
SDIRS=()
while IFS= read -r d; do
  # brain_projects already drops the common root (it matches NNN_ when it sits at the vault
  # root), so its docs/ and p_memory/ are not scanned twice — it is added whole below.
  [ -d "$d/docs" ] && SDIRS[${#SDIRS[@]}]="$d/docs"
  [ -d "$d/p_memory" ] && SDIRS[${#SDIRS[@]}]="$d/p_memory"
done < <(brain_projects)
[ -n "$BRAIN_COMMON" ] && SDIRS[${#SDIRS[@]}]="$BRAIN_COMMON"
[ -d "$VAULT/neocortex" ] && SDIRS[${#SDIRS[@]}]="$VAULT/neocortex"

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
      # <PREFIX>-YYYYMMDD-HHMMSS, PREFIX optional — the 0.1.x session-uid shape. 0.2.0 session
      # filenames are `<pp>_YYYYMMDD_<slug>`, so this pattern now catches legacy links during
      # migration rather than links a fresh vault could produce.
      UID = "([A-Z][A-Z0-9]*-)?" D8 "-" D6
      # Covers [[uid]] · [[hippocampus/uid]] (any path prefix) · [[uid|alias]] ·
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
# Canon: project-docs-convention.md §frontmatter Standard v2 + §history & session linkage
# + §ID Issuance; status vocabulary: doc-catalog.md; `updated:` format canon:
# sessions-note-convention.md. Findings vs warns — deliberately asymmetric:
#   FINDINGS (schema violations — --strict blocks on them):
#   · `session:` key anywhere in docs frontmatter. Upgraded from the old "no session
#     wikilink" rule: hippocampus/ is git-untracked, so even a *plain uid* is a
#     reference no teammate can resolve. Team provenance = history `ticket`; the
#     session uid rides the boundary commit message (git-convention.md).
#   · `status:` absent, or a value outside created|draft|approved|deprecated — the only
#     required key (meta files exempt; they are folder TOCs, not body documents).
#   · v1 history subkeys `date:`/`by:` — the top-level key regex cannot see inside a
#     `- { ... }` inline map or an indented block entry, which is exactly where the
#     v1 vocabulary hid. v2 entry = { at, change, ticket } only.
#   · `docs/adr/`: body files without `id:` (multi-instance, PM-issued, immutable); its
#     index/_index without `next_id:` (the issuance counter). ADR is the ONLY multi-instance
#     kind — `docs/policy/` was the other one until KJP-79 retired the folder model.
#     ⚠️ Presence only, and that is all this per-file scan can be: whether two files carry the
#     SAME id, or whether an issued number has lost its file, is a question about the folder
#     rather than about any one document in it. That half is the ADR ID audit below (KJP-83) —
#     same paths, different unit.
#   · `docs/develop/API_SPEC.md` without `source:` + `readonly: true` (mirror contract).
#   WARNS (stderr only, never a finding — --strict must not fail on them):
#   · unknown top-level keys (protects docs imported from outside; migration off the v1
#     schema is "no longer written", never a forced rewrite). Known set = the v2
#     vocabulary only; the kind ← path derivation matrix stays in project-docs-convention.
#   · `updated:` not YYYY-MM-DDTHH:MM:SS — date-only values are legacy-legal
#     (sessions-note-convention.md), absence is normal (only `status:` is required).
# Declared UNCOVERED here, by choice: value-axis duplication (a price outside BUSINESS §BM, a
# schema copied out of migrations/ — project-docs-convention §Value Axes). Judging "this
# token is a price" is semantics, not schema, so it stays out of this linter — but the
# price/tier *literal* half now has its own report-only detector, `value-axis-drift.sh`
# (KJP-58), which reads the §Value Axes table as its SSOT. Semantic duplication (a norm
# restated in prose) has **no automated owner**: it rests on the §Value Axes declaration itself
# plus PM mediation (project-docs-convention.md §Value Axes). 🔴 It is explicitly NOT dreaming's —
# that skill's operations are refine · link · promotion ②, it reads only `p_memory`/`neocortex`,
# and it never touches `docs/` at all (`skills/dreaming/SKILL.md`; ownership judged KJP-77). This
# line exists so the split reads as a decision, not an oversight — and so "dreaming does it" is
# not quietly reinvented by the next reader.
# Scope = NNN_*/docs/** recursive (the docs trees only — the wiki layer has its own scan and
# its dirs are not scanned here). index/_index are folder meta
# (`next_id`, TOC titles), so they skip the unknown-key warn and the body-document rules
# (status·id·mirror·updated) but not the session check. The decision that exemption was waiting
# for landed in KJP-79: there is no policy tier at all any more, at either level. A project rule
# is a `## POL-NNN` heading inside the `docs/develop/P_POLICY.md` singleton and a single-feature
# rule lives in that feature's own §Rules, so no policy path is multi-instance and none carries
# `id:`/`next_id:`. P_POLICY.md is matched by nothing special below — it is an ordinary body
# document, which is the whole point of collapsing the tiers.
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
  # Path-derived obligations — only the *paths* are matched here; the kind ← path matrix
  # itself stays in project-docs-convention (never replicated):
  #   docs/adr/                        body → `id:` required; index/_index → `next_id:` required
  #   docs/develop/API_SPEC.md         repo-spec mirror → `source:` + `readonly: true` required
  idreq=0; nidreq=0; mirror=0
  case "$f" in
    */docs/adr/*) if [ "$meta" -eq 1 ]; then nidreq=1; else idreq=1; fi ;;
    */docs/develop/API_SPEC.md) mirror=1 ;;
  esac
  awk -v file="$f" -v meta="$meta" -v idreq="$idreq" -v nidreq="$nidreq" -v mirror="$mirror" "$AWK_PRELUDE$AWK_BAREWIKI$AWK_FMPARSE"'
    BEGIN {
      # Spelled-out digit runs — one-true-awk has no ERE interval expressions (see the
      # wikilink scan above for why {n} would silently never match).
      D4 = "[0-9][0-9][0-9][0-9]"; D2 = "[0-9][0-9]"
      DATEONLY = "^" D4 "-" D2 "-" D2 "$"
      DATETIME = "^" D4 "-" D2 "-" D2 "T" D2 ":" D2 ":" D2 "$"
      # A quoted key is the same key (`"session":` dodged both the ban and the key
      # collector — verifier bypass 2026-07-29). Built as dynamic strings because a
      # literal single quote cannot appear inside this single-quoted awk program (the
      # same %c trick as unq() in the prelude). QC = one quote char, QK = an optional
      # one; extracted keys are stripped of quotes so `"status"` registers as status.
      QC = "[\"" sprintf("%c", 39) "]"; QK = QC "?"
      SESSKEY = "(^|[ \t{,])" QK "session" QK ":"
      TOPKEY  = "^" QK "[A-Za-z_][A-Za-z0-9_]*" QK ":"
      V1DATE  = "(^|[ \t{,])" QK "date" QK ":"
      V1BY    = "(^|[ \t{,])" QK "by" QK ":"
    }
    # v1 history vocabulary in one string — shared by the two call sites below: entry
    # lines, and the value of the `history:` line itself (flow style).
    # ponytail: value text containing ` date:`/` by:` inside an entry would false-
    # positive — hand-written one-liners, not worth a YAML parser until one appears.
    # 2026-08-12 (KJP-56), the revisit this line was waiting for, recorded here rather than
    # replacing it: a case DID appear at scale — 303 of the vault 660 frontmatter blocks do not
    # parse, 302 of them from a single unquoted-wikilink spelling — and it was still answered
    # WITHOUT a parser (see AWK_BAREWIKI: two substr tests, no bracket metacharacter). So the
    # judgment above stands, and now with a measurement behind it instead of a guess.
    # 🔴 What that costs, stated so the next reader does not have to rediscover it: the remaining
    # 1 file fails to parse for an unrelated reason (an unquoted `summary:` whose text contains
    # a colon-space, which YAML reads as a nested mapping). No check in this file sees it. THAT
    # is the case to weigh a real parser against — not the wikilink one, which is now covered.
    # 2026-08-12 (KJP-97), the case the line above named, weighed and answered — appended rather
    # than replacing either judgment, because a decision whose history is deleted gets re-argued
    # from scratch. The "1 file" estimate was low: re-measured after the KJP-96 sweep landed,
    # **11** blocks fail to parse for non-wikilink reasons (6 colon+space · 3 leading backtick ·
    # 2 unclosed `[`). It was still answered WITHOUT a parser — AWK_FMPARSE above is three
    # index()/substr() tests — and the answer was checked the only way that means anything: its
    # output was diffed against PyYAML over all 660 blocks and agreed on **file AND line, 11 = 11,
    # zero false positives and zero misses**, plus 32/32 on a synthetic set carrying the shapes the
    # vault does not have (block scalars, anchors, tags, nested maps, quoted colons).
    # 🔴 So the standing judgment is now twice-tested and still holds: no parser. What remains
    # genuinely uncovered is narrower than before and stated here so it is not rediscovered as a
    # surprise — duplicate keys (last-wins, above), a value that parses to null (`key: #text`), and
    # the ` date:`/` by:` false positive this very note is about. None is a parse failure; each is
    # a block that parses into something other than what its author meant, which is a different
    # axis from the one KJP-97 closed and would need a different rule, not a bigger one.
    function v1hist(s, nr) {
      if (s ~ V1DATE)
        print file ":" nr ": v1 history key \"date:\" (v2 history entry = { at, change, ticket })"
      if (s ~ V1BY)
        print file ":" nr ": v1 history key \"by:\" (v2 history entry = { at, change, ticket } — author lives in git)"
    }
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { exit }
    fm {
      # 🔴 Before the `next` below, so the session ban cannot shadow it, and NOT gated on `meta`:
      # a folder index whose frontmatter fails to parse loses its `next_id` the same way a body
      # document loses its `status`. This is the one docs-layer rule that is not about vocabulary,
      # which is why KJP-89 (unknown keys warn, never fail) does not reach it — see the note at
      # AWK_BAREWIKI and project-docs-convention.md §frontmatter Standard v2.
      barewiki($0, NR)
      # Same seat, same argument, one axis wider (KJP-97): a docs block that fails to parse loses
      # its `status:` — and a folder index its `next_id:` — exactly the way a wiki note loses its
      # `summary:`. Measured 2026-08-12: 0 docs-layer files carry it today, so this is a forward
      # guard here rather than a backlog; the 11 live cases are all on the wiki layer.
      fmparse($0, NR)
      # Matches the key in every YAML shape: top-level `session:`, nested-map
      # `    session:`, inline-map `{ ..., session: ... }`, and the quoted spelling of
      # each (`"session":` — verifier bypass 2026-07-29). The leading class keeps
      # `cc_session_ids:` (underscore before) and `sessions:` (no quote/colon right
      # after "session") out of the match.
      if ($0 ~ SESSKEY) {
        print file ":" NR ": session key in docs frontmatter (banned — team provenance = history ticket:, the session uid goes in the boundary commit message)"
        next
      }
      if (match($0, TOPKEY)) {
        k = substr($0, 1, RLENGTH - 1)
        gsub(QC, "", k)
        v = substr($0, RLENGTH + 1)
        sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
        seen[k] = 1; ln[k] = NR; val[k] = unq(v)
        inhist = (k == "history")
        # Flow style keeps the entries in the *value* of the history: line itself
        # (`history: [{ ... }]`) — the entry-line branch below never sees that line, so
        # the v1 check runs on the value here too (verifier bypass 2026-07-29).
        if (inhist && v != "")
          v1hist(v, NR)
        if (!meta && k !~ /^(status|updated|id|source|readonly|synced|history)$/)
          print file ":" NR ": unknown docs frontmatter key: " k " (warn only — never a finding)" > "/dev/stderr"
      } else if (inhist) {
        # history entry lines (inline map or indented block) — invisible to the top-level
        # key regex above, which is exactly the hole the v1 vocabulary slipped through.
        # v2 entry = { at, change, ticket } only; `session:` in the same position is
        # already a finding via the ban above, so only the other two v1 keys match here.
        v1hist($0, NR)
      }
    }
    END {
      if (meta) {
        # index/_index are folder meta, not body documents — no status/id/mirror duty.
        # In docs/adr/ they carry the ID counter instead (§ID Issuance).
        if (nidreq && !("next_id" in seen))
          print file ":1: missing next_id: in the adr folder index (the ID issuance counter — the PM reads and bumps it)"
        exit
      }
      if (!("status" in seen))
        print file ":1: missing frontmatter key: status (the only required key — created|draft|approved|deprecated)"
      else {
        s = val["status"]
        if (s !~ /^(created|draft|approved|deprecated)$/) {
          if (s ~ /^(active|parked|done)$/)
            print file ":" ln["status"] ": session status \"" s "\" used in a docs document (docs status = created|draft|approved|deprecated)"
          # `stub` was the docs "no information" status until 2026-08-02. Its own message carries
          # the migration instruction, since "invalid" alone would not say what to replace it with.
          else if (s == "stub")
            print file ":" ln["status"] ": retired status \"stub\" (docs status = created|draft|approved|deprecated; a pre-created empty document is created)"
          else
            print file ":" ln["status"] ": invalid docs status \"" s "\" (expected created|draft|approved|deprecated)"
        }
      }
      if (idreq && !("id" in seen))
        print file ":1: missing id: on a multi-instance document (docs/adr — the PM issues it; required & immutable)"
      if (mirror) {
        if (!("source" in seen))
          print file ":1: missing source: on the API_SPEC mirror (required SSOT pointer to the repo spec)"
        if (!("readonly" in seen) || val["readonly"] != "true")
          print file ":1: API_SPEC mirror without readonly: true (required constant — the mirror is view-only)"
      }
      if ("updated" in seen) {
        u = val["updated"]
        if (u !~ DATETIME) {
          if (u ~ DATEONLY)
            print file ":" ln["updated"] ": date-only updated: (legacy-legal, warn only — new writes use YYYY-MM-DDTHH:MM:SS)" > "/dev/stderr"
          else
            print file ":" ln["updated"] ": updated: is not YYYY-MM-DDTHH:MM:SS: " u " (warn only)" > "/dev/stderr"
        }
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

# ------------------------------------- ADR ID audit (duplicates · sequence gaps · next_id)
# 🔴 The half the presence check above cannot reach, and the reason it needed its own owner
# (KJP-83). `id:`/`next_id:` presence proves every ADR carries *a* number; it says nothing about
# whether two carry the SAME one, or whether a number the counter handed out has lost its file.
# Both failures are silent by construction — every file is well-formed, every required key is
# there, and the vault reports clean — and both break the thing an ID exists for:
#   · duplicate — `[[<PREFIX>-ADR-0000N]]` stops naming one decision. The link still resolves, to
#                 whichever file the reader opens first, so nothing ever errors.
#   · gap       — a number was issued and its record is gone. Links to it dangle, and because IDs
#                 are immutable the number cannot be reused to make the ledger whole again.
#   · counter   — `next_id` at or below the highest issued id, i.e. the *next* issuance is already
#                 a duplicate. The only one of the three that predicts a defect instead of
#                 reporting one, which is why it is worth a finding before anything breaks.
# Canon: project-docs-convention.md §ID Issuance. ADR is the only multi-instance kind — policy
# stopped being one when KJP-79 retired the folder model, so `## POL-NNN` is a heading serial
# inside one file and has no `id:`, no `next_id`, and nothing for this audit to hold.
#
# Scope = `docs/adr/` and no other path, reusing the docs-layer list the scan above just consumed
# rather than opening a scan root of its own: one manifest-derived enumeration, so a moved
# `projects_root` cannot reach one scan and miss the other.
#
# 🔴 No `sort`/`uniq` anywhere in here, deliberately. Every set is an awk subscript — byte-exact
# string keys, no collation, no dedup pass — so the KJP-74 hazard (macOS `sort -u` collapsing
# non-ASCII names that carry no primary collation weight, measured `en_US.UTF-8` → 1 line of 4)
# has no seat. The shell pipeline that would have had one is the naive spelling of this check,
# `awk '{print id}' | sort | uniq -d`, which would silently under-count duplicates among
# non-ASCII filenames; the selftest's 결정-가/결정-나 pair is the fixture that keeps it out.
: > "$ADRL"
while IFS= read -r f; do
  # The same path predicate the id/next_id obligations use above — one rule, not a second copy.
  case "$f" in */docs/adr/*) printf '%s\n' "$f" >> "$ADRL" ;; esac
done < "$LIST"

awk -v adrlist="$ADRL" -v countf="$NADR" "$AWK_PRELUDE"'
  # Dynamic regex strings, not /literals/: one-true-awk (macOS /usr/bin/awk) cannot parse a `/`
  # inside a bracket class in a regex literal. Same discipline as the coverage scan above.
  function folder_of(path,   dir)  { dir = path; sub(DIRPART, "", dir); return dir }
  function base_of(path,   name)   { name = path; sub(BASEPART, "", name); return name }
  function trim(text) { sub(/^[ \t]+/, "", text); sub(/[ \t]+$/, "", text); return text }
  function idform(folder, serial) { return IDPREFIX[folder] sprintf("%05d", serial) }

  # One ADR file, frontmatter only. A body file contributes its `id:`, the folder TOC its
  # `next_id:` — the two halves of one issuance record. GOTID reports back whether this file
  # yielded an id, which is what the filename fallback keys off.
  function harvest(file, folder,   line, lineno, keyname, value) {
    GOTID = 0; lineno = 0
    while ((getline line < file) > 0) {
      lineno++
      sub(/\r$/, "", line)
      if (lineno == 1 && line != "---") break
      if (lineno == 1) continue
      if (line == "---") break
      if (!match(line, TOPKEY)) continue
      keyname = substr(line, 1, RLENGTH - 1); gsub(QC, "", keyname)
      value = unq(trim(substr(line, RLENGTH + 1)))
      if (keyname == "id") record_id(folder, file, value, lineno)
      else if (keyname == "next_id" && value != "") {
        NEXTVAL[folder] = value; NEXTLINE[folder] = lineno; NEXTFILE[folder] = file
      }
    }
    close(file)
  }

  # An id joins two tables. The literal string drives duplicate detection, because the string IS
  # the link target and identical strings are exactly what makes `[[...]]` ambiguous; the trailing
  # digit run drives the sequence. A value the serial parse cannot read still counts as a
  # duplicate — it simply sits outside the sequence rather than dodging the audit.
  # ponytail: two different prefixes on one serial in one folder (`KJP-ADR-00001` beside
  # `ABC-ADR-00001`) is a double issuance this misses, since the strings differ. No instance in
  # either measured vault, and mixed prefixes in one folder are their own defect; revisit if one
  # appears.
  function record_id(folder, file, value, lineno,   slot, serial) {
    if (value == "") return
    GOTID = 1; IDTOTAL++
    slot = folder SUBSEP value
    if (!(slot in IDCOUNT)) {
      IDCOUNT[slot] = 0; IDLINE[slot] = lineno; IDANCHOR[slot] = file
      NIDORDER[folder]++; IDORDER[folder, NIDORDER[folder]] = value
    }
    IDCOUNT[slot]++
    IDFILES[slot] = (IDCOUNT[slot] == 1) ? base_of(file) : IDFILES[slot] " " base_of(file)
    if (!match(value, /[0-9]+$/)) return
    serial = substr(value, RSTART, RLENGTH) + 0
    ISSUED[folder, serial] = 1
    if (!(folder in IDPREFIX)) IDPREFIX[folder] = substr(value, 1, RSTART - 1)
    if (serial > TOPSERIAL[folder]) {
      TOPSERIAL[folder] = serial; TOPID[folder] = value; TOPFILE[folder] = file
    }
  }

  # A body file whose `id:` is absent or unreadable still consumed its number if the FILENAME
  # carries one. `KJP-ADR-00001.md` with no `id:` key is already reported by the presence check
  # above; calling its number a hole as well would say "the record is gone" about a file sitting
  # right there — the wrong defect, reported twice. (The coverage scan makes the same call about
  # malformed index lines: already a finding, so not counted as missing too.)
  # 🔴 A stem is recorded in its own set and never touches TOPSERIAL: it may only ever silence a
  # gap, never invent one above the highest *issued* id. Otherwise one misnamed file
  # (`KJP-ADR-00099.md` in a folder that has issued three) would manufacture 95 findings.
  function record_stem(folder, file,   stem) {
    stem = base_of(file); sub(/\.md$/, "", stem)
    if (!match(stem, /[0-9]+$/)) return
    NAMEDSERIAL[folder, substr(stem, RSTART, RLENGTH) + 0] = 1
  }

  # One finding per duplicated id, not one per file: the collision is the defect, and the message
  # names every file in it so the anchor line does not have to carry that meaning alone.
  function report_dupes(folder,   i, value, slot) {
    for (i = 1; i <= NIDORDER[folder]; i++) {
      value = IDORDER[folder, i]; slot = folder SUBSEP value
      if (IDCOUNT[slot] < 2) continue
      print IDANCHOR[slot] ":" IDLINE[slot] ": duplicate ADR id: " value " is carried by " IDCOUNT[slot] \
            " files (" IDFILES[slot] ") — an id is the link target, so [[" value "]] resolves to whichever one the reader opens and no link can tell the two decisions apart; the folder counter issues one number to one decision (project-docs-convention.md §ID Issuance), so a collision means two files were written against the same next_id"
    }
  }

  # 🔴 Holes are enumerated over 1..highest-issued, never up to next_id. A number ABOVE every file
  # is issuance in advance, which canon expects and report_counter deliberately stays silent about;
  # a number BELOW a file that exists was handed out and then lost its record. The range starts at
  # 1 rather than at the lowest id present: measured 2026-08-12 on the techtainment vault, all 6
  # ADR folders holding no files carry `next_id: 1`, so serial 1 is always the first number the
  # counter hands out and a hole underneath the lowest file is a consumed number, not numbering
  # that began later. (That measurement is also what makes this rule earn its keep: the vault has
  # exactly one such hole, and it is a leading one.)
  # Anchored at the file carrying the highest issued id — the file whose own number proves the
  # counter walked past the hole. Not the folder TOC: an ADR folder is not guaranteed to have one
  # (the `missing next_id:` finding above can only speak when an index file exists), and an anchor
  # that exists only sometimes is a finding that disappears sometimes.
  function report_gaps(folder,   serial, miss, nmiss) {
    if (TOPSERIAL[folder] + 0 == 0) return
    nmiss = 0; miss = ""
    for (serial = 1; serial <= TOPSERIAL[folder]; serial++) {
      if ((folder, serial) in ISSUED || (folder, serial) in NAMEDSERIAL) continue
      nmiss++
      if (nmiss <= GAPCAP) miss = (nmiss == 1) ? idform(folder, serial) : miss ", " idform(folder, serial)
    }
    if (nmiss == 0) return
    if (nmiss > GAPCAP) miss = miss " and " (nmiss - GAPCAP) " more"
    print TOPFILE[folder] ":1: gap in the ADR sequence: " miss " (issued, then unaccounted for — the counter handed out every number below " TOPID[folder] ", so a hole is a decision record deleted, moved out of docs/adr/, or never written; ids are immutable so the number can never be reissued, and any link to it dangles)"
  }

  # 🔴 The asymmetric judgment, and the reason it is asymmetric. `next_id` is what the PM reads to
  # issue the next number (§ID Issuance), so the two directions of drift are not the same thing:
  #   · ABOVE highest + 1 — numbers issued, records not written yet. Canon puts issuance *in
  #     advance* ("issuer = the PM, in advance"), so this is a legal, expected, transient state.
  #     Silent — and not a stderr warn either: warns here are for legacy-legal spellings, and this
  #     is current-legal. A gate that fires on correct behaviour is a gate that gets ignored.
  #   · AT OR BELOW highest — the next number the PM hands out is one a file already holds. That
  #     is a duplicate that has not happened yet, and there is no reading in which it is correct.
  # Measured 2026-08-12, techtainment vault: every one of the 5 ADR folders holding files carries
  # next_id = highest + 1, and all 6 empty ones carry `next_id: 1` — so the counter is maintained
  # as "the next number to hand out", which is the semantics this comparison assumes.
  # An index carrying no `next_id` at all is already reported above; repeating it here would add
  # no instruction. A value with no digits is left alone for the same reason format is not this
  # audit’s question — it is counted by neither side and reported by neither.
  function report_counter(folder,   next_serial) {
    if (!(folder in NEXTVAL) || TOPSERIAL[folder] + 0 == 0) return
    if (!match(NEXTVAL[folder], /[0-9]+$/)) return
    next_serial = substr(NEXTVAL[folder], RSTART, RLENGTH) + 0
    if (next_serial > TOPSERIAL[folder]) return
    print NEXTFILE[folder] ":" NEXTLINE[folder] ": next_id " NEXTVAL[folder] " is not ahead of the highest issued id " TOPID[folder] " (the counter hands out the next number, so the PM'"'"'s next issuance collides with a file that already exists — set next_id to " (TOPSERIAL[folder] + 1) ")"
  }

  BEGIN {
    # A quoted key is the same key, and a quoted value the same value — the same bypass the docs
    # scan above closed (`"id":` / `id: "KJP-ADR-00001"`). QC is built with %c because a literal
    # single quote cannot appear inside this single-quoted awk program; unq() comes from the
    # shared prelude rather than a second copy.
    QC = "[\"" sprintf("%c", 39) "]"
    TOPKEY = "^" QC "?[A-Za-z_][A-Za-z0-9_]*" QC "?:"
    DIRPART = "/[^/]*$"; BASEPART = "^.*/"
    METAPAT = "^_?index[.]md$"
    # Gap listing cap. A mistyped serial (`id: KJP-ADR-2026`) would otherwise enumerate two
    # thousand holes and bury every other finding in the run — the false-positive rate that gets a
    # gate ignored. The COUNT stays exact; only the printed list is trimmed.
    GAPCAP = 10
    while ((getline file < adrlist) > 0) {
      folder = folder_of(file)
      if (!(folder in FOLDERSEEN)) {
        FOLDERSEEN[folder] = 1; NFOLDERS++; FOLDERS[NFOLDERS] = folder
      }
      harvest(file, folder)
      if (!GOTID && base_of(file) !~ METAPAT) record_stem(folder, file)
    }
    close(adrlist)
    printf "%d\n", (IDTOTAL + 0) > countf
    close(countf)
    # Per folder, because every rule here is scoped to one counter: the same id string under two
    # folders is two decisions under two counters, not a collision.
    for (i = 1; i <= NFOLDERS; i++) {
      report_dupes(FOLDERS[i]); report_gaps(FOLDERS[i]); report_counter(FOLDERS[i])
    }
  }
' >> "$OUT"
# The evidence base, carried out of awk as one integer — the same reason `entries` is reported:
# a folder of ADRs whose ids never got parsed yields zero duplicates and zero gaps, which reads
# exactly like a clean ledger.
n_adr="$(tr -d ' \n' < "$NADR")"
[ -n "$n_adr" ] || n_adr=0

# ------------------------------------------------------------------------ report
# The scanned counts print on every run so a collapsed scan (0 files) is visibly
# different from a clean vault — "OK" on its own cannot distinguish the two.
# `entries` and `adr ids` are the odd ones out: not file counts but payload counts — the distinct
# link targets the folder indexes yielded, and the `id:` values the ADR bodies yielded. Each is
# the evidence base of a check whose clean result and whose collapsed result are the same output.
# A vault whose notes are all indexed and a run whose indexes were never parsed both report zero
# coverage findings; a folder of ADRs and a folder whose ids never got parsed both report zero
# duplicates and zero gaps. Neither number is implied by any file count next to it, which is
# exactly why both are printed.
# 🔴 `wiki indexes` and `docs indexes` are two numbers, not one, for the same reason: they are two
# scans under two rules, and a single total could hide either half collapsing to zero. The docs
# number is also the *only* place a project hub is ever counted — it sits above `docs/` and outside
# every wiki root, so no other count in this line moves when the hub scan breaks. The older label
# was a bare `indexes`, which stopped being unambiguous the moment there were two.
#
# ponytail: known limits, all judged not worth the weight for a real vault —
#   · symlinked notes are skipped (`-type f`); use `find -L` if vaults ever use links.
#   · filenames containing newlines break the line-based file list and counts.
# The label is `wiki`, not `knowledge`: that is the canon's name for the layer (vault-tree.md
# §Layers) and the name this file's own header has used since the 0.2.0 pass. The count line was
# the last place the retired word survived.
# 🔴 `p_memory names` is its own number and not a slice of `wiki`: the name scan is a second,
# independent walk (per project, so it can resolve that project's PREFIX), and it counts only the
# notes under a hub that actually declared one. So it moves when `wiki` does not — a project whose
# hub lost its PREFIX line keeps its notes in `wiki` and drops them from here, which is the one
# number that distinguishes "checked and clean" from "skipped for want of an authority".
scanned="$n_sessions sessions, $n_wiki wiki, $n_pmem p_memory names, $n_index wiki indexes, $n_dindex docs indexes, $n_cover entries, $n_shared shared, $n_docs docs, $n_adr adr ids"
count="$(wc -l < "$OUT" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
  echo "validate.sh: OK — no issues ($scanned) $VAULT"
  exit 0
fi

cat "$OUT"
echo "validate.sh: $count issue(s) ($scanned) $VAULT"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
