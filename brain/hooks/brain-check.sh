#!/usr/bin/env bash
# brain-check.sh [--quiet] — 블록 대조 통합 검사기 (brain 0.3.0 · 전서 §6.1·§6.2·§3.1)
#
# 검사 ① AGENTS.md ↔ CLAUDE.md 의 <!-- brain:begin --> … <!-- brain:end --> 마커 블록
#   바이트 동일성 (CR 제거 후 비교 — CRLF 편집기가 만드는 가짜 드리프트 배제).
#   대상 레포 = 시작 디렉토리에서 상향 탐색, 두 파일이 같이 있는 최근접 디렉토리.
#   두 파일 모두 마커가 없으면 skip — init 전 정상이므로 finding 이 아니다.
#   한쪽에만 블록이 있으면 finding — init/스킬은 두 파일을 항상 동시 갱신하므로
#   편측 존재는 "init 전"이 아니라 사후 손상이다.
# 검사 ② 플러그인 agents/*.md 의 ## KERNEL-BEGIN … ## KERNEL-END 블록 동일성.
#   기준 = 정렬 순 첫 정상 블록. 0파일 스캔 = finding — 빈 디렉토리가 "전부 통과"로
#   읽히는 공허참 방어.
#
# 출력: file:line: message. 통과 시 무음 (--quiet 여부 무관) — SessionStart stdout 은
#   모든 세션의 컨텍스트에 주입되므로 "OK" 한 줄도 영구 토큰세다. --quiet 는 CLI 모드에서
#   findings 와 함께 나가는 스캔 계수 요약 1줄(stderr)까지 끄는 스위치.
#
# 이벤트 어댑터 내장 — 별도 어댑터 파일 금지(파일 최소). stdin 이 파이프이고
# hook_event_name 이 읽히면 훅 모드, 아니면 CLI 모드.
#   SessionStart — findings stdout + exit 0. SessionStart 는 차단 불가이며 stdout 이
#     모델 컨텍스트 주입 채널이다 (exit 2 의 stderr 는 사용자에게만 보여 모델이 못 본다).
#   PostToolUse — 대상 파일이 AGENTS.md·CLAUDE.md·agents/*.md 일 때만 검사.
#     쓰기는 이미 일어나 차단이 아닌 사후 피드백: findings stderr + exit 2 가
#     "지금 복구하라"를 모델에 전달하는 유일한 채널이다.
#     이때 심판 대상은 방금 편집된 그 사본 — 상향 탐색·agents 스캔 모두 편집 파일의
#     디렉토리에서 시작한다 (다른 checkout/캐시가 아니라 편집본을 심판).
#     agents/*.md 는 이름이 아니라 내용으로 식별 — KERNEL 블록이 하나도 없는 디렉토리
#     (일반 프로젝트의 .claude/agents/)를 "블록 없음" 오탐 폭풍으로 뒤덮지 않는다.
#   stdin JSON 추출은 jq 없이 grep/sed 첫 매치 — Write 의 content 문자열 안에
#     "file_path": … 텍스트가 들어 있어도(이 파일 자신을 쓰는 경우) 진짜 키가 먼저 온다.
#
# CLI 모드: 통과 exit 0 무음 · findings stdout + exit 1 — 수동 점검·selftest 용.
# 이스케이프 해치: BRAIN_CHECK_OFF=1 → 무조건 통과.
# 이식성: macOS 기본 bash 3.2 + POSIX 도구(grep/sed/tr/head/cut/dirname/basename) ·
#   의존성 0 · jq 금지.

set -u
LC_ALL=C
export LC_ALL

[ "${BRAIN_CHECK_OFF:-}" = "1" ] && exit 0

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 0

INPUT=""
[ -t 0 ] || INPUT="$(cat 2>/dev/null || true)"

_bc_str() {  # _bc_str <key> — stdin JSON 문자열 값, 첫 매치 (없으면 빈 문자열)
  printf '%s' "$INPUT" | tr '\n\r\t' '   ' \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed 's/^[^:]*:[[:space:]]*"//; s/"$//'
}

EVENT=""
[ -n "$INPUT" ] && EVENT="$(_bc_str hook_event_name)"

START_DIR="$PWD"
AGENTS_DIR="$HERE/../agents"

if [ "$EVENT" = "PostToolUse" ]; then
  TARGET="$(_bc_str file_path)"
  [ -n "$TARGET" ] || TARGET="$(_bc_str notebook_path)"
  [ -n "$TARGET" ] || exit 0
  case "$TARGET" in /*) ;; *) TARGET="$PWD/$TARGET" ;; esac
  TDIR="$(dirname "$TARGET")"
  RELEVANT=0
  case "$(basename "$TARGET")" in
    AGENTS.md|CLAUDE.md)
      RELEVANT=1
      START_DIR="$TDIR"
      ;;
    *.md)
      if [ "$(basename "$TDIR")" = "agents" ] \
         && grep -l '^## KERNEL-BEGIN' "$TDIR"/*.md >/dev/null 2>&1; then
        RELEVANT=1
        AGENTS_DIR="$TDIR"
        START_DIR="$TDIR"
      fi
      ;;
  esac
  [ "$RELEVANT" = "1" ] || exit 0
fi

FINDINGS=""
N_FINDINGS=0
_bc_find() {  # _bc_find "<file>:<line>: <message>"
  FINDINGS="${FINDINGS}$1
"
  N_FINDINGS=$((N_FINDINGS + 1))
}

_bc_line() {  # _bc_line <file> <fixed-string> — CR 제거 후 첫 매치 줄 번호, 없으면 빈
  tr -d '\r' < "$1" | grep -nF -- "$2" | head -1 | cut -d: -f1
}

# ── 검사 ① AGENTS.md ↔ CLAUDE.md 마커 블록 ─────────────────────────────────
_bc_marker_block() {  # _bc_marker_block <file> — brain 마커 블록 (CR 제거, 마커 줄 포함)
  tr -d '\r' < "$1" | sed -n '/<!-- brain:begin -->/,/<!-- brain:end -->/p'
}

REPO=""
_d="$START_DIR"
while :; do
  if [ -f "$_d/AGENTS.md" ] && [ -f "$_d/CLAUDE.md" ]; then REPO="$_d"; break; fi
  [ "$_d" = "/" ] && break
  _d="$(dirname "$_d")"
done

PAIR=0
if [ -n "$REPO" ]; then
  A="$REPO/AGENTS.md"
  C="$REPO/CLAUDE.md"
  A_BEG="$(_bc_line "$A" '<!-- brain:begin -->')"
  C_BEG="$(_bc_line "$C" '<!-- brain:begin -->')"
  if [ -n "$A_BEG" ] || [ -n "$C_BEG" ]; then
    PAIR=1
    if [ -z "$A_BEG" ]; then
      _bc_find "$A:1: brain 마커 블록 없음 — CLAUDE.md 에는 있다 (두 파일 동시 갱신이 규약)"
    elif [ -z "$C_BEG" ]; then
      _bc_find "$C:1: brain 마커 블록 없음 — AGENTS.md 에는 있다 (두 파일 동시 갱신이 규약)"
    else
      A_END="$(_bc_line "$A" '<!-- brain:end -->')"
      C_END="$(_bc_line "$C" '<!-- brain:end -->')"
      PAIR_OK=1
      if [ -z "$A_END" ]; then
        _bc_find "$A:$A_BEG: brain:begin 만 있고 brain:end 가 없다 — 블록 파손"
        PAIR_OK=0
      fi
      if [ -z "$C_END" ]; then
        _bc_find "$C:$C_BEG: brain:begin 만 있고 brain:end 가 없다 — 블록 파손"
        PAIR_OK=0
      fi
      if [ "$PAIR_OK" = "1" ] \
         && [ "$(_bc_marker_block "$A")" != "$(_bc_marker_block "$C")" ]; then
        _bc_find "$C:$C_BEG: brain 블록이 AGENTS.md:$A_BEG 블록과 바이트 불일치 — 두 파일을 동시 갱신해 복구"
      fi
    fi
  fi
fi

# ── 검사 ② agents/*.md KERNEL 블록 ─────────────────────────────────────────
AGENTS_DIR="$(cd "$AGENTS_DIR" 2>/dev/null && pwd || printf '%s' "$AGENTS_DIR")"

_bc_kernel_block() {  # _bc_kernel_block <file> — KERNEL 블록 (CR 제거, 마커 줄 포함)
  tr -d '\r' < "$1" | sed -n '/^## KERNEL-BEGIN$/,/^## KERNEL-END$/p'
}

N_AGENT=0
REF_BLOCK=""
REF_FILE=""
for _f in "$AGENTS_DIR"/*.md; do
  [ -f "$_f" ] || continue
  N_AGENT=$((N_AGENT + 1))
  K_BEG="$(tr -d '\r' < "$_f" | grep -n '^## KERNEL-BEGIN$' | head -1 | cut -d: -f1)"
  K_END="$(tr -d '\r' < "$_f" | grep -n '^## KERNEL-END$' | head -1 | cut -d: -f1)"
  if [ -z "$K_BEG" ]; then
    _bc_find "$_f:1: KERNEL 블록 없음 (## KERNEL-BEGIN 부재)"
    continue
  fi
  if [ -z "$K_END" ]; then
    _bc_find "$_f:$K_BEG: KERNEL-BEGIN 만 있고 KERNEL-END 가 없다 — 블록 파손"
    continue
  fi
  _blk="$(_bc_kernel_block "$_f")"
  if [ -z "$REF_BLOCK" ]; then
    REF_BLOCK="$_blk"
    REF_FILE="$_f"
  elif [ "$_blk" != "$REF_BLOCK" ]; then
    _bc_find "$_f:$K_BEG: KERNEL 블록이 기준($REF_FILE)과 다르다 — 전 agent 동일 블록이 규약"
  fi
done

if [ "$N_AGENT" -eq 0 ]; then
  _bc_find "$AGENTS_DIR:0: 스캔된 agent .md 0개 — 빈 스캔은 통과가 아니라 결함 (공허참 방어)"
fi

# ── 채널·exit — 헤더의 이벤트별 계약 ────────────────────────────────────────
[ "$N_FINDINGS" -eq 0 ] && exit 0

case "$EVENT" in
  SessionStart)
    printf '%s' "$FINDINGS"
    exit 0
    ;;
  PostToolUse)
    printf '%s' "$FINDINGS" >&2
    exit 2
    ;;
  *)
    printf '%s' "$FINDINGS"
    if [ "$QUIET" != "1" ]; then
      printf 'brain-check: agents=%d marker-pair=%d findings=%d\n' \
        "$N_AGENT" "$PAIR" "$N_FINDINGS" >&2
    fi
    exit 1
    ;;
esac
