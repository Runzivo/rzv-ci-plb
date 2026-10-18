#!/usr/bin/env bash
# Smoke test the Docker example image: start a container, wait for
# /healthz, then remove the container on any exit.
# Usage: examples/docker/ci/test.sh   (run ci/build.sh first)
# Env:   IMAGE       image reference to test (default: docker-example:local)
#        REPORT_DIR  where to write container logs (default: .reports)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
APP_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
# When you copy this example, point LIB_DIR at your copy of scripts/lib.
LIB_DIR="$(cd -- "${SCRIPT_DIR}/../../../scripts/lib" && pwd -P)"
# shellcheck source=../../../scripts/lib/errors.sh
source "${LIB_DIR}/errors.sh"
# shellcheck source=../../../scripts/lib/cleanup.sh
source "${LIB_DIR}/cleanup.sh"

errors_install_traps
cleanup_install_trap
require_cmd docker curl

IMAGE="${IMAGE:-docker-example:local}"
REPORT_DIR="${REPORT_DIR:-${APP_DIR}/.reports}"
mkdir -p -- "$REPORT_DIR"
docker image inspect "$IMAGE" >/dev/null 2>&1 || die "image not found: ${IMAGE}; run ci/build.sh first"

container_id=""
save_logs_and_remove() {
  if [[ -n "$container_id" ]]; then
    # Logs are best effort: a container that failed to start may have none.
    docker logs "$container_id" >"${REPORT_DIR}/docker-container.log" 2>&1 ||
      log_warn "could not save container logs"
    docker rm -f "$container_id" >/dev/null
  fi
}
cleanup_register save_logs_and_remove

log_group_start "Start container"
container_id="$(docker run --detach --publish 127.0.0.1::8080 \
  --label "ci.example=docker" --read-only --cap-drop ALL "$IMAGE")"
host_port="$(docker port "$container_id" 8080/tcp)"
host_port="${host_port##*:}"
log_info "container ${container_id:0:12} listening on 127.0.0.1:${host_port}"
log_group_end

log_group_start "Check /healthz"
body="$(retry 10 1 curl --fail --silent --show-error "http://127.0.0.1:${host_port}/healthz")"
[[ "$body" == "ok" ]] || die "unexpected /healthz body: ${body}"
log_group_end

log_info "Docker smoke test passed"
summary_add "- Docker example: \`${IMAGE}\` passed the /healthz smoke test"
