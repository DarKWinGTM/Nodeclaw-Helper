#!/usr/bin/env bash
set -euo pipefail

SETTINGS_PATH="${CLAUDE_CODE_SETTINGS_PATH:-$HOME/.claude/settings.json}"
NODECLAW_API_KEY="${NODECLAW_API_KEY:-}"
NODECLAW_BASE_URL="${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-claude-code-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

if [ -z "$NODECLAW_API_KEY" ]; then
  printf 'Set NODECLAW_API_KEY before running this script.\n' >&2
  printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-claude-code-nodeclaw.sh --dry-run\n' >&2
  exit 1
fi

python3 - <<'PY' "$SETTINGS_PATH" "$NODECLAW_API_KEY" "$NODECLAW_BASE_URL" "$DRY_RUN"
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
