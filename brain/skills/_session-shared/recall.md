# Reference: Recall (shared procedure)

> The recall-injection procedure `ss` invokes for both **new session creation** and **continue/resume**. Primes relevant accumulated memory at session start. Recall-layer overview is `docs/memory-control-convention.md` §Recall — the canonical procedure is this document. Not executed standalone.
> Prerequisites: `VAULT` (vault root — the vault-root value in the project `CLAUDE.local.md`, recorded by `/brain:init` onboarding. No hardcoding) · `PROJDIR` (the current project folder inside the vault, `NNN_<project>`) · `<project>` (slug) are set.

## graphify first
If the vault has `graphify-out/graph.json`, pull with `graphify query "<session goal>" --budget 800` (includes source_location) instead of grep. Otherwise use the grep priming below.

## grep priming — scan 4 sources (not just project knowledge)
```bash
# Meta-file exclusion convention: `! -name 'index.md' ! -name '0.*'` — both are required.
#   - `index.md`  = folder TOC (not a recall target).
#   - `0.*`       = `0.`-prefixed meta logs — currently `0.rejected.md` (reject-log, canonical: knowledge-promotion.md).
# Using only one of them leaks: exclude only index.md and 0.rejected slips in; exclude only 0.* and index slips in.

# 1) [K] this project's knowledge — title + path. Meta (index, 0.rejected) excluded:
find "$PROJDIR/knowledge" -maxdepth 1 -name '*.md' ! -name 'index.md' ! -name '0.*' 2>/dev/null | while read -r f; do
  t=$(grep -h '^title:' "$f" 2>/dev/null | sed 's/^title: *//'); [ -n "$t" ] && printf 'K  %s  —  %s\n' "$t" "$f"
done
# 2) [C] common (facts + patterns + policies) — cross-project knowledge (infra facts, shared patterns, norms):
#    The folder name is `000_common` (canonical tree: docs/vault-tree.md).
#    policies = the normative axis (top priority on document conflicts — docs/project-docs-convention.md) → high recall value, so scan it on par with facts and patterns.
#    ⚠ The `${t:-basename}` fallback here exists to keep notes without `title:` alive, so [K]'s `[ -n "$t" ]` guard is absent
#      → name-based exclusion is the **only line of defense**. Do not delete the exclusion convention above (index.md would surface straight into recall).
find "$VAULT/000_common/facts" "$VAULT/000_common/patterns" "$VAULT/000_common/policies" -maxdepth 1 -name '*.md' ! -name 'index.md' ! -name '0.*' 2>/dev/null | while read -r f; do
  t=$(grep -h '^title:' "$f" 2>/dev/null | sed 's/^title: *//'); printf 'C  %s  —  %s\n' "${t:-$(basename "$f" .md)}" "$f"
done
# 3) [X] cross-membership — other projects' knowledge notes whose projects: includes the current project:
#    `[0-9]*_*` sweeps every numeric-prefixed folder — project folders (NNN_<project>) are the target,
#    and `000_common` matches the glob too but has no knowledge/ subfolder, so it is a no-op. common is 2)'s job (intended division of labor).
find "$VAULT"/[0-9]*_*/knowledge -maxdepth 1 -name '*.md' ! -name 'index.md' ! -name '0.*' 2>/dev/null | while read -r f; do
  case "$f" in "$PROJDIR"/*) continue ;; esac   # the current project is handled in 1)
  grep -Eq "^projects:.*<project>" "$f" 2>/dev/null || continue
  t=$(grep -h '^title:' "$f" 2>/dev/null | sed 's/^title: *//'); [ -n "$t" ] && printf 'X  %s  —  %s\n' "$t" "$f"
done
# 4) [M] Mistakes from this project's past sessions (repeat prevention) — with their source sessions:
find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null | while read -r f; do
  grep -q '^session_type: dreaming' "$f" && continue   # dreaming reports are not work sessions (prevents recall pollution)
  grep -q "^project: <project>" "$f" || continue
  awk '/^#### Mistake/{p=1;next} /^####/{p=0} p' "$f" | sed "s#^#M  $(basename "$f"): #"
done
```

## 1-hop related expansion
From the list above, pick the notes relevant to the goal (A), then include each A note's `related:` neighbors (B) as well: `grep -h '^related:' "<note.md>"`. **1 hop only** (neighbors-of-neighbors = 2+ hops is forbidden — signal dilution and token blowup).

## Injection
Pick only what is relevant into a concise recall block: **A = direct matches (K) first · common (C), cross-membership (X), and 1-hop related as secondary "related" · Mistake (M) summarized**, **~5–8 items total cap**, **source path on every item** (reduces memory hallucination and staleness). If nothing is relevant, quietly move on with "no relevant accumulated memory (fresh vault)".
- **On a policies (C) conflict**: `common/policies/` is the normative axis — when it contradicts facts or patterns, **policies wins** (`docs/project-docs-convention.md` §Document Conflict Precedence). If you spot a contradiction, do not silently pick one — call it out in the recall block.
- **New session**: add as a recall block to `## Context`.
- **Continue**: present recall **together with** the continuation summary (live context priming). Do not overwrite the session note's `## Context`.
> Marker: `<!-- recall: recall.md · K+common(facts/patterns/policies)+cross+Mistake · 1-hop related · source paths · graphify first -->`
