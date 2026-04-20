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
  .\script\launcher.ps1 -Command dry-run -Tool <claude-code|gemini-cli|codex|hermes|openclaw|opencode|zed>
  .\script\launcher.ps1 -Command wizard

Remote example:
  powershell -ExecutionPolicy Bypass -c "irm <nodeclaw-launcher-ps1-url> | iex"

Notes:
- PowerShell helper paths remain scaffold-first and dry-run-only in the current checked scope.
- Remote launcher usage can fetch the helper payload it needs automatically.
- Use direct per-tool scripts if you want a tool-specific entrypoint.
- Gemini CLI stays helper-guided on the checked env-first path.
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

    function Parse-LauncherArguments {
        param([string[]]$RawArgs)

        $resolvedCommand = if ($env:NODECLAW_LAUNCHER_COMMAND) { $env:NODECLAW_LAUNCHER_COMMAND } else { '' }
        $resolvedTool = if ($env:NODECLAW_LAUNCHER_TOOL) { $env:NODECLAW_LAUNCHER_TOOL } else { '' }

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

        return @{
            Command = $resolvedCommand
            Tool = $resolvedTool
        }
    }

    $parsed = Parse-LauncherArguments -RawArgs $LauncherArgs
    $Command = $parsed.Command
    $Tool = $parsed.Tool

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
            Write-Host "  $Item -> $(Describe-Tool -SelectedTool $Item)"
        }
        return
    }

    if ($Command -eq 'wizard') {
        Write-Host 'NodeClaw Setup Wizard'
        Write-Host ''
        Write-Host 'Step 1/4 — Choose tool'
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
        Write-Host 'Step 2/4 — What this helper does'
        Write-Host "  Tool: $Tool"
        Write-Host "  Summary: $(Describe-Tool -SelectedTool $Tool)"
        Write-Host "  Target: $(Describe-Target -SelectedTool $Tool)"

        $Target = Resolve-TargetScript -SelectedTool $Tool
        Write-Host ''
        Write-Host 'Step 3/4 — Preview first'
        Write-Host '  Launcher will run:'
        Write-Host "    $Target -DryRun"
        if (-not $HasLocalScriptPath) {
            Write-Host '  Remote launcher will fetch the helper payload automatically when needed.'
        }
        Write-Host ''
        & $Target -DryRun
        Write-Host ''
        Write-Host 'Step 4/4 — Apply'
        Write-Host '  PowerShell helpers remain dry-run-only in the current checked scope.'
        Write-Host '  If you want the apply path today, use the shell launcher for the same tool.'
        return
    }

    $Target = Resolve-TargetScript -SelectedTool $Tool
    if (-not (Test-Path $Target)) {
        throw "Target setup script not found: $Target"
    }

    switch ($Command) {
        'dry-run' {
            Write-Host "Launcher target: $Target"
            & $Target -DryRun
        }
        default {
            Show-Usage
            throw "Unsupported command: $Command"
        }
    }
}
