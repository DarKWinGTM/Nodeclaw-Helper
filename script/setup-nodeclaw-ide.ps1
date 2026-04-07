param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('claude-code', 'codex', 'openclaw', 'opencode', 'zed')]
    [string]$Tool,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$TargetScript = switch ($Tool) {
    'claude-code' { Join-Path $ScriptRoot 'setup-claude-code-nodeclaw.ps1' }
    'codex' { Join-Path $ScriptRoot 'setup-codex-nodeclaw.ps1' }
    'openclaw' { Join-Path $ScriptRoot 'setup-openclaw-nodeclaw.ps1' }
    'opencode' { Join-Path $ScriptRoot 'setup-opencode-nodeclaw.ps1' }
    'zed' { Join-Path $ScriptRoot 'setup-zed-nodeclaw.ps1' }
}

if (-not (Test-Path $TargetScript)) {
    Write-Error "Target setup script not found: $TargetScript"
}

$InvokeArgs = @{}
if ($DryRun) {
    $InvokeArgs['DryRun'] = $true
}

& $TargetScript @InvokeArgs
