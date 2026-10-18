#!/usr/bin/env bats
# Tests for scripts/lib/paths.sh.

setup() {
  load test_helper
  # shellcheck source=../../scripts/lib/paths.sh
  source "${LIB_DIR}/paths.sh"
  ROOT="$(cd -- "$BATS_TEST_TMPDIR" && pwd -P)/root dir"
  mkdir -p "${ROOT}/sub" "${ROOT}-other"
  touch "${ROOT}/sub/file.txt"
}

@test "abs_path resolves directories and files from any working directory" {
  cd "${ROOT}/sub"
  run abs_path .
  [ "$output" = "${ROOT}/sub" ]
  run abs_path ./file.txt
  [ "$output" = "${ROOT}/sub/file.txt" ]
}

@test "abs_path resolves symlinks to the physical path" {
  ln -s "${ROOT}/sub" "${BATS_TEST_TMPDIR}/link"
  run abs_path "${BATS_TEST_TMPDIR}/link"
  [ "$output" = "${ROOT}/sub" ]
}

@test "abs_path fails for a missing path" {
  run abs_path "${ROOT}/missing"
  [ "$status" -eq 1 ]
  [[ "$output" == *"path does not exist"* ]]
}

@test "require_file and require_dir report what is missing" {
  run require_file "${ROOT}/sub/file.txt"
  [ "$status" -eq 0 ]
  run require_file "${ROOT}/sub"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required file not found"* ]]
  run require_dir "${ROOT}/nope"
  [ "$status" -eq 1 ]
}

@test "path_within accepts paths inside the root" {
  run path_within "$ROOT" "${ROOT}/sub/file.txt"
  [ "$status" -eq 0 ]
  run path_within "$ROOT" "$ROOT"
  [ "$status" -eq 0 ]
}

@test "path_within rejects traversal and sibling prefixes" {
  run path_within "$ROOT" "${ROOT}/sub/../.."
  [ "$status" -eq 1 ]
  run path_within "$ROOT" "${ROOT}-other"
  [ "$status" -eq 1 ]
  [[ "$output" == *"path is outside"* ]]
}
