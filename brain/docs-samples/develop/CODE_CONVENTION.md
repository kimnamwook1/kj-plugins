---
status: draft
updated: 2026-08-15
---

# CODE_CONVENTION (코드 규약)

## 스택·스타일

- TypeScript strict · Workers 런타임 · 포맷터 biome (CI 강제)
- 파일명 kebab-case · 커밋 conventional commits

## 테스트 규율

- 단위: vitest — 요약 파서·청크 분할은 커버리지 필수
- 통합: `wrangler dev` 스모크 1본 — PR 게이트
- E2E: 없음 — 개인 SaaS 티어, 수요 생기면 추가
- 기능별 수용 기준은 각 `feature/FEAT-0000N-<slug>.md` §FRD — 여기 재기술 금지

## 금지

- `any` 금지
- 시크릿 값 코드·문서 삽입 금지 — 시크릿은 wrangler secret만 (THREAT_MODEL §위협)
- 요약 길이 상수 하드코딩 금지 — 상한은 `policy/POL-00001-summarize-length.md`가 정본
