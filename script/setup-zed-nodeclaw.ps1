param(
    [string]$ZedSettingsPath = $env:ZED_SETTINGS_PATH,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawModelDisplayName = $(if ($env:NODECLAW_MODEL_DISPLAY_NAME) { $env:NODECLAW_MODEL_DISPLAY_NAME } else { 'NodeClaw GPT-5.4' }),
    [int]$NodeClawMaxTokens = $(if ($env:NODECLAW_MAX_TOKENS) { [int]$env:NODECLAW_MAX_TOKENS } else { 128000 }),
    [ValidateSet('auto', 'env', 'persistent')]
    [string]$NodeClawInstallMode = $(if ($env:NODECLAW_REQUESTED_INSTALL_MODE) { $env:NODECLAW_REQUESTED_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { 'auto' }),
    [string]$NodeClawInteractive = $(if ($env:NODECLAW_INTERACTIVE) { $env:NODECLAW_INTERACTIVE } else { 'auto' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$HelperCapability = 'persistent-primary'

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

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability

Write-Host 'Target Zed posture: persistent-primary settings owner'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Endpoint root: $NodeClawBaseUrl"
Write-Host "Model: $NodeClawModelId"
Write-Host ''

if ([string]::IsNullOrWhiteSpace($ZedSettingsPath)) {
    Write-Error 'Set ZED_SETTINGS_PATH before running this script. Use Zed Command Palette > zed: open settings file to get the active settings path. Example: $env:ZED_SETTINGS_PATH="<path-to-zed-settings.json>"; .\script\setup-zed-nodeclaw.ps1 -DryRun'
}

$SettingsPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($ZedSettingsPath.Replace('~', $HOME)))
$Data = @{}

if (Test-Path $SettingsPath) {
    $Raw = Get-Content -Raw -Path $SettingsPath
    if (-not [string]::IsNullOrWhiteSpace($Raw)) {
        $Data = ConvertFrom-JsonCompatHashtable -Raw $Raw
    }
}

if (-not $Data.ContainsKey('language_models')) { $Data['language_models'] = @{} }
if (-not $Data['language_models'].ContainsKey('openai_compatible')) { $Data['language_models']['openai_compatible'] = @{} }
if (-not $Data['language_models']['openai_compatible'].ContainsKey('NodeClaw')) { $Data['language_models']['openai_compatible']['NodeClaw'] = @{} }

$NodeClawProvider = $Data['language_models']['openai_compatible']['NodeClaw']
$NodeClawProvider['api_url'] = $NodeClawBaseUrl

$ExistingModels = @()
if ($NodeClawProvider.ContainsKey('available_models') -and $NodeClawProvider['available_models']) {
    $ExistingModels = @($NodeClawProvider['available_models'])
}

$FilteredModels = @()
foreach ($Model in $ExistingModels) {
    if ($Model.name -ne $NodeClawModelId) {
        $FilteredModels += $Model
    }
}

$FilteredModels += @{
    name = $NodeClawModelId
    display_name = $NodeClawModelDisplayName
    max_tokens = $NodeClawMaxTokens
}

$NodeClawProvider['available_models'] = $FilteredModels
$Rendered = $Data | ConvertTo-Json -Depth 100

Write-Host "Target Zed settings: $SettingsPath"

if ($DryRun) {
    Write-Host "`nDry run only. Planned Zed settings:`n"
    Write-Host $Rendered
    Write-Host "`nDry run only. Re-run without -DryRun to write the Zed settings."
    exit 0
}

$SettingsDirectory = Split-Path -Parent $SettingsPath
if ($SettingsDirectory -and -not (Test-Path $SettingsDirectory)) {
    New-Item -ItemType Directory -Force -Path $SettingsDirectory | Out-Null
}

Set-Content -Path $SettingsPath -Value ($Rendered + "`n") -Encoding UTF8
Write-Host "Wrote Zed settings to $SettingsPath"
