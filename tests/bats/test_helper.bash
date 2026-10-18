# shellcheck shell=bash
# Shared setup for the Bats tests.

bats_require_minimum_version 1.5.0

REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/../.." && pwd -P)"
LIB_DIR="${REPO_ROOT}/scripts/lib"
export REPO_ROOT LIB_DIR

# Run outside GitHub Actions unless a test opts in, so results do not
# depend on where the tests run.
unset GITHUB_ACTIONS GITHUB_STEP_SUMMARY RUNNER_TEMP

# write_script NAME BODY: create an executable test script that loads the
# helper library with strict mode and traps, followed by BODY.
write_script() {
  local path="${BATS_TEST_TMPDIR}/$1"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -Eeuo pipefail\n'
    printf 'source %q\n' "${LIB_DIR}/errors.sh" "${LIB_DIR}/cleanup.sh" "${LIB_DIR}/paths.sh"
    printf 'errors_install_traps\n'
    printf 'cleanup_install_trap\n'
    printf '%s\n' "$2"
  } >"$path"
  chmod +x "$path"
  printf '%s\n' "$path"
}
