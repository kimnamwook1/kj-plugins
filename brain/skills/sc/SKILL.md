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

- 양식 정본 = `docs/memory.md`. **통째 Read 금지** — 절만 뽑는다:
  ```bash
  "${CLAUDE_PLUGIN_ROOT}/scripts/brain-canon" session-format,note-schema,promote
  ```
  본 문서에 양식 사본 없음(포인터만).
- 문서 라우팅 정본 = `${CLAUDE_SKILL_DIR}/../../docs/project-docs.md`.
- 볼트 쓰기 = Write/Edit만 · Edit old_string = CAS · CLI 쓰기 금지 · vault-root(CLAUDE.local.md 1키) 밖 쓰기 금지.
- 볼트 기록은 개조식 bullet만 · fail-visible — 계수 상시 보고, 0도 0.

## 절차

1. **대상 확정** — 이 대화의 열린 세션(`active`·`parked` 모두 가능). 인자 경로 우선. 불명이면 `${CLAUDE_SKILL_DIR}/../_shared/scan.md` §1~§3으로 후보 제시 후 사용자 선택 — 추측 금지. `parked` 세션 직접 종료는 정상 — `sr` 왕복 불요.
2. **양식 확보** — `brain-canon session-format,note-schema,promote` 출력을 그대로 따른다.
3. **볼트 락 획득 — 승격 전 필수**(0.3.2):
   ```bash
   mkdir "$VAULT/.vault.lock" 2>/dev/null || { echo 'sc: 다른 세션이 승격 중 — skip'; }
   ```
   - 획득 성공 → §4~§8 수행 후 `rmdir "$VAULT/.vault.lock"`.
   - 획득 실패 → **대기·재시도 금지.** 승격을 건너뛰고 종료 엔트리·frontmatter(§6·§7)만 수행한 뒤 `승격 skip — 볼트 락 점유 중` 을 보고에 명시(fail-visible). 사용자가 나중에 다시 부른다.
   - 근거: peer 세션 다중 실행 시 `_index.md` append 충돌은 조용한 유실이다(2026-08-20 실측 — uncommitted 20건).
4. **승격 ① — PM 직접, 노트와 인덱스는 같은 커밋**:
   - 수확 대상: 이 세션 Progress의 **learned 하위** + 대화 — 사용자 정정 · AI 자인 실수 · 재사용 가치 사실.
   - 기존 노트 대조(내용 기준 — `_index.md` summary grep) → 주제 일치 시 기존 `memory/<topic>.md` Edit(CAS) · 없으면 Write.
   - 노트 양식 = memory.md 4키(summary는 "언제+주장" 두 성분 · **100자 이내 · 트리거 1개 · 백틱·따옴표 금지** · `scope: [<project>]` 명시 · `kind` fact|policy · `updated`) + `## Insight`/`## Why`, bullet만. 파일명 = 토픽 kebab, 프로젝트 접두 금지.
   - 지식이 레포 문서를 근거로 하면 `## Why` 에 그 경로를 평문으로 적는다(`docs/develop/feature/FEAT-...`).
   - 🔴 `볼트-적중`·`볼트-공백` 줄은 **승격 대상이 아니다** — 효능 측정 기록이지 지식이 아니다. 단 `볼트-공백` 은 "없어서 틀린 지식" 을 가리키므로 그 지식 자체는 승격 후보다.
   - `_index.md`에 행 append — `- [[<stem>]] (<scope>) — <summary>`.
   - 0건이어도 "승격 0건" 보고.
5. **문서 라우팅** — 세션 산출이 기능·아키텍처·배포·스키마·정책에 닿으면 **레포 `docs/`**(project-docs.md 트리 — 볼트 아님)로: 기능 → `docs/develop/feature/FEAT-*` · 정책·규칙·임계값 → `docs/develop/policy/POL-*` · 해당 없으면 `docs-impact: none` 명시 판정. 갱신하거나 세션 To-Do 미결로 남김. 경계: 코드 PR과 함께 리뷰되면 레포 docs · 세션에서 배웠으면 볼트 memory. 레포에 지식 파일 금지.
6. **종료 엔트리 — PM 직접 Edit** — `## Progress` 맨 위 `### YYYY-MM-DD HH:MM (completed)`(시각 필수):
   - done 하위에 최종 상태·산출 경로·미검증 항목 · learned 하위는 있으면(승격과 별개로 세션에 남는 기록).
   - 방치 종료도 같은 `(completed)` 토큰 — 어떻게 끝났는지는 done 하위 bullet이 말한다.
7. **frontmatter — PM 직접 Edit** — `status:` → `done`(frontmatter **첫** `status:` 줄만 — CAS · `active`/`parked` 모두 `done`으로) · `updated:` → 오늘.
8. **볼트 git 커밋 — PM 직접 · 커밋 2개로 분리**(0.3.2 — `sessions/` 도 git 추적):
   - 커밋 ① 승격: pathspec = 승격한 노트 경로 + `memory/_index.md`만.
   - 커밋 ② 세션: pathspec = `sessions/<파일명>` 만.
   - 🔴 두 커밋을 합치지 않는다 — dreaming 계수(`-- memory/`)와 `git revert` 단위가 흐려진다.
   - 다른 dirty 파일 미접촉(스테이징·스태시·리버트 금지). 메시지는 그 볼트 관례 확인(`git -C "$VAULT" log --oneline -5`) 후 따름. `git push` 금지.
   - 승격 0건이면 커밋 ① 없음(빈 커밋 금지) — 그 사실을 보고. 볼트가 git repo가 아니면 조용히 skip 후 보고에 언급.
   - 커밋 후 락 해제: `rmdir "$VAULT/.vault.lock"`.
9. **dreaming 제안 1줄 — 실행 금지**:
   ```bash
   cur=$(cat "$VAULT/.dreaming-cursor" 2>/dev/null || :)
   [ -n "$cur" ] && N=$(git -C "$VAULT" rev-list --count "$cur"..HEAD -- memory/) \
                 || N=$(git -C "$VAULT" rev-list --count HEAD -- memory/)
   ```
   - 출력: `dreaming 권장 — 미통합 N건` 1줄만. 커서 정의는 `${CLAUDE_SKILL_DIR}/../dreaming/SKILL.md` §운영. 실행은 사용자 승인 또는 `/brain:dreaming` — 여기서 돌리지 않는다.
10. **다음 시작 프롬프트 — 화면 출력만**(볼트 쓰기 없음):
    - 소스 = 종료 엔트리 done 하위의 미검증 항목 + 남은 To-Do + 문서 라우팅 미결. 셋 다 없으면 `후속 없음` 1줄로 대체 — 프롬프트를 지어내지 않는다.
    - 형식 = 복붙 가능한 fenced block 1개, 3줄 이내:
      ```
      ss <다음 목표 한 줄>
      배경: <직전 세션 산출 경로>
      먼저: <첫 행동 1줄>
      ```
    - 첫 줄은 `ss` 고정 — 닫힌 세션은 재개하지 않는다.
11. **보고** — `세션 종료: <경로> (status: done)` · 승격 N건(노트 경로) · 문서 라우팅 M건 · 커밋 2건 여부 · 락 skip 여부 · dreaming 제안 1줄.

## 금지

- dreaming 실행 — 제안 1줄이 전부.
- `git push` — 커밋까지만, 원격 노출은 사용자의 몫.
- 세션 파일 전체 Read — scan.md awk 추출·필요 절만.
- 승격 역기록 — 세션에 승격 마커·백링크·카운터를 남기지 않는다.
- 볼트 락 대기·강제 해제 — 점유 중이면 skip 후 보고. `rm -rf` 로 남의 락을 걷어내지 않는다.
- 레포에 지식 파일 생성 — 지식은 볼트 `memory/` 한 곳.
