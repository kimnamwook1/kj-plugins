---
status: draft
updated: 2026-08-20
---

# 에이전트 지식베이스 경쟁·참조 지형

- 목적: brain 설계 판단 시 대조군. "우리가 이미 푼 것 / 남이 더 잘 푼 것 / 아직 아무도 안 푼 것" 을 가르는 기준표.
- 수집 2026-08-20. 별점·버전은 수집 시점 값 — 재확인 없이 인용 금지.
- 판정 어휘: **채택 후보** / **관찰** / **불채택**(사유 필수).

## 1. 표준·스펙

| 이름 | 무엇 | brain 대비 | 판정 |
|---|---|---|---|
| **OKF (Open Knowledge Format)** — Google Cloud · [spec](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md) | 마크다운 디렉터리 + YAML frontmatter. v0.1 2026-06-12 · v0.2 2026-07-25. 필수 키 `type` 하나, 권장 `title`·`description`·`resource`·`tags`. 파일 경로 = 개념의 정체성, 개념 간 연결 = 마크다운 링크. v0.2가 신뢰 신호 추가(`provenance`·`trust`·`freshness`·`lifecycle`·`computation`) | 형식·단위·연결이 사실상 동일. 차이는 **키 어휘**뿐(`kind`↔`type`, `scope`↔`tags`). 우리에겐 `freshness`·`provenance` 축이 없다 | **관찰** — 상호운용 소비자가 없고 스키마 동결 중. 소비자 생기면 매핑만 하면 된다 |
| **Open Agentic KB spec** — [openakb/spec](https://github.com/openakb/spec) | OKF와 별개 계보의 에이전트 KB 스펙 | 미조사 | **관찰** |

## 2. LLM Wiki 계보 (Karpathy 패턴, 2026-04)

- 원형: LLM이 RAG로 매번 재검색하는 대신 **마크다운 위키를 점증적으로 쓰고 유지**한다. Gist가 며칠 만에 5,000★.
- brain 대비: 우리 `memory/` + `_index.md` + `sc` 승격이 같은 패턴이다. 다만 우리는 **세션에서 배운 것만** 승격하고, 이들은 **원본 문서를 통째로 컴파일**한다.

| 이름 | 무엇 | 판정 |
|---|---|---|
| [tjiahen/awesome-llm-wiki](https://github.com/tjiahen/awesome-llm-wiki) | 패턴 구현체 큐레이션 목록 | **관찰** — 신규 구현 추적 진입점 |
| [VectifyAI/OpenKB](https://github.com/VectifyAI/OpenKB) | 원문(PDF·Word·PPT·Excel·HTML·URL)을 위키로 컴파일. PageIndex 트리 인덱싱으로 장문 처리, 멀티모달(그림·표). OpenKB Studio(웹 UI + REST API) | **관찰** — 입력이 외부 문서. 우리 입력은 세션. 축이 다르다 |
| [nashsu/llm_wiki](https://github.com/nashsu/llm_wiki) | 데스크톱 앱. 문서를 점증적 위키로 | **불채택** — 앱 형태, 파일 위 규약이 아니다 |
| [lucasastorian/llmwiki](https://github.com/tjiahen/awesome-llm-wiki) | Claude를 MCP로 붙여 볼트 search/read/write/lint | **채택 후보(참조)** — `lint` 가 우리 `brain-validate.sh` 대응물 |
| [Astro-Han/karpathy-llm-wiki](https://github.com/Astro-Han/karpathy-llm-wiki) | Agent Skills 호환. 전부 `raw/` 로 넣고 `wiki/` 로 컴파일. 실운영 94문서·99소스 | **채택 후보(참조)** — Skills 규약이 우리와 같은 층 |
| NicholasSpisak/second-brain | Obsidian 네이티브 Karpathy 구현. raw 폴더에 넣으면 컴파일 결과를 그래프뷰로 | **관찰** |
| nvk/llm-wiki | CLI. 5~10 병렬 에이전트로 논지 기반 조사 | **관찰** — 우리 `round` 와 같은 병렬 축 |

## 3. Obsidian × Claude Code 직접 경쟁

| 이름 | 무엇 | brain 대비 |
|---|---|---|
| **[eugeniughelbur/obsidian-second-brain](https://github.com/eugeniughelbur/obsidian-second-brain)** | CC + 6개 CLI 에이전트용 볼트 메모리. 명령 45개(운영 28 · 사고 9 · 리서치 7). 하이브리드 시맨틱+키워드 검색, 야간 스케줄 통합 | **가장 가까운 경쟁자.** 아래 §5에 설계 격차 별도 정리 |
| **[ArtemXTech/personal-os-skills](https://github.com/ArtemXTech/personal-os-skills)** (530★, MIT) | CC 플러그인 마켓플레이스. `granola`·`wispr-flow`·`tasknotes`·`notebooklm`·`notebooklm-import`·**`recall`**·**`sync-claude-sessions`** | `recall` = 우리 `brain-recall` · `sync-claude-sessions` = 우리 세션 노트. **구현 비교 대상 1순위** |
| **[ArtemXTech/claude-code-obsidian-starter](https://github.com/ArtemXTech/claude-code-obsidian-starter)** (220★) | 무료 스타터 볼트. `.claude/ .obsidian/ Bases/ Clients/ Daily/ Meetings/ Projects/ Tasks/ guide/ CLAUDE.md`. 스킬 4종. `/setup-memory` 가 CLAUDE.md 생성 | 우리 `init` 의 대응물 |
| [ArtemXTech 유료 코스](https://brain.artemzhutov.com/) | The 30-Day Agentic Second Brain · $790 · 65레슨/11모듈 · 스킬 25종 | 볼트 구조 비공개. **불채택**(무료 레포 2개로 실물 확인 가능) |
| [smixs/agent-second-brain](https://github.com/smixs/agent-second-brain) | 텔레그램 음성노트 → Obsidian. 구독 위에서 24/7 | **관찰** — 입력 채널 축 |
| [bbuch82/agentic-second-brain-guide](https://github.com/bbuch82/agentic-second-brain-guide) | MD + Obsidian + OpenClaw 셋업 가이드 | **관찰** |
| [agentic-ai-research/second-brain-os](https://github.com/agentic-ai-research/second-brain-os) | 미조사 | **관찰** |
| **OpenWiki Brains** — [LangChain](https://www.langchain.com/blog/introducing-openwiki-brains-general-purpose-wiki-memory-for-agents) | 코드베이스 요약 위키 생성 CLI에서 출발 → 에이전트용 범용 위키 메모리. 저장은 평문 마크다운, 파일시스템 그대로 노출. Gmail·X 등 앱에서 자가 갱신 | **관찰** — "인터페이스 뒤에 숨기지 않는다" 는 우리와 같은 원칙 |
| **graphify** (로컬 스킬 설치됨) | 임의 폴더 → 지식 그래프. god node·커뮤니티 탐지·query/path/explain. HTML·GraphRAG JSON·GRAPH_REPORT.md 출력 | **불채택(현시점)** — 노트 57건에 커뮤니티 탐지는 노이즈. 단 Artem 실볼트(2,928 아이템)엔 `graphify-out/` 이 실제로 있다. **200건 넘으면 재판정** |

## 4. 에이전트 메모리 프레임워크 (라이브러리 층)

- brain과 층이 다르다 — 이들은 벡터·그래프 스토어 + API. 우리는 마크다운 + 규약. 그래도 **개념 축**은 빌릴 수 있다.

| 이름 | 접근 | 빌릴 개념 |
|---|---|---|
| **Mem0** | LLM이 대화에서 사실을 뽑아 벡터 스토어에 조정 병합. 채택 폭 최대 | 승격 판정을 LLM이 한다는 점은 우리 `sc` 와 같다 |
| **Zep / Graphiti** | **시간 지식 그래프** — 각 사실이 **언제 참이었는지** + **언제 알게 됐는지** 둘 다 기록 | 🔴 **bi-temporal.** 우리는 `updated:` 하나뿐 |
| **Letta** (구 MemGPT) | 모델을 OS로 취급. 에이전트가 툴로 자기 컨텍스트를 페이징하고 자기 메모리를 다시 쓴다 | 우리 `dreaming` 이 같은 자리(단 배치·수동) |
| **Cognee** | 지식 그래프 + 피드백 재가중. 단일 Postgres 가능. 로컬 우선 | **관찰** |
| **HippoRAG / HippoRAG2** | 해마 모사 장기기억 RAG | **관찰** |

- 🔴 벤치마크 경고: LongMemEval 수치는 **재현이 안 된다**. Mem0 자체 발표치가 외부 하네스(Maximem)에서 73.8% 로 떨어졌다. **하네스와 측정 주체를 반드시 물을 것.**

## 5. 최근접 경쟁자 설계 격차 — obsidian-second-brain

우리보다 앞선 지점 4개. 전부 동결 해제 후 재검토 대상.

1. **점진 로딩 L0~L3** — `CRITICAL_FACTS.md` ~120토큰 항상 로드 + 레벨별 토큰 예산. 우리는 8KiB **단일 상한**뿐이라 "무엇을 먼저 버릴지" 가 없다.
2. **Bi-temporal 사실** — 참이었던 시점 / 알게 된 시점 분리.
3. **OKM 삼분법** — 모든 사실은 `timeless`(영구 원칙) · `dated`(유효기한) · `pointer`(라이브 소스 링크) 중 하나. 목적은 *"빠르게 변하는 데이터가 볼트 안에서 썩지 않게"*. 우리 `kind: fact|policy` 와 **직교하는 축** — 우리에겐 "언제 상하나" 를 판정할 키가 없다.
4. **Two-Output Rule** — 볼트 질의에 답할 때마다 관련 문서도 같이 갱신.

- 계보 인용: *"Karpathy의 위키가 LLM으로 유지하는 지식베이스라면, 이건 스스로 유지하는 지식베이스다."*
- 반대로 우리가 가진 것: 조직(회사) 볼트 물리 분리 · 검사기 3종 + selftest · 원자 락 · dreaming 커서 · 1 run 1 commit(revert 단위).

## 6. 논문·서베이

| 항목 | 비고 |
|---|---|
| **Karpathy, LLM Wiki** (2026-04) | 본 지형 전체의 출발점. Gist |
| [Shichun-Liu/Agent-Memory-Paper-List](https://github.com/Shichun-Liu/Agent-Memory-Paper-List) | *Memory in the Age of AI Agents: A Survey* 논문 목록 |
| [DEEP-PolyU/Awesome-GraphMemory](https://github.com/DEEP-PolyU/Awesome-GraphMemory) | 그래프 기반 에이전트 메모리 서베이 (2026-02-03) |
| **Mem0** (arXiv:2504.19413, ECAI 2025) | 메모리 접근 10종 최초 정면 비교 |
| **A-MEM: Agentic Memory for LLM Agents** (arXiv:2502.12110) | |
| **MemGraphRAG** (arXiv:2606.00610) | 그래프 구축 품질을 다중 에이전트 + 공유 메모리로 |
| **REAL** (arXiv:2606.10694) | 추론 강화 그래프 장기 메모리 |
| **HyMem** (arXiv:2602.13933) | 하이브리드 메모리 + 동적 검색 스케줄링 |
| **Beyond RAG for Agent Memory** (arXiv:2602.02007) | 분리·집계 기반 검색 |
| **MemoryCD** (arXiv:2603.25973) | 평생 교차도메인 개인화 벤치마크 |

## 7. 사망 사례 — 반증 자료

| 사례 | 실측 | 교훈 |
|---|---|---|
| **CC 내장/플러그인 메모리** (`~/.claude/projects/*/memory/`) | 209건 / **34 디렉터리** / 2026-03~06 → 이후 **0건** | 프로젝트 경로마다 별도 디렉터리 = 교차 조회 불가 → 방치. **경로 파생 금지** 원칙의 실측 근거 |
| brain 0.2.x `related` frontmatter | YAML 붕괴 **354건** + 재배선 세금 | 다대다 링크를 허용하면 무너진다. Artem은 **부모 정확히 1개** 제약으로 같은 기능을 살려 쓴다 |

## 8. 다음 액션

- [ ] `personal-os-skills` clone — `recall`·`sync-claude-sessions` 구현 대조 (MIT)
- [ ] `claude-code-obsidian-starter` clone — `init` 대응물 구조 대조
- [ ] `obsidian-second-brain` 정독 — L0~L3 로딩·OKM 삼분법 실물 확인
- [ ] OKM 삼분법 티켓화 — **스키마 동결 해제 후**
- [ ] `openakb/spec` 조사 — OKF와의 관계
