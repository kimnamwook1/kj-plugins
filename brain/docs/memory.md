> 소비자: `ss`·`sr`·`sh`·`sc`·`dreaming` — 볼트를 읽고 쓰는 모든 스킬이 실행 전 Read. `ss`·`sh`·`sr`·`sc`는 세션 노트 작성 전 §세션 4절 작성 양식을 Read하고 그대로 따른다. `init` — 볼트 스캐폴드 기준. `brain-validate.sh`(볼트 모드)·`brain-recall` — 검사·질의 어휘의 기준.

# memory — 볼트 구조 · 노트 스키마 · 승격 · recall · dreaming

- 정본 근거: `전서_0.3.0.md` §1.1~§1.4 · §2.
- 원칙 5: ①선별 주입(상한) ②PM 직접 쓰기 ③단일 원본 ④fail-visible(0도 0이라 말한다) ⑤명시 선언(경로·이름에서 자동 파생 금지).
- 볼트 기록 전반(세션 노트 포함)은 개조식 bullet만 — 줄글(산문) 금지. 한 줄 = 한 사실.
- 볼트 쓰기는 Write/Edit만 — `obsidian create` 금지 · Edit old_string = CAS · vault-root 밖 쓰기 금지.

## 볼트 구조 — 2층 평탄

```
<vault>/                      # 볼트 루트 = org 경계 (techtainment / beafter 볼트 분리)
  sessions/                   # 세션 노트 — git 추적(0.3.2). 휘발성은 주입 정책이 정한다(§recall) — git 위치가 아니다
  memory/                     # 전 지식 단일 트리 — 폴더 계층 없음
    _index.md                 # 공용 인덱스 1파일
```

- 폐지: `projects/NNN_slug/` · `p_memory/` · `neocortex/` · 공통층(`org/`·`000_common/`) · `999_tools/` · `.brain-paths` · 번호 밴드.
- 구분축은 폴더가 아니라 frontmatter 2키(`scope`·`kind`).

## memory 노트 스키마

```yaml
---
summary: <언제 + 주장 — 한 문장, 100자 이내>
scope: [kjp]          # 프로젝트 식별자 목록. org = 회사 지식. 명시 선언만
kind: fact            # fact | policy — 생략 시 fact
updated: YYYY-MM-DD
---
## Insight   ← 주장·결론
## Why       ← 근거 (파일:줄·명령 출력·숫자·URL)
```

- 키는 4개(summary·scope·kind·updated) — 신키 추가 금지.
- 절은 2개(Insight·Why) — Trigger 절 없음(폐지 2026-08-13). 트리거는 summary가 겸한다.
- summary = "언제(트리거) + 주장" 두 성분 필수 — recall·brain-recall의 매칭 재료가 summary 한 곳에 모인다.
- 🔴 **summary 100자 이내** — 트리거는 **1개만**. `·` 로 트리거를 나열하지 않는다. 초과분은 §Insight 로 내린다.
  - 근거(2026-08-20 실측): 상한이 없어 median 359B 까지 부풀었고 `youtube-stts` scope 주입량이 8,696B 로 recall 8KiB 상한을 넘겨 절단이 시작됐다.
- 🔴 **summary 의 YAML 안전 규칙** — plain scalar 가 조용히 깨진다.
  - 감싸지 않을 때: 첫 글자에 YAML indicator(`` ` `` `[` `{` `&` `*` `!` `|` `>` `%` `@`) 금지 · `: `(콜론+공백) 금지 · ` #`(공백+해시) 금지.
  - 위 문자가 필요하면 **값 전체를 따옴표로 감싼다** — 열었으면 반드시 닫는다. 문장 안의 백틱·따옴표 자체는 문제가 아니다.
  - 근거(2026-08-20 실측): 백틱으로 시작한 노트 1건 · `"` 로 열고 닫지 않은 노트 1건이 `yaml.safe_load` 파싱 실패. `brain-recall` 은 awk 줄 파싱이라 안 깨지지만 Obsidian properties·Bases 가 깨진다.
- brain-validate는 절 부재 대신 summary 부재·트리거 성분 결손·길이 초과·금지 문자를 잡는다.
- 본문은 개조식 bullet만 — 줄글 금지.
- kind 판별: 위반할 수 있으면 policy, 틀릴 수 있으면 fact. 교훈·절차 → fact. 취향 → policy.
- 제3종 kind는 실측 필요가 나올 때 validate 어휘 1줄 추가로만.
- scope 값은 명시 선언만 — AGENTS.md brain config `project:` 키가 출처. 경로·폴더 파생 금지.
- `scope: [org]` = **회사 맥락의 내 관측**(0.3.2 개정 — "회사 공식 지식" 이 아니다). 회사 공식 문서의 집은 레포 `docs/`.
  - 근거(2026-08-20 실측): beafter 볼트 org scope 15건 전수에 PRD·FRD·정책 0건, 전부 개인 관측 교훈이었다.
- scope 2+ = 교차 지식(구 neocortex 상당).
- 파일명 = 토픽 kebab 소문자 (`obsidian-cli_silent-fork.md`). 프로젝트 접두 금지 — 프로젝트는 scope가 안다.
- 노트 연결이 필요하면 본문(Why)에 `[[링크]]` — `related` frontmatter 키 금지(소비자 없음).
- 🔴 **§Why 에 레포 문서 포인터** — 지식이 레포 문서를 근거로 하면 경로를 평문으로 적는다(`docs/develop/feature/FEAT-0000N-<slug>.md`). 볼트 밖은 `[[]]` 로 못 간다.
  - 목적: 저장은 분리(볼트=관측 · 레포=정본), **조회는 단일**(볼트에서 찾고 레포에서 읽는다).
- `sessions/` 링크 허용 — 단 §Why 는 링크 없이 완결이어야 한다. 근거는 파일:줄·명령 출력·커밋 해시.

### `_index.md`

- 줄 형식: `- [[<stem>]] (kjp, org) — <summary>`.
- recall·brain-recall은 노트 frontmatter를 열지 않고 인덱스 grep으로 scope 필터.
- memory 노트 생성·갱신과 `_index.md` append는 같은 커밋.
- 🔴 세션 커밋과 memory 승격 커밋을 섞지 않는다(0.3.2) — `sessions/` 가 git 추적으로 바뀌어 한 커밋에 담기면 dreaming 계수·`git revert` 단위가 흐려진다.

## 세션 노트 스키마

```yaml
# sessions/kjp_20260813_rebuild.md   ← 파일명 = <id>_<YYYYMMDD>_<slug>.md, 파일명이 곧 식별자
---
status: active        # active | parked | done — 쓰기 권한: ss=active 생성 · sr=active 복원 · sh=parked · sc=done
project: kjp          # 프로젝트 식별자 (scope와 같은 어휘)
updated: YYYY-MM-DD
related_ticket: KJP-12   # 없으면 빈 값
cc_session_ids: [<uuid>] # 최신을 앞에 prepend
---
## Goal       ← 한 줄
## Recall     ← ss가 주입한 결과 기록 (파일 수·바이트 포함)
## To-Do      ← bullet — 남은 일·pending 마커
## Progress   ← 최신 엔트리가 맨 위. bullet만, 줄글 금지
```

- 키는 5개(status·project·updated·related_ticket·cc_session_ids) — 신키 추가 금지.
- status 어휘 3값 — cancel 없음. 방치 세션도 done으로 닫는다.
- 유일성: ss는 생성 전 동일 파일명 존재 검사 — 존재하면 자동 접미사 금지, 사용자에게 구분 slug 질문.
- 유일성 근거: 파일명이 곧 식별자다 — 같은 이름 두 세션은 이력이 섞인다. (0.3.2 이전 근거였던 "git 밖이라 복구 불가" 는 §볼트 구조 전환으로 소멸.)
- 절별 쓰기 주인: Goal·Recall=ss / To-Do=수시(PM) / Progress 기계(스킬) 쓰기=sh(parked)·sc(completed)만 — ss는 안 쓴다(세션 파일 생성 자체가 시작 증거) · sr도 안 쓴다(cc_session_ids prepend가 재개 증거) · 헤딩 어휘 4값(started|resumed|parked|completed)은 유지, started·resumed는 사람 수동 기록용.

## 세션 4절 작성 양식 (정본 — 유일 사본)

- 고정 양식 — 에이전트 자유 서식 금지. 이 절이 스킬이 Read하는 양식 정본이다.
- 강제 ①생성 시점: ss·sh·sr·sc는 작성 전 이 절을 Read하고 그대로 따른다. 스킬 문서에 양식 사본 금지 — 포인터만(사본 4개 = 드리프트).
- 강제 ②사후: brain-validate가 헤딩·접두 어휘를 검사한다.

```markdown
## Goal
빌드 검사기 3종을 0.3.0 스펙으로 신규 작성          ← 한 줄만. 바뀌면 덮어씀(이력은 Progress가)

## Recall
- 3건 · 2,410B 주입 (scope: kjp) · 절단 0건        ← ss가 계수 라인 1줄
- [[obsidian-cli_silent-fork]] · [[plane-cli_uuid]]  ← 주입한 노트 stem 목록

## To-Do
- [ ] brain-check.sh 작성
- [x] 스키마 확정
- [ ] ASK: 8KiB 상한 값 재확인                      ← 사용자 입력 대기는 ASK: 접두

## Progress
### 2026-08-13 15:30 (parked)              ← 헤딩 = 날짜 시각 (started|resumed|parked|completed) — 시각 필수
- done
  - brain-check.sh 골격 작성 — brain/hooks/brain-check.sh    ← 산출 경로는 done 줄에 포함
  - selftest 픽스처 볼트 생성
- learned
  - PostToolUse stderr+exit 2 만 모델 피드백 채널
  - matcher에 NotebookEdit 누락 실수 → 추가로 복구            ← 실수도 여기 — `실수 → 복구` 형태 의무
  - 볼트-적중 [[obsidian-cli_silent-fork]] — 포크 함정을 처음부터 피함    ← 주입 노트가 실제로 쓰였다
  - 볼트-공백 plane CLI 세션 프로젝트 드리프트 — 노트 없어 404 한 번      ← 노트가 없어서 틀렸다
- next
  - selftest 픽스처부터                    ← 파킹 시 필수 — 하위 1줄만(재개 첫 행동)
```

### Progress 규칙 — 중첩 카테고리 3종

- 엔트리 헤딩 = `### YYYY-MM-DD HH:MM (started|resumed|parked|completed)` — 시각 필수(하루 다중 파킹·재개의 순서 보장).
- 최신 엔트리가 맨 위.
- 중첩 카테고리 3종 = `done` `learned` `next` — 순서 고정: done → learned → next.
- 카테고리 줄은 `- done` 고정 표기 — 콜론·부가 텍스트 금지(파서 앵커). 사실은 하위 bullet.
- 같은 카테고리 반복 금지 — 하위에 줄 추가. 빈 카테고리는 줄 생략.
- `next`는 하위 1줄만 — 재개 첫 행동. 파킹 시 필수.
- 산출 경로는 done 줄에 포함 — output 칸 폐지.
- 실수는 learned 하위에 `실수 → 복구` 형태 의무 — mistake 칸 병합. 실수 은폐가 실측되면 mistake 재분리(validate 어휘 1줄).
- 🔴 **볼트 효능 측정 — learned 하위 접두 어휘 2종**(0.3.2 신설).
  - `볼트-적중 [[<stem>]] — <어떻게 도움됐나>` · `볼트-공백 <주제> — <노트가 없어 무엇을 틀렸나>`.
  - 주입만 있고 효과 기록이 없으면 볼트의 값을 판정할 수 없다 — 집계는 `grep -c` (코드 0줄).
  - 근거(2026-08-20 실측): 세션 6건 전수에 주입 계수는 있으나 "그 노트가 도움됐다" 기록 0건. 주입 0건 세션이 6건 중 3건.
  - 소비자 = 사람(2주 주기 적중/공백 비율로 볼트 확대·축소 판정). 자동 소비자 없음 — 강제하지 않고 기록만 한다.
- 카테고리 소비자: done=sr 맥락 / learned=sc 승격 수확 / next=sr 재개 — 소비자 없는 카테고리 추가 금지.

## 프로젝트 식별자 — 2키 분리

- `project: kjp`(소문자) — 세션 파일명·scope 담당.
- `ticket-prefix: KJP`(대문자) — `related_ticket` 표기·검증 담당.
- 두 키 각각 명시 선언 — 대소문자 자동 변환 금지(명시 선언 원칙 위반).
- 출처 = AGENTS.md brain config. 경로 파생 금지(claude-mem 파편화 4건 실측 근거).

## 승격 — 2게이트

- 게이트 ①(sc): 세션에서 남길 것(사용자 정정·AI 자인 실수·재사용 가치 사실) → `memory/<topic>.md` 생성/갱신 + `_index.md` 같은 커밋 append.
- 승격 쓰기 주체 = PM 직접 Write/Edit — scribe 폐지.
- 🔴 **승격 구간은 볼트 락 안에서**(0.3.2 신설) — `<vault>/.vault.lock` mkdir 원자 획득 → 승격+`_index.md` append+커밋 → 해제.
  - 획득 실패 = 다른 세션이 승격 중. **대기하지 말고 skip 후 사용자에게 보고**(fail-visible). 자동 재시도 금지.
  - 근거(2026-08-20 실측): peer 세션 13개가 동시에 돌고, 한 볼트에 uncommitted 노트 20건이 쌓인 채 발견됐다. `_index.md` append 충돌은 조용한 유실이다.
  - `.dreaming.lock` 과 별개 — dreaming 은 배치, 이건 승격 1회. 둘 다 볼트 `.gitignore` 대상.
- 게이트 ②(dreaming): 같은 교훈이 타 프로젝트에서 확인 → scope에 식별자 추가 1줄 편집.
- 게이트 ②에 git mv·링크 재배선 없음.

## recall — ss/sr 주입

- 주입 재료 = ①채택 세션 요약(awk 추출 — sr만, ss는 인덱스만) ②`_index.md`에서 현재 프로젝트 scope 행만.
- sr 세션 요약 = 3요소 한정: Goal + 미완 To-Do(`- [ ]`)만 + 최신 Progress 엔트리 1개 — 그 외 절대 미주입.
- 과거 Progress 엔트리는 저장만(주입 비용 0) — 필요 시 on-demand Read.
- org·타 프로젝트 행은 "N건 — 요청 시" 1줄 포인터.
- 하드 상한 8KiB — 초과분은 절단.
- fail-visible: 파일 수·바이트·잘린 수를 상시 보고 — 0도 0이라 말한다.

## brain-recall — on-demand 질의

- `brain-recall <query> [--scope <id>] [-n N]` — 기본 `-n 3`(0.3.2, 이전 5). 노트 본문 통째 반환이라 기본값이 곧 토큰 비용이다.
- summary grep 매칭 top-N 본문 반환 — 트리거는 summary가 겸한다(§memory 노트 스키마).
- read-only · bash · 의존성 0.
- 타 에이전트(codex·grok)의 볼트 소비 경로.

## dreaming — 배치 통합

- 연산 2종: Refine(사실 불변 정제) · 승격 ②(scope 확장).
- Link 연산 폐지 — `related` 키는 소비자 없음(recall·brain-recall 모두 안 읽음, 0.2.x YAML 붕괴 354건·재배선 세금 실측).
- 운영: 볼트 원자 락 · 증분 커서(마지막 성공 커밋) · 1 run 1 commit — 나쁜 run = `git revert` 1개.
- 락 = `<vault>/.dreaming.lock` — mkdir 원자 획득 · 실행 종료 시 제거 · 존재하면 skip · 볼트 .gitignore 대상(`.vault.lock` 도 같이).
- 커서 = `<vault>/.dreaming-cursor` 1줄(마지막 성공 run의 커밋 해시) — git 추적, 커서 갱신도 1 run 1 commit에 포함(revert 시 커서도 같이 복귀).
- worktree 격리 없음 — 락 + CAS + 1 run 1 commit이 대체.
- 파괴적 변경(merge·delete·move)은 제안-승인 — 자동 덮어쓰기 금지.
- 트리거: sc가 실행하지 않는다 — 커서 이후 미통합 커밋 수를 세어 `dreaming 권장 — 미통합 N건` 1줄 제안만.
- 🔴 스캔·계수 대상은 `memory/` 경로 한정 — `git log <cursor>..HEAD -- memory/`. sessions 도 git 추적이라(0.3.2) 경로를 안 좁히면 세션 커밋이 미통합 수를 부풀린다.
- 실행 = 사용자 승인 또는 `/brain:dreaming`. 큐·cron 없음.
