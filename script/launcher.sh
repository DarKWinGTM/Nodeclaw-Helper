#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS=("claude-code" "codex" "openclaw" "opencode" "zed")

get_shell_target() {
  case "$1" in
    claude-code)
      printf '%s\n' "$SCRIPT_DIR/setup-claude-code-nodeclaw.sh"
      ;;
    codex)
      printf '%s\n' "$SCRIPT_DIR/setup-codex-nodeclaw.sh"
      ;;
    openclaw)
      printf '%s\n' "$SCRIPT_DIR/setup-openclaw-nodeclaw.sh"
      ;;
    opencode)
      printf '%s\n' "$SCRIPT_DIR/setup-opencode-nodeclaw.sh"
      ;;
    zed)
      printf '%s\n' "$SCRIPT_DIR/setup-zed-nodeclaw.sh"
      ;;
    *)
      printf 'Unsupported tool: %s\n' "$1" >&2
      exit 1
      ;;
  esac
}

LAUNCHER_PS1="$SCRIPT_DIR/launcher.ps1"

usage() {
  cat <<'EOF'
NodeClaw IDE Helper Launcher

Usage:
  bash ./script/launcher.sh <command> [options]

Commands:
  list
      Show supported tools.

  dry-run --tool <tool>
      Run the tool-specific shell helper in dry-run mode.

  apply --tool <tool>
      Run the tool-specific shell helper in apply mode.

  windows-dry-run --tool <tool>
      Run the tool-specific PowerShell helper in dry-run mode.

  help
      Show this help message.

Supported tools:
  claude-code
  codex
  openclaw
  opencode
  zed

Notes:
- Shell helper paths can apply changes where the checked contract supports it.
- PowerShell helper paths remain dry-run-only in the current checked scope.
- Hosted curl|bash distribution is not live yet; use the repo-local scripts for now.
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
}

cmd_dry_run() {
  local tool target
  tool="$(parse_tool_flag "$@")"
  target="$(get_shell_target "$tool")"
  bash "$target" --dry-run
}

cmd_apply() {
  local tool target
  tool="$(parse_tool_flag "$@")"
  target="$(get_shell_target "$tool")"
  bash "$target"
}

cmd_windows_dry_run() {
  local tool
  tool="$(parse_tool_flag "$@")"
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

  "$ps_bin" -File "$LAUNCHER_PS1" -Command dry-run -Tool "$tool"
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
