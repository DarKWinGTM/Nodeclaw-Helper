param(
    [string]$HermesNodeClawProfile = $(if ($env:HERMES_NODECLAW_PROFILE) { $env:HERMES_NODECLAW_PROFILE } else { 'nodeclaw-hermes' }),
    [string]$HermesNodeClawHome = $(if ($env:HERMES_NODECLAW_HOME) { $env:HERMES_NODECLAW_HOME } else { '' }),
    [string]$HermesNodeClawBaseUrl = $(if ($env:HERMES_NODECLAW_BASE_URL) { $env:HERMES_NODECLAW_BASE_URL } elseif ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$HermesNodeClawApiKey = $(if ($env:HERMES_NODECLAW_API_KEY) { $env:HERMES_NODECLAW_API_KEY } else { $env:NODECLAW_API_KEY }),
    [string]$HermesNodeClawModel = $(if ($env:HERMES_NODECLAW_MODEL) { $env:HERMES_NODECLAW_MODEL } elseif ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$HermesNodeClawWorkdir = $(if ($env:HERMES_NODECLAW_WORKDIR) { $env:HERMES_NODECLAW_WORKDIR } else { '' }),
    [ValidateSet('fresh', 'clone', 'clone-all')]
    [string]$HermesNodeClawCloneMode = $(if ($env:HERMES_NODECLAW_CLONE_MODE) { $env:HERMES_NODECLAW_CLONE_MODE } else { 'fresh' }),
    [string]$HermesNodeClawCloneFrom = $(if ($env:HERMES_NODECLAW_CLONE_FROM) { $env:HERMES_NODECLAW_CLONE_FROM } else { '' }),
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

function Resolve-HermesProfileHome {
    if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawHome)) {
        return $HermesNodeClawHome
    }

    if ($HermesNodeClawProfile -eq 'default') {
        return (Join-Path $HOME '.hermes')
    }

    return (Join-Path $HOME ".hermes/profiles/$HermesNodeClawProfile")
}

$ProfileHome = Resolve-HermesProfileHome
$EnvPath = Join-Path $ProfileHome '.env'
$ConfigPath = Join-Path $ProfileHome 'config.yaml'
$SoulPath = Join-Path $ProfileHome 'SOUL.md'
$IsCustomHome = -not [string]::IsNullOrWhiteSpace($HermesNodeClawHome)
$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability

function Resolve-HermesApiKey {
    if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawApiKey)) { return $HermesNodeClawApiKey }

    if (-not (Test-NodeClawPromptAllowed)) {
        throw 'HERMES_NODECLAW_API_KEY or NODECLAW_API_KEY is required for apply. Re-run interactively or set NODECLAW_API_KEY first.'
    }

    $PromptedKey = Read-Host 'Enter NodeClaw API key'
    if ([string]::IsNullOrWhiteSpace($PromptedKey)) {
        throw 'NODECLAW_API_KEY cannot be empty.'
    }

    $env:HERMES_NODECLAW_API_KEY = $PromptedKey
    $env:NODECLAW_API_KEY = $PromptedKey
    $env:NODECLAW_PROMPTED_API_KEY = 'true'
    return $PromptedKey
}

function Get-EnvContent {
    param([string]$ApiKey)

    $lines = @(
        '# NodeClaw-managed Hermes profile env',
        "HERMES_NODECLAW_PROFILE=$HermesNodeClawProfile",
        "HERMES_NODECLAW_BASE_URL=$HermesNodeClawBaseUrl",
        "HERMES_NODECLAW_API_KEY=$ApiKey",
        "HERMES_NODECLAW_MODEL=$HermesNodeClawModel"
    )

    if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawWorkdir)) {
        $lines += "HERMES_NODECLAW_WORKDIR=$HermesNodeClawWorkdir"
    }

    return ($lines -join "`n") + "`n"
}

function Get-ConfigContent {
    $lines = @(
        '# NodeClaw-managed Hermes profile config',
        'model:',
        '  default: "${HERMES_NODECLAW_MODEL}"',
        '  provider: "custom"',
        '  base_url: "${HERMES_NODECLAW_BASE_URL}"',
        '  api_key: "${HERMES_NODECLAW_API_KEY}"'
    )

    if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawWorkdir)) {
        $lines += @(
            '',
            'terminal:',
            '  backend: "local"',
            '  cwd: "${HERMES_NODECLAW_WORKDIR}"'
        )
    }

    return ($lines -join "`n") + "`n"
}

function Get-SoulContent {
@"
# NodeClaw Hermes Profile

You are the NodeClaw-backed Hermes additional runtime IDE agent profile.

## Role
- use the NodeClaw custom endpoint configured through the profile-local env/config contract
- keep secrets in .env and non-secret route structure in config.yaml
- treat this profile as a dedicated NodeClaw helper-managed profile rather than a shared mutable Hermes home

## Boundary
- this is an additional runtime IDE agent path
- it is inventory-first and not a Home-promoted path by default
- keep service-specific compatibility translation outside the profile when a shim is required

## Managed contract
- profile: $HermesNodeClawProfile
- profile home: $ProfileHome
- endpoint env: HERMES_NODECLAW_BASE_URL
- api key env: HERMES_NODECLAW_API_KEY
- model env: HERMES_NODECLAW_MODEL
"@
}

function Show-VerificationNotes {
    Write-Host 'Verification reminders:'
    Write-Host "  - hermes --profile=$HermesNodeClawProfile doctor"
    Write-Host "  - hermes --profile=$HermesNodeClawProfile config"
    Write-Host "  - hermes -p $HermesNodeClawProfile chat"
}

function Get-ProfileCreatePreview {
    if ($IsCustomHome) {
        return "mkdir -Force -ItemType Directory `"$ProfileHome`""
    }

    if ($HermesNodeClawProfile -eq 'default') {
        return "update default Hermes home at $ProfileHome"
    }

    $parts = @('hermes', 'profile', 'create', $HermesNodeClawProfile)
    switch ($HermesNodeClawCloneMode) {
        'clone' {
            $parts += '--clone'
            if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawCloneFrom)) {
                $parts += '--clone-from'
                $parts += $HermesNodeClawCloneFrom
            }
        }
        'clone-all' {
            $parts += '--clone-all'
        }
    }

    return ($parts -join ' ')
}

function Ensure-ProfileExists {
    if (Test-Path $ProfileHome) {
        return
    }

    if ($IsCustomHome -or $HermesNodeClawProfile -eq 'default') {
        New-Item -ItemType Directory -Force -Path $ProfileHome | Out-Null
        return
    }

    if (-not (Get-Command hermes -ErrorAction SilentlyContinue)) {
        Write-Error 'hermes command not found. Install Hermes first or rerun in -DryRun mode.'
    }

    $createArgs = @('profile', 'create', $HermesNodeClawProfile)
    switch ($HermesNodeClawCloneMode) {
        'clone' {
            $createArgs += '--clone'
            if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawCloneFrom)) {
                $createArgs += '--clone-from'
                $createArgs += $HermesNodeClawCloneFrom
            }
        }
        'clone-all' {
            $createArgs += '--clone-all'
        }
    }

    & hermes @createArgs
}

Write-Host "Target Hermes profile: $HermesNodeClawProfile"
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Target Hermes home: $ProfileHome"
Write-Host "Managed env file: $EnvPath"
Write-Host "Managed config file: $ConfigPath"
Write-Host "Managed SOUL file: $SoulPath"
Write-Host "Endpoint root: $HermesNodeClawBaseUrl"
Write-Host "Model: $HermesNodeClawModel"
Write-Host "Clone mode: $HermesNodeClawCloneMode"
if (-not [string]::IsNullOrWhiteSpace($HermesNodeClawCloneFrom)) {
    Write-Host "Clone source profile: $HermesNodeClawCloneFrom"
}
Write-Host ''

if ($DryRun) {
    Write-Host 'Dry run only. Planned Hermes helper output:'
    Write-Host ''
    Write-Host '1. Profile creation path:'
    Write-Host ''
    Write-Host ('  ' + (Get-ProfileCreatePreview))
    Write-Host ''
    Write-Host '2. Managed .env contents:'
    Write-Host ''
    Write-Host (Get-EnvContent -ApiKey '<nodeclaw_access_key>')
    Write-Host '3. Managed config.yaml contents:'
    Write-Host ''
    Write-Host (Get-ConfigContent)
    Write-Host '4. Managed SOUL.md contents:'
    Write-Host ''
    Write-Host (Get-SoulContent)
    Write-Host '5. Suggested verification commands:'
    Write-Host ''
    Show-VerificationNotes
    exit 0
}

$HermesNodeClawApiKey = Resolve-HermesApiKey
Ensure-ProfileExists
New-Item -ItemType Directory -Force -Path $ProfileHome | Out-Null
Set-Content -Path $EnvPath -Value (Get-EnvContent -ApiKey $HermesNodeClawApiKey) -Encoding UTF8
Set-Content -Path $ConfigPath -Value (Get-ConfigContent) -Encoding UTF8
Set-Content -Path $SoulPath -Value ((Get-SoulContent) + "`r`n") -Encoding UTF8

Write-Host "Wrote Hermes profile env to $EnvPath"
Write-Host "Wrote Hermes profile config to $ConfigPath"
Write-Host "Wrote Hermes profile identity to $SoulPath"
Write-Host ''
Write-Host 'PowerShell launcher remains dry-run-first, but this direct Hermes PowerShell helper can write the profile-local files now.'
Write-Host ''
Show-VerificationNotes
