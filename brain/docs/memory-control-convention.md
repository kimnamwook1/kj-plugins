# Memory Control

> Promotion → [[knowledge-escalate-convention]] · knowledge notes → [[knowledge-convention]] · sessions → [[sessions-note-convention]] · commits → [[git-convention]]

## Handoff Format (worker → PM → scribe, maps to session Progress — Risks·Next·Ask feed To-Do-List / PM judgment)
```
Done / Mistake / Learned / Outputs / Risks / Next / Ask   (+ optional: Docs draft)

- 🔴 **`Fixed` 는 0.2.0 KERNEL 에서 제거됐다** (KJP-64). 워커가 자기 실수를 고친 사실은 `Mistake` 와 같은 사건의 뒷면이라, 항목을 나누면 한 사건이 두 곳에 쪼개져 적힌다. 에이전트 정의는 spawn 마다 100% 주입되므로 항목 하나가 곧 비용이다.
- ⚠ **세션 노트 `## Progress` 의 `#### Fixed` 는 별개이고 살아 있다** — 그쪽은 에이전트 반환 포맷이 아니라 세션 기록 소절이다 (canon: `sessions-note-convention.md`).
```
> Workers **never write to the vault directly** — vault writes are serialized through PM-delegated recording briefs (concurrent sessions would otherwise collide in the same files). Hand off, and a `scribe` worker records it via the PM (**`scribe` = a worker given a recording brief** — a label, not a resident agent). Keep `Learned` atomic — promotion quality is governed by capture quality (GIGO).
> **`Docs draft` (optional section — KJP-37 role split)**: when the work affects a project document (architecture · API surface · deployment · schema, or one discovered mid-work), **the worker/coder authors the draft** (goal · structure · behavior — whoever did the work knows it) inside the Handoff. Roles: DoD designation = the PM's brief (as far as it can predict) · content = the worker · vault write = `scribe` (**copies the draft verbatim — authoring forbidden**) · commit = the PM. **A document that does not exist yet takes the same path** — the worker drafts it as a new document, the PM judges creation and location against [[doc-catalog]] (only on a catalog trigger — never habitually), and `scribe` creates the file. The PM forwards the draft into the scribe brief unedited — a PM rewrite reintroduces the guessing the split exists to remove.

## Recall — cue-based
- **CLAUDE.local.md Router pointers** (per project): a **thin router / hot-cache** auto-loaded every session. (Machine-local absolute paths — lives in `CLAUDE.local.md`, never the committed `CLAUDE.md`.)
  - Rules: **pointers only, no content** (token savings). **Regenerated between the markers by `/brain:init`** — 🔴 not by `dreaming` (it writes only the 3 vault layers) and not by `scribe` (vault content only; `CLAUDE.local.md` is outside the vault). No hand-curation (it rots).
- **★ recall step**: at session start, inject the folder indexes — **canon: `skills/_session-shared/recall.md`** (what is scanned and what is not is defined only there). **`_index.md` whole, note bodies never**; no ranking, no cap, no candidate selection. Two callers, two dispositions:
  - **`ss` (new session)** — recall is **written into `## Recall`** (`scribe` delegation).
  - **`sr` (resume)** — recall is **re-presented on screen only, never written**. Skipping it would leave a resumed session with zero priming, so it is required, not optional.
  - **fail-visible** — both callers report the injected file count and total bytes, 0 included.

## Dreaming Skill (sleep consolidation)
Keep realtime cheap; batch the hard parts. Triggered by `sc` at session close. Inputs are `p_memory` and `neocortex` only — it neither reads nor writes sessions.
- **refine** — conform notes to the form and fold duplicates together, without changing a single fact.
- **link** — join related notes with `related`, never a shortcut between notes already two hops apart.
- **promotion ②** — the same knowledge standing in two projects moves to `neocortex/`, a three-line operation ([[knowledge-escalate-convention]]).

**Guardrails (violate these and memory gets polluted)**:
- **Incremental** — not the whole vault every time; only what changed or aged since the last dream.
- **Destruction is proposed, never automatic** — only low-risk actions like dead-link fixes run automatically. Merges/deletions need PM/human approval. Never silently overwrite memory.

## Governance (scribe + PM mediation)
- **`scribe` = the vault (memory) recording worker** (spawn = the `worker` profile — spec: knowledge-promotion §Write boundary)**.** All vault writes (session files, Progress, frontmatter, `p_memory`, `neocortex`, folder TOCs, docs `history`) are delegated by the PM as recording briefs. **Code is strictly forbidden, and so is committing** — code goes straight to the repo/worktree via an **implementation worker**, and the commit is the PM's (a boundary record that swallows the whole repo, so only whoever sees the whole is safe). A `scribe` brief's payload is notes and documents only, so it stays light.
- **`scribe` = a verbatim scribe (not a summarizer).** Records the `Learned`/`Outputs` of worker Handoffs **word for word**. PM compression belongs **only to the user-reporting channel** — the Handoff `scribe` receives is the original text (→ prevents losing the conditional nuances of Mistake/Fixed).
- **Never force realtime dedup** — on duplicates, record both for now; merging & cleanup is Dreaming's job (batch). (fast-but-lossy capture + periodic consolidation)
- **PM mediation**: worker Handoff → PM → `scribe`. **Direct worker→`scribe` is forbidden** — only the PM can see whether delegations overlap. Go direct, and two `scribe` workers silently overwrite the same file.
- **Two concurrency layers**: intra-machine = **`scribe` discipline** (no locks — the PM delegates without overlap) / inter-machine = git merge. Canon → [[git-convention]]
- **PM = the main session · workers = subagents.** A worker's scope is defined by **the PM's brief** (Goal, constraints, context pointers, DoD), not by a role catalog. Labels (`scribe`, `architecture`, etc.) name kinds of briefs — they are not resident agents.
