#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${OPENCODE_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json}"
NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
NODECLAW_MODEL_ID="${NODECLAW_MODEL_ID:-gpt-5.4}"
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
      printf 'Usage: NODECLAW_INSTALL_MODE="auto|env|persistent" NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-opencode-nodeclaw.sh [--dry-run]\n' >&2
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

RESOLVED_INSTALL_MODE="$(resolve_install_mode "$NODECLAW_INSTALL_MODE" "$HELPER_CAPABILITY")"
if [ "$DRY_RUN" = true ]; then
  LOCAL_PREVIEW_KEY='<nodeclaw_access_key>'
else
  prompt_nodeclaw_api_key_if_needed
  LOCAL_PREVIEW_KEY="$NODECLAW_API_KEY"
fi

cat <<EOF
Target OpenCode config: $CONFIG_PATH
NodeClaw provider name: nodeclaw
Capability class: $HELPER_CAPABILITY
Requested install mode: $NODECLAW_INSTALL_MODE
Install mode: $RESOLVED_INSTALL_MODE
Base URL: $NODECLAW_BASE_URL
Model: nodeclaw/$NODECLAW_MODEL_ID
EOF

python3 - <<'PY' "$CONFIG_PATH" "$LOCAL_PREVIEW_KEY" "$NODECLAW_BASE_URL" "$NODECLAW_MODEL_ID" "$DRY_RUN"
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

if dry_run:
    print('\nDry run only. Planned OpenCode config:\n')
    print(rendered)
else:
    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text(rendered + '\n', encoding='utf-8')
    print(f'\nWrote OpenCode config to {config_path}')
PY
