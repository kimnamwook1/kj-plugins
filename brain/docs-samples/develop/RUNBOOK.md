---
status: draft
updated: 2026-08-15
---

# RUNBOOK (배포·운영 절차)

## Delivery

- 분류: 서버-SaaS — 배포 통제 주체 = 나, 실사용자 있음
- 브랜치: main 단일 + 기능 브랜치 — flow 규약은 canon `git-convention.md`

## 배포

- merge → stage 자동 · prod = 태그 범프 PR
- 롤백: 직전 태그로 되돌림 (`git revert` 후 재배포)

## 관측 (Observability)

- Workers analytics + 실패 잡 Discord 알림 — 임계: 실패율 5%/시간
- 검증: `npx wrangler tail vidnote-worker --format pretty` → 실패율 0.4%/h · Discord 웹훅 200 (2026-08-15)

## 재해 복구 (DR)

- D1 일 1회 export → R2 · 복구: `scripts/restore.sh <date>` — 분기 1회 리허설
- 검증: `scripts/restore.sh 2026-08-14 --dry-run` → `restore OK · notes=1204` (2026-08-15)

## 마이그레이션 (Migration)

- D1 migration 파일은 repo `migrations/` — 적용·롤백 명령 쌍으로 기록
- 검증: `npx wrangler d1 migrations list vidnote-db` → `4/4 applied` (2026-08-15)

## 원본 폐기 점검 (ADR-00001 집행)

- 주 1회: R2 버킷에 `audio/` 프리픽스 객체 0건 확인 — 1건이라도 있으면 사고 절차
- 검증: `npx wrangler r2 object list vidnote-export --prefix audio/` → 0건 (2026-08-15)
