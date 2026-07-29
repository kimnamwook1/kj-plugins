---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — 독립 유지 (흡수 없음), ticket: "VDN-36" }
---

# THREAT_MODEL (위협 모델)

<!-- 독립 유지 — 보안·증적 성격이라 다른 문서에 섞지 않는다. 론칭 전 필수 1회 -->

## 자산·데이터
- 사용자 계정(이메일)·노트 본문 — 영상 원본은 저장 안 함 ([[PRD]] §NFR)

## 위협·완화
| 위협 | 완화 |
|---|---|
| URL 주입으로 내부 자원 fetch (SSRF) | youtube.com 도메인 allowlist |
| 무료 티어 남용 (스크레이핑) | Turnstile + 계정당 rate limit |
| API 키 유출 | 시크릿은 wrangler secret — 코드·문서 삽입 금지 ([[SECRETS_BOUNDARY]]) |

## 미해결
- Stripe webhook 서명 검증 리허설 미실시 — 론칭 게이트
