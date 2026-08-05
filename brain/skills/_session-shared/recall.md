# Reference: Recall (0.2.0)

세션 시작에 주입되는 것은 **`_index.md` 뿐이다.** 노트 본문은 주입하지 않는다 — 에이전트가 목록과
`summary` 한 줄로 무엇이 어디 있는지 알고, 필요한 노트만 링크를 따라 직접 연다.
랭킹 없음 · **주입량 상한 없음**(이 파일 크기 상한과 무관) · 후보 선별 없음.

전제: `VAULT`(CLAUDE.local.md 의 vault-root) · `<project>`(project-inference.md).

```bash
. "${CLAUDE_SKILL_DIR}/../../scripts/vault-paths.sh"    # BRAIN_COMMON · brain_project_dir
PROJDIR=$(brain_project_dir "<project>")

{ find "$PROJDIR"       -name '_index.md' 2>/dev/null    # 현재 프로젝트 전량
  find "$BRAIN_COMMON"  -name '_index.md' 2>/dev/null    # 공통층 전량
  ls    "$VAULT/neocortex/_index.md"      2>/dev/null    # 볼트 전역 지식
} | sort -u | while read -r f; do
    printf '\n### %s\n' "${f#$VAULT/}"; cat "$f"
  done
```

- `hippocampus/**` 는 스캔하지 않는다(raw 층).
- **fail-visible**: 주입한 파일 수와 총 바이트를 **항상** 출력한다. 0건이면 0건이라고 말한다.
- **`ss`(신규 세션)** — 결과를 `## Recall` 에 쓴다. **`sr`(재개)** — 화면 출력만, 파일을 고치지 않는다.
