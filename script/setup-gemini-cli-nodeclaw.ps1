param(
    [string]$NodeClawGeminiBaseUrl = $(if ($env:NODECLAW_GEMINI_BASE_URL) { $env:NODECLAW_GEMINI_BASE_URL } else { 'https://payg.nodenetwork.ovh' }),
    [string]$NodeClawApiKey = $(if ($env:NODECLAW_API_KEY) { $env:NODECLAW_API_KEY } elseif ($env:GEMINI_API_KEY) { $env:GEMINI_API_KEY } else { '' }),
    [string]$NodeClawGeminiEnvPath = $(if ($env:NODECLAW_GEMINI_ENV_PATH) { $env:NODECLAW_GEMINI_ENV_PATH } else { Join-Path $HOME '.gemini/nodeclaw-gemini-env.ps1' }),
    [string]$NodeClawGeminiProfilePath = $(if ($env:NODECLAW_GEMINI_PROFILE_PATH) { $env:NODECLAW_GEMINI_PROFILE_PATH } else { $PROFILE }),
    [ValidateSet('auto', 'env', 'persistent')]
    [string]$NodeClawInstallMode = $(if ($env:NODECLAW_REQUESTED_INSTALL_MODE) { $env:NODECLAW_REQUESTED_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { 'auto' }),
    [string]$NodeClawInteractive = $(if ($env:NODECLAW_INTERACTIVE) { $env:NODECLAW_INTERACTIVE } else { 'auto' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$HelperCapability = 'env-default'

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

$managedBlockStart = '# >>> NodeClaw Gemini CLI >>>'
$managedBlockEnd = '# <<< NodeClaw Gemini CLI <<<'
$sourceLine = ". `"$NodeClawGeminiEnvPath`""

function Resolve-NodeClawApiKey {
    if (-not [string]::IsNullOrWhiteSpace($NodeClawApiKey)) { return $NodeClawApiKey }

    if (-not (Test-NodeClawPromptAllowed)) {
        throw 'NODECLAW_API_KEY or GEMINI_API_KEY is required for apply. Re-run interactively or set NODECLAW_API_KEY first.'
    }

    $PromptedKey = Read-Host 'Enter NodeClaw API key'
    if ([string]::IsNullOrWhiteSpace($PromptedKey)) {
        throw 'NODECLAW_API_KEY cannot be empty.'
    }

    $env:NODECLAW_API_KEY = $PromptedKey
    $env:GEMINI_API_KEY = $PromptedKey
    $env:NODECLAW_PROMPTED_API_KEY = 'true'
    return $PromptedKey
}

function Get-EnvSnippet {
    param([string]$ApiKey)
@"
`$env:GOOGLE_GEMINI_BASE_URL=`"$NodeClawGeminiBaseUrl`"
`$env:GEMINI_API_KEY=`"$ApiKey`"
"@
}

function Get-ProfileBlock {
@"
$managedBlockStart
$sourceLine
$managedBlockEnd
"@
}

function Write-GeminiVerificationNotes {
    Write-Host '   - Gemini should authenticate through the gemini-api-key path.'
    Write-Host '   - Requests should reach the custom endpoint root and then follow the Gemini-shaped route family under v1beta.'
    Write-Host '   - Model entitlement failures do not mean the endpoint path is wrong.'
}

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability

Write-Host 'Target Gemini CLI posture: env-first / helper-guided custom endpoint'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Custom endpoint root: $NodeClawGeminiBaseUrl"
Write-Host "Managed env snippet: $NodeClawGeminiEnvPath"
Write-Host "Target PowerShell profile: $NodeClawGeminiProfilePath"
Write-Host ''

if ($ResolvedInstallMode -eq 'env') {
    if ($DryRun) {
        Write-Host 'Dry run only. Planned Gemini CLI session env assignments:'
        Write-Host ''
        Write-Host (Get-EnvSnippet -ApiKey '<nodeclaw_access_key>')
        Write-Host 'Verification notes:'
        Write-GeminiVerificationNotes
        exit 0
    }

    $NodeClawApiKey = Resolve-NodeClawApiKey
    Write-Host (Get-EnvSnippet -ApiKey $NodeClawApiKey)
    Write-Host 'Run these assignments in the current PowerShell session or save them into your profile by choice.'
    exit 0
}

if ($DryRun) {
    Write-Host 'Dry run only. Planned Gemini CLI helper output:'
    Write-Host ''
    Write-Host '1. Helper-managed env snippet:'
    Write-Host ''
    Write-Host (Get-EnvSnippet -ApiKey '<nodeclaw_access_key>')
    Write-Host ''
    Write-Host '2. Helper-managed PowerShell profile block:'
    Write-Host ''
    Write-Host (Get-ProfileBlock)
    Write-Host ''
    Write-Host '3. Immediate session usage after writing the snippet:'
    Write-Host ''
    Write-Host ". `"$NodeClawGeminiEnvPath`""
    Write-Host 'gemini'
    Write-Host ''
    Write-Host '4. Verification notes:'
    Write-GeminiVerificationNotes
    exit 0
}

$NodeClawApiKey = Resolve-NodeClawApiKey
$envDirectory = Split-Path -Parent $NodeClawGeminiEnvPath
if (-not (Test-Path $envDirectory)) {
    New-Item -ItemType Directory -Force -Path $envDirectory | Out-Null
}

Get-EnvSnippet -ApiKey $NodeClawApiKey | Set-Content -Path $NodeClawGeminiEnvPath -Encoding UTF8

if (Test-Path $NodeClawGeminiProfilePath) {
    $profileContent = Get-Content -Path $NodeClawGeminiProfilePath -Raw
    if ($profileContent -notlike "*$managedBlockStart*") {
        Add-Content -Path $NodeClawGeminiProfilePath -Value "`r`n$(Get-ProfileBlock)`r`n"
    }
}
else {
    $profileDirectory = Split-Path -Parent $NodeClawGeminiProfilePath
    if ($profileDirectory -and -not (Test-Path $profileDirectory)) {
        New-Item -ItemType Directory -Force -Path $profileDirectory | Out-Null
    }
    Set-Content -Path $NodeClawGeminiProfilePath -Value ((Get-ProfileBlock) + "`r`n") -Encoding UTF8
}

Write-Host "Wrote Gemini helper env snippet to $NodeClawGeminiEnvPath"
Write-Host "Ensured PowerShell profile sources it from $NodeClawGeminiProfilePath"
Write-Host ''
Write-Host 'Use one of these to activate it now:'
Write-Host "  . `"$NodeClawGeminiEnvPath`""
Write-Host "  . `"$NodeClawGeminiProfilePath`""
Write-Host ''
Write-Host 'Then launch Gemini normally:'
Write-Host '  gemini'
Write-Host ''
Write-Host 'Verification reminder:'
Write-Host '  - If Gemini reaches the endpoint but fails on model entitlement, re-check the model/account before changing the endpoint root.'
