#!/usr/bin/env bash
# Build the Docker example image. Unit tests run inside the build stage.
# Usage: examples/docker/ci/build.sh   (works from any directory)
# Env:   IMAGE  image reference to tag (default: docker-example:local)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/errors.sh
source "${LIB_DIR}/errors.sh"

errors_install_traps
require_cmd docker
docker info >/dev/null 2>&1 || die "Docker daemon is not reachable"

IMAGE="${IMAGE:-docker-example:local}"

log_group_start "Build ${IMAGE}"
docker build --pull --tag "$IMAGE" \
  --label "org.opencontainers.image.revision=${GITHUB_SHA:-local}" \
  "$APP_DIR"
log_group_end

log_info "built ${IMAGE}"
summary_add "- Docker example: built \`${IMAGE}\`"
