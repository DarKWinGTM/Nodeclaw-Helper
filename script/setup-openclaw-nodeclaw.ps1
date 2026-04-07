param(
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawProviderId = $(if ($env:NODECLAW_PROVIDER_ID) { $env:NODECLAW_PROVIDER_ID } else { 'nodeclaw' }),
    [ValidateSet('openai', 'anthropic')]
    [string]$NodeClawCompatibility = $(if ($env:NODECLAW_COMPATIBILITY) { $env:NODECLAW_COMPATIBILITY } else { 'openai' }),
    [string]$OpenClawGatewayPort = $(if ($env:OPENCLAW_GATEWAY_PORT) { $env:OPENCLAW_GATEWAY_PORT } else { '18789' }),
    [string]$OpenClawGatewayBind = $(if ($env:OPENCLAW_GATEWAY_BIND) { $env:OPENCLAW_GATEWAY_BIND } else { 'loopback' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
    Write-Error 'openclaw command not found. Install OpenClaw first from the official docs, then rerun this script.'
}

if ([string]::IsNullOrWhiteSpace($NodeClawApiKey)) {
    Write-Error 'Set NODECLAW_API_KEY before running this script. Example: $env:NODECLAW_API_KEY="<nodeclaw_access_key>"; .\script\setup-openclaw-nodeclaw.ps1'
}

$OnboardArgs = @(
    'onboard',
    '--non-interactive',
    '--mode', 'local',
    '--auth-choice', 'custom-api-key',
    '--custom-base-url', $NodeClawBaseUrl,
    '--custom-model-id', $NodeClawModelId,
    '--custom-api-key', $NodeClawApiKey,
    '--custom-provider-id', $NodeClawProviderId,
    '--custom-compatibility', $NodeClawCompatibility,
    '--gateway-port', $OpenClawGatewayPort,
    '--gateway-bind', $OpenClawGatewayBind
)

if ($DryRun) {
    Write-Host 'Dry run only. Planned OpenClaw command:'
    Write-Host ''
    Write-Host ('  openclaw ' + ($OnboardArgs -join ' '))
    Write-Host ''
    Write-Host 'Windows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification.'
    Write-Host 'Then run:'
    Write-Host '  openclaw config file'
    Write-Host '  openclaw config validate --json'
    exit 0
}

Write-Error 'Windows execution is intentionally not enabled yet. Use -DryRun for now until a real Windows environment is available for validation.'
