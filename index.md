# Nodeclaw-Helper

Public GitHub Pages distribution surface for the helper scripts that configure supported tools to use NodeClaw.

## What this is

- A public mirror and download surface for the checked helper scripts.
- A simple landing page for discovering which helper to use.
- A safe starting point before running any helper locally.

## What this is not

- Not the primary development repo.
- Not the governance authority for helper behavior.
- Not a promise that remote `curl | bash` install is officially live.

## Source authority

The authoritative source for these scripts remains:
- `NodeClaw-platform/script/`
- local source path: `/home/node/workplace/AWCLOUD/CLAUDE/NodeClaw-platform/script/`

This repository publishes a mirrored copy for public access.

## Supported tools

- `claude-code`
- `codex`
- `openclaw`
- `opencode`
- `zed`

## Start here

List supported tools:

```bash
bash ./script/launcher.sh list
```

Dry-run first:

```bash
NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/launcher.sh dry-run --tool claude-code
```

## Download helpers

### Standalone tool-specific helpers

These are the cleanest direct download targets because each file owns one tool-specific path.

- [Claude Code shell helper](./script/setup-claude-code-nodeclaw.sh)
- [Claude Code PowerShell helper](./script/setup-claude-code-nodeclaw.ps1)
- [Codex shell helper](./script/setup-codex-nodeclaw.sh)
- [Codex PowerShell helper](./script/setup-codex-nodeclaw.ps1)
- [OpenClaw shell helper](./script/setup-openclaw-nodeclaw.sh)
- [OpenClaw PowerShell helper](./script/setup-openclaw-nodeclaw.ps1)
- [OpenCode shell helper](./script/setup-opencode-nodeclaw.sh)
- [OpenCode PowerShell helper](./script/setup-opencode-nodeclaw.ps1)
- [Zed shell helper](./script/setup-zed-nodeclaw.sh)
- [Zed PowerShell helper](./script/setup-zed-nodeclaw.ps1)

### Bundle-structured entrypoints

These expect the sibling files in `script/` to stay together, so use them from a repo checkout or downloaded script folder.

- [launcher.sh](./script/launcher.sh)
- [setup-nodeclaw-ide.sh](./script/setup-nodeclaw-ide.sh)
- [setup-nodeclaw-ide.ps1](./script/setup-nodeclaw-ide.ps1)

## Current support boundary

- Shell helper paths can apply changes where the checked script supports it.
- PowerShell helper paths remain scaffold-first and dry-run-only.
- Some helpers require upstream prerequisites from the tool itself.
- `openclaw` requires the `openclaw` command to already exist in `PATH`.
- Default checked NodeClaw base URL in several helpers is `https://payg.nodenetwork.ovh/v1`.
- Default checked model in several helpers is `gpt-5.4`.

## Safe usage guidance

- Download or clone the repo first.
- Inspect the script before running it.
- Prefer `--dry-run` before apply mode.
- Pass secrets through environment variables.
- Do not assume every bundle-structured entrypoint is safe as a single-file remote installer.

## Provenance

- [Mirrored script manifest](./script/manifest.json)
- [Publishing notes](./PUBLISHING.md)
- [Repository README](./README.md)
