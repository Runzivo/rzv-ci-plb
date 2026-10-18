# shellcheck shell=bash
# Logging helpers: [INFO]/[WARN]/[ERROR] lines on stderr, GitHub Actions
# groups, annotations and step summaries. Source this file; do not run it.
# Never pass secret values to these functions.

if [[ -n "${_LIB_LOGGING_LOADED:-}" ]]; then
  return 0
fi
_LIB_LOGGING_LOADED=1

# True when running inside a GitHub Actions job.
in_github_actions() {
  [[ "${GITHUB_ACTIONS:-}" == "true" ]]
}

# Escape a message for a workflow command (::error::, ::warning::).
_log_escape() {
  local msg=$1
  msg=${msg//'%'/'%25'}
  msg=${msg//$'\r'/'%0D'}
  msg=${msg//$'\n'/'%0A'}
  printf '%s' "$msg"
}

_log_line() {
  local level=$1
  shift
  printf '%s [%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$level" "$*" >&2
}

log_info() {
  _log_line INFO "$@"
}

log_warn() {
  _log_line WARN "$@"
  if in_github_actions; then
    printf '::warning::%s\n' "$(_log_escape "$*")" >&2
  fi
}

log_error() {
  _log_line ERROR "$@"
  if in_github_actions; then
    printf '::error::%s\n' "$(_log_escape "$*")" >&2
  fi
}

# Start a collapsible log group. Close it with log_group_end.
log_group_start() {
  if in_github_actions; then
    printf '::group::%s\n' "$*" >&2
  else
    printf '==> %s\n' "$*" >&2
  fi
}

log_group_end() {
  if in_github_actions; then
    printf '::endgroup::\n' >&2
  fi
}

# Append one Markdown line to the job summary. No-op outside Actions.
summary_add() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '%s\n' "$*" >>"$GITHUB_STEP_SUMMARY"
  fi
}
