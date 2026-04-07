#!/usr/bin/env bash
set -euo pipefail

ZED_SETTINGS_PATH="${ZED_SETTINGS_PATH:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
NODECLAW_MODEL_DISPLAY_NAME="${NODECLAW_MODEL_DISPLAY_NAME:-NodeClaw GPT-5.4}"
NODECLAW_MAX_TOKENS="${NODECLAW_MAX_TOKENS:-128000}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: ZED_SETTINGS_PATH="<path-to-zed-settings.json>" bash ./script/setup-zed-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

if [ -z "$ZED_SETTINGS_PATH" ]; then
  printf 'Set ZED_SETTINGS_PATH before running this script. Use Zed Command Palette > zed: open settings file to get the active settings path.\n' >&2
  printf 'Example: ZED_SETTINGS_PATH="<path-to-zed-settings.json>" bash ./script/setup-zed-nodeclaw.sh --dry-run\n' >&2
  exit 1
fi

python3 - <<'PY' "$ZED_SETTINGS_PATH" "$NODECLAW_BASE_URL" "$NODECLAW_MODEL_ID" "$NODECLAW_MODEL_DISPLAY_NAME" "$NODECLAW_MAX_TOKENS" "$DRY_RUN"
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1]).expanduser()
base_url = sys.argv[2]
model_id = sys.argv[3]
display_name = sys.argv[4]
max_tokens = int(sys.argv[5])
dry_run = sys.argv[6].lower() == 'true'

if settings_path.exists():
    raw = settings_path.read_text(encoding='utf-8').strip()
    data = json.loads(raw) if raw else {}
else:
    data = {}

language_models = data.setdefault('language_models', {})
openai_compatible = language_models.setdefault('openai_compatible', {})
nodeclaw = openai_compatible.setdefault('NodeClaw', {})
nodeclaw['api_url'] = base_url
available_models = nodeclaw.setdefault('available_models', [])

if not isinstance(available_models, list):
    raise SystemExit('Existing NodeClaw available_models value is not a list; inspect the target settings file manually first.')

matching_model = None
for item in available_models:
    if isinstance(item, dict) and item.get('name') == model_id:
        matching_model = item
        break

if matching_model is None:
    matching_model = {'name': model_id}
    available_models.append(matching_model)

matching_model['name'] = model_id
matching_model['display_name'] = display_name
matching_model['max_tokens'] = max_tokens

rendered = json.dumps(data, indent=2, ensure_ascii=False)

print(f'Target Zed settings: {settings_path}')

if dry_run:
    print('\nDry run only. Planned Zed settings:\n')
    print(rendered)
else:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(rendered + '\n', encoding='utf-8')
    print(f'\nWrote Zed settings to {settings_path}')
PY
