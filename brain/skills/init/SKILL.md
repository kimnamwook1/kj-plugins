---
name: init
description: brain 하네스 구조 설치 — 질문(vault-root·project·ticket-prefix·org·ticket) 후 AGENTS.md+CLAUDE.md에 공용 마커 블록 실작성(두 파일 바이트 동일), CLAUDE.local.md vault-root 1키, 볼트 sessions/+memory/+_index.md 스캐폴드, .gitignore 등록. 마커 블록만 교체 — 전체 덮어쓰기 금지. "init", "하네스 설치", "볼트 세팅", "브레인 설치"에 사용. 내용 인터뷰는 onboard.
argument-hint: ""
---

# init — 하네스 구조 설치 (기계적)

- 구조만 — 문서 내용 채우기(인터뷰)는 `/brain:onboard`.
- 실행 주체 = PM 직접 Write/Edit. 크레덴셜(토큰·키)은 어떤 파일에도 기록 금지 — 식별자만.

## 절차

1. **질문 — 값 5개** (AskUserQuestion·추측 금지):
   - `vault-root` — 절대경로. 제안 기본값 `~/Documents/Obsidian/second-brain/<org>`. 기록 전 `$HOME` 실확장 + 후행 `/` 제거 — 쓰기 경계 검사가 문자열 접두 비교라 `<root>`와 `<root>/`는 다른 문자열.
   - `project` — 소문자(세션 파일명·scope 담당) / `ticket-prefix` — 대문자(티켓 표기 담당). **2키 각각 명시 선언** — 대소문자 자동 변환 금지.
   - `org` — 볼트 경계 식별자.
   - `ticket` — 티켓 시스템 식별자만(plane 등) — 없으면 `none`.
2. **AGENTS.md + CLAUDE.md — 공용 마커 블록 실작성** (블록 정본 = `전서_0.3.0.md` §3.1 — 아래 그대로, 값만 치환):
   - **두 파일 동시 갱신 · 블록 바이트 동일 의무.** 기존 파일이 있으면 `<!-- brain:begin -->`…`<!-- brain:end -->` 사이만 교체 — 전체 덮어쓰기 금지. 파일이 없으면 블록만으로 생성. CLAUDE.md의 블록 밖 Claude 전용분은 보존.

   ```markdown
   <!-- brain:begin -->
   ## brain config
   project: <project>         # 소문자 — 세션 파일명·scope
   ticket-prefix: <TICKET-PREFIX>   # 대문자 — 티켓 표기
   org: <org>
   ticket: <ticket>        # 식별자만 — 크레덴셜 금지

   ## 필수 규칙
   - 지식은 볼트 memory/ 한 곳 — 레포에 지식 파일 금지. 조회: brain-recall <query>
   - 문서는 docs/ — 코드와 같은 PR로 리뷰
   - 세션: ss 시작 · sr 재개 · sl 목록 · sh 파킹 · sc 종료
   - 정책 우선순위: 볼트 memory 노트(kind: policy, scope: [org]) > 레포 docs/develop/policy/POL-* — 하위가 상위를 침묵 오버라이드 금지

   ## 포인터
   - 볼트 구조·노트 양식: ~/.claude/brain-docs/memory.md
   - 레포 문서 규약: ~/.claude/brain-docs/project-docs.md
   - git 규약: ~/.claude/brain-docs/git-convention.md
   <!-- brain:end -->
   ```
   - 갱신 후 바이트 동일 검증(드리프트는 brain-check.sh도 잡지만, 생성 시점에 확인):
   ```bash
   diff <(sed -n '/<!-- brain:begin -->/,/<!-- brain:end -->/p' AGENTS.md) \
        <(sed -n '/<!-- brain:begin -->/,/<!-- brain:end -->/p' CLAUDE.md) >/dev/null && echo SAME || echo DRIFT
   ```
3. **CLAUDE.local.md** — `vault-root: <절대경로>` **1키만**. Router 없음. 기존 파일이 있으면 `vault-root:` 키만 갱신 — 다른 내용 미접촉.
4. **볼트 스캐폴드 — PM 직접, idempotent**(있으면 skip·덮어쓰기 금지):
   - `<vault-root>/sessions/` · `<vault-root>/memory/` · `<vault-root>/memory/_index.md`(없을 때만 — 빈 파일).
   - `vault-root` 디렉터리 자체가 없으면 생성 전 사용자 확인.
   - 폐지 구조 스캐폴드 금지 — `projects/NNN_slug/`·`p_memory/`·`neocortex/`·공통층·`999_tools/`·`.brain-paths`·docs 스텁(문서는 트리거 시 — onboard·기능 착수).
5. **.gitignore 2곳 — idempotent** (`grep -qxF '<줄>' <파일> || echo '<줄>' >> <파일>` · git repo가 아니면 조용히 skip):
   - 프로젝트 레포 `.gitignore` ← `CLAUDE.local.md` (머신 로컬 경로 — 커밋 금지). **CLAUDE.md는 절대 gitignore 금지** — 공유가 목적.
   - 볼트 `.gitignore` ← `sessions/` (휘발층 — git 밖) · `.dreaming.lock` (dreaming 원자 락 — 휘발). 첫 세션이 커밋되기 전에 등록.
6. **보고** — 생성/갱신 경로 목록(파일별 생성/블록 교체/skip 구분) + 바이트 동일 검증 결과 + "내용 인터뷰는 `/brain:onboard`".

## 금지

- 전체 파일 덮어쓰기 — 마커 블록 밖은 손대지 않는다.
- 크레덴셜 기록 — `ticket`은 식별자만.
- 볼트에 폐지 구조·docs 스텁 생성 — "pre-created ≠ evidence".
- 두 파일 중 한쪽만 갱신 — 블록은 항상 동시·바이트 동일.
