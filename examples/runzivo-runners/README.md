# Runzivo runners example

Runs the Node.js, Python and Go example jobs on a
[Runzivo](https://runzivo.dev/docs/runners/) runner. The jobs are the same
reusable workflows that `ci.yml` runs on GitHub-hosted runners; only the
runner label changes.

| File | Purpose |
| --- | --- |
| [`runzivo.yml`](../../.github/workflows/runzivo.yml) | Calls the example workflows with the Runzivo label |
| [`ci/runner-info.sh`](ci/runner-info.sh) | Writes OS, CPU, memory and disk to the job summary |

## Set up

1. Connect your GitHub organization and select this repository in the
   Runzivo portal ([getting started](https://runzivo.dev/docs/getting-started/)).
2. Add a repository variable `RUNZIVO_RUNNER_LABEL` with the label shown in
   the portal. Today that is `rzv-ubuntu-24.04-x64-2vcpu-8gb`.
3. Push to `main` or run the workflow from the Actions tab.

Without the variable, every job in `runzivo.yml` is skipped.

## What to know

From the Runzivo documentation at the time of writing:

- Linux x64 only, one label, one job at a time. Jobs in this workflow queue
  and run one after another, so it never cancels a run in progress.
- Each job gets a fresh Firecracker microVM that is destroyed when the job
  ends. Do not rely on files from an earlier job.
- Runner execution is live for organization repositories, not personal ones.

The Docker example is not included: the public documentation does not say
whether Docker is on the runner image. Add `example-docker.yml` once you
confirm it in your own run.

`runzivo.yml` runs on `push` and `workflow_dispatch` only. Pull requests from
forks never reach a self-hosted runner this way; see
[docs/security.md](../../docs/security.md).
