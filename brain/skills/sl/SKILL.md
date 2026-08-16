---
name: sl
description: 열린 세션 목록 — 완전 read-only. status parked|active 세션을 스캔해 상태·Goal·파일명·최신 Progress를 한 줄씩 출력. 아무것도 쓰지 않고 아무것도 채택하지 않는다. "sl", "세션 목록", "열린 세션", "파킹된 세션", "뭐 하다 말았지", "what was I working on"에 사용. 재개는 sr, 새 세션은 ss.
argument-hint: "[project|all]"
---

# sl — 세션 목록 (완전 read-only)

- 하는 일: 열린 세션(`parked` + `active`)을 한 줄씩 출력. 그게 전부.
- 완전 read-only — Write·Edit·frontmatter 접촉(`updated:` 포함) 전부 금지. 목록은 사용이 아니다.

## 절차

1. **해석** — `VAULT` = CLAUDE.local.md `vault-root:`(없으면 질문 + `/brain:init` 안내). 스코프:
   - 인자 없음 → 현재 프로젝트(AGENTS.md brain config `project:`). 해석 실패 시 추측 금지 — `all`로 폴백하고 그렇게 말한다(read-only라 넓은 목록은 무해, 틀린 추측은 아님).
   - `all` → 전 프로젝트(`PROJ_RE='.*'`).
   - 그 외 값 → 그 프로젝트 식별자.
   - 상태 필터는 없고, 필요하지도 않다 — `parked`·`active` 둘 다 열린 상태. 한쪽만 보여주는 목록이 세션을 잃는 방식이다.
2. **스캔** — `${CLAUDE_SKILL_DIR}/../_shared/scan.md` §1 실행. 스니펫 사본 금지 — `|| :` 종결자·첫 `status:` 줄만 읽기는 그 문서가 정본.
   - 0건 → "열린 세션 0건 (<스코프>)" 1줄 보고 후 중단(fail-visible — 0도 0).
3. **추출·출력** — scan.md §2 awk(파일 전체 Read 금지) · §3 렌더:
   - `[parked]`/`[active]` 마커 필수 — 스캔 status 열에서. Progress 접미로 추론 금지.
   - 정렬 = `updated:` 내림차순 — 여기서 고른 번호가 `sr`에서 같은 세션을 가리킨다.
   - `all`이면 각 줄에 `project:` 값 접두.
   - 마감 1줄: "재개는 `sr` · 새 세션은 `ss`".

## 금지

- 쓰기 전부 — 볼트의 어떤 파일도 접촉하지 않는다.
- 세션 채택 — 출력이 채택이 아니다. 채택은 `sr` + 사용자 명시 선택.
- 세션 생성 — 목록이 비어도 `ss`로 흘러 들어가지 않는다.
- 세션 파일 전체 Read — awk 추출만.
