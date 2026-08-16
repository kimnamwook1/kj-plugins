---
status: draft
updated: 2026-08-15
---

# docs-samples — brain 0.3.0 시안 스냅샷 (2026-08-15)

> 이 트리는 **0.3.0 시안 스냅샷이다. canon이 아니다.** 정본은 `brain/docs/`(project-docs.md 등 규약 3종)이며, 여기는 전서_0.3.0.md §1.5 트리를 가상 프로젝트로 채워 보여주는 참고용이다.

## 가상 프로젝트: vidnote

- 유튜브 영상 URL → 타임스탬프 요약 노트 SaaS
- 식별자: `project: vdn` · `ticket-prefix: VDN`

## 트리 (전서 §1.5 미러)

| 경로 | 내용 |
|---|---|
| `business/` | PRD · GTM · COMPLIANCE(§Legal Sources 표) · MILESTONE |
| `develop/` | ARCHITECTURE · INFORMATION_ARCHITECTURE · CODE_CONVENTION · RUNBOOK · THREAT_MODEL · DESIGN |
| `develop/policy/` | `POL-0000N-<slug>.md` — 프로젝트·기능 정책 공용 |
| `develop/feature/` | `FEAT-0000N-<slug>.md` — §FRD·§TDC 2절 구성 |
| `adr/` | `ADR-0000N-<slug>.md` — 3중 게이트(불가역·의아·트레이드오프) 통과분만 |
| `research/` | 조사 산출물 대기 폴더 (빈 상태 = `.gitkeep`) |

## 파일명 규칙 (전서 §1.5 확정)

- ID부 = 대문자 + dash + 숫자 5자리: `POL-00001` · `FEAT-00001` · `ADR-00001`
- slug = 소문자 kebab: `summarize-length`
- 스텁 사전 생성 없음 — 문서는 트리거 시(onboard 답변·기능 착수) 생성

## frontmatter

- 최소 2키: `status` · `updated` — 나머지는 경로·본문이 말한다
