# security-audit — 보안 감사 페이즈 · 오탐 필터 · 보고 형식

> `agents/verifier.md` 가 **보안 브리프**를 받았을 때 읽는 본문. 에이전트 정의는 spawn 마다 100% 주입되므로 본문이 거기 들어갈 수 없다 — 정의는 이 문서를 가리키고, 실제 절차는 여기 있다.
> 🔴 **report-only.** 이 문서의 어떤 절차도 코드를 고치지 않는다. 수정은 별도 구현 브리프의 몫이다. `verifier` 는 `Write`·`Edit`·`NotebookEdit` 이 차단돼 있고, 이 문서는 그 경계를 절차로 재확인한다.
> 원료 = `gstack` `cso` 스킬(Phase 0–13). 하네스로 옮기며 gstack 전용 기계(설정 CLI·학습 저장소·리포트 저장·텔레메트리·수정 로드맵 질문)는 걷어냈다 — 그 자리는 Handoff 와 PM 이 맡는다.
> 커밋·브랜치 → [[git-convention]] · 문서 규약 → [[project-docs-convention]]

## 경계 — 이 문서가 하지 않는 것

- **고치지 않는다.** 수정 제안은 텍스트로만 쓴다. 패치를 적용하거나 파일을 만들지 않는다.
- **살아있는 대상을 두드리지 않는다.** 웹훅·SSRF·시크릿 전부 **코드 추적으로만** 검증한다. 실제 HTTP 요청 금지, 실 API 에 키 검증 금지.
- **리포트를 저장하지 않는다.** 산출물은 Handoff 로 넘긴다. 볼트 기록은 PM 이 scribe 브리프로 위임한다.
- **하위 워커는 읽기 브리프만.** 읽기 전용 경계는 자식에게 상속되지 않으므로 규율로 강제한다.
- **코드 검색은 `Grep` 도구로.** 아래 bash 블록은 *무엇을 찾는지*를 보이는 예시지 실행 대본이 아니다. `| head` 로 잘라 보지 않는다.

## 모드 해석

브리프가 모드를 지정하지 않으면 `daily` 다.

| 모드 | 신뢰 게이트 | 범위 |
|---|---|---|
| `daily` | **8/10 이상만 보고** | 전 페이즈 |
| `comprehensive` | **2/10** — 진짜 잡음만 걸러내고 나머지는 `TENTATIVE` 로 표시 | 전 페이즈 |
| `--infra` | 모드의 게이트 | Phase 0–6 |
| `--code` | 모드의 게이트 | Phase 0–1 · 7 · 9–11 |
| `--supply-chain` | 모드의 게이트 | Phase 0 · 3 |
| `--skills` | 모드의 게이트 | Phase 0 · 8 |
| `--owasp` | 모드의 게이트 | Phase 0 · 9 |
| `--diff` | 모드의 게이트 | 위 어느 것과도 조합 — 현재 브랜치가 base 대비 바꾼 파일로 한정 |

- **범위 플래그는 상호 배타.** 두 개가 들어오면 조용히 하나를 고르지 말고 **즉시 Ask 로 반송**한다. 보안 도구가 사용자 의도를 무시하는 것이 가장 나쁘다.
- 🔴 **Phase 0 · 1 · 12 · 13 은 범위 플래그와 무관하게 **항상** 돈다.** 스택을 모르고 스캔하면 우선순위가 없고, 오탐 필터를 건너뛴 보고는 신뢰를 깎는다.
- `--diff` 일 때 Phase 2 의 git 히스토리 스캔은 현재 브랜치 커밋으로 한정한다.

---

## Phase 0 — 아키텍처 멘탈 모델 + 스택 탐지 (항상)

버그를 찾기 전에 스택을 탐지하고 코드베이스의 명시적 멘탈 모델을 세운다. 이 페이즈는 발견을 내는 게 아니라 **이후 전 페이즈의 사고 방식을 바꾼다.**

```bash
ls package.json tsconfig.json 2>/dev/null && echo "STACK: Node/TypeScript"
ls Gemfile 2>/dev/null && echo "STACK: Ruby"
ls requirements.txt pyproject.toml setup.py 2>/dev/null && echo "STACK: Python"
ls go.mod 2>/dev/null && echo "STACK: Go"
ls Cargo.toml 2>/dev/null && echo "STACK: Rust"
ls pom.xml build.gradle 2>/dev/null && echo "STACK: JVM"
ls composer.json 2>/dev/null && echo "STACK: PHP"
```

프레임워크는 매니페스트 안에서 찾는다 — `next` · `express` · `fastify` · `hono` (package.json) · `django` · `fastapi` · `flask` (requirements/pyproject) · `rails` (Gemfile) · `gin-gonic` (go.mod) · `spring-boot` (pom/gradle) · `laravel` (composer.json).

🔴 **소프트 게이트지 하드 게이트가 아니다.** 스택 탐지는 스캔 **우선순위**를 정하지 **범위**를 자르지 않는다. 탐지된 언어를 먼저·깊게 보되, 그 뒤 **전 파일 유형에 고신호 패턴(SQL 인젝션·명령 인젝션·하드코딩 시크릿·SSRF) catch-all 패스**를 돌린다. 루트에서 안 잡힌 `ml/` 밑 파이썬 서비스도 기본 커버리지는 받아야 한다.

**멘탈 모델** — `CLAUDE.md`·README·핵심 설정을 읽고, 컴포넌트와 신뢰 경계를 지도로 그리고, 사용자 입력이 **어디로 들어와 어디로 나가며 무슨 변환을 거치는지** 추적하고, 코드가 기대는 불변식을 적는다. 체크리스트가 아니라 추론 페이즈다 — 산출물은 발견이 아니라 **이해**이며, 진행 전에 짧은 아키텍처 요약으로 표현한다.

## Phase 1 — 공격면 인구조사 (항상)

공격자가 보는 것을 지도로 그린다. 코드 표면과 인프라 표면 둘 다.

**코드 표면** — `Grep` 으로 엔드포인트 · 인증 경계 · 외부 연동 · 파일 업로드 경로 · 관리자 라우트 · 웹훅 핸들러 · 백그라운드 잡 · WebSocket 채널을 찾고 **범주별로 센다.** 파일 확장자는 Phase 0 에서 탐지된 스택으로 좁힌다.

**인프라 표면** — CI 워크플로 · Dockerfile/compose · `.tf`/`.tfvars`/kustomization · `.env*` 의 존재와 개수.

```
ATTACK SURFACE MAP
══════════════════
CODE SURFACE
  Public endpoints:      N (미인증)
  Authenticated:         N
  Admin-only:            N
  API endpoints:         N (machine-to-machine)
  File upload points:    N
  External integrations: N
  Background jobs:       N (비동기 공격면)
  WebSocket channels:    N

INFRASTRUCTURE SURFACE
  CI/CD workflows:       N
  Webhook receivers:     N
  Container configs:     N
  IaC configs:           N
  Deploy targets:        N
  Secret management:     [env vars | KMS | vault | unknown]
```

## Phase 2 — 시크릿 고고학

git 히스토리의 유출 크레덴셜, 추적되는 `.env`, 인라인 시크릿을 쓴 CI 설정.

```bash
git log -p --all -S "AKIA" --diff-filter=A -- "*.env" "*.yml" "*.yaml" "*.json" "*.toml" 2>/dev/null
git log -p --all -G "ghp_|gho_|github_pat_" 2>/dev/null
git log -p --all -G "xoxb-|xoxp-|xapp-" 2>/dev/null
git log -p --all -G "password|secret|token|api_key" -- "*.env" "*.yml" "*.json" "*.conf" 2>/dev/null
git ls-files '*.env' '.env.*' 2>/dev/null | grep -v '.example\|.sample\|.template'
```

`.gitignore` 가 `.env` 를 덮는지 확인한다. CI 설정은 `password:`·`token:`·`secret:`·`api_key:` 중 `${{ }}`·`secrets.` 를 **안** 거치는 줄만 발견이다.

**심각도** — 활성 시크릿 패턴(AKIA·sk_live_·ghp_·xoxb-)이 히스토리에 = **CRITICAL** · `.env` 가 git 추적 / CI 인라인 크레덴셜 = HIGH · 수상한 `.env.example` 값 = MEDIUM.
**오탐 규칙** — 플레이스홀더(`your_`·`changeme`·`TODO`) 제외 · 테스트 픽스처는 같은 값이 비테스트 코드에도 있을 때만 · **로테이트된 시크릿도 발견이다**(이미 노출됐다) · `.gitignore` 안의 `.env.local` 은 정상.
**`--diff`** — `git log -p --all` 을 `git log -p <base>..HEAD` 로 바꾼다.

## Phase 3 — 의존성 공급망

`npm audit` 을 넘어 실제 공급망 위험을 본다. 매니페스트로 패키지 매니저를 탐지하고, 사용 가능한 audit 도구를 돌린다. **도구가 없으면 발견이 아니라 `SKIPPED — tool not installed`** 로 적고 설치법을 남긴 뒤 나머지로 계속한다.

- **prod 의존성의 install 스크립트** (`preinstall`·`postinstall`·`install`) — 공급망 공격 벡터.
- **락파일 무결성** — 존재하는가, 그리고 **git 이 추적하는가.**

**심각도** — 직접 의존성의 알려진 high/critical CVE = CRITICAL · prod 의존성 install 스크립트 / 락파일 부재 = HIGH · 방치된 패키지 / medium CVE / 락파일 미추적 = MEDIUM.
**오탐 규칙** — devDependency CVE 는 **MEDIUM 상한** · `node-gyp`·`cmake` 의 install 스크립트는 정상(MEDIUM) · 수정본 없고 알려진 익스플로잇도 없는 권고 제외 · **라이브러리 레포**(앱이 아닌)의 락파일 부재는 발견이 아니다.

## Phase 4 — CI/CD 파이프라인 보안

누가 워크플로를 고칠 수 있고 어떤 시크릿에 닿는가.

- SHA 로 핀되지 않은 서드파티 액션 (`uses:` 줄에 `@<sha>` 없음)
- `pull_request_target` — 포크 PR 이 write 권한을 얻는다
- `run:` 스텝 안 `${{ github.event.* }}` 스크립트 인젝션
- 시크릿을 env 변수로 (로그 유출 가능)
- 워크플로 파일의 CODEOWNERS 보호

**심각도** — `pull_request_target` + PR 코드 체크아웃 / `${{ github.event.*.body }}` 스크립트 인젝션 = CRITICAL · 핀 안 된 서드파티 액션 / 마스킹 없는 시크릿 env = HIGH · 워크플로 CODEOWNERS 부재 = MEDIUM.
**오탐 규칙** — 퍼스트파티 `actions/*` 미핀은 MEDIUM · **PR ref 체크아웃 없는 `pull_request_target` 은 안전**(선례 11) · `env:`/`run:` 이 아닌 `with:` 블록의 시크릿은 런타임이 처리.

## Phase 5 — 인프라 섀도 표면

- **Dockerfile** — `USER` 지시자 부재(root 실행) · `ARG` 로 넘긴 시크릿 · 이미지에 복사된 `.env` · 노출 포트.
- **설정 파일의 prod 크레덴셜** — `postgres://`·`mysql://`·`mongodb://`·`redis://` 연결 문자열. localhost·127.0.0.1·example.com 은 제외. staging/dev 설정이 prod 를 가리키는지도 본다.
- **IaC** — Terraform 의 IAM action/resource `"*"`, `.tf`/`.tfvars` 하드코딩 시크릿. K8s 의 privileged 컨테이너·hostNetwork·hostPID.

**심각도** — 커밋된 설정의 크레덴셜 포함 prod DB URL / 민감 리소스에 `"*"` IAM / 이미지에 구워진 시크릿 = CRITICAL · prod 의 root 컨테이너 / prod DB 를 쥔 staging / privileged K8s = HIGH · `USER` 부재 / 목적 미기재 노출 포트 = MEDIUM.
**오탐 규칙** — 로컬 개발용 `docker-compose.yml` + localhost 는 발견이 아니다(선례 12) · Terraform `data` 소스(읽기 전용)의 `"*"` 제외 · `test/`·`dev/`·`local/` 의 localhost K8s 매니페스트 제외.

## Phase 6 — 웹훅·연동 감사

무엇이든 받아들이는 인바운드 엔드포인트를 찾는다.

- **웹훅 라우트** — webhook·hook·callback 라우트 패턴을 가진 파일을 찾고, **같은 파일에 서명 검증**(signature·hmac·verify·digest·x-hub-signature·stripe-signature·svix)이 있는지 본다. 라우트는 있는데 검증이 없으면 발견이다.
- **TLS 검증 비활성** — `verify.*false` · `VERIFY_NONE` · `InsecureSkipVerify` · `NODE_TLS_REJECT_UNAUTHORIZED.*0`.
- **OAuth 스코프** — 과도하게 넓은 스코프.

🔴 **검증은 코드 추적으로만.** 미들웨어 체인(부모 라우터·미들웨어 스택·API 게이트웨이 설정) 어딘가에 검증이 있는지 코드로 따라간다. **웹훅 엔드포인트에 실제 HTTP 요청을 보내지 않는다.**

**심각도** — 서명 검증이 전혀 없는 웹훅 = CRITICAL · prod 코드의 TLS 검증 비활성 / 과대 OAuth 스코프 = HIGH · 서드파티로 나가는 미기재 아웃바운드 = MEDIUM.
**오탐 규칙** — 테스트 코드의 TLS 비활성 제외 · 사설망 내부 서비스 간 웹훅은 MEDIUM 상한 · 게이트웨이가 상류에서 서명을 검증하면 발견이 아니지만 **증거가 필요하다.**

## Phase 7 — LLM·AI 보안

새로운 공격 클래스다.

- **프롬프트 인젝션 벡터** — 사용자 입력이 시스템 프롬프트나 도구 스키마로 흘러드는가. 시스템 프롬프트 구성 근처의 문자열 보간을 본다.
- **정제되지 않은 LLM 출력** — `dangerouslySetInnerHTML` · `v-html` · `innerHTML` · `.html()` · `raw()` 로 렌더되는 응답.
- **검증 없는 도구 호출** — `tool_choice` · `function_call` · `tools=` · `functions=`.
- **코드에 박힌 AI API 키** — `sk-` 패턴, 하드코딩 대입.
- **LLM 출력의 eval/exec** — `eval()` · `exec()` · `Function()` · `new Function`.

grep 너머로 볼 것 — 사용자 콘텐츠 흐름 추적 · RAG 포이즈닝(외부 문서가 검색을 통해 행동을 바꾸는가) · 도구 호출 권한 검증 · 출력을 신뢰하는가 · **비용/자원 공격**(사용자가 무한 LLM 호출을 유발할 수 있는가).

**심각도** — 시스템 프롬프트의 사용자 입력 / HTML 로 렌더되는 미정제 출력 / LLM 출력 eval = CRITICAL · 도구 호출 검증 부재 / 노출된 AI 키 = HIGH · 무한 호출 / 입력 검증 없는 RAG = MEDIUM.
**오탐 규칙** — 🔴 **대화의 user-message 위치에 있는 사용자 콘텐츠는 프롬프트 인젝션이 아니다**(선례 13). 시스템 프롬프트·도구 스키마·function-calling 컨텍스트로 들어갈 때만 발견이다.

## Phase 8 — 스킬 공급망

설치된 에이전트 스킬을 악성 패턴으로 스캔한다. 공개 스킬의 36% 가 보안 결함, 13.4% 가 명백한 악성이다(Snyk ToxicSkills).

- **Tier 1 — 레포 로컬 (자동)** — `.claude/skills/` 의 `SKILL.md` 를 검사: `curl`·`wget`·`fetch`·`http`·`exfiltrat` (네트워크 반출) · `ANTHROPIC_API_KEY`·`OPENAI_API_KEY`·`process.env` (크레덴셜 접근) · `IGNORE PREVIOUS`·`system override`·`disregard`·`forget your instructions` (프롬프트 인젝션).
- **Tier 2 — 전역 스킬 (허가 필요)** — 레포 밖 사용자 홈을 읽는다. 🔴 **브리프에 명시되지 않았으면 스캔하지 말고 Ask 로 PM 에게 묻는다.**

**심각도** — 크레덴셜 반출 시도 / 스킬 파일의 프롬프트 인젝션 = CRITICAL · 수상한 네트워크 호출 / 과대 도구 권한 = HIGH · 미검증 출처 = MEDIUM.
**오탐 규칙** — 하네스 자신의 스킬은 신뢰 대상 · 정당한 `curl`(도구 내려받기·헬스체크)은 **대상 URL 이 수상하거나 크레덴셜 변수가 함께 있을 때만** 발견.

## Phase 9 — OWASP Top 10

- **A01 접근 제어 붕괴** — 라우트의 인증 누락(`skip_before_action`·`skip_authorization`·`no_auth`) · 직접 객체 참조(`params[:id]`·`req.params.id`) · A 가 B 의 자원을 ID 만 바꿔 읽는가 · 수평/수직 권한 상승.
- **A02 암호 실패** — 약한 알고리즘(MD5·SHA1·DES·ECB) · 하드코딩 시크릿 · 저장·전송 시 암호화 · 키 관리.
- **A03 인젝션** — SQL(raw 쿼리·문자열 보간) · 명령(`system()`·`exec()`·`spawn()`·`popen`) · 템플릿(`render` with params·`html_safe`·`raw()`) · LLM 은 Phase 7.
- **A04 안전하지 않은 설계** — 인증 엔드포인트 레이트 리밋 · 실패 후 계정 잠금 · 서버 측 비즈니스 로직 검증.
- **A05 보안 설정 오류** — CORS 와일드카드 · CSP 헤더 · prod 의 디버그 모드/상세 에러.
- **A06 취약·구식 컴포넌트** — **Phase 3** 참조.
- **A07 인증 실패** — 세션 생성·저장·무효화 · 비밀번호 정책 · MFA(관리자 강제?) · JWT 만료와 리프레시 로테이션.
- **A08 무결성 실패** — **Phase 4** 참조 · 역직렬화 입력 검증 · 외부 데이터 무결성 검사.
- **A09 로깅·모니터링 실패** — 인증 이벤트 · 인가 실패 · 관리자 행위 감사 추적 · 로그 변조 방지.
- **A10 SSRF** — 사용자 입력으로 만든 URL · 내부 서비스 도달 가능성 · 아웃바운드 allowlist.

## Phase 10 — STRIDE 위협 모델

Phase 0 에서 식별한 주요 컴포넌트마다 평가한다.

```
COMPONENT: [이름]
  Spoofing:               사용자·서비스를 사칭할 수 있는가?
  Tampering:              전송 중·저장 중 데이터를 변조할 수 있는가?
  Repudiation:            행위를 부인할 수 있는가? 감사 추적이 있는가?
  Information Disclosure: 민감 데이터가 샐 수 있는가?
  Denial of Service:      압도당할 수 있는가?
  Elevation of Privilege: 권한을 넘어설 수 있는가?
```

## Phase 11 — 데이터 분류

```
RESTRICTED (유출 = 법적 책임):
  - 비밀번호·크레덴셜: [저장 위치, 보호 방식]
  - 결제 데이터:       [저장 위치, PCI 준수 상태]
  - PII:               [유형, 저장 위치, 보존 정책]
CONFIDENTIAL (유출 = 사업 피해):
  - API 키:            [저장 위치, 로테이션 정책]
  - 비즈니스 로직:     [코드 안의 영업비밀?]
  - 사용자 행동 데이터
INTERNAL (유출 = 망신):
  - 시스템 로그:       [내용, 접근 권한]
  - 설정:              [에러 메시지에 노출되는 것]
PUBLIC:
  - 마케팅·문서·공개 API
```

## Phase 12 — 오탐 필터 + 능동 검증 (항상)

🔴 **후보를 전부 이 필터에 통과시킨 뒤에만 보고한다. 오탐 1건이 신뢰 전체를 깎는다.**

**신뢰 게이트** — `daily` 는 8/10 미만 보고 금지(9–10 = 익스플로잇 경로 확실, PoC 를 쓸 수 있다 / 8 = 알려진 악용 방법이 있는 명백한 취약 패턴). `comprehensive` 는 2/10 이며 8 미만은 `TENTATIVE` 로 표시한다.

**하드 제외 — 아래에 걸리면 자동 폐기한다.**

1. DoS · 자원 고갈 · 레이트 리밋 — **예외: Phase 7 의 LLM 비용 증폭(무한 호출·상한 부재)은 DoS 가 아니라 재무 위험이므로 폐기하지 않는다.**
2. 달리 보호된(암호화·권한) 디스크 저장 시크릿
3. 메모리·CPU 고갈, 파일 디스크립터 누수
4. 영향이 입증되지 않은 비보안 필드의 입력 검증
5. 신뢰할 수 없는 입력으로 명확히 트리거되지 않는 GitHub Action 이슈 — **예외: Phase 4 발견(미핀 액션·`pull_request_target`·스크립트 인젝션·시크릿 노출)은 폐기하지 않는다.**
6. 하드닝 부재 — 없는 모범 사례가 아니라 구체적 취약점을 보고한다. **예외: 미핀 서드파티 액션과 워크플로 CODEOWNERS 부재는 구체적 위험이다.**
7. 구체적 경로로 악용 가능하지 않은 경쟁 조건·타이밍 공격
8. 구식 서드파티 라이브러리 취약점 (Phase 3 소관)
9. 메모리 안전 언어(Rust·Go·Java·C#)의 메모리 안전성
10. 비테스트 코드가 import 하지 않는 순수 테스트 파일·픽스처
11. 로그 스푸핑 — 미정제 입력을 로그에 쓰는 것 자체는 취약점이 아니다
12. 공격자가 host·protocol 이 아니라 path 만 제어하는 SSRF
13. AI 대화의 user-message 위치에 있는 사용자 콘텐츠
14. 신뢰할 수 없는 입력을 처리하지 않는 코드의 정규식 복잡도 (사용자 문자열에 대한 ReDoS 는 진짜다)
15. 문서 파일(`*.md`)의 보안 우려 — **예외: `SKILL.md` 는 문서가 아니라 에이전트 행동을 지배하는 실행 프롬프트 코드다. Phase 8 발견은 절대 제외하지 않는다.**
16. 감사 로그 부재
17. 비보안 맥락의 취약한 난수 (UI 엘리먼트 ID 등)
18. 최초 셋업 PR 안에서 커밋되고 같이 제거된 히스토리 시크릿
19. CVSS 4.0 미만이고 알려진 익스플로잇이 없는 의존성 CVE
20. prod 배포 설정이 참조하지 않는 `Dockerfile.dev`·`Dockerfile.local`
21. 보관·비활성 워크플로의 CI/CD 발견
22. 하네스 자신의 스킬 파일

**선례** — ① 평문 시크릿 로깅은 취약점이다(URL 로깅은 안전) ② UUID 는 추측 불가 ③ 환경 변수와 CLI 플래그는 신뢰 입력 ④ React·Angular 는 기본 XSS 안전(탈출구만 발견) ⑤ 클라이언트 JS 는 인증 책임이 없다 ⑥ 셸 명령 인젝션은 구체적 비신뢰 입력 경로가 필요 ⑦ 미묘한 웹 취약점은 극히 높은 확신 + 구체적 익스플로잇일 때만 ⑧ 노트북은 비신뢰 입력이 트리거할 때만 ⑨ 비PII 로깅은 취약점 아님 ⑩ 락파일 미추적은 앱 레포에서만 발견 ⑪ PR ref 체크아웃 없는 `pull_request_target` 은 안전 ⑫ 로컬 `docker-compose` 의 root 컨테이너는 발견 아님(prod Dockerfile·K8s 는 발견).

**능동 검증 — 안전한 선에서 증명한다.**

1. **시크릿** — 실제 키 형식인지(길이·접두어) 본다. **실 API 로 테스트하지 않는다.**
2. **웹훅** — 미들웨어 체인을 코드로 추적한다. **HTTP 요청을 보내지 않는다.**
3. **SSRF** — URL 구성 경로가 내부 서비스에 닿는지 코드로 추적한다.
4. **CI/CD** — 워크플로 YAML 을 파싱해 `pull_request_target` 이 정말 PR 코드를 체크아웃하는지 확인한다.
5. **의존성** — 취약 함수가 직접 호출되면 `VERIFIED`. 아니면 `UNVERIFIED` + "프레임워크 내부·전이 실행·설정 경로로 도달 가능할 수 있음, 수동 확인 권장".
6. **LLM** — 사용자 입력이 실제로 시스템 프롬프트 구성에 닿는지 추적한다.

각 발견을 `VERIFIED`(코드 추적으로 확인) · `UNVERIFIED`(패턴 일치만) · `TENTATIVE`(comprehensive 의 8 미만)로 표시한다.

**변종 분석** — 발견이 `VERIFIED` 되면 **같은 패턴을 코드베이스 전체에서 찾는다.** SSRF 하나가 확인됐다면 다섯 개가 더 있을 수 있다. 변종은 `Finding #N 의 변종`으로 연결해 별도 발견으로 보고한다.

**병렬 독립 검증** — 후보마다 `Agent` 로 독립 검증 하위 워커를 띄운다. **읽기 브리프만** 주고, 앵커링을 피하기 위해 **file:line 과 오탐 규칙만** 전달한다("이 위치의 코드를 읽어라. 독립적으로 판단해라 — 진짜 취약점인가? 1–10 점. 8 미만이면 왜 아닌지 설명해라"). 검증자가 8 미만(comprehensive 는 2 미만)을 주면 폐기한다. 하위 워커를 못 띄우면 회의적 눈으로 재독하고 `자체 검증 — 독립 하위 작업 불가` 라고 명시한다.

## Phase 13 — 보고 (항상)

🔴 **모든 발견은 구체적 익스플로잇 시나리오를 포함해야 한다** — 공격자가 밟을 단계별 경로. "이 패턴은 안전하지 않다"는 발견이 아니다.

```
SECURITY FINDINGS
═════════════════
#   Sev    Conf   Status      Category         Finding                          Phase   File:Line
──  ────   ────   ──────      ────────         ───────                          ─────   ─────────
1   CRIT   9/10   VERIFIED    Secrets          AWS key in git history           P2      .env:3
2   CRIT   9/10   VERIFIED    CI/CD            pull_request_target + checkout    P4      .github/ci.yml:12
3   HIGH   8/10   UNVERIFIED  Integrations     Webhook w/o signature verify      P6      api/webhooks.ts:24
```

**신뢰도 보정** — 9–10 정상 표시 · 7–8 정상 표시 · 5–6 "중간 신뢰, 실제 이슈인지 확인 필요" 단서와 함께 · 3–4 본문에서 억제하고 부록에만 · 1–2 심각도가 P0 일 때만.

**발견 형식**

```
## Finding N: [제목] — [File:Line]
* Severity:    CRITICAL | HIGH | MEDIUM
* Confidence:  N/10
* Status:      VERIFIED | UNVERIFIED | TENTATIVE
* Phase:       N — [페이즈 이름]
* Category:    [Secrets | Supply Chain | CI/CD | Infrastructure | Integrations | LLM Security | Skill Supply Chain | OWASP A01-A10]
* Description: [무엇이 잘못됐나]
* Exploit:     [단계별 공격 경로]
* Impact:      [공격자가 얻는 것]
* Recommendation: [구체적 수정안 — 텍스트로만. 적용하지 않는다]
```

🔴 **발신 전 검증 게이트** — 발견을 보고서에 올리기 전에 **그 발견을 유발한 코드 줄을 file:line 과 함께 그대로 인용**한다. "필드 X 가 모델 Y 에 없다"면 Y 의 해당 위치를 인용하고, "dict.get() 이 None 일 수 있다"면 dict 초기화를 인용한다. **인용할 수 없으면 그 발견은 unverified 이며 신뢰도를 4–5 로 강등**해 본문에서 뺀다. 추측으로 7 이상을 매겨 게이트를 우회하지 않는다.

- **프레임워크 메타 보정** — 심볼이 프레임워크 메타클래스·디스크립터·ORM Meta·마이그레이션(Django `Meta`, Rails `has_many`, SQLAlchemy `relationship`, TypeORM 데코레이터, Prisma 생성 클라이언트)로 만들어지면 클래스 본문 대신 **그 메타 구성물**을 인용한다. 검증은 "이 심볼을 만드는 소스를 읽었다"이지 "이름을 grep 했는데 없더라"가 아니다.

**시크릿 유출 대응 플레이북** (권고 텍스트로만 — 실행하지 않는다) — ① 즉시 폐기 ② 로테이트 ③ 히스토리 세척(`git filter-repo`·BFG) ④ 정리된 히스토리 force-push ⑤ 노출 기간 감사(언제 커밋·언제 제거·공개 레포였나) ⑥ 공급자 감사 로그로 악용 확인.

**Handoff** — 발견표와 발견 본문을 `Outputs` 에 넣는다. 후속 조치(수정·수용·연기)는 **PM 이 정한다** — 이 문서는 판단 재료를 줄 뿐 로드맵을 만들지 않는다.
