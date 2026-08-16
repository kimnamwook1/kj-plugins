---
status: draft
updated: 2026-08-15
---

# THREAT_MODEL (위협 모델)

## 자산·데이터

- 사용자 계정(이메일) · 노트 본문 · Stripe 고객 ID
- 영상·음성 원본은 자산 아님 — 저장하지 않는다 (`../adr/ADR-00001-no-source-retention.md`)

## 위협·완화

| 위협 | 완화 |
|---|---|
| URL 주입으로 내부 자원 fetch (SSRF) | youtube.com 도메인 allowlist — 파서 단 검증 |
| 무료 티어 남용 (스크레이핑) | Turnstile + 계정당 rate limit |
| API 키 유출 | 시크릿은 wrangler secret만 — 코드·문서 삽입 금지 (CODE_CONVENTION §금지) |
| 타인 노트 열람 (IDOR) | `/notes/:id` 소유자 검증 — 공유 기능 없음이 곧 완화 |
| Stripe webhook 위조 | 서명 검증 + 이벤트 ID 멱등 처리 |

## 미해결

- Stripe webhook 서명 검증 리허설 미실시 — M2 게이트 (MILESTONE §Milestones)
