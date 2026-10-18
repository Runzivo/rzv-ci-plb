# shellcheck shell=bash
# Error helpers: fail with a clear message, report the failing line,
# map signals to exit codes, check prerequisites and retry transient
# failures. Source this file; do not run it.

if [[ -n "${_LIB_ERRORS_LOADED:-}" ]]; then
  return 0
fi
_LIB_ERRORS_LOADED=1

# shellcheck source=logging.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/logging.sh"

# die MESSAGE [EXIT_CODE]: log an error and exit (default 1).
die() {
  log_error "$1"
  exit "${2:-1}"
}

# ERR trap handler. Reports the file, line and command text. The command
# text is shown before expansion, so variable values are not printed.
_errors_on_err() {
  local status=$1 line=$2 cmd=$3
  local file=${BASH_SOURCE[1]:-unknown}
  log_error "command failed (exit ${status}) at ${file##*/}:${line}: ${cmd}"
}

# Install ERR, INT and TERM traps. Use with `set -Eeuo pipefail`.
# INT and TERM exit with 130 and 143 so EXIT traps still run.
errors_install_traps() {
  trap '_errors_on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR
  trap 'exit 130' INT
  trap 'exit 143' TERM
}

# require_cmd NAME...: exit 127 if any command is missing.
require_cmd() {
  local name
  for name in "$@"; do
    command -v -- "$name" >/dev/null 2>&1 || die "required command not found: ${name}" 127
  done
}

# require_env NAME...: exit 1 if any variable is unset or empty.
# Prints only the variable name, never its value.
require_env() {
  local name
  for name in "$@"; do
    [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid variable name: ${name}"
    [[ -n "${!name:-}" ]] || die "required variable is not set: ${name}"
  done
}

# retry ATTEMPTS DELAY_SECONDS COMMAND [ARGS...]
# Retry a command that can fail for temporary reasons (network, a service
# still starting). Returns the last exit code. Use it for external
# commands; errexit does not apply inside a retried shell function.
retry() {
  local attempts=$1 delay=$2
  shift 2
  [[ "$attempts" =~ ^[1-9][0-9]*$ ]] || die "retry: attempts must be a positive integer"
  [[ "$delay" =~ ^[0-9]+$ ]] || die "retry: delay must be a whole number of seconds"
  (($# > 0)) || die "retry: no command given"

  local i status=0
  for ((i = 1; i <= attempts; i++)); do
    status=0
    "$@" || status=$?
    if ((status == 0)); then
      return 0
    fi
    if ((i < attempts)); then
      log_warn "attempt ${i}/${attempts} failed (exit ${status}): $1; retrying in ${delay}s"
      sleep "$delay"
    fi
  done
  log_error "all ${attempts} attempts failed (exit ${status}): $1"
  return "$status"
}
