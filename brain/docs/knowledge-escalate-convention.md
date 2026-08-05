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

**The whole operation is three lines. Everything else is byte-identical.**

```
1. git mv <project>/p_memory/<pp>_<slug>.md   neocortex/NEO-<slug>.md
2. append <pp>_<slug> to aliases
3. insert the projects key (the 2 slugs the judgment was made on)
```

- **The body is not edited.** No reformatting, no re-summarizing, no status field.
- `projects:` is **write-once** — it freezes the evidence used at that moment, not the note's current scope. Never appended to or corrected later.
- The old name survives in `aliases:`, so links written before the move still resolve.
- Two notes that are related but not the same knowledge get a `related:` link instead of a move.

## What does not ride this ladder

- **`<common_root>/` is a fact record, not a promotion tier.** It is maintained by measurement. The unattended cycle (`sc` · `dreaming`) never writes there, and the refusal is enforced twice — once before the write and once before the commit ([[vault-tree]] §Write permission). Its `*policies*` directories are the normative axis and sit at the top of Document Conflict Precedence ([[project-docs-convention]]), which is why no agent may set one on its own.
- **ADRs are a human-approved artifact.** They live at `<project>/docs/adr/<pp>-ADR-0000N.md` from birth, at a single tier, and the unattended cycle neither reads nor writes them. A decision is never promoted into an ADR and an ADR never rises out of one.
