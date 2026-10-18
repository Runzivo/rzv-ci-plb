# Working with AI coding agents

[AGENTS.md](../AGENTS.md) holds the rules an agent must follow. This page
covers how to ask for a pipeline and how to keep credentials out of the
conversation.

## Asking for a pipeline

- Name the stack and point the agent at its example, for example "copy
  `examples/golang` and `example-golang.yml` for this service".
- Ask for the script first and run it locally. Then ask for the workflow.
- Ask the agent to run `scripts/ci/01-validate.sh` and `scripts/ci/02-test.sh`
  and report the exact commands and results.
- Review every action SHA it adds against the tag with `gh api`.

## Credentials during local work

The agent should know where a credential comes from, never its value.

1. Keep credentials where they already live: a password manager CLI, the
   OS keychain, a cloud CLI profile, or an env file outside the repository
   with mode 600.
2. Have the agent write or reuse a small script that loads them and runs
   one command, such as
   [01-load-credentials.sh](../scripts/examples/01-load-credentials.sh):

   ```bash
   # macOS Keychain item: service ci-credentials, account GH_TOKEN
   scripts/examples/01-load-credentials.sh GH_TOKEN -- gh api user --jq .login
   # 1Password: op://dev/GH_TOKEN/credential
   CRED_SOURCE=op CRED_OP_VAULT=dev scripts/examples/01-load-credentials.sh GH_TOKEN -- make deploy-check
   ```

3. The agent runs the script. Values go into the command's environment
   only; the script logs names, never values, and turns off `set -x`.
   Its Bats tests prove this
   ([05-load-credentials.bats](../tests/bats/05-load-credentials.bats)).

Rules:

- Never paste a secret into the chat or ask the agent to print one.
- Never commit credentials. Env files stay outside the repository and are
  git-ignored if one ends up inside it.
- Prefer short-lived tokens: OIDC in CI, `gh auth token` or a cloud CLI
  session locally. Revoke a token if it appears in a transcript or log.
- Cloud CLIs with named profiles (`aws --profile`, `gcloud config
  configurations`) already keep keys out of the shell. Tell the agent the
  profile name, not the key.
