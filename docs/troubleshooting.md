# Troubleshooting

**The error line points at `tee` or the last command of a pipeline.**
Bash reports the pipeline's last command in `BASH_COMMAND`. The line number
is right; read the whole pipeline on that line.

**A cleanup registered inside `$(...)` never ran.** Command substitution
runs in a subshell, so the registration is lost. Call
`cleanup_temp_dir VAR` or `cleanup_register` in the main shell.

**`set -e` did not stop a failing function.** Errexit is off inside a
function called from `if`, `&&`, `||` or `!`, including through `retry`.
Retry external commands, or check status inside the function.

**The same failure is reported twice.** With `set -E`, a failure inside a
subshell triggers the ERR trap there and again in the parent. The first
line is the original error.

**`actionlint` says the runner label is unknown.** Add self-hosted labels to
[.github/actionlint.yaml](../.github/actionlint.yaml).

**zizmor suggests `uses: $/...`.** GitHub's self-repository syntax is newer
than actionlint's support (rhysd/actionlint#711), so the audit is disabled
in [zizmor.yml](../.github/zizmor.yml) until it lands.

**`shellcheck` cannot follow `source`.** Run it with the repository's
[.shellcheckrc](../.shellcheckrc), which resolves paths from each script.

**A Runzivo job stays queued or is skipped.**

- Skipped: `RUNZIVO_RUNNER_LABEL` is not set as a repository variable.
- Queued: the label must match the one in the Runzivo portal exactly; the
  repository must be an organization repository selected in the Runzivo
  GitHub App; and Runzivo runs one job at a time, so jobs wait their turn.
- See the [Runzivo troubleshooting guide](https://runzivo.dev/docs/troubleshooting/).

**Scripts behave differently on macOS.** macOS ships Bash 3.2 as
`/bin/bash`. The library works there, but `#!/usr/bin/env bash` picks a
newer Bash from Homebrew if installed. CI uses the runner's Bash 5.

**Docker suite skipped locally.** `scripts/ci/test.sh` skips it when no
Docker daemon is reachable outside CI. Start Docker and run
`bash scripts/ci/test.sh docker`.
