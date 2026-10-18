# Environment naming

Name every environment `<NN>-<env>-<NN>`: a fixed stage number, a
three-letter stage code, and an instance number. Use the same ids for
GitHub environments, cloud resources and docs.

| Stage | Code | Meaning | Ids |
| --- | --- | --- | --- |
| 01 | `dev` | development | `01-dev-01`, `01-dev-02`, ... |
| 02 | `qat` | quality assurance testing | `02-qat-01`, ... |
| 03 | `stg` | staging | `03-stg-01`, ... |
| 04 | `prd` | production | `04-prd-01`, `04-prd-02`, ... |

Always use the three-letter codes. Never `development`, `production`,
`prod` or `staging`.

## Why

- Lists sort from development to production in the GitHub environments
  page, the cloud console and any directory listing.
- The stage number never changes. A small team that uses only `01-dev-01`
  and `04-prd-01` keeps the numbers, so production never sorts above a
  staging or QA environment added later.
- The instance number lets you add a second region or tenant
  (`04-prd-02`) without renaming the first.

## Deploy gate

Create the environment in **Settings > Environments**, add required
reviewers, allow only the `main` branch, and store deployment secrets
there. Then reference it from a deploy job that depends on your checks:

```yaml
  deploy:
    needs: [test, build]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    timeout-minutes: 15
    environment:
      name: 04-prd-01
    permissions:
      contents: read
    concurrency:
      group: deploy-04-prd-01
      cancel-in-progress: false
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - run: bash "${GITHUB_WORKSPACE}/scripts/ci/03-deploy.sh"
```

`03-deploy.sh` stands for your deploy script, numbered after build and
test. Pull-request jobs never name an environment, so never see its secrets.
