---
status: draft
updated: 2026-08-15
---

# DESIGN (디자인 시스템 스펙)

## Overview

- vidnote 웹앱 2화면 (INFORMATION_ARCHITECTURE §화면 구조)
- 디자인 언어: 문서 중심 미니멀 — 노트가 주인공, 크롬은 침묵
- 픽셀 SSOT는 Figma — 이 문서는 링크 + 토큰명·상태 매트릭스·인터랙션 불변식만

## SSOT

- Figma: `figma.com/files/vidnote-lib` — 컴포넌트 라이브러리 포함

## Design Tokens

- Color: `--bg` `--ink` `--accent` — 라이트/다크 각 1세트, Figma variables와 동명
- Typography: Pretendard · 스케일 14/16/20/28 · 본문 400 제목 600
- Spacing·radius·elevation: 4px 그리드 · radius 8 · elevation 2단 (카드·모달)

## Components

| Component | States | Notes |
|---|---|---|
| URLInput | idle · validating · error | 에러는 인라인 — 모달 금지 |
| NoteCard | queued · summarizing · done · failed | 상태별 좌측 색 바 — FEAT-00001 §TDC 상태기계와 1:1 |
| PlanBadge | free · pro | 업그레이드 배너 진입점 (GTM §전환 퍼널) |

## States & Interactions

- 요약 진행 중 화면 이탈 자유 — 완료 시 토스트, 블로킹 스피너 금지
- failed 카드 클릭 → 사유 + 재시도 버튼 (Pro만 활성)

## Accessibility & Responsive

- 대비 AA · 포커스 링 유지 · 단일 컬럼 브레이크포인트 720px

## Open questions

- 다크모드 토큰 값 미확정 → Figma 라이브러리 v2에서 결정 — 되돌리기 쉬워 ADR 불요
