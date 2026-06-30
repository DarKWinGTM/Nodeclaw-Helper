#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
  SCRIPT_DIR="$(pwd)"
fi
TOOLS=("claude-code" "gemini-cli" "opencode" "openclaw" "zed" "codex" "hermes")
HELPER_BASE_URL="${NODECLAW_HELPER_BASE_URL:-https://darkwingtm.github.io/Nodeclaw-Helper/script}"
HELPER_CACHE_DIR="${NODECLAW_HELPER_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nodeclaw-helper}"
CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL="https://gateway.ai.cloudflare.com/v1/06b7333b2c174700306d7f931d809765/nodenetwork-nodeclaw-payg/custom-nodenetwork/"
CLOUDFLARE_CUSTOM_PROVIDER_GOOGLE_V1BETA_BASE_URL="${CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL%/}/v1beta"
DEFAULT_ROUTE_MODE="direct"
DEFAULT_INSTALL_MODE="auto"
NODECLAW_INTERACTIVE="${NODECLAW_INTERACTIVE:-auto}"

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
    hermes)
      printf '%s\n' "$SCRIPT_DIR/setup-hermes-nodeclaw.sh"
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
    hermes)
      printf '%s\n' 'creates or updates a dedicated Hermes profile with profile-local .env, config.yaml, and SOUL.md for the NodeClaw custom endpoint path'
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
    hermes)
      printf '%s\n' '~/.hermes or ~/.hermes/profiles/<profile> with profile-local .env, config.yaml, and SOUL.md'
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

capability_label() {
  case "$1" in
    claude-code|codex|zed)
      printf '%s\n' 'cloudflare-capable'
      ;;
    openclaw)
      printf '%s\n' 'cloudflare-capable (openai|anthropic only)'
      ;;
    opencode|hermes)
      printf '%s\n' 'cloudflare-capable (custom-provider root)'
      ;;
    gemini-cli)
      printf '%s\n' 'cloudflare-capable (protected v1beta family)'
      ;;
    *)
      printf '%s\n' 'direct-only first-wave'
      ;;
  esac
}

install_capability_for_tool() {
  case "$1" in
    claude-code|gemini-cli)
      printf '%s\n' 'env-default'
      ;;
    codex)
      printf '%s\n' 'hybrid'
      ;;
    hermes|openclaw|opencode|zed)
      printf '%s\n' 'persistent-primary'
      ;;
    *)
      printf '%s\n' 'persistent-primary'
      ;;
  esac
}

resolve_install_mode() {
  local requested="$1"
  local capability="$2"

  case "$requested" in
    env|persistent)
      printf '%s\n' "$requested"
      return
      ;;
    auto|'')
      ;;
    *)
      printf 'Unsupported install mode: %s\n' "$requested" >&2
      exit 1
      ;;
  esac

  case "$capability" in
    env-default|hybrid)
      printf 'env\n'
      ;;
    persistent-primary)
      printf 'persistent\n'
      ;;
    *)
      printf 'persistent\n'
      ;;
  esac
}

prompt_input_is_available() {
  [ -t 0 ] || { [ -r /dev/tty ] && [ -w /dev/tty ]; }
}

read_prompt_value() {
  local __var_name="$1"

  if [ -t 0 ]; then
    IFS= read -r "$__var_name"
  elif [ -r /dev/tty ] && [ -w /dev/tty ]; then
    IFS= read -r "$__var_name" < /dev/tty
  else
    return 1
  fi
}

print_prompt_message() {
  local message="$1"

  if [ -w /dev/tty ]; then
    printf '%s' "$message" > /dev/tty
  else
    printf '%s' "$message" >&2
  fi
}

helper_allows_prompt() {
  case "$NODECLAW_INTERACTIVE" in
    true|TRUE|1|yes|YES)
      return 0
      ;;
    false|FALSE|0|no|NO)
      return 1
      ;;
    auto|'')
      prompt_input_is_available
      ;;
    *)
      printf 'NODECLAW_INTERACTIVE must be auto, true, or false.
' >&2
      exit 1
      ;;
  esac
}

prompt_nodeclaw_api_key() {
  local required="${1:-required}"

  if [ -n "${NODECLAW_API_KEY:-}" ]; then
    return 0
  fi

  if ! helper_allows_prompt; then
    if [ "$required" = 'optional' ]; then
      return 0
    fi
    printf 'NODECLAW_API_KEY is required. Re-run interactively or export NODECLAW_API_KEY first.
' >&2
    exit 1
  fi

  print_prompt_message 'Enter NodeClaw API key: '
  if ! read_prompt_value NODECLAW_API_KEY || [ -z "$NODECLAW_API_KEY" ]; then
    if [ "$required" = 'optional' ]; then
      unset NODECLAW_API_KEY 2>/dev/null || true
      return 0
    fi
    printf 'NODECLAW_API_KEY is required. Re-run interactively or export NODECLAW_API_KEY first.\n' >&2
    exit 1
  fi
  export NODECLAW_API_KEY
}

launcher_can_render_env_contract() {
  case "$1" in
    claude-code|gemini-cli|codex)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

quote_shell_value() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}

print_export_line() {
  local name="$1"
  local value="$2"
  printf 'export %s=' "$name"
  quote_shell_value "$value"
  printf '\n'
}

render_launcher_env_contract() {
  local tool="$1"
  local dry_run="${2:-true}"
  local api_key="<nodeclaw_access_key>"

  if [ "$dry_run" != 'true' ]; then
    api_key="$NODECLAW_API_KEY"
  fi

  printf 'Launcher env install contract for %s\n' "$tool"
  printf 'No persistent files are changed by env install mode.\n'
  if [ "$dry_run" = 'true' ]; then
    printf '\nDry run only. Planned session env exports:\n\n'
  else
    printf '\nRun these exports in the current shell or save them into your profile by choice:\n\n'
  fi

  print_export_line 'NODECLAW_API_KEY' "$api_key"

  case "$tool" in
    claude-code)
      print_export_line 'ANTHROPIC_BASE_URL' "$NODECLAW_EFFECTIVE_BASE_URL"
      printf 'export ANTHROPIC_AUTH_TOKEN="$NODECLAW_API_KEY"\n'
      ;;
    gemini-cli)
      print_export_line 'GOOGLE_GEMINI_BASE_URL' "$NODECLAW_EFFECTIVE_BASE_URL"
      printf 'export GEMINI_API_KEY="$NODECLAW_API_KEY"\n'
      ;;
    codex)
      printf 'export OPENAI_API_KEY="$NODECLAW_API_KEY"\n'
      printf '\nCodex is hybrid: env mode only supplies auth. Use --install-mode persistent when base URL/model/provider config must be written.\n'
      ;;
    *)
      printf 'Env install mode is not available for %s from the launcher yet. Use --install-mode persistent.\n' "$tool" >&2
      exit 1
      ;;
  esac
}

block_unsupported_launcher_env_mode() {
  local tool="$1"
  if [ "${NODECLAW_INSTALL_MODE:-}" = 'env' ] && ! launcher_can_render_env_contract "$tool"; then
    printf 'Install mode env is not available for %s from the launcher yet. Use --install-mode persistent for the helper-managed path.\n' "$tool" >&2
    exit 1
  fi
}

route_mode_for_tool() {
  local tool="$1"
  local requested="$2"
  local compatibility="${NODECLAW_COMPATIBILITY:-openai}"
  local direct_base="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
  local anthropic_direct_root="${NODECLAW_ANTHROPIC_BASE_URL:-${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh}}"
  local gemini_root="${NODECLAW_GEMINI_BASE_URL:-https://payg.nodenetwork.ovh}"

  case "$tool" in
    claude-code)
      if [ "$requested" = 'cloudflare' ]; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'cloudflare' 'anthropic' "$CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL" ''
      else
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'anthropic' "$anthropic_direct_root" ''
      fi
      ;;
    codex|zed)
      if [ "$requested" = 'cloudflare' ]; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'cloudflare' 'openai' "$CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL" ''
      else
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'openai' "$direct_base" ''
      fi
      ;;
    openclaw)
      if [ "$requested" = 'cloudflare' ] && { [ "$compatibility" = 'openai' ] || [ "$compatibility" = 'anthropic' ]; }; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'cloudflare' 'openai-or-anthropic' "$CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL" ''
      elif [ "$requested" = 'cloudflare' ]; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'custom-unverified' "$direct_base" 'OpenClaw can only use Cloudflare mode when NODECLAW_COMPATIBILITY is openai or anthropic.'
      else
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'openai-or-anthropic' "$direct_base" ''
      fi
      ;;
    gemini-cli)
      if [ "$requested" = 'cloudflare' ]; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'cloudflare' 'gemini-v1beta' "$CLOUDFLARE_CUSTOM_PROVIDER_GOOGLE_V1BETA_BASE_URL" ''
      else
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'gemini-v1beta' "$gemini_root" ''
      fi
      ;;
    opencode|hermes)
      if [ "$requested" = 'cloudflare' ]; then
        printf '%s|%s|%s|%s|%s\n' "$requested" 'cloudflare' 'custom-provider-root' "$CLOUDFLARE_CUSTOM_PROVIDER_BASE_URL" ''
      else
        printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'custom-provider-root' "$direct_base" ''
      fi
      ;;
    *)
      printf '%s|%s|%s|%s|%s\n' "$requested" 'direct' 'custom-unverified' "$direct_base" 'Unknown tool family.'
      ;;
  esac
}

export_resolved_route_env() {
  local tool="$1"
  local requested="$2"
  local requested_mode resolved_mode family base reason

  IFS='|' read -r requested_mode resolved_mode family base reason <<EOF
$(route_mode_for_tool "$tool" "$requested")
EOF

  export NODECLAW_REQUESTED_ROUTE_MODE="$requested_mode"
  export NODECLAW_RESOLVED_MODE="$resolved_mode"
  export NODECLAW_EFFECTIVE_COMPATIBILITY_FAMILY="$family"
  export NODECLAW_EFFECTIVE_BASE_URL="$base"
  if [ -n "$reason" ]; then
    export NODECLAW_FALLBACK_REASON="$reason"
  else
    unset NODECLAW_FALLBACK_REASON 2>/dev/null || true
  fi

  if [ "$tool" = 'gemini-cli' ]; then
    export NODECLAW_GEMINI_BASE_URL="$base"
  else
    export NODECLAW_BASE_URL="$base"
  fi
}

export_resolved_install_env() {
  local tool="$1"
  local requested="$2"
  local capability resolved

  capability="$(install_capability_for_tool "$tool")"
  resolved="$(resolve_install_mode "$requested" "$capability")"

  export NODECLAW_REQUESTED_INSTALL_MODE="${requested:-auto}"
  export NODECLAW_INSTALL_CAPABILITY="$capability"
  export NODECLAW_INSTALL_MODE="$resolved"
}

print_route_resolution_summary() {
  printf 'Requested route mode: %s\n' "$NODECLAW_REQUESTED_ROUTE_MODE"
  printf 'Resolved route mode: %s\n' "$NODECLAW_RESOLVED_MODE"
  printf 'Compatibility family: %s\n' "$NODECLAW_EFFECTIVE_COMPATIBILITY_FAMILY"
  printf 'Effective base URL: %s\n' "$NODECLAW_EFFECTIVE_BASE_URL"
  if [ -n "${NODECLAW_FALLBACK_REASON:-}" ]; then
    printf 'Fallback reason: %s\n' "$NODECLAW_FALLBACK_REASON"
  fi
}

print_install_mode_summary() {
  printf 'Requested install mode: %s\n' "$NODECLAW_REQUESTED_INSTALL_MODE"
  printf 'Install capability: %s\n' "$NODECLAW_INSTALL_CAPABILITY"
  printf 'Install mode: %s\n' "$NODECLAW_INSTALL_MODE"
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
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- dry-run --tool gemini-cli --route-mode cloudflare
  curl -fsSL <nodeclaw-launcher-url> | bash -s -- dry-run --tool hermes

Commands
  list
      Show supported tools plus what each helper changes.

  dry-run --tool <tool> [--route-mode <direct|cloudflare>] [--install-mode <auto|env|persistent>]
      Preview the exact config change without writing files.
      Supported tools: claude-code, gemini-cli, codex, hermes, openclaw, opencode, zed.
      Route mode defaults to direct. Cloudflare mode is only used for checked eligible tool families.
      Install mode defaults to auto, which resolves to env when the checked tool contract supports it.

  apply --tool <tool> [--route-mode <direct|cloudflare>] [--install-mode <auto|env|persistent>]
      Apply the config change for the selected tool.
      Apply is currently supported for: claude-code, gemini-cli, codex, hermes, openclaw, opencode, zed.
      Route mode defaults to direct. Ineligible tools fall back to direct with an explicit reason.
      Env install mode prompts for NODECLAW_API_KEY when the key is missing.

  wizard [--tool <tool>] [--route-mode <direct|cloudflare>] [--install-mode <auto|env|persistent>]
      Guided setup mode. Helps choose tool, route mode, install mode, shows what will change,
      runs dry-run first, and only then offers apply when a helper-managed apply path exists.

  windows-dry-run --tool <tool> [--route-mode <direct|cloudflare>] [--install-mode <auto|env|persistent>]
      Preview the PowerShell helper path.
      Current checked boundary: Windows is scaffold-first / dry-run-only.

  help
      Show this help message.

Notes
- Shell helper paths can apply changes where the checked contract supports it.
- PowerShell helper paths remain dry-run-only in the current checked scope.
- Route mode defaults to direct; Cloudflare mode is explicit opt-in and only resolves for checked eligible helper families.
- Install mode defaults to auto; auto resolves to env for env-default/hybrid tools and persistent for persistent-primary tools.
- Gemini CLI now supports the protected Google / Gemini `v1beta` route when Cloudflare mode is selected, while direct mode keeps the native Gemini root.
- Remote launcher usage can fetch the required helper payload automatically from the published helper surface.
- Override the remote helper base with NODECLAW_HELPER_BASE_URL when needed.
EOF
}

require_flag_value() {
  local flag="$1"
  shift
  if [ $# -eq 0 ]; then
    printf '%s requires a value.\n' "$flag" >&2
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

has_argument_flag() {
  local flag="$1"
  shift
  local arg
  for arg in "$@"; do
    if [ "$arg" = "$flag" ]; then
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
        require_flag_value '--tool' "$@"
        tool="$1"
        ;;
      --route-mode|--install-mode)
        local flag="$1"
        shift
        require_flag_value "$flag" "$@"
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

parse_route_mode_flag() {
  local requested="$DEFAULT_ROUTE_MODE"

  while [ $# -gt 0 ]; do
    case "$1" in
      --tool|--install-mode)
        local flag="$1"
        shift
        require_flag_value "$flag" "$@"
        ;;
      --route-mode)
        shift
        require_flag_value '--route-mode' "$@"
        requested="$1"
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  case "$requested" in
    direct|cloudflare)
      printf '%s\n' "$requested"
      ;;
    *)
      printf 'Unsupported route mode: %s\n' "$requested" >&2
      exit 1
      ;;
  esac
}

parse_install_mode_flag() {
  local requested="$DEFAULT_INSTALL_MODE"

  while [ $# -gt 0 ]; do
    case "$1" in
      --tool|--route-mode)
        local flag="$1"
        shift
        require_flag_value "$flag" "$@"
        ;;
      --install-mode)
        shift
        require_flag_value '--install-mode' "$@"
        requested="$1"
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  case "$requested" in
    auto|env|persistent)
      printf '%s\n' "$requested"
      ;;
    *)
      printf 'Unsupported install mode: %s\n' "$requested" >&2
      exit 1
      ;;
  esac
}

resolve_launcher_setup_install_mode() {
  local command="$1"
  local tool="$2"
  local requested="$3"

  if [ "$requested" = 'auto' ]; then
    case "$command:$tool" in
      apply:claude-code|wizard:claude-code)
        printf 'persistent\n'
        return
        ;;
    esac
  fi

  printf '%s\n' "$requested"
}

cmd_list() {
  printf 'Supported tools:\n'
  local tool
  for tool in "${TOOLS[@]}"; do
    printf '  - %s\n' "$tool"
  done

  printf '\nWhat each helper changes:\n'
  for tool in "${TOOLS[@]}"; do
    printf '  %s -> %s [%s, install=%s]\n' "$tool" "$(describe_tool "$tool")" "$(capability_label "$tool")" "$(install_capability_for_tool "$tool")"
  done
}

cmd_dry_run() {
  local tool route_mode install_mode
  tool="$(parse_tool_flag "$@")"
  route_mode="$(parse_route_mode_flag "$@")"
  install_mode="$(parse_install_mode_flag "$@")"
  install_mode="$(resolve_launcher_setup_install_mode 'dry-run' "$tool" "$install_mode")"
  export_resolved_route_env "$tool" "$route_mode"
  export_resolved_install_env "$tool" "$install_mode"

  if [ "$NODECLAW_INSTALL_MODE" = 'env' ]; then
    print_route_resolution_summary
    print_install_mode_summary
    render_launcher_env_contract "$tool" true
    return
  fi

  local target
  target="$(resolve_shell_target "$tool")"
  printf 'Launcher target: %s
' "$target"
  print_route_resolution_summary
  print_install_mode_summary
  bash "$target" --dry-run
}

cmd_apply() {
  local tool route_mode install_mode
  tool="$(parse_tool_flag "$@")"
  route_mode="$(parse_route_mode_flag "$@")"
  install_mode="$(parse_install_mode_flag "$@")"
  install_mode="$(resolve_launcher_setup_install_mode 'apply' "$tool" "$install_mode")"
  export_resolved_route_env "$tool" "$route_mode"
  export_resolved_install_env "$tool" "$install_mode"

  if [ "$NODECLAW_INSTALL_MODE" = 'env' ]; then
    prompt_nodeclaw_api_key
    print_route_resolution_summary
    print_install_mode_summary
    render_launcher_env_contract "$tool" false
    return
  fi

  local target
  target="$(resolve_shell_target "$tool")"
  printf 'Launcher target: %s
' "$target"
  print_route_resolution_summary
  print_install_mode_summary
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
  IFS= read -r value || value=""
  printf '%s\n' "$value"
}

print_install_mode_options() {
  local capability="$1"
  printf 'Install mode\n'
  case "$capability" in
    env-default|hybrid)
      printf '  [1] env (recommended)\n'
      printf '  [2] persistent\n'
      printf '  [3] auto\n'
      ;;
    *)
      printf '  [1] persistent (recommended)\n'
      printf '  [2] env\n'
      printf '  [3] auto\n'
      ;;
  esac
  printf '\n'
}

normalize_install_mode_selection() {
  local selection="$1"
  local capability="$2"

  case "$capability" in
    env-default|hybrid)
      case "$selection" in
        ''|auto|3) printf 'auto\n' ;;
        1|env) printf 'env\n' ;;
        2|persistent) printf 'persistent\n' ;;
        *)
          printf 'Unsupported install mode selection: %s\n' "$selection" >&2
          exit 1
          ;;
      esac
      ;;
    *)
      case "$selection" in
        ''|auto|3) printf 'auto\n' ;;
        1|persistent) printf 'persistent\n' ;;
        2|env) printf 'env\n' ;;
        *)
          printf 'Unsupported install mode selection: %s\n' "$selection" >&2
          exit 1
          ;;
      esac
      ;;
  esac
}

cmd_wizard() {
  show_wizard_header
  printf '\nStep 1/6 — Choose tool\n'
  printf '  [1] claude-code\n'
  printf '  [2] gemini-cli\n'
  printf '  [3] codex\n'
  printf '  [4] hermes\n'
  printf '  [5] openclaw\n'
  printf '  [6] opencode\n'
  printf '  [7] zed\n\n'

  local selection tool target apply_now route_mode_input route_mode install_mode install_mode_input install_capability
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
    4|hermes) tool='hermes' ;;
    5|openclaw) tool='openclaw' ;;
    6|opencode) tool='opencode' ;;
    7|zed) tool='zed' ;;
    *)
      printf 'Unsupported selection: %s\n' "$selection" >&2
      exit 1
      ;;
  esac

  if [ $# -gt 0 ]; then
    route_mode="$(parse_route_mode_flag "$@")"
    printf '\nStep 2/6 — Choose routing mode\n'
    printf 'Preselected route mode: %s\n' "$route_mode"
  else
    printf '\nStep 2/6 — Choose routing mode\n'
    printf '  [1] direct\n'
    printf '  [2] cloudflare\n\n'
    route_mode_input="$(prompt_choice 'Select routing mode: ')"
    case "$route_mode_input" in
      ''|1|direct) route_mode='direct' ;;
      2|cloudflare) route_mode='cloudflare' ;;
      *)
        printf 'Unsupported routing mode selection: %s\n' "$route_mode_input" >&2
        exit 1
        ;;
    esac
  fi

  install_capability="$(install_capability_for_tool "$tool")"
  if has_argument_flag '--install-mode' "$@"; then
    install_mode="$(parse_install_mode_flag "$@")"
    install_mode="$(resolve_launcher_setup_install_mode 'wizard' "$tool" "$install_mode")"
    printf '\nStep 3/6 — Choose install mode\n'
    printf 'Preselected install mode: %s\n' "$install_mode"
  else
    printf '\nStep 3/6 — Choose install mode\n'
    print_install_mode_options "$install_capability"
    install_mode_input="$(prompt_choice 'Select install mode: ')"
    install_mode="$(normalize_install_mode_selection "$install_mode_input" "$install_capability")"
    install_mode="$(resolve_launcher_setup_install_mode 'wizard' "$tool" "$install_mode")"
  fi

  printf '\nStep 4/6 — What this helper does\n'
  printf '  Tool: %s\n' "$tool"
  printf '  Summary: %s\n' "$(describe_tool "$tool")"
  printf '  Target: %s\n' "$(describe_target "$tool")"

  target="$(resolve_shell_target "$tool")"
  export_resolved_route_env "$tool" "$route_mode"
  export_resolved_install_env "$tool" "$install_mode"

  printf '
Step 5/6 — Preview first
'
  printf '  Launcher will run:
'
  if [ "$NODECLAW_INSTALL_MODE" = 'env' ]; then
    printf '    render session env exports for %s
' "$tool"
  else
    printf '    bash %q --dry-run
' "$target"
  fi
  if [ -z "$SCRIPT_SOURCE" ]; then
    printf '  Remote launcher will fetch the helper payload automatically when needed.
'
  fi

  printf '
Running dry-run now...

'
  print_route_resolution_summary
  print_install_mode_summary
  if [ "$NODECLAW_INSTALL_MODE" = 'env' ]; then
    render_launcher_env_contract "$tool" true
  else
    bash "$target" --dry-run
  fi

  printf '
Step 6/6 — Apply
'
  apply_now="$(prompt_choice 'Apply this change now? [y/N]: ')"
  case "$apply_now" in
    y|Y|yes|YES)
      printf '
Applying...

'
      if [ "$NODECLAW_INSTALL_MODE" = 'env' ]; then
        prompt_nodeclaw_api_key
        render_launcher_env_contract "$tool" false
      else
        bash "$target"
      fi
      ;;
    *)
      printf '
No files were changed by apply. You can rerun later with:
'
      printf '  bash ./script/launcher.sh apply --tool %s --route-mode %s --install-mode %s
' "$tool" "$route_mode" "$NODECLAW_REQUESTED_INSTALL_MODE"
      ;;
  esac
}

run_windows_launcher() {
  local tool="$1"
  local route_mode="$2"
  local install_mode="$3"
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

  "$ps_bin" -File "$launcher_ps1" -Command dry-run -Tool "$tool" -RouteMode "$route_mode" -InstallMode "$install_mode"
}

cmd_windows_dry_run() {
  local tool route_mode install_mode
  tool="$(parse_tool_flag "$@")"
  route_mode="$(parse_route_mode_flag "$@")"
  install_mode="$(parse_install_mode_flag "$@")"
  export_resolved_route_env "$tool" "$route_mode"
  export_resolved_install_env "$tool" "$install_mode"
  print_route_resolution_summary
  print_install_mode_summary
  run_windows_launcher "$tool" "$route_mode" "$install_mode"
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
