#!/usr/bin/env bash
# Run the repository tests: Bats tests for the helpers and each example.
# Usage: scripts/ci/test.sh [SUITE...]
#   Suites: bats nodejs python golang docker runzivo-runners
#   Default: all suites. Outside GitHub Actions the docker suite is
#   skipped with a warning when no Docker daemon is reachable.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
# shellcheck source=../lib/errors.sh
source "${SCRIPT_DIR}/../lib/errors.sh"

errors_install_traps

run_suite() {
  local examples="${REPO_ROOT}/examples"
  case "$1" in
    bats)
      require_cmd bats
      bats --print-output-on-failure "${REPO_ROOT}/tests/bats"
      ;;
    nodejs | python | golang)
      bash "${examples}/$1/ci/test.sh"
      ;;
    docker)
      if ! in_github_actions && ! docker info >/dev/null 2>&1; then
        log_warn "skipping docker suite: no Docker daemon reachable"
        return 0
      fi
      bash "${examples}/docker/ci/build.sh"
      bash "${examples}/docker/ci/test.sh"
      ;;
    runzivo-runners)
      bash "${examples}/runzivo-runners/ci/runner-info.sh"
      ;;
    *) die "unknown suite: $1" 2 ;;
  esac
}

suites=("$@")
if ((${#suites[@]} == 0)); then
  suites=(bats nodejs python golang docker runzivo-runners)
fi

for suite in "${suites[@]}"; do
  log_group_start "Suite: ${suite}"
  run_suite "$suite"
  log_group_end
done
log_info "all suites passed: ${suites[*]}"
