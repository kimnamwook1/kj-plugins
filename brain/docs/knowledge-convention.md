# Knowledge Layer (neocortex = semantic long-term memory)

> Tree & naming → [[vault-tree]] · sessions → [[sessions-note-convention]]

## Note Form — atomic + trigger-first (optimal for LLM recall)
Recall is symptom-driven, so **the trigger goes first**.
```
---
type: lesson | gotcha | decision | reference
title: <title containing the trigger>
uid: <anchor; same generator as session uids>
created / updated
projects: [x, y]            # tags, not folders (cross-membership allowed)
source_sessions: [uid...]   # vertical backlink: source sessions (required). Plain uid strings — sessions/ is local-only (gitignored), so never `[[wikilink]]` a session from a knowledge note (body included); it dangles for teammates
related: [[note-a]], [[note-b]]   # horizontal links: topical neighbor Knowledge (planted by the scribe worker at promotion)
status: fresh | stale?      # flagged by Dreaming
---
## Trigger   when this becomes relevant (symptom/situation)
## Insight   the core reusable knowledge
## Why       rationale + sources
```
- **1 note = 1 reusable claim** (atomic). No essays.
- **update-over-create**: if similar, don't create anew — add nuance to the existing note (living note).
- **Horizontal links are the precondition for recall** — `source_sessions` (vertical) alone gives weak topic-to-topic connectivity. At promotion, weave adjacent Knowledge into `related` (when not merging). Explicit links only — with weak links, every recall tool fails at multi-hop recall. **Orphans (0 inbound) and missing cross-refs are audited & reinforced by Dreaming**.

## `common/` = 3 Axes (origin, lifespan, and trust model each differ)

| | A. `facts/` (facts) | B. `patterns/` (distilled lessons) | C. `policies/` (norms) |
|---|---|---|---|
| Content | infra · credential locations · CLI inventory · accounts · conventions | lessons & patterns shared across projects | company-wide compliance — laws, regulations, certifications |
| Question asked | "what is true" | "what works well" | "what must be done" |
| Origin | environment/world — written directly or auto-derived | upward distillation of project Knowledge (promotion) | external mandates — laws, regulators, certification requirements |
| Verification | "still true?" (checkable against reality) | "still best?" (judgment) | "still in force?" (whether the law changed) |
| Binding force | none (descriptive) | none (advisory) | yes (no project exceptions) |
| staleness | fast → rescan | slow | slow (only when laws change) |

- **Why split off the 3rd axis**: facts are *facts*, patterns are *techniques*, policies are *norms*. "What is true" and "what must be done" differ in both verification method and binding force — mix norms into facts and "checking against reality" becomes impossible (a norm is an ought, not a reality); mix them into patterns and advice becomes indistinguishable from obligation.
