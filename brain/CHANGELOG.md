# Changelog

## Unreleased

### Changed
- **`common/policies/` re-defined by binding force + scope, not origin (KJP-15).** The tier was described as *external* mandates — laws, regulations, certifications. It is now any norm that **binds every project in the vault**, origin-agnostic: an external mandate **or** a self-imposed org-wide invariant, gated on must vs. advice/technique. Touches `knowledge-convention` (3-axis table Content/Origin cells), `knowledge-escalate-convention` (§common/policies diagram + bullet), and `knowledge-promotion` (the obligation test in Step 2 and the sole-exception note in Step 1). The `Binding force = yes (no project exceptions)` cell was already on this axis and is unchanged.
- **ADR counterexample re-premised (KJP-15).** The "don't bundle decisions that may diverge per project" warning stands, but its test is now *whether an exception can arise inside this vault*, not *whether the org differs*. Consequently git branch strategy does **not** diverge in a single-org vault and stays in `common/policies/`; it would split per project only across distinct orgs sharing one vault.
- **Session commit is a per-vault choice, not a fixed gitignore (KJP-15).** The earlier session share-scope split stands — `sessions/` sits outside the team-shared surface; what changes is the premise that a gitignore was its *sole* implementation. The gitignore is now framed as the team-vault implementation only — a solo vault may track sessions (the commit doubles as backup). The plain-uid (never `[[wikilink]]`) rule for shared notes is unchanged, re-grounded on "a session may be absent from the shared surface." Touches `versioning-convention` §Share scope, `knowledge-promotion` reject-log clause, `knowledge-convention` `source_sessions` comment.
- **`ss` project-resolution wording tightened (KJP-15).** Step 2 said "infer from cwd"; it now reads "config `project:` first, then cwd", matching `project-inference.md` §Priority (config outranks cwd). Behavior unchanged — wording only.

### Added
- **`update-over-create` names its tooling in canon (KJP-15).** `knowledge-convention` now states edit-existing-with-`Edit` / `Write`-only-for-new at the canon layer, so the scribe procedure's tool rule (`knowledge-promotion`) reads as canon-derived rather than a lone skill-level instruction.

## 0.1.2 — 2026-07-18

### Added
- **`scripts/validate.sh` — schema checker (KJP-1).** Was: zero mechanical validation, every rule enforced by documentation discipline alone. Checks session uid shape + uid/filename agreement, the 3-value `status` vocabulary, required frontmatter keys, knowledge-note `title:`, and doc-status values leaking into sessions. Reports `file:line`, warns by default, `--strict` exits 1. bash 3.2, no dependencies beyond `awk`/`find` and coreutils. `scripts/validate-selftest.sh` covers it with 39 assertions; the suite is mutation-tested (16/16 mutants killed) because a passing assertion is not evidence that it can fail.
- **Human sign-off gate for `common/policies/` (KJP-2).** The normative axis — top of Document Conflict Precedence — no longer gets written by an agent. Candidates land on their normal tier and return as a `common-policy candidates` list, presented as one batch at `sh`/`sc`/dreaming §7. Agents draft; the user signs. Per-item interrupts are forbidden, and every other tier keeps the automatic score gate unchanged.
- **Third-time test (KJP-3).** dreaming §3's reject-log recurrence scan now states the rule it was implying: two occurrences make the third a rule. Detection and proposal only.

### Changed
- **`dreaming` §5 `project-policy candidates` renamed.** Both axes (org-wide `common/policies/` and per-project `docs/policy/`) surface approval-pending candidates in `## For PM` under near-identical wording — a signer could approve a project policy as an org-wide one. The two lists are now named apart and must never be merged.
- **`knowledge-promotion.md` reject-log clause** points at dreaming §3 as canon instead of describing the scan, which had made this file read as the spec.

### Notes
- Session `#### Mistake` recurrence was evaluated for inclusion in the third-time test and **deferred, not dropped**. The blind spot is real — a Mistake never mirrored into `Learned` escapes both the score gate and the reject-log — but sessions are an incremental scope and are records that carry no handled-marker, so recurrence there can neither be counted nor closed out. Record-format work has to land first (KJP-9). The reasoning is recorded in dreaming §3 so it is not rediscovered and re-attempted.

### Changed
- **ss resume: whole-file Read → awk section extract.** Resume injected the entire session file (worst case 94,948 B ≈ 31.6k tokens); it now extracts only `## Goal` + `## To-Do-List` + the newest Progress entry. Measured across 8 active sessions: 222,979 → 58,202 B (−74%).
- **Sessions split from the team share scope.** The shared surface is project trees (`NNN_*/`) + `000_common/`; `sessions/` is a gitignored personal episodic log. Shared notes reference sessions as plain uid text — never `[[wikilink]]` (dangles in teammates' vaults):
  - `versioning-convention`: new **Share scope** bullet (git canon)
  - `knowledge-convention`: wikilink ban noted on `source_sessions`
  - `knowledge-promotion`: `0.rejected.md` format `[[uid]]` → plain uid
  - `vault-tree`: `sessions/` annotated local-only

## 0.1.0 — 2026-07-16

- Initial release: session lifecycle skills (`ss`/`sh`/`sc`), `init`/`onboard`, `dreaming`, worker/coder/verifier agent profiles, vault conventions (`docs/`), recall + knowledge promotion procedures.
