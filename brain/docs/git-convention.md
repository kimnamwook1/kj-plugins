> 소비자: PM — 커밋·머지·브랜치·워크트리 정리·PR 게이트 판정 시. `coder` — 브랜치 생성·draft PR 시.

# git-convention — 타입 어휘 · 표기 · 브랜치 · 워크트리 · PR

- 프로젝트 유형(모바일·웹·SaaS·독립형)과 무관한 git 표면 공통 규칙.
- flow 선택(GitHub Flow/GitFlow)·브랜치 운용·배포 환경 매핑·게이트 실측값 = 각 프로젝트 `docs/develop/RUNBOOK.md` 소관 — 여기는 형식만 담는다.

## 타입 어휘 — Conventional Commits 표준 11개

`feat` · `fix` · `docs` · `style` · `refactor` · `perf` · `test` · `build` · `ci` · `chore` · `revert`

- 정의 원문의 상위 정본 = `@commitlint/config-conventional` `type-enum`.
- 새 타입 발명 금지 — 프로젝트 사정으로 깎거나 늘리지 않는다.
- 하나의 어휘가 네 표면(티켓·커밋·PR·브랜치)을 지배한다 — 표기만 다르다.

## 표면별 표기

| 표면 | 형식 | 예 |
|---|---|---|
| 티켓 제목 | `[type] 대상+증상` | `[fix] ArgoCD 앱 11개 상시 Progressing` |
| 커밋 제목 | `type(scope): 요약` | `ci(youtube-stts): bump image to 4426c48f` |
| PR 제목 | `type(<PREFIX>-<번호>): 요약` | `feat(KJP-4): recall 랭커 신설` |
| 브랜치 | `<type>/<PREFIX>-<번호>-<slug>` | `feat/KJP-46-pr-mr-canon` |
| 워크트리 | `<PREFIX>-<번호>-<slug>` | `KJP-46-pr-mr-canon` |

- `<PREFIX>` = AGENTS.md brain config `ticket-prefix:` 값(대문자) — 명시 선언, 파생 금지.
- 티켓에 `type(scope):` 금지, 커밋에 `[type]` 금지.
- 제목은 "무엇이"까지 — 원인·왜는 description·댓글.
- 이 표가 다섯 표면의 유일한 정본이다 — 다른 절·다른 문서에서 형식 재서술 금지(재서술이 곧 드리프트 — PR 제목 이중 서술 실측 2026-08-03이 근거).

## 타입 판정

- 여러 type에 걸치면 쪼갠다.
- `chore`는 잔여 범주 — 나머지 10개가 안 맞을 때만.
- 의존성 업데이트 = `build`. GitOps 매니페스트 = `ci`.
- 포매터·린터: 설정만 = `build`, 포매팅된 코드가 남으면 = `style`.
- 조사·스파이크는 산출물로 판정 — 보고서가 완료 조건이면 `docs`, 수정이 나오면 후속 카드로 해당 type.

## 브랜치 네이밍

- `<type>/<PREFIX>-<번호>-<slug>` — kebab · 소문자 · type 포함 전체 40자 상한.
- 티켓 없으면 `<type>/<PREFIX>-adhoc-<slug>`.
- slug = 티켓 제목의 kebab화 — 상한 초과 시 slug만 줄인다. type·ID는 안 줄인다.
- 브랜치는 PR이 열리면 개명 불가한 유일한 표면 — type 재분류 정정은 PR 제목이 싣고 브랜치는 유지.
- 사람 브랜치 접두어는 에이전트의 소관이 아니다 — 에이전트는 어느 레포에서든 위 형식만 쓰고, 충돌은 보고할 측정치이지 해소할 대상이 아니다.

## 워크트리

- 코더 격리 = worktree — CC `isolation: worktree` 기본.
- Orca가 workspace worktree를 연 세션은 isolation off — 격리 주인 1개.
- 워크트리 이름 = `<PREFIX>-<번호>-<slug>` — kebab · 소문자 · type 없음(2026-07-28 사용자 확정).

## 커밋·push 규율

- 커밋 주체 = PM — 커밋은 레포 전체를 삼키므로 전체를 보는 자만 안전하게 한다.
- 자동 커밋 금지 — 쓰기마다 훅 커밋은 히스토리를 툴콜 단위 노이즈로 만들고 revert 지점을 지운다.
- push는 사용자가 명시적으로 말할 때만 — 통합 브랜치 규율(좁은 예외는 §Pull / merge requests).
- 볼트 git(0.3.2): `sessions/`도 **git 추적**한다 — `.gitignore` 대상은 `.dreaming.lock`·`.vault.lock` 뿐. 휘발성은 주입 정책이 정하지 git 위치가 아니다(정본: `memory.md`).
- 🔴 볼트 커밋은 **2개로 분리** — ①승격(노트 + `memory/_index.md`) ②세션(`sessions/<파일>`). 합치면 dreaming 계수(`-- memory/`)와 `git revert` 단위가 흐려진다.
- dreaming = 1 run 1 commit(정본: `memory.md`). 승격 구간은 `.vault.lock` 안에서 — 획득 실패 시 대기 없이 skip 후 보고.

## Worktree integration order (PM)

머지를 확인하고 나서 지운다 — 순서를 뒤집지 않는다.

1. `git worktree remove <path>` — 워크트리에 체크아웃된 브랜치는 아예 삭제되지 않으므로 이게 먼저다.
2. 머지 — 코더의 브랜치(Handoff `Outputs` 첫 줄에 보고됨)를 통합 브랜치로. 보고된 이름 그대로 머지한다 — `<type>` 세그먼트 때문에 티켓 ID만으로 브랜치 이름을 유도할 수 없다.
3. `git branch -d`로 삭제 — `-D` 금지. `-d`는 미머지 브랜치를 거부하므로 도구가 2단계를 스스로 강제한다 — 그 거부가 곧 확인이다. `-D`는 그 가드를 지우고, 마지막 ref가 사라지는 순간 미머지 커밋은 도달 불가가 된다.
4. 하네스가 남긴 `worktree-agent-<hash>` 브랜치도 같은 방식 — 자기 커밋이 없고 베이스를 가리키므로 `-d`로 지워진다.

- 실측 2026-07-26 (KJP-45): 체크아웃 중 브랜치 `-d` → `error: cannot delete branch … used by worktree at …` · 미머지 `-d` → `error: the branch … is not fully merged` · 같은 것 `-D` → 삭제되고 커밋 고아화 · 빈 하네스 브랜치 `-d` → 삭제됨.
- 순서를 뒤집은 사고 실측 2026-07-25: diverge한 코더 브랜치를 먼저 지워 복구에 커밋 해시 지목이 필요했다.
- stale 베이스는 부주의가 아니라 구조다 — push는 사용자 말이 있을 때만이므로 `origin/`은 설계상 로컬보다 뒤처진다. 자동 push로 "고치지" 말 것 — 코더의 베이스 확인이 상시 대응책.

## Pull / merge requests

PR이 필요한지는 취향이 아니라 리모트에 묻는다 — 레포가 고르고 PM이 고르지 않는다.

```bash
gh api "repos/$OWNER/$REPO/rulesets" --jq '[.[] | select(.enforcement == "active")] | length'
gh api "repos/$OWNER/$REPO/branches/$BRANCH/protection" >/dev/null 2>&1 && echo protected
```

- 둘 다 돌린다 — classic branch protection과 ruleset은 별개 시스템이고 어느 쪽이든 브랜치를 게이트한다. 실측 2026-07-26: classic 404인데 활성 ruleset이 PR을 강제한 레포(`kimnamwook1/rss-proj`).
- 게이트 없음 → 로컬 경로 — 코더가 브랜치를 넘기고 PM이 로컬 머지(§Worktree integration order). push도 PR도 없다.
- 게이트 있음 → PR 경로 — `bypass_actors: []`면 소유자도 직접 push 불가, PR이 유일한 전달 수단.
- 누가 만드나: 코더가 draft를 열고 PM이 ready로 넘긴다 — draft는 제출이지 발행이 아니다. 내용 = 일한 사람 · 릴리스 = PM.
- CI는 draft의 첫 push에 돈다 — PM이 볼 때쯤 체크는 이미 초록이거나 빨갛다.
- PR 제목·브랜치 형식은 §표면별 표기가 정본 — 여기 다시 적지 않는다.
- push 예외, 좁게: 게이트가 걸린 레포에서 코더는 자기 토픽 브랜치만, 위 측정이 게이트를 보였을 때만 push. `main`은 어느 레포에서도 사용자 말 없이 push 되지 않는다.
