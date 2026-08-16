---
name: sh
description: 세션 파킹(중단) — 종료 아님. 무조건 현재 세션을 파킹한다 — Progress 맨 위에 (parked) 엔트리(중첩 3종 done/learned/next·시각 필수)를 PM 직접 기록하고 status를 parked로 전이. 승격 금지 — 승격은 sc 단독. "sh", "파킹", "park", "핸드오프", "잠깐 멈춤", "보류"에 사용. 완전 종료는 sc, 재개는 sr.
argument-hint: ""
---

# sh — 세션 파킹

- 무조건 파킹 — 인자·질문 없이, 호출되면 현재 세션을 파킹하고 끝. 재개는 `sr` 명시 타이핑.
- `parked`만 쓴다 — `done` 금지(종료는 `sc`). 이미 `parked`면 값 유지, 엔트리는 그래도 추가.
- 승격 금지 — `memory/` 쓰기 없음. 승격 ①은 `sc` 단독 — 파킹은 싸고 반복 가능해야 하고, 파킹마다 승격하면 같은 지식이 반복 기록된다.
- 실행 주체 = PM 직접 Write/Edit — 위임 없음.

## 공통 규율

- 양식 정본 = `${CLAUDE_SKILL_DIR}/../../docs/memory.md` — 작성 전 §세션 4절 작성 양식·§Progress 규칙을 Read하고 그대로. 본 문서에 양식 사본 없음(포인터만).
- 볼트 쓰기 = Write/Edit만 · Edit old_string = CAS · CLI 쓰기 금지.
- `VAULT` = CLAUDE.local.md `vault-root:` — 없으면 질문 + `/brain:init` 안내. vault-root 밖 쓰기 금지.
- 볼트 기록은 개조식 bullet만 · fail-visible — 계수 상시 보고.

## 절차

1. **대상 확정** — 이 대화에서 작업 중인 세션(`$VAULT/sessions/<file>.md`). 사용자가 지목했으면 그것. 불명이면 질문 — 추측 금지.
2. **양식 Read** — memory.md의 4절 양식·Progress 규칙 절.
3. **Progress 엔트리 — PM 직접 Edit**, `## Progress` 맨 위 삽입(기존 엔트리 보존·최신이 맨 위):
   - 헤딩 = `### YYYY-MM-DD HH:MM (parked)` — **시각 필수**(하루 다중 파킹·재개의 순서 보장).
   - 중첩 카테고리 3종, 순서 고정 done → learned → next. 카테고리 줄은 `- done` 고정 표기(콜론·부가 텍스트 금지 — 파서 앵커), 사실은 하위 bullet.
   - 같은 카테고리 반복 금지(하위에 줄 추가) · 빈 카테고리는 줄 생략.
   - `next` 하위 1줄만 = 재개 첫 행동 — **파킹 시 필수**.
   - 산출 경로는 done 줄에 포함. 실수는 learned 하위 `실수 → 복구` 형태 의무.
4. **To-Do 정리** — 남은 일·사용자 입력 대기(`ASK:` 접두) 반영. 사용자가 다음 방향을 말했으면 맨 앞에 — 사용자 지시 > 에이전트 분석.
5. **frontmatter — PM 직접 Edit** — `status:` → `parked`(frontmatter **첫** `status:` 줄만 — 본문에도 `status:` 문자열 가능, CAS) · `updated:` → 오늘(`YYYY-MM-DD`).
6. **보고**:
   > 세션 파킹: `<경로>` (status: parked)
   > 재개는 `sr` · 목록은 `sl` · 끝난 작업이면 `sh`가 아니라 `sc`.

## 금지

- 승격 — `memory/`·`_index.md` 쓰기 없음. `sc`의 몫.
- `done` 전이 — `parked`가 이 스킬이 쓰는 유일한 status 값.
- 세션 파일 전체 Read — 필요한 절만.
- 볼트 git 커밋 — sessions는 git 밖, 커밋 대상이 없다.
