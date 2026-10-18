# Security policy

## Reporting a vulnerability

Report security problems privately. Do not open a public issue.

- Use GitHub's **Report a vulnerability** button on this repository's
  Security tab, or
- email [security@runzivo.dev](mailto:security@runzivo.dev).

Include what you found, the affected file or workflow, and steps to
reproduce. We will acknowledge the report and keep you updated until it is
resolved.

## Scope

This repository holds examples and a shell library. In scope:

- a workflow or script here that leaks secrets, allows command injection,
  or grants more permissions than it needs;
- a pinned action or tool version with a known vulnerability;
- advice in the docs that would make a reader's pipeline unsafe.

Problems in GitHub Actions itself, in third-party actions or in Runzivo's
service go to their owners. For Runzivo, use the same address above.

## Supported versions

Only the latest commit on `main` is supported.
