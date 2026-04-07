param(
    [string]$OpenCodeConfig = $(if ($env:OPENCODE_CONFIG) { $env:OPENCODE_CONFIG } else { Join-Path $HOME '.config/opencode/opencode.json' }),
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [string]$NodeClawModelId = $(if ($env:NODECLAW_MODEL_ID) { $env:NODECLAW_MODEL_ID } else { 'gpt-5.4' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($NodeClawApiKey)) {
    Write-Error 'Set NODECLAW_API_KEY before running this script. Example: $env:NODECLAW_API_KEY="<nodeclaw_access_key>"; .\script\setup-opencode-nodeclaw.ps1 -DryRun'
}

$ConfigPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($OpenCodeConfig.Replace('~', $HOME)))
$Data = @{}

if (Test-Path $ConfigPath) {
    $Raw = Get-Content -Raw -Path $ConfigPath
    if (-not [string]::IsNullOrWhiteSpace($Raw)) {
        $Data = $Raw | ConvertFrom-Json -AsHashtable
    }
}

if (-not $Data.ContainsKey('provider')) { $Data['provider'] = @{} }
if (-not $Data['provider'].ContainsKey('nodeclaw')) { $Data['provider']['nodeclaw'] = @{} }
if (-not $Data['provider']['nodeclaw'].ContainsKey('options')) { $Data['provider']['nodeclaw']['options'] = @{} }
if (-not $Data['provider']['nodeclaw'].ContainsKey('models')) { $Data['provider']['nodeclaw']['models'] = @{} }

$Data['provider']['nodeclaw']['name'] = 'NodeClaw'
$Data['provider']['nodeclaw']['options']['baseURL'] = $NodeClawBaseUrl
$Data['provider']['nodeclaw']['options']['apiKey'] = $NodeClawApiKey
$Data['provider']['nodeclaw']['models'][$NodeClawModelId] = @{ name = $NodeClawModelId }
$Data['model'] = "nodeclaw/$NodeClawModelId"

$Rendered = $Data | ConvertTo-Json -Depth 100

Write-Host "Target OpenCode config: $ConfigPath"

if ($DryRun) {
    Write-Host "`nDry run only. Planned OpenCode config:`n"
    Write-Host $Rendered
    Write-Host "`nWindows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification."
    exit 0
}

Write-Error 'Windows execution is intentionally not enabled yet. Use -DryRun for now until a real Windows environment is available for validation.'
