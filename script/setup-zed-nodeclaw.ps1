param(
    [string]$ZedSettingsPath = $env:ZED_SETTINGS_PATH,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [string]$NodeClawModelDisplayName = $(if ($env:NODECLAW_MODEL_DISPLAY_NAME) { $env:NODECLAW_MODEL_DISPLAY_NAME } else { 'NodeClaw GPT-5.4' }),
    [int]$NodeClawMaxTokens = $(if ($env:NODECLAW_MAX_TOKENS) { [int]$env:NODECLAW_MAX_TOKENS } else { 128000 }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ZedSettingsPath)) {
    Write-Error 'Set ZED_SETTINGS_PATH before running this script. Use Zed Command Palette > zed: open settings file to get the active settings path. Example: $env:ZED_SETTINGS_PATH="<path-to-zed-settings.json>"; .\script\setup-zed-nodeclaw.ps1 -DryRun'
}

$SettingsPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($ZedSettingsPath.Replace('~', $HOME)))
$Data = @{}

if (Test-Path $SettingsPath) {
    $Raw = Get-Content -Raw -Path $SettingsPath
    if (-not [string]::IsNullOrWhiteSpace($Raw)) {
        $Data = $Raw | ConvertFrom-Json -AsHashtable
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
    Write-Host "`nWindows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification."
    exit 0
}

Write-Error 'Windows execution is intentionally not enabled yet. Use -DryRun for now until a real Windows environment is available for validation.'
