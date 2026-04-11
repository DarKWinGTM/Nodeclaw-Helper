param(
    [string]$NodeClawGeminiBaseUrl = $(if ($env:NODECLAW_GEMINI_BASE_URL) { $env:NODECLAW_GEMINI_BASE_URL } else { 'https://payg.nodenetwork.ovh' }),
    [string]$NodeClawApiKey = $(if ($env:NODECLAW_API_KEY) { $env:NODECLAW_API_KEY } elseif ($env:GEMINI_API_KEY) { $env:GEMINI_API_KEY } else { '' }),
    [string]$NodeClawGeminiEnvPath = $(if ($env:NODECLAW_GEMINI_ENV_PATH) { $env:NODECLAW_GEMINI_ENV_PATH } else { Join-Path $HOME '.gemini/nodeclaw-gemini-env.ps1' }),
    [string]$NodeClawGeminiProfilePath = $(if ($env:NODECLAW_GEMINI_PROFILE_PATH) { $env:NODECLAW_GEMINI_PROFILE_PATH } else { $PROFILE }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$managedBlockStart = '# >>> NodeClaw Gemini CLI >>>'
$managedBlockEnd = '# <<< NodeClaw Gemini CLI <<<'
$sourceLine = ". `"$NodeClawGeminiEnvPath`""

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

Write-Host 'Target Gemini CLI posture: env-first / helper-guided custom endpoint'
Write-Host "Custom endpoint root: $NodeClawGeminiBaseUrl"
Write-Host "Managed env snippet: $NodeClawGeminiEnvPath"
Write-Host "Target PowerShell profile: $NodeClawGeminiProfilePath"
Write-Host ''

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
    Write-Host '   - Gemini should authenticate through the gemini-api-key path.'
    Write-Host '   - Requests should reach the custom endpoint root and then follow the Gemini-shaped route family under v1beta.'
    Write-Host '   - Model entitlement failures do not mean the endpoint path is wrong.'
    return
}

if ([string]::IsNullOrWhiteSpace($NodeClawApiKey)) {
    Write-Error 'Set NODECLAW_API_KEY (or GEMINI_API_KEY) before running apply.'
}

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
