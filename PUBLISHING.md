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
4. Refresh local verification notes when the checked contract changes:
   - focused launcher route-mode coverage
   - focused setup-script dry-run smoke coverage
   - install-mode contract coverage
   - missing-API-key interactive / placeholder-preview coverage
   - PowerShell bootstrap compatibility coverage
   - shell syntax checks (`bash -n`)
   - PowerShell parse checks
5. Sync this subtree into the public `Nodeclaw-Helper` GitHub repository.
6. Verify:
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

Current checked UX rule:
- the helper should reduce user work, not add extra follow-up steps
- wizard is the main first-use path
- env-first is the default where supported
- persistent config/file writes are explicit-only choices
- advanced flags remain available for automation/operator use, not as the main public onboarding surface
- the remote contract should call launcher only; launcher may fetch the helper payload it needs automatically
- hosted launcher examples are live/promoted, but local verification still is not hosted deploy/provider proof

## Boundary notes

- Do not present local verification as hosted deploy/provider proof, even though the hosted launcher examples are already the promoted public entrypoint.
- Treat repo-local `launcher.sh` and `launcher.ps1` as normal in-repo entrypoints, but treat the remote contract as launcher-only: the remote launcher should fetch the helper payload it needs automatically.
- Keep wizard/help honest about target files and real command behavior.
- Keep PowerShell launcher wording honest: route-mode-aware and preview-first, without implying launcher apply parity or full Windows end-to-end proof; direct PowerShell helpers may still expose real apply paths where the checked helper supports file writes or env/session output.
