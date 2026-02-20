#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="${CODEX_NOTIFY_CONFIG:-$REPO_ROOT/config/codex-notify.conf}"

# shellcheck disable=SC1090
if [[ -f "$CONFIG_PATH" ]]; then
  source "$CONFIG_PATH"
fi

ENABLE_NOTIFY="${ENABLE_NOTIFY:-1}"
DEFAULT_SHRIMPY_APP_PATH="${SHRIMPY_APP_PATH:-/Applications/Shrimpy.app}"
CODEX_BIN="${CODEX_BIN:-codex}"
PROJECT_TITLE="${PROJECT_TITLE:-Codex}"

resolve_shrimpy_app_path() {
  local candidate="$DEFAULT_SHRIMPY_APP_PATH"
  if [[ -x "$candidate/Contents/MacOS/Shrimpy" ]]; then
    echo "$candidate"
    return 0
  fi

  candidate="$REPO_ROOT/Shrimpy.app"
  if [[ -x "$candidate/Contents/MacOS/Shrimpy" ]]; then
    echo "$candidate"
    return 0
  fi

  echo ""
}

notify() {
  local message="$1"
  local title="$2"
  local app_path
  app_path="$(resolve_shrimpy_app_path)"

  if [[ "$ENABLE_NOTIFY" != "1" ]]; then
    return 0
  fi

  if [[ -z "$app_path" ]]; then
    echo "codex-notify: no launchable Shrimpy app found at $DEFAULT_SHRIMPY_APP_PATH or $REPO_ROOT/Shrimpy.app" >&2
    return 0
  fi

  open -gj "$app_path" --args "$message" --title "$title" 2>/dev/null || true
}

if [[ "${1:-}" == "--test" ]]; then
  notify "${2:-Codex notification test}" "$PROJECT_TITLE"
  exit 0
fi

tmp_log="$(mktemp "${TMPDIR:-/tmp}/codex-notify.XXXXXX.log")"
trap 'rm -f "$tmp_log"' EXIT

set +e
"$CODEX_BIN" "$@" 2>&1 | tee "$tmp_log"
codex_exit="${PIPESTATUS[0]}"
set -e

if rg -qi "needs[[:space:]]+input|waiting[[:space:]]+(for[[:space:]]+)?(your[[:space:]]+)?input|request_user_input|approval[[:space:]]+required|permission[[:space:]]+required" "$tmp_log"; then
  notify "Codex needs your input" "$PROJECT_TITLE"
elif [[ "$codex_exit" -ne 0 ]]; then
  notify "Codex command failed (exit $codex_exit)" "$PROJECT_TITLE"
else
  notify "Codex task completed" "$PROJECT_TITLE"
fi

exit "$codex_exit"
