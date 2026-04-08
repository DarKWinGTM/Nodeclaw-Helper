# Nodeclaw-Helper

Public helper distribution for NodeClaw integrations.

This release surface exists so users can access the checked helper scripts more directly, while the broader product/docs surface is part of the main `https://nodenetwork.ovh` domain.

The broader product/docs surface is part of the main domain basis:
- `https://nodenetwork.ovh`
- `https://nodenetwork.ovh/docs`
- `https://nodenetwork.ovh/docs/tools`

## What this release is for

Use this release when you want:
- the launcher-first helper entrypoints
- one remote launcher entrypoint that can fetch the helper payload automatically
- direct per-tool helper scripts when you need an explicit tool-specific path
- a lightweight public distribution surface separate from the larger app repo experience

## Supported tools

Helper-capable targets:
- `claude-code`
- `codex`
- `openclaw`
- `opencode`
- `zed`

Additional bounded public target:
- `gemini-cli` — manual-first / gateway-capable only in the checked scope; do not read this as a launcher-helper target

## Main entrypoints

Shell launcher:

```bash
bash ./script/launcher.sh help
bash ./script/launcher.sh list
bash ./script/launcher.sh dry-run --tool <claude-code|codex|openclaw|opencode|zed>
bash ./script/launcher.sh apply --tool <claude-code|codex|openclaw|opencode|zed>
bash ./script/launcher.sh wizard
```

Remote launcher-first usage:

```bash
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- wizard
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool <claude-code|codex|openclaw|opencode|zed>
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- apply --tool <claude-code|codex|openclaw|opencode|zed>
```

Bounded Gemini CLI note:

```text
Gemini CLI is visible in the broader public tool set, but its checked current posture is manual-first / gateway-capable.
Use the official Gemini CLI install path first, then wire NodeClaw through ACP gateway metadata instead of expecting launcher-helper automation here.
```

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1 | iex"
```

PowerShell launcher:

```powershell
.\script\launcher.ps1 -Command help
.\script\launcher.ps1 -Command list
.\script\launcher.ps1 -Command dry-run -Tool <claude-code|codex|openclaw|opencode|zed>
.\script\launcher.ps1 -Command wizard
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

Tool-specific scripts remain available when a direct tool path is clearer than the generic launcher.

### Linux / macOS shell helpers

These `.sh` helpers are the direct shell-side tool-specific entrypoints.

- `script/setup-claude-code-nodeclaw.sh`
- `script/setup-codex-nodeclaw.sh`
- `script/setup-openclaw-nodeclaw.sh`
- `script/setup-opencode-nodeclaw.sh`
- `script/setup-zed-nodeclaw.sh`

### Windows PowerShell helpers

These `.ps1` helpers are the direct PowerShell-side tool-specific entrypoints.
Current checked boundary: PowerShell remains scaffold-first and dry-run-only.

- `script/setup-claude-code-nodeclaw.ps1`
- `script/setup-codex-nodeclaw.ps1`
- `script/setup-openclaw-nodeclaw.ps1`
- `script/setup-opencode-nodeclaw.ps1`
- `script/setup-zed-nodeclaw.ps1`

### Platform note

- Linux and macOS share the same shell helper files.
- Windows uses the PowerShell helper files.
- If you want one generic cross-tool entrypoint, use `launcher.sh` or `launcher.ps1` instead.

## Current support boundary

- Shell helper paths can apply changes where the checked script supports it.
- PowerShell helper paths remain scaffold-first and dry-run-only.
- Launcher help and wizard are now available, but they still reveal the real command flow and do not replace dry-run-first visibility.
- Hosted remote install flow is not declared as fully live here yet.
- `openclaw` helper requires the `openclaw` command to already exist in `PATH`.
- `gemini-cli` is not a helper-capable target in this release surface; its checked current fit is manual-first / gateway-capable only.
- Default checked NodeClaw base URL in several helpers is `https://payg.nodenetwork.ovh/v1`.
- The checked public Google / Gemini-shaped lane uses `https://payg.nodenetwork.ovh/v1beta`.
- Default checked model used in several helpers is `gpt-5.4`.

## Recommended usage order

1. Start from the main NodeClaw docs/product surface when you want the full context.
2. Run `launcher.sh help` or `launcher.ps1 -Command help` first if you are unsure.
3. Use `launcher.sh` or `launcher.ps1` as the generic helper entrypoint.
4. Run `dry-run` first.
5. Use `wizard` when you want a guided setup flow that still shows the real command and target file.
6. Use direct per-tool scripts only when you want a more explicit tool-specific entrypoint.

## Related release files

- `index.html`
- `manifest.json`
- `PUBLISHING.md`
