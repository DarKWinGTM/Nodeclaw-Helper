# Nodeclaw-Helper

Public distribution mirror for the helper scripts that live in `NodeClaw-platform/script/`.

- GitHub Pages release surface: `Nodeclaw-Helper/script/`
- Source authority remains: `NodeClaw-platform/script/`
- `script/` in this repo is mirrored publication content, not the primary authoring location
- The live site is intended to be deployed from the `script/` directory, not the repository root

## Included helpers

- `script/launcher.sh`
- `script/setup-nodeclaw-ide.sh`
- `script/setup-nodeclaw-ide.ps1`
- `script/setup-claude-code-nodeclaw.sh`
- `script/setup-claude-code-nodeclaw.ps1`
- `script/setup-codex-nodeclaw.sh`
- `script/setup-codex-nodeclaw.ps1`
- `script/setup-openclaw-nodeclaw.sh`
- `script/setup-openclaw-nodeclaw.ps1`
- `script/setup-opencode-nodeclaw.sh`
- `script/setup-opencode-nodeclaw.ps1`
- `script/setup-zed-nodeclaw.sh`
- `script/setup-zed-nodeclaw.ps1`

## Supported tools

- `claude-code`
- `codex`
- `openclaw`
- `opencode`
- `zed`

## Main entrypoint

```bash
bash ./script/launcher.sh list
bash ./script/launcher.sh dry-run --tool claude-code
bash ./script/launcher.sh apply --tool claude-code
```

## Wrapper entrypoints

Shell:

```bash
bash ./script/setup-nodeclaw-ide.sh --tool <claude-code|codex|openclaw|opencode|zed> [--dry-run]
```

PowerShell:

```powershell
.\script\setup-nodeclaw-ide.ps1 -Tool <claude-code|codex|openclaw|opencode|zed> [-DryRun]
```

## Current support boundary

- Shell helper paths can apply changes where the checked script supports it.
- PowerShell helper paths are scaffold-first and dry-run-only.
- Hosted remote install flow is not declared here yet. This repo currently exposes repo-local helper usage only.

## Common examples

Claude Code dry-run:

```bash
NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/launcher.sh dry-run --tool claude-code
```

Codex dry-run:

```bash
bash ./script/launcher.sh dry-run --tool codex
```

OpenCode dry-run:

```bash
NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/launcher.sh dry-run --tool opencode
```

Zed dry-run:

```bash
ZED_SETTINGS_PATH="<path-to-zed-settings.json>" bash ./script/launcher.sh dry-run --tool zed
```

## Notes

- Some helpers require prerequisites from the upstream tool itself.
- `openclaw` helper requires the `openclaw` command to already exist in `PATH`.
- Default NodeClaw base URL in the checked scripts is `https://payg.nodenetwork.ovh/v1`.
- Default checked model used in several helpers is `gpt-5.4`.
