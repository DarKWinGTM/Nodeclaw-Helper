param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('list', 'dry-run')]
    [string]$Command,
    [ValidateSet('claude-code', 'codex', 'openclaw', 'opencode', 'zed')]
    [string]$Tool
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SupportedTools = @('claude-code', 'codex', 'openclaw', 'opencode', 'zed')

function Show-Usage {
    @"
NodeClaw Helper Launcher (PowerShell)

Usage:
  .\script\launcher.ps1 -Command list
  .\script\launcher.ps1 -Command dry-run -Tool <claude-code|codex|openclaw|opencode|zed>

Notes:
- PowerShell helper paths remain scaffold-first and dry-run-only in the current checked scope.
- Use direct per-tool scripts if you want a tool-specific entrypoint.
"@
}

function Get-TargetScript {
    param([string]$SelectedTool)

    switch ($SelectedTool) {
        'claude-code' { return (Join-Path $ScriptRoot 'setup-claude-code-nodeclaw.ps1') }
        'codex' { return (Join-Path $ScriptRoot 'setup-codex-nodeclaw.ps1') }
        'openclaw' { return (Join-Path $ScriptRoot 'setup-openclaw-nodeclaw.ps1') }
        'opencode' { return (Join-Path $ScriptRoot 'setup-opencode-nodeclaw.ps1') }
        'zed' { return (Join-Path $ScriptRoot 'setup-zed-nodeclaw.ps1') }
        default { throw "Unsupported tool: $SelectedTool" }
    }
}

if ($Command -eq 'list') {
    Write-Host 'Supported tools:'
    foreach ($Item in $SupportedTools) {
        Write-Host "  - $Item"
    }
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Tool)) {
    Show-Usage
    throw 'Set -Tool when using dry-run.'
}

$Target = Get-TargetScript -SelectedTool $Tool

if (-not (Test-Path $Target)) {
    throw "Target setup script not found: $Target"
}

switch ($Command) {
    'dry-run' {
        & $Target -DryRun
    }
    default {
        Show-Usage
        throw "Unsupported command: $Command"
    }
}
