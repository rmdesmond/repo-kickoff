#!/usr/bin/env bash
# Unit tests for the bash-cli type in the real catalog: generate a repository
# in a temporary folder, then run its command and its smoke test.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff
unset REPO_KICKOFF_TYPES

test_type_has_a_one_line_description() {
	file=$REPO_ROOT/types/bash-cli/description
	assert_file "$file"
	assert_eq 1 "$(wc -l <"$file" | tr -d ' ')" "lines in the description"
	[ -n "$(cat "$file")" ] || _fail "the description is empty"
}

test_generates_the_expected_files() {
	run "$KICKOFF" bash-cli greet
	assert_status 0
	assert_executable greet/bin/greet
	assert_executable greet/tests/smoke.sh
	assert_file greet/README.md
	assert_file greet/.gitignore
	assert_contains "$(cat greet/README.md)" "# greet"
	assert_not_contains "$(cat greet/README.md greet/bin/greet greet/tests/smoke.sh)" "{{NAME}}"
}

test_command_prints_a_placeholder_line_naming_itself() {
	run "$KICKOFF" bash-cli greet
	run greet/bin/greet
	assert_status 0
	assert_eq "greet: placeholder - nothing implemented yet" "$OUT"
}

test_command_supports_help_and_version() {
	run "$KICKOFF" bash-cli my-tool
	run my-tool/bin/my-tool --help
	assert_status 0
	assert_contains "$OUT" "Usage: my-tool"
	run my-tool/bin/my-tool --version
	assert_status 0
	assert_eq "my-tool 0.1.0" "$OUT"
	run my-tool/bin/my-tool --bogus
	assert_status 2
	assert_contains "$ERR" "my-tool: unknown argument: --bogus"
}

test_smoke_test_passes_from_any_folder() {
	run "$KICKOFF" bash-cli greet
	mkdir elsewhere
	cd elsewhere || exit 1
	run ../greet/tests/smoke.sh
	assert_status 0
	assert_eq "smoke: ok" "$OUT"
}

test_smoke_test_fails_when_the_command_is_wrong() {
	run "$KICKOFF" bash-cli greet
	printf '#!/bin/sh\necho something else\n' >greet/bin/greet
	run greet/tests/smoke.sh
	assert_status 1
	assert_contains "$ERR" "unexpected output: something else"
}

test_generated_shell_files_pass_shellcheck() {
	command -v shellcheck >/dev/null || _fail "shellcheck is not installed"
	run "$KICKOFF" bash-cli greet
	run shellcheck greet/bin/greet greet/tests/smoke.sh
	assert_status 0
}
