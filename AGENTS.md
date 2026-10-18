# Instructions for coding agents

Apply these rules when you write or change a workflow, here or in a
repository that copies these patterns.

## Start from an example

Copy the closest example and keep its structure; do not start from scratch.

| Asked for | Copy |
| --- | --- |
| Node.js, TypeScript, npm | `examples/nodejs/`, `.github/workflows/example-nodejs.yml` |
| Python | `examples/python/`, `.github/workflows/example-python.yml` |
| Go | `examples/golang/`, `.github/workflows/example-golang.yml` |
| Container image | `examples/docker/`, `.github/workflows/example-docker.yml` |
| Runzivo runners | `examples/runzivo-runners/`, `.github/workflows/runzivo.yml` |

## Workflow rules

- The three-line rule: a `run:` step holds at most three lines of simple
  commands. Conditions, loops, retries, cleanup or error handling go in a
  script, called as `bash "${GITHUB_WORKSPACE}/path/to/script.sh"`.
- Top-level `permissions: contents: read`. Grant more to one job only.
- Pin every action to a full commit SHA with the tag in a comment, checked
  with `gh api repos/OWNER/REPO/git/ref/tags/TAG`. Never guess a SHA.
- Never put `${{ github.event.* }}`, `${{ inputs.* }}` or other untrusted
  values inside `run:`. Pass them through `env:` and quote them.
- `actions/checkout` with `persist-credentials: false`. Every job has
  `timeout-minutes`; workflows on PRs have `concurrency`.
- GitHub environments use ids like `01-dev-01` and `04-prd-01`, never
  `production`. See [docs/environments.md](docs/environments.md).
- Runner labels come from documentation. For Runzivo use
  `${{ vars.RUNZIVO_RUNNER_LABEL }}`; the documented label today is
  `rzv-ubuntu-24.04-x64-2vcpu-8gb`. Do not invent labels.

## Script rules

- Repository scripts live in `scripts/ci/`; example scripts in
  `examples/<stack>/ci/`; shared helpers in `scripts/lib/`.
- Number every new script and Bats file in run or load order
  (`01-test.sh`, `02-deploy.sh`); `00` is for setup or shared utilities.
- Start with `set -Eeuo pipefail`, resolve paths from `BASH_SOURCE`, source
  `scripts/lib/03-errors.sh` and call `errors_install_traps`.
- Logging: `log_info`, `log_warn`, `log_error`, `log_group_start`,
  `log_group_end`, `summary_add`. Failing: `die MESSAGE [CODE]`.
- Prerequisites: `require_cmd`, `require_env`. Transient failures:
  `retry ATTEMPTS DELAY CMD...`.
- Cleanup: `cleanup_install_trap`, then `cleanup_register CMD...` or
  `cleanup_temp_dir VAR`. Never `|| true` without a comment saying why.
- Never print secrets. Never write credentials into the repository.

## Validate before you finish

```bash
bash scripts/ci/01-validate.sh   # actionlint, shellcheck, shfmt, zizmor
bash scripts/ci/02-test.sh       # Bats tests and every example
```

Add Bats tests for new helpers covering success, failure and cleanup.
Credentials during local work: [docs/ai-agent-guide.md](docs/ai-agent-guide.md).
