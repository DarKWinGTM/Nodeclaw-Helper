param(
    [string]$NodeClawGeminiBaseUrl = $(if ($env:NODECLAW_GEMINI_BASE_URL) { $env:NODECLAW_GEMINI_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1beta' }),
    [string]$NodeClawAuthHeader = $(if ($env:NODECLAW_AUTH_HEADER) { $env:NODECLAW_AUTH_HEADER } else { 'Authorization: Bearer <nodeclaw_access_key>' }),
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host 'Target Gemini CLI posture: manual-first / gateway-capable'
Write-Host "Checked Google / Gemini-shaped base URL: $NodeClawGeminiBaseUrl"
Write-Host "Checked auth header shape: $NodeClawAuthHeader"
Write-Host ''
Write-Host 'Dry run only. Checked Gemini CLI gateway contract:'
Write-Host ''
Write-Host '1. Install Gemini CLI from the official upstream path first.'
Write-Host '2. Use Gemini CLI in ACP mode when you need the strongest checked custom-endpoint path:'
Write-Host '   gemini --acp'
Write-Host '3. Authenticate with ACP methodId = "gateway" and send gateway metadata like:'
Write-Host ''
Write-Host '{'
Write-Host '  "methodId": "gateway",'
Write-Host '  "_meta": {'
Write-Host '    "gateway": {'
Write-Host '      "baseUrl": "https://payg.nodenetwork.ovh/v1beta",'
Write-Host '      "headers": {'
Write-Host '        "Authorization": "Bearer <nodeclaw_access_key>"'
Write-Host '      }'
Write-Host '    }'
Write-Host '  }'
Write-Host '}'
Write-Host ''
Write-Host '4. Optional shell/env helpers when your bridge needs explicit header shaping:'
Write-Host '   GEMINI_API_KEY_AUTH_MECHANISM=bearer'
Write-Host '   GEMINI_CLI_CUSTOM_HEADERS=Authorization:Bearer <nodeclaw_access_key>'
Write-Host ''
Write-Host 'No helper-managed apply path exists for Gemini CLI in the current checked scope.'

if (-not $DryRun) {
    Write-Error 'Gemini CLI remains manual-first / gateway-capable only. No apply path is implemented.'
}
