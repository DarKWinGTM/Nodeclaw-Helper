#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${OPENCODE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json}"
NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-opencode-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

if [ -z "$NODECLAW_API_KEY" ]; then
  printf 'Set NODECLAW_API_KEY before running this script.\n' >&2
  printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-opencode-nodeclaw.sh --dry-run\n' >&2
  exit 1
fi

cat <<EOF
Target OpenCode config: $CONFIG_PATH
NodeClaw provider name: nodeclaw
Base URL: $NODECLAW_BASE_URL
Model: nodeclaw/$NODECLAW_MODEL_ID
EOF

python3 - <<'PY' "$CONFIG_PATH" "$NODECLAW_API_KEY" "$NODECLAW_BASE_URL" "$NODECLAW_MODEL_ID" "$DRY_RUN"
import json
import os
import pathlib
import sys

config_path = pathlib.Path(sys.argv[1]).expanduser()
api_key = sys.argv[2]
base_url = sys.argv[3]
model_id = sys.argv[4]
dry_run = sys.argv[5].lower() == 'true'

if config_path.exists():
    raw = config_path.read_text(encoding='utf-8').strip()
    data = json.loads(raw) if raw else {}
else:
    data = {}

provider = data.setdefault('provider', {})
nodeclaw = provider.setdefault('nodeclaw', {})
nodeclaw['name'] = 'NodeClaw'
options = nodeclaw.setdefault('options', {})
options['baseURL'] = base_url
options['apiKey'] = api_key
models = nodeclaw.setdefault('models', {})
models[model_id] = {'name': model_id}
data['model'] = f'nodeclaw/{model_id}'

rendered = json.dumps(data, indent=2, ensure_ascii=False)

if dry_run:
    print('\nDry run only. Planned OpenCode config:\n')
    print(rendered)
else:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(rendered + '\n', encoding='utf-8')
    print(f'\nWrote OpenCode config to {config_path}')
PY
