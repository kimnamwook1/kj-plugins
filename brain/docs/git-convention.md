# git-convention — 타입 어휘 · 표기 · 브랜치 · 워크트리

> 프로젝트 유형(모바일·웹·SaaS·독립형)과 무관한 git 표면 공통 규칙. **flow 선택(GitHub Flow/GitFlow)·브랜치 운용은 각 프로젝트 `docs/tech-design/GIT.md` 소관** — onboard 가 유형을 물어 추천한다.
> 🔴 이 문서가 하네스의 정본이다 (2026-07-28 승격 — 종전 정본이던 개인 `at` 스킬·볼트 미러는 이 문서를 가리킨다). 배포되는 플러그인은 사용자 개인 스킬에 의존할 수 없다.

## 타입 어휘 — Conventional Commits 표준 11개

`feat` · `fix` · `docs` · `style` · `refactor` · `perf` · `test` · `build` · `ci` · `chore` · `revert`

- 정의 원문의 상위 정본 = `@commitlint/config-conventional` `type-enum`.
- 새 타입 발명 금지. 프로젝트 사정으로 깎거나 늘리지 않는다.
- 하나의 어휘가 네 표면(티켓·커밋·PR·브랜치)을 지배한다. 표기만 다르다.

## 표면별 표기

| 표면 | 형식 | 예 |
|---|---|---|
| 티켓 제목 | `[type] 대상+증상` | `[fix] ArgoCD 앱 11개 상시 Progressing` |
| 커밋 제목 | `type(scope): 요약` | `ci(youtube-stts): bump image to 4426c48f` |
| PR 제목 | `type(<PREFIX>-<번호>): 요약` | `feat(KJP-4): recall 랭커 신설` |
| 브랜치 | `<type>/<PREFIX>-<번호>-<slug>` | `feat/KJP-46-pr-mr-canon` |
| 워크트리 | `<PREFIX>-<번호>-<slug>` | `KJP-46-pr-mr-canon` |

- 티켓에 `type(scope):` 금지, 커밋에 `[type]` 금지.
- 제목은 "무엇이"까지. 원인·왜는 description·댓글.

## 타입 판정

- 여러 type 에 걸치면 쪼갠다.
- `chore` 는 잔여 범주 — 나머지 10개가 안 맞을 때만.
- 의존성 업데이트 = `build`. GitOps 매니페스트 = `ci`.
- 포매터·린터: 설정만 = `build`, 포매팅된 코드가 남으면 = `style`.
- 조사·스파이크는 산출물로 판정 — 보고서가 완료 조건이면 `docs`, 수정이 나오면 후속 카드로 해당 type.

## 브랜치 네이밍

- `<type>/<PREFIX>-<번호>-<slug>` — kebab · 소문자 · type 포함 전체 40자 상한.
- 티켓 없으면 `<type>/<PREFIX>-adhoc-<slug>`.
- slug 는 티켓 제목의 kebab 화 — 상한을 넘으면 slug 만 줄인다. type·ID 는 안 줄인다.
- 브랜치는 PR 이 열리면 개명 불가한 유일한 표면 — type 재분류 정정은 PR 제목이 싣고 브랜치는 유지.

## 워크트리

- 코더 격리 = worktree. 브랜치는 위 형식.
- 워크트리 이름 = `<PREFIX>-<번호>-<slug>` — kebab · 소문자 · type 없음 (2026-07-28 사용자 확정).
- 사람 브랜치 접두어(`feature/*` 등)는 측정 대상이지 충돌 대상이 아니다 — 에이전트는 위 형식만 쓴다.
