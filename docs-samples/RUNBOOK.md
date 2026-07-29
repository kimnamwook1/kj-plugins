---
status: draft
updated: 2026-07-25T12:00:00
history:
  - { at: 2026-07-25T12:00:00, change: 통합안 시안 — GIT_STRATEGY·OBSERVABILITY·DR·MIGRATION 흡수, ticket: "VDN-36" }
---

# RUNBOOK (배포·운영 절차)

## Delivery (구 GIT_STRATEGY.md 흡수 — 배포 통제자 분류 + git flow)
<!-- onboard Q1/Q2 결과가 여기 기록된다. flow 값은 볼트의 delivery 분류 노트가 결정 — 여기 재기술 금지 -->
- 분류: **서버-SaaS** (Q1 내가 통제 · Q2 실사용자)
- git flow: 볼트 delivery 분류 노트 참조 → `000_common/policies/DELIVERY_STRATEGY.md` §3
  <!-- beafter 프로젝트라면 → 000_common/facts/delivery-classification.md (참조·비구속) -->
- 예외: **없음 — 분류표 준수**

## 배포
- merge → stage 자동 · prod = 태그 범프 PR (오버레이 stage+prod)
- 롤백: 직전 태그로 오버레이 되돌림 (`git revert` 후 sync)

## 관측 (Observability)
<!-- 구 OBSERVABILITY.md — 프로덕션 진입 시 이 절을 채운다 -->
- Workers analytics + 실패 잡 Discord 알림 (임계: 실패율 5%/시간)
- 검증: `npx wrangler tail vidnote-worker --format pretty | head -3` → 실패율 0.4%/h · Discord 웹훅 200 (2026-07-25)

## 재해 복구 (DR — Disaster Recovery)
<!-- 구 DR.md — 데이터 유실이 사업 리스크일 때 채운다 -->
- D1 일 1회 export → R2. 복구 절차: `scripts/restore.sh <date>` (분기 1회 리허설)
- 검증: `scripts/restore.sh 2026-07-24 --dry-run` → `restore OK · notes=1204` — Q3 리허설 (2026-07-25)

## 마이그레이션 (Migration)
<!-- 구 MIGRATION.md — 스키마 변경 시 절차를 여기 누적 -->
- D1 migration 파일은 repo `migrations/` — 적용·롤백 명령 쌍으로 기록
- 검증: `npx wrangler d1 migrations list vidnote-db` → `4/4 applied` (2026-07-25)
