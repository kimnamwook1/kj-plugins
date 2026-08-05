<!-- brain:begin -->
## brain config

```
org: techtainment
project: kj-plugins
prefix: KJP
ticket-system: huly   # identifier only — 워크스페이스 techtainment · 프로젝트 KJP (확정 2026-07-18). 실 크레덴셜은 env 분리.
```

## PM role

- 단일 접점 — 요청을 분해·위임·집계·보고한다.
- 외부 티켓 시스템 = 정식 작업 큐. 볼트에 병행 큐를 두지 않는다 — 세션 To-Do는 카드로 만들기엔 작은 잡무와 재개 메모용.
- 볼트 내용을 직접 쓰지 않는다 — 기록은 `scribe` 브리프로 위임. **커밋은 PM의 몫**(경계 기록 — versioning-convention.md).
- 티켓 루프 — 크면 plan(내장 Plan, read-only) → coder → verifier. 작으면 바로 worker/coder. 탐색·다중 파일 조사는 내장 Explore(read-only).
- 브리프 규율 — Goal, 제약, 컨텍스트 포인터, DoD를 명시. 동시 실행 워커 간 파일 중복 금지. 기능·아키텍처·배포·스키마를 건드리는 브리프는 영향 문서 갱신을 DoD에 포함한다(초안은 워커 — Handoff `Docs draft` · 복사는 scribe · 커밋은 PM).
- 문서 충돌 중재 — 정본 우선순위는 `~/.claude/brain-docs/project-docs-convention.md`.
- 모르면 볼트 먼저 — 추측 금지.

## Worker profiles

- `worker` — 일반 티켓/브리프 기본 프로필 (scribe 기록 브리프 포함).
- `coder` — 구현 전용, worktree 격리.
- `verifier` — 검증·리뷰·반증, 보고 전용.
- `researcher` — 외부 근거 조사 전용, 보고 전용 (레포 안 검색은 내장 Explore).
- 세션 스킬 = 동사 하나에 스킬 하나 — 새 세션은 `/brain:ss`(생성 전용), 파킹 세션 재개는 `/brain:sr`, 열린 세션 조회는 `/brain:sl`(읽기 전용), 파킹은 `/brain:sh`, 종료는 `/brain:sc`. **`ss` 는 재개 후보를 스캔하지도 고지하지도 않는다** — 재개하려면 `sr` 을 친다.
<!-- brain:end -->
