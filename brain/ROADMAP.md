# ROADMAP — 0.2.0

> 0.2.0 완성까지의 확정 설계 결정과 남은 작업. **현행 체계의 정본은 이 문서가 아니라 `docs/` 10문서다** — 여기는 아직 랜딩하지 않은 것만 적는다. 랜딩한 항목은 canon으로 옮겨지고 이 문서에서 지워진다. 0.2.0 컷과 함께 이 문서는 CHANGELOG로 흡수·소멸한다.

## 확정된 설계 결정 (2026-07-30, 미랜딩)

- **뇌 용어 개명** — `sessions/` → `hippocampus/` · `<project>/knowledge/` → `neocortex/`. recall·dreaming은 이미 뇌 용어라 불변. `candidates/`는 유지.
  - 실행 범위: canon+스킬+스크립트 전면 스윕 + **두 볼트**(techtainment·beafter) `git mv` + 프로젝트 Router 13곳 일괄. beafter 동반은 선택이 아니라 필수 — canon이 바뀌면 그쪽 스캔이 깨진다.
  - **스킬명 ss·sr·sl·sh·sc는 유지** — 호출 인터페이스라 개명하면 근육기억·기존 문서·세션 노트 안내 문구까지 연쇄 파손. 스킬 내부 서술만 뇌 용어로.
  - 미결 1건: canon 문서 파일명(`knowledge-convention.md` 등)까지 개명할지 — 스윕 설계 때 확정.
- ③·④와 **같은 스윕에서 실행** — 두 번 갈아엎지 않는다.

## D2

- **③ hippocampus(세션) 골격 재정의** — 세션 노트 스키마·작성법 정규화. Progress 포맷, To-Do 규율, cc_session_ids 조용한 실패 제거(KJP-52), 파킹·재개 기록 최적화. 개명 스윕과 동시 실행.
- **④ dreaming 재정의** — candidates 3갈래 라우팅 반영(현행 서술은 common 단일 목적지), 증분 스코프·감사 목록 재설계, recall-fix 신호 루프(already_known 반복 = 검색 결함) 정식화.

## D3

- **⑤ agents·skills·hooks 정규화** — 3프로필 규율 전수 재점검, 스킬 간 중복·모순 제거, force-delegate 활성화 여부 판단, 기억 주입 레이어 최적화.
- **기계 이빨 3종** — 드리프트를 사후 청소가 아니라 발생 시점에 차단:
  1. **쓰기 시점 검증** — scribe가 볼트에 쓰기 직전 자기 출력을 lint. (YAML 파싱 실패 270건(KJP-60)·cc_session_ids 빈 값(KJP-52)이 전부 이 부재에서 나왔다.)
  2. **canon 변경 → 인스턴스 마이그레이션 절차** — 규칙이 바뀔 때 기존 인스턴스(볼트 문서·프로젝트 하네스)를 따라오게 하는 표준 절차. (frontmatter v2 때 4회의 수동 대량 마이그레이션이 이 부재의 비용이었다.)
  3. **릴리스 게이트** — 컷·재설치·byte 검증의 자동화. ("레포에만 있으면 무효" 사고가 0.1.5→0.1.6, 0.1.6→0.1.7 두 번 재발했다. 버전 문자열 대조는 무의미 — byte 대조가 기준.)
- **머신 스코프 층 설계 (회사/개인)** — 분리 경계는 볼트 유지(개인=techtainment·회사=beafter). 남은 문제는 머신 사실의 이중 기록(같은 맥북을 두 볼트가 각자 서술 — 31KB vs 3KB 드리프트 실측). tools 층과 같은 머신-스코프 축으로 설계.
- **0.2.0 컷 + 전면 재적용** — CHANGELOG 확정 → bump → push → 재설치 byte 검증 → techtainment 12곳 재검증 + beafter 6곳 하네스 적용.

## 열린 티켓 접점 (Huly)

- KJP-52 cc_session_ids 빈 값 13건 → ③에 흡수
- KJP-59 frontmatter 미규정 키 71건 처분 (version 46건 스키마 판단 포함) → ③·⑤ 접점
- KJP-60 YAML 파싱 실패 270건 → 기계 이빨 1(쓰기 시점 검증)과 함께 해소
- KJP-61 참조 섹션 규약 신설 → ⑤ 접점

## 서명 대기

- techtainment `learned/` 잔류 1건 — «코드리뷰 봇과 보안스캐너는 다른 카테고리·보완관계» 노트의 org_policies 승격 (승인 시 이동·learned/ 소멸, 기각 시 candidates/로).
