# Python example

A small package (`src/textstats`) tested with `unittest` from the standard
library, so there is nothing to install.

| File | Purpose |
| --- | --- |
| [`ci/test.sh`](ci/test.sh) | Byte-compile sources, run tests, save the test log |
| [`.python-version`](.python-version) | Version used by `actions/setup-python` |
| [`example-python.yml`](../../.github/workflows/example-python.yml) | Workflow job |

Run locally from any directory:

```bash
bash examples/python/ci/test.sh
PYTHON=python3.13 bash examples/python/ci/test.sh   # another interpreter
```

To copy: take `scripts/lib/`, this directory and the workflow. Fix the
`LIB_DIR` line in `ci/test.sh` if your layout differs, and replace
`workflow_call` with your triggers.

When you add dependencies, pin them with hashes (for example a
`requirements.txt` from `pip-compile --generate-hashes`) and install with
`pip install --require-hashes -r requirements.txt` inside `ci/test.sh`.
