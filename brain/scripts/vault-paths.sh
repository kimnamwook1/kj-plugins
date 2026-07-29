#!/bin/bash
# vault-paths.sh — resolve the vault's tree axes. Sourced, not run.
#
#   VAULT=/path/to/vault . "$(dirname "$0")/vault-paths.sh"
#
# Why this exists: the tree differs per vault. One vault keeps cross-project knowledge in
# `000_common/` with project folders at the root; another keeps it in `_primary/` with project
# folders under `projects/`. That knowledge used to be copied into five consumers (validate.sh,
# recall.md, ss, sr), so a restructure silently zeroed every scan until all five were patched.
# Here it is declared once, in the vault itself, and read from one place.
#
# Manifest: `<vault>/.brain-paths`, `key: value` per line, `#` comments allowed.
#   common_root:   path relative to the vault root   (default `000_common`)
#   projects_root: path relative to the vault root   (default `.` — project folders at the root)
#   tools_root:    path relative to the vault root   (default `999_tools` — machine-global tool inventory)
# Absent file or absent key = the default, so a vault that never restructured needs no manifest.
#
# Portability: macOS stock bash 3.2 + POSIX find/sed/grep. No associative arrays, no mapfile,
# no `find -printf`, no `grep -P`, no yaml parser.

: "${VAULT:?vault-paths.sh: set VAULT to the vault root before sourcing}"

# ponytail: grep+sed, not a yaml parser. The manifest is two scalar keys; a parser would be
# a dependency for something `grep` does in one line. Revisit if it ever grows nesting.
_bp_get() {  # _bp_get <key> <default>
  _bp_v=""
  if [ -f "$VAULT/.brain-paths" ]; then
    _bp_v=$(grep -E "^[[:space:]]*$1:" "$VAULT/.brain-paths" 2>/dev/null | head -1 \
            | sed "s/^[[:space:]]*$1:[[:space:]]*//" | sed 's/[[:space:]]*$//' | tr -d '\r')
  fi
  if [ -n "$_bp_v" ]; then printf '%s' "$_bp_v"; else printf '%s' "$2"; fi
}

# Env wins over the manifest — a dry-run seam (test a layout without writing to the vault) and
# an escape hatch for a one-off scan. Unset in normal use, so the manifest is the operative source.
BRAIN_COMMON_REL="${BRAIN_COMMON_REL:-$(_bp_get common_root 000_common)}"
BRAIN_PROJECTS_REL="${BRAIN_PROJECTS_REL:-$(_bp_get projects_root .)}"
BRAIN_TOOLS_REL="${BRAIN_TOOLS_REL:-$(_bp_get tools_root 999_tools)}"

BRAIN_COMMON="$VAULT/$BRAIN_COMMON_REL"
case "$BRAIN_PROJECTS_REL" in
  .|./) BRAIN_PROJECTS="$VAULT" ;;
  *)    BRAIN_PROJECTS="$VAULT/$BRAIN_PROJECTS_REL" ;;
esac
BRAIN_TOOLS="$VAULT/$BRAIN_TOOLS_REL"

# 🔴 Loud, not silent. A missing common root is exactly the failure this file was written for:
# the scan returns zero notes and every caller reports "no accumulated memory" as if that were
# a fact about the vault rather than a broken path.
if [ ! -d "$BRAIN_COMMON" ]; then
  echo "vault-paths: common root not found: $BRAIN_COMMON (common_root=$BRAIN_COMMON_REL)" >&2
  BRAIN_COMMON=""
fi
if [ ! -d "$BRAIN_PROJECTS" ]; then
  echo "vault-paths: projects root not found: $BRAIN_PROJECTS (projects_root=$BRAIN_PROJECTS_REL)" >&2
fi

# Silent, not loud — the deliberate opposite of the common root above. The tools layer
# (`999_tools/` by default) is machine-global and git-untracked (vault-tree.md §The tools root):
# a vault without it is a *legal* state (fresh machine, a teammate's clone), not a broken
# path, so absence here means "nothing to scan", never "the tree moved under us". A warning
# would cry wolf on every such vault; consumers test for the empty string and skip.
if [ ! -d "$BRAIN_TOOLS" ]; then
  BRAIN_TOOLS=""
fi

# Project folders, one per line. `NNN_` prefixed, reserved 9xx band excluded (a `999_*` folder
# is infra, not a project — and letting it into the number computation yields a 4-digit `next`).
# The common root matches `NNN_` too when it is `000_common` at the vault root, so it is dropped.
brain_projects() {
  find "$BRAIN_PROJECTS" -mindepth 1 -maxdepth 1 -type d -name '[0-8][0-9][0-9]_*' 2>/dev/null \
  | sort | while IFS= read -r _bp_d; do
      [ -n "$BRAIN_COMMON" ] && [ "$_bp_d" = "$BRAIN_COMMON" ] && continue
      printf '%s\n' "$_bp_d"
    done
}

# Next free project number, zero-padded to 3. Max-based: with no projects it yields 001.
brain_next_project_num() {
  _bp_n=$(brain_projects | sed 's|.*/||;s|_.*||' | sort -n | tail -1)
  printf '%03d' $((10#${_bp_n:-0} + 1))
}

# Locate one project folder by slug. Prints nothing when absent.
brain_project_dir() {  # brain_project_dir <slug>
  brain_projects | grep -E "/[0-8][0-9][0-9]_$1$" | head -1
}

# Knowledge-note file list under the given roots. Recursive on purpose: the common layer's
# sub-axes differ per vault (`000_common/{facts,patterns,policies}` flat vs `_primary/patterns`
# plus `_primary/_company/<folder>/`), and naming them here would re-hardcode the tree this
# file exists to stop hardcoding.
#
# Exclusions are structural, not per-vault, so they stay in code rather than the manifest:
#   index.md / _index.md / 0.*  — folder TOCs and meta logs, not notes
#   _templates/                 — skeletons with placeholder frontmatter; they would lint as broken notes
#   999_Archive/ Archive/       — retired content
#   _dreaming_logs/ dream-log.md — dreaming output, not knowledge. Two shapes for one thing:
#                                 a folder in one vault, a single file in the other (measured).
brain_find_notes() {  # brain_find_notes <dir>...
  [ $# -gt 0 ] || return 0
  find "$@" -type f -name '*.md' \
    ! -name 'index.md' ! -name '_index.md' ! -name '0.*' ! -name 'dream-log.md' \
    ! -path '*/_templates/*' ! -path '*/999_Archive/*' ! -path '*/Archive/*' \
    ! -path '*/_dreaming_logs/*' 2>/dev/null
}
