# The ten standards

Each standard links to the code that applies it.

1. **Keep YAML small; put logic in scripts.** `run:` holds at most three
   lines of simple commands. Everything else is a script that runs the same
   way locally. See any `examples/*/ci/*.sh`.
2. **Fail clearly and keep exit codes.** `set -Eeuo pipefail`, an ERR trap
   that names the file, line and command, and `die` with a specific code.
   No `|| true` or `continue-on-error` without a written reason.
   [errors.sh](../scripts/lib/errors.sh)
3. **Always clean up.** Register cleanup as you create resources; it runs
   on success, failure, `INT` and `TERM`, newest first, and keeps the exit
   code. Traps cannot run after `SIGKILL`, so keep resources disposable.
   [cleanup.sh](../scripts/lib/cleanup.sh),
   [docker/ci/test.sh](../examples/docker/ci/test.sh)
4. **Use absolute paths.** `${GITHUB_WORKSPACE}` in workflows, `BASH_SOURCE`
   in scripts. Quote every path; validate input paths with `path_within`.
   [paths.sh](../scripts/lib/paths.sh)
5. **Log consistently.** `[INFO]`, `[WARN]`, `[ERROR]` with UTC timestamps
   on stderr; `::group::`, `::error::` and `$GITHUB_STEP_SUMMARY` inside
   Actions. Never log secrets. [logging.sh](../scripts/lib/logging.sh)
6. **Least privilege.** `contents: read` by default, actions pinned to
   commit SHAs, untrusted values passed through `env:`, no persisted
   checkout credentials. [security.md](security.md)
7. **Repeatable, retry-safe jobs.** Pin tool versions and checksums, commit
   lockfiles, set `timeout-minutes` and `concurrency`, and retry only
   transient failures. [install-tools.sh](../scripts/ci/install-tools.sh)
8. **Separate test, build and deploy.** Pull requests run tests without
   deployment credentials. Builds are their own step or job. Deploys run on
   `main` through a protected GitHub environment.
   [example-docker.yml](../.github/workflows/example-docker.yml)
9. **Validate every workflow.** actionlint, ShellCheck, shfmt, zizmor and
   Bats, on every pull request. Test failure paths, not only success.
   [lint.yml](../.github/workflows/lint.yml),
   [security.yml](../.github/workflows/security.yml),
   [tests/bats](../tests/bats)
10. **Build for reuse and debugging.** Reusable workflows for whole jobs,
    composite actions for repeated steps, failure artifacts with short
    retention, and portability across runners, including Runzivo.
    [ci.yml](../.github/workflows/ci.yml),
    [setup-ci](../.github/actions/setup-ci/action.yml),
    [runzivo.yml](../.github/workflows/runzivo.yml)

These are this repository's conventions. GitHub Actions does not require
them; they make pipelines easier to test, review and debug.
