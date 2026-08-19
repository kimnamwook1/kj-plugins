#!/usr/bin/env bash
# 워크트리 트랙 1개 기동 — orca worktree create 의 함정 3개를 보정한다.
#   1) 브랜치가 워크트리명 그대로 만들어진다 → <type>/<name> 으로 리네임
#   2) --agent 없으면 터미널이 빈 셸로 남는다 → claude 지정
#   3) gitignore 된 CLAUDE.local.md 가 워크트리에 안 따라간다 → 본체로 심볼릭 링크
#
# 사용: spawn-track.sh <repo-selector> <worktree-name> <type> <브리프경로> [본체경로]
#   repo-selector : orca 형식 (id:<uuid> · name:<이름> · path:<경로>)
#   worktree-name : <TICKET>-<slug>  예) RSS-137-save-path-migration
#   type          : 커밋 타입 어휘  예) feat fix refactor docs chore
set -euo pipefail

[ $# -ge 4 ] || { echo "usage: $0 <repo-selector> <worktree-name> <type> <brief-path> [main-repo-path]" >&2; exit 2; }
REPO=$1 NAME=$2 TYPE=$3 BRIEF=$4
MAIN=${5:-$(git rev-parse --show-toplevel)}

[ -f "$BRIEF" ] || { echo "브리프 없음: $BRIEF" >&2; exit 1; }

orca worktree create --repo "$REPO" --name "$NAME" --base-branch main --no-parent \
  --agent claude --prompt "브리프 파일을 먼저 읽어라: $BRIEF — 그 브리프대로 작업한다. 브리프의 🔴 제약(라이브 쓰기 금지 · pkill 금지 · 타 트랙 소유 라인 금지 · push 금지)을 반드시 지켜라. 끝나면 SendMessage 로 PM 에 보고해라." \
  --json > /dev/null

# orca 는 <repo-parent>/.worktrees/<repo-name>/<name> 에 만든다. 경로는 git 에 직접 묻는다.
WT=$(git -C "$MAIN" worktree list --porcelain | awk '/^worktree /{p=$2} p ~ /\/'"$NAME"'$/{print p; exit}')
[ -n "$WT" ] || { echo "워크트리 경로를 못 찾았다: $NAME" >&2; exit 1; }

git -C "$WT" branch -m "$TYPE/$NAME"
[ -f "$MAIN/CLAUDE.local.md" ] && ln -sfn "$MAIN/CLAUDE.local.md" "$WT/CLAUDE.local.md"

echo "$NAME  ->  $(git -C "$WT" rev-parse --abbrev-ref HEAD)  @ $WT"
