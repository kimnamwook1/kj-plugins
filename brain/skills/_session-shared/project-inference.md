# Reference: Project Inference (shared procedure)

> This document is the **Project Inference** rule shared by `ss` and `sc`. The calling skill reads this document with Read and pins down `<project>` by the rules below. Not executed standalone.

## Vault root — configuration, not inference (a separate axis from project inference)

**The canonical vault root is the vault-root value defined in the project `CLAUDE.local.md`** (recorded by `/brain:init` onboarding. No hardcoding). Guessing the vault root from the `<org>` segment of cwd is **only a fallback for when CLAUDE.local.md has no value** — and if even the fallback fails, do not guess; ask the user.

## Rule (cwd fallback)

**Configuration wins; cwd inference is the fallback** — if the project `CLAUDE.md` brain config has a `project:` value, that is canonical (recorded by `/brain:init`; pre-split projects may still carry it in `CLAUDE.local.md` — read both). Below is the fallback rule for when that value is absent; it assumes the convention that everything under the work root (the top-level folder that collects repos) is layered as `<org>/<project>/<repo>`. The value that goes into `project:` = the **product family**, i.e. the path segment immediately after org:

```
<work-root>/<org>/<project>/<repo>/...
                  ^^^^^^^^^ this is the project
```

Examples (hypothetical):
- cwd `<work-root>/acme/rocket/rocket-server` → project `rocket`
- cwd `<work-root>/acme/anything` → project `anything`

## Priority

1. **If a first argument exists, it is the project override.** (e.g. `ss rocket` or `ss rocket "fix login"` → project `rocket`, the remaining text is the title.) An argument always beats configuration and inference.
2. Without an argument, **the `project:` value in `CLAUDE.md`** (pre-split projects: `CLAUDE.local.md`) — configuration first.
3. Without configuration either, **parse cwd** with the fallback rule above.
4. If inference fails because cwd is not shaped like `<work-root>/<org>/<project>` — **do not guess; ask the user for the project name.**
