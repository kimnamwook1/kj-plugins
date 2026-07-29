---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — doc-templates canon 골격 그대로, ticket: "VDN-36" }
---

# MILESTONE (마일스톤 — 단계별 딜리버리 로드맵)

<!-- 사전 스텁 아님 — "단계별 딜리버리 계획"이 필요해질 때 트리거 생성 (owner=pm, docs/ 루트 — planning/ 폴더 없음) -->
<!-- 경계: when만 기록. what/why는 PRD·FRD, 결정 근거는 ADR, 유동적 태스크 상태는 트래커 -->

## Overview
2026 Q3 베타 → Q4 유료 전환까지 3단계. 트래커 = Huly VDN 프로젝트.

## Milestones
| Milestone | Target | Scope (→ 문서) | Exit criteria | Status (→ tracker) |
|---|---|---|---|---|
| M1 베타 | 08-15 | [[FRD]] summarize (자막 경로만) | 지인 10명 온보딩 · p95 60초 | VDN 보드 M1 |
| M2 Whisper | 09-30 | [[PRD]] R1 잔여 (무자막 경로) | Pro 결제 연동 · [[THREAT_MODEL]] 미해결 0 | VDN 보드 M2 |
| M3 공개 | 11-15 | [[BUSINESS]] §GTM 채널 실행 | 유료 10명 · 해지율 측정 시작 | VDN 보드 M3 |

## Sequencing rationale
자막 경로 먼저 — 비용 10배 차이라 단위 경제 검증이 선행 ([[BUSINESS]] §BM). Whisper 도입 결정은 VDN-ADR-00001 예정.

## Dependencies & risks
- M2는 Stripe 심사 리드타임(외부) 의존
- YouTube API 쿼터 상향 거절 시 M3 지연 리스크

## Out of scope
- 팀·협업 기능 (트래커 백로그) · 모바일 앱 (로드맵 밖)
