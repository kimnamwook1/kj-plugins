# Changelog

## 0.1.1 — 2026-07-16

### Changed
- **ss resume: whole-file Read → awk section extract.** Resume injected the entire session file (worst case 94,948 B ≈ 31.6k tokens); it now extracts only `## Goal` + `## To-Do-List` + the newest Progress entry. Measured across 8 active sessions: 222,979 → 58,202 B (−74%).
- **Sessions split from the team share scope.** The shared surface is project trees (`NNN_*/`) + `000_common/`; `sessions/` is a gitignored personal episodic log. Shared notes reference sessions as plain uid text — never `[[wikilink]]` (dangles in teammates' vaults):
  - `versioning-convention`: new **Share scope** bullet (git canon)
  - `knowledge-convention`: wikilink ban noted on `source_sessions`
  - `knowledge-promotion`: `0.rejected.md` format `[[uid]]` → plain uid
  - `vault-tree`: `sessions/` annotated local-only

## 0.1.0 — 2026-07-16

- Initial release: session lifecycle skills (`ss`/`sh`/`sc`), `init`/`onboard`, `dreaming`, worker/coder/verifier agent profiles, vault conventions (`docs/`), recall + knowledge promotion procedures.
