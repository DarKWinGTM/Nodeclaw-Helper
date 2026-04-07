param(
    [string]$ClaudeCodeSettingsPath = $(if ($env:CLAUDE_CODE_SETTINGS_PATH) { $env:CLAUDE_CODE_SETTINGS_PATH } else { Join-Path $HOME '.claude/settings.json' }),
    [string]$NodeClawApiKey = $env:NODECLAW_API_KEY,
    [string]$NodeClawBaseUrl = $(if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($NodeClawApiKey)) {
    Write-Error 'Set NODECLAW_API_KEY before running this script. Example: $env:NODECLAW_API_KEY="<nodeclaw_access_key>"; .\script\setup-claude-code-nodeclaw.ps1 -DryRun'
}

$SettingsPath = [System.IO.Path]::GetFullPath([System.Environment]::ExpandEnvironmentVariables($ClaudeCodeSettingsPath.Replace('~', $HOME)))
$Data = @{}

if (Test-Path $SettingsPath) {
    $Raw = Get-Content -Raw -Path $SettingsPath
    if (-not [string]::IsNullOrWhiteSpace($Raw)) {
        $Data = $Raw | ConvertFrom-Json -AsHashtable
    }
}

if (-not $Data.ContainsKey('env')) { $Data['env'] = @{} }
$Data['env']['ANTHROPIC_BASE_URL'] = $NodeClawBaseUrl
$Data['env']['ANTHROPIC_AUTH_TOKEN'] = $NodeClawApiKey
if (-not $Data['env'].ContainsKey('CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS')) { $Data['env']['CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS'] = '1' }
if (-not $Data['env'].ContainsKey('DISABLE_INTERLEAVED_THINKING')) { $Data['env']['DISABLE_INTERLEAVED_THINKING'] = '1' }

$Rendered = $Data | ConvertTo-Json -Depth 100

Write-Host "Target Claude Code settings: $SettingsPath"

if ($DryRun) {
    Write-Host "`nDry run only. Planned Claude Code settings:`n"
    Write-Host $Rendered
    Write-Host "`nWindows scaffold status: dry-run-only until a real Windows environment is available for end-to-end verification."
    exit 0
}

Write-Error 'Windows execution is intentionally not enabled yet. Use -DryRun for now until a real Windows environment is available for validation.'
