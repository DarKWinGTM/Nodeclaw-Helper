#!/usr/bin/env bash
set -euo pipefail

NODECLAW_GEMINI_BASE_URL="${NODECLAW_GEMINI_BASE_URL:-https://payg.nodenetwork.ovh}"
NODECLAW_API_KEY_VALUE="${NODECLAW_API_KEY:-${GEMINI_API_KEY:-}}"
NODECLAW_GEMINI_ENV_PATH="${NODECLAW_GEMINI_ENV_PATH:-$HOME/.gemini/nodeclaw-gemini-env.sh}"
NODECLAW_GEMINI_PROFILE_PATH="${NODECLAW_GEMINI_PROFILE_PATH:-}"
NODECLAW_INSTALL_MODE="${NODECLAW_INSTALL_MODE:-auto}"
NODECLAW_INTERACTIVE="${NODECLAW_INTERACTIVE:-auto}"
NODECLAW_PROMPTED_API_KEY="${NODECLAW_PROMPTED_API_KEY:-}"
HELPER_CAPABILITY='env-default'
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_INSTALL_MODE="auto|env|persistent" NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-gemini-cli-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

resolve_install_mode() {
  local requested="$1"
  local capability="$2"

  case "$requested" in
    env)
      if [ "$capability" = 'persistent-primary' ]; then
        printf 'persistent\n'
      else
        printf 'env\n'
      fi
      return
      ;;
    persistent)
      printf 'persistent\n'
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

prompt_nodeclaw_api_key_if_needed() {
  if [ -n "$NODECLAW_API_KEY_VALUE" ]; then
    return 0
  fi

  if ! helper_allows_prompt; then
    printf 'NODECLAW_API_KEY or GEMINI_API_KEY is required for apply. Re-run interactively or export NODECLAW_API_KEY first.
' >&2
    exit 1
  fi

  print_prompt_message 'Enter NodeClaw API key: '
  if ! read_prompt_value NODECLAW_API_KEY_VALUE || [ -z "$NODECLAW_API_KEY_VALUE" ]; then
    printf 'NODECLAW_API_KEY cannot be empty.\n' >&2
    exit 1
  fi

  NODECLAW_API_KEY="$NODECLAW_API_KEY_VALUE"
  GEMINI_API_KEY="$NODECLAW_API_KEY_VALUE"
  NODECLAW_PROMPTED_API_KEY='true'
  export NODECLAW_API_KEY GEMINI_API_KEY NODECLAW_PROMPTED_API_KEY
}

shell_quote_value() {
  local value="${1-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$/\\\$}"
  value="${value//\`/\\\`}"
  printf '"%s"' "$value"
}

render_export_line() {
  local name="$1"
  local value="$2"
  printf 'export %s=%s\n' "$name" "$(shell_quote_value "$value")"
}

resolve_profile_path() {
  if [ -n "$NODECLAW_GEMINI_PROFILE_PATH" ]; then
    printf '%s\n' "$NODECLAW_GEMINI_PROFILE_PATH"
    return
  fi

  case "$(basename "${SHELL:-bash}")" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash|sh|*)
      printf '%s\n' "$HOME/.bashrc"
      ;;
  esac
}

render_session_env_exports() {
  local api_key="$1"

  render_export_line 'GOOGLE_GEMINI_BASE_URL' "$NODECLAW_GEMINI_BASE_URL"
  render_export_line 'GEMINI_API_KEY' "$api_key"
}

render_env_file() {
  render_session_env_exports "$1"
}

render_profile_block() {
  cat <<EOF
$MANAGED_BLOCK_START
$SOURCE_LINE
$MANAGED_BLOCK_END
EOF
}

RESOLVED_INSTALL_MODE="$(resolve_install_mode "$NODECLAW_INSTALL_MODE" "$HELPER_CAPABILITY")"
PROFILE_PATH="$(resolve_profile_path)"
ENV_DIR="$(dirname "$NODECLAW_GEMINI_ENV_PATH")"
MANAGED_BLOCK_START='# >>> NodeClaw Gemini CLI >>>'
MANAGED_BLOCK_END='# <<< NodeClaw Gemini CLI <<<'
SOURCE_LINE="[ -f \"$NODECLAW_GEMINI_ENV_PATH\" ] && . \"$NODECLAW_GEMINI_ENV_PATH\""

printf 'Target Gemini CLI posture: env-first / helper-guided custom endpoint\n'
printf 'Capability class: %s\n' "$HELPER_CAPABILITY"
printf 'Requested install mode: %s\n' "$NODECLAW_INSTALL_MODE"
printf 'Install mode: %s\n' "$RESOLVED_INSTALL_MODE"
printf 'Custom endpoint root: %s\n' "$NODECLAW_GEMINI_BASE_URL"
printf 'Managed env snippet: %s\n' "$NODECLAW_GEMINI_ENV_PATH"
printf 'Target shell profile: %s\n' "$PROFILE_PATH"
printf '\n'

if [ "$RESOLVED_INSTALL_MODE" = 'env' ]; then
  if [ "$DRY_RUN" = true ]; then
    printf 'Dry run only. Planned Gemini CLI session env exports:\n\n'
    render_session_env_exports '<nodeclaw_access_key>'
    printf '\nVerification notes:\n'
    printf '  - Gemini should authenticate through the gemini-api-key path.\n'
    printf '  - Requests should reach the custom endpoint root and then follow the Gemini-shaped route family under v1beta.\n'
    printf '  - Model entitlement failures do not mean the endpoint path is wrong.\n'
    exit 0
  fi

  prompt_nodeclaw_api_key_if_needed
  render_session_env_exports "$NODECLAW_API_KEY_VALUE"
  printf 'Run this in the current shell or save it into your profile by choice.\n'
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  printf 'Dry run only. Planned Gemini CLI persistent helper output:\n\n'
  printf '1. Helper-managed env snippet:\n\n'
  render_env_file '<nodeclaw_access_key>'
  printf '\n2. Helper-managed shell profile block:\n\n'
  render_profile_block
  printf '\n3. Immediate session usage after writing the snippet:\n\n'
  printf 'source "%s"\n' "$NODECLAW_GEMINI_ENV_PATH"
  printf 'gemini\n'
  printf '\n4. Verification notes:\n'
  printf '   - Gemini should authenticate through the gemini-api-key path.\n'
  printf '   - Requests should reach the custom endpoint root and then follow the Gemini-shaped route family under v1beta.\n'
  printf '   - Model entitlement failures do not mean the endpoint path is wrong.\n'
  exit 0
fi

prompt_nodeclaw_api_key_if_needed

mkdir -p "$ENV_DIR"
render_env_file "$NODECLAW_API_KEY_VALUE" > "$NODECLAW_GEMINI_ENV_PATH"
chmod 600 "$NODECLAW_GEMINI_ENV_PATH" 2>/dev/null || true

if [ -f "$PROFILE_PATH" ]; then
  if ! grep -Fq "$MANAGED_BLOCK_START" "$PROFILE_PATH"; then
    {
      printf '\n'
      render_profile_block
      printf '\n'
    } >> "$PROFILE_PATH"
  fi
else
  {
    render_profile_block
    printf '\n'
  } > "$PROFILE_PATH"
fi

printf 'Wrote Gemini helper env snippet to %s\n' "$NODECLAW_GEMINI_ENV_PATH"
printf 'Ensured shell profile sources it from %s\n' "$PROFILE_PATH"
printf '\nUse one of these to activate it now:\n'
printf '  source "%s"\n' "$NODECLAW_GEMINI_ENV_PATH"
printf '  . "%s"\n' "$PROFILE_PATH"
printf '\nThen launch Gemini normally:\n'
printf '  gemini\n'
printf '\nVerification reminder:\n'
printf '  - If Gemini reaches the endpoint but fails on model entitlement, re-check the model/account before changing the endpoint root.\n'
