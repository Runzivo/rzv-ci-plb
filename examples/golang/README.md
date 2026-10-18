# Go example

A small package (`wordwrap`) with table-driven tests. The Go version comes
from `go.mod`, so local and CI builds use the same toolchain line.

| File | Purpose |
| --- | --- |
| [`ci/01-test.sh`](ci/01-test.sh) | `gofmt` check, `go vet`, `go test` with a saved log |
| [`go.mod`](go.mod) | Module and Go version used by `actions/setup-go` |
| [`example-golang.yml`](../../.github/workflows/example-golang.yml) | Workflow job |

Run locally from any directory:

```bash
bash examples/golang/ci/01-test.sh
```

To copy: take `scripts/lib/`, this directory and the workflow. Fix the
`LIB_DIR` line in `ci/01-test.sh` if your layout differs, and replace
`workflow_call` with your triggers. Once you have a `go.sum`, remove
`cache: false` from the setup step so modules are cached.
