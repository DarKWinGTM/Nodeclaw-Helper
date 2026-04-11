# Nodeclaw-Helper

Public helper distribution for NodeClaw integrations.

This release surface exists so users can access the checked helper scripts more directly, while the broader product/docs surface remains on:
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

Helper-guided targets:
- `claude-code`
- `gemini-cli`
- `codex`
- `openclaw`
- `opencode`
- `zed`

## Main entrypoints

Shell launcher:

```bash
bash ./script/launcher.sh help
bash ./script/launcher.sh list
bash ./script/launcher.sh dry-run --tool <claude-code|gemini-cli|codex|openclaw|opencode|zed>
bash ./script/launcher.sh apply --tool <claude-code|gemini-cli|codex|openclaw|opencode|zed>
bash ./script/launcher.sh wizard
```

Remote launcher-first usage:

```bash
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- wizard
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool gemini-cli
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- apply --tool gemini-cli
```

PowerShell launcher:

```powershell
.\script\launcher.ps1 -Command help
.\script\launcher.ps1 -Command list
.\script\launcher.ps1 -Command dry-run -Tool <claude-code|gemini-cli|codex|openclaw|opencode|zed>
.\script\launcher.ps1 -Command wizard
```

Remote PowerShell launcher:

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1 | iex"
```

## Gemini CLI setup posture

`gemini-cli` now uses an env-first custom-endpoint helper path.

Primary setup contract:

```bash
export GOOGLE_GEMINI_BASE_URL="https://payg.nodenetwork.ovh"
export GEMINI_API_KEY="<nodeclaw_access_key>"
gemini
```

What the helper manages:
- shell/PowerShell env snippet generation
- profile source block generation
- helper-guided preview/apply flow for that same env-based setup

Important boundary:
- effective Google / Gemini-shaped route family still resolves under `v1beta`
- the helper does **not** use ACP as the setup story anymore
- shell helper can apply the managed env/profile path
- PowerShell launcher remains dry-run-first, but the direct Gemini PowerShell helper can write the managed env/profile files

## Direct per-tool helpers

Linux / macOS shell helpers:
- `script/setup-claude-code-nodeclaw.sh`
- `script/setup-gemini-cli-nodeclaw.sh`
- `script/setup-codex-nodeclaw.sh`
- `script/setup-openclaw-nodeclaw.sh`
- `script/setup-opencode-nodeclaw.sh`
- `script/setup-zed-nodeclaw.sh`

Windows PowerShell helpers:
- `script/setup-claude-code-nodeclaw.ps1`
- `script/setup-gemini-cli-nodeclaw.ps1`
- `script/setup-codex-nodeclaw.ps1`
- `script/setup-openclaw-nodeclaw.ps1`
- `script/setup-opencode-nodeclaw.ps1`
- `script/setup-zed-nodeclaw.ps1`

## Current support boundary

- Launcher remains the generic entrypoint.
- Shell helper paths can apply changes where the checked script supports it.
- PowerShell launcher paths remain dry-run-first.
- Gemini helper support is env/snippet/profile oriented, not file-mutation-first like some other tools.
- `openclaw` still requires the local `openclaw` command to already exist in `PATH`.
- Default checked OpenAI-compatible helper base in several tools is `https://payg.nodenetwork.ovh/v1`.
- Gemini helper examples use the service root `https://payg.nodenetwork.ovh`, while the effective Google / Gemini-shaped route family still resolves under `v1beta`.
- Default checked model used in several helpers remains `gpt-5.4` unless the target tool expects another provider-native model id.

## Recommended usage order

1. Start from the main NodeClaw docs/product surface when you want the full context.
2. Use `launcher.sh` or `launcher.ps1` as the generic helper entrypoint.
3. Run `dry-run` first.
4. Use `wizard` when you want a guided setup flow that still shows the real command and target output.
5. Use direct per-tool scripts only when you want a more explicit tool-specific entrypoint.

## Related release files

- `index.html`
- `manifest.json`
- `PUBLISHING.md`
