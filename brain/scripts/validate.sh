#!/bin/bash
# validate.sh — brain vault schema linter.
#
#   validate.sh <vault-root> [--strict]
#
# Checks the vault manifest's `schema_version`, session-note frontmatter (required keys, status
# vocabulary, retired keys) on the raw layer (`hippocampus/`), `summary:` on the wiki layer
# (`p_memory/` + `neocortex/` + the common and tools roots), the wiki layer's folder indexes
# (`_index.md` line form + dangling links), session-uid wikilinks on the
# team-shared surface, and docs frontmatter v2 (`session:` key = violation; `status:`
# required + vocabulary; v1 history subkeys; policy/adr `id:` and index `next_id:`;
# API_SPEC mirror keys; unknown keys and legacy `updated:` formats = stderr warn
# only). Reports as `file:line: message`.
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
trap 'rm -f "$OUT" "$LIST" "$TARGETS"' EXIT

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
  awk -v file="$f" "$AWK_PRELUDE"'
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
# §The tools root). recall scans it, and *this* scan is the recall mirror — so it is a scan root
# here too. It does not arrive via brain_projects: that helper excludes the reserved 9xx band
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

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" '
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

# ----------------------------------------------------- folder indexes (`_index.md`)
# 🔴 The failure mode this whole layer is built on, and the only one no other check can reach.
# recall injects the folder indexes and nothing else (`skills/_session-shared/recall.md`), so an
# index line naming a file that is not there is not a broken link — it is a **false inventory**.
# Every later session reads the list, believes the note exists, and nothing contradicts it. The
# inverse is loud: a note with no summary is reported by the scan above. This one is silent.
# Line form canon: knowledge-convention.md §summary — `- [[<filename stem>]] — <summary>`.
#
# Scope = the wiki layer's TOCs, i.e. the same roots as the note scan above, because that line
# form is the memory-note canon. Two trees are deliberately outside it, each pinned by a
# dangling-link fixture in the self-test so the boundary cannot rot into an accident:
#   · `hippocampus/` — the raw layer, never a recall target (vault-tree.md §Layers)
#   · `NNN_*/docs/`  — a docs TOC legitimately carries prose and `next_id:`, not memory-note lines
#     (doc-catalog.md: the project hub is "one-line definition + PREFIX + TOC pointers")
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

: > "$TARGETS"
if [ "$n_index" -gt 0 ]; then
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
  done | sort -u > "$TARGETS"
fi

while IFS= read -r f; do
  [ -r "$f" ] || { echo "$f:1: cannot read file (permission or broken link)"; continue; }
  awk -v file="$f" -v targets="$TARGETS" '
    BEGIN {
      while ((getline t < targets) > 0) T[t] = 1
      close(targets)
    }
    { sub(/\r$/, "") }
    # A TOC entry is a list line, and only a list line. Headings, the intro sentence that says what
    # the folder is, and blank lines carry no obligation — an index is allowed to introduce itself.
    # Any bullet, though, is claiming to be an entry, so `*` and `+` bullets are entries too and
    # fail the form: recall reads the whole file, and a half-formed line costs a note its summary.
    /^[ \t]*[-*+][ \t]/ {
      if (!match($0, /^- \[\[[^]]+\]\] — [^ ]/))
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
        if (!(t in T))
          print file ":" NR ": dangling _index link: [[" t "]] (recall injects this index and nothing else — a line naming a file that is not there is a false inventory no other check can see)"
      }
    }
  ' "$f"
done < "$LIST" >> "$OUT"

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
# 🔴 The tools root is NOT scanned here, and that is not a mirror divergence — this scan was never
# the recall mirror (the wiki summary scan above is). Its axis is *share scope*, and the tools root is
# gitignored machine-local content, so it is outside the shared surface by definition: no teammate
# ever pulls it, so no link in it can dangle for one. It needs no exclusion either — it has neither
# docs/ nor p_memory/, so the sweep below never picks it up (measured).
#
# 🔴 `neocortex/` IS scanned here, as of KJP-65. It had been left out for a reason that was never a
# reason — step 6 of the 0.2.0 linter migration renamed this scan without extending it — and the
# axis decides the question outright: neocortex/ is git-tracked and pulled like any project folder,
# so a session wikilink there dangles for a teammate exactly as one in docs/ does. That leaves the
# tools root as the only root inside the recall mirror and outside this scan, which is what keeps
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
#   · `docs/policy/`·`docs/adr/`: body files without `id:` (multi-instance, PM-issued,
#     immutable); their index/_index without `next_id:` (the issuance counter).
#     ⚠️ Presence only. **Duplicate IDs and gaps in the sequence have no owner** — the audit that
#     would have caught them was retired with the dreaming feature set (KJP-77), and
#     project-docs-convention.md §ID Issuance records the hole as a known gap rather than a rule
#     someone is following. Named here so the presence check is not mistaken for the whole
#     contract; closing it is a separate card, not this one.
#   · `docs/tech-design/API_SPEC.md` without `source:` + `readonly: true` (mirror contract).
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
# (status·id·mirror·updated) but not the session check. Feature-tier policies
# (`docs/feature/<F>/policy/`) are NOT under the id rule yet — deliberate scope, extend on
# decision, not by drift.
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
  #   docs/policy/ · docs/adr/         body → `id:` required; index/_index → `next_id:` required
  #   docs/tech-design/API_SPEC.md     repo-spec mirror → `source:` + `readonly: true` required
  idreq=0; nidreq=0; mirror=0
  case "$f" in
    */docs/policy/*|*/docs/adr/*) if [ "$meta" -eq 1 ]; then nidreq=1; else idreq=1; fi ;;
    */docs/tech-design/API_SPEC.md) mirror=1 ;;
  esac
  awk -v file="$f" -v meta="$meta" -v idreq="$idreq" -v nidreq="$nidreq" -v mirror="$mirror" "$AWK_PRELUDE"'
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
        # In docs/policy/·docs/adr/ they carry the ID counter instead (§ID Issuance).
        if (nidreq && !("next_id" in seen))
          print file ":1: missing next_id: in policy/adr folder index (the ID issuance counter — the PM reads and bumps it)"
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
        print file ":1: missing id: on a multi-instance document (docs/policy·docs/adr — the PM issues it; required & immutable)"
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

# ------------------------------------------------------------------------ report
# The scanned counts print on every run so a collapsed scan (0 files) is visibly
# different from a clean vault — "OK" on its own cannot distinguish the two.
#
# ponytail: known limits, all judged not worth the weight for a real vault —
#   · symlinked notes are skipped (`-type f`); use `find -L` if vaults ever use links.
#   · filenames containing newlines break the line-based file list and counts.
# The label is `wiki`, not `knowledge`: that is the canon's name for the layer (vault-tree.md
# §Layers) and the name this file's own header has used since the 0.2.0 pass. The count line was
# the last place the retired word survived.
scanned="$n_sessions sessions, $n_wiki wiki, $n_index indexes, $n_shared shared, $n_docs docs"
count="$(wc -l < "$OUT" | tr -d ' ')"
if [ "$count" -eq 0 ]; then
  echo "validate.sh: OK — no issues ($scanned) $VAULT"
  exit 0
fi

cat "$OUT"
echo "validate.sh: $count issue(s) ($scanned) $VAULT"
[ "$STRICT" -eq 1 ] && exit 1
exit 0
