---
name: ss
description: 새 볼트 세션 시작 — 파일명 유일성 검사 후 세션 노트 1파일을 `status: active`로 생성하고, memory/_index.md의 현재 프로젝트 scope 행을 ## Recall에 주입(8KiB 상한·계수 보고). 생성 전용 — 열린 세션을 스캔하지도 고지하지도 않는다. "ss", "session start", "세션 시작", "새 세션", "작업 시작"에 사용. 재개는 sr, 목록은 sl.
argument-hint: "[goal...]"
---

# ss — 세션 시작 (생성 전용)

- 하는 일: 세션 노트 1파일 생성(`status: active`) + recall 주입. 그 외 없음.
- 생성 전용 — 열린 세션 스캔·고지 금지("파킹 N건 있음" 1줄도 금지). 재개 의도가 보이면 `sr`을 안내하고 멈춘다.
- 실행 주체 = PM 직접 Write/Edit — 위임 없음.

## 공통 규율

- 양식 정본 = `${CLAUDE_SKILL_DIR}/../../docs/memory.md` — 작성 전 §세션 노트 스키마·§세션 4절 작성 양식을 Read하고 그대로 따른다. 본 문서에 양식 사본 없음(포인터만).
- 볼트 쓰기 = Write/Edit만 · Edit old_string = CAS · `obsidian create` 등 CLI 쓰기 금지.
- `VAULT` = CLAUDE.local.md `vault-root:` 1키 — 없으면 사용자에 질문 + `/brain:init` 안내. vault-root 밖 쓰기 금지.
- `project`·`ticket-prefix` = AGENTS.md(=CLAUDE.md) brain config 명시 선언 — 경로·이름 파생 금지. 없으면 질문.
- 볼트 기록은 개조식 bullet만 · fail-visible — 계수 상시 보고, 0도 0이라 말한다.

## 절차

1. **해석** — `VAULT`·`project`·`ticket-prefix` 확정. `$VAULT/sessions/` 또는 `$VAULT/memory/_index.md` 부재 시 `/brain:init` 안내 후 중단 — 폴더를 여기서 만들지 않는다.
2. **양식 Read** — `memory.md`의 세션 스키마·4절 양식 절.
3. **Goal 확정** — 인자 텍스트 또는 사용자 진술 1줄. `related_ticket`은 대화에서 확정(`<ticket-prefix>-N` 표기) — 없으면 빈 값.
4. **파일명 mint + 유일성 검사** — `<project>_$(date +%Y%m%d)_<slug>.md` (slug = Goal의 소문자 kebab 축약):
   ```bash
   [ -e "$VAULT/sessions/$name.md" ] && echo "COLLISION" || echo OK
   ```
   - 충돌 시 **자동 접미사 금지** — 사용자에게 구분 slug를 질문한다. sessions는 git 밖 — 덮어쓰기 = 복구 불가.
5. **recall 수행(read)** — `$VAULT/memory/_index.md`에서 현재 프로젝트 scope 행만:
   ```bash
   grep '^- \[\[' "$VAULT/memory/_index.md" | grep -E "\([^)]*\b${PROJECT}\b[^)]*\)"
   ```
   - 주입 = 매칭 행 그대로 · 하드 상한 8KiB(8192B) — 초과분 절단.
   - org·타 프로젝트 행은 주입하지 않고 "N건 — 요청 시" 1줄 포인터만.
   - 계수 의무: 매칭 N건 · 주입 바이트 · 절단 M건 (전부 0 포함).
6. **세션 파일 Write** — memory.md 양식 그대로:
   - frontmatter 5키 — `status: active` · `project` · `updated`(오늘 `YYYY-MM-DD`) · `related_ticket` · `cc_session_ids`(현재 CC 세션 id 획득 가능 시 1개, 아니면 빈 리스트). 신키 추가 금지.
   - 4절 — `## Goal`(1줄) · `## Recall`(계수 라인 1줄 + 주입 행) · `## To-Do` · `## Progress`.
   - `## Progress` 엔트리 기록 없음(확정 2026-08-15) — 세션 파일 생성 자체가 시작 증거. 헤딩 어휘의 `started`는 사람 수동 기록용.
7. **보고** — 생성 경로 + recall 계수(매칭 N건 · B바이트 · 절단 M건 · 기타 scope K건).

## 금지

- 열린 세션 스캔·고지·재개 — `sr`/`sl`의 몫.
- 충돌 시 자동 접미사 — 사용자 질문이 유일한 해소.
- `active` 외 status 값 — `parked`는 sh · `done`은 sc.
- 세션 폴더 생성 — 세션 = 1파일. 볼트 git 커밋 — sessions는 git 밖.
