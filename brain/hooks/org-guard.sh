#!/usr/bin/env bash
# ⚠ OPT-IN — inactive unless wired into hooks.json. This file is NOT registered in this
#   plugin's hooks.json on purpose (same stance as force-delegate.sh): a hook that can block
#   a write is a policy, and a policy ships off by default. To turn it on, add to hooks.json
#   (or your settings.json) — matcher syntax is a regex, `|` for OR:
#
#     "PreToolUse": [
#       {
#         "matcher": "Write|Edit|NotebookEdit",
#         "hooks": [
#           { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/org-guard.sh", "timeout": 5 }
#         ]
#       }
#     ]
#
# org-guard.sh — blocks writes to the vault's COMMON layer (`common_root`, e.g. `org/`).
#
# Why: the 0.2.0 write-permission split. An UNATTENDED cycle (`sc`, `dreaming`) writes only to
#   `hippocampus/` · `<project>/p_memory/` · `neocortex/`. The common layer and `docs/` are
#   written only by an AI acting on an explicit user instruction. The common layer is the
#   cross-project surface — a wrong write there propagates into every project's recall.
#
# 🔴 Why a hook and not a linter: the `writer` frontmatter key was retired, so a file's own
#   state no longer records who wrote it. After the fact there is NOTHING in the vault that
#   distinguishes a user-directed write from an unattended one — the evidence a linter would
#   need does not exist. Detection is therefore impossible in principle; only PREVENTION is
#   available, and prevention has to sit at the moment of the write. Hence PreToolUse.
#
# What it decides on: the target path only. It does NOT try to infer whether the caller was
#   unattended — that inference was the impossible half. The rule it enforces is the flat one
#   ("nothing writes to the common layer through this hook"), which is why it is opt-in: turn
#   it on for the sessions that must not touch the common layer.
#
# Common-layer root is NEVER hardcoded here. It comes from scripts/vault-paths.sh, which reads
#   the vault's own `.brain-paths` manifest (`common_root`) — the same resolver validate.sh
#   uses. A literal `org/` in this file would break the day a vault restructures, and would
#   silently stop blocking rather than fail loudly.
#
# 🔴 Fails OPEN, never closed. If the vault root cannot be determined, or the common root does
#   not resolve, the write is ALLOWED and one line goes to stderr saying so. A false positive
#   (blocking a legitimate write with no way for the user to see why) is worse than a miss:
#   the miss is recoverable by a human review, the false positive halts real work.
#
# Exit contract (PreToolUse): 0 = allow, silent. 2 = block, stderr is shown to the model.
#   stdout is left EMPTY on the allow path on purpose — Claude Code parses hook stdout as JSON
#   on exit 0, so a stray `echo` would be read as a malformed directive.
#
# Escape hatch: ORG_GUARD_OFF=1 → unconditional pass.
#
# Portability: macOS stock bash 3.2 + POSIX grep/sed only. NO jq (dependency zero — the same
#   constraint every brain script carries; force-delegate.sh's optional jq path is not copied
#   here because a hook that behaves differently depending on whether jq happens to be
#   installed is a hook you cannot reason about).

set -u

[ "${ORG_GUARD_OFF:-}" = "1" ] && exit 0

INPUT="$(cat)"

# ------------------------------------------------------------------- JSON field extraction
# First occurrence wins, deliberately. `tool_input.content` on a Write can itself contain the
# text `"file_path": "..."` (writing this very file would do it), and a greedy `sed` would
# match that one instead. Taking the FIRST match keeps the real key — and when it ever guesses
# wrong it guesses toward allowing, which is the direction this hook fails in by design.
_og_str() {  # _og_str <key>  — prints the JSON string value, empty if absent
  printf '%s' "$INPUT" | tr '\n\r\t' '   ' \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed 's/^[^:]*:[[:space:]]*"//; s/"$//'
}

# Write and Edit carry `file_path`; NotebookEdit carries `notebook_path` instead (measured
# against the documented PreToolUse tool_input schema, 2026-08-03). Reading only `file_path`
# would leave NotebookEdit silently unguarded even though the matcher above sends it here.
TARGET="$(_og_str file_path)"
[ -n "$TARGET" ] || TARGET="$(_og_str notebook_path)"
[ -n "$TARGET" ] || exit 0   # no path in the payload = nothing to judge

HOOK_CWD="$(_og_str cwd)"
[ -n "$HOOK_CWD" ] || HOOK_CWD="${CLAUDE_PROJECT_DIR:-$PWD}"

# ------------------------------------------------------------------------ vault resolution
# Canon: VAULT is the `vault-root` value in the project's CLAUDE.local.md — never a hardcoded
# path, never inferred from the directory name (skills/_session-shared/project-inference.md).
# Env wins, as a dry-run seam and an escape hatch, mirroring vault-paths.sh's own override.
VAULT="${BRAIN_VAULT:-${VAULT:-}}"

if [ -z "$VAULT" ]; then
  # Walk up from the session cwd: the hook may fire while the model is working in a
  # subdirectory, where CLAUDE.local.md sits several levels above.
  _d="$HOOK_CWD"
  while [ -n "$_d" ] && [ "$_d" != "/" ]; do
    if [ -r "$_d/CLAUDE.local.md" ]; then
      VAULT="$(grep -E '^[[:space:]]*vault-root:' "$_d/CLAUDE.local.md" 2>/dev/null | head -1 \
               | sed 's/^[[:space:]]*vault-root:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '\r')"
      [ -n "$VAULT" ] && break
    fi
    _d="$(dirname "$_d")"
  done
fi

# Trailing slash stripped: vault-root is compared as a string prefix downstream, and
# `<root>` vs `<root>/` are different strings (skills/init/SKILL.md step 2b makes the same point).
case "$VAULT" in */) VAULT="${VAULT%/}" ;; esac

if [ -z "$VAULT" ] || [ ! -d "$VAULT" ]; then
  echo "[org-guard] vault root unresolved (no VAULT/BRAIN_VAULT env, no readable vault-root: in CLAUDE.local.md at or above ${HOOK_CWD}) — allowing the write unchecked." >&2
  exit 0
fi

# ------------------------------------------------------------------ common-layer resolution
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 0
RESOLVER="$HERE/../scripts/vault-paths.sh"
if [ ! -r "$RESOLVER" ]; then
  echo "[org-guard] path resolver not found: $RESOLVER — allowing the write unchecked." >&2
  exit 0
fi
# shellcheck source=../scripts/vault-paths.sh
. "$RESOLVER"

# vault-paths.sh already warns loudly on stderr and blanks BRAIN_COMMON when the common root
# is missing; that is a legal state here (a vault mid-restructure), so allow and move on.
if [ -z "${BRAIN_COMMON:-}" ] || [ ! -d "$BRAIN_COMMON" ]; then
  echo "[org-guard] common layer did not resolve under $VAULT — allowing the write unchecked." >&2
  exit 0
fi

# ------------------------------------------------------------------------- path comparison
# Both sides are collapsed through `cd … && pwd -P` so that `..` segments and symlinks cannot
# walk into the common layer behind a path that does not lexically look like it. The target
# usually does NOT exist yet (that is the point of a PreToolUse on Write), so only its PARENT
# is resolved; when the parent does not exist either, the lexical path is used and the check
# fails open — consistent with every other unknown in this hook.
case "$TARGET" in
  /*) _t="$TARGET" ;;
  *)  _t="$HOOK_CWD/$TARGET" ;;
esac
_tdir="$(dirname "$_t")"
_tbase="$(basename "$_t")"
if [ -d "$_tdir" ]; then
  _tdir="$(cd "$_tdir" 2>/dev/null && pwd -P)" || _tdir="$(dirname "$_t")"
fi
ABS="$_tdir/$_tbase"

COMMON="$(cd "$BRAIN_COMMON" 2>/dev/null && pwd -P)" || COMMON="$BRAIN_COMMON"

# String prefix, not a `case` glob: the vault path is DATA, and a `case "$ABS" in "$COMMON"/*)`
# would silently reinterpret a `[` or `*` in that path as a pattern. Quoting the prefix inside
# the parameter expansion disables globbing outright.
_pfx="$COMMON/"
if [ "$ABS" = "$COMMON" ] || [ "${ABS#"$_pfx"}" != "$ABS" ]; then
  echo "[org-guard] BLOCKED: $ABS" >&2
  echo "[org-guard] Why: that path is inside the vault's COMMON layer ($COMMON — resolved from .brain-paths 'common_root', not hardcoded). The common layer is the cross-project surface: it is written only by an AI acting on an explicit user instruction, never by an unattended cycle (sc / dreaming), which is confined to hippocampus/ , <project>/p_memory/ and neocortex/. Because the 'writer' frontmatter key was retired, a wrong write here cannot be identified after the fact — so it is stopped before it happens." >&2
  echo "[org-guard] What to do: do not write it here. Bring it to a session that has the user's explicit instruction, and have the PM delegate the write as a scribe brief. If a promotion candidate needs somewhere to sit meanwhile, that is <project>/p_memory/ — the unattended cycle may write there. To lift this policy for one session, start it with ORG_GUARD_OFF=1." >&2
  exit 2
fi

exit 0
