---
name: dreaming
description: 볼트 memory/ 배치 통합 — 2연산: Refine(사실 불변 정제)·승격 ②(타 프로젝트에서 확인된 지식의 scope 확장). 원자 락·증분 커서·1 run 1 commit, 파괴적 변경(merge·delete·move)은 제안-승인. 세션은 읽지도 쓰지도 않는다. "dreaming", "수면 통합", "볼트 정리", "지식 통합", "메모리 consolidate", "볼트 유지보수"에 사용. 실행 = 사용자 승인 또는 /brain:dreaming 명시 호출 — sc는 제안 1줄만.
argument-hint: ""
---

# dreaming — memory 배치 통합

- 입력 = `<VAULT>/memory/`만 — `sessions/`는 읽기·쓰기 모두 금지.
- 실행 주체 = PM 직접 Write/Edit(old_string = CAS) · 커밋도 PM · `git push` 금지. **worktree 격리 없음** — 락 + CAS + 1 run 1 commit(revert 가능)이 대체.
- 트리거 = 사용자 승인 또는 `/brain:dreaming` 명시 호출 — `sc`는 "미통합 N건" 1줄 제안만 한다. 큐·cron 없음.
- 노트 양식 정본 = `docs/memory.md`. **통째 Read 금지** — 절만 뽑는다: `"${CLAUDE_PLUGIN_ROOT}/scripts/brain-canon" note-schema,dreaming`. 본 문서에 양식 사본 없음(포인터만).
- `VAULT` = CLAUDE.local.md `vault-root:` — 밖은 접촉 금지.

## 2연산

- **Refine — 사실 불변 정제**:
  - 대상: 형식 이탈(줄글 → 개조식 bullet · summary "언제+주장" 성분 결손 보강 · 중복 문단 접기 · 4키 이탈).
  - 불변 경계: 코드블록·명령·경로·수치·버전·부정문은 그대로. 편집 전후로 그 값들을 추출·비교 — 1개라도 사라지면 그 쓰기 취소.
- **승격 ② — scope 확장**:
  - 같은 교훈이 타 프로젝트에서 확인되면 frontmatter `scope:` 배열에 식별자 추가 **1줄 Edit** + `_index.md` 해당 행 scope 갱신. git mv·링크 재배선 없음 — 파일은 제자리.
  - 동일성은 **내용 기준** — 파일명·제목 일치는 후보 좁히기일 뿐, 수치·경로·조건이 하나라도 다르면 다른 지식(확장 금지).
- **Link 연산 없음(폐지)** — `related` 키 작성 금지(소비자 없음 — recall·brain-recall 모두 안 읽음). 노트 연결이 필요하면 본문 `## Why`에 `[[링크]]`.

## 운영

- **원자 락** — run 시작 시 획득, 실패(이미 존재) = 진행 중 run → skip(실패 아님), 종료 시 해제:
  ```bash
  mkdir "$VAULT/.dreaming.lock" 2>/dev/null || { echo "skip — run 진행 중"; exit 0; }
  ```
  - 락 = `$VAULT/.dreaming.lock`(확정 2026-08-15) — mkdir 원자 획득 · 실행 종료 시 제거 · 존재하면 skip · 볼트 .gitignore 대상.
- **증분 커서** — 커서 = 마지막 성공 run의 커밋 SHA. 스캔 = 커서 이후 변경된 `memory/` 노트만 — 전량 재처리는 느리고 오염 위험만 키운다.
  - 커서 저장 = `$VAULT/.dreaming-cursor` 1줄(마지막 성공 run의 커밋 해시 — 확정 2026-08-15) · **git 추적** — 커서 갱신도 1 run 1 commit에 포함(revert 시 커서도 같이 돌아가 정합). `sc`의 미통합 계수가 이 파일을 읽는다.
- **1 run 1 commit** — run의 모든 쓰기를 커밋 1개로 묶는다. 나쁜 run = `git revert` 1개. 커밋 메시지는 그 볼트 관례 확인 후.
- **파괴적 변경(merge·delete·move) = 제안-승인** — 자동 적용 금지. 자동 적용 가능 범위 = 무손실 Refine·scope 추가뿐. 제안은 대상·근거·결과를 개조식으로 제시하고 승인 후에만 실행.
- **fail-visible** — 스캔 노트 수 · Refine N건 · 승격 ② M건 · 제안 K건 · 커서 이동(구→신 SHA)을 상시 보고, 0도 0.

## 금지

- 세션 파일 접촉 — 읽기도 쓰기도 금지.
- 레포 docs/ 쓰기 — dreaming의 세계는 볼트 `memory/`뿐.
- `related` frontmatter 키 작성 · 신키 추가.
- 파괴적 변경 자동 적용 — 제안 없이 merge·delete·move 금지.
- secrets 값 기록 — 위치·규약만, 값은 절대.
- CLI 쓰기(`obsidian create` 등) · worktree 생성 · `git push`.
