# Promotion Topology (episodic → semantic, 3 stages)

> Tree → [[vault-tree]] · knowledge → [[knowledge-convention]] · sessions → [[sessions-note-convention]]

## <project>/knowledge/ Promotion
```
session Learned  ──(scribe, realtime)──▶  <project>/knowledge/
```
- **Stage 1 (realtime, `scribe`)**: at session close, each Learned → (a) **score gate** (canon: `skills/_session-shared/knowledge-promotion.md`) — **sum ≥ 3 promotes / below → reject-log at `<project>/knowledge/0.rejected.md`** (not discarded — audit trail + recurrence signal for Dreaming. No `title:`, so it never hits recall) (b) query for similars via graphify → update/create (c) atomic note, trigger-first (d) uid backlink. **Never force perfect dedup** — write roughly and let Dreaming clean up.

## common/patterns/ Promotion
```
<project>/knowledge/  ──(Dreaming, batch)──▶  common/patterns/
```
- **Stage 2 (batch, Dreaming)**: a `scribe` worker that sees only one session cannot spot cross-recurrence. Dreaming, which sees the whole, elevates project knowledge recurring across ≥3 projects up to `000_common/patterns/`.

## common/facts/ Promotion
```
environment facts  ──(direct / auto-derived)──▶  common/facts/
```
- **Facts**: not promotion — maintained directly / auto-derived.

## common/policies/ Promotion
```
org-wide binding norm (external mandate OR self-imposed invariant)  ──(draft=agent / signature=user)──▶  common/policies/
```
- **Policies**: **not** promotion **on the patterns/knowledge axis** — accumulated advice (patterns) does not become obligation (policies). They are set directly by decision, origin-agnostic (an external mandate like a law/regulation, or a self-imposed org-wide invariant); the transcription path from such a norm is the next item.
- **Human sign-off gate (canon: this section)** — **no agent writes `common/policies/` on its own. Agents draft; the user signs.** A candidate that reads as obligation is still recorded on its normal tier (project `knowledge/` — nothing is lost) and **additionally returned as a `common-policy candidates` list**; the calling skill presents the list **in one batch** at the promotion point (`skills/sh`·`sc` · dreaming §7), and only approved items get a follow-up `scribe` brief writing to `000_common/policies/`. **Never interrupt per item.**
- **Why only policies**: they sit at the top of Document Conflict Precedence (`docs/project-docs-convention.md`), so one wrong entry silently overrides every other document. Project `knowledge/` · `facts/` · `patterns/` keep the **automatic** score gate unchanged (`skills/_session-shared/knowledge-promotion.md`).

## docs/adr/
```
decision occurs  ──(architecture, immediate)──▶  <project>/docs/adr/
```
- **ADR**: **no** promotion — a single tier in `docs/adr/` from birth. They never rise out of feature folders (they are never written there in the first place).
- **Cross-project decisions are not raised into ADRs either** — a decision that binds every project in this vault goes to `common/policies/` (origin-agnostic — external mandate or self-imposed invariant); one that may legitimately differ per project stays split (each project its own ADR, or a per-project norm in `<project>/docs/policy/`). **The test is whether an exception can arise inside this vault, not whether the org differs** — a convention that needs a per-project exception is not a policy at all: admit one exception and its binding force is gone. So bundling a genuinely divergent decision into `common/policies/` makes exceptions impossible. In a single-org vault git branch strategy does *not* diverge — it stays in `common/policies/`; it would split per project only if several distinct orgs shared one vault.

## <project>/docs/policy/ Promotion
```
<feature>/policy/  ──(detection=Dreaming / approval=user)──▶  <project>/docs/policy/
```
- **Policy**: a **separate axis** from the 3 stages above (norms, not knowledge). Feature policy → project policy promotion
