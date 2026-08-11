---
status: draft
updated: 2026-07-25T12:00:00
---

# docs-samples — 통합안 검토용 시안 (2026-07-25)

> 🔴 **2026-07-25 시점 스냅샷이다. 현행 canon 이 아니다.** 이 트리는 그날의 검토안을 보존한 기록이고, 이후 0.2.0 랜딩이 최소 세 축에서 그것을 지나쳤다 — **정책**(`docs/policy/<PREFIX>-POL-0000N` 폴더형 → `docs/develop/P_POLICY.md` 단일 파일 + `## POL-NNN` 조항, KJP-79) · **경로 중첩**(`docs/develop/` 계층 신설, KJP-63) · **API_SPEC 생성 주체**(`dreaming` → PM 위임 동기화 워커, KJP-77). 현행 정본은 `brain/docs/` 와 `.artifact/brain-0.2.0.html` 이다.
>
> 고치지 않고 배너만 다는 이유 — **기록을 현재에 맞춰 고치는 것은 정합이 아니라 위조**다(`brain/docs/vault-tree.md` §Renaming a path term). 시안으로서의 값을 되살리려면 세 축을 함께 재생성해야 하고 그건 별건이다.

> 커밋·플러그인 반영 전 검토용. 가상 프로젝트 **vidnote**(유튜브 요약 노트 SaaS)로 채워진 모습을 보여준다.

## 사전 스텁 19 → 6

| 파일 | 흡수한 것 (구 채움율) |
|---|---|
| `PRD.md` | NFR(12%) · GLOSSARY(6%) |
| `ARCHITECTURE.md` | ERD(12%) · INTEGRATION |
| `CODE_CONVENTION.md` | FULL_TEST_PLAN(6%) |
| `RUNBOOK.md` | GIT_STRATEGY §Delivery(60%) · OBSERVABILITY · DR · MIGRATION |
| `THREAT_MODEL.md` | (독립 유지) |
| `BUSINESS.md` | BM(6%) · GTM(6%) |

- API_SPEC: 사전 생성 제외 — repo spec 미러라 dreaming 자동 생성.
- COMPLIANCE · DESIGN: situational 파일 잔존 (트리거 시 생성).

## 트리거 생성 문서 샘플 (사전 스텁 아님 — 참고용으로 동봉)

| 파일 | 트리거 | 비고 |
|---|---|---|
| `DESIGN.md` | UI 있는 제품일 때 | doc-templates canon 골격 그대로 — 픽셀 SSOT는 Figma, 여기는 링크+규칙 |
| `MILESTONE.md` | 단계별 딜리버리 계획 필요 시 (owner=pm) | when만 — what/why는 PRD·ADR, 태스크 상태는 트래커 |

## 기능 세트 6 → 3 (`feature/summarize/`)

| 파일 | 흡수한 것 |
|---|---|
| `FRD.md` | — (what) |
| `TDC.md` | DATA_FLOW · SEQUENCE · STATE_DIAGRAM → §Diagrams (how) |
| `policy/VDN-POL-00001.md` | — (기능 한정 규칙) |

## 표기 규칙
- H1 = 약어 + 풀네임 병기: `PRD (Product Requirements Doc — 제품 요구사항)`
- frontmatter v2: 베이스 2필드 `status` · `updated`(datetime)만. multi-instance(POL·ADR)만 `id` 추가, `history`는 optional (`{ at, change, ticket }`).
- 부재 시맨틱: 필드가 없으면 경로·본문이 말한다 — kind는 파일명, scope는 디렉터리, title은 H1.
- `session` 키 금지 — 세션 연결은 경계 커밋 메시지가 담당.
- delivery 프레임: org 단일 flow 폐기 → **분류표(프로젝트 유형→flow)가 결정**. beafter 분류표는 `000_common/facts/`(참조·비구속, 안정되면 policies 승격).
