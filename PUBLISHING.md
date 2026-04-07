# Publishing Nodeclaw-Helper

This subtree is the in-platform publication basis for the public `Nodeclaw-Helper` distribution repo.

## Source authority

Do all functional script work in:
- `/home/node/workplace/AWCLOUD/CLAUDE/NodeClaw-platform/script/`

Do not treat the public GitHub repo as the primary authoring location for helper behavior.

## Publish flow

1. Edit and verify scripts in `NodeClaw-platform/script/`.
2. Copy the checked script payload into `NodeClaw-platform/script/Nodeclaw-Helper/script/`.
3. Update root release files when needed:
   - `README.md`
   - `index.html`
   - `manifest.json`
   - `PUBLISHING.md`
4. Sync this subtree into the public `Nodeclaw-Helper` GitHub repository.
5. Verify:
   - `https://darkwingtm.github.io/Nodeclaw-Helper/`
   - helper files under `/script/`
   - launcher-first guidance and current hosted-contract wording

## Current Pages model

- GitHub Pages is deployed by GitHub Actions
- the deployment artifact is `./`
- `index.html` is the intended homepage
- `manifest.json` lives at the repository root
- helper payload files remain under `script/`

## Hosted quick-start contract

Current checked truth:
- launcher-first repo/distribution usage is real today
- the site can expose launcher help, wizard guidance, and direct helper downloads
- hosted remote `curl | bash` wording remains placeholder-scoped only

Current not-yet-proven truth:
- a single-file hosted launcher/bootstrap contract is not yet verified strongly enough to be promoted as a live hero quick-start path on Home and `/docs`

## Boundary notes

- Do not imply that hosted `curl | bash` is officially live unless the hosted launcher/bootstrap contract is truly verified.
- Treat `launcher.sh` and `launcher.ps1` as repo-folder entrypoints that still rely on sibling files in `script/`.
- Keep wizard/help honest about target files and real command behavior.
- Keep PowerShell wording honest: scaffold-first and dry-run-only.
