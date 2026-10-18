#!/usr/bin/env bats
# Tests for scripts/lib/errors.sh.

setup() {
  load test_helper
}

@test "die exits 1 by default with an [ERROR] message" {
  script="$(write_script die.sh 'die "it broke"')"
  run "$script"
  [ "$status" -eq 1 ]
  [[ "$output" == *"[ERROR] it broke"* ]]
}

@test "die keeps a custom exit code" {
  script="$(write_script die.sh 'die "bad usage" 2')"
  run "$script"
  [ "$status" -eq 2 ]
}

@test "a failing command reports file, line and exit code" {
  script="$(write_script fail.sh $'true\nfalse\necho unreachable')"
  run "$script"
  [ "$status" -eq 1 ]
  [[ "$output" == *"command failed (exit 1) at fail.sh:"*": false"* ]]
  [[ "$output" != *"unreachable"* ]]
}

@test "the error report shows command text, not secret values" {
  # shellcheck disable=SC2016 # the script must contain the literal $API_TOKEN
  script="$(write_script secret.sh 'API_TOKEN=s3cr3t-value; grep -q "$API_TOKEN" /dev/null')"
  run "$script"
  [ "$status" -eq 1 ]
  # shellcheck disable=SC2016 # match the literal text, not the value
  [[ "$output" == *'$API_TOKEN'* ]]
  [[ "$output" != *"s3cr3t-value"* ]]
}

@test "the exit code of a failing command is preserved" {
  script="$(write_script code.sh 'bash -c "exit 7"')"
  run "$script"
  [ "$status" -eq 7 ]
}

@test "require_cmd exits 127 for a missing command" {
  script="$(write_script cmd.sh 'require_cmd bash no-such-command-xyz')"
  run -127 "$script"
  [ "$status" -eq 127 ]
  [[ "$output" == *"required command not found: no-such-command-xyz"* ]]
}

@test "require_env names a missing variable and never prints values" {
  script="$(write_script env.sh 'require_env PRESENT MISSING_VAR')"
  PRESENT=visible-value run "$script"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required variable is not set: MISSING_VAR"* ]]
  [[ "$output" != *"visible-value"* ]]
}

@test "retry succeeds once a temporary failure clears" {
  counter="${BATS_TEST_TMPDIR}/count"
  script="$(write_script retry.sh "
flaky() {
  local n=\$((\$(cat '${counter}' 2>/dev/null || echo 0) + 1))
  echo \"\$n\" >'${counter}'
  [ \"\$n\" -ge 3 ]
}
retry 5 0 flaky
echo done")"
  run "$script"
  [ "$status" -eq 0 ]
  [ "$(cat "$counter")" = 3 ]
  [[ "$output" == *"attempt 2/5 failed"* ]]
  [[ "$output" == *"done"* ]]
}

@test "retry returns the last exit code when all attempts fail" {
  script="$(write_script retry.sh 'retry 2 0 bash -c "exit 4"')"
  run "$script"
  [ "$status" -eq 4 ]
  [[ "$output" == *"all 2 attempts failed (exit 4)"* ]]
}

@test "retry rejects invalid arguments" {
  script="$(write_script retry.sh 'retry 0 1 true')"
  run "$script"
  [ "$status" -eq 1 ]
  [[ "$output" == *"attempts must be a positive integer"* ]]
}

@test "SIGTERM exits 143 and SIGINT exits 130" {
  script="$(write_script term.sh 'kill -TERM $$; sleep 5')"
  run "$script"
  [ "$status" -eq 143 ]

  script="$(write_script int.sh 'kill -INT $$; sleep 5')"
  run "$script"
  [ "$status" -eq 130 ]
}
