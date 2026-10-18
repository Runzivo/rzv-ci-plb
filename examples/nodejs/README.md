# Node.js example

A small ES module (`src/slugify.js`) tested with the built-in `node:test`
runner. No dependencies; the lockfile is committed so `npm ci` stays exact.

| File | Purpose |
| --- | --- |
| [`ci/01-test.sh`](ci/01-test.sh) | `npm ci --ignore-scripts`, then tests with a JUnit report |
| [`.nvmrc`](.nvmrc) | Node.js major version used by `actions/setup-node` |
| [`example-nodejs.yml`](../../.github/workflows/example-nodejs.yml) | Workflow job |

Run locally from any directory:

```bash
bash examples/nodejs/ci/01-test.sh
```

To copy: take `scripts/lib/`, this directory and the workflow. Fix the
`LIB_DIR` line in `ci/01-test.sh` if your layout differs, and replace
`workflow_call` with your triggers. Once you add dependencies, remove
`package-manager-cache: false` so npm downloads are cached.

`--ignore-scripts` stops dependency install scripts from running in CI. Drop
it only for a package that needs a build step, and know which one it is.
