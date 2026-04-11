#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi
TOOLS=("claude-code" "gemini-cli" "opencode" "openclaw" "zed" "codex")
HELPER_BASE_URL="${NODECLAW_HELPER_BASE_URL:-https://darkwingtm.github.io/Nodeclaw-Helper/script}"
HELPER_CACHE_DIR="${NODECLAW_HELPER_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nodeclaw-helper}"

get_shell_target() {
  case "$1" in
    claude-code)
      printf '%s\n' "$SCRIPT_DIR/setup-claude-code-nodeclaw.sh"
      ;;
    gemini-cli)
      printf '%s\n' "$SCRIPT_DIR/setup-gemini-cli-nodeclaw.sh"
      ;;
    opencode)
      printf '%s\n' "$SCRIPT_DIR/setup-opencode-nodeclaw.sh"
      ;;
    openclaw)
      printf '%s\n' "$SCRIPT_DIR/setup-openclaw-nodeclaw.sh"
      ;;
    zed)
      printf '%s\n' "$SCRIPT_DIR/setup-zed-nodeclaw.sh"
      ;;
    codex)
      printf '%s\n' "$SCRIPT_DIR/setup-codex-nodeclaw.sh"
      ;;
    *)
      printf 'Unsupported tool: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

LAUNCHER_PS1="$SCRIPT_DIR/launcher.ps1"

fetch_remote_helper_file() {
  local file_name="$1"
  local target_dir="$HELPER_CACHE_DIR"
  local target_path="$target_dir/$file_name"
  local source_url="${HELPER_BASE_URL%/}/$file_name"
  printf 'Fetching helper payload: %s\n' "$source_url" >&2

  mkdir -p "$target_dir"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$source_url" -o "$target_path"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$target_path" "$source_url"
  else
    printf 'Need curl or wget to fetch helper payload from %s\n' "$source_url" >&2
    exit 1
  fi

  chmod +x "$target_path" 2>/dev/null || true
  printf '%s\n' "$target_path"
}

resolve_shell_target() {
  local tool="$1"
  local local_target
  if [ -n "$SCRIPT_SOURCE" ]; then
    local_target="$(get_shell_target "$tool")"
  else
    local_target=""
  fi

  if [ -n "$local_target" ] && [ -f "$local_target" ]; then
    printf '%s\n' "$local_target"
    return 0
  fi

  fetch_remote_helper_file "setup-${tool}-nodeclaw.sh"
}

resolve_powershell_launcher() {
  if [ -n "$SCRIPT_SOURCE" ] && [ -f "$LAUNCHER_PS1" ]; then
    printf '%s\n' "$LAUNCHER_PS1"
    return 0
  fi

  fetch_remote_helper_file "launcher.ps1"
}

describe_tool() {
  case "$1" in
    claude-code)
      printf '%s\n' 'edits ~/.claude/settings.json and writes ANTHROPIC_* env values'
      ;;
    gemini-cli)
      printf '%s\n' 'writes a managed Gemini env snippet/profile source block for the custom-endpoint path and keeps launch helper-guided'
      ;;
    codex)
      printf '%s\n' 'edits ~/.codex/config.toml and keeps auth in OPENAI_API_KEY'
      ;;
    openclaw)
      printf '%s\n' 'runs the OpenClaw onboard flow and validates the resulting config'
      ;;
    opencode)
      printf '%s\n' 'edits opencode.json provider/model configuration'
      ;;
    zed)
      printf '%s\n' 'edits the Zed settings file selected through ZED_SETTINGS_PATH'
      ;;
    *)
      printf '%s\n' 'unknown tool'
      ;;
  esac
}

describe_target() {
  case "$1" in
    claude-code)
      printf '%s\n' '~/.claude/settings.json'
      ;;
    gemini-cli)
      printf '%s\n' '~/.gemini/nodeclaw-gemini-env.sh + shell profile source block'
      ;;
    codex)
      printf '%s\n' '~/.codex/config.toml'
      ;;
    openclaw)
      printf '%s\n' 'OpenClaw onboard command flow + resulting OpenClaw config'
      ;;
    opencode)
      printf '%s\n' '~/.config/opencode/opencode.json'
      ;;
    zed)
      printf '%s\n' 'ZED_SETTINGS_PATH target file'
      ;;
    *)
      printf '%s\n' 'unknown target'
      ;;
  esac
}

usage() {
  cat <<'EOF'
NodeClaw Helper Launcher

Purpose
  Configure supported tools to use NodeClaw endpoints more easily.
  Use launcher as the main generic entrypoint.
  Remote usage should call launcher only; launcher fetches the helper payload it needs.

Recommended flow
  1. list available tools
  2. run dry-run first
  3. review the target file / planned config
  4. run apply only when ready

Usage
  bash ./script/launcher.sh <command> [options]

Remote examples
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- wizard
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- dry-run --tool claude-code
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- apply --tool claude-code
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- dry-run --tool gemini-cli

Commands
  list
      Show supported tools plus what each helper changes.

  dry-run --tool <tool>
      Preview the exact config change without writing files.
      Supported tools: claude-code, gemini-cli, codex, openclaw, opencode, zed.

  apply --tool <tool>
      Apply the config change for the selected tool.
      Apply is currently supported for: claude-code, gemini-cli, codex, openclaw, opencode, zed.

  wizard [--tool <tool>]
      Guided setup mode. Helps choose tool, shows what will change,
      runs dry-run first, and only then offers apply when a helper-managed apply path exists.

  windows-dry-run --tool <tool>
      Preview the PowerShell helper path.
      Current checked boundary: Windows is scaffold-first / dry-run-only.

  help
      Show this help message.

Notes
- Shell helper paths can apply changes where the checked contract supports it.
- PowerShell helper paths remain dry-run-only in the current checked scope.
- Remote launcher usage can fetch the required helper payload automatically from the published helper surface.
- Override the remote helper base with NODECLAW_HELPER_BASE_URL when needed.
EOF
}

require_tool_value() {
  if [ $# -eq 0 ]; then
    printf '--tool requires a value.\n' >&2
    usage >&2
    exit 1
  fi
}

is_supported_tool() {
  local candidate="$1"
  local tool
  for tool in "${TOOLS[@]}"; do
    if [ "$tool" = "$candidate" ]; then
      return 0
    fi
  done
  return 1
}

parse_tool_flag() {
  local tool=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --tool)
        shift
        require_tool_value "$@"
        tool="$1"
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  if [ -z "$tool" ]; then
    printf 'Set --tool to one of: %s\n' "${TOOLS[*]}" >&2
    usage >&2
    exit 1
  fi

  if ! is_supported_tool "$tool"; then
    printf 'Unsupported tool: %s\n' "$tool" >&2
    printf 'Supported tools: %s\n' "${TOOLS[*]}" >&2
    exit 1
  fi

  printf '%s\n' "$tool"
}

cmd_list() {
  printf 'Supported tools:\n'
  local tool
  for tool in "${TOOLS[@]}"; do
    printf '  - %s\n' "$tool"
  done

  printf '\nWhat each helper changes:\n'
  for tool in "${TOOLS[@]}"; do
    printf '  %s -> %s\n' "$tool" "$(describe_tool "$tool")"
  done
}

cmd_dry_run() {
  local tool target
  tool="$(parse_tool_flag "$@")"
  target="$(resolve_shell_target "$tool")"
  printf 'Launcher target: %s\n' "$target"
  bash "$target" --dry-run
}

cmd_apply() {
  local tool target
  tool="$(parse_tool_flag "$@")"
  target="$(resolve_shell_target "$tool")"
  printf 'Launcher target: %s\n' "$target"
  bash "$target"
}

show_wizard_header() {
  cat <<'EOF'
NodeClaw Setup Wizard
EOF
}

prompt_choice() {
  local prompt="$1"
  local value
  printf '%s' "$prompt" >&2
  IFS= read -r value
  printf '%s\n' "$value"
}

cmd_wizard() {
  show_wizard_header
  printf '\nStep 1/4 — Choose tool\n'
  printf '  [1] claude-code\n'
  printf '  [2] gemini-cli\n'
  printf '  [3] codex\n'
  printf '  [4] openclaw\n'
  printf '  [5] opencode\n'
  printf '  [6] zed\n\n'

  local selection tool target run_cmd apply_now
  if [ $# -gt 0 ]; then
    tool="$(parse_tool_flag "$@")"
    selection="$tool"
    printf 'Preselected tool: %s\n' "$tool"
  else
    selection="$(prompt_choice 'Select tool: ')"
  fi

  case "$selection" in
    1|claude-code) tool='claude-code' ;;
    2|gemini-cli) tool='gemini-cli' ;;
    3|codex) tool='codex' ;;
    4|openclaw) tool='openclaw' ;;
    5|opencode) tool='opencode' ;;
    6|zed) tool='zed' ;;
    *)
      printf 'Unsupported selection: %s\n' "$selection" >&2
      exit 1
      ;;
  esac

  printf '\nStep 2/4 — What this helper does\n'
  printf '  Tool: %s\n' "$tool"
  printf '  Summary: %s\n' "$(describe_tool "$tool")"
  printf '  Target: %s\n' "$(describe_target "$tool")"

  target="$(resolve_shell_target "$tool")"

  printf '\nStep 3/4 — Preview first\n'
  printf '  Launcher will run:\n'
  printf '    bash %q --dry-run\n' "$target"
  if [ -z "$SCRIPT_SOURCE" ]; then
    printf '  Remote launcher will fetch the helper payload automatically when needed.\n'
  fi

  printf '\nRunning dry-run now...\n\n'
  bash "$target" --dry-run

  printf '\nStep 4/4 — Apply\n'
  apply_now="$(prompt_choice 'Apply this change now? [y/N]: ')"
  case "$apply_now" in
    y|Y|yes|YES)
      printf '\nApplying...\n\n'
      bash "$target"
      ;;
    *)
      printf '\nNo files were changed by apply. You can rerun later with:\n'
      printf '  bash ./script/launcher.sh apply --tool %s\n' "$tool"
      ;;
  esac
}

run_windows_launcher() {
  local tool="$1"
  local launcher_ps1

  launcher_ps1="$(resolve_powershell_launcher)"

  if ! command -v pwsh >/dev/null 2>&1 && ! command -v powershell >/dev/null 2>&1; then
    printf 'PowerShell runtime not found. Use pwsh or powershell to run the Windows dry-run helper path.\n' >&2
    exit 1
  fi

  local ps_bin
  if command -v pwsh >/dev/null 2>&1; then
    ps_bin="pwsh"
  else
    ps_bin="powershell"
  fi

  "$ps_bin" -File "$launcher_ps1" -Command dry-run -Tool "$tool"
}

cmd_windows_dry_run() {
  local tool
  tool="$(parse_tool_flag "$@")"
  run_windows_launcher "$tool"
}

main() {
  local command="${1:-help}"
  shift || true

  case "$command" in
    list)
      cmd_list
      ;;
    dry-run)
      cmd_dry_run "$@"
      ;;
    apply)
      cmd_apply "$@"
      ;;
    wizard)
      cmd_wizard "$@"
      ;;
    windows-dry-run)
      cmd_windows_dry_run "$@"
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      printf 'Unknown command: %s\n' "$command" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
