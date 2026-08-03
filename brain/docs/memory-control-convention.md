# Memory Control

> Promotion → [[knowledge-escalate-convention]] · knowledge notes → [[knowledge-convention]] · sessions → [[sessions-note-convention]] · commits → [[git-convention]]

## Handoff Format (worker → PM → scribe, maps to session Progress — Risks·Next·Ask feed To-Do-List / PM judgment)
```
Done / Mistake / Fixed / Learned / Outputs / Risks / Next / Ask   (+ optional: Docs draft)
```
> Workers **never write to the vault directly** — vault writes are serialized through PM-delegated recording briefs (concurrent sessions would otherwise collide in the same files). Hand off, and a `scribe` worker records it via the PM (**`scribe` = a worker given a recording brief** — a label, not a resident agent). Keep `Learned` atomic — promotion quality is governed by capture quality (GIGO).
> **`Docs draft` (optional section — KJP-37 role split)**: when the work affects a project document (architecture · API surface · deployment · schema, or one discovered mid-work), **the worker/coder authors the draft** (goal · structure · behavior — whoever did the work knows it) inside the Handoff. Roles: DoD designation = the PM's brief (as far as it can predict) · content = the worker · vault write = `scribe` (**copies the draft verbatim — authoring forbidden**) · commit = the PM. **A document that does not exist yet takes the same path** — the worker drafts it as a new document, the PM judges creation and location against [[doc-catalog]] (only on a catalog trigger — never habitually), and `scribe` creates the file. The PM forwards the draft into the scribe brief unedited — a PM rewrite reintroduces the guessing the split exists to remove.

## Recall — cue-based
- **CLAUDE.local.md Router pointers** (per project): a **thin router / hot-cache** auto-loaded every session. (Machine-local absolute paths — lives in `CLAUDE.local.md`, never the committed `CLAUDE.md`.)
  - Rules: **pointers only, no content** (token savings). **Auto-maintained** (Dreaming/`scribe`). No hand-curation (it rots).
- **★ recall step**: at session start, pull in related memory — **canon: `skills/_session-shared/recall.md`** (source composition, related hops, caps, and source-path discipline are all defined only there). Two callers, two dispositions:
  - **`ss` (new session)** — recall is **written into `## Context`** (`scribe` delegation). That block is the session's canonical injected-notes record, which `sh`/`sc` later read to bump `recalled:`/`useful:`.
  - **`sr` (resume)** — recall is **re-presented on screen only, never written**. Feedback counters count injection once per session, so a resume extends neither the record nor any counter. Skipping it would leave a resumed session with zero priming, so it is required, not optional.

## Dreaming Skill (sleep consolidation)
Keep realtime cheap; batch the hard parts. Runs periodically (scheduled).
- **dedup / consolidation** — merge accumulated similar notes.
- **staleness flags** — mark claims unreferenced for N months / grown stale (not deletion; flagged for review).
- **Stage-2 promotion + graph links** — elevate cross-project recurrences to common, add missing cross-links.
- **Recall-layer refresh** — regenerate the CLAUDE.local.md Router pointers + rescan the facts inventory.

**Guardrails (violate these and memory gets polluted)**:
- **Incremental** — not the whole vault every time; only what changed or aged since the last dream.
- **Destruction is proposed, never automatic** — only low-risk actions like dead-link fixes run automatically. Merges/deletions need PM/human approval. Never silently overwrite memory.

## Governance (scribe + PM mediation)
- **`scribe` = the vault (memory) recording worker** (spawn = the `worker` profile — spec: knowledge-promotion §Write boundary)**.** All vault writes (Progress, outputs, stage-1 promotion) are delegated by the PM as recording briefs. **Code is strictly forbidden** — code goes straight to the repo/worktree via an **implementation worker**, bypassing `scribe`. A `scribe` brief's payload is knowledge/documents only, so it stays light.
- **`scribe` = a verbatim scribe (not a summarizer).** Records the `Learned`/`Outputs` of worker Handoffs **word for word**. PM compression belongs **only to the user-reporting channel** — the Handoff `scribe` receives is the original text (→ prevents losing the conditional nuances of Mistake/Fixed).
- **Never force realtime dedup** — on duplicates, record both for now; merging & cleanup is Dreaming's job (batch). (fast-but-lossy capture + periodic consolidation)
- **PM mediation**: worker Handoff → PM → `scribe`. **Direct worker→`scribe` is forbidden** — only the PM can see whether delegations overlap. Go direct, and two `scribe` workers silently overwrite the same file.
- **Two concurrency layers**: intra-machine = **`scribe` discipline** (no locks — the PM delegates without overlap) / inter-machine = git merge. Canon → [[git-convention]]
- **PM = the main session · workers = subagents.** A worker's scope is defined by **the PM's brief** (Goal, constraints, context pointers, DoD), not by a role catalog. Labels (`scribe`, `architecture`, etc.) name kinds of briefs — they are not resident agents.
