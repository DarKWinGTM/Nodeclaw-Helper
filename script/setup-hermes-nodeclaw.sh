#!/usr/bin/env bash
set -euo pipefail

HERMES_NODECLAW_PROFILE="${HERMES_NODECLAW_PROFILE:-nodeclaw-hermes}"
HERMES_NODECLAW_HOME="${HERMES_NODECLAW_HOME:-}"
HERMES_NODECLAW_BASE_URL="${HERMES_NODECLAW_BASE_URL:-${NODECLAW_BASE_URL:-https://payg.nodenetwork.ovh/v1}}"
HERMES_NODECLAW_API_KEY="${HERMES_NODECLAW_API_KEY:-${NODECLAW_API_KEY:-}}"
HERMES_NODECLAW_MODEL="${HERMES_NODECLAW_MODEL:-${NODECLAW_MODEL_ID:-gpt-5.4}}"
HERMES_NODECLAW_WORKDIR="${HERMES_NODECLAW_WORKDIR:-}"
HERMES_NODECLAW_CLONE_MODE="${HERMES_NODECLAW_CLONE_MODE:-fresh}"
HERMES_NODECLAW_CLONE_FROM="${HERMES_NODECLAW_CLONE_FROM:-}"
HERMES_NODECLAW_REWRITE_SOUL="${HERMES_NODECLAW_REWRITE_SOUL:-true}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      printf 'Unknown argument: %s\n' "$arg" >&2
      printf 'Usage: HERMES_NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-hermes-nodeclaw.sh [--dry-run]\n' >&2
      exit 1
      ;;
  esac
done

case "$HERMES_NODECLAW_CLONE_MODE" in
  fresh|clone|clone-all)
    ;;
  *)
    printf 'HERMES_NODECLAW_CLONE_MODE must be one of: fresh, clone, clone-all.\n' >&2
    exit 1
    ;;
esac

resolve_profile_home() {
  if [ -n "$HERMES_NODECLAW_HOME" ]; then
    printf '%s\n' "$HERMES_NODECLAW_HOME"
    return
  fi

  if [ "$HERMES_NODECLAW_PROFILE" = 'default' ]; then
    printf '%s\n' "$HOME/.hermes"
    return
  fi

  printf '%s\n' "$HOME/.hermes/profiles/$HERMES_NODECLAW_PROFILE"
}

PROFILE_HOME="$(resolve_profile_home)"
ENV_PATH="$PROFILE_HOME/.env"
CONFIG_PATH="$PROFILE_HOME/config.yaml"
SOUL_PATH="$PROFILE_HOME/SOUL.md"
IS_CUSTOM_HOME=false
if [ -n "$HERMES_NODECLAW_HOME" ]; then
  IS_CUSTOM_HOME=true
fi

render_env_file() {
  local api_key="$1"

  cat <<EOF
# NodeClaw-managed Hermes profile env
HERMES_NODECLAW_PROFILE=$HERMES_NODECLAW_PROFILE
HERMES_NODECLAW_BASE_URL=$HERMES_NODECLAW_BASE_URL
HERMES_NODECLAW_API_KEY=$api_key
HERMES_NODECLAW_MODEL=$HERMES_NODECLAW_MODEL
EOF

  if [ -n "$HERMES_NODECLAW_WORKDIR" ]; then
    cat <<EOF
HERMES_NODECLAW_WORKDIR=$HERMES_NODECLAW_WORKDIR
EOF
  fi
}

render_config_file() {
  cat <<'EOF'
# NodeClaw-managed Hermes profile config
model:
  default: "${HERMES_NODECLAW_MODEL}"
  provider: "custom"
  base_url: "${HERMES_NODECLAW_BASE_URL}"
  api_key: "${HERMES_NODECLAW_API_KEY}"
EOF

  if [ -n "$HERMES_NODECLAW_WORKDIR" ]; then
    cat <<'EOF'

terminal:
  backend: "local"
  cwd: "${HERMES_NODECLAW_WORKDIR}"
EOF
  fi
}

render_soul_file() {
  cat <<EOF
# NodeClaw Hermes Profile

You are the NodeClaw-backed Hermes additional runtime IDE agent profile.

## Role
- use the NodeClaw custom endpoint configured through the profile-local env/config contract
- keep secrets in \.env and non-secret route structure in config.yaml
- treat this profile as a dedicated NodeClaw helper-managed profile rather than a shared mutable Hermes home

## Boundary
- this is an additional runtime IDE agent path
- it is inventory-first and not a Home-promoted path by default
- keep service-specific compatibility translation outside the profile when a shim is required

## Managed contract
- profile: $HERMES_NODECLAW_PROFILE
- profile home: $PROFILE_HOME
- endpoint env: HERMES_NODECLAW_BASE_URL
- api key env: HERMES_NODECLAW_API_KEY
- model env: HERMES_NODECLAW_MODEL
EOF
}

show_verification_notes() {
  printf 'Verification reminders:\n'
  printf '  - hermes --profile=%q doctor\n' "$HERMES_NODECLAW_PROFILE"
  printf '  - hermes --profile=%q config\n' "$HERMES_NODECLAW_PROFILE"
  printf '  - hermes -p %q chat\n' "$HERMES_NODECLAW_PROFILE"
}

create_profile_if_needed() {
  if [ -d "$PROFILE_HOME" ]; then
    return
  fi

  if [ "$IS_CUSTOM_HOME" = true ] || [ "$HERMES_NODECLAW_PROFILE" = 'default' ]; then
    mkdir -p "$PROFILE_HOME"
    return
  fi

  if ! command -v hermes >/dev/null 2>&1; then
    printf 'hermes command not found. Install Hermes first or rerun in --dry-run mode.\n' >&2
    exit 1
  fi

  create_cmd=(hermes profile create "$HERMES_NODECLAW_PROFILE")
  case "$HERMES_NODECLAW_CLONE_MODE" in
    fresh)
      ;;
    clone)
      create_cmd+=(--clone)
      if [ -n "$HERMES_NODECLAW_CLONE_FROM" ]; then
        create_cmd+=(--clone-from "$HERMES_NODECLAW_CLONE_FROM")
      fi
      ;;
    clone-all)
      create_cmd+=(--clone-all)
      ;;
  esac

  "${create_cmd[@]}"
}

printf 'Target Hermes profile: %s\n' "$HERMES_NODECLAW_PROFILE"
printf 'Target Hermes home: %s\n' "$PROFILE_HOME"
printf 'Managed env file: %s\n' "$ENV_PATH"
printf 'Managed config file: %s\n' "$CONFIG_PATH"
printf 'Managed SOUL file: %s\n' "$SOUL_PATH"
printf 'Endpoint root: %s\n' "$HERMES_NODECLAW_BASE_URL"
printf 'Model: %s\n' "$HERMES_NODECLAW_MODEL"
printf 'Clone mode: %s\n' "$HERMES_NODECLAW_CLONE_MODE"
if [ -n "$HERMES_NODECLAW_CLONE_FROM" ]; then
  printf 'Clone source profile: %s\n' "$HERMES_NODECLAW_CLONE_FROM"
fi
printf '\n'

if [ "$DRY_RUN" = true ]; then
  printf 'Dry run only. Planned Hermes helper output:\n\n'
  printf '1. Profile creation path:\n\n'
  if [ "$IS_CUSTOM_HOME" = true ]; then
    printf '  mkdir -p %q\n' "$PROFILE_HOME"
  elif [ "$HERMES_NODECLAW_PROFILE" = 'default' ]; then
    printf '  update default Hermes home at %q\n' "$PROFILE_HOME"
  else
    printf '  hermes profile create %q' "$HERMES_NODECLAW_PROFILE"
    case "$HERMES_NODECLAW_CLONE_MODE" in
      clone)
        printf ' --clone'
        if [ -n "$HERMES_NODECLAW_CLONE_FROM" ]; then
          printf ' --clone-from %q' "$HERMES_NODECLAW_CLONE_FROM"
        fi
        ;;
      clone-all)
        printf ' --clone-all'
        ;;
    esac
    printf '\n'
  fi

  printf '\n2. Managed .env contents:\n\n'
  render_env_file '<nodeclaw_access_key>'
  printf '\n3. Managed config.yaml contents:\n\n'
  render_config_file
  printf '\n4. Managed SOUL.md contents:\n\n'
  render_soul_file
  printf '\n5. Suggested verification commands:\n\n'
  show_verification_notes
  exit 0
fi

if [ -z "$HERMES_NODECLAW_API_KEY" ]; then
  printf 'Set HERMES_NODECLAW_API_KEY (or NODECLAW_API_KEY) before running apply.\n' >&2
  printf 'Example: HERMES_NODECLAW_API_KEY="<nodeclaw_access_key>" bash ./script/setup-hermes-nodeclaw.sh\n' >&2
  exit 1
fi

create_profile_if_needed
mkdir -p "$PROFILE_HOME"
render_env_file "$HERMES_NODECLAW_API_KEY" > "$ENV_PATH"
render_config_file > "$CONFIG_PATH"

case "$HERMES_NODECLAW_REWRITE_SOUL" in
  true|TRUE|1|yes|YES)
    render_soul_file > "$SOUL_PATH"
    ;;
  *)
    if [ ! -f "$SOUL_PATH" ]; then
      render_soul_file > "$SOUL_PATH"
    fi
    ;;
esac

printf 'Wrote Hermes profile env to %s\n' "$ENV_PATH"
printf 'Wrote Hermes profile config to %s\n' "$CONFIG_PATH"
printf 'Wrote Hermes profile identity to %s\n' "$SOUL_PATH"
printf '\nSuggested verification commands:\n'
show_verification_notes
