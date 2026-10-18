#!/usr/bin/env bats
# Tests for scripts/lib/cleanup.sh: cleanup runs on success, failure and
# signals, in reverse order, and never changes the exit code.

setup() {
  load test_helper
  WORK="${BATS_TEST_TMPDIR}/work dir"
  mkdir -p "$WORK"
}

@test "cleanup runs after success" {
  script="$(write_script ok.sh "cleanup_register rm -rf -- '${WORK}'")"
  run "$script"
  [ "$status" -eq 0 ]
  [ ! -e "$WORK" ]
}

@test "cleanup runs after a failure and keeps its exit code" {
  script="$(write_script fail.sh "cleanup_register rm -rf -- '${WORK}'
exit 3")"
  run "$script"
  [ "$status" -eq 3 ]
  [ ! -e "$WORK" ]
}

@test "cleanup runs when a command fails under errexit" {
  script="$(write_script errexit.sh "cleanup_register rm -rf -- '${WORK}'
false")"
  run "$script"
  [ "$status" -eq 1 ]
  [ ! -e "$WORK" ]
}

@test "cleanup runs on SIGTERM and SIGINT" {
  script="$(write_script term.sh "cleanup_register rm -rf -- '${WORK}'
kill -TERM \$\$
sleep 5")"
  run "$script"
  [ "$status" -eq 143 ]
  [ ! -e "$WORK" ]

  mkdir -p "$WORK"
  script="$(write_script int.sh "cleanup_register rm -rf -- '${WORK}'
kill -INT \$\$
sleep 5")"
  run "$script"
  [ "$status" -eq 130 ]
  [ ! -e "$WORK" ]
}

@test "cleanup commands run newest first" {
  script="$(write_script order.sh 'cleanup_register echo first
cleanup_register echo second')"
  run "$script"
  [ "$status" -eq 0 ]
  [ "$output" = $'second\nfirst' ]
}

@test "a failing cleanup command warns, the rest still run and the exit code is kept" {
  script="$(write_script partial.sh "cleanup_register rm -rf -- '${WORK}'
cleanup_register false
exit 5")"
  run "$script"
  [ "$status" -eq 5 ]
  [[ "$output" == *"[WARN] cleanup command failed (exit 1): false"* ]]
  [ ! -e "$WORK" ]
}

@test "cleanup_run is safe to call twice" {
  script="$(write_script twice.sh 'cleanup_register echo ran
cleanup_run
cleanup_run')"
  run "$script"
  [ "$status" -eq 0 ]
  [ "$output" = "ran" ]
}

@test "cleanup_temp_dir creates a directory and removes it at exit" {
  record="${BATS_TEST_TMPDIR}/path"
  script="$(write_script temp.sh "cleanup_temp_dir TMP
[ -d \"\$TMP\" ]
printf '%s' \"\$TMP\" >'${record}'")"
  run "$script"
  [ "$status" -eq 0 ]
  [ -n "$(cat "$record")" ]
  [ ! -e "$(cat "$record")" ]
}

@test "cleanup_temp_dir rejects an invalid variable name" {
  script="$(write_script badvar.sh 'cleanup_temp_dir "1bad"')"
  run "$script"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid variable name"* ]]
}
