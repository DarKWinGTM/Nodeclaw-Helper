#!/usr/bin/env bash
set -euo pipefail

NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
NODECLAW_PROVIDER_ID="${NODECLAW_PROVIDER_ID:-nodeclaw}"
NODECLAW_COMPATIBILITY="${NODECLAW_COMPATIBILITY:-openai}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-loopback}"
NODECLAW_INSTALL_MODE="${NODECLAW_INSTALL_MODE:-auto}"
NODECLAW_INTERACTIVE="${NODECLAW_INTERACTIVE:-auto}"
NODECLAW_PROMPTED_API_KEY="${NODECLAW_PROMPTED_API_KEY:-}"
HELPER_CAPABILITY='persistent-primary'
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_INSTALL_MODE="auto|env|persistent" NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-openclaw-nodeclaw.sh [--dry-run]\n' >&2
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

helper_allows_prompt() {
  case "$NODECLAW_INTERACTIVE" in
    true|TRUE|1|yes|YES)
      return 0
      ;;
    false|FALSE|0|no|NO)
      return 1
      ;;
    auto|'')
      [ -t 0 ]
      ;;
    *)
      printf 'NODECLAW_INTERACTIVE must be auto, true, or false.\n' >&2
      exit 1
      ;;
  esac
}

prompt_nodeclaw_api_key_if_needed() {
  if [ -n "$NODECLAW_API_KEY" ]; then
    return 0
  fi

  if ! helper_allows_prompt; then
    printf 'NODECLAW_API_KEY is required for apply. Re-run interactively or export NODECLAW_API_KEY first.\n' >&2
    exit 1
  fi

  printf 'Enter NodeClaw API key: ' >&2
  IFS= read -r NODECLAW_API_KEY
  if [ -z "$NODECLAW_API_KEY" ]; then
    printf 'NODECLAW_API_KEY cannot be empty.\n' >&2
    exit 1
  fi

  NODECLAW_PROMPTED_API_KEY='true'
  export NODECLAW_API_KEY NODECLAW_PROMPTED_API_KEY
}

if [ "$NODECLAW_COMPATIBILITY" != "openai" ] && [ "$NODECLAW_COMPATIBILITY" != "anthropic" ]; then
  printf 'NODECLAW_COMPATIBILITY must be either openai or anthropic.\n' >&2
  exit 1
fi

RESOLVED_INSTALL_MODE="$(resolve_install_mode "$NODECLAW_INSTALL_MODE" "$HELPER_CAPABILITY")"
LOCAL_PREVIEW_KEY='<nodeclaw_access_key>'
if [ "$DRY_RUN" != true ]; then
  if ! command -v openclaw >/dev/null 2>&1; then
    printf 'openclaw command not found. Install OpenClaw first or rerun in --dry-run mode.\n' >&2
    exit 1
  fi
  prompt_nodeclaw_api_key_if_needed
  LOCAL_PREVIEW_KEY="$NODECLAW_API_KEY"
fi

onboard_cmd=(
  openclaw onboard
  --non-interactive
  --mode local
  --auth-choice custom-api-key
  --custom-base-url "$NODECLAW_BASE_URL"
  --custom-model-id "$NODECLAW_MODEL_ID"
  --custom-api-key "$LOCAL_PREVIEW_KEY"
  --custom-provider-id "$NODECLAW_PROVIDER_ID"
  --custom-compatibility "$NODECLAW_COMPATIBILITY"
  --gateway-port "$OPENCLAW_GATEWAY_PORT"
  --gateway-bind "$OPENCLAW_GATEWAY_BIND"
)

printf 'Target OpenClaw posture: persistent-primary onboarding owner\n'
printf 'Capability class: %s\n' "$HELPER_CAPABILITY"
printf 'Requested install mode: %s\n' "$NODECLAW_INSTALL_MODE"
printf 'Install mode: %s\n' "$RESOLVED_INSTALL_MODE"
printf 'Base URL: %s\n' "$NODECLAW_BASE_URL"
printf 'Model: %s\n' "$NODECLAW_MODEL_ID"
printf 'Compatibility: %s\n' "$NODECLAW_COMPATIBILITY"
printf '\n'

if [ "$DRY_RUN" = true ]; then
  printf 'Dry run only. Planned OpenClaw command:\n\n'
  printf '  %q' "${onboard_cmd[@]}"
  printf '\n\nRedacted secret argument: --custom-api-key <nodeclaw_access_key>\n'
  printf '\nThen run:\n'
  printf '  openclaw config file\n'
  printf '  openclaw config validate --json\n'
  exit 0
fi

"${onboard_cmd[@]}"

printf '\nConfigured OpenClaw custom provider %s -> %s (%s, %s).\n' \
  "$NODECLAW_PROVIDER_ID" \
  "$NODECLAW_BASE_URL" \
  "$NODECLAW_MODEL_ID" \
  "$NODECLAW_COMPATIBILITY"

printf 'Active OpenClaw config file:\n'
openclaw config file

printf '\nConfig validation:\n'
openclaw config validate --json
