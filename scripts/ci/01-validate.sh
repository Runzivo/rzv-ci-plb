#!/usr/bin/env bash
# Validate workflows and shell scripts.
# Usage: scripts/ci/01-validate.sh [lint|security|all]   (default: all)
#   lint      actionlint, shellcheck, shfmt
#   security  zizmor (set GH_TOKEN to enable its online audits)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
# shellcheck source=../lib/03-errors.sh
source "${SCRIPT_DIR}/../lib/03-errors.sh"

errors_install_traps

# Shell files tracked by this repository, excluding dependencies.
shell_files() {
  find "$REPO_ROOT" \( -name .git -o -name node_modules \) -prune -o \
    -type f \( -name '*.sh' -o -name '*.bats' \) -print | LC_ALL=C sort
}

run_lint() {
  require_cmd actionlint shellcheck shfmt
  local files=() file
  while IFS= read -r file; do
    files+=("$file")
  done < <(shell_files)

  log_group_start "actionlint"
  (cd -- "$REPO_ROOT" && actionlint)
  log_group_end

  log_group_start "shellcheck (${#files[@]} files)"
  shellcheck "${files[@]}"
  log_group_end

  log_group_start "shfmt"
  shfmt --diff "${files[@]}"
  log_group_end

  summary_add "- Lint: actionlint, shellcheck and shfmt passed"
}

run_security() {
  require_cmd zizmor
  log_group_start "zizmor"
  zizmor --config "${REPO_ROOT}/.github/zizmor.yml" "$REPO_ROOT"
  log_group_end
  summary_add "- Security: zizmor passed"
}

case "${1:-all}" in
  lint) run_lint ;;
  security) run_security ;;
  all)
    run_lint
    run_security
    ;;
  *) die "usage: ${0##*/} [lint|security|all]" 2 ;;
esac
log_info "validation passed"
