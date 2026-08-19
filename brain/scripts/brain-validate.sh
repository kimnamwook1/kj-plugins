#!/bin/bash
# brain-validate.sh — brain 0.3.0 스키마 린터 (볼트 모드 | 레포 모드)
#
# Usage:
#   brain-validate.sh <vault-root> [--strict]          # 볼트 모드 (기본)
#   brain-validate.sh <repo-root> --repo [--strict]    # 레포 모드
#
# 볼트 모드 (스키마 정본: brain/docs/memory.md):
#   sessions/*.md   frontmatter 5키(status project updated related_ticket cc_session_ids)
#                   · status 어휘 active|parked|done · 신키(unknown key)
#                   · Progress 헤딩 "### YYYY-MM-DD HH:MM (started|resumed|parked|completed)"
#                   · Progress 카테고리 "- done" "- learned" "- next"만 · next 하위 1줄만
#   memory/*.md     frontmatter 4키(summary scope kind updated) · kind 어휘 fact|policy
#                   · 신키 · summary 비어있음/100자 초과/백틱·따옴표 · "## Insight"/"## Why" 절 부재
#   memory/_index.md  줄 형식 "- [[stem]] (scope) — summary" · dangling stem · 커버리지
#   전 스캔 .md     오염: "[Image #N]" · "<!--" (코드펜스 내부는 스킵)
#
# 레포 모드 (어휘 정본: brain/docs/project-docs.md):
#   docs/**/*.md    frontmatter 2키(status updated) · status 어휘 draft|approved · 신키
#   docs/develop/policy/    파일명 POL-NNNNN-<kebab>.md
#   docs/develop/feature/   파일명 FEAT-NNNNN-<kebab>.md
#   docs/adr/               파일명 ADR-NNNNN-<kebab>.md · 연번 중복 · 연번 gap(1..max 연속)
#   docs/business/COMPLIANCE.md   존재 시 "## Legal Sources" 절 필수
#   전 스캔 .md     오염 (볼트 모드와 동일)
#
# 출력: finding = "file:line: message" · 스캔 계수 상시 출력(0도 보고 — fail-visible)
# Exit: 0 = 실행 완료 (--strict 없으면 finding이 있어도 0)
#       1 = --strict + finding 1건 이상
#       2 = usage · 환경 오류
#
# 이식성: macOS 재고 bash 3.2 + POSIX 도구만(awk find grep sort uniq cut).
# 연관 배열·mapfile·grep -P·jq 금지. LC_ALL=C 고정 — sort 집합 비교의 바이트 안정
# 및 로케일 무관 정규식. 볼트 경로는 find의 start path로만 전달(패턴에 결합 금지).

set -u
LC_ALL=C; export LC_ALL
TAB=$(printf '\t')

usage() {
  echo "usage: brain-validate.sh <vault-root|repo-root> [--repo] [--strict]" >&2
  exit 2
}

ROOT=""; MODE=vault; STRICT=0
for arg in "$@"; do
  case "$arg" in
    --repo)   MODE=repo ;;
    --strict) STRICT=1 ;;
    -*)       usage ;;
    *)        [ -n "$ROOT" ] && usage; ROOT=$arg ;;
  esac
done
[ -n "$ROOT" ] || usage
[ -d "$ROOT" ] || { echo "brain-validate: not a directory: $ROOT" >&2; exit 2; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/brain-validate.XXXXXX") || exit 2
trap 'rm -rf "$TMP"' EXIT
FINDINGS="$TMP/findings"
: > "$FINDINGS"

# ---------------------------------------------------------------- 오염 패턴
# 코드펜스(``` 로 시작하는 줄) 내부는 스킵. finding 2종:
#   [Image #N] 잔존물 · HTML 주석 시작 토큰 <!--
check_contamination() {
  awk '
    /^[ \t]*```/ { fence = !fence; next }
    fence        { next }
    /\[Image #[0-9]+\]/ { print FILENAME ":" NR ": contamination: [Image #N] artifact" }
    /<!--/              { print FILENAME ":" NR ": contamination: HTML comment" }
  ' "$1" >> "$FINDINGS"
}

# ---------------------------------------------------------------- 세션 노트
check_session() {
  awk '
    NR == 1 && /^---[ \t]*$/ { fm = 1; next }
    fm == 1 {
      if ($0 ~ /^---[ \t]*$/) { fm = 2; next }
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) {
        key = $0; sub(/:.*/, "", key)
        val = $0; sub(/^[^:]*:/, "", val); sub(/^[ \t]*/, "", val)
        seen[key] = 1
        if (key !~ /^(status|project|updated|related_ticket|cc_session_ids)$/)
          print FILENAME ":" NR ": session: unknown key: " key
        if (key == "status") {
          v = val; sub(/[ \t]*#.*/, "", v); sub(/[ \t]*$/, "", v)
          if (v !~ /^(active|parked|done)$/)
            print FILENAME ":" NR ": session: bad status: " v " (want active|parked|done)"
        }
      }
      next
    }
    /^## / { inprog = ($0 ~ /^## Progress[ \t]*$/); innext = 0; next }
    inprog && /^### / {
      innext = 0
      if ($0 !~ /^### [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:[0-9][0-9] \((started|resumed|parked|completed)\)$/)
        print FILENAME ":" NR ": session: bad Progress heading: " $0
      next
    }
    inprog && /^- / {
      if ($0 == "- next") { innext = 1; nsub = 0 }
      else {
        innext = 0
        if ($0 != "- done" && $0 != "- learned") {
          c = $0; sub(/^- /, "", c)
          print FILENAME ":" NR ": session: bad Progress category: " c " (want done|learned|next)"
        }
      }
      next
    }
    inprog && innext && /^[ \t]+- / {
      nsub++
      if (nsub == 2) print FILENAME ":" NR ": session: next has more than 1 sub-bullet"
      next
    }
    END {
      if (fm != 2) print FILENAME ":1: session: missing frontmatter"
      else {
        n = split("status project updated related_ticket cc_session_ids", req, " ")
        for (i = 1; i <= n; i++)
          if (!(req[i] in seen)) print FILENAME ":1: session: missing key: " req[i]
      }
    }
  ' "$1" >> "$FINDINGS"
}

# ---------------------------------------------------------------- memory 노트
check_memory() {
  awk '
    NR == 1 && /^---[ \t]*$/ { fm = 1; next }
    fm == 1 {
      if ($0 ~ /^---[ \t]*$/) { fm = 2; next }
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) {
        key = $0; sub(/:.*/, "", key)
        val = $0; sub(/^[^:]*:/, "", val); sub(/^[ \t]*/, "", val)
        seen[key] = 1
        if (key !~ /^(summary|scope|kind|updated)$/)
          print FILENAME ":" NR ": memory: unknown key: " key
        if (key == "kind") {
          v = val; sub(/[ \t]*#.*/, "", v); sub(/[ \t]*$/, "", v)
          if (v !~ /^(fact|policy)$/)
            print FILENAME ":" NR ": memory: bad kind: " v " (want fact|policy)"
        }
        if (key == "summary") {
          v = val; sub(/[ \t]*$/, "", v)
          if (v == "") print FILENAME ":" NR ": memory: empty summary"
          # 문자 수 = 바이트에서 UTF-8 연속바이트(0x80-0xBF) 제거 후 길이. LC_ALL=C 전제.
          c = v; gsub(/[\200-\277]/, "", c)
          if (length(c) > 100)
            print FILENAME ":" NR ": memory: summary too long: " length(c) " chars (max 100)"
          # YAML 파손 검사 (memory.md §memory 노트 스키마).
          # 따옴표로 감싼 값은 정상 — 여는 따옴표가 있으면 닫는 따옴표를 요구하고,
          # 감싸지 않은 plain scalar 에만 indicator·": "·" #" 를 금지한다.
          q = substr(v, 1, 1)
          if (q == "\"" || q == "\047") {
            if (length(v) < 2 || substr(v, length(v), 1) != q)
              print FILENAME ":" NR ": memory: summary opens with " q " but does not close it (broken YAML scalar)"
          } else {
            if (v ~ /^[`[{&*!|>%@]/)
              print FILENAME ":" NR ": memory: summary starts with YAML indicator (breaks plain scalar): " q
            if (v ~ /: /)
              print FILENAME ":" NR ": memory: summary contains \": \" unquoted (breaks plain scalar)"
            if (v ~ / #/)
              print FILENAME ":" NR ": memory: summary contains \" #\" unquoted (parsed as YAML comment)"
          }
        }
      }
      next
    }
    /^## Insight[ \t]*$/ { insight = 1 }
    /^## Why[ \t]*$/     { why = 1 }
    END {
      if (fm != 2) print FILENAME ":1: memory: missing frontmatter"
      else {
        n = split("summary scope kind updated", req, " ")
        for (i = 1; i <= n; i++)
          if (!(req[i] in seen)) print FILENAME ":1: memory: missing key: " req[i]
      }
      if (!insight) print FILENAME ":1: memory: missing section: ## Insight"
      if (!why)     print FILENAME ":1: memory: missing section: ## Why"
    }
  ' "$1" >> "$FINDINGS"
}

# ---------------------------------------------------------------- _index.md
# $IDX 형식 검사 + stem 추출 → dangling($MDIR 에 파일 없음) · 커버리지(노트가 인덱스에 없음)
check_index() {
  STEMS="$TMP/stems"
  : > "$STEMS"
  awk -v stems="$STEMS" '
    NF == 0 { next }
    /^- \[\[[^]]+\]\] \([^)]+\) — .+/ {
      stem = $0
      sub(/^- \[\[/, "", stem); sub(/\]\].*/, "", stem)
      print NR "\t" stem >> stems
      next
    }
    { print FILENAME ":" NR ": index: bad line format (want - [[stem]] (scope) — summary)" }
  ' "$IDX" >> "$FINDINGS"

  while IFS="$TAB" read -r ln stem; do
    [ -f "$MDIR/$stem.md" ] || echo "$IDX:$ln: index: dangling stem: [[$stem]]" >> "$FINDINGS"
  done < "$STEMS"

  cut -f2 "$STEMS" | LC_ALL=C sort -u > "$TMP/stems.sorted"
  while IFS= read -r f; do
    stem=${f##*/}; stem=${stem%.md}
    grep -qxF -- "$stem" "$TMP/stems.sorted" \
      || echo "$IDX:1: index: not in index: [[$stem]]" >> "$FINDINGS"
  done < "$TMP/mem.list"
}

# ---------------------------------------------------------------- 레포 docs
check_doc() {
  awk '
    NR == 1 && /^---[ \t]*$/ { fm = 1; next }
    fm == 1 {
      if ($0 ~ /^---[ \t]*$/) { fm = 2; next }
      if ($0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) {
        key = $0; sub(/:.*/, "", key)
        val = $0; sub(/^[^:]*:/, "", val); sub(/^[ \t]*/, "", val)
        seen[key] = 1
        if (key !~ /^(status|updated)$/)
          print FILENAME ":" NR ": doc: unknown key: " key
        if (key == "status") {
          v = val; sub(/[ \t]*#.*/, "", v); sub(/[ \t]*$/, "", v)
          if (v !~ /^(draft|approved)$/)
            print FILENAME ":" NR ": doc: bad status: " v " (want draft|approved)"
        }
      }
      next
    }
    END {
      if (fm != 2) print FILENAME ":1: doc: missing frontmatter"
      else {
        n = split("status updated", req, " ")
        for (i = 1; i <= n; i++)
          if (!(req[i] in seen)) print FILENAME ":1: doc: missing key: " req[i]
      }
    }
  ' "$1" >> "$FINDINGS"
}

# $1=디렉토리 $2=접두(POL|FEAT|ADR) — 파일명 규칙 검사. NAME_N에 계수를 남긴다.
# 유효 파일명 목록은 $TMP/names.$2.list (ADR 연번 검사가 재사용).
check_names() {
  NAME_N=0
  : > "$TMP/names.$2.list"
  [ -d "$1" ] || return 0
  find "$1" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort > "$TMP/dir.list"
  while IFS= read -r f; do
    NAME_N=$((NAME_N + 1))
    base=${f##*/}
    if printf '%s\n' "$base" | grep -Eq "^$2-[0-9]{5}-[a-z0-9]+(-[a-z0-9]+)*\.md$"; then
      echo "$base" >> "$TMP/names.$2.list"
    else
      echo "$f:1: doc: bad filename: want $2-NNNNN-<kebab>.md" >> "$FINDINGS"
    fi
  done < "$TMP/dir.list"
}

# ---------------------------------------------------------------- 모드 실행
run_vault() {
  SDIR="$ROOT/sessions"; MDIR="$ROOT/memory"; IDX="$MDIR/_index.md"
  SESS_N=0; MEM_N=0; IDX_N=0

  if [ -d "$SDIR" ]; then
    find "$SDIR" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort > "$TMP/sess.list"
    while IFS= read -r f; do
      SESS_N=$((SESS_N + 1))
      check_session "$f"
      check_contamination "$f"
    done < "$TMP/sess.list"
  fi

  if [ -d "$MDIR" ]; then
    find "$MDIR" -maxdepth 1 -type f -name '*.md' ! -name '_index.md' | LC_ALL=C sort > "$TMP/mem.list"
    while IFS= read -r f; do
      MEM_N=$((MEM_N + 1))
      check_memory "$f"
      check_contamination "$f"
    done < "$TMP/mem.list"

    if [ -f "$IDX" ]; then
      IDX_N=1
      check_index
      check_contamination "$IDX"
    else
      echo "$IDX:1: index: _index.md missing" >> "$FINDINGS"
    fi
  fi

  COUNTS="scanned: sessions=$SESS_N memory=$MEM_N index=$IDX_N"
}

run_repo() {
  DDIR="$ROOT/docs"
  DOCS_N=0; POL_N=0; FEAT_N=0; ADR_N=0

  if [ -d "$DDIR" ]; then
    find "$DDIR" -type f -name '*.md' | LC_ALL=C sort > "$TMP/docs.list"
    while IFS= read -r f; do
      DOCS_N=$((DOCS_N + 1))
      check_doc "$f"
      check_contamination "$f"
    done < "$TMP/docs.list"

    check_names "$DDIR/develop/policy" POL;   POL_N=$NAME_N
    check_names "$DDIR/develop/feature" FEAT; FEAT_N=$NAME_N
    check_names "$DDIR/adr" ADR;              ADR_N=$NAME_N

    # ADR 연번 — 유효 파일명에서 번호 추출 → 중복 · gap(1..max 연속이어야 함)
    : > "$TMP/adrnums"
    while IFS= read -r base; do
      n=${base#ADR-}; n=${n%%-*}
      echo "$n" >> "$TMP/adrnums"
    done < "$TMP/names.ADR.list"
    sort "$TMP/adrnums" | uniq -d | while IFS= read -r n; do
      echo "$DDIR/adr:1: doc: ADR number duplicated: $n" >> "$FINDINGS"
    done
    sort -n -u "$TMP/adrnums" | awk -v pre="$DDIR/adr" '
      { n = $1 + 0
        for (e = (expect ? expect : 1); e < n; e++)
          printf "%s:1: doc: ADR sequence gap: %05d missing\n", pre, e
        expect = n + 1 }
    ' >> "$FINDINGS"

    comp="$DDIR/business/COMPLIANCE.md"
    if [ -f "$comp" ]; then
      grep -q '^## Legal Sources' "$comp" \
        || echo "$comp:1: doc: missing section: ## Legal Sources" >> "$FINDINGS"
    fi
  fi

  COUNTS="scanned: docs=$DOCS_N policy=$POL_N feature=$FEAT_N adr=$ADR_N"
}

if [ "$MODE" = vault ]; then run_vault; else run_repo; fi

cat "$FINDINGS"
echo "$COUNTS"
NFOUND=$(wc -l < "$FINDINGS" | tr -d ' ')
echo "findings: $NFOUND"

if [ "$STRICT" -eq 1 ] && [ "$NFOUND" -gt 0 ]; then exit 1; fi
exit 0
