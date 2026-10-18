# shellcheck shell=bash
# Path helpers: resolve absolute paths and validate inputs. Scripts find
# their own location from BASH_SOURCE and never rely on the caller's
# working directory. Source this file; do not run it.

if [[ -n "${_LIB_PATHS_LOADED:-}" ]]; then
  return 0
fi
_LIB_PATHS_LOADED=1

# shellcheck source=01-logging.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/01-logging.sh"

# abs_path PATH: print the absolute physical path of an existing file or
# directory. Returns 1 if it does not exist.
abs_path() {
  local path=$1 dir
  if [[ -d "$path" ]]; then
    (cd -- "$path" && pwd -P)
  elif [[ -e "$path" ]]; then
    dir=$(cd -- "$(dirname -- "$path")" && pwd -P) || return 1
    printf '%s/%s\n' "$dir" "$(basename -- "$path")"
  else
    log_error "path does not exist: ${path}"
    return 1
  fi
}

# require_file PATH / require_dir PATH: return 1 with an error if missing.
require_file() {
  [[ -f "$1" ]] || {
    log_error "required file not found: $1"
    return 1
  }
}

require_dir() {
  [[ -d "$1" ]] || {
    log_error "required directory not found: $1"
    return 1
  }
}

# path_within ROOT PATH: return 0 if PATH exists and resolves inside ROOT.
# Use it to validate a path that comes from an input or an argument.
path_within() {
  local root path
  root=$(abs_path "$1") || return 1
  path=$(abs_path "$2") || return 1
  if [[ "$path" == "$root" || "$path" == "$root"/* ]]; then
    return 0
  fi
  log_error "path is outside ${root}: $2"
  return 1
}
