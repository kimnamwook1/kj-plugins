---
status: draft
updated: 2026-08-15
---

# MILESTONE (단계별 딜리버리 로드맵)

## Overview

- 2026 Q3 베타 → Q4 유료 전환, 3단계
- 경계: 여기는 **when만** — what/why는 PRD·FEAT·ADR, 태스크 상태는 트래커(Plane VDN)

## Milestones

| Milestone | Target | Scope (→ 문서) | Exit criteria | Status (→ tracker) |
|---|---|---|---|---|
| M1 베타 | 08-31 | FEAT-00001 summarize — 자막 경로만 | 지인 10명 온보딩 · p95 60초 | VDN 보드 M1 |
| M2 Whisper | 09-30 | PRD R1 잔여 — 무자막 경로 | Pro 결제 연동 · THREAT_MODEL 미해결 0 | VDN 보드 M2 |
| M3 공개 | 11-15 | GTM §채널 실행 | 유료 10명 · 해지율 측정 시작 | VDN 보드 M3 |

## Sequencing rationale

- 자막 경로 선행 — 편당 원가 10배 차이라 단위 경제 검증이 먼저 (GTM §가격)
- 원본 미보존 결정이 M2 설계의 전제 — `../adr/ADR-00001-no-source-retention.md`

## Dependencies & risks

- M2는 Stripe 심사 리드타임(외부) 의존
- YouTube API 쿼터 상향 거절 시 M3 지연 리스크
- 저작권법 적용 판정(COMPLIANCE §Legal Sources 검토중 행)이 M3 공개 게이트

## Out of scope

- 팀·협업 기능 — 트래커 백로그
- 모바일 앱 — 로드맵 밖
