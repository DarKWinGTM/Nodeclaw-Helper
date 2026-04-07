#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${CODEX_CONFIG_PATH:-$HOME/.codex/config.toml}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
NODECLAW_PROVIDER_ID="${NODECLAW_PROVIDER_ID:-nodeclaw}"
CODEX_PROVIDER_MODE="${CODEX_PROVIDER_MODE:-simple}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: bash ./script/setup-codex-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

if [ "$CODEX_PROVIDER_MODE" != "simple" ] && [ "$CODEX_PROVIDER_MODE" != "custom-provider" ]; then
  printf 'CODEX_PROVIDER_MODE must be either simple or custom-provider.\n' >&2
  exit 1
fi

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
