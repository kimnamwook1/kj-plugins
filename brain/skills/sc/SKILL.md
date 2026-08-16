---
name: sc
description: 세션 종료 — status를 done으로 전이하고 (completed) 엔트리 기록, learned 하위를 수확해 memory 노트+_index.md를 같은 커밋으로 승격(PM 직접), 산출이 문서에 닿으면 레포 docs/로 라우팅, dreaming은 "미통합 N건" 1줄 제안만. 방치 세션도 done으로 닫는다 — cancel 없음. "sc", "세션 종료", "세션 완료", "마감", "이 작업 끝"에 사용. 잠깐 멈춤이면 sh.
argument-hint: "[session-file?]"
---

# sc — 세션 종료

- 하는 일: `done` 전이 + 승격 ① + 문서 라우팅(레포 docs) + dreaming 제안 1줄.
- 실행 주체 = PM 직접 — 볼트 쓰기도, 볼트 git 커밋도 PM.
- `done`이 이 스킬이 쓰는 유일한 status 값 — cancel 없음. 방치·중단 세션도 `done`으로 닫고 사유는 종료 엔트리에.

## 공통 규율

- 양식 정본 = `${CLAUDE_SKILL_DIR}/../../docs/memory.md` — 작성 전 §세션 4절 양식·§memory 노트 스키마·§승격을 Read하고 그대로. 본 문서에 양식 사본 없음(포인터만).
- 문서 라우팅 정본 = `${CLAUDE_SKILL_DIR}/../../docs/project-docs.md`.
- 볼트 쓰기 = Write/Edit만 · Edit old_string = CAS · CLI 쓰기 금지 · vault-root(CLAUDE.local.md 1키) 밖 쓰기 금지.
- 볼트 기록은 개조식 bullet만 · fail-visible — 계수 상시 보고, 0도 0.

## 절차

1. **대상 확정** — 이 대화의 열린 세션(`active`·`parked` 모두 가능). 인자 경로 우선. 불명이면 `${CLAUDE_SKILL_DIR}/../_shared/scan.md` §1~§3으로 후보 제시 후 사용자 선택 — 추측 금지. `parked` 세션 직접 종료는 정상 — `sr` 왕복 불요.
2. **양식 Read** — memory.md 해당 절.
3. **승격 ① — PM 직접, 노트와 인덱스는 같은 커밋**:
   - 수확 대상: 이 세션 Progress의 **learned 하위** + 대화 — 사용자 정정 · AI 자인 실수 · 재사용 가치 사실.
   - 기존 노트 대조(내용 기준 — `_index.md` summary grep) → 주제 일치 시 기존 `memory/<topic>.md` Edit(CAS) · 없으면 Write.
   - 노트 양식 = memory.md 4키(summary는 "언제+주장" 두 성분 · `scope: [<project>]` 명시 · `kind` fact|policy · `updated`) + `## Insight`/`## Why`, bullet만. 파일명 = 토픽 kebab, 프로젝트 접두 금지.
   - `_index.md`에 행 append — `- [[<stem>]] (<scope>) — <summary>`.
   - 0건이어도 "승격 0건" 보고.
4. **문서 라우팅** — 세션 산출이 기능·아키텍처·배포·스키마·정책에 닿으면 **레포 `docs/`**(project-docs.md 트리 — 볼트 아님)로: 해당 문서 갱신 또는 세션 To-Do 미결로 남김. 경계: 코드 PR과 함께 리뷰되면 레포 docs · 세션에서 배웠으면 볼트 memory. 레포에 지식 파일 금지.
5. **종료 엔트리 — PM 직접 Edit** — `## Progress` 맨 위 `### YYYY-MM-DD HH:MM (completed)`(시각 필수):
   - done 하위에 최종 상태·산출 경로·미검증 항목 · learned 하위는 있으면(승격과 별개로 세션에 남는 기록).
   - 방치 종료도 같은 `(completed)` 토큰 — 어떻게 끝났는지는 done 하위 bullet이 말한다.
6. **frontmatter — PM 직접 Edit** — `status:` → `done`(frontmatter **첫** `status:` 줄만 — CAS · `active`/`parked` 모두 `done`으로) · `updated:` → 오늘.
7. **볼트 git 커밋 — PM 직접** — pathspec = 3단계 노트 경로 + `memory/_index.md`만. 세션 파일은 git 밖 — 스냅샷에 없다.
   - 다른 dirty 파일 미접촉(스테이징·스태시·리버트 금지). 메시지는 그 볼트 관례 확인(`git -C "$VAULT" log --oneline -5`) 후 따름. `git push` 금지.
   - 승격 0건이면 커밋 없음(빈 커밋 금지) — 그 사실을 보고. 볼트가 git repo가 아니면 조용히 skip 후 보고에 언급.
8. **dreaming 제안 1줄 — 실행 금지**:
   ```bash
   cur=$(cat "$VAULT/.dreaming-cursor" 2>/dev/null || :)
   [ -n "$cur" ] && N=$(git -C "$VAULT" rev-list --count "$cur"..HEAD -- memory/) \
                 || N=$(git -C "$VAULT" rev-list --count HEAD -- memory/)
   ```
   - 출력: `dreaming 권장 — 미통합 N건` 1줄만. 커서 정의는 `${CLAUDE_SKILL_DIR}/../dreaming/SKILL.md` §운영. 실행은 사용자 승인 또는 `/brain:dreaming` — 여기서 돌리지 않는다.
9. **보고** — `세션 종료: <경로> (status: done)` · 승격 N건(노트 경로) · 문서 라우팅 M건 · 커밋 여부 · dreaming 제안 1줄.

## 금지

- dreaming 실행 — 제안 1줄이 전부.
- `git push` — 커밋까지만, 원격 노출은 사용자의 몫.
- 세션 파일 전체 Read — scan.md awk 추출·필요 절만.
- 승격 역기록 — 세션에 승격 마커·백링크·카운터를 남기지 않는다.
- 레포에 지식 파일 생성 — 지식은 볼트 `memory/` 한 곳.
