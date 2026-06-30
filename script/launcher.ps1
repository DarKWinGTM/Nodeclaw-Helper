param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$LauncherArgs
)

$LauncherScriptPath = $PSCommandPath
$LauncherHasLocalScriptPath = -not [string]::IsNullOrWhiteSpace($LauncherScriptPath)
$LauncherScriptRoot = if ($LauncherHasLocalScriptPath) { Split-Path -Parent $LauncherScriptPath } else { (Get-Location).Path }

& {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $ScriptPath = $LauncherScriptPath
    $HasLocalScriptPath = $LauncherHasLocalScriptPath
    $ScriptRoot = $LauncherScriptRoot
    $SupportedTools = @('claude-code', 'gemini-cli', 'codex', 'hermes', 'openclaw', 'opencode', 'zed')
    $HelperBaseUrl = if ($env:NODECLAW_HELPER_BASE_URL) { $env:NODECLAW_HELPER_BASE_URL } else { 'https://darkwingtm.github.io/Nodeclaw-Helper/script' }
    $HelperCacheRoot = if ($env:NODECLAW_HELPER_CACHE_DIR) { $env:NODECLAW_HELPER_CACHE_DIR } elseif ($env:XDG_CACHE_HOME) { Join-Path $env:XDG_CACHE_HOME 'nodeclaw-helper' } else { Join-Path $HOME '.cache/nodeclaw-helper' }
    $CloudflareCustomProviderBaseUrl = 'https://gateway.ai.cloudflare.com/v1/06b7333b2c174700306d7f931d809765/nodenetwork-nodeclaw-payg/custom-nodenetwork/'
    $CloudflareCustomProviderGoogleV1BetaBaseUrl = "$CloudflareCustomProviderBaseUrl" + 'v1beta'
    $DefaultRouteMode = 'direct'
    $DefaultInstallMode = 'auto'

    function Show-Usage {
@"
NodeClaw Helper Launcher (PowerShell)

Purpose
  Configure supported tools to use NodeClaw endpoints more easily.
  Use launcher as the main generic entrypoint.
  Remote usage should call launcher only; launcher fetches the helper payload it needs.

Recommended flow
  1. list available tools
  2. run dry-run first
  3. review the planned output
  4. use apply only after preview in the shell launcher flow

Usage:
  .\script\launcher.ps1 -Command list
  .\script\launcher.ps1 -Command dry-run -Tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed> -RouteMode <direct|cloudflare> -InstallMode <auto|env|persistent>
  .\script\launcher.ps1 -Command wizard [-Tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed>] [-RouteMode <direct|cloudflare>] [-InstallMode <auto|env|persistent>]

Remote example:
  powershell -ExecutionPolicy Bypass -c "`$launcherText = irm <nodeclaw-launcher-ps1-url>; & ([scriptblock]::Create(`$launcherText))"

Notes:
- PowerShell launcher stays preview-first in the current checked scope; direct PowerShell helpers remain the tool-specific apply surface where that helper supports file writes or env/session output.
- Route mode defaults to direct; Cloudflare mode is explicit opt-in and only resolves for checked eligible helper families.
- Install mode defaults to auto; auto resolves to env for env-default/hybrid tools and persistent for persistent-primary tools.
- Gemini CLI stays helper-guided on the checked env-first path and can now request Cloudflare for the protected Google / Gemini `v1beta` family when Cloudflare opt-in is selected.
- Remote launcher usage can fetch the helper payload it needs automatically.
- Use direct per-tool scripts if you want a tool-specific entrypoint.
- Hermes currently has a helper-guided profile-local setup target that the launcher can preview through the same entrypoint family.
"@
    }

    function Get-TargetScript {
        param([string]$SelectedTool)

        switch ($SelectedTool) {
            'claude-code' { return (Join-Path $ScriptRoot 'setup-claude-code-nodeclaw.ps1') }
            'gemini-cli' { return (Join-Path $ScriptRoot 'setup-gemini-cli-nodeclaw.ps1') }
            'codex' { return (Join-Path $ScriptRoot 'setup-codex-nodeclaw.ps1') }
            'hermes' { return (Join-Path $ScriptRoot 'setup-hermes-nodeclaw.ps1') }
            'openclaw' { return (Join-Path $ScriptRoot 'setup-openclaw-nodeclaw.ps1') }
            'opencode' { return (Join-Path $ScriptRoot 'setup-opencode-nodeclaw.ps1') }
            'zed' { return (Join-Path $ScriptRoot 'setup-zed-nodeclaw.ps1') }
            default { throw "Unsupported tool: $SelectedTool" }
        }
    }

    function Fetch-RemoteHelperFile {
        param([string]$FileName)

        $null = New-Item -ItemType Directory -Force -Path $HelperCacheRoot
        $targetPath = Join-Path $HelperCacheRoot $FileName
        $sourceUrl = ('{0}/{1}' -f $HelperBaseUrl.TrimEnd('/'), $FileName)
        Write-Host "Fetching helper payload: $sourceUrl"
        Invoke-WebRequest -Uri $sourceUrl -OutFile $targetPath | Out-Null
        return $targetPath
    }

    function Resolve-TargetScript {
        param([string]$SelectedTool)

        if ($HasLocalScriptPath) {
            $localTarget = Get-TargetScript -SelectedTool $SelectedTool
            if (Test-Path $localTarget) {
                return $localTarget
            }
        }

        $cwdScriptTarget = Join-Path (Join-Path (Get-Location).Path 'script') "setup-$SelectedTool-nodeclaw.ps1"
        if (Test-Path $cwdScriptTarget) {
            return $cwdScriptTarget
        }

        return (Fetch-RemoteHelperFile -FileName "setup-$SelectedTool-nodeclaw.ps1")
    }

    function Describe-Tool {
        param([string]$SelectedTool)

        switch ($SelectedTool) {
            'claude-code' { return 'edits ~/.claude/settings.json and writes ANTHROPIC_* env values' }
            'gemini-cli' { return 'writes a managed Gemini env snippet/profile source block for the custom-endpoint path and keeps launch helper-guided' }
            'codex' { return 'edits ~/.codex/config.toml and keeps auth in OPENAI_API_KEY' }
            'hermes' { return 'creates or updates a dedicated Hermes profile with profile-local .env, config.yaml, and SOUL.md for the NodeClaw custom endpoint path' }
            'openclaw' { return 'runs the OpenClaw onboard flow and validates the resulting config' }
            'opencode' { return 'edits opencode.json provider/model configuration' }
            'zed' { return 'edits the Zed settings file selected through ZED_SETTINGS_PATH' }
            default { return 'unknown tool' }
        }
    }

    function Describe-Target {
        param([string]$SelectedTool)

        switch ($SelectedTool) {
            'claude-code' { return '~/.claude/settings.json' }
            'gemini-cli' { return '~/.gemini/nodeclaw-gemini-env.ps1 + PowerShell profile source block' }
            'codex' { return '~/.codex/config.toml' }
            'hermes' { return '~/.hermes or ~/.hermes/profiles/<profile> with profile-local .env, config.yaml, and SOUL.md' }
            'openclaw' { return 'OpenClaw onboard command flow + resulting OpenClaw config' }
            'opencode' { return '~/.config/opencode/opencode.json' }
            'zed' { return 'ZED_SETTINGS_PATH target file' }
            default { return 'unknown target' }
        }
    }

    function Get-CapabilityLabel {
        param([string]$SelectedTool)

        switch ($SelectedTool) {
            'claude-code' { return 'cloudflare-capable' }
            'codex' { return 'cloudflare-capable' }
            'zed' { return 'cloudflare-capable' }
            'openclaw' { return 'cloudflare-capable (openai|anthropic only)' }
            'opencode' { return 'cloudflare-capable (custom-provider root)' }
            'hermes' { return 'cloudflare-capable (custom-provider root)' }
            'gemini-cli' { return 'cloudflare-capable (protected v1beta family)' }
            default { return 'direct-only first-wave' }
        }
    }

    function Normalize-LauncherArguments {
        param($RawArgs)

        if ($null -eq $RawArgs) { return @() }

        $normalized = @()
        foreach ($item in @($RawArgs)) {
            if ($null -eq $item) { continue }
            $text = [string]$item
            if ([string]::IsNullOrEmpty($text)) { continue }
            $normalized += $text
        }

        return @($normalized)
    }

    function Get-InstallCapabilityForTool {
        param([string]$SelectedTool)

        switch ($SelectedTool) {
            'claude-code' { return 'env-default' }
            'gemini-cli' { return 'env-default' }
            'codex' { return 'hybrid' }
            'hermes' { return 'persistent-primary' }
            'openclaw' { return 'persistent-primary' }
            'opencode' { return 'persistent-primary' }
            'zed' { return 'persistent-primary' }
            default { return 'persistent-primary' }
        }
    }

    function Resolve-InstallMode {
        param(
            [string]$RequestedInstallMode,
            [string]$Capability
        )

        switch ($RequestedInstallMode) {
            'env' { return 'env' }
            'persistent' { return 'persistent' }
            '' { }
            'auto' { }
            default { throw "Unsupported install mode: $RequestedInstallMode" }
        }

        switch ($Capability) {
            'env-default' { return 'env' }
            'hybrid' { return 'env' }
            'persistent-primary' { return 'persistent' }
            default { return 'persistent' }
        }
    }

    function Prompt-NodeClawApiKey {
        if (-not [string]::IsNullOrWhiteSpace($env:NODECLAW_API_KEY)) { return }
        if (-not $Host.UI) {
            throw 'NODECLAW_API_KEY is required. Re-run interactively or set the env first.'
        }
        $apiKey = Read-Host 'Enter NodeClaw API key'
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            throw 'NODECLAW_API_KEY is required. Re-run interactively or set the env first.'
        }
        $env:NODECLAW_API_KEY = $apiKey
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

    function Render-LauncherEnvContract {
        param(
            [string]$SelectedTool,
            [bool]$DryRun = $true
        )

        $ApiKey = '<nodeclaw_access_key>'
        if (-not $DryRun) {
            $ApiKey = $env:NODECLAW_API_KEY
        }

        Write-Host "Launcher env install contract for $SelectedTool"
        Write-Host 'No persistent files are changed by env install mode.'
        Write-Host ''
        if ($DryRun) {
            Write-Host 'Dry run only. Planned session env exports:'
            Write-Host ''
        } else {
            Write-Host 'Run these assignments in the current PowerShell session or save them into your profile by choice.'
            Write-Host ''
        }

        Write-EnvAssignment -Name 'NODECLAW_API_KEY' -Value $ApiKey

        switch ($SelectedTool) {
            'claude-code' {
                Write-EnvAssignment -Name 'ANTHROPIC_BASE_URL' -Value $env:NODECLAW_EFFECTIVE_BASE_URL
                Write-Host '$env:ANTHROPIC_AUTH_TOKEN=$env:NODECLAW_API_KEY'
            }
            'gemini-cli' {
                Write-EnvAssignment -Name 'GOOGLE_GEMINI_BASE_URL' -Value $env:NODECLAW_EFFECTIVE_BASE_URL
                Write-Host '$env:GEMINI_API_KEY=$env:NODECLAW_API_KEY'
            }
            'codex' {
                Write-Host '$env:OPENAI_API_KEY=$env:NODECLAW_API_KEY'
                Write-Host ''
                Write-Host 'Codex is hybrid: env mode only supplies auth. Use -InstallMode persistent when base URL/model/provider config must be written.'
            }
            default {
                throw "Env install mode is not available for $SelectedTool from the launcher yet. Use -InstallMode persistent."
            }
        }
    }

    function Export-ResolvedInstallEnv {
        param(
            [string]$SelectedTool,
            [string]$RequestedInstallMode
        )

        $capability = Get-InstallCapabilityForTool -SelectedTool $SelectedTool
        $resolved = Resolve-InstallMode -RequestedInstallMode $RequestedInstallMode -Capability $capability
        $env:NODECLAW_REQUESTED_INSTALL_MODE = if ([string]::IsNullOrWhiteSpace($RequestedInstallMode)) { 'auto' } else { $RequestedInstallMode }
        $env:NODECLAW_INSTALL_CAPABILITY = $capability
        $env:NODECLAW_INSTALL_MODE = $resolved

        return @{
            Requested = $env:NODECLAW_REQUESTED_INSTALL_MODE
            Capability = $capability
            Resolved = $resolved
        }
    }

    function Write-InstallModeSummary {
        param([hashtable]$InstallMode)

        Write-Host "Requested install mode: $($InstallMode.Requested)"
        Write-Host "Install capability: $($InstallMode.Capability)"
        Write-Host "Install mode: $($InstallMode.Resolved)"
    }

    function Write-InstallModeOptions {
        param([string]$Capability)

        Write-Host 'Install mode'
        if ($Capability -in @('env-default', 'hybrid')) {
            Write-Host '  [1] env (recommended)'
            Write-Host '  [2] persistent'
            Write-Host '  [3] auto'
        } else {
            Write-Host '  [1] persistent (recommended)'
            Write-Host '  [2] env'
            Write-Host '  [3] auto'
        }
        Write-Host ''
    }

    function ConvertTo-InstallModeSelection {
        param(
            [string]$Selection,
            [string]$Capability
        )

        if ($Capability -in @('env-default', 'hybrid')) {
            switch ($Selection) {
                '' { return 'auto' }
                '1' { return 'env' }
                'env' { return 'env' }
                '2' { return 'persistent' }
                'persistent' { return 'persistent' }
                '3' { return 'auto' }
                'auto' { return 'auto' }
                default { throw "Unsupported install mode selection: $Selection" }
            }
        }

        switch ($Selection) {
            '' { return 'auto' }
            '1' { return 'persistent' }
            'persistent' { return 'persistent' }
            '2' { return 'env' }
            'env' { return 'env' }
            '3' { return 'auto' }
            'auto' { return 'auto' }
            default { throw "Unsupported install mode selection: $Selection" }
        }
    }

    function Resolve-RouteModeForTool {
        param(
            [string]$SelectedTool,
            [string]$RequestedRouteMode,
            [string]$Compatibility = $(if ($env:NODECLAW_COMPATIBILITY) { $env:NODECLAW_COMPATIBILITY } else { 'openai' })
        )

        $directBase = if ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh/v1' }
        $anthropicDirectRoot = if ($env:NODECLAW_ANTHROPIC_BASE_URL) { $env:NODECLAW_ANTHROPIC_BASE_URL } elseif ($env:NODECLAW_BASE_URL) { $env:NODECLAW_BASE_URL } else { 'https://payg.nodenetwork.ovh' }
        $geminiRoot = if ($env:NODECLAW_GEMINI_BASE_URL) { $env:NODECLAW_GEMINI_BASE_URL } else { 'https://payg.nodenetwork.ovh' }

        switch ($SelectedTool) {
            'claude-code' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='anthropic'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='anthropic'; Base=$anthropicDirectRoot; Reason='' }
            }
            'codex' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='openai'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='openai'; Base=$directBase; Reason='' }
            }
            'zed' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='openai'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='openai'; Base=$directBase; Reason='' }
            }
            'openclaw' {
                if ($RequestedRouteMode -eq 'cloudflare' -and $Compatibility -in @('openai', 'anthropic')) {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='openai-or-anthropic'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='direct'; Family='custom-unverified'; Base=$directBase; Reason='OpenClaw can only use Cloudflare mode when NODECLAW_COMPATIBILITY is openai or anthropic.' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='openai-or-anthropic'; Base=$directBase; Reason='' }
            }
            'gemini-cli' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='gemini-v1beta'; Base=$CloudflareCustomProviderGoogleV1BetaBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='gemini-v1beta'; Base=$geminiRoot; Reason='' }
            }
            'opencode' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='custom-provider-root'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='custom-provider-root'; Base=$directBase; Reason='' }
            }
            'hermes' {
                if ($RequestedRouteMode -eq 'cloudflare') {
                    return @{ Requested='cloudflare'; Resolved='cloudflare'; Family='custom-provider-root'; Base=$CloudflareCustomProviderBaseUrl; Reason='' }
                }
                return @{ Requested='direct'; Resolved='direct'; Family='custom-provider-root'; Base=$directBase; Reason='' }
            }
            default {
                throw "Unsupported tool: $SelectedTool"
            }
        }
    }

    function Export-ResolvedRouteEnv {
        param(
            [string]$SelectedTool,
            [hashtable]$Route
        )

        $env:NODECLAW_REQUESTED_ROUTE_MODE = $Route.Requested
        $env:NODECLAW_RESOLVED_MODE = $Route.Resolved
        $env:NODECLAW_EFFECTIVE_COMPATIBILITY_FAMILY = $Route.Family
        $env:NODECLAW_EFFECTIVE_BASE_URL = $Route.Base
        $env:NODECLAW_FALLBACK_REASON = $Route.Reason
        if ($SelectedTool -eq 'gemini-cli') {
            $env:NODECLAW_GEMINI_BASE_URL = $Route.Base
        } else {
            $env:NODECLAW_BASE_URL = $Route.Base
        }
    }

    function Write-RouteResolutionSummary {
        param([hashtable]$Route)

        Write-Host "Requested route mode: $($Route.Requested)"
        Write-Host "Resolved route mode: $($Route.Resolved)"
        Write-Host "Compatibility family: $($Route.Family)"
        Write-Host "Effective base URL: $($Route.Base)"
        if (-not [string]::IsNullOrWhiteSpace($Route.Reason)) {
            Write-Host "Fallback reason: $($Route.Reason)"
        }
    }

    function Parse-LauncherArguments {
        param($RawArgs)

        $RawArgs = @(Normalize-LauncherArguments -RawArgs $RawArgs)

        $resolvedCommand = if ($env:NODECLAW_LAUNCHER_COMMAND) { $env:NODECLAW_LAUNCHER_COMMAND } else { '' }
        $resolvedTool = if ($env:NODECLAW_LAUNCHER_TOOL) { $env:NODECLAW_LAUNCHER_TOOL } else { '' }
        $resolvedRouteMode = if ($env:NODECLAW_LAUNCHER_ROUTE_MODE) { $env:NODECLAW_LAUNCHER_ROUTE_MODE } else { $DefaultRouteMode }
        $resolvedInstallMode = if ($env:NODECLAW_LAUNCHER_INSTALL_MODE) { $env:NODECLAW_LAUNCHER_INSTALL_MODE } elseif ($env:NODECLAW_INSTALL_MODE) { $env:NODECLAW_INSTALL_MODE } else { $DefaultInstallMode }

        for ($i = 0; $i -lt $RawArgs.Length; $i++) {
            switch ($RawArgs[$i]) {
                '-Command' {
                    if ($i + 1 -ge $RawArgs.Length) {
                        throw 'Set -Command to one of: list, dry-run, wizard, help.'
                    }
                    $i++
                    $resolvedCommand = $RawArgs[$i]
                }
                '-Tool' {
                    if ($i + 1 -ge $RawArgs.Length) {
                        throw 'Set -Tool to one of: claude-code, gemini-cli, codex, hermes, openclaw, opencode, zed.'
                    }
                    $i++
                    $resolvedTool = $RawArgs[$i]
                }
                '-RouteMode' {
                    if ($i + 1 -ge $RawArgs.Length) {
                        throw 'Set -RouteMode to one of: direct, cloudflare.'
                    }
                    $i++
                    $resolvedRouteMode = $RawArgs[$i]
                }
                '-InstallMode' {
                    if ($i + 1 -ge $RawArgs.Length) {
                        throw 'Set -InstallMode to one of: auto, env, persistent.'
                    }
                    $i++
                    $resolvedInstallMode = $RawArgs[$i]
                }
                default {
                    if ([string]::IsNullOrWhiteSpace($resolvedCommand)) {
                        $resolvedCommand = $RawArgs[$i]
                    } elseif ([string]::IsNullOrWhiteSpace($resolvedTool)) {
                        $resolvedTool = $RawArgs[$i]
                    } else {
                        throw "Unknown argument: $($RawArgs[$i])"
                    }
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($resolvedCommand)) {
            $resolvedCommand = 'wizard'
        }

        if ($resolvedCommand -notin @('list', 'dry-run', 'wizard', 'help')) {
            Show-Usage
            throw "Unsupported command: $resolvedCommand"
        }

        if (-not [string]::IsNullOrWhiteSpace($resolvedTool) -and ($resolvedTool -notin $SupportedTools)) {
            throw "Unsupported tool: $resolvedTool"
        }

        if ($resolvedCommand -eq 'dry-run' -and [string]::IsNullOrWhiteSpace($resolvedTool)) {
            Show-Usage
            throw 'Set -Tool when using dry-run.'
        }

        if ($resolvedRouteMode -notin @('direct', 'cloudflare')) {
            throw "Unsupported route mode: $resolvedRouteMode"
        }

        if ($resolvedInstallMode -notin @('auto', 'env', 'persistent')) {
            throw "Unsupported install mode: $resolvedInstallMode"
        }

        return @{
            Command = $resolvedCommand
            Tool = $resolvedTool
            RouteMode = $resolvedRouteMode
            InstallMode = $resolvedInstallMode
        }
    }

    $NormalizedLauncherArgs = @(Normalize-LauncherArguments -RawArgs $LauncherArgs)
    $parsed = Parse-LauncherArguments -RawArgs $NormalizedLauncherArgs
    $Command = $parsed.Command
    $Tool = $parsed.Tool
    $RouteMode = $parsed.RouteMode
    $InstallMode = $parsed.InstallMode

    if ($Command -eq 'help') {
        Show-Usage
        return
    }

    if ($Command -eq 'list') {
        Write-Host 'Supported tools:'
        foreach ($Item in $SupportedTools) {
            Write-Host "  - $Item"
        }
        Write-Host ''
        Write-Host 'What each helper changes:'
        foreach ($Item in $SupportedTools) {
            Write-Host "  $Item -> $(Describe-Tool -SelectedTool $Item) [$(Get-CapabilityLabel -SelectedTool $Item), install=$(Get-InstallCapabilityForTool -SelectedTool $Item)]"
        }
        return
    }

    if ($Command -eq 'wizard') {
        Write-Host 'NodeClaw Setup Wizard'
        Write-Host ''
        Write-Host 'Step 1/6 — Choose tool'
        Write-Host '  [1] claude-code'
        Write-Host '  [2] gemini-cli'
        Write-Host '  [3] codex'
        Write-Host '  [4] hermes'
        Write-Host '  [5] openclaw'
        Write-Host '  [6] opencode'
        Write-Host '  [7] zed'
        Write-Host ''

        $Selection = if ([string]::IsNullOrWhiteSpace($Tool)) { Read-Host 'Select tool' } else { $Tool }
        switch ($Selection) {
            '1' { $Tool = 'claude-code' }
            '2' { $Tool = 'gemini-cli' }
            '3' { $Tool = 'codex' }
            '4' { $Tool = 'hermes' }
            '5' { $Tool = 'openclaw' }
            '6' { $Tool = 'opencode' }
            '7' { $Tool = 'zed' }
            'claude-code' { $Tool = 'claude-code' }
            'gemini-cli' { $Tool = 'gemini-cli' }
            'codex' { $Tool = 'codex' }
            'hermes' { $Tool = 'hermes' }
            'openclaw' { $Tool = 'openclaw' }
            'opencode' { $Tool = 'opencode' }
            'zed' { $Tool = 'zed' }
            default { throw "Unsupported selection: $Selection" }
        }

        Write-Host ''
        Write-Host 'Step 2/6 — Choose routing mode'
        if ($NormalizedLauncherArgs.Count -gt 0 -or -not [string]::IsNullOrWhiteSpace($env:NODECLAW_LAUNCHER_ROUTE_MODE)) {
            Write-Host "Preselected route mode: $RouteMode"
        } else {
            Write-Host '  [1] direct'
            Write-Host '  [2] cloudflare'
            Write-Host ''
            $RouteSelection = Read-Host 'Select routing mode'
            switch ($RouteSelection) {
                '' { $RouteMode = 'direct' }
                '1' { $RouteMode = 'direct' }
                '2' { $RouteMode = 'cloudflare' }
                'direct' { $RouteMode = 'direct' }
                'cloudflare' { $RouteMode = 'cloudflare' }
                default { throw "Unsupported routing mode selection: $RouteSelection" }
            }
        }

        $InstallCapability = Get-InstallCapabilityForTool -SelectedTool $Tool
        Write-Host ''
        Write-Host 'Step 3/6 — Choose install mode'
        if ($NormalizedLauncherArgs -contains '-InstallMode' -or -not [string]::IsNullOrWhiteSpace($env:NODECLAW_LAUNCHER_INSTALL_MODE) -or -not [string]::IsNullOrWhiteSpace($env:NODECLAW_INSTALL_MODE) -or @(Normalize-LauncherArguments -RawArgs $NormalizedLauncherArgs).Length -gt 0) {
            Write-Host "Preselected install mode: $InstallMode"
        } else {
            Write-InstallModeOptions -Capability $InstallCapability
            $InstallSelection = Read-Host 'Select install mode'
            $InstallMode = ConvertTo-InstallModeSelection -Selection $InstallSelection -Capability $InstallCapability
        }

        Write-Host ''
        Write-Host 'Step 4/6 — What this helper does'
        Write-Host "  Tool: $Tool"
        Write-Host "  Summary: $(Describe-Tool -SelectedTool $Tool)"
        Write-Host "  Target: $(Describe-Target -SelectedTool $Tool)"

        $Route = Resolve-RouteModeForTool -SelectedTool $Tool -RequestedRouteMode $RouteMode
        Export-ResolvedRouteEnv -SelectedTool $Tool -Route $Route
        $ResolvedInstallMode = Export-ResolvedInstallEnv -SelectedTool $Tool -RequestedInstallMode $InstallMode
        $Target = Resolve-TargetScript -SelectedTool $Tool
        Write-Host ''
        Write-Host 'Step 5/6 — Preview first'
        Write-Host '  Launcher will run:'
        Write-Host "    $Target -DryRun"
        if (-not $HasLocalScriptPath) {
            Write-Host '  Remote launcher will fetch the helper payload automatically when needed.'
        }
        Write-Host ''
        Write-RouteResolutionSummary -Route $Route
        Write-InstallModeSummary -InstallMode $ResolvedInstallMode
        if ($ResolvedInstallMode.Resolved -eq 'env') {
            Render-LauncherEnvContract -SelectedTool $Tool -DryRun $true
        } else {
            & $Target -DryRun
        }
        Write-Host ''
        Write-Host 'Step 6/6 — Apply'
        Write-Host '  PowerShell launcher stops at preview in the current checked scope.'
        Write-Host '  If you want apply next, run the direct PowerShell helper for the same tool without -DryRun where that helper supports file writes or env/session output.'
        return
    }

    $Target = Resolve-TargetScript -SelectedTool $Tool
    if (-not (Test-Path $Target)) {
        throw "Target setup script not found: $Target"
    }

    switch ($Command) {
        'dry-run' {
            $Route = Resolve-RouteModeForTool -SelectedTool $Tool -RequestedRouteMode $RouteMode
            Export-ResolvedRouteEnv -SelectedTool $Tool -Route $Route
            $ResolvedInstallMode = Export-ResolvedInstallEnv -SelectedTool $Tool -RequestedInstallMode $InstallMode
            Write-Host "Launcher target: $Target"
            Write-RouteResolutionSummary -Route $Route
            Write-InstallModeSummary -InstallMode $ResolvedInstallMode
            if ($ResolvedInstallMode.Resolved -eq 'env') {
                Render-LauncherEnvContract -SelectedTool $Tool -DryRun $true
            } else {
                & $Target -DryRun
            }
        }
        default {
            Show-Usage
            throw "Unsupported command: $Command"
        }
    }
}
