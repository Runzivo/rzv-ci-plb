#!/usr/bin/env bats
# Tests for scripts/lib/01-logging.sh.

setup() {
  load 00-test-helper
  # shellcheck source=../../scripts/lib/01-logging.sh
  source "${LIB_DIR}/01-logging.sh"
}

@test "log_info writes a timestamped [INFO] line to stderr only" {
  run --separate-stderr log_info "hello world"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [[ "$stderr" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z\ \[INFO\]\ hello\ world$ ]]
}

@test "log_warn and log_error add annotations only inside GitHub Actions" {
  run --separate-stderr log_error "broken"
  [[ "$stderr" == *"[ERROR] broken"* ]]
  [[ "$stderr" != *"::error::"* ]]

  GITHUB_ACTIONS=true run --separate-stderr log_warn "careful"
  [[ "$stderr" == *"[WARN] careful"* ]]
  [[ "$stderr" == *"::warning::careful"* ]]
}

@test "annotations escape percent signs and newlines" {
  GITHUB_ACTIONS=true run --separate-stderr log_error $'50% done\nnext'
  [[ "$stderr" == *"::error::50%25 done%0Anext"* ]]
}

@test "log groups use workflow commands in Actions and a plain header locally" {
  run --separate-stderr log_group_start "Build"
  [ "$stderr" = "==> Build" ]

  GITHUB_ACTIONS=true run --separate-stderr log_group_start "Build"
  [ "$stderr" = "::group::Build" ]
  GITHUB_ACTIONS=true run --separate-stderr log_group_end
  [ "$stderr" = "::endgroup::" ]
}

@test "summary_add appends to GITHUB_STEP_SUMMARY and is a no-op without it" {
  run summary_add "no file"
  [ "$status" -eq 0 ]

  export GITHUB_STEP_SUMMARY="${BATS_TEST_TMPDIR}/summary.md"
  summary_add "- one"
  summary_add "- two"
  [ "$(cat "$GITHUB_STEP_SUMMARY")" = $'- one\n- two' ]
}
