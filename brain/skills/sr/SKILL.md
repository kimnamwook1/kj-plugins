---
name: sr
description: 파킹된 세션 재개 — 현재 프로젝트의 열린 세션(status parked|active)을 스캔해 요약을 제시하고, 사용자가 고른 세션을 채택. 쓰기는 frontmatter 3줄만 PM 직접 Edit(status→active·updated·cc_session_ids), 주입은 Goal+미완 To-Do+최신 Progress 1개. 세션 신규 생성 금지. "sr", "재개", "resume", "이어서", "하던 거 계속"에 사용. 새 세션은 ss, 목록만은 sl.
argument-hint: ""
---

# sr — 세션 재개

- 하는 일: 스캔 → 요약 제시 → 사용자 채택 → frontmatter 3줄 Edit + recall 화면 출력.
- 세션 파일 신규 생성 절대 금지 — 새 세션을 원하면 `ss` 안내 후 중단.
- 실행 주체 = PM 직접 — 위임 없음.

## 공통 규율

- 양식 정본 = `${CLAUDE_SKILL_DIR}/../../docs/memory.md` — 쓰기 전 Read. 본 문서에 양식 사본 없음(포인터만).
- 볼트 쓰기 = Write/Edit만 · Edit old_string = CAS · CLI 쓰기 금지.
- `VAULT` = CLAUDE.local.md `vault-root:` — 없으면 질문 + `/brain:init` 안내. vault-root 밖 쓰기 금지.
- `project` = AGENTS.md brain config 명시 선언 — 경로 파생 금지.
- fail-visible — 계수 상시 보고, 0도 0.

## 절차

1. **해석** — `VAULT`·`project` 확정.
2. **스캔** — `${CLAUDE_SKILL_DIR}/../_shared/scan.md` §1 실행(`PROJ_RE=<project>`). 스니펫 사본 금지 — `|| :` 종결자·첫 `status:` 줄만 읽기 등 검증 기법은 그 문서가 정본.
   - 0건 → "열린 세션 0건 — 새 세션은 `ss`" 1줄 보고 후 중단. 생성으로 빠지지 않는다.
3. **후보 제시** — scan.md §2 awk 추출 · §3 렌더(상태 마커 필수 · `updated` 내림차순 · 번호는 `sl`과 동일 규칙).
   - `[active]` 후보도 목록에 유지 — `sh` 없이 끊긴 세션의 유일한 복구 경로가 여기다.
   - 정확히 1건이어도 제시 후 예/아니오 확인. 사용자가 번호로 채택 → 4단계. 거절 → 중단.
4. **채택 — frontmatter 3줄만 PM 직접 Edit** (old_string = CAS):
   - `status:` → `active` — frontmatter **첫** `status:` 줄만(본문 Progress에도 `status:` 문자열 존재 가능). 이미 `active`면 값 유지.
   - `updated:` → 오늘(`YYYY-MM-DD`).
   - `cc_session_ids:` — 현재 CC 세션 id 획득 가능 시 리스트 맨 앞 prepend. 없으면 미접촉.
   - 그 외 frontmatter·본문 일절 미접촉 — Progress 엔트리 추가 없음.
   - Progress `(resumed)` 엔트리 기록 없음(확정 2026-08-15) — `cc_session_ids` prepend가 재개 증거. 헤딩 어휘의 `resumed`는 사람 수동 기록용.
5. **주입(화면 출력)** — 3요소 한정: **Goal + 미완 To-Do(`- [ ]`)만 + 최신 Progress 엔트리 1개** — 3단계 awk 추출 재사용, 파일 재Read 금지. 그 외 절대 미주입 — 과거 엔트리는 필요 시 on-demand Read.
   - 추가 주입: `memory/_index.md` 현재 프로젝트 scope 행(하드 상한 8KiB 공유 — memory.md §recall). org·타 프로젝트는 "N건 — 요청 시" 1줄.
6. **보고** — 채택 경로 · 최종 status 값 · 주입 계수(세션 요약 바이트 · 인덱스 N건·바이트·절단 M건).

## 금지

- 세션 신규 생성 — 파일명 mint·`Write` 진입 자체가 금지.
- `active` 외 status 쓰기 — `done`은 sc · `parked`는 sh.
- 세션 파일 전체 Read — scan.md awk 추출만.
- 본문(4절) 쓰기 — 이 스킬의 쓰기는 frontmatter 3줄이 전부.
