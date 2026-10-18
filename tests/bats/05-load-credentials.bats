#!/usr/bin/env bats
# Tests for scripts/examples/01-load-credentials.sh. The main property: the
# value reaches the command's environment and never appears in output.

SECRET='s3cr3t-Value-42'

setup() {
  load 00-test-helper
  LOADER="${REPO_ROOT}/scripts/examples/01-load-credentials.sh"
  CRED_FILE="${BATS_TEST_TMPDIR}/creds.env"
  printf '# local test credentials\nOTHER=x\nAPI_TOKEN=%s\n' "$SECRET" >"$CRED_FILE"
  chmod 600 "$CRED_FILE"
  export CRED_FILE CRED_SOURCE=file EXPECTED="$SECRET"
  # The command checks the value without printing it.
  # shellcheck disable=SC2016 # expanded by the child shell, not here
  CHECK=(bash -c '[ "$API_TOKEN" = "$EXPECTED" ] && echo match')
  STUBS="${BATS_TEST_TMPDIR}/stubs"
  mkdir -p "$STUBS"
}

stub() {
  printf '#!/usr/bin/env bash\n%s\n' "$2" >"${STUBS}/$1"
  chmod +x "${STUBS}/$1"
}

@test "file source exports the value to the command without printing it" {
  run "$LOADER" API_TOKEN -- "${CHECK[@]}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded API_TOKEN from file"* ]]
  [[ "$output" == *"match"* ]]
  [[ "$output" != *"$SECRET"* ]]
}

@test "xtrace from the caller does not reveal the value" {
  run bash -x "$LOADER" API_TOKEN -- "${CHECK[@]}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"match"* ]]
  [[ "$output" != *"$SECRET"* ]]
}

@test "file source rejects a file readable by others" {
  chmod 644 "$CRED_FILE"
  run "$LOADER" API_TOKEN -- true
  [ "$status" -eq 1 ]
  [[ "$output" == *"must be mode 600"* ]]
}

@test "file source rejects a file inside the repository" {
  copy="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${copy}/scripts"
  cp -R "${REPO_ROOT}/scripts/lib" "${REPO_ROOT}/scripts/examples" "${copy}/scripts/"
  cp "$CRED_FILE" "${copy}/creds.env"
  chmod 600 "${copy}/creds.env"
  CRED_FILE="${copy}/creds.env" run "${copy}/scripts/examples/01-load-credentials.sh" API_TOKEN -- true
  [ "$status" -eq 1 ]
  [[ "$output" == *"must live outside the repository"* ]]
}

@test "a missing name fails without printing other values" {
  run "$LOADER" NOT_THERE -- true
  [ "$status" -eq 1 ]
  [[ "$output" == *"NOT_THERE not found in file"* ]]
  [[ "$output" != *"$SECRET"* ]]
}

@test "usage errors exit 2" {
  run "$LOADER" API_TOKEN
  [ "$status" -eq 2 ]
  run "$LOADER" API_TOKEN --
  [ "$status" -eq 2 ]
  run "$LOADER" 'bad-name' -- true
  [ "$status" -eq 2 ]
  [[ "$output" == *"invalid variable name"* ]]
}

@test "keychain source reads the item for the account and hides the value" {
  stub security "[ \"\$*\" = 'find-generic-password -s ci-credentials -a API_TOKEN -w' ] && printf '%s\n' '${SECRET}'"
  PATH="${STUBS}:${PATH}" CRED_SOURCE=keychain run "$LOADER" API_TOKEN -- "${CHECK[@]}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded API_TOKEN from keychain"* ]]
  [[ "$output" != *"$SECRET"* ]]
}

@test "1Password source reads op://VAULT/NAME/credential and hides the value" {
  stub op "[ \"\$*\" = 'read op://dev/API_TOKEN/credential' ] && printf '%s\n' '${SECRET}'"
  PATH="${STUBS}:${PATH}" CRED_SOURCE=op CRED_OP_VAULT=dev run "$LOADER" API_TOKEN -- "${CHECK[@]}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded API_TOKEN from op"* ]]
  [[ "$output" != *"$SECRET"* ]]
}

@test "auto picks the file source when no keychain or op is available" {
  stub uname 'echo Linux'
  PATH="${STUBS}:${PATH}" CRED_SOURCE=auto run "$LOADER" API_TOKEN -- "${CHECK[@]}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"loaded API_TOKEN from file"* ]]
}
