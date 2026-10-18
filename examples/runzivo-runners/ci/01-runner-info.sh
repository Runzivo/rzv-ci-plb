#!/usr/bin/env bash
# Print what the job runs on: OS, kernel, CPU, memory, disk and runner
# name. Adds a table to the job summary. Prints no secrets or tokens.
# Usage: examples/runzivo-runners/ci/01-runner-info.sh   (Linux or macOS)
# Env:   EXPECTED_LABEL  optional label to show next to the runner facts
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/03-errors.sh
source "${LIB_DIR}/03-errors.sh"

errors_install_traps
require_cmd uname df

os_name() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck source=/dev/null
    (. /etc/os-release && printf '%s\n' "${PRETTY_NAME:-${NAME:-unknown}}")
  else
    printf '%s %s\n' "$(uname -s)" "$(uname -r)"
  fi
}

cpu_count() {
  getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || printf 'unknown\n'
}

memory_gib() {
  local kib bytes
  if [[ -r /proc/meminfo ]]; then
    kib="$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
    awk -v k="$kib" 'BEGIN { printf "%.1f\n", k / 1048576 }'
  elif bytes="$(sysctl -n hw.memsize 2>/dev/null)"; then
    awk -v b="$bytes" 'BEGIN { printf "%.1f\n", b / 1073741824 }'
  else
    printf 'unknown\n'
  fi
}

disk_free() {
  df -Ph "${GITHUB_WORKSPACE:-$SCRIPT_DIR}" | awk 'NR == 2 { print $4 " free of " $2 }'
}

rows=(
  "Expected label|${EXPECTED_LABEL:-not set}"
  "Runner name|${RUNNER_NAME:-local}"
  "Runner OS / arch|${RUNNER_OS:-$(uname -s)} / ${RUNNER_ARCH:-$(uname -m)}"
  "Operating system|$(os_name)"
  "Kernel|$(uname -r)"
  "CPUs|$(cpu_count)"
  "Memory (GiB)|$(memory_gib)"
  "Workspace disk|$(disk_free)"
)

summary_add "### Runner"
summary_add ""
summary_add "| Item | Value |"
summary_add "| --- | --- |"
for row in "${rows[@]}"; do
  log_info "${row%%|*}: ${row#*|}"
  summary_add "| ${row%%|*} | ${row#*|} |"
done
