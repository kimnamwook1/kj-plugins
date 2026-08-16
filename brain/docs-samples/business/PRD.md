---
status: draft
updated: 2026-08-15
---

# PRD (Product Requirements Doc — 제품 요구사항)

## 목표

- 유튜브 영상 URL 1개 → 타임스탬프 달린 요약 노트 1개를 만드는 SaaS
- 대상: 강의·컨퍼런스 영상을 자주 보는 개발자

## 요구사항

- R1: URL 입력 → 3분 내 요약 노트 (자막 있으면 40초)
- R2: 노트는 Obsidian 호환 마크다운으로 내보내기
- R3: 무료 티어 월 10편, Pro 무제한 — 가격은 GTM §가격

## 비기능 요구 (NFR)

- 요약 파이프라인 p95 < 3분 (자막 경로 < 60초)
- 가용성 99.5% — 개인 SaaS 티어 (`../develop/RUNBOOK.md` §배포)
- 영상·음성 원본은 저장하지 않는다 — `../adr/ADR-00001-no-source-retention.md`

## 용어 (Glossary)

| 용어 | 뜻 |
|---|---|
| 노트 | 타임스탬프+요약 단락의 묶음 — 영상 1개당 1노트 |
| 청크 | 자막을 LLM에 넘기는 분할 단위 — 기본 10분 |
| 자막 경로 | 유튜브 자막을 입력으로 쓰는 저비용 경로 |
| Whisper 경로 | 무자막 영상의 음성 전사 경로 — Pro 전용 |

## 참조

- 가격·채널: `GTM.md` · 법령 적용: `COMPLIANCE.md`
- 기능별 상세: `../develop/feature/FEAT-0000N-<slug>.md` §FRD
