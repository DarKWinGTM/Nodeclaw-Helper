param(
    [string]$CodexConfigPath = $(if ($env:CODEX_CONFIG_PATH) { $env:CODEX_CONFIG_PATH } else { Join-Path $HOME '.codex/config.toml' }),
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawProviderId = $(if ($env:NODECLAW_PROVIDER_ID) { $env:NODECLAW_PROVIDER_ID } else { 'nodeclaw' }),
    [ValidateSet('simple', 'custom-provider')]
    [string]$CodexProviderMode = $(if ($env:CODEX_PROVIDER_MODE) { $env:CODEX_PROVIDER_MODE } else { 'simple' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ConfigPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($CodexConfigPath.Replace('~', $HOME)))

$Rendered = if ($CodexProviderMode -eq 'simple') {
@"
model = "$NodeClawModelId"
openai_base_url = "$NodeClawBaseUrl"
"@
} else {
@"
model = "$NodeClawModelId"
model_provider = "$NodeClawProviderId"

[model_providers.$NodeClawProviderId]
name = "NodeClaw"
base_url = "$NodeClawBaseUrl"
env_key = "OPENAI_API_KEY"
wire_api = "responses"
"@
}

Write-Host "Target Codex config: $ConfigPath"
Write-Host "Provider mode: $CodexProviderMode"
Write-Host "Base URL: $NodeClawBaseUrl"
Write-Host "Model: $NodeClawModelId"
Write-Host 'Auth env: OPENAI_API_KEY'

if ($DryRun) {
    Write-Host "`nDry run only. Planned Codex config:`n"
    Write-Host $Rendered.TrimEnd()
    Write-Host "`nWindows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification."
    exit 0
}

Write-Error 'Windows execution is intentionally not enabled yet. Use -DryRun for now until a real Windows environment is available for validation.'
