# Publishing Nodeclaw-Helper

This subtree is the in-platform publication basis for the public `Nodeclaw-Helper` distribution repo.

## Source authority

Do all functional script work in:
- `/home/node/workplace/AWCLOUD/CLAUDE/NodeClaw-platform/script/`

Do not treat the public GitHub repo as the primary authoring location for helper behavior.

## Publish flow

1. Edit and verify scripts in `NodeClaw-platform/script/`.
2. Copy the checked script tree into `NodeClaw-platform/script/Nodeclaw-Helper/script/`.
3. Update `script/manifest.json` with the source commit and mirrored file metadata.
4. Update `README.md`, `script/index.html`, and `script/manifest.json` only if the public usage/support contract changed.
5. Sync this subtree into the public `Nodeclaw-Helper` GitHub repository.
6. Verify:
   - `https://darkwingtm.github.io/Nodeclaw-Helper/`
   - helper files published from the `script/` directory

## Current Pages model

- GitHub Pages is deployed by GitHub Actions
- the deployment artifact is `./script`
- `script/index.html` is the intended homepage
- helper files in `script/` are published directly at the site root

## Boundary notes

- Do not imply that hosted `curl | bash` is officially live unless the helper contract is redesigned for that purpose.
- Treat launcher entrypoints like `launcher.sh` and `launcher.ps1` as repo-folder entrypoints, not guaranteed standalone single-file remote installers.
- Keep PowerShell wording honest: scaffold-first and dry-run-only.
