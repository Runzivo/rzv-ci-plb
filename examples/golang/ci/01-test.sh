#!/usr/bin/env bash
# Check formatting, vet and test the Go example.
# Usage: examples/golang/ci/01-test.sh   (works from any directory)
# Env:   REPORT_DIR  where to write the go test log (default: .reports)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/03-errors.sh
source "${LIB_DIR}/03-errors.sh"

errors_install_traps
require_cmd go gofmt

REPORT_DIR="${REPORT_DIR:-${APP_DIR}/.reports}"
mkdir -p -- "$REPORT_DIR"
log_info "$(go version)"

log_group_start "Check formatting"
unformatted="$(gofmt -l "$APP_DIR")"
if [[ -n "$unformatted" ]]; then
  die "files need gofmt: ${unformatted//$'\n'/ }"
fi
log_group_end

log_group_start "Vet and test"
go -C "$APP_DIR" vet ./...
go -C "$APP_DIR" test -count=1 -v ./... 2>&1 | tee "${REPORT_DIR}/go-test.log"
log_group_end

log_info "Go tests passed"
summary_add "- Go example: tests passed"
