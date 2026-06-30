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
- `hermes`
- `openclaw`
- `opencode`
- `zed`

## Main entrypoints

Shell launcher:

```bash
bash ./script/launcher.sh help
bash ./script/launcher.sh list
bash ./script/launcher.sh dry-run --tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed> --route-mode <direct|cloudflare>
bash ./script/launcher.sh apply --tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed> --route-mode <direct|cloudflare>
bash ./script/launcher.sh wizard [--tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed>] [--route-mode <direct|cloudflare>]
```

Remote launcher-first usage:

Direct-native examples first:

```bash
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- wizard
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool claude-code
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool codex
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool zed
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool openclaw
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool gemini-cli
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool opencode
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool hermes
```

Optional Cloudflare-protected launcher examples:

```bash
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- wizard --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool claude-code --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool codex --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool zed --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool openclaw --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool gemini-cli --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool opencode --route-mode cloudflare
curl -fsSL https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.sh | bash -s -- dry-run --tool hermes --route-mode cloudflare
```

`gemini-cli` can now use the Cloudflare-protected launcher path through the protected Google / Gemini `v1beta` family when you explicitly opt into Cloudflare mode.

PowerShell launcher:

```powershell
.\script\launcher.ps1 -Command help
.\script\launcher.ps1 -Command list
.\script\launcher.ps1 -Command dry-run -Tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed> -RouteMode <direct|cloudflare>
.\script\launcher.ps1 -Command wizard -Tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed> -RouteMode <direct|cloudflare>
```

Remote PowerShell launcher:

Direct-native examples first:

```powershell
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='claude-code'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='codex'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='zed'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='openclaw'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='gemini-cli'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='opencode'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='hermes'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
```

Optional Cloudflare-protected launcher examples:

```powershell
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='claude-code'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='codex'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='zed'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='openclaw'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='gemini-cli'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='opencode'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
powershell -ExecutionPolicy Bypass -c "$env:NODECLAW_LAUNCHER_COMMAND='wizard'; $env:NODECLAW_LAUNCHER_TOOL='hermes'; $env:NODECLAW_LAUNCHER_ROUTE_MODE='cloudflare'; $launcherText = irm https://darkwingtm.github.io/Nodeclaw-Helper/script/launcher.ps1; & ([scriptblock]::Create($launcherText))"
```

`gemini-cli` can now use the Cloudflare-protected launcher path through the protected Google / Gemini `v1beta` family when you explicitly opt into Cloudflare mode.

## Claude Code CLI setup posture

`claude-code` uses an env-first helper path through the checked `ANTHROPIC_*` environment contract.

Quick start:

```bash
export ANTHROPIC_BASE_URL="https://payg.nodenetwork.ovh"
export ANTHROPIC_AUTH_TOKEN="<nodeclaw_access_key>"
export ANTHROPIC_MODEL="gemini-3.1-flash"
claude --model gemini-3.1-flash
```

Optional compatibility fallbacks when the gateway rejects Anthropic beta headers/features:

```bash
export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
export DISABLE_INTERLEAVED_THINKING=1
```

Optional Cloudflare-protected helper posture for the same Claude contract:

```bash
export ANTHROPIC_BASE_URL="https://gateway.ai.cloudflare.com/v1/06b7333b2c174700306d7f931d809765/nodenetwork-nodeclaw-payg/custom-nodenetwork/"
export ANTHROPIC_AUTH_TOKEN="<nodeclaw_access_key>"
claude
```

Config file paths proved from the official Claude Code settings docs:
- Linux / macOS user settings: `~/.claude/settings.json`
- Windows user settings: `%USERPROFILE%\.claude\settings.json`
- Project shared settings: `.claude/settings.json`
- Project local settings: `.claude/settings.local.json`

What the helper manages:
- `~/.claude/settings.json` generation/update on Linux / macOS shell helper runs
- the same `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN` env contract under the Claude Code `env` object
- helper-guided dry-run/apply flow for that same env-based setup

Verify / troubleshoot:
- launch `claude` only after both env vars are active in the same shell that starts Claude Code
- if the first request fails immediately, verify the target still exposes `/v1/messages` and `/v1/messages/count_tokens`
- if `ANTHROPIC_BASE_URL` points to a non-first-party host, Claude Code MCP tool search remains disabled unless that proxy forwards `tool_reference` blocks correctly

Important boundary:
- Claude helper writes the checked Claude Code settings file instead of only printing a profile snippet
- direct/native Claude Code must use the service root `https://payg.nodenetwork.ovh` in `ANTHROPIC_BASE_URL` rather than appending `/v1`
- shell helper can apply the settings path directly
- PowerShell launcher is route-mode-aware and preview-first in the current checked scope; direct PowerShell helpers remain the apply surface where that helper supports file writes or env/session output

## Gemini CLI setup posture

`gemini-cli` now uses an env-first custom-endpoint helper path.

Primary setup contract:

```bash
export GOOGLE_GEMINI_BASE_URL="https://payg.nodenetwork.ovh"
export GEMINI_API_KEY="<nodeclaw_access_key>"
gemini
```

Optional Cloudflare-protected helper posture for the same Gemini contract:

```bash
export GOOGLE_GEMINI_BASE_URL="https://gateway.ai.cloudflare.com/v1/06b7333b2c174700306d7f931d809765/nodenetwork-nodeclaw-payg/custom-nodenetwork/v1beta"
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
- PowerShell launcher stays preview-first, while the direct Gemini PowerShell helper can still write the managed env/profile files

## Hermes helper path

`hermes` now has a dedicated helper-guided profile path for the NodeClaw custom endpoint.

Primary helper contract:

```bash
export HERMES_NODECLAW_API_KEY="<nodeclaw_access_key>"
export HERMES_NODECLAW_BASE_URL="https://payg.nodenetwork.ovh/v1"
bash ./script/setup-hermes-nodeclaw.sh --dry-run
bash ./script/setup-hermes-nodeclaw.sh
```

Optional Cloudflare-protected helper posture for the same Hermes profile-local contract:

```bash
export HERMES_NODECLAW_API_KEY="<nodeclaw_access_key>"
export HERMES_NODECLAW_BASE_URL="https://gateway.ai.cloudflare.com/v1/06b7333b2c174700306d7f931d809765/nodenetwork-nodeclaw-payg/custom-nodenetwork/"
bash ./script/setup-hermes-nodeclaw.sh --dry-run
bash ./script/setup-hermes-nodeclaw.sh
```

What the helper manages:
- one dedicated Hermes profile such as `~/.hermes/profiles/nodeclaw-hermes`
- profile-local `.env`
- profile-local `config.yaml`
- profile-local `SOUL.md`
- optional clone-based bootstrap from another Hermes profile before the NodeClaw-specific files are rewritten

Important boundary:
- the helper assumes Hermes profiles are separate Hermes home directories
- the first-wave helper target is still inventory-first and does not by itself promote Hermes into Home or the main `/docs` onboarding flow
- PowerShell launcher stays preview-first, but the direct Hermes PowerShell helper can write the profile-local files now
- this release wave does not claim that Hermes has been installed or live-tested against a real target service yet; the current proof boundary is docs-first + helper-payload accuracy

## Direct per-tool helpers

Linux / macOS shell helpers:
- `script/setup-claude-code-nodeclaw.sh`
- `script/setup-gemini-cli-nodeclaw.sh`
- `script/setup-codex-nodeclaw.sh`
- `script/setup-hermes-nodeclaw.sh`
- `script/setup-openclaw-nodeclaw.sh`
- `script/setup-opencode-nodeclaw.sh`
- `script/setup-zed-nodeclaw.sh`

Windows PowerShell helpers:
- `script/setup-claude-code-nodeclaw.ps1`
- `script/setup-gemini-cli-nodeclaw.ps1`
- `script/setup-codex-nodeclaw.ps1`
- `script/setup-hermes-nodeclaw.ps1`
- `script/setup-openclaw-nodeclaw.ps1`
- `script/setup-opencode-nodeclaw.ps1`
- `script/setup-zed-nodeclaw.ps1`

## Current support boundary

- Launcher remains the generic entrypoint.
- Route mode defaults to `direct`, while `cloudflare` is explicit opt-in at the launcher surface.
- Checked Cloudflare-capable targets are `claude-code`, `codex`, `zed`, `opencode`, `hermes`, and `gemini-cli`; `openclaw` can use Cloudflare only when `NODECLAW_COMPATIBILITY` is `openai` or `anthropic`.
- `gemini-cli` now uses the protected Google / Gemini `v1beta` family when `--route-mode cloudflare` is requested, while direct mode keeps the native Gemini root.
- `opencode` and `hermes` keep the same custom-provider-root contract in both modes; launcher only swaps which root/base gets injected.
- Shell helper paths can apply changes where the checked script supports it.
- PowerShell launcher paths are route-mode-aware and preview-first; direct PowerShell helpers remain the apply surface where that helper supports file writes or env/session output.
- Gemini helper support is env/snippet/profile oriented, not file-mutation-first like some other tools.
- Hermes helper support is profile-local and writes `.env` / `config.yaml` / `SOUL.md` for one dedicated Hermes home/profile path.
- `openclaw` still requires the local `openclaw` command to already exist in `PATH`.
- `hermes` helper needs the local `hermes` command when apply mode is used for real profile creation outside a custom-home-only write path.
- Default checked OpenAI-compatible helper base in several tools is `https://payg.nodenetwork.ovh/v1`.
- Gemini helper examples use the service root `https://payg.nodenetwork.ovh`, while the effective Google / Gemini-shaped route family still resolves under `v1beta`.
- Default checked model used in several helpers remains `gpt-5.4` unless the target tool expects another provider-native model id.
- Checked local smoke coverage now verifies launcher route-mode behavior plus setup-script dry-run contracts in scope; this is not live provider, deploy, or hosted Pages proof.

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
