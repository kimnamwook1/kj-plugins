<!-- brain:begin -->
## brain config
project: kjp         # 소문자 — 세션 파일명·scope
ticket-prefix: KJP   # 대문자 — 티켓 표기
org: techtainment
ticket: plane        # 식별자만 — 크레덴셜 금지

## 필수 규칙
- 지식은 볼트 memory/ 한 곳 — 레포에 지식 파일 금지. 조회: brain-recall <query>
- 문서는 docs/ — 코드와 같은 PR로 리뷰
- 세션: ss 시작 · sr 재개 · sh 파킹 · sc 종료
- 정책 우선순위: 볼트 memory 노트(kind: policy, scope: [org]) > 레포 docs/develop/policy/POL-* — 하위가 상위를 침묵 오버라이드 금지

## 포인터
- 볼트 구조·노트 양식: ~/.claude/brain-docs/memory.md (절만 필요하면 brain-canon)
- 레포 문서 규약: ~/.claude/brain-docs/project-docs.md
- git 규약: ~/.claude/brain-docs/git-convention.md
<!-- brain:end -->

## 달성하고자 하는 것

- 팀 또는 개인이 사용할 수 있는 기억 저장소 시스템. 저장, 기억 인출이 효과적으로 일어나서 컨택스트를 오염시키지 않고 지난 실수들을 반복하지 않게 하기 위한 시스템
- 또한 멀티 세션 및 멀티 프로젝트와 다중 에이전트 구조에 맞는 하네스를 구축하는 것이 목표



### 왜 만드나?

- 이미 지난 일들을 또 다시 실행하는 문제를 해결하기 위함
- 이미 한 실수는 다시하지 않도록 강제하기 위함. 
  - ClaudeCode 기본 메모리 (Auto-memory) 기능은 여러 프로젝트에 걸쳐서 하는 실수는 다루기 어렵고 프로젝트 별 memory의 Table of content 처럼 관리되는 구조임을 확인함.



### 영감을 받은 레포 및 영상

- Second-brain
  - Gist
    - 안드레 카파시-[LLM wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
  - 가장 참조한 Github-repo
    - [Claude-Obsidian](https://github.com/AgriciDaniel/claude-obsidian)
    - [Graphify](https://github.com/Graphify-Labs/graphify)
    - [Obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain)
    - [OpenKB](https://github.com/VectifyAI/OpenKB)
    - [Cognee](https://github.com/topoteretes/cognee) 
    - [openwiki](https://github.com/langchain-ai/openwiki)
    - [Understand-anything](https://github.com/Egonex-AI/Understand-Anything)
  - 기타 참조 github-repo
    - [Open-knowledge](https://github.com/inkeep/open-knowledge)
    - [Codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)
    - [Infinite-brain-OS](https://github.com/starmynd-org/infinite-brain-os)
    - [Mempalace](https://github.com/MemPalace/mempalace)
    - [Gbrain](https://github.com/garrytan/gbrain)
  - 가장 최초로 사용해본 기억 MCP
    - [Claude-mem](https://github.com/thedotmack/claude-mem)
- Agent-harness
  - [Matt Pocock & Uncle Bob](https://notebook.google.com/notebook/47819dcb-d887-45e5-815a-e835a80fd879?original_referer=https:%2F%2Faccounts.google.com%23) 
  - [https://github.com/mattpocock/skills](https://github.com/mattpocock/skills)
  - [Matt Pocock skills notebooklm](https://notebook.google.com/notebook/3da759b9-6a1e-4f17-b8fd-29c9bfa8e793)

---

## 참조 지형 — 경쟁·영감 자료

- 목적: brain 설계 판단 시 대조군. "우리가 이미 푼 것 / 남이 더 잘 푼 것 / 아직 아무도 안 푼 것"을 가르는 기준표.
- 판정 어휘: **채택 후보** / **관찰** / **불채택**(사유 필수).
- 별점·버전은 측정 시점 값. **재확인 없이 인용 금지.** 최종 측정 2026-08-23.
- 🔴 **수록 기준: 판정이 있고 그 판정이 무언가를 바꿨거나, 살아 있는 다음 행동이 걸려 있는 것만.** 이름표 수집 금지 — 2026-08-23 정리에서 "관찰" 딱지만 붙고 3일간 후속 0건이던 25항목을 삭제했다. 다시 찾는 비용은 검색 10초, 상시 컨텍스트 비용은 매 세션이다.

### 0. 계보의 원형 — Karpathy LLM Wiki (2026-04)

[gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 아래 지형 대부분이 이 문서의 변주다. 조사한 주요 구현 7개 중 5개가 명시적으로 인용한다.

- **핵심 주장**: RAG는 매 질의마다 지식을 처음부터 재발견한다. 축적이 없다. 대신 LLM이 **마크다운 위키를 점증적으로 쓰고 유지**한다 — 새 소스가 들어오면 색인만 하는 게 아니라 읽고, 추출하고, 기존 엔티티·개념 페이지를 갱신하고, 모순을 표시한다. *"the wiki is a persistent, compounding artifact."*
- **3층 구조**: **raw sources**(불변, LLM은 읽기만) · **wiki**(LLM이 전적으로 소유) · **schema**(CLAUDE.md/AGENTS.md — 규약과 워크플로를 담는 설정 파일).
- **3연산**: **Ingest**(소스 1건이 위키 10~15페이지를 건드림) · **Query**(답을 위키에 새 페이지로 되돌려 적재 — 탐색도 복리로) · **Lint**(모순·낡은 주장·고아 페이지·누락 상호참조 건강검진).
- **특수 파일 2개**: `index.md`(내용 지향 카탈로그, 매 ingest마다 갱신, 질의 시 먼저 읽음) · `log.md`(시간순 append-only. `## [2026-04-02] ingest | Title` 접두 고정 시 `grep "^## \[" log.md | tail -5`로 파싱).
- **벡터DB 불필요 선언**: 소스 ~100건·페이지 수백 규모까지 index.md만으로 충분.
- brain 대비: `memory/` + `_index.md` + `sc` 승격이 같은 패턴. 단 우리 입력은 **세션에서 배운 것**, 이들은 **원본 문서 통째 컴파일**.
- 🔴 **`log.md` 대응물은 조사한 구현 전부에서 0건.** `index.md`는 모두 갖췄는데 시간축만 계보에서 사라졌다. 우리 `sessions/`가 그 자리 — 우리가 앞선 것인지 헛짚은 것인지 미판정.

### 1. 표준 — OKF

**OKF (Open Knowledge Format)** — Google Cloud · [spec](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)

- 마크다운 디렉터리 + YAML frontmatter. v0.1 2026-06-12 · v0.2 2026-07-25. 필수 키 `type` 하나, 권장 `title`·`description`·`resource`·`tags`. 파일 경로 = 개념의 정체성, 개념 간 연결 = 마크다운 링크.
- v0.2가 신뢰 신호 추가: `provenance`·`trust`·`freshness`·`lifecycle`·`computation`.
- brain 대비: 형식·단위·연결이 사실상 동일. 차이는 **키 어휘**뿐(`kind`↔`type`, `scope`↔`tags`). 우리에겐 `freshness`·`provenance` 축이 없다.
- **관찰** — 상호운용 소비자가 없고 스키마 동결 중. 소비자 생기면 매핑만 하면 된다.

### 2. LLM Wiki 계보 — 컴파일형

| 이름 | 무엇 | 판정 |
|---|---|---|
| [VectifyAI/OpenKB](https://github.com/VectifyAI/OpenKB) `3,833★` | 원문(PDF·Word·PPT·Excel·HTML·URL)을 위키로 컴파일. PageIndex 트리 인덱싱, 멀티모달. **vectorless** 헤드라인. Entity Pages. **Skill Factory — 볼트에서 재배포 가능한 agent skill 추출** | **관찰** — 입력이 외부 문서, 우리 입력은 세션. 단 Skill Factory의 **볼트→하네스 역방향은 이 지형에서 유일** |
| [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki) `15,490★` | 코드 위키 + 개인 위키 2모드. **Grounded Claims**(§8). OKF v0.2 출력. CI 자가 갱신. 커넥터 9종 | 🔴 **판정 상향 필요** — `openwiki integrations install claude`로 **Claude Code 안에서 호스트 모델로 구동**. 우리 영역과 직접 겹침 |
| [Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything) `80,150★` | 다중 에이전트 파이프라인 → 지식 그래프 + 대시보드. **`/understand-knowledge`가 Karpathy 위키를 입력으로 받음.** diff impact analysis, guided tours | **관찰** — 계보 직계이면서 출력이 그래프 |
| [inkeep/open-knowledge](https://github.com/inkeep/open-knowledge) `3,604★` | AI-native 마크다운 IDE + LLM 위키 | **미조사** |

### 3. Obsidian × Claude Code 직접 경쟁

| 이름 | 무엇 | brain 대비 |
|---|---|---|
| **[AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian)** `11,158★` | Karpathy 패턴 기반 CC 플러그인, 스킬 15종. **불변·content-addressed 소스 사본**을 합성 전에 보존. **source/claim 원장**(authority·freshness·support·contradiction·confidence·review state). Obsidian Canvas 지식맵 | 🔴 **claim 원장 + 병렬 트랜잭션 둘 다 우리에게 없는 축.** §7-B |
| **[eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain)** `4,154★` | CC + 7개 CLI용 볼트 메모리. 명령 46종. 하이브리드 시맨틱+키워드 검색, 스케줄 에이전트 4종. v0.14 "The Harvest" — 포크 408개 스캔해 역수입 | **최근접 경쟁자.** 격차 §7-A |
| **[thedotmack/claude-mem](https://github.com/thedotmack/claude-mem)** `91,541★` | 세션 중 일어난 일 전부 캡처 → AI 압축 → 다음 세션에 관련 컨텍스트 재주입. 다중 호스트 | **미조사 · 1순위** — 우리 `sc` 승격과 정확히 같은 자리, 별점 지형 최대급 |
| **[MemPalace/mempalace](https://github.com/MemPalace/mempalace)** `58,562★` | "best-benchmarked open-source AI memory system" 자칭 | **미조사** — §4 벤치마크 경고를 그대로 적용할 대상 |
| **[garrytan/gbrain](https://github.com/garrytan/gbrain)** `28,948★` | OpenClaw/Hermes용 의견 있는 에이전트 브레인 | **미조사** |
| **[ArtemXTech/personal-os-skills](https://github.com/ArtemXTech/personal-os-skills)** `530★` MIT | CC 플러그인. `granola`·`wispr-flow`·`tasknotes`·`notebooklm`·**`recall`**·**`sync-claude-sessions`** | `recall` = 우리 `brain-recall` · `sync-claude-sessions` = 우리 세션 노트. **구현 비교 1순위** |
| **[ArtemXTech/claude-code-obsidian-starter](https://github.com/ArtemXTech/claude-code-obsidian-starter)** `220★` | 무료 스타터 볼트. `/setup-memory`가 CLAUDE.md 생성 | 우리 `init`의 대응물 |
| [starmynd-org/infinite-brain-os](https://github.com/starmynd-org/infinite-brain-os) `242★` | git 기반 "AI 에이전트로 사업 운영하는 OS". 평문 Markdown+YAML, "owned by you" | **관찰** — 소유권 원칙이 우리와 동일 |

### 4. 메모리 라이브러리 층

brain과 층이 다르다 — 이들은 벡터·그래프 스토어 + API, 우리는 마크다운 + 규약. 개념 축만 빌린다.

| 이름 | 접근 | 판정 |
|---|---|---|
| **[topoteretes/cognee](https://github.com/topoteretes/cognee)** `30,189★` | 지식 그래프 + 벡터 + 인지과학 기반 온톨로지 생성. 자가호스팅. CC 플러그인 있음. [arXiv:2505.24478](https://arxiv.org/abs/2505.24478) | **관찰** |

- 🔴 **벤치마크 경고**: LongMemEval 수치는 **재현이 안 된다**. Mem0 자체 발표치가 외부 하네스(Maximem)에서 73.8%로 떨어졌다. **하네스와 측정 주체를 반드시 물을 것.** "best-benchmarked" 자칭에 그대로 적용한다.

### 5. 코드 그래프 축

지식 볼트가 아니라 **코드 자체를 그래프로** 만드는 계열. 우리 `docs/develop/ARCHITECTURE.md`의 생성기 자리.

| 이름 | 무엇 | 판정 |
|---|---|---|
| **[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)** `109,619★` | tree-sitter AST 결정론 파싱(코드는 LLM 0, 로컬). **모든 간선에 `EXTRACTED`(원문 명시) / `INFERRED`(추론) 태그.** "Not a vector index" 헤드라인. `graph.html` + `GRAPH_REPORT.md` + `graph.json` | **불채택(현시점)** — 노트 57건에 커뮤니티 탐지는 노이즈. **200건 넘으면 재판정.** 단 간선 출처 태그는 별개로 채택 후보 |
| **[DeusData/codebase-memory-mcp](https://github.com/DeusData/codebase-memory-mcp)** `39,947★` | C 단일 정적 바이너리, 의존성 0. 158언어, 밀리초 인덱싱, sub-ms 질의, "99% fewer tokens" | **미조사** — 의존성 0 · 단일 바이너리가 우리 이식성 원칙(bash 3.2 + POSIX)과 같은 계열 |
| **arch-view** — [unclebob/arch-view](https://github.com/unclebob/arch-view) | Clojure. 순환 제거 후 위상정렬 → 레벨 배정, 순환은 지표로 표시, 드릴다운, 헤드리스 EDN 내보내기 | **채택 후보(레시피)** — 도구 배포가 아니라 알고리즘 참조 |

### 6. 에이전트 하네스 축

지식이 아니라 **작업 규율**을 다루는 계열. 우리 `agents/*.md` · `round` · `coder`의 대조군. **이 지형에서 실제로 판정을 뒤집은 유일한 절.**

| 이름 | 무엇 | 우리에게 |
|---|---|---|
| **[unclebob/swarm-forge](https://github.com/unclebob/swarm-forge)** | tmux 6에이전트 편성(`six-pack` 브랜치): specifier·coder·cleaner·architect·hardender·QA. **constitution(4줄) + articles 3개**가 상시층, `roles/*.prompt`(32~44줄)가 역할층. `git_handoff` 고정 헤더 `type·to·priority·task` | 🔴 우리와 **독립 수렴**(Handoff 고정 필드·worktree 격리·역할 분리). 우리에게 없는 것 = **cleaner·architect·hardender 3역**. 상시층 1,763B vs 우리 마커 블록 874B |
| ↳ `constitution/articles/local-engineering.prompt` | 전문: *"Every agent except the specifier must run unit tests and acceptance tests before handoff and fix any failures."* | **게이트 선언의 정본 사례** — 역할 프롬프트가 아니라 헌법에 둔 것이 핵심 |
| ↳ `roles/coder.prompt` §Implementation | *"For each behavior slice, use TDD to specify behavior before implementation. First write focused unit tests that ... would fail for a plausible wrong implementation."* | 인터뷰에서 그가 거부한 것은 **라인 단위 미시 사이클**뿐. **행위 슬라이스 단위 test-first는 그의 현행 강제 사항** — 우리 `coder.md` §테스트와 같은 자리. **TDD 완화안 폐기 근거** |
| ↳ `roles/cleaner.prompt` | *"reduce CRAP to 6 or below"* · 변경 파일이 **mutation site 100 초과 시 분할** | 임계값 축이 **함수 줄 수가 아니라 CRAP·mutation site**. 그의 6~8은 **100% 커버리지 + mutation 강제가 전제**. **임계값 상향안 폐기 근거** |
| **[unclebob/Acceptance-Pipeline-Specification](https://github.com/unclebob/Acceptance-Pipeline-Specification)** | Gherkin → JSON IR → 생성 테스트 + 러너. `bb gherkin-mutator` · **`bb gherkin-ir-dry-checker`**(반복·유사·동의어 step 텍스트 리포트) | "step 문구 규율 없으면 Gherkin이 쓰레기가 된다"를 **도구로 푼 사례** |
| **[mattpocock/skills](https://github.com/mattpocock/skills)** | 작고 조합 가능한 스킬 묶음. CC 공식 마켓플레이스 + `skills.sh`(포크형) 2경로 | **`/grill-me` = 우리 `onboard` grill의 원형** |
| ↳ 설계 주장 | *"GSD, BMAD, Spec-Kit try to help by owning the process. But while doing so, **they take away your control and make bugs in the process hard to resolve**."* 근거 = Pragmatic Programmer *"No-one knows exactly what they want"* | Uncle Bob의 *"don't download those — I wrote them for me. Point your agents at them and build one for you"*와 **독립 2인의 같은 결론.** 플러그인은 레시피를 배포하고 프로젝트가 인스턴스를 만든다 |

### 7. 최근접 경쟁자 설계 격차

#### 7-A. obsidian-second-brain — 우리보다 앞선 4개

1. **점진 로딩 L0~L3** — `CRITICAL_FACTS.md` ~120토큰 항상 로드 + 레벨별 토큰 예산. 우리는 8KiB **단일 상한**뿐이라 "무엇을 먼저 버릴지"가 없다.
2. **Bi-temporal 사실** — 참이었던 시점 / 알게 된 시점 분리.
3. **OKM 삼분법** — 모든 사실은 `timeless`(영구 원칙) · `dated`(유효기한) · `pointer`(라이브 소스 링크) 중 하나. 목적은 *"빠르게 변하는 데이터가 볼트 안에서 썩지 않게"*. 우리 `kind: fact|policy`와 **직교하는 축** — 우리에겐 "언제 상하나"를 판정할 키가 없다.
4. **Two-Output Rule** — 볼트 질의에 답할 때마다 관련 문서도 같이 갱신.

계보 인용: *"Karpathy의 위키가 LLM으로 유지하는 지식베이스라면, 이건 스스로 유지하는 지식베이스다."*

#### 7-B. claude-obsidian — 병렬 쓰기 해법이 다르다

> *"Parallel agents cannot race the vault. **Workers return drafts. One orchestrator inspects and applies one recoverable transaction.**"*

- 우리는 **원자 락**으로 푼다. 이쪽은 **드래프트 회수 + 단일 적용자**로 푼다. 다른 해법이지 우리가 앞선 게 아니다.
- 모든 변경이 `plan` → `approved_plan_sha256` → `--apply` 3단. 우리 `init`의 "묻고 쓴다"와 같은 자리인데 **해시로 계획을 고정**한다.

#### 7-C. 우리가 가진 것 (대조)

조직(회사) 볼트 물리 분리 · 검사기 3종 + selftest · 원자 락 · dreaming 커서 · 1 run 1 commit(revert 단위) · 레포 `docs/` 규약과 세션 승격의 결합.

### 8. 🔴 수렴 — freshness·provenance는 사실상 표준

6개 구현이 서로 참조하지 않고 같은 문제에 도달했다. 공통 질문 = **"이 사실이 언제 참이었고 무엇이 근거인가"**. `updated:` 한 키로는 답할 수 없다.

| 구현 | 이름 | 형태 |
|---|---|---|
| openwiki | Grounded Claims | 명제 ↔ 버전된 소스 증거. 증거 변경 시 confirm/rewrite/retire 판정 |
| claude-obsidian | source·claim 원장 | authority · freshness · support · contradiction · confidence · review state |
| obsidian-second-brain | OKM | 모든 사실 = `timeless` \| `dated` \| `pointer` |
| graphify | 간선 태그 | `EXTRACTED`(원문 명시) \| `INFERRED`(추론) |
| OKF v0.2 | frontmatter | `provenance` · `trust` · `freshness` · `lifecycle` · `computation` |
| Zep / Graphiti | bi-temporal | 언제 **참이었는지** + 언제 **알게 됐는지** 를 분리 기록 |

**넓게 훑은 조사가 값을 한 지점은 여기 하나다.** 1~2건만 봤으면 "쟤들 특이하네"로 끝났을 것. 6건이 수렴하는 건 6건을 봐야 보인다. 그 임무는 끝났고, 그 뒤로는 재고 목록이었다.

### 9. 사망 사례 — 반증 자료

| 사례 | 실측 | 교훈 |
|---|---|---|
| **CC 내장/플러그인 메모리** (`~/.claude/projects/*/memory/`) | 209건 / **34 디렉터리** / 2026-03~06 → 이후 **0건** | 프로젝트 경로마다 별도 디렉터리 = 교차 조회 불가 → 방치. **경로 파생 금지** 원칙의 실측 근거 |
| **brain 0.2.x `related` frontmatter** | YAML 붕괴 **354건** + 재배선 세금 | 다대다 링크를 허용하면 무너진다. Artem은 **부모 정확히 1개** 제약으로 같은 기능을 살려 쓴다 |
| **사전 계획·SDD** (Uncle Bob 실측) | *"I've been in the middle of trying this just this week. And it's **always a disaster**."* / *"the agents love to write plans ... And then they **fall apart at the end**."* | 변경 비용이 0에 수렴했으므로 비싼 사전 계획의 근거가 사라졌다. 대안 = 스토리 1~2개 → 아키텍처 점검 → 반복 |
| **본 지형도 자신** (2026-08-20~23) | 51항목 조사 → 3일간 후속 커밋 **0건**, "관찰" 22건, 다음 액션 5건 중 **0건 실행** | 넓이는 수렴 탐지(§8) 한 번에만 값을 했다. 판정을 뒤집은 건 **전문을 읽은 2건**(Karpathy gist · swarm-forge 역할 프롬프트)뿐. **목록 수집 ≠ 판단** |

### 10. 다음 행동 (살아 있는 것만)

- [ ] `thedotmack/claude-mem` 조사 — 세션 캡처→압축→재주입이 우리 `sc`와 같은 자리, 별점 지형 최대급
- [ ] `AgriciDaniel/claude-obsidian` 정독 — claim 원장 · 드래프트 트랜잭션 · plan-sha256 3단
- [ ] `personal-os-skills` clone — `recall`·`sync-claude-sessions` 구현 대조 (MIT)
- [ ] `obsidian-second-brain` 정독 — L0~L3 로딩 · OKM 삼분법 실물 확인
- [ ] freshness·provenance 6구현 키 어휘 대조표 — §8이 사실상 표준이면 남의 어휘를 따르는 게 이득
- [ ] `log.md` 미판정 해소 — 계보 전체가 버린 시간축을 우리 `sessions/`가 대신하는지, 아니면 우리도 버려야 하는지
