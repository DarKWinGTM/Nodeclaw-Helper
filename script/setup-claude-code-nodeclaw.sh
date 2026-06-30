#!/usr/bin/env bash
set -euo pipefail

SETTINGS_PATH="${CLAUDE_CODE_SETTINGS_PATH:-$HOME/.claude/settings.json}"
NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh}"
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
      printf 'Usage: NODECLAW_INSTALL_MODE="auto|env|persistent" NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-claude-code-nodeclaw.sh [--dry-run]\n' >&2
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

RESOLVED_INSTALL_MODE="$(resolve_install_mode "$NODECLAW_INSTALL_MODE" "$HELPER_CAPABILITY")"

printf 'Target Claude Code posture: env-first session contract\n'
printf 'Capability class: %s\n' "$HELPER_CAPABILITY"
printf 'Requested install mode: %s\n' "$NODECLAW_INSTALL_MODE"
printf 'Install mode: %s\n' "$RESOLVED_INSTALL_MODE"
printf 'Endpoint root: %s\n' "$NODECLAW_BASE_URL"
printf '\n'

if [ "$RESOLVED_INSTALL_MODE" = 'env' ]; then
  if [ "$DRY_RUN" = true ]; then
    printf 'Dry run only. Planned session env exports:\n\n'
    render_export_line 'NODECLAW_API_KEY' '<nodeclaw_access_key>'
    render_export_line 'ANTHROPIC_BASE_URL' "$NODECLAW_BASE_URL"
    printf 'export ANTHROPIC_AUTH_TOKEN="$NODECLAW_API_KEY"\n'
    exit 0
  fi

  prompt_nodeclaw_api_key_if_needed
  render_export_line 'NODECLAW_API_KEY' "$NODECLAW_API_KEY"
  render_export_line 'ANTHROPIC_BASE_URL' "$NODECLAW_BASE_URL"
  printf 'export ANTHROPIC_AUTH_TOKEN="$NODECLAW_API_KEY"\n'
  printf 'Run this in the current shell or save it into your profile by choice.\n'
  exit 0
fi

PREVIEW_API_KEY='<nodeclaw_access_key>'
if [ "$DRY_RUN" != true ]; then
  prompt_nodeclaw_api_key_if_needed
  PREVIEW_API_KEY="$NODECLAW_API_KEY"
fi

python3 - <<'PY' "$SETTINGS_PATH" "$PREVIEW_API_KEY" "$NODECLAW_BASE_URL" "$DRY_RUN"
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
