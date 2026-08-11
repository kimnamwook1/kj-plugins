# git-convention — 타입 어휘 · 표기 · 브랜치 · 워크트리 · 흐름 · 경계

> 프로젝트 유형(모바일·웹·SaaS·독립형)과 무관한 git 표면 공통 규칙. **flow 선택(GitHub Flow/GitFlow)·브랜치 운용은 각 프로젝트 `docs/develop/RUNBOOK.md` §Delivery 소관** — onboard 가 유형을 물어 추천한다.
> 🔴 이 문서가 하네스의 정본이다 (2026-07-28 승격 — 종전 정본이던 개인 `at` 스킬·볼트 미러는 이 문서를 가리킨다). 배포되는 플러그인은 사용자 개인 스킬에 의존할 수 없다.
> 🔴 **배포 환경은 여기 없다.** 환경 수·티어 = 볼트 공통층 `common_policy.md` §배포 분류 · **브랜치↔환경 매핑**과 게이트 실측값 = 프로젝트 `RUNBOOK.md` §배포 `### 환경`. 여기는 형식만 담는다.
> 문서 규약 → [[project-docs-convention]] · 트리 → [[vault-tree]]
>
> **2026-08-03 합병** — 구 `versioning-convention.md` 를 흡수했다. PR 제목 형식이 두 문서에 다른 값으로 적혀 있던 것이 합병의 직접 원인이다(§표면별 표기가 유일 정본). 절 제목은 인바운드 앵커를 살리기 위해 그대로 옮겼다.

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
- 🔴 **이 표가 다섯 표면의 유일한 정본이다.** 다른 절·다른 문서에서 형식을 재서술하지 않는다 — 재서술이 곧 드리프트다. 실측 2026-08-03: PR 제목이 이 표와 구 `versioning-convention` 에 다른 값으로 적혀 있었고, 그것이 이 합병의 원인이다.

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
- **알려진 마찰, 일부러 기록한다.** type 은 가변인데 브랜치만 개명이 불가능하다. 재분류는 티켓·커밋·PR 제목에서 싸고 push 된 브랜치에서는 불가능하다. 자주 문제가 되면 이 불릿이 재론의 진입점이다.
- **사람 브랜치 접두어는 에이전트의 소관이 아니다.** 레포의 `RUNBOOK §배포` 가 사람이 실제로 쓰는 이름을 **측정치**로 기록한다(`dev-<이름>` · `feature/*` 등). 에이전트는 어느 레포에서든 위 형식만 쓰고, 둘의 충돌은 보고할 측정치이지 해소할 대상이 아니다.

## 워크트리

- 코더 격리 = worktree. 브랜치는 위 형식.
- 워크트리 이름 = `<PREFIX>-<번호>-<slug>` — kebab · 소문자 · type 없음 (2026-07-28 사용자 확정).

## Share scope

- **git = SOT + 버전 관리** — history · diff · revert · blame · **rollback** 전부 git.
- **공유 표면 = 프로젝트 트리 + 공통층** (실제 루트는 볼트의 `.brain-paths` 매니페스트 — [[vault-tree]]). **세션 층은 그 밖에 있다** — 개인에게 스코프된 episodic log 다.
  - 스코프 정의와 강제는 별개다: **세션을 커밋할지는 볼트별 선택**이다. 팀 공유 볼트는 세션 폴더를 gitignore 하고(episodic log 는 개인 것, 절대 push 안 함), 솔로 볼트는 추적해도 된다(커밋이 백업을 겸함).
  - 세션이 공유 표면에 없을 수 있으므로, 공유 노트는 세션을 **plain uid 텍스트로 참조하고 `[[wikilink]]` 로 쓰지 않는다** — 그 세션이 없는 팀원 볼트에서 dangle 한다.
- **기기 간 동기화는 채널 하나만** — 두 시스템이 동시에 동기화하면 충돌이 따라온다(`git pull` = dirty/merge conflict).
- **동시성 2층**: 머신 안 = `scribe` 규율(락 없음 — PM 이 겹치지 않게 위임) / 머신 간 = git merge.
- **커밋 주체 = PM**, 시점 = 세션 수명주기(handoff · complete). `scribe` 는 커밋하지 않는다 — 커밋은 레포 전체를 삼켜 다른 scribe 의 미완성 작업까지 쓸어담는다.
- **경계 커밋 메시지에 세션 uid 를 넣는다.** docs frontmatter 는 `session` 키를 갖지 않으므로([[project-docs-convention]] §history & session linkage) 커밋 메시지가 세션↔문서 연결의 유일한 채널이다.
- **자동 커밋 금지** — 쓰기마다 훅(PostToolUse)으로 커밋하면 히스토리가 툴콜 단위 노이즈가 되고 revert 지점이 사라진다.
- **push 는 사용자가 명시적으로 말할 때만.**

## Worktree integration order (PM)

**머지를 확인하고 나서 지운다. 순서를 뒤집지 않는다.**

1. **`git worktree remove <path>`** — 워크트리에 체크아웃된 브랜치는 아예 삭제되지 않으므로 이게 먼저다.
2. **머지** — 코더의 브랜치(`<type>/<PREFIX>-<번호>-<slug>`, Handoff `Outputs` 첫 줄에 보고됨)를 통합 브랜치로. **보고된 이름 그대로 머지하고 재구성한 이름을 쓰지 않는다** — `<type>` 세그먼트 때문에 티켓 ID 만으로 브랜치 이름을 유도할 수 없다.
3. **`git branch -d` 로 삭제 — `-D` 금지.** `-d` 는 완전히 머지되지 않은 브랜치를 거부하므로 도구가 2단계를 스스로 강제한다. 그 거부가 곧 확인이다. `-D` 는 그 가드를 브랜치와 함께 지우고, 마지막 ref 가 사라지는 순간 미머지 커밋은 도달 불가가 된다.
4. 하네스가 남긴 **`worktree-agent-<hash>`** 브랜치도 같은 방식. 자기 커밋이 없고 베이스를 가리키므로 `-d` 로 지워진다.

- 실측 2026-07-26 (KJP-45), 네 동작 전부: 워크트리에 체크아웃된 브랜치에 `-d` → `error: cannot delete branch … used by worktree at …` · 미머지 브랜치에 `-d` → `error: the branch … is not fully merged` · 같은 것에 `-D` → 삭제되고 커밋 고아화 · 빈 하네스 브랜치에 `-d` → 삭제됨.
- **이게 취향이 아니라 canon 인 이유** — 2026-07-25: 코더 베이스가 diverge 해 fast-forward 가 실패했는데 정리가 브랜치를 **먼저** 지웠다. 복구는 커밋 객체를 해시로 지목해서야 됐다.
- **stale 베이스는 부주의가 아니라 구조다.** 워크트리 브랜치는 `origin/<branch>` 에서 잘리고(실측 2026-07-26 — 브랜치 자신의 reflog 에 `branch: Created from origin/main`), 이 canon 은 사용자 말이 있을 때만 push 하므로 `origin/` 은 설계상 로컬보다 항상 뒤처진다. 코더의 베이스 확인(`agents/coder.md` §First action)이 상시 대응책이다 — **자동 push 로 "고치지" 말 것.** 확인 가능한 staleness 를 묻지 않은 발행과 바꾸는 셈이다.

## Pull / merge requests

**PR 이 필요한지는 취향이 아니라 리모트에 묻는다.** 두 경로가 있고 레포가 고른다. PM 이 고르지 않는다.

```bash
gh api "repos/$OWNER/$REPO/rulesets" --jq '[.[] | select(.enforcement == "active")] | length'
gh api "repos/$OWNER/$REPO/branches/$BRANCH/protection" >/dev/null 2>&1 && echo protected
```

- 🔴 **둘 다 돌린다.** classic branch protection 과 ruleset 은 별개 시스템이고 어느 쪽이든 브랜치를 게이트할 수 있다. 실측 2026-07-26: `kimnamwook1/rss-proj` 는 classic 엔드포인트에서 `Branch not protected`(HTTP 404) 를 돌려주는데 **활성 ruleset 이 PR 을 강제**하고 있었다 — 앞의 것만 봤으면 모든 직접 push 를 거부하는 레포를 "보호 없음"으로 보고했을 것이다.
- **게이트 없음 → 로컬 경로.** 코더가 브랜치를 넘기고 PM 이 로컬 머지한다(§Worktree integration order). push 도 PR 도 없다. 실측 2026-07-26: `kimnamwook1/kj-plugins` 는 `rulesets` = `[]` 이고 classic 404 — **이 레포가 그 경우다.**
- **게이트 있음 → PR 경로.** 깔끔해서가 아니라, `bypass_actors: []` 면 소유자를 포함해 누구도 직접 push 로 착지시킬 수 없기 때문이다. PR 이 리모트가 받아들이는 유일한 전달 수단이다.

**누가 만드나: 코더가 *draft* 를 열고 PM 이 ready 로 넘긴다.**

- **draft 는 제출이지 발행이 아니다** — draft PR 은 머지될 수 없고, 머지가 이 canon 이 PM 에게 남긴 행위다. "커밋 주체는 PM" 이 온전히 유지되고 코더는 아무것도 착지시키지 않는다.
- **`Docs draft` 와 같은 축**(`agents/*.md` Handoff): **내용 = 일한 사람 · 릴리스 = PM.** 코더가 PR 본문을 쓰는 것은 무슨 일이 있었는지 아는 유일한 당사자이기 때문이고, PM 이 ready 로 바꾸는 것은 검증한 유일한 당사자이기 때문이다.
- **PM 병목을 만드는 게 아니라 없앤다.** CI 는 draft 의 첫 push 에 돈다. PM 이 볼 때쯤 체크는 이미 초록이거나 이미 빨갛다.
- 🔴 **PR 제목·브랜치 형식은 §표면별 표기 표가 정본이다. 여기 다시 적지 않는다.**

**push 예외, 좁게 서술한다.** "사용자가 말할 때만 push" 는 **발행된 히스토리 — 통합 브랜치**를 규율한다. 게이트가 걸린 레포에서는 코더 자신의 토픽 브랜치까지 규율할 수 없다. 그러면 작업이 아무에게도 전달되지 못한다 — 게이트가 직접 push 를 막고, PR 은 브랜치가 리모트에 있어야 열린다. 그래서 코더는 **자기 토픽 브랜치만, 그것만, 위 측정이 게이트를 보였을 때만** push 할 수 있다. `main` 은 어느 레포에서도 사용자 말 없이 push 되지 않는다.

## Exception to the PM No-Write Rule

- **`git add` 와 `git commit` 은 PM 이 한다.** PM 은 볼트 **콘텐츠**를 쓰지 않는다(그건 `scribe`). 커밋은 콘텐츠 저작이 아니라 **경계 기록**이고, 커밋이 레포 전체를 삼키므로 전체를 보는 자만 안전하게 할 수 있다.
