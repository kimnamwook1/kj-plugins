# Promotion Topology — two stages, judged by content

> Tree → [[vault-tree]] · note form → [[knowledge-convention]] · sessions → [[sessions-note-convention]]

Knowledge rises exactly twice.

```
hippocampus/  ──① sc──▶  <project>/p_memory/  ──② dreaming──▶  neocortex/
```

There is no score, no weight, and no threshold anywhere on this path. **Sameness is decided by content**: matching filenames or titles only narrow the candidate set, and the merge itself turns on whether the two notes assert the same thing. If a number, path, version, or condition disagrees, they are different knowledge — link them, do not merge them.

## ① session → `p_memory` — `sc` writes it

At session close, `sc` reads the conversation and extracts two things: **what the user corrected**, and **what the AI admitted was its own mistake and then recovered from**. Those become project knowledge, rewritten in the note form ([[knowledge-convention]]).

- Compare against existing slugs first. Same subject ⇒ **merge into the existing note**, do not create a second one.
- The note lands at `<project>/p_memory/<pp>_<slug>.md`, and `p_memory/_index.md` is updated in the same commit.
- **Nothing is written back to the session.** raw stays raw — the session carries no promotion marker, no backlink, no counter.
- `related:` is left `[]`. Linking is stage ②'s job.

## ② `p_memory` → `neocortex` — `dreaming` moves it

When the same knowledge stands in **two different projects**, it has earned the claim that it does not depend on either. `dreaming` moves it up.

**Three lines change inside the note. Everything else in it is byte-identical.**

```
1. git mv <project>/p_memory/<pp>_<slug>.md   neocortex/NEO-<slug>.md
2. append <pp>_<slug> to aliases
3. insert the projects key (the 2 slugs the judgment was made on)
```

🔴 **The note is not the whole operation — step 1 is a rename, and a rename is not finished until its inbound links are rewired.** Everything that named `<pp>_<slug>` now names nothing: the source project's `p_memory/_index.md` line, `neocortex/_index.md`'s new line, and every `related:` entry pointing at the old stem. All of it lands **in the same commit as the move**. `aliases:` does not stand in for that work — Obsidian's resolver, the canonical verdict on link integrity (`skills/_session-shared/vault-io.md` §2), does not read the key at all. Measured 2026-08-12: a note moved with its old basename appended to `aliases:` stayed in `obsidian unresolved` under the old stem, and this vault's `projects/001_rss-proj/_index.md` has advertised `aliases: [rss-proj]` since 2026-07-12 while 14 links to `rss-proj` remain unresolved. Evidence and the verification method: [[knowledge-convention]] §Filename.

- **The body is not edited.** No reformatting, no re-summarizing, no status field.
- `projects:` is **write-once** — it freezes the evidence used at that moment, not the note's current scope. Never appended to or corrected later.
- The old name is kept in `aliases:` so a reader who remembers it can still find the note. That is a courtesy to human memory, not link maintenance.
- Two notes that are related but not the same knowledge get a `related:` link instead of a move.

## What does not ride this ladder

- **`<common_root>/` is not a promotion tier.** Its descriptive folders are a fact record maintained by measurement, and its `*policies*` directories are the normative axis, sitting at the top of Document Conflict Precedence ([[project-docs-convention]]). Neither is reached by this ladder: the unattended cycle (`sc` · `dreaming`) never writes there, and for `dreaming` the path is refused twice, once before the write and once before the commit (`skills/dreaming/SKILL.md` §Paths).
  - 🔴 **That is a bar on the ladder, not on the AI.** A norm is written by an AI acting on a user instruction, exactly like every other user-directed write ([[vault-tree]] §Write permission) — what no agent may do is **decide** one on its own judgment. So an org-wide obligation does not ride up this path; it gets promoted as ordinary project knowledge and **surfaced to the user as a `common-policy candidate`** (`skills/_session-shared/knowledge-promotion.md` step 3). The user's answer, not the agent's, is what turns it into a norm — and then an agent writes it.
- **ADRs are a human-approved artifact.** They live at `<project>/docs/adr/<pp>-ADR-0000N.md` from birth, at a single tier, and the unattended cycle neither reads nor writes them. A decision is never promoted into an ADR and an ADR never rises out of one.
