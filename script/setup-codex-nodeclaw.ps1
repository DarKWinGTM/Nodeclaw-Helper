param(
    [string]$CodexConfigPath = $(if ($env:CODEX_CONFIG_PATH) { $env:CODEX_CONFIG_PATH } else { Join-Path $HOME '.codex/config.toml' }),
    [string]$NodeClawApiKey = $(if ($env:NODECLAW_API_KEY) { $env:NODECLAW_API_KEY } elseif ($env:OPENAI_API_KEY) { $env:OPENAI_API_KEY } else { '' }),
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawProviderId = $(if ($env:NODECLAW_PROVIDER_ID) { $env:NODECLAW_PROVIDER_ID } else { 'nodeclaw' }),
    [ValidateSet('simple', 'custom-provider')]
    [string]$CodexProviderMode = $(if ($env:CODEX_PROVIDER_MODE) { $env:CODEX_PROVIDER_MODE } else { 'simple' }),
    [ValidateSet('auto', 'env', 'persistent')]
    [string]$NodeClawInstallMode = $(if ($env:NODECLAW_REQUESTED_INSTALL_MODE) { $env:NODECLAW_REQUESTED_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { 'auto' }),
    [string]$NodeClawInteractive = $(if ($env:NODECLAW_INTERACTIVE) { $env:NODECLAW_INTERACTIVE } else { 'auto' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$HelperCapability = 'hybrid'

function Resolve-NodeClawInstallMode {
    param(
        [string]$RequestedInstallMode,
        [string]$Capability
    )

    switch ($RequestedInstallMode) {
        'env' {
            if ($Capability -eq 'persistent-primary') { return 'persistent' }
            return 'env'
        }
        'persistent' { return 'persistent' }
        'auto' { }
        '' { }
        default { throw "Unsupported install mode: $RequestedInstallMode" }
    }

    switch ($Capability) {
        'env-default' { return 'env' }
        'hybrid' { return 'env' }
        'persistent-primary' { return 'persistent' }
        default { return 'persistent' }
    }
}

function Test-NodeClawPromptAllowed {
    $Normalized = if ([string]::IsNullOrWhiteSpace($NodeClawInteractive)) { 'auto' } else { $NodeClawInteractive.Trim().ToLowerInvariant() }

    if ($Normalized -in @('true', '1', 'yes')) { return $true }
    if ($Normalized -in @('false', '0', 'no')) { return $false }
    if ($Normalized -ne 'auto') { throw 'NODECLAW_INTERACTIVE must be auto, true, or false.' }

    try {
        return ((-not [Console]::IsInputRedirected) -and ($null -ne $Host.UI))
    }
    catch {
        return $false
    }
}

function ConvertTo-PowerShellLiteral {
    param([string]$Value)

    return "'" + ($Value -replace "'", "''") + "'"
}

function Write-EnvAssignment {
    param(
        [string]$Name,
        [string]$Value
    )

    Write-Host (('$env:{0}={1}' -f $Name, (ConvertTo-PowerShellLiteral -Value $Value)))
}

function Resolve-NodeClawApiKey {
    if (-not [string]::IsNullOrWhiteSpace($NodeClawApiKey)) { return $NodeClawApiKey }

    if (-not (Test-NodeClawPromptAllowed)) {
        throw 'NODECLAW_API_KEY or OPENAI_API_KEY is required to print an apply-ready Codex auth assignment. Re-run interactively or set NODECLAW_API_KEY first.'
    }

    $PromptedKey = Read-Host 'Enter NodeClaw API key'
    if ([string]::IsNullOrWhiteSpace($PromptedKey)) {
        throw 'NODECLAW_API_KEY cannot be empty.'
    }

    $env:NODECLAW_API_KEY = $PromptedKey
    $env:OPENAI_API_KEY = $PromptedKey
    $env:NODECLAW_PROMPTED_API_KEY = 'true'
    return $PromptedKey
}

function Get-CodexConfigContent {
    if ($CodexProviderMode -eq 'simple') {
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
}

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability
$ConfigPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($CodexConfigPath.Replace('~', $HOME)))
$Rendered = Get-CodexConfigContent

Write-Host 'Target Codex posture: hybrid env auth plus config wiring'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Target Codex config: $ConfigPath"
Write-Host "Provider mode: $CodexProviderMode"
Write-Host "Base URL: $NodeClawBaseUrl"
Write-Host "Model: $NodeClawModelId"
Write-Host 'Auth env: OPENAI_API_KEY'

if ($DryRun) {
    Write-Host 'Preview auth assignment:'
    Write-EnvAssignment -Name 'OPENAI_API_KEY' -Value '<nodeclaw_access_key>'
    Write-Host "`nDry run only. Planned Codex config:`n"
    Write-Host $Rendered.TrimEnd()
    Write-Host "`nDry run only. Re-run without -DryRun to write the Codex config."
    exit 0
}

if ($ResolvedInstallMode -eq 'env') {
    $NodeClawApiKey = Resolve-NodeClawApiKey
    Write-Host 'Session auth assignment:'
    Write-EnvAssignment -Name 'OPENAI_API_KEY' -Value $NodeClawApiKey
}
else {
    Write-Host 'Auth remains env-owned; set OPENAI_API_KEY before running Codex.'
}

$ConfigDirectory = Split-Path -Parent $ConfigPath
if ($ConfigDirectory -and -not (Test-Path $ConfigDirectory)) {
    New-Item -ItemType Directory -Force -Path $ConfigDirectory | Out-Null
}

Set-Content -Path $ConfigPath -Value ($Rendered.TrimEnd() + "`n") -Encoding UTF8
Write-Host "Wrote Codex config to $ConfigPath"
