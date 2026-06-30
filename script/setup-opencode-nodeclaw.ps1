param(
    [string]$OpenCodeConfig = $(if ($env:OPENCODE_CONFIG) { $env:OPENCODE_CONFIG } else { Join-Path $HOME '.config/opencode/opencode.json' }),
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
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

function Get-OpenCodeConfigJson {
    param([string]$ApiKey)

    $Data = @{}
    if (Test-Path $ConfigPath) {
        $Raw = Get-Content -Raw -Path $ConfigPath
        if (-not [string]::IsNullOrWhiteSpace($Raw)) {
            $Data = ConvertFrom-JsonCompatHashtable -Raw $Raw
        }
    }

    if (-not $Data.ContainsKey('provider')) { $Data['provider'] = @{} }
    if (-not $Data['provider'].ContainsKey('nodeclaw')) { $Data['provider']['nodeclaw'] = @{} }
    if (-not $Data['provider']['nodeclaw'].ContainsKey('options')) { $Data['provider']['nodeclaw']['options'] = @{} }
    if (-not $Data['provider']['nodeclaw'].ContainsKey('models')) { $Data['provider']['nodeclaw']['models'] = @{} }

    $Data['provider']['nodeclaw']['name'] = 'NodeClaw'
    $Data['provider']['nodeclaw']['options']['baseURL'] = $NodeClawBaseUrl
    $Data['provider']['nodeclaw']['options']['apiKey'] = $ApiKey
    $Data['provider']['nodeclaw']['models'][$NodeClawModelId] = @{ name = $NodeClawModelId }
    $Data['model'] = "nodeclaw/$NodeClawModelId"

    return ($Data | ConvertTo-Json -Depth 100)
}

$ResolvedInstallMode = Resolve-NodeClawInstallMode -RequestedInstallMode $NodeClawInstallMode -Capability $HelperCapability
$ConfigPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($OpenCodeConfig.Replace('~', $HOME)))
$PreviewApiKey = '<nodeclaw_access_key>'
if (-not $DryRun) {
    $PreviewApiKey = Resolve-NodeClawApiKey
}
$Rendered = Get-OpenCodeConfigJson -ApiKey $PreviewApiKey

Write-Host 'Target OpenCode posture: persistent-primary config owner'
Write-Host "Capability class: $HelperCapability"
Write-Host "Requested install mode: $NodeClawInstallMode"
Write-Host "Install mode: $ResolvedInstallMode"
Write-Host "Target OpenCode config: $ConfigPath"
Write-Host "Base URL: $NodeClawBaseUrl"
Write-Host "Model: nodeclaw/$NodeClawModelId"

if ($DryRun) {
    Write-Host "`nDry run only. Planned OpenCode config:`n"
    Write-Host $Rendered
    Write-Host "`nDry run only. Re-run without -DryRun to write the OpenCode config."
    exit 0
}

$ConfigDirectory = Split-Path -Parent $ConfigPath
if ($ConfigDirectory -and -not (Test-Path $ConfigDirectory)) {
    New-Item -ItemType Directory -Force -Path $ConfigDirectory | Out-Null
}

Set-Content -Path $ConfigPath -Value ($Rendered + "`n") -Encoding UTF8
Write-Host "Wrote OpenCode config to $ConfigPath"
