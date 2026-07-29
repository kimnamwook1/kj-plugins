---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — FULL_TEST_PLAN 흡수, ticket: "VDN-36" }
---

# CODE_CONVENTION (코드 규약)

## 스택·스타일
- TypeScript strict · Workers 런타임 · 포맷터 biome (CI에서 강제)
- 파일명 kebab-case · 커밋 conventional commits

## 테스트 규율 (구 FULL_TEST_PLAN 흡수)
<!-- 프로젝트 공통 테스트 전략만. 기능별 수용 기준은 각 feature/FRD.md §수용 기준 -->
- 단위: vitest — 요약 파서·청크 분할은 커버리지 필수
- 통합: Workers 로컬(wrangler dev) 스모크 1본 — PR 게이트
- E2E: 없음 (개인 SaaS 티어 — 수요 생기면 추가)

## 금지
- `any` 금지 · 시크릿 값 코드 삽입 금지 ([[SECRETS_BOUNDARY]] 정책)
