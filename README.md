# Nodeclaw-Helper

Public helper distribution for NodeClaw integrations.

This release surface exists so users can access the checked helper scripts more directly, while the main product/docs surface still lives under:
- `https://claw-frontend-dev.nodenetwork.ovh`
- `https://claw-frontend-dev.nodenetwork.ovh/docs`
- `https://claw-frontend-dev.nodenetwork.ovh/docs/tools`

## What this release is for

Use this release when you want:
- the launcher-first helper entrypoints
- direct per-tool helper scripts
- a lightweight public distribution surface separate from the larger app repo experience

## Supported tools

- `claude-code`
- `codex`
- `openclaw`
- `opencode`
- `zed`

## Main entrypoints

Shell launcher:

```bash
bash ./script/launcher.sh list
bash ./script/launcher.sh dry-run --tool <claude-code|codex|openclaw|opencode|zed>
bash ./script/launcher.sh apply --tool <claude-code|codex|openclaw|opencode|zed>
```

PowerShell launcher:

```powershell
.\script\launcher.ps1 -Command list
.\script\launcher.ps1 -Command dry-run -Tool <claude-code|codex|openclaw|opencode|zed>
```

## Real terminal example

Launcher tool list:

```text
$ bash ./script/launcher.sh list
Supported tools:
  - claude-code
  - codex
  - openclaw
  - opencode
  - zed
```

Claude Code dry-run through launcher:

```text
$ NODECLAW_API_KEY="test-key" bash ./script/launcher.sh dry-run --tool claude-code
Target Claude Code settings: /tmp/claude-settings-readme.json

Dry run only. Planned Claude Code settings:

{
  "env": {
    "ANTHROPIC_BASE_URL": "https://payg.nodenetwork.ovh/v1",
    "ANTHROPIC_AUTH_TOKEN": "test-key",
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1",
    "DISABLE_INTERLEAVED_THINKING": "1"
  }
}
```

Codex dry-run through launcher:

```text
$ CODEX_CONFIG_PATH="/tmp/codex-readme.toml" bash ./script/launcher.sh dry-run --tool codex
Target Codex config: /tmp/codex-readme.toml
Provider mode: simple
Base URL: https://payg.nodenetwork.ovh/v1
Model: gpt-5.4
Auth env: OPENAI_API_KEY

Dry run only. Planned Codex config:

model = "gpt-5.4"
openai_base_url = "https://payg.nodenetwork.ovh/v1"

[model_providers]
```

## Direct per-tool helpers

Tool-specific shell and PowerShell scripts remain available when a direct tool path is clearer than the generic launcher.

Included helpers:
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

## Current support boundary

- Shell helper paths can apply changes where the checked script supports it.
- PowerShell helper paths remain scaffold-first and dry-run-only.
- Hosted remote install flow is not declared as fully live here yet.
- `openclaw` helper requires the `openclaw` command to already exist in `PATH`.
- Default checked NodeClaw base URL in several helpers is `https://payg.nodenetwork.ovh/v1`.
- Default checked model used in several helpers is `gpt-5.4`.

## Recommended usage order

1. Start from the main NodeClaw docs/product surface when you want the full context.
2. Use `launcher.sh` or `launcher.ps1` as the generic helper entrypoint.
3. Run `dry-run` first.
4. Use direct per-tool scripts only when you want a more explicit tool-specific entrypoint.

## Related release files

- `script/index.html`
- `script/manifest.json`
- `PUBLISHING.md`
