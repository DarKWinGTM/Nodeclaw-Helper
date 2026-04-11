#!/usr/bin/env bash
set -euo pipefail

NODECLAW_GEMINI_BASE_URL="${NODECLAW_GEMINI_BASE_URL:-https://payg.nodenetwork.ovh}"
NODECLAW_API_KEY_VALUE="${NODECLAW_API_KEY:-${GEMINI_API_KEY:-}}"
NODECLAW_GEMINI_ENV_PATH="${NODECLAW_GEMINI_ENV_PATH:-$HOME/.gemini/nodeclaw-gemini-env.sh}"
NODECLAW_GEMINI_PROFILE_PATH="${NODECLAW_GEMINI_PROFILE_PATH:-}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-gemini-cli-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

resolve_profile_path() {
  if [ -n "$NODECLAW_GEMINI_PROFILE_PATH" ]; then
    printf '%s\n' "$NODECLAW_GEMINI_PROFILE_PATH"
    return
  fi

  case "$(basename "${SHELL:-bash}")" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash|sh|*)
      printf '%s\n' "$HOME/.bashrc"
      ;;
  esac
}

PROFILE_PATH="$(resolve_profile_path)"
ENV_DIR="$(dirname "$NODECLAW_GEMINI_ENV_PATH")"
MANAGED_BLOCK_START='# >>> NodeClaw Gemini CLI >>>'
MANAGED_BLOCK_END='# <<< NodeClaw Gemini CLI <<<'
SOURCE_LINE="[ -f \"$NODECLAW_GEMINI_ENV_PATH\" ] && . \"$NODECLAW_GEMINI_ENV_PATH\""

render_env_file() {
  cat <<EOF
export GOOGLE_GEMINI_BASE_URL="$NODECLAW_GEMINI_BASE_URL"
export GEMINI_API_KEY="$1"
EOF
}

render_profile_block() {
  cat <<EOF
$MANAGED_BLOCK_START
$SOURCE_LINE
$MANAGED_BLOCK_END
EOF
}

printf 'Target Gemini CLI posture: env-first / helper-guided custom endpoint\n'
printf 'Custom endpoint root: %s\n' "$NODECLAW_GEMINI_BASE_URL"
printf 'Managed env snippet: %s\n' "$NODECLAW_GEMINI_ENV_PATH"
printf 'Target shell profile: %s\n' "$PROFILE_PATH"
printf '\n'

if [ "$DRY_RUN" = true ]; then
  printf 'Dry run only. Planned Gemini CLI helper output:\n\n'
  printf '1. Helper-managed env snippet:\n\n'
  render_env_file '<nodeclaw_access_key>'
  printf '\n2. Helper-managed shell profile block:\n\n'
  render_profile_block
  printf '\n3. Immediate session usage after writing the snippet:\n\n'
  printf 'source "%s"\n' "$NODECLAW_GEMINI_ENV_PATH"
  printf 'gemini\n'
  printf '\n4. Verification notes:\n'
  printf '   - Gemini should authenticate through the gemini-api-key path.\n'
  printf '   - Requests should reach the custom endpoint root and then follow the Gemini-shaped route family under v1beta.\n'
  printf '   - Model entitlement failures do not mean the endpoint path is wrong.\n'
  exit 0
fi

if [ -z "$NODECLAW_API_KEY_VALUE" ]; then
  printf 'Set NODECLAW_API_KEY (or GEMINI_API_KEY) before running apply.\n' >&2
  printf 'Example: NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-gemini-cli-nodeclaw.sh\n' >&2
  exit 1
fi

mkdir -p "$ENV_DIR"
render_env_file "$NODECLAW_API_KEY_VALUE" > "$NODECLAW_GEMINI_ENV_PATH"
chmod 600 "$NODECLAW_GEMINI_ENV_PATH" 2>/dev/null || true

if [ -f "$PROFILE_PATH" ]; then
  if ! grep -Fq "$MANAGED_BLOCK_START" "$PROFILE_PATH"; then
    {
      printf '\n'
      render_profile_block
      printf '\n'
    } >> "$PROFILE_PATH"
  fi
else
  {
    render_profile_block
    printf '\n'
  } > "$PROFILE_PATH"
fi

printf 'Wrote Gemini helper env snippet to %s\n' "$NODECLAW_GEMINI_ENV_PATH"
printf 'Ensured shell profile sources it from %s\n' "$PROFILE_PATH"
printf '\nUse one of these to activate it now:\n'
printf '  source "%s"\n' "$NODECLAW_GEMINI_ENV_PATH"
printf '  . "%s"\n' "$PROFILE_PATH"
printf '\nThen launch Gemini normally:\n'
printf '  gemini\n'
printf '\nVerification reminder:\n'
printf '  - If Gemini reaches the endpoint but fails on model entitlement, re-check the model/account before changing the endpoint root.\n'
