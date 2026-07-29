---
id: VDN-POL-00001
status: draft
updated: 2026-07-25T12:00:00
# scope 필드 없음 — tier는 경로가 말한다: feature/summarize/policy/ = summarize 기능 한정
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — 기능 한정 규칙 예시, ticket: "VDN-36" }
---

# POL-00001 (Feature Policy — 기능 한정 규칙) · 원본 즉시 폐기

## 규칙
Whisper 경로에서 받은 음성 파일은 요약 완료 즉시 삭제한다. R2에 원본을 남기지 않는다.

## 근거
- 저작권 리스크 ([[THREAT_MODEL]] §자산) + 저장 비용.
- 이 규칙이 기능 2개 이상에 걸치게 되면 `docs/policy/`(project scope)로 승격.
