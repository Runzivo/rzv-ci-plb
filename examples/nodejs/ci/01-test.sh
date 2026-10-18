#!/usr/bin/env bash
# Install locked dependencies and run the Node.js example tests.
# Usage: examples/nodejs/ci/01-test.sh   (works from any directory)
# Env:   REPORT_DIR  where to write the JUnit report (default: .reports)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/03-errors.sh
source "${LIB_DIR}/03-errors.sh"

errors_install_traps
require_cmd node npm

REPORT_DIR="${REPORT_DIR:-${APP_DIR}/.reports}"
mkdir -p -- "$REPORT_DIR"
log_info "node $(node --version), npm $(npm --version)"

log_group_start "Install locked dependencies"
npm ci --prefix "$APP_DIR" --ignore-scripts --no-audit --no-fund
log_group_end

log_group_start "Run tests"
npm test --prefix "$APP_DIR" -- \
  --test-reporter=spec --test-reporter-destination=stdout \
  --test-reporter=junit --test-reporter-destination="${REPORT_DIR}/nodejs-junit.xml"
log_group_end

log_info "Node.js tests passed"
summary_add "- Node.js example: tests passed"
