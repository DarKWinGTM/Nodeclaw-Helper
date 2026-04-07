#!/usr/bin/env bash
set -euo pipefail

NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
NODECLAW_PROVIDER_ID="${NODECLAW_PROVIDER_ID:-nodeclaw}"
NODECLAW_COMPATIBILITY="${NODECLAW_COMPATIBILITY:-openai}"
OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-loopback}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-openclaw-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

if ! command -v openclaw >/dev/null 2>&1; then
  printf 'openclaw command not found. Install OpenClaw first from the official docs, then rerun this script.\n' >&2
  exit 1
fi

if [ -z "$NODECLAW_API_KEY" ]; then
  printf 'Set NODECLAW_API_KEY before running this script.\n' >&2
  printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-openclaw-nodeclaw.sh\n' >&2
  exit 1
fi

if [ "$NODECLAW_COMPATIBILITY" != "openai" ] && [ "$NODECLAW_COMPATIBILITY" != "anthropic" ]; then
  printf 'NODECLAW_COMPATIBILITY must be either openai or anthropic.\n' >&2
  exit 1
fi

onboard_cmd=(
  openclaw onboard
  --non-interactive
  --mode local
  --auth-choice custom-api-key
  --custom-base-url "$NODECLAW_BASE_URL"
  --custom-model-id "$NODECLAW_MODEL_ID"
  --custom-api-key "$NODECLAW_API_KEY"
  --custom-provider-id "$NODECLAW_PROVIDER_ID"
  --custom-compatibility "$NODECLAW_COMPATIBILITY"
  --gateway-port "$OPENCLAW_GATEWAY_PORT"
  --gateway-bind "$OPENCLAW_GATEWAY_BIND"
)

if [ "$DRY_RUN" = true ]; then
  printf 'Dry run only. Planned OpenClaw command:\n\n'
  printf '  %q' "${onboard_cmd[@]}"
  printf '\n\nThen run:\n'
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
