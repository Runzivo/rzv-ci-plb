#!/usr/bin/env bash
# Run the Python example tests with the standard library only.
# Usage: examples/python/ci/01-test.sh   (works from any directory)
# Env:   PYTHON      interpreter to use (default: python3)
#        REPORT_DIR  where to write the test log (default: .reports)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/03-errors.sh
source "${LIB_DIR}/03-errors.sh"

errors_install_traps
PYTHON="${PYTHON:-python3}"
require_cmd "$PYTHON"

REPORT_DIR="${REPORT_DIR:-${APP_DIR}/.reports}"
mkdir -p -- "$REPORT_DIR"
log_info "$("$PYTHON" --version)"

log_group_start "Compile sources"
"$PYTHON" -m compileall -q "${APP_DIR}/src" "${APP_DIR}/tests"
log_group_end

log_group_start "Run tests"
PYTHONPATH="${APP_DIR}/src" PYTHONDONTWRITEBYTECODE=1 \
  "$PYTHON" -m unittest discover -s "${APP_DIR}/tests" -v 2>&1 |
  tee "${REPORT_DIR}/python-unittest.log"
log_group_end

log_info "Python tests passed"
summary_add "- Python example: tests passed"
