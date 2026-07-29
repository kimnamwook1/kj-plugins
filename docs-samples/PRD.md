---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — NFR·GLOSSARY 흡수, ticket: "VDN-36" }
---

# PRD (Product Requirements Doc — 제품 요구사항)

## 목표
유튜브 영상 URL을 넣으면 타임스탬프 달린 요약 노트를 만들어주는 SaaS. 대상: 강의·컨퍼런스 영상을 자주 보는 개발자.

## 요구사항
- R1: URL 입력 → 3분 내 요약 노트 (자막 있으면 40초)
- R2: 노트는 Obsidian 호환 마크다운으로 내보내기
- R3: 무료 티어 월 10편, Pro 무제한

## 비기능 요구 (NFR — Non-Functional Requirements)
<!-- 구 NFR.md 흡수. 성능·가용성·보안 목표가 설계에 영향 줄 때 이 절을 채운다 -->
- 요약 파이프라인 p95 < 3분 (자막 경로 < 60초)
- 가용성 99.5% (개인 SaaS 티어 — [[ARCHITECTURE]] §배포 참조)
- 영상 원본은 저장하지 않는다 (저작권 — [[THREAT_MODEL]] §데이터)

## 용어 (Glossary)
<!-- 구 GLOSSARY.md 흡수. 도메인 용어가 모호해질 때 여기에 누적 -->
| 용어 | 뜻 |
|---|---|
| 노트 | 타임스탬프+요약 단락의 묶음 (영상 1개당 1노트) |
| 청크 | 자막을 LLM에 넘기는 분할 단위 (기본 10분) |

## 참조
- 수익 모델·채널: [[BUSINESS]] (§BM · §GTM)
- 기능별 상세: `feature/<F>/FRD.md`
