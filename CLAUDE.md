<!-- brain:begin -->
## brain config
project: kjp         # 소문자 — 세션 파일명·scope
ticket-prefix: KJP   # 대문자 — 티켓 표기
org: techtainment
ticket: plane        # 식별자만 — 크레덴셜 금지

## 필수 규칙
- 지식은 볼트 memory/ 한 곳 — 레포에 지식 파일 금지. 조회: brain-recall <query>
- 문서는 docs/ — 코드와 같은 PR로 리뷰
- 세션: ss 시작 · sr 재개 · sl 목록 · sh 파킹 · sc 종료
- 정책 우선순위: 볼트 memory 노트(kind: policy, scope: [org]) > 레포 docs/develop/policy/POL-* — 하위가 상위를 침묵 오버라이드 금지

## 포인터
- 볼트 구조·노트 양식: ~/.claude/brain-docs/memory.md (절만 필요하면 brain-canon)
- 레포 문서 규약: ~/.claude/brain-docs/project-docs.md
- git 규약: ~/.claude/brain-docs/git-convention.md
<!-- brain:end -->
