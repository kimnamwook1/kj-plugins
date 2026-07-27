# Reference: Recall (shared procedure)

> The recall procedure invoked by **`ss`** (new session creation — result **written** into `## Context`) and by **`sr`** (resume — result **presented on screen only, never written**). Primes relevant accumulated memory at session start. Recall-layer overview is `docs/memory-control-convention.md` §Recall — the canonical procedure is this document. Not executed standalone.
> Prerequisites: `VAULT` (vault root — the vault-root value in the project `CLAUDE.local.md`, recorded by `/brain:init` onboarding. No hardcoding) · `PROJDIR` (the current project folder inside the vault, `NNN_<project>`) · `<project>` (slug) · `GOAL` (the session goal string — feeds the ranker's overlap term) are set.
> Tree axes (common layer · projects root) are **not** prerequisites and **not** literals in this file — `scripts/vault-paths.sh` resolves them from the vault's `.brain-paths` manifest, defaulting to the pre-restructure layout when the manifest is absent.

## graphify first
If the vault has `graphify-out/graph.json`, pull with `graphify query "<session goal>" --budget 800` (includes source_location) instead of grep. Otherwise use the grep priming below.

## grep priming — scan 4 sources → deterministic ranker
Each of the 4 source scans (structure unchanged — same find roots, same exclusions, same guards) emits an **enriched TSV candidate** instead of a freeform line; the pipe tail scores every candidate with a fixed integer weighted sum, sorts, and keeps only the top **N** (`RECALL_N`). Formula + weights documented under **## ranker** below. Zero-dependency, bash-3.2 safe (integer arithmetic / awk only — no associative arrays, no `mapfile`, no `grep -P`, no `bc`).
```bash
# Meta-file exclusion convention: `! -name 'index.md' ! -name '0.*'` — both are required.
#   - `index.md`  = folder TOC (not a recall target).
#   - `0.*`       = `0.`-prefixed meta logs — currently `0.rejected.md` (reject-log, canonical: knowledge-promotion.md).
# Using only one of them leaks: exclude only index.md and 0.rejected slips in; exclude only 0.* and index slips in.

RECALL_N="${RECALL_N:-8}"                                    # injection cap N (default 8; tune via env). See "## ranker".
: "${GOAL:?recall: set GOAL to the session goal string (the ss goal — drives the overlap term)}"

# Tree axes come from the vault's own `.brain-paths` manifest, never from literals here — the common
# layer and the projects root do not sit in the same place in every vault, and copying their names
# into each consumer is what made this scan silently return zero after a restructure.
. "${CLAUDE_SKILL_DIR}/../../scripts/vault-paths.sh"         # → BRAIN_COMMON · brain_projects · brain_find_notes

# --- field helpers (single frontmatter scalar · first Trigger line · type→section delta · date→YYYYMMDD int) ---
fm() { grep -h "^$2:" "$1" 2>/dev/null | head -1 | sed "s/^$2:[[:space:]]*//" | tr -d '\r'; }
trigger_line() {                                            # inline-on-heading OR first content line under `## Trigger`
  awk '/^##[ \t]*[Tt]rigger/ { r=$0; sub(/^##[ \t]*[Tt]rigger[ \t]*/,"",r); if(r!=""){print r; exit} f=1; next }
       f && /^## / { exit }
       f && NF     { print; exit }' "$1" 2>/dev/null
}
sec_delta() { case "$1" in gotcha|decision) echo 1 ;; reference) echo -1 ;; *) echo 0 ;; esac; }
ymd() { printf '%s' "$1" | tr -cd '0-9' | cut -c1-8 | grep -E '^[0-9]{8}$' || echo 0; }

# emit one enriched candidate — TSV: SRC \t sec \t conf \t prio \t updated \t PATH \t LABEL \t OVERLAP_TEXT
emit() {
  _s=$1; _p=$2; _l=$(printf '%s' "$3" | tr '\t\n' '  ')
  case "$_s" in
    C) case "$_p" in */policies/*) _sec=4 ;; *) _sec=3 ;; esac ;;   # policies outranks facts/patterns (ticket section axis)
    K) _sec=2 ;; X) _sec=1 ;; *) _sec=1 ;;
  esac
  _sec=$(( _sec + $(sec_delta "$(fm "$_p" type)") ))               # type refinement: gotcha/decision > lesson > reference
  [ "$_sec" -gt 5 ] && _sec=5; [ "$_sec" -lt 1 ] && _sec=1
  _cf=$(fm "$_p" useful | tr -cd '0-9');   [ -n "$_cf" ] || _cf=0  # useful: feedback counter (KJP-7); field absent (pre-KJP-7 note) = 0
  _pr=$(fm "$_p" priority | tr -cd '0-9'); [ -n "$_pr" ] || _pr=0  # priority if present; else 0
  _tr=$(trigger_line "$_p" | tr '\t\n' '  ')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$_s" "$_sec" "$_cf" "$_pr" "$(ymd "$(fm "$_p" updated)")" "$_p" "$_l" "$_l $_tr"
}

{
  # 1) [K] this project's knowledge — title + path. Meta (index, 0.rejected) excluded:
  find "$PROJDIR/knowledge" -maxdepth 1 -name '*.md' ! -name 'index.md' ! -name '0.*' 2>/dev/null | while read -r f; do
    t=$(fm "$f" title); [ -n "$t" ] && emit K "$f" "$t"
  done
  # 2) [C] common (facts + patterns + policies) + machine-global tools — knowledge above the current project:
  #    The common root comes from `.brain-paths` (vault-paths.sh); `999_tools` is a fixed machine-scope folder (canonical tree: docs/vault-tree.md).
  #    policies = the normative axis (top priority on document conflicts — docs/project-docs-convention.md) → high recall value, so scan it on par with facts and patterns.
  #    `999_tools` (tool-mcp/skill/cli/plugin) is IN scope, at the facts tier — emit's C branch gives it sec=3, since it is descriptive inventory, not a norm. Ground:
  #      a) It preserves measured behavior. Those 4 notes lived in `000_common/facts/` and were already scanned here; KJP-44 moved a folder on the
  #         scope-of-truth axis, and did not decide to stop priming tool facts. Dropping them would be an unvoted capability regression.
  #      b) The cost is bounded: +4 candidate files, and only `title:` + the first `## Trigger` line ever enter the pipeline — the 31KB body never does.
  #         W_OVERLAP gates injection, so a goal that never mentions the tool surface never spends budget on them.
  #      c) Router lookup and recall are not exclusive. Router answers "where do I look this up"; recall answers "what should I already know".
  #         A tool note serves both, and being well-suited to one is not an argument for blinding the other.
  #    ⚠ The `${t:-basename}` fallback here exists to keep notes without `title:` alive, so [K]'s `[ -n "$t" ]` guard is absent
  #      → name-based exclusion is the **only line of defense**. Do not delete the exclusion convention above (index.md would surface straight into recall).
  #    🔴 The common layer is scanned **recursively** and its root comes from the manifest, not from a literal here.
  #      Its sub-axes are not the same shape in every vault — flat `{facts,patterns,policies}/` in one, `patterns/` plus
  #      `_company/<folder>/` in another — so naming them would put the tree back into this file, which is what made
  #      this scan return zero after a restructure. brain_find_notes owns the exclusions (meta files, _templates/, archives, dreaming logs).
  CROOTS=()   # indexed arrays are bash 3.2-safe; an empty one under `set -u` would be an error, so guard the expansion
  [ -n "$BRAIN_COMMON" ]      && CROOTS[${#CROOTS[@]}]="$BRAIN_COMMON"
  [ -d "$VAULT/999_tools" ]   && CROOTS[${#CROOTS[@]}]="$VAULT/999_tools"
  if [ ${#CROOTS[@]} -gt 0 ]; then
    brain_find_notes "${CROOTS[@]}" | while read -r f; do
      t=$(fm "$f" title); emit C "$f" "${t:-$(basename "$f" .md)}"
    done
  fi
  # 3) [X] cross-membership — other projects' knowledge notes whose projects: includes the current project:
  #    brain_projects enumerates the project band only — it drops the common root and the reserved `9xx` infra band
  #    (vault-tree.md §Reserved number bands), both of which are 2)'s job (intended division of labor).
  brain_projects | while read -r d; do
    find "$d/knowledge" -maxdepth 1 -name '*.md' ! -name 'index.md' ! -name '_index.md' ! -name '0.*' 2>/dev/null
  done | while read -r f; do
    case "$f" in "$PROJDIR"/*) continue ;; esac   # the current project is handled in 1)
    grep -Eq "^projects:.*<project>" "$f" 2>/dev/null || continue
    t=$(fm "$f" title); [ -n "$t" ] && emit X "$f" "$t"
  done
  # 4) [M] Mistakes from this project's past sessions (repeat prevention) — one candidate per `#### Mistake` block:
  find "$VAULT/sessions" -maxdepth 1 -name "*.md" ! -name "index.md" 2>/dev/null | while read -r f; do
    grep -q '^session_type: dreaming' "$f" && continue   # dreaming reports are not work sessions (prevents recall pollution)
    grep -q "^project: <project>" "$f" || continue
    u=$(ymd "$(fm "$f" updated)")
    awk '/^#### Mistake/{ if(b!="")print b; b=""; c=1; h=$0; sub(/^####[ \t]*/,"",h); b=h; next }
         /^##/{ if(b!=""){print b; b=""} c=0; next }   # any ##/###/#### heading ends the block — bare /^####/ let a trailing Mistake swallow the next ### date entry / ## section (KJP-9)
         c&&NF{ s=$0; gsub(/^[ \t]+|[ \t]+$/,"",s); b=(b==""?s:b" "s) }
         END{ if(b!="")print b }' "$f" | while IFS= read -r m; do
      [ -n "$m" ] && printf 'M\t5\t0\t0\t%s\t%s\t%s\t%s\n' "$u" "$f" "$m" "$m"   # [M] = top section axis: sec=5
    done
  done
} | awk -F '\t' -v goal="$GOAL" '
    # --- deterministic weighted-sum ranker (ticket KJP-4 · cognee DeterministicRanker mapping) · integer arithmetic ---
    BEGIN{
      g=tolower(goal); gsub(/[^a-z0-9]+/," ",g); ng=split(g,ga," ")
      for(i=1;i<=ng;i++) if(length(ga[i])>=2) gset[ga[i]]=1               # goal token set (drop 1-char noise)
      G=0; for(k in gset) G++
    }
    {
      src=$1; sec=$2+0; conf=$3+0; prio=$4+0; upd=$5+0; path=$6; label=$7; otext=$8
      sec_n = sec*20                                                      # W_SECTION axis, normalized 20..100
      c=conf; if(c>10)c=10; conf_n=c*10                                   # W_CONFIDENCE (useful feedback counter, cap 10) 0..100
      p=prio; if(p>5)p=5;   prio_n=p*20                                   # W_PRIORITY (cap 5) 0..100
      t=tolower(otext); gsub(/[^a-z0-9]+/," ",t); nt=split(t,ta," ")
      delete seen; ov=0
      for(i=1;i<=nt;i++){ w=ta[i]; if(length(w)>=2 && (w in gset) && !(w in seen)){ seen[w]=1; ov++ } }
      ovl_n = (G>0)? int(ov*100/G) : 0                                    # W_OVERLAP (goal↔title/Trigger token overlap ratio) 0..100
      score = 10*sec_n + 5*conf_n + 4*ovl_n + 1*prio_n                    # weighted sum 10·S+5·C+4·O+1·P  (range 0..2000)
      key   = score*100000000 + upd                                      # W_RECENCY 0.5 → updated as strict low-order tiebreaker (score·1e8 dominates upd<1e8)
      if(src=="M"){ n=split(path,pp,"/"); disp=sprintf("M  %s: %s", pp[n], label) }
      else        { disp=sprintf("%s  %s  —  %s", src, label, path) }
      printf "%015.0f\t%s\n", key, disp
    }
' | sort -k1,1nr | head -n "$RECALL_N" | cut -f2-
```

## ranker — deterministic weighted sum + cap N
The pipeline scores every candidate with a fixed integer weighted sum, sorts descending, and injects only the top **N** (`RECALL_N`, **default 8** — the old "5–8" upper bound, now enforced by code instead of eyeballed). Same `(candidate, goal)` ⇒ same order: no randomness, no wall-clock (recency reads each note's `updated:`, never `now`).

| Weight | Term (normalized 0–100) | Computation | Source |
|---|---|---|---|
| **W_SECTION 10** | section axis | `sec*20` — M=5 · C-policies=4 · C-facts/patterns/999_tools=3 · K=2 · X=1, then ±1 by `type:` (gotcha/decision > lesson > reference), clamped 1..5 | source prefix + `type:` |
| **W_CONFIDENCE 5** | net-help feedback | `min(useful,10)*10` — the `useful:` feedback counter (sessions that actually used the note; bumped by `sh`/`sc`, canon `docs/knowledge-convention.md` §Feedback counters — KJP-7); field absent (pre-KJP-7 note) = 0 | `useful:` |
| **W_OVERLAP 4** | goal overlap | `overlap_count*100/goal_tokens` — distinct goal tokens (≥2 chars) present in title+Trigger | `$GOAL` ↔ `title:`/`## Trigger` |
| **W_PRIORITY 1** | priority | `min(prio,5)*20` — if present; else 0 | `priority:` |
| **W_RECENCY 0.5** | recency | `updated` (YYYYMMDD) — **tiebreaker only**: the low-order digits of the sort key, so it can never overturn a score difference | `updated:` |

- `score = 10·sec_n + 5·conf_n + 4·ovl_n + 1·prio_n` (range 0–2000) · `sort key = score·1e8 + updated`.
- `score·1e8` strictly dominates `updated` (< 1e8), so recency decides **only** on an exact score tie — realizing "W_RECENCY 0.5 · 타이브레이커 전용".
- The weights are the ticket's cognee-DeterministicRanker mapping (S 10 / C 5 / O 4 / P 1 / recency 0.5), scaled to integers so bash/awk needs no floating point.

## 1-hop related expansion
From the **ranked top-N** above (A), you may add each note's `related:` neighbors (B) as secondary context: `grep -h '^related:' "<note.md>"`. **1 hop only** (neighbors-of-neighbors = 2+ hops is forbidden — signal dilution and token blowup). Neighbors are enrichment, not re-ranked, and **share the N budget** (they do not push the total past N).

## Injection
The ranker's **top-N** (default 8) **is** the recall set — no manual re-picking, no re-ordering. Emit each item on its own line with its **source path** (reduces memory hallucination and staleness); the ranker already puts direct goal matches and Mistakes (M) up top. If the ranked set is empty, quietly move on with "no relevant accumulated memory (fresh vault)".
- **On a policies (C) conflict**: `common/policies/` is the normative axis — when it contradicts facts or patterns, **policies wins** (`docs/project-docs-convention.md` §Document Conflict Precedence). If you spot a contradiction, do not silently pick one — call it out in the recall block.
- **New session (`ss`)**: add as a recall block to `## Context`. **This block doubles as the session's canonical injected-notes record** (each line already carries its source path — no separate list is kept): `sh`/`sc` read it to bump the injected notes' `recalled:`/`useful:` feedback counters (canon: `docs/knowledge-convention.md` §Feedback counters).
- **Resume (`sr`)**: present recall **together with** the resume summary (live context priming). Do not overwrite the session note's `## Context`. (Feedback counters count injection **once per session** — the resume re-presentation is screen-only and extends neither the injected-notes record nor any counter.)
> Marker: `<!-- recall: recall.md · K+common(facts/patterns/policies)+tools(999_tools)+cross+Mistake · deterministic weighted-sum ranker (S10/C5/O4/P1/rec0.5 · C=useful feedback) · top-N cap · 1-hop related · source paths · Context block = injected-notes record · graphify first -->`
