#!/bin/bash
# brain-selftest.sh — brain-validate.sh · brain-recall 전수 자가검증
#
# Usage: brain-selftest.sh          # 인자 없음
#
# mktemp 아래에 픽스처(정상 볼트·결함 볼트·인덱스 없는 볼트·정상 레포·결함 레포)를
# 짓고, 두 스크립트의 발화(finding·계수)와 침묵(정상 픽스처 findings: 0 · 코드펜스
# 내부 오염 무시)을 grep 으로 전수 assert 한다. 모든 검사 규칙마다 positive 픽스처 1개 이상.
#
# 출력: 실패 assert 는 "FAIL: ..." 1줄씩 · 마지막에 "asserts: P passed / F failed"
# Exit: 0 = 전 assert 통과 · 1 = assert 실패 1건 이상 · 2 = usage · 환경 오류
#
# 이식성: macOS 재고 bash 3.2 + POSIX 도구만. 의존성 0. 레포·볼트에 아무것도 쓰지 않는다.

set -u
LC_ALL=C; export LC_ALL

[ $# -eq 0 ] || { echo "usage: brain-selftest.sh" >&2; exit 2; }

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd) || exit 2
VALIDATE="$SCRIPT_DIR/brain-validate.sh"
RECALL="$SCRIPT_DIR/brain-recall"
[ -x "$VALIDATE" ] || { echo "brain-selftest: missing executable: $VALIDATE" >&2; exit 2; }
[ -x "$RECALL" ]   || { echo "brain-selftest: missing executable: $RECALL" >&2; exit 2; }

T=$(mktemp -d "${TMPDIR:-/tmp}/brain-selftest.XXXXXX") || exit 2
trap 'rm -rf "$T"' EXIT
OUT="$T/out"

PASS=0; FAIL=0
ok()  { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "FAIL: $1"; }

assert_has()  { # $1=file $2=fixed-string $3=desc
  if grep -qF -- "$2" "$1"; then ok; else bad "$3 (missing: $2)"; fi
}
assert_not()  { # $1=file $2=fixed-string $3=desc
  if grep -qF -- "$2" "$1"; then bad "$3 (unexpected: $2)"; else ok; fi
}
assert_exit() { # $1=got $2=want $3=desc
  if [ "$1" -eq "$2" ]; then ok; else bad "$3 (exit $1, want $2)"; fi
}

# ================================================================ 픽스처: 정상 볼트
V="$T/goodvault"
mkdir -p "$V/sessions" "$V/memory"

cat > "$V/sessions/kjp_20260813_rebuild.md" <<'EOF'
---
status: active
project: kjp
updated: 2026-08-13
related_ticket: KJP-12
cc_session_ids: [abc-123]
---
## Goal
빌드 검사기 3종을 0.3.0 스펙으로 신규 작성

## Recall
- 1건 · 200B 주입 (scope: kjp) · 절단 0건
- [[good-note]]

## To-Do
- [ ] brain-validate.sh 작성
- [x] 스키마 확정

## Progress
### 2026-08-13 15:30 (parked)
- done
  - 골격 작성 — brain/scripts/brain-validate.sh
- learned
  - matcher 누락 실수 → 추가로 복구
- next
  - selftest 픽스처부터
EOF

cat > "$V/memory/good-note.md" <<'EOF'
---
summary: 2026-08-13 obsidian cli가 조용히 fork한다 — flag로 막는다
scope: [kjp]
kind: fact
updated: 2026-08-13
---
## Insight
- obsidian cli는 기본으로 fork한다

## Why
- 실측 근거 file:1

```bash
# 코드펜스 내부 오염은 무시되어야 한다
grep '<!--' x
[Image #7]
```
EOF

cat > "$V/memory/org-note.md" <<'EOF'
---
summary: 2026-08-14 회사 공용 지식 예시 — 트리거와 주장
scope: [org]
kind: policy
updated: 2026-08-14
---
## Insight
- 회사 지식 주장

## Why
- 근거 file:2
EOF

cat > "$V/memory/_index.md" <<'EOF'
- [[good-note]] (kjp) — 2026-08-13 obsidian cli가 조용히 fork한다
- [[org-note]] (org) — 2026-08-14 회사 공용 지식 예시
EOF

# ================================================================ 픽스처: 결함 볼트
B="$T/badvault"
mkdir -p "$B/sessions" "$B/memory"

# 세션 결함: bad status · 신키 mood · related_ticket 누락 · bad Progress 헤딩(시각 없음)
# · bad 카테고리 output · next 하위 2줄
cat > "$B/sessions/kjp_20260101_bad1.md" <<'EOF'
---
status: wip
project: kjp
updated: 2026-01-01
cc_session_ids: [x]
mood: grim
---
## Progress
### 2026-01-01 (parked)
- output
  - 산출물
- next
  - 첫 줄
  - 둘째 줄
EOF

# 세션 결함: frontmatter 부재 + 오염 2종(펜스 밖)
cat > "$B/sessions/kjp_20260102_nofm.md" <<'EOF'
## Progress
[Image #3]
<!-- oops -->
EOF

# memory 결함: bad kind · 신키 related · ## Why 부재
cat > "$B/memory/bad-mem.md" <<'EOF'
---
summary: 2026 뭔가 주장
scope: [kjp]
kind: opinion
updated: 2026-01-01
related: [[other]]
---
## Insight
- 주장만 있다
EOF

# memory 결함: summary 비어있음
cat > "$B/memory/empty-summary.md" <<'EOF'
---
summary:
scope: [kjp]
kind: fact
updated: 2026-01-01
---
## Insight
- x

## Why
- y
EOF

# memory 결함: ## Insight 부재
cat > "$B/memory/no-insight.md" <<'EOF'
---
summary: 2026 인사이트 절이 없다
scope: [kjp]
kind: fact
updated: 2026-01-01
---
## Why
- y
EOF

# memory 결함: scope·kind 키 누락
cat > "$B/memory/missing-keys.md" <<'EOF'
---
summary: 2026 키가 모자란 노트
updated: 2026-01-01
---
## Insight
- x

## Why
- y
EOF

# memory 정상이지만 인덱스 미등재 → 커버리지 finding
cat > "$B/memory/not-in-index.md" <<'EOF'
---
summary: 2026 인덱스에 없는 노트
scope: [kjp]
kind: fact
updated: 2026-01-01
---
## Insight
- x

## Why
- y
EOF

# 인덱스 결함: dangling stem(ghost-note) · 형식 위반 줄 · not-in-index 미등재
cat > "$B/memory/_index.md" <<'EOF'
- [[bad-mem]] (kjp) — x
- [[empty-summary]] (kjp) — x
- [[no-insight]] (kjp) — x
- [[missing-keys]] (kjp) — x
- [[ghost-note]] (kjp) — 대상 파일이 없다
이 줄은 인덱스 형식이 아니다
EOF

# ================================================================ 픽스처: 인덱스 없는 볼트
NI="$T/noidxvault"
mkdir -p "$NI/memory"
cat > "$NI/memory/lone-note.md" <<'EOF'
---
summary: 2026 인덱스 없는 볼트의 노트
scope: [kjp]
kind: fact
updated: 2026-01-01
---
## Insight
- x

## Why
- y
EOF

# ================================================================ 픽스처: 정상 레포
R="$T/goodrepo"
mkdir -p "$R/docs/business" "$R/docs/develop/policy" "$R/docs/develop/feature" "$R/docs/adr"

cat > "$R/docs/business/PRD.md" <<'EOF'
---
status: draft
updated: 2026-08-13
---
# PRD
- 내용

```html
<!-- 코드펜스 내부 주석은 무시되어야 한다 -->
[Image #9]
```
EOF

cat > "$R/docs/business/COMPLIANCE.md" <<'EOF'
---
status: draft
updated: 2026-08-13
---
# COMPLIANCE

## Legal Sources
| 규범 | 구분 | 상태 | 시행·적용일 | 적용여부 | 적용근거 | 조문 | 하위법령 | 확인일 | 근거 URL |
EOF

cat > "$R/docs/develop/ARCHITECTURE.md" <<'EOF'
---
status: approved
updated: 2026-08-13
---
# ARCHITECTURE
- 구조
EOF

cat > "$R/docs/develop/policy/POL-00001-login.md" <<'EOF'
---
status: draft
updated: 2026-08-13
---
# POL-00001 login
- 정책
EOF

cat > "$R/docs/develop/feature/FEAT-00001-checkout.md" <<'EOF'
---
status: draft
updated: 2026-08-13
---
## FRD
- what

## TDC
- how
EOF

cat > "$R/docs/adr/ADR-00001-vault-flat.md" <<'EOF'
---
status: approved
updated: 2026-08-13
---
# ADR-00001
- 결정
EOF

cat > "$R/docs/adr/ADR-00002-two-keys.md" <<'EOF'
---
status: approved
updated: 2026-08-13
---
# ADR-00002
- 결정
EOF

# ================================================================ 픽스처: 결함 레포
BR="$T/badrepo"
mkdir -p "$BR/docs/business" "$BR/docs/develop/policy" "$BR/docs/develop/feature" "$BR/docs/adr"

# bad status · 신키 owner · updated 누락
cat > "$BR/docs/business/GTM.md" <<'EOF'
---
status: wip
owner: nwkim
---
# GTM
EOF

# frontmatter 부재
cat > "$BR/docs/develop/ARCHITECTURE.md" <<'EOF'
# ARCHITECTURE
- frontmatter가 없다
EOF

# COMPLIANCE 존재 + ## Legal Sources 부재
cat > "$BR/docs/business/COMPLIANCE.md" <<'EOF'
---
status: draft
updated: 2026-01-01
---
# COMPLIANCE
- 표가 없다
EOF

# 오염 2종(펜스 밖)
cat > "$BR/docs/business/PRD.md" <<'EOF'
---
status: draft
updated: 2026-01-01
---
# PRD
[Image #2]
<!-- 주석 -->
EOF

fm_ok() { # $1=path — 파일명 검사 전용 문서(frontmatter는 정상으로)
  cat > "$1" <<'EOF'
---
status: draft
updated: 2026-01-01
---
# doc
EOF
}
fm_ok "$BR/docs/develop/policy/pol-00002-bad.md"        # ID부 소문자
fm_ok "$BR/docs/develop/policy/POL-3-login.md"          # 숫자 5자리 아님
fm_ok "$BR/docs/develop/feature/FEAT-00001-Checkout.md" # slug 대문자
fm_ok "$BR/docs/adr/ADR-004-d.md"                       # 숫자 5자리 아님
fm_ok "$BR/docs/adr/ADR-00001-a.md"                     # 연번 중복 1/2
fm_ok "$BR/docs/adr/ADR-00001-b.md"                     # 연번 중복 2/2
fm_ok "$BR/docs/adr/ADR-00003-c.md"                     # gap: 00002 없음

# ================================================================ validate — 정상 볼트 (침묵)
"$VALIDATE" "$V" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "good vault: exit 0"
assert_has "$OUT" "findings: 0" "good vault: findings 0"
assert_has "$OUT" "scanned: sessions=1 memory=2 index=1" "good vault: scan counts"
assert_not "$OUT" "contamination" "good vault: fenced contamination silent"
"$VALIDATE" "$V" --strict > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "good vault --strict: exit 0"

# ================================================================ validate — 결함 볼트 (발화)
"$VALIDATE" "$B" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "bad vault non-strict: exit 0"
assert_has "$OUT" "scanned: sessions=2 memory=5 index=1" "bad vault: scan counts"

assert_has "$OUT" "session: bad status: wip (want active|parked|done)" "rule: session status vocab"
assert_has "$OUT" "session: unknown key: mood" "rule: session unknown key"
assert_has "$OUT" "session: missing key: related_ticket" "rule: session missing key"
assert_has "$OUT" "session: bad Progress heading: ### 2026-01-01 (parked)" "rule: Progress heading time required"
assert_has "$OUT" "session: bad Progress category: output (want done|learned|next)" "rule: Progress category vocab"
assert_has "$OUT" "session: next has more than 1 sub-bullet" "rule: next max 1 sub-bullet"
assert_has "$OUT" "kjp_20260102_nofm.md:1: session: missing frontmatter" "rule: session missing frontmatter"
assert_has "$OUT" "contamination: [Image #N] artifact" "rule: [Image #N] contamination"
assert_has "$OUT" "contamination: HTML comment" "rule: HTML comment contamination"

assert_has "$OUT" "memory: bad kind: opinion (want fact|policy)" "rule: memory kind vocab"
assert_has "$OUT" "memory: unknown key: related" "rule: memory unknown key"
assert_has "$OUT" "memory: missing section: ## Why" "rule: memory ## Why required"
assert_has "$OUT" "memory: missing section: ## Insight" "rule: memory ## Insight required"
assert_has "$OUT" "memory: empty summary" "rule: memory empty summary"
assert_has "$OUT" "memory: missing key: scope" "rule: memory missing key scope"
assert_has "$OUT" "memory: missing key: kind" "rule: memory missing key kind"

assert_has "$OUT" "index: bad line format" "rule: index line format"
assert_has "$OUT" "index: dangling stem: [[ghost-note]]" "rule: index dangling stem"
assert_has "$OUT" "index: not in index: [[not-in-index]]" "rule: index coverage"

"$VALIDATE" "$B" --strict > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 1 "bad vault --strict: exit 1"

# ================================================================ validate — 인덱스 없는 볼트
"$VALIDATE" "$NI" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "no-index vault: exit 0"
assert_has "$OUT" "index: _index.md missing" "rule: _index.md required"
assert_has "$OUT" "scanned: sessions=0 memory=1 index=0" "no-index vault: zero counts reported (fail-visible)"

# ================================================================ validate — 정상 레포 (침묵)
"$VALIDATE" "$R" --repo > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "good repo: exit 0"
assert_has "$OUT" "findings: 0" "good repo: findings 0"
assert_has "$OUT" "scanned: docs=7 policy=1 feature=1 adr=2" "good repo: scan counts"
assert_not "$OUT" "contamination" "good repo: fenced contamination silent"
"$VALIDATE" "$R" --repo --strict > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "good repo --strict: exit 0"

# ================================================================ validate — 결함 레포 (발화)
"$VALIDATE" "$BR" --repo > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "bad repo non-strict: exit 0"

assert_has "$OUT" "doc: bad status: wip (want draft|approved)" "rule: doc status vocab"
assert_has "$OUT" "doc: unknown key: owner" "rule: doc unknown key"
assert_has "$OUT" "doc: missing key: updated" "rule: doc missing key updated"
assert_has "$OUT" "ARCHITECTURE.md:1: doc: missing frontmatter" "rule: doc missing frontmatter"
assert_has "$OUT" "COMPLIANCE.md:1: doc: missing section: ## Legal Sources" "rule: COMPLIANCE Legal Sources"
assert_has "$OUT" "pol-00002-bad.md:1: doc: bad filename: want POL-NNNNN-<kebab>.md" "rule: POL filename lowercase id"
assert_has "$OUT" "POL-3-login.md:1: doc: bad filename: want POL-NNNNN-<kebab>.md" "rule: POL filename 5 digits"
assert_has "$OUT" "FEAT-00001-Checkout.md:1: doc: bad filename: want FEAT-NNNNN-<kebab>.md" "rule: FEAT filename kebab slug"
assert_has "$OUT" "ADR-004-d.md:1: doc: bad filename: want ADR-NNNNN-<kebab>.md" "rule: ADR filename 5 digits"
assert_has "$OUT" "doc: ADR number duplicated: 00001" "rule: ADR number duplicate"
assert_has "$OUT" "doc: ADR sequence gap: 00002 missing" "rule: ADR sequence gap"
assert_has "$OUT" "PRD.md:6: contamination: [Image #N] artifact" "rule: doc [Image #N] contamination"
assert_has "$OUT" "PRD.md:7: contamination: HTML comment" "rule: doc HTML comment contamination"

"$VALIDATE" "$BR" --repo --strict > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 1 "bad repo --strict: exit 1"

# ================================================================ validate — usage
"$VALIDATE" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "validate no args: exit 2"
"$VALIDATE" "$T/does-not-exist" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "validate nonexistent root: exit 2"
"$VALIDATE" "$V" "$B" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "validate two roots: exit 2"

# ================================================================ brain-recall
BRAIN_VAULT_ROOT="$V" "$RECALL" obsidian > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "recall basic: exit 0"
assert_has "$OUT" "matched=1 shown=1" "recall basic: count line"
assert_has "$OUT" "== $V/memory/good-note.md" "recall basic: hit path"
assert_has "$OUT" "## Insight" "recall basic: body printed"

BRAIN_VAULT_ROOT="$V" "$RECALL" OBSIDIAN > "$OUT" 2>&1; rc=$?
assert_has "$OUT" "matched=1 shown=1" "recall: case-insensitive match"

BRAIN_VAULT_ROOT="$V" "$RECALL" 2026 > "$OUT" 2>&1; rc=$?
assert_has "$OUT" "matched=2 shown=2" "recall: multi match"

BRAIN_VAULT_ROOT="$V" "$RECALL" 2026 --scope org > "$OUT" 2>&1; rc=$?
assert_has "$OUT" "matched=1 shown=1" "recall scope filter: count"
assert_has "$OUT" "org-note.md" "recall scope filter: org note kept"
assert_not "$OUT" "good-note.md" "recall scope filter: kjp note excluded"

BRAIN_VAULT_ROOT="$V" "$RECALL" 2026 -n 1 > "$OUT" 2>&1; rc=$?
assert_has "$OUT" "matched=2 shown=1" "recall -n: cap reported"
assert_has "$OUT" "org-note.md" "recall -n: newest (updated desc) shown"
assert_not "$OUT" "good-note.md" "recall -n: older note cut"

BRAIN_VAULT_ROOT="$V" "$RECALL" zzz-no-such-thing > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "recall zero match: exit 0"
assert_has "$OUT" "matched=0 shown=0" "recall zero match: reported (fail-visible)"

mkdir -p "$T/proj/sub"
printf 'vault-root: %s\n' "$V" > "$T/proj/CLAUDE.local.md"
(cd "$T/proj/sub" && BRAIN_VAULT_ROOT= "$RECALL" obsidian) > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 0 "recall CLAUDE.local.md walk-up: exit 0"
assert_has "$OUT" "matched=1 shown=1" "recall CLAUDE.local.md walk-up: match"

"$RECALL" > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "recall no args: exit 2"
BRAIN_VAULT_ROOT="$V" "$RECALL" q -n abc > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "recall bad -n: exit 2"
BRAIN_VAULT_ROOT="$T/does-not-exist" "$RECALL" q > "$OUT" 2>&1; rc=$?
assert_exit "$rc" 2 "recall bad vault: exit 2"

# ================================================================ 결과
echo "asserts: $PASS passed / $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
