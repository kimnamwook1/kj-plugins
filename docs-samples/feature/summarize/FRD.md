---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — 기능 세트 3종의 what, ticket: "VDN-36" }
---

# FRD (Feature Requirements Doc — 기능 요구사항) · summarize

## 무엇
URL 1개 → 타임스탬프 요약 노트 1개. PRD R1의 실행 스펙.

## 흐름 (사용자 관점)
1. URL 붙여넣기 → 즉시 잡 큐잉 응답 (동기 대기 없음)
2. 완료 시 노트 화면 + 알림. 실패 시 사유 노출 (자막 없음 → Whisper 안내)

## 수용 기준
<!-- 프로젝트 공통 테스트 규율은 CODE_CONVENTION §테스트. 여기는 이 기능의 통과 조건만 -->
- 자막 있는 20분 영상: 60초 내 노트 생성
- 자막 없는 영상 + Free 티어: Whisper 경로 차단 + 업그레이드 안내
- 같은 URL 재제출: 새 잡 대신 기존 노트 반환 (멱등)
