param(
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawProviderId = $(if ($env:NODECLAW_PROVIDER_ID) { $env:NODECLAW_PROVIDER_ID } else { 'nodeclaw' }),
    [ValidateSet('openai', 'anthropic')]
    [string]$NodeClawCompatibility = $(if ($env:NODECLAW_COMPATIBILITY) { $env:NODECLAW_COMPATIBILITY } else { 'openai' }),
    [string]$OpenClawGatewayPort = $(if ($env:OPENCLAW_GATEWAY_PORT) { $env:OPENCLAW_GATEWAY_PORT } else { '18789' }),
    [string]$OpenClawGatewayBind = $(if ($env:OPENCLAW_GATEWAY_BIND) { $env:OPENCLAW_GATEWAY_BIND } else { 'loopback' }),
    [ValidateSet('auto', 'env', 'persistent')]
    [string]$NodeClawInstallMode = $(if ($env:NODECLAW_REQUESTED_INSTALL_MODE) { $env:NODECLAW_REQUESTED_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { 'auto' }),
    [string]$NodeClawInteractive = $(if ($env:NODECLAW_INTERACTIVE) { $env:NODECLAW_INTERACTIVE } else { 'auto' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$HelperCapability = 'persistent-primary'

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
        throw 'NODECLAW_API_KEY is required for apply. Re-run interactively or set NODECLAW_API_KEY first.'
    }

    $PromptedKey = Read-Host 'Enter NodeClaw API key'
    if ([string]::IsNullOrWhiteSpace($PromptedKey)) {
        throw 'NODECLAW_API_KEY cannot be empty.'
    }

    $env:NODECLAW_API_KEY = $PromptedKey
    $env:NODECLAW_PROMPTED_API_KEY = 'true'
    return $PromptedKey
}

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability
$PreviewApiKey = '<nodeclaw_access_key>'
if (-not $DryRun) {
    if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
        Write-Error 'openclaw command not found. Install OpenClaw first or rerun in -DryRun mode.'
    }

    $PreviewApiKey = Resolve-NodeClawApiKey
}

$OnboardArgs = @(
    'onboard',
    '--non-interactive',
    '--mode', 'local',
    '--auth-choice', 'custom-api-key',
    '--custom-base-url', $NodeClawBaseUrl,
    '--custom-model-id', $NodeClawModelId,
    '--custom-api-key', $PreviewApiKey,
    '--custom-provider-id', $NodeClawProviderId,
    '--custom-compatibility', $NodeClawCompatibility,
    '--gateway-port', $OpenClawGatewayPort,
    '--gateway-bind', $OpenClawGatewayBind
)

Write-Host 'Target OpenClaw posture: persistent-primary onboarding owner'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Base URL: $NodeClawBaseUrl"
Write-Host "Model: $NodeClawModelId"
Write-Host "Compatibility: $NodeClawCompatibility"
Write-Host ''

if ($DryRun) {
    Write-Host 'Dry run only. Planned OpenClaw command:'
    Write-Host ''
    Write-Host ('  openclaw ' + ($OnboardArgs -join ' '))
    Write-Host ''
    Write-Host 'Redacted secret argument: --custom-api-key <nodeclaw_access_key>'
    Write-Host ''
    Write-Host 'Windows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification.'
    Write-Host 'Then run:'
    Write-Host '  openclaw config file'
    Write-Host '  openclaw config validate --json'
    exit 0
}

& openclaw @OnboardArgs

Write-Host ''
Write-Host ("Configured OpenClaw custom provider {0} -> {1} ({2}, {3})." -f $NodeClawProviderId, $NodeClawBaseUrl, $NodeClawModelId, $NodeClawCompatibility)
Write-Host 'Active OpenClaw config file:'
& openclaw config file

Write-Host ''
Write-Host 'Config validation:'
& openclaw config validate --json
