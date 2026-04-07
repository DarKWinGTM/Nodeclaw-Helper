# Publishing Nodeclaw-Helper

This repository is a public distribution mirror for the helper scripts in `NodeClaw-platform/script/`.

## Source authority

Do all functional script work in:
- `/home/node/workplace/AWCLOUD/CLAUDE/NodeClaw-platform/script/`

Do not treat this repository as the primary authoring location for helper behavior.

## Publish flow

1. Edit and verify scripts in `NodeClaw-platform/script/`.
2. Copy the checked script tree into `Nodeclaw-Helper/script/`.
3. Update `script/manifest.json` with the source commit and mirrored file metadata.
4. Update `README.md` and `index.md` only if the public usage/support contract changed.
5. Commit and push `main`.
6. Verify:
   - `https://darkwingtm.github.io/Nodeclaw-Helper/`
   - direct `/script/<file>` URLs

## Current Pages model

- GitHub Pages serves directly from `main:/`
- `index.md` is the intended homepage
- `script/` remains directly downloadable from the published site

## Boundary notes

- Do not imply that hosted `curl | bash` is officially live unless the helper contract is redesigned for that purpose.
- Treat bundle-structured entrypoints like `launcher.sh` and `setup-nodeclaw-ide.*` as repo-folder entrypoints, not guaranteed standalone single-file remote installers.
- Keep PowerShell wording honest: scaffold-first and dry-run-only.
