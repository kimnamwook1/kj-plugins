#!/usr/bin/env bash
# kernel-check-hook.sh — the wiring adapter that makes scripts/kernel-check.sh actually run.
#
# KJP-71. The checker existed but nothing invoked it, so KERNEL drift was detected only when
# someone remembered to run it by hand — which is the same as not being detected.
#
# Two events, two DIFFERENT subjects. This is not redundancy:
#   PostToolUse (matcher Edit|Write) — checks the agents directory of the file JUST EDITED.
#     Catches the author in the act, seconds after the drift, wherever that copy lives (repo
#     checkout, worktree, or plugin cache). kernel-check.sh takes the directory as an argument
#     precisely so the edited copy is the one judged, not some other copy of the same file.
#   SessionStart — checks THIS plugin's own agents/ (kernel-check.sh's default). Those are the
#     definitions the harness actually injects. Catches drift that no Edit tool ever touched:
#     git merge, git pull, `sed -i`, a version bump, a hand-patched install.
#
# 🔴 Why not CI, and why not pre-commit (measured 2026-08-05, not assumed):
#   CI — the repo has no .github/ at all, and `gh api .../rulesets` returns zero active rulesets
#     with no branch protection, so a workflow would be a signal and never a gate. Worse, it runs
#     only on push, and this repo is pushed only when the user says so; drift would sit locally
#     for days. Worst: CI guards THIS repo, while the definitions that actually run come from the
#     installed plugin copy, which no workflow ever sees.
#   pre-commit — `--no-verify` bypasses it, `core.hooksPath` is unset and .git/hooks holds only
#     samples (so every developer and every worktree needs a manual install), and it too guards
#     only this repo. Commits here are the PM's, but the drift is introduced earlier, by workers.
#   hooks.json wins on exactly one property neither has: it travels WITH the plugin, so the check
#     reaches every install and every project rather than one checkout.
#
# Exit contract, per the documented per-event table (code.claude.com/docs/en/hooks):
#   PostToolUse  — cannot block (the write already happened). exit 2 feeds STDERR back to the
#     model as feedback, which is the whole point: tell the author to restore the block now.
#   SessionStart — cannot block at all, and exit 2 shows stderr to the USER only, where the model
#     never sees it. So findings go to STDOUT with exit 0, which the docs define as context the
#     model can read and act on.
#
# 🔴 Silent on pass, both events. SessionStart stdout is injected into context on every single
#   session of every project using this plugin; printing "OK — 4 agents" there would be a
#   permanent token tax for a check that passes almost always. Only findings are worth context.
#
# Escape hatch: KERNEL_CHECK_OFF=1 → unconditional pass.
# Test seam: KERNEL_CHECK_DIR overrides the SessionStart scan target.
#
# Portability: macOS stock bash 3.2 + POSIX grep/sed/basename only. No jq — the same dependency-
#   zero constraint kernel-check.sh and org-guard.sh carry.

set -u

[ "${KERNEL_CHECK_OFF:-}" = "1" ] && exit 0

INPUT="$(cat)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 0
CHECKER="$HERE/../scripts/kernel-check.sh"

# First occurrence wins. A PostToolUse payload carries `tool_input` AND `tool_response`, and a
# Write's `content` can itself contain the text `"file_path": "..."` — editing this very file
# would do it. Taking the FIRST match keeps the real key.
_kh_str() {  # _kh_str <key> — prints the JSON string value, empty if absent
  printf '%s' "$INPUT" | tr '\n\r\t' '   ' \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed 's/^[^:]*:[[:space:]]*"//; s/"$//'
}

# A brain agents directory identifies itself by CONTENT, not by name. Gating on the name alone
# would drag in every project's `.claude/agents/`, whose definitions carry no KERNEL block and
# would all be reported as "missing KERNEL block" — a false positive storm in repos that have
# nothing to do with this plugin. Requiring at least one existing block means the check fires
# only where the discipline is already in force.
_kh_is_kernel_dir() {  # _kh_is_kernel_dir <dir>
  [ -d "$1" ] || return 1
  [ "$(basename "$1")" = "agents" ] || return 1
  grep -l '^## KERNEL-BEGIN' "$1"/*.md >/dev/null 2>&1
}

# Runs the checker and prints findings to the caller's chosen channel. Not being able to RUN the
# check is reported as a finding too, never swallowed: a drift detector that quietly stopped
# working reports the absence of evidence as evidence of absence — the exact failure mode
# kernel-check.sh's own zero-file guard exists to prevent.
_kh_run() {  # _kh_run <dir> — 0 = clean, 1 = findings (printed on stdout)
  if [ ! -x "$CHECKER" ]; then
    echo "kernel-check-hook: checker missing or not executable: $CHECKER — KERNEL drift is NOT being checked."
    return 1
  fi
  _kh_out="$("$CHECKER" "$1" 2>&1)" && return 0
  printf '%s\n' "$_kh_out"
  return 1
}

case "$(_kh_str hook_event_name)" in
  SessionStart)
    # No argument in normal use: kernel-check.sh defaults to its own ../agents, which resolves
    # correctly from a repo checkout and from an installed plugin cache alike.
    findings="$(_kh_run "${KERNEL_CHECK_DIR:-$HERE/../agents}")" || printf '%s\n' "$findings"
    exit 0
    ;;
  PostToolUse)
    TARGET="$(_kh_str file_path)"
    [ -n "$TARGET" ] || TARGET="$(_kh_str notebook_path)"
    case "$TARGET" in *.md) ;; *) exit 0 ;; esac
    DIR="$(dirname "$TARGET")"
    _kh_is_kernel_dir "$DIR" || exit 0
    findings="$(_kh_run "$DIR")" && exit 0
    printf '%s\n' "$findings" >&2
    exit 2
    ;;
esac

exit 0
