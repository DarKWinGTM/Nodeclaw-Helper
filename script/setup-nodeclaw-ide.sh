#!/usr/bin/env bash
set -euo pipefail

TOOL=""
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: bash ./script/setup-nodeclaw-ide.sh --tool <claude-code|codex|openclaw|opencode|zed> [--dry-run]

Supported tools:
  claude-code
  codex
  openclaw
  opencode
  zed

This script is standalone so it can be used either from the repo or via a hosted curl | bash flow later.
EOF
}

require_python3() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 is required for this setup path but was not found in PATH.\n' >&2
    exit 1
  fi
}

run_claude_code() {
  local settings_path="${CLAUDE_CODE_SETTINGS_PATH:-$HOME/.claude/settings.json}"
  local api_key="${NODECLAW_API_KEY:-}"
  local base_url="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"

  if [ -z "$api_key" ]; then
    printf 'Set NODECLAW_API_KEY before running the Claude Code setup path.\n' >&2
    printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-nodeclaw-ide.sh --tool claude-code --dry-run\n' >&2
    exit 1
  fi

  require_python3

  python3 - <<'PY' "$settings_path" "$api_key" "$base_url" "$DRY_RUN"
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1]).expanduser()
api_key = sys.argv[2]
base_url = sys.argv[3]
dry_run = sys.argv[4].lower() == 'true'

if settings_path.exists():
    raw = settings_path.read_text(encoding='utf-8').strip()
    data = json.loads(raw) if raw else {}
else:
    data = {}

env = data.setdefault('env', {})
env['ANTHROPIC_BASE_URL'] = base_url
env['ANTHROPIC_AUTH_TOKEN'] = api_key
env.setdefault('CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS', '1')
env.setdefault('DISABLE_INTERLEAVED_THINKING', '1')

rendered = json.dumps(data, indent=2, ensure_ascii=False)

print(f'Target Claude Code settings: {settings_path}')

if dry_run:
    print('\nDry run only. Planned Claude Code settings:\n')
    print(rendered)
else:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(rendered + '\n', encoding='utf-8')
    print(f'\nWrote Claude Code settings to {settings_path}')
PY
}

run_codex() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local cmd=(bash "$script_dir/setup-codex-nodeclaw.sh")

  if [ "$DRY_RUN" = true ]; then
    cmd+=(--dry-run)
  fi

  "${cmd[@]}"
}

run_opencode() {
  local config_path="${OPENCODE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json}"
  local api_key="${NODECLAW_API_KEY:-}"
  local base_url="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
  local model_id="${NODECLAW_MODEL_ID:-gpt-5.4}"

  if [ -z "$api_key" ]; then
    printf 'Set NODECLAW_API_KEY before running the OpenCode setup path.\n' >&2
    printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-nodeclaw-ide.sh --tool opencode --dry-run\n' >&2
    exit 1
  fi

  require_python3

  python3 - <<'PY' "$config_path" "$api_key" "$base_url" "$model_id" "$DRY_RUN"
import json
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

print(f'Target OpenCode config: {config_path}')

if dry_run:
    print('\nDry run only. Planned OpenCode config:\n')
    print(rendered)
else:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(rendered + '\n', encoding='utf-8')
    print(f'\nWrote OpenCode config to {config_path}')
PY
}

run_zed() {
  local settings_path="${ZED_SETTINGS_PATH:-}"
  local base_url="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
  local model_id="${NODECLAW_MODEL_ID:-gpt-5.4}"
  local display_name="${NODECLAW_MODEL_DISPLAY_NAME:-NodeClaw GPT-5.4}"
  local max_tokens="${NODECLAW_MAX_TOKENS:-128000}"

  if [ -z "$settings_path" ]; then
    printf 'Set ZED_SETTINGS_PATH before running the Zed setup path.\n' >&2
    printf 'Example: ZED_SETTINGS_PATH="<path-to-zed-settings.json>" bash ./script/setup-nodeclaw-ide.sh --tool zed --dry-run\n' >&2
    exit 1
  fi

  require_python3

  python3 - <<'PY' "$settings_path" "$base_url" "$model_id" "$display_name" "$max_tokens" "$DRY_RUN"
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
}

run_openclaw() {
  local api_key="${NODECLAW_API_KEY:-}"
  local base_url="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
  local model_id="${NODECLAW_MODEL_ID:-gpt-5.4}"
  local provider_id="${NODECLAW_PROVIDER_ID:-nodeclaw}"
  local compatibility="${NODECLAW_COMPATIBILITY:-openai}"
  local gateway_port="${OPENCLAW_GATEWAY_PORT:-18789}"
  local gateway_bind="${OPENCLAW_GATEWAY_BIND:-loopback}"

  if ! command -v openclaw >/dev/null 2>&1; then
    printf 'openclaw command not found. Install OpenClaw first from the official docs, then rerun this setup path.\n' >&2
    exit 1
  fi

  if [ -z "$api_key" ]; then
    printf 'Set NODECLAW_API_KEY before running the OpenClaw setup path.\n' >&2
    printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-nodeclaw-ide.sh --tool openclaw --dry-run\n' >&2
    exit 1
  fi

  if [ "$compatibility" != "openai" ] && [ "$compatibility" != "anthropic" ]; then
    printf 'NODECLAW_COMPATIBILITY must be either openai or anthropic.\n' >&2
    exit 1
  fi

  local onboard_cmd=(
    openclaw onboard
    --non-interactive
    --mode local
    --auth-choice custom-api-key
    --custom-base-url "$base_url"
    --custom-model-id "$model_id"
    --custom-api-key "$api_key"
    --custom-provider-id "$provider_id"
    --custom-compatibility "$compatibility"
    --gateway-port "$gateway_port"
    --gateway-bind "$gateway_bind"
  )

  if [ "$DRY_RUN" = true ]; then
    printf 'Dry run only. Planned OpenClaw command:\n\n'
    printf '  %q' "${onboard_cmd[@]}"
    printf '\n\nThen run:\n'
    printf '  openclaw config file\n'
    printf '  openclaw config validate --json\n'
    return 0
  fi

  "${onboard_cmd[@]}"

  printf '\nConfigured OpenClaw custom provider %s -> %s (%s, %s).\n' \
    "$provider_id" \
    "$base_url" \
    "$model_id" \
    "$compatibility"

  printf 'Active OpenClaw config file:\n'
  openclaw config file

  printf '\nConfig validation:\n'
  openclaw config validate --json
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)
      shift
      if [ $# -eq 0 ]; then
        printf '--tool requires a value.\n' >&2
        usage >&2
        exit 1
      fi
      TOOL="$1"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ -z "$TOOL" ]; then
  printf 'Set --tool to one of claude-code, codex, openclaw, opencode, or zed.\n' >&2
  usage >&2
  exit 1
fi

case "$TOOL" in
  claude-code)
    run_claude_code
    ;;
  codex)
    run_codex
    ;;
  openclaw)
    run_openclaw
    ;;
  opencode)
    run_opencode
    ;;
  zed)
    run_zed
    ;;
  *)
    printf 'Unsupported tool: %s\n' "$TOOL" >&2
    usage >&2
    exit 1
    ;;
esac
