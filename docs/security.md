# Security

## Permissions

Set `permissions: contents: read` at the top of every workflow. Grant extra
scopes to the one job that needs them, for example `packages: write` on a
push job that runs only on `main`.

## Pin actions to commit SHAs

A tag can be moved; a commit SHA cannot. Pin with the tag in a comment:

```yaml
- uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

Verify a SHA before you use it:

```bash
gh api repos/actions/checkout/git/ref/tags/v7.0.1 --jq '.object.type + " " + .object.sha'
# If the type is "tag", dereference it:
gh api repos/OWNER/REPO/git/tags/TAG_OBJECT_SHA --jq .object.sha
```

zizmor enforces SHA pins for every action ([zizmor.yml](../.github/zizmor.yml)).

## Untrusted input

Titles, branch names, commit messages and `workflow_dispatch` inputs are
attacker-controlled. Never expand them inside `run:`; pass them through
`env:` and quote the variable:

```yaml
- name: Show title
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: |
    printf 'Title: %s\n' "$PR_TITLE"
```

Avoid `pull_request_target` and `workflow_run` for code from forks. If you
must use them, never check out or run the fork's code in that job.

## Credentials

- `actions/checkout` with `persist-credentials: false`, so later steps
  cannot reuse the token from `.git/config`.
- Prefer OIDC (`id-token: write` on the deploy job) over long-lived cloud
  keys. Store any remaining keys as environment secrets.
- Deploy jobs use a GitHub environment with required reviewers and a
  branch rule, so pull requests never see deployment secrets.

## Self-hosted runners, including Runzivo

A public repository that runs fork pull requests on self-hosted runners lets
outsiders run code on them. Run pull-request checks on GitHub-hosted
runners, keep self-hosted jobs on `push` and `workflow_dispatch` as
[runzivo.yml](../.github/workflows/runzivo.yml) does, and require approval
for workflows from outside contributors in the repository settings.
