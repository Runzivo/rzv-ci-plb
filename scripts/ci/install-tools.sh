#!/usr/bin/env bash
# Install pinned validation tools on a Linux x86_64 runner. Every download
# is checked against a SHA-256 digest; bats is checked against a commit.
# Usage: scripts/ci/install-tools.sh TOOL...   (or TOOLS="a b" in the env)
#   Tools: actionlint shellcheck shfmt bats zizmor
# Env:   INSTALL_DIR  target bin dir (default: $RUNNER_TEMP/ci-tools/bin)
# On macOS use Homebrew instead: brew install actionlint shellcheck shfmt bats-core zizmor
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../lib/errors.sh
source "${SCRIPT_DIR}/../lib/errors.sh"
# shellcheck source=../lib/cleanup.sh
source "${SCRIPT_DIR}/../lib/cleanup.sh"

errors_install_traps
cleanup_install_trap

# Versions and digests. Update a version and its digest together.
ACTIONLINT_VERSION=1.7.12
ACTIONLINT_SHA256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
SHELLCHECK_VERSION=0.11.0
SHELLCHECK_SHA256=8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
SHFMT_VERSION=3.14.1
SHFMT_SHA256=76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
BATS_VERSION=1.14.0
BATS_COMMIT=eb7f42f8d608ac693d7a4b67474f6714ea68cfc5
ZIZMOR_VERSION=1.31.1
ZIZMOR_SHA256=d185f726bdaf92df78273217dfdd24ebcd6b0ef48cf3ce776ff5762b6e138c99

tools=("$@")
if ((${#tools[@]} == 0)); then
  read -r -a tools <<<"${TOOLS:-}"
fi
((${#tools[@]} > 0)) || die "usage: ${0##*/} TOOL..." 2
[[ "$(uname -s)/$(uname -m)" == "Linux/x86_64" ]] ||
  die "only Linux x86_64 is supported; on macOS use Homebrew" 2
require_cmd curl sha256sum tar git

INSTALL_DIR="${INSTALL_DIR:-${RUNNER_TEMP:?RUNNER_TEMP or INSTALL_DIR must be set}/ci-tools/bin}"
[[ "$INSTALL_DIR" == */bin ]] || die "INSTALL_DIR must end in /bin: ${INSTALL_DIR}" 2
mkdir -p -- "$INSTALL_DIR"
cleanup_temp_dir WORK_DIR

# fetch URL SHA256 FILE: download and verify a file.
fetch() {
  local url=$1 sha=$2 out=$3
  retry 3 5 curl --fail --silent --show-error --location --output "$out" "$url"
  printf '%s  %s\n' "$sha" "$out" | sha256sum --check --quiet ||
    die "checksum mismatch for ${url}"
}

install_tool() {
  local gh=https://github.com
  case "$1" in
    actionlint)
      fetch "${gh}/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_amd64.tar.gz" \
        "$ACTIONLINT_SHA256" "${WORK_DIR}/actionlint.tar.gz"
      tar -xzf "${WORK_DIR}/actionlint.tar.gz" -C "$INSTALL_DIR" actionlint
      ;;
    shellcheck)
      fetch "${gh}/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" \
        "$SHELLCHECK_SHA256" "${WORK_DIR}/shellcheck.tar.xz"
      tar -xJf "${WORK_DIR}/shellcheck.tar.xz" -C "$WORK_DIR"
      install -m 0755 "${WORK_DIR}/shellcheck-v${SHELLCHECK_VERSION}/shellcheck" "$INSTALL_DIR/"
      ;;
    shfmt)
      fetch "${gh}/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_amd64" \
        "$SHFMT_SHA256" "${WORK_DIR}/shfmt"
      install -m 0755 "${WORK_DIR}/shfmt" "$INSTALL_DIR/"
      ;;
    bats)
      retry 3 5 git clone --quiet --depth 1 --branch "v${BATS_VERSION}" \
        "${gh}/bats-core/bats-core.git" "${WORK_DIR}/bats-core"
      [[ "$(git -C "${WORK_DIR}/bats-core" rev-parse HEAD)" == "$BATS_COMMIT" ]] ||
        die "bats v${BATS_VERSION} does not match commit ${BATS_COMMIT}"
      "${WORK_DIR}/bats-core/install.sh" "${INSTALL_DIR%/bin}" >/dev/null
      ;;
    zizmor)
      fetch "${gh}/zizmorcore/zizmor/releases/download/v${ZIZMOR_VERSION}/zizmor-x86_64-unknown-linux-gnu.tar.gz" \
        "$ZIZMOR_SHA256" "${WORK_DIR}/zizmor.tar.gz"
      tar -xzf "${WORK_DIR}/zizmor.tar.gz" -C "$WORK_DIR"
      install -m 0755 "$(find "$WORK_DIR" -type f -name zizmor | head -n 1)" "$INSTALL_DIR/"
      ;;
    *) die "unknown tool: $1" 2 ;;
  esac
  log_info "installed $1"
}

for tool in "${tools[@]}"; do
  install_tool "$tool"
done

if [[ -n "${GITHUB_PATH:-}" ]]; then
  printf '%s\n' "$INSTALL_DIR" >>"$GITHUB_PATH"
fi
log_info "tools are in ${INSTALL_DIR}"
