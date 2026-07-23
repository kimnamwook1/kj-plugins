#!/usr/bin/env bash
# ⚠ OPT-IN — inactive unless wired into hooks.json. Wire it into PreToolUse (matcher: Edit|Write)
#   only when you want the "PM (main session) does not write" rule enforced by machinery rather
#   than by discipline.
#
# force-delegate.sh — blocks file edits (Edit/Write) in the main session (PM) to force delegation
#   to Agent subagents (workers).
#   (Exploration/execution — Grep/Glob/Bash etc. — stays free in main; the PreToolUse matcher in
#   settings catches Edit|Write only.)
#
# How it decides: if the input JSON the PreToolUse hook receives on stdin has a top-level
#   "agent_id" key, the call came from a subagent spawned via the Agent tool → pass (exit 0).
#   If absent, it is the main session (PM) → block (exit 2 + guidance).
# Current model: vault content writes are performed by the scribe worker (a subagent), so they
#   pass via agent_id and were never blocked to begin with. The only legitimate direct writes
#   left in main (PM) are harness settings (~/.claude) and the two config files init step 2
#   writes at the project root — CLAUDE.md (2a, shared block) and CLAUDE.local.md (2b) — the
#   exception paths below cover exactly those.
# Exception paths: ~/.claude · vault paths · */CLAUDE.md · */CLAUDE.local.md. The canonical vault path is the
#   vault-root value in the project's CLAUDE.local.md, but this hook does not read that value —
#   it approximates with the default vault location pattern, so if your vault-root differs,
#   adjust the case patterns below as well.
# Escape hatch: env var FORCE_DELEGATE_OFF=1 → unconditional pass (temporarily lifts the policy).
# Caution: agent_id is an unofficial (undocumented) field — observed empirically on CLI v2.1.178.
#   Re-check after upgrades. (Even then, FORCE_DELEGATE_OFF=1 restores operation immediately.)

set -u

if [ "${FORCE_DELEGATE_OFF:-}" = "1" ]; then
  exit 0
fi

input="$(cat)"

# Subagent (agent_id present) → pass
is_sub=0
if command -v jq >/dev/null 2>&1; then
  [ "$(printf '%s' "$input" | jq -r 'has("agent_id")' 2>/dev/null)" = "true" ] && is_sub=1
else
  printf '%s' "$input" | grep -q '"agent_id"[[:space:]]*:' && is_sub=1
fi
[ "$is_sub" -eq 1 ] && exit 0

# Legitimate direct writes from main (PM) — harness settings (~/.claude) · vault paths (canonical
# source = the vault-root value in CLAUDE.local.md; the hook cannot read that value, so it
# approximates with the default vault location — adjust the patterns if yours differs) ·
# CLAUDE.md + CLAUDE.local.md (init steps 2a/2b).
if command -v jq >/dev/null 2>&1; then
  fpath="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
  case "$fpath" in
    "$HOME"/.claude/*|"$HOME"/Documents/Obsidian/*|*/CLAUDE.md|*/CLAUDE.local.md) exit 0 ;;
  esac
fi

# Main session → block (the matcher only sends Edit|Write, so no per-tool branching is needed)
echo "[force-delegate] File edits (Edit/Write) from the main session are blocked. Spawn a subagent (worker) with the Agent tool and delegate — this policy conserves main-context tokens. Exploration (Grep/Glob/Bash) remains available directly in main. Edits to ~/.claude, vault paths, CLAUDE.md, and CLAUDE.local.md are allowed. If you really must edit another file from main, start the session with FORCE_DELEGATE_OFF=1." >&2
exit 2
