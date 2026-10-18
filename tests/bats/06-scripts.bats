#!/usr/bin/env bats
# Tests for the repository CI scripts and the runner-info example.

setup() {
  load 00-test-helper
}

@test "02-test.sh rejects an unknown suite" {
  run "${REPO_ROOT}/scripts/ci/02-test.sh" no-such-suite
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown suite: no-such-suite"* ]]
}

@test "01-validate.sh rejects an unknown mode" {
  run "${REPO_ROOT}/scripts/ci/01-validate.sh" everything
  [ "$status" -eq 2 ]
}

@test "00-install-tools.sh requires a tool list" {
  TOOLS="" run "${REPO_ROOT}/scripts/ci/00-install-tools.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}

@test "01-runner-info.sh writes a summary table without tokens" {
  export GITHUB_STEP_SUMMARY="${BATS_TEST_TMPDIR}/summary.md"
  GITHUB_TOKEN=should-not-appear EXPECTED_LABEL=rzv-ubuntu-24.04-x64-2vcpu-8gb \
    run "${REPO_ROOT}/examples/runzivo-runners/ci/01-runner-info.sh"
  [ "$status" -eq 0 ]
  grep -q '^| Expected label | rzv-ubuntu-24.04-x64-2vcpu-8gb |$' "$GITHUB_STEP_SUMMARY"
  grep -q '^| CPUs | [0-9][0-9]* |$' "$GITHUB_STEP_SUMMARY"
  run ! grep -q should-not-appear "$GITHUB_STEP_SUMMARY"
  [[ "$output" != *"should-not-appear"* ]]
}
