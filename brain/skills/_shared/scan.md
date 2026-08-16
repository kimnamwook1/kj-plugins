> 소비자: `sr`(재개 후보) · `sl`(목록) · `sc`(대상 불명 시 후보 제시). `ss`는 사용하지 않는다 — 스캔 자체를 안 한다(생성 전용).
> 단독 실행 문서 아님. 스킬 본문에 스니펫 사본 금지 — 포인터만(사본 = 드리프트).
> 전제: `VAULT`(CLAUDE.local.md `vault-root:`) · `PROJECT`(AGENTS.md brain config `project:`) 확정 후 실행.

# scan — 열린 세션 스캔 + 요약 추출 (공유 스니펫)

## 1. 스캔 — 열린 세션(`active` + `parked`) 찾기

- 열린 세션 = frontmatter `status:`가 `active` 또는 `parked` — 3값 어휘 중 `done`만 닫힘.
- 두 값 모두, 항상. `parked`만 스캔하면 결함 — `sh` 없이 끊긴 세션(크래시·터미널 종료)은 `active`로 남고, `sr`의 유일한 복구 경로가 막힌다.

```bash
PROJ_RE="${PROJ_RE:-$PROJECT}"   # `sl all` = PROJ_RE='.*'
find "$VAULT/sessions" -maxdepth 1 -name "*.md" 2>/dev/null | while read -r f; do
  st=$(sed -n 's/^status:[[:space:]]*//p' "$f" | head -1 | tr -d '"'\''[:space:]')
  case "$st" in active|parked) ;; *) continue ;; esac
  grep -qE "^project:[[:space:]]*${PROJ_RE}[[:space:]]*$" "$f" && printf '%s\t%s\n' "$st" "$f" || :
done
```

- `sed … | head -1` = **frontmatter 첫 `status:` 줄만** 읽는다 — Progress 본문에도 `status:` 문자열이 나올 수 있다. `tr`은 따옴표(`status: "parked"`) 방어.
- 루프 몸통 끝 `|| :` 종결자 = 검증된 필수 기법 — 없으면 마지막 파일이 비매칭일 때 파이프라인 전체가 exit 1(빈 볼트뿐 아니라 매칭 2건인 정상 run에서도 실측). 삭제 금지.
- 출력 = `<status>\t<path>` — §3 렌더가 상태별로 다르게 그린다. 경로만 내보내면 파일당 재grep 비용.

## 2. 요약 추출 — 후보 1개씩

- 세션 파일 전체 Read 금지 — Progress가 누적되어 커진다. 추출 3요소 = Goal + 미완 To-Do(`- [ ]`)만 + 최신 Progress 엔트리 1개(sr 주입 3요소와 동일 — canon `memory.md` §recall).

```bash
awk '/^## /{s=$0;n=0}
  s=="## Goal"{print;next}
  s=="## To-Do"{if(/^## /||/^- \[ \]/)print;next}
  s=="## Progress"{if(/^### /)n++; if(n<=1)print}' "$f"
```

- frontmatter 스칼라(`updated`·`related_ticket`)는 1줄 grep — `grep -m1 '^updated:' "$f"`. 또 다른 Read 금지.
- 식별자 = 파일명 — `basename "$f" .md`. uid 키 없음.

## 3. 렌더 — 후보당 1줄

```
1. [parked] <Goal 한 줄> (<파일명>, updated <updated>) — <최신 Progress 한 줄 요약>
2. [active] <Goal 한 줄> (<파일명>, updated <updated>) — <최신 Progress 한 줄 요약>
```

- `[parked]`/`[active]` 마커 필수 — §1 스캔의 status 열 값. Progress 헤딩 접미(`(parked)` 등)는 이력이지 상태가 아니다 — 접미에서 추론 금지.
- 정렬 = `updated:` 내림차순, 1부터 번호 — `sl`에서 고른 번호가 `sr`에서 같은 세션을 가리키도록 두 스킬이 같은 정렬을 쓴다.
- `PROJ_RE='.*'`일 때는 각 줄 앞에 `project:` 값 접두 — 아니면 목록이 모호.
- 0건도 0건이라 보고(fail-visible).
