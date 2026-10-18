#!/usr/bin/env bash
# Load credentials from where they already live, export them, and run a
# command with them. The caller (a person or an AI agent) only names the
# variables; values are never printed, logged or written to disk.
#
# Usage: 01-load-credentials.sh NAME [NAME...] -- COMMAND [ARGS...]
#   e.g. 01-load-credentials.sh GH_TOKEN -- gh api user --jq .login
#
# Sources, chosen by CRED_SOURCE (default: auto):
#   keychain  macOS Keychain item: service $CRED_KEYCHAIN_SERVICE
#             (default: ci-credentials), account NAME
#   op        1Password CLI: op://$CRED_OP_VAULT/NAME/credential
#   file      KEY=VALUE lines in $CRED_FILE (default:
#             ~/.config/ci-credentials/env). The file must be mode 600,
#             owned by you and outside the repository.
#   auto      keychain on macOS, else op when CRED_OP_VAULT is set and op
#             is installed, else file.
set -Eeuo pipefail
set +x # never trace this script: traced lines would show values

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
# shellcheck source=../lib/03-errors.sh
source "${SCRIPT_DIR}/../lib/03-errors.sh"
# shellcheck source=../lib/02-paths.sh
source "${SCRIPT_DIR}/../lib/02-paths.sh"

errors_install_traps

usage() {
  die "usage: ${0##*/} NAME [NAME...] -- COMMAND [ARGS...]" 2
}

names=()
while (($# > 0)) && [[ "$1" != "--" ]]; do
  [[ "$1" =~ ^[A-Z_][A-Z0-9_]*$ ]] || die "invalid variable name: $1" 2
  names+=("$1")
  shift
done
(($# > 0)) || usage
shift # drop --
((${#names[@]} > 0 && $# > 0)) || usage

pick_source() {
  local src="${CRED_SOURCE:-auto}"
  if [[ "$src" == "auto" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]] && command -v security >/dev/null 2>&1; then
      src="keychain"
    elif [[ -n "${CRED_OP_VAULT:-}" ]] && command -v op >/dev/null 2>&1; then
      src="op"
    else
      src="file"
    fi
  fi
  case "$src" in
    keychain | op | file) printf '%s\n' "$src" ;;
    *) die "unknown CRED_SOURCE: ${src}" 2 ;;
  esac
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

file_owner() {
  stat -c '%u' "$1" 2>/dev/null || stat -f '%u' "$1"
}

check_env_file() {
  local file=$1
  require_file "$file" || die "credentials file not found: ${file}"
  [[ "$(file_mode "$file")" == "600" ]] || die "credentials file must be mode 600: ${file}"
  [[ "$(file_owner "$file")" == "$(id -u)" ]] || die "credentials file must be owned by you: ${file}"
  if path_within "$REPO_ROOT" "$file" 2>/dev/null; then
    die "credentials file must live outside the repository: ${file}"
  fi
}

# read_from_file FILE NAME: print the value of NAME. Lines are KEY=VALUE;
# blank lines and lines starting with # are ignored. Nothing is executed.
read_from_file() {
  local file=$1 name=$2 line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "${line%%=*}" == "$name" && "$line" == *=* ]]; then
      printf '%s' "${line#*=}"
      return 0
    fi
  done <"$file"
  return 1
}

read_value() {
  local src=$1 name=$2
  case "$src" in
    keychain)
      security find-generic-password -s "${CRED_KEYCHAIN_SERVICE:-ci-credentials}" -a "$name" -w 2>/dev/null
      ;;
    op)
      require_env CRED_OP_VAULT
      op read "op://${CRED_OP_VAULT}/${name}/credential" 2>/dev/null
      ;;
    file)
      read_from_file "${CRED_FILE:-${HOME}/.config/ci-credentials/env}" "$name"
      ;;
  esac
}

source_name="$(pick_source)"
case "$source_name" in
  keychain) require_cmd security ;;
  op) require_cmd op ;;
  file) check_env_file "${CRED_FILE:-${HOME}/.config/ci-credentials/env}" ;;
esac

for name in "${names[@]}"; do
  value="$(read_value "$source_name" "$name")" || die "${name} not found in ${source_name}"
  [[ -n "$value" ]] || die "${name} is empty in ${source_name}"
  export "${name}=${value}"
  log_info "loaded ${name} from ${source_name}"
done
unset value

exec "$@"
