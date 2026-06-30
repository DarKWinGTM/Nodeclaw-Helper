#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${CODEX_CONFIG_PATH:-$HOME/.codex/config.toml}"
NODECLAW_API_KEY="${NODECLAW_API_KEY:-${OPENAI_API_KEY:-}}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
NODECLAW_PROVIDER_ID="${NODECLAW_PROVIDER_ID:-nodeclaw}"
CODEX_PROVIDER_MODE="${CODEX_PROVIDER_MODE:-simple}"
NODECLAW_INSTALL_MODE="${NODECLAW_INSTALL_MODE:-auto}"
NODECLAW_INTERACTIVE="${NODECLAW_INTERACTIVE:-auto}"
NODECLAW_PROMPTED_API_KEY="${NODECLAW_PROMPTED_API_KEY:-}"
HELPER_CAPABILITY='hybrid'
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_INSTALL_MODE="auto|env|persistent" bash ./script/setup-codex-nodeclaw.sh [--dry-run]\n' >&2
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
    printf 'NODECLAW_API_KEY or OPENAI_API_KEY is required to print an apply-ready Codex auth export. Re-run interactively or export NODECLAW_API_KEY first.\n' >&2
    exit 1
  fi

  printf 'Enter NodeClaw API key: ' >&2
  IFS= read -r NODECLAW_API_KEY
  if [ -z "$NODECLAW_API_KEY" ]; then
    printf 'NODECLAW_API_KEY cannot be empty.\n' >&2
    exit 1
  fi

  OPENAI_API_KEY="$NODECLAW_API_KEY"
  NODECLAW_PROMPTED_API_KEY='true'
  export NODECLAW_API_KEY OPENAI_API_KEY NODECLAW_PROMPTED_API_KEY
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

if [ "$CODEX_PROVIDER_MODE" != "simple" ] && [ "$CODEX_PROVIDER_MODE" != "custom-provider" ]; then
  printf 'CODEX_PROVIDER_MODE must be either simple or custom-provider.\n' >&2
  exit 1
fi

RESOLVED_INSTALL_MODE="$(resolve_install_mode "$NODECLAW_INSTALL_MODE" "$HELPER_CAPABILITY")"
PREVIEW_API_KEY='<nodeclaw_access_key>'

printf 'Target Codex posture: hybrid env auth plus config wiring\n'
printf 'Capability class: %s\n' "$HELPER_CAPABILITY"
printf 'Requested install mode: %s\n' "$NODECLAW_INSTALL_MODE"
printf 'Install mode: %s\n' "$RESOLVED_INSTALL_MODE"
printf 'Auth env: OPENAI_API_KEY\n'
if [ "$DRY_RUN" = true ]; then
  printf 'Preview auth export: '
  render_export_line 'OPENAI_API_KEY' "$PREVIEW_API_KEY"
elif [ "$RESOLVED_INSTALL_MODE" = 'env' ]; then
  prompt_nodeclaw_api_key_if_needed
  printf 'Session auth export: '
  render_export_line 'OPENAI_API_KEY' "$NODECLAW_API_KEY"
else
  printf 'Auth remains env-owned; set OPENAI_API_KEY before running Codex.\n'
fi
printf '\n'

python3 - <<'PY' "$CONFIG_PATH" "$NODECLAW_BASE_URL" "$NODECLAW_MODEL_ID" "$NODECLAW_PROVIDER_ID" "$CODEX_PROVIDER_MODE" "$DRY_RUN"
import pathlib
import sys
import tomllib
import tomli_w

config_path = pathlib.Path(sys.argv[1]).expanduser()
base_url = sys.argv[2]
model_id = sys.argv[3]
provider_id = sys.argv[4]
provider_mode = sys.argv[5]
dry_run = sys.argv[6].lower() == 'true'

if config_path.exists():
    raw = config_path.read_text(encoding='utf-8').strip()
    data = tomllib.loads(raw) if raw else {}
else:
    data = {}

if not isinstance(data, dict):
    raise SystemExit('Existing Codex config is not a TOML table; inspect the target config manually first.')

data['model'] = model_id

if provider_mode == 'simple':
    data['openai_base_url'] = base_url
    data.pop('model_provider', None)
else:
    data['model_provider'] = provider_id

model_providers = data.setdefault('model_providers', {})
if provider_mode == 'custom-provider':
    provider = model_providers.setdefault(provider_id, {})
    provider['name'] = 'NodeClaw'
    provider['base_url'] = base_url
    provider['env_key'] = 'OPENAI_API_KEY'
    provider['wire_api'] = 'responses'

rendered = tomli_w.dumps(data)

print(f'Target Codex config: {config_path}')
print(f'Provider mode: {provider_mode}')
print(f'Base URL: {base_url}')
print(f'Model: {model_id}')
print('Auth env: OPENAI_API_KEY')

if dry_run:
    print('\nDry run only. Planned Codex config:\n')
    print(rendered)
else:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(rendered, encoding='utf-8')
    print(f'\nWrote Codex config to {config_path}')
PY
