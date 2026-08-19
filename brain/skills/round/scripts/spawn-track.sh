#!/usr/bin/env bash
# 워크트리 트랙 1개 기동 — orca worktree create 의 함정 3개를 보정한다.
#   1) 브랜치가 워크트리명 그대로 만들어진다 → <type>/<name> 으로 리네임
#   2) 에이전트를 안 붙이면 터미널이 빈 셸로 남는다 → terminal create 로 명령 지정
#   3) gitignore 된 CLAUDE.local.md 가 워크트리에 안 따라간다 → 본체로 심볼릭 링크
#
# 사용: spawn-track.sh <repo-selector> <worktree-name> <type> <브리프경로> [본체경로] [agent]
#   repo-selector : orca 형식 (id:<uuid> · name:<이름> · path:<경로>)
#   worktree-name : <TICKET>-<slug>  예) RSS-137-save-path-migration
#   type          : 커밋 타입 어휘  예) feat fix refactor docs chore
#   본체경로       : 생략 시 현재 레포 최상위
#   agent         : 기본 claude. codex 등 가능. `claude:coder` 처럼 <agent>:<프로필> 로
#                   주면 CC 세션 프로필(brain agents/)을 붙인다.
#
# 출력 마지막 줄 = `<name>  ->  <branch>  @ <path>`.
#   정리(§9)는 여기 나온 **경로**로 셀렉터를 만든다 — `path:<path>` 는 브랜치를 리네임해도
#   안 변한다. `branch:` 셀렉터는 리네임 전후가 갈리므로 쓰지 않는다.
set -euo pipefail

[ $# -ge 4 ] || { echo "usage: $0 <repo-selector> <worktree-name> <type> <brief-path> [main-repo-path] [agent]" >&2; exit 2; }
REPO=$1 NAME=$2 TYPE=$3 BRIEF=$4
MAIN=${5:-$(git rev-parse --show-toplevel)}
AGENT_SPEC=${6:-claude}

[ -f "$BRIEF" ] || { echo "브리프 없음: $BRIEF" >&2; exit 1; }

# agent 스펙 분해 — <agent>[:<프로필>]
AGENT=${AGENT_SPEC%%:*}
PROFILE=""
case "$AGENT_SPEC" in *:*) PROFILE=${AGENT_SPEC#*:} ;; esac

PROMPT="브리프 파일을 먼저 읽어라: $BRIEF — 그 브리프대로 작업한다. 브리프의 🔴 제약(라이브 쓰기 금지 · pkill 금지 · 타 트랙 소유 라인 금지 · push 금지)을 반드시 지켜라. 끝나면 SendMessage 로 PM 에 보고해라."

orca worktree create --repo "$REPO" --name "$NAME" --base-branch main --no-parent --json > /dev/null

# orca 생성은 즉시 끝나지 않을 수 있다 — 경로가 git 에 등록될 때까지 폴링(최대 20초).
WT=""
i=0
while [ $i -lt 40 ]; do
  WT=$(git -C "$MAIN" worktree list --porcelain | awk '/^worktree /{p=$2} p ~ /\/'"$NAME"'$/{print p; exit}')
  [ -n "$WT" ] && break
  sleep 0.5
  i=$((i + 1))
done
[ -n "$WT" ] || { echo "워크트리 경로를 못 찾았다(20초 대기 후): $NAME" >&2; exit 1; }

git -C "$WT" branch -m "$TYPE/$NAME"
[ -f "$MAIN/CLAUDE.local.md" ] && ln -sfn "$MAIN/CLAUDE.local.md" "$WT/CLAUDE.local.md"

# 에이전트 기동 — worktree create --agent 는 CLI 인자를 못 넘기므로 terminal create 로 붙인다.
if [ "$AGENT" = "claude" ] && [ -n "$PROFILE" ]; then
  CMD="claude --agent $PROFILE $(printf '%q' "$PROMPT")"
else
  CMD="$AGENT $(printf '%q' "$PROMPT")"
fi
orca terminal create --worktree "path:$WT" --title "$NAME" --command "$CMD" --json > /dev/null

echo "$NAME  ->  $(git -C "$WT" rev-parse --abbrev-ref HEAD)  @ $WT"
