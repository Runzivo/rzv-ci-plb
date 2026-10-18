# shellcheck shell=bash
# Cleanup helpers: register commands that run once, in reverse order, when
# the script exits for any reason. The original exit code is kept.
# Source this file; do not run it.
#
# Traps cannot run after SIGKILL or a lost runner. Keep resources
# disposable (temp dirs, labelled containers) so a later run can clean up.

if [[ -n "${_LIB_CLEANUP_LOADED:-}" ]]; then
  return 0
fi
_LIB_CLEANUP_LOADED=1

# shellcheck source=01-logging.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/01-logging.sh"

_CLEANUP_ENTRIES=()

# cleanup_register COMMAND [ARGS...]: run this command at exit.
# Arguments are quoted with printf %q, so paths with spaces are safe.
cleanup_register() {
  (($# > 0)) || return 0
  local entry
  entry=$(printf '%q ' "$@")
  _CLEANUP_ENTRIES+=("$entry")
}

# Run registered commands newest first. A failing command logs a warning
# and does not stop the others. Safe to call more than once.
cleanup_run() {
  local i status
  for ((i = ${#_CLEANUP_ENTRIES[@]} - 1; i >= 0; i--)); do
    status=0
    eval "${_CLEANUP_ENTRIES[i]}" || status=$?
    if ((status != 0)); then
      log_warn "cleanup command failed (exit ${status}): ${_CLEANUP_ENTRIES[i]}"
    fi
  done
  _CLEANUP_ENTRIES=()
}

_cleanup_on_exit() {
  local status=$?
  trap - EXIT
  cleanup_run
  exit "$status"
}

# Install the EXIT trap. Call once, near the top of the script.
cleanup_install_trap() {
  trap _cleanup_on_exit EXIT
}

# cleanup_temp_dir VAR: create a temp dir, store its path in VAR and
# remove it at exit. Do not call it in $(...): the subshell would lose
# the registration.
cleanup_temp_dir() {
  local var=$1 dir
  [[ "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || {
    log_error "cleanup_temp_dir: invalid variable name: ${var}"
    return 1
  }
  dir=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/ci.XXXXXX")
  cleanup_register rm -rf -- "$dir"
  printf -v "$var" '%s' "$dir"
}
