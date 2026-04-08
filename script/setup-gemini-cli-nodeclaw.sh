#!/usr/bin/env bash
set -euo pipefail

NODECLAW_GEMINI_BASE_URL="${NODECLAW_GEMINI_BASE_URL:-https://payg.nodenetwork.ovh/v1beta}"
NODECLAW_AUTH_HEADER="${NODECLAW_AUTH_HEADER:-Authorization: Bearer <nodeclaw_access_key>}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: bash ./script/setup-gemini-cli-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

cat <<EOF
Target Gemini CLI posture: manual-first / gateway-capable
Checked Google / Gemini-shaped base URL: $NODECLAW_GEMINI_BASE_URL
Checked auth header shape: $NODECLAW_AUTH_HEADER
EOF

cat <<'EOF'

Dry run only. Checked Gemini CLI gateway contract:

1. Install Gemini CLI from the official upstream path first.
2. Use Gemini CLI in ACP mode when you need the strongest checked custom-endpoint path:
   gemini --acp
3. Authenticate with ACP methodId = "gateway" and send gateway metadata like:

{
  "methodId": "gateway",
  "_meta": {
    "gateway": {
      "baseUrl": "https://payg.nodenetwork.ovh/v1beta",
      "headers": {
        "Authorization": "Bearer <nodeclaw_access_key>"
      }
    }
  }
}

4. Optional shell helpers when your bridge needs explicit header shaping:
   export GEMINI_API_KEY_AUTH_MECHANISM="bearer"
   export GEMINI_CLI_CUSTOM_HEADERS="Authorization:Bearer <nodeclaw_access_key>"

No helper-managed apply path exists for Gemini CLI in the current checked scope.
EOF

if [ "$DRY_RUN" = false ]; then
  printf '\nGemini CLI remains manual-first / gateway-capable only. No apply path is implemented.\n' >&2
  exit 1
fi
