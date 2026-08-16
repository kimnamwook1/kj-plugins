> 소비자: `onboard` — grill 인터뷰로 문서를 lazy 생성·갱신할 때. `sc` — 문서 라우팅(레포 docs) 시. `worker`·`coder` — docs/ 를 쓰는 브리프 수행 시. `brain-validate.sh`(레포 모드) — 검사 어휘의 기준.

# project-docs — 레포 docs/ 트리 · 파일명 · feature · COMPLIANCE · 정책 · ADR

- 정본 근거: `전서_0.3.0.md` §1.5 · §5.1.
- 문서의 집 = 레포 `docs/` — 코드와 같은 PR로 리뷰.
- 볼트↔레포 경계: 코드 PR과 함께 리뷰되면 레포 `docs/` · 세션에서 배웠으면 볼트 `memory/`. 레포에 지식 파일 금지.
- 멀티레포 = 주 레포 1곳 원본, 나머지는 포인터.
- API_SPEC 볼트 미러 없음.

## docs/ 트리

```
docs/
  research/
    .gitkeep
  business/
    PRD.md
    GTM.md
    COMPLIANCE.md           # §Legal Sources 표 필수
    MILESTONE.md
  develop/
    ARCHITECTURE.md
    INFORMATION_ARCHITECTURE.md
    CODE_CONVENTION.md
    RUNBOOK.md
    THREAT_MODEL.md
    DESIGN.md
    policy/                 # 프로젝트 및 기능 개발에 필요한 정책
      POL-0000N-<slug>.md   # 예시 POL-00001-login.md
    feature/
      FEAT-0000N-<slug>.md  # §FRD §TDC
  adr/
```

- 스텁 사전 생성 없음 — "pre-created ≠ evidence". 문서는 트리거 시(onboard 답변·기능 착수) 생성.
- 문서별 종료 조건(draft 최소 확정)은 onboard가 명시한다.

## 파일명 규칙 — POL·FEAT

- ID부 = 대문자 + dash + 숫자 5자리. slug = 소문자 kebab.
- 예: `POL-00001-login.md` · `FEAT-00001-checkout.md`.
- ADR ID(dash) 전례·memory 파일명(소문자 kebab)과 통일 — 사용자 확정 2026-08-15.

## feature 문서 — `docs/develop/feature/FEAT-0000N-<slug>.md`

- 구성 2절: `## FRD`(기능 요구 — what) · `## TDC`(기술 설계 — how).
- 쓰기 주인: 기능 브리프를 수행하는 **coder** — 같은 브랜치·같은 PR로 코드와 동행. 코드 없는 문서 작업이면 worker.
- 기능 명칭 = 도메인 내 유일 식별 명칭 — 범용 동작어(process·handle·manage) 금지. 린트 강제 없음(규약 1줄).
- 생성 시점 = 기능 착수 — 프로젝트 생성 시점에 만들지 않는다.

## COMPLIANCE — `docs/business/COMPLIANCE.md`

- 본문 필수 절 = `## Legal Sources` 표.
- 열 고정: `규범 | 구분(법률/시행령/시행규칙/고시) | 상태(시행중/제정예정/개정예정/입법예고) | 시행·적용일 | 적용여부(적용/일부/비적용/검토중) | 적용근거 | 조문 | 하위법령 | 확인일 | 근거 URL`.
- 비적용도 행으로 남긴다.
- 확인일 없는 행 인용 금지.
- 1차 출처 도구 = korean-law MCP.
- 기계 검사 = COMPLIANCE 존재 시 §Legal Sources 부재 = finding(brain-validate 레포 모드). 셀 내용 판단은 PM 몫.

## 정책 — POL 파일 · 우선순위 · override

- 집 = `docs/develop/policy/POL-0000N-<slug>.md` — 프로젝트 정책·기능 정책 공용(사용자 확정 2026-08-15).
- 우선순위: 볼트 memory 노트(`kind: policy`, `scope: [org]`) > 레포 `docs/develop/policy/POL-*`.
- 하위가 상위를 침묵 오버라이드 금지.
- 예외 절차 = override 레코드: 벗어나는 하위 문서에 상위 정책 ID · 사유 · 만료일을 남기고 close 보고에 포함.

## ADR — `docs/adr/`

- 생성 3중 게이트 — 전부 통과 시에만: ①되돌리기 어려움 ②맥락 없이는 의아함 ③진짜 트레이드오프의 결과.
- 대부분의 세션은 ADR 0건이 정상 — 빈 ADR·사전 생성 금지(결정이 있었다는 거짓 신호).
- ID 표기 = 대문자 + dash(전례 유지) — `brain-validate.sh` 레포 모드가 ID를 검사한다.
- 파일명·연번 발급: `ADR-0000N-<slug>.md`(POL·FEAT 규칙과 통일) · 연번 = 폴더 내 최고 ID + 1 스캔, PM 발급 — 카운터 파일 없음(상태 최소화. 사용자 승인 2026-08-15).

## frontmatter — 최소

- 키 2개: `status`(draft | approved) · `updated`(YYYY-MM-DD) — 확정(사용자 승인 2026-08-15).
- 신키 추가 금지 — 과설계 금지. 파생 가능한 값(제목=H1 · 종류=경로)은 키로 두지 않는다.

## DoD — 문서 갱신은 완료 조건
- 브리프가 기능·아키텍처·배포·스키마·정책을 건드리면 **해당 문서 갱신이 DoD 에 포함**된다 — PM 은 브리프 작성 시 명시하고, 워커는 안 냈으면 `Done` 을 쓰지 못한다.
- 검수 앵커 = Handoff `Outputs` 의 `docs:` 라인 — `<갱신 경로들> | none (docs-impact: none)`, 공란 불가(빈 줄은 "판정 안 함"과 구분 불가).
- 쓰기 주인: 코드 동행 = coder(같은 브랜치·같은 PR) / 문서만 = worker / 스코프 밖 발견 = `Docs draft` 초안 + PM 배치.

## 오염 금지

- 금지 3종: `[Image #N]` 잔존물 · HTML 주석 · placeholder(빈 스켈레톤·채움말).
- brain-validate가 오염 패턴(`\[Image #N\]` · HTML 주석 시작 토큰)을 finding으로 잡는다 — 코드펜스는 스킵.
- 워커 Handoff `Docs draft`에도 같은 금지가 적용된다.
