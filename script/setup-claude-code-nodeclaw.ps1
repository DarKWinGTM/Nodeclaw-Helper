param(
    [string]$ClaudeCodeSettingsPath = $(if ($env:CLAUDE_CODE_SETTINGS_PATH) { $env:CLAUDE_CODE_SETTINGS_PATH } else { Join-Path $HOME '.claude/settings.json' }),
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh' }),
    [ValidateSet('auto', 'env', 'persistent')]
    [string]$NodeClawInstallMode = $(if ($env:NODECLAW_REQUESTED_INSTALL_MODE) { $env:NODECLAW_REQUESTED_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { 'auto' }),
    [string]$NodeClawInteractive = $(if ($env:NODECLAW_INTERACTIVE) { $env:NODECLAW_INTERACTIVE } else { 'auto' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$HelperCapability = 'env-default'

function ConvertTo-CompatHashtable {
    param($InputObject)

    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $Table = [ordered]@{}
        foreach ($Key in $InputObject.Keys) {
            $Table[$Key] = ConvertTo-CompatHashtable -InputObject $InputObject[$Key]
        }
        return $Table
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $Items = @()
        foreach ($Item in $InputObject) {
            $Items += ,(ConvertTo-CompatHashtable -InputObject $Item)
        }
        return $Items
    }

    if ($InputObject -is [pscustomobject]) {
        $Table = [ordered]@{}
        foreach ($Property in $InputObject.PSObject.Properties) {
            $Table[$Property.Name] = ConvertTo-CompatHashtable -InputObject $Property.Value
        }
        return $Table
    }

    return $InputObject
}

function ConvertFrom-JsonCompatHashtable {
    param([string]$Raw)

    if ([string]::IsNullOrWhiteSpace($Raw)) { return @{} }

    $Command = Get-Command ConvertFrom-Json
    $SupportsAsHashtable = $Command.Parameters.ContainsKey('AsHashtable')
    if ($SupportsAsHashtable) {
        $Params = @{ InputObject = $Raw }
        $Params['AsHashtable'] = $true
        return ConvertFrom-Json @Params
    }

    return ConvertTo-CompatHashtable -InputObject ($Raw | ConvertFrom-Json)
}

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

function Get-ClaudeCodeSettingsJson {
    param([string]$ApiKey)

    $Data = @{}
    if (Test-Path $SettingsPath) {
        $Raw = Get-Content -Raw -Path $SettingsPath
        if (-not [string]::IsNullOrWhiteSpace($Raw)) {
            $Data = ConvertFrom-JsonCompatHashtable -Raw $Raw
        }
    }

    if (-not $Data.ContainsKey('env')) { $Data['env'] = @{} }
    $Data['env']['ANTHROPIC_BASE_URL'] = $NodeClawBaseUrl
    $Data['env']['ANTHROPIC_AUTH_TOKEN'] = $ApiKey
    if (-not $Data['env'].ContainsKey('CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS')) { $Data['env']['CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS'] = '1' }
    if (-not $Data['env'].ContainsKey('DISABLE_INTERLEAVED_THINKING')) { $Data['env']['DISABLE_INTERLEAVED_THINKING'] = '1' }

    return ($Data | ConvertTo-Json -Depth 100)
}

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability
$SettingsPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($ClaudeCodeSettingsPath.Replace('~', $HOME)))

Write-Host 'Target Claude Code posture: env-first session contract'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Endpoint root: $NodeClawBaseUrl"
Write-Host ''

if ($ResolvedInstallMode -eq 'env') {
    if ($DryRun) {
        Write-Host 'Dry run only. Planned Claude Code session env assignments:'
        Write-Host ''
        Write-EnvAssignment -Name 'NODECLAW_API_KEY' -Value '<nodeclaw_access_key>'
        Write-EnvAssignment -Name 'ANTHROPIC_BASE_URL' -Value $NodeClawBaseUrl
        Write-Host '$env:ANTHROPIC_AUTH_TOKEN=$env:NODECLAW_API_KEY'
        exit 0
    }

    $NodeClawApiKey = Resolve-NodeClawApiKey
    Write-EnvAssignment -Name 'NODECLAW_API_KEY' -Value $NodeClawApiKey
    Write-EnvAssignment -Name 'ANTHROPIC_BASE_URL' -Value $NodeClawBaseUrl
    Write-Host '$env:ANTHROPIC_AUTH_TOKEN=$env:NODECLAW_API_KEY'
    Write-Host 'Run these assignments in the current PowerShell session or save them into your profile by choice.'
    exit 0
}

$PreviewApiKey = '<nodeclaw_access_key>'
if (-not $DryRun) {
    $PreviewApiKey = Resolve-NodeClawApiKey
}

$Rendered = Get-ClaudeCodeSettingsJson -ApiKey $PreviewApiKey
Write-Host "Target Claude Code settings: $SettingsPath"

if ($DryRun) {
    Write-Host "`nDry run only. Planned Claude Code settings:`n"
    Write-Host $Rendered
    Write-Host "`nWindows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification."
    exit 0
}

$SettingsDirectory = Split-Path -Parent $SettingsPath
if ($SettingsDirectory -and -not (Test-Path $SettingsDirectory)) {
    New-Item -ItemType Directory -Force -Path $SettingsDirectory | Out-Null
}

Set-Content -Path $SettingsPath -Value ($Rendered + "`n") -Encoding UTF8

Write-Host "Wrote Claude Code settings to $SettingsPath"
Write-Host 'Restart Claude Code or reload the session so the managed env settings are picked up.'
