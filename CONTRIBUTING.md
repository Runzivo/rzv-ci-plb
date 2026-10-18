# Contributing

Issues and pull requests are welcome. Keep changes small and focused.

## Before you open a pull request

1. Follow the conventions in [AGENTS.md](AGENTS.md). They apply to people
   too.
2. Add or update tests:
   - helper or script changes need Bats tests in `tests/bats/` covering
     success, failure and cleanup paths;
   - example changes need tests in the example itself.
3. Run every check and make it pass:

   ```bash
   bash scripts/ci/01-validate.sh
   bash scripts/ci/02-test.sh
   ```

4. Pin any new action to a full commit SHA with the tag in a comment, and
   say in the pull request how you verified the SHA (see
   [docs/security.md](docs/security.md)).

## New examples

An example is a small real application with real tests, a `ci/` script
that runs locally, a reusable workflow in `.github/workflows/`, a README,
and a row in the README table. Do not add an example that only works on
one vendor's runners unless the generic version exists too.

## Style

- Plain, short sentences. Each fact lives in one place; link to it.
- Docs stay under 60 lines. Split a longer page and link the parts.
- Bash: `set -Eeuo pipefail`, two-space indent, `shfmt` formatting, helpers
  from `scripts/lib/` instead of new copies.

By contributing you agree that your contribution is licensed under the
[MIT License](LICENSE).
