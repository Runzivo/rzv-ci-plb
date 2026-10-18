# Docker example

A small Go HTTP service packaged as a container image. Build and test are
separate scripts and separate workflow steps.

| File | Purpose |
| --- | --- |
| [`Dockerfile`](Dockerfile) | Multi-stage build, unit tests in the build stage, distroless runtime |
| [`ci/01-build.sh`](ci/01-build.sh) | Builds and labels the image |
| [`ci/02-test.sh`](ci/02-test.sh) | Starts the container, polls `/healthz` with `retry`, always removes the container |
| [`example-docker.yml`](../../.github/workflows/example-docker.yml) | Workflow job |

Run locally (needs a Docker daemon):

```bash
bash examples/docker/ci/01-build.sh
bash examples/docker/ci/02-test.sh
IMAGE=myapp:dev bash examples/docker/ci/01-build.sh   # another tag
```

Patterns shown:

- Base images pinned by tag and digest. Update both together.
- The container runs read-only, as a non-root user, with all capabilities
  dropped, and binds only to `127.0.0.1` on a random port.
- `cleanup_register` removes the container on success, failure or
  cancellation, and saves its logs for the failure artifact.
- The workflow does not push. Add a push step in a separate job that runs
  only on `main`, with `packages: write` granted to that job alone.
