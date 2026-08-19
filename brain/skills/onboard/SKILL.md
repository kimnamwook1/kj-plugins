---
name: onboard
description: grill식 프로젝트 인터뷰 — 1문 1답+추천답 제시, 코드로 답 가능하면 질문 대신 실측, 답이 굳는 즉시 레포 docs/ 해당 문서를 lazy 생성/갱신(project-docs.md 트리). ADR은 3중 게이트, 미결은 티켓 차팅, 환경 실측은 볼트 memory 노트(scope: [org]). "onboard", "프로젝트 인터뷰", "문서 채우기", "온보딩"에 사용. 전제 = init 완료 — 구조 설치는 init.
argument-hint: ""
---

# onboard — grill식 프로젝트 인터뷰 (내용 채우기)

- 산출의 집 = **레포 `docs/`** (트리·파일명·frontmatter 정본 = `${CLAUDE_SKILL_DIR}/../../docs/project-docs.md`). 환경 실측만 볼트 `memory/`.
- 전제: AGENTS.md/CLAUDE.md brain config + CLAUDE.local.md `vault-root:` — 없으면 `/brain:init` 먼저, 임의 경로에 쓰지 않는다.
- 실행 주체 = PM 직접 Write/Edit.

## grill 규율

- **1문 1답** — 일괄 배터리 금지. 한 질문이 굳은 뒤 다음 질문.
- **추천답 제시** — 질문마다 추천 답을 옵션으로 함께 제시(AskUserQuestion — 추천에 (권장) 표기). 사용자는 고르거나 고쳐 쓴다.
- **실측 우선** — 코드·설정으로 답할 수 있으면 질문하지 않는다: 스택 = 매니페스트(package.json 등) · 배포 = CI 설정·Dockerfile · 기존 docs/ 내용. 실측 결과는 "이렇게 읽었다 — 맞나"로 확인만.
- **답이 굳는 즉시 lazy 생성/갱신** — 해당 문서를 그 자리에서 쓴다. 스텁 사전 생성 금지("pre-created ≠ evidence") — 답 있는 문서만 존재한다. frontmatter 2키(`status: draft` · `updated: YYYY-MM-DD`) — 신키 금지.
- **문서별 종료 조건 명시** — 문서를 만들 때 "draft 최소 = <무엇이 채워지면 draft인가>"를 선언하고, 보고에서 도달 여부를 말한다.
- **미결 → 티켓 차팅** — 굳지 않은 질문·후속 조사는 brain config `ticket:` 시스템(plane 등)에 티켓으로 남긴다. `ticket: none`이면 세션 To-Do로.
- **오염 금지** — placeholder·빈 스켈레톤·`[Image #N]`·HTML 주석 금지(project-docs.md §오염 금지).

## 인터뷰 축 → 문서 매핑 (한 축씩 grill, 답 굳는 대로 기록)

- 목표·BM → `docs/business/PRD.md`
- 스택·구조 → `docs/develop/ARCHITECTURE.md` · `CODE_CONVENTION.md`
- 규제·민감 데이터 → `docs/business/COMPLIANCE.md`(**§Legal Sources 표 필수 — 열 고정·확인일 없는 행 인용 금지·1차 출처 korean-law MCP** — project-docs.md) · `docs/develop/THREAT_MODEL.md`
- 배포·운영 → `docs/develop/RUNBOOK.md`
- 답이 다른 문서(GTM·MILESTONE·DESIGN·INFORMATION_ARCHITECTURE)에 닿으면 project-docs.md 트리로 라우팅 — 닿을 때만 생성.
- 정책이 굳으면 → `docs/develop/policy/POL-0000N-<slug>.md` · 기능이 굳으면 → `docs/develop/feature/FEAT-0000N-<slug>.md`(§FRD·§TDC — 도메인 유일 명칭, 범용 동작어 금지).
- **ADR 3중 게이트** — 전부 통과할 때만 `docs/adr/ADR-0000N-<slug>.md`: ①되돌리기 어려움 ②맥락 없이는 의아함 ③진짜 트레이드오프의 결과. 대부분 0건이 정상 — 빈 ADR·사전 생성 금지. 연번 = 폴더 내 최고 ID + 1 스캔.

## 환경 실측 → 볼트 memory

- 머신·환경 사실(OS·주요 도구·MCP 등)은 질문이 아니라 실측 — 결과는 `memory/<topic>.md`:
  - 양식 = `"${CLAUDE_PLUGIN_ROOT}/scripts/brain-canon" note-schema` 출력 그대로(4키 · summary "언제+주장" 100자 이내 · `scope: [org]` · `kind: fact` · Insight/Why bullet만). 통째 Read 금지 · 본 문서에 양식 사본 없음.
  - `_index.md` 행 append — 노트와 **같은 커밋**(볼트 커밋 = PM · push 금지).
  - 같은 주제 기존 노트가 있으면 Edit 갱신(CAS) — 한 주제 두 노트 금지.

## 보고

- 생성/갱신 문서 목록 + 각 종료 조건 도달 여부(draft/미달) · 차팅한 티켓 목록 · memory 노트 경로 · 남은 미답 축 — 전부 0건도 0건이라 말한다(fail-visible).

## 금지

- 일괄 질문 배터리 · 답 없는 문서 생성(스텁·placeholder) · 게이트 미통과 ADR · 티켓 시스템 크레덴셜 기록 · 볼트에 문서 산출(문서의 집은 레포 docs/).
