#!/usr/bin/env bash
# Integration tests: the c-cli type with a dashed name, through a symlink on
# PATH, built the way its README says. Needs cmake and a C compiler; uses
# GoogleTest only if it's installed.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

unset REPO_KICKOFF_TYPES

# Put a symlink to bin/repo-kickoff on PATH, and work in $TEST_TMP/work.
install_on_path() {
	mkdir onpath work
	ln -s "$REPO_ROOT/bin/repo-kickoff" onpath/repo-kickoff
	PATH=$TEST_TMP/onpath:$PATH
	export PATH
	cd work || exit 1
	command -v cmake >/dev/null 2>&1 || _fail "cmake is needed for the c-cli tests"
}

test_a_generated_c_repository_builds_and_runs() {
	install_on_path
	run repo-kickoff c-cli my-tool
	assert_status 0
	assert_contains "$OUT" "Created my-tool from the c-cli type."
	cd my-tool || exit 1
	run cmake -S . -B build
	assert_status 0
	run cmake --build build
	assert_status 0
	assert_executable build/my-tool
	run build/my-tool
	assert_status 0
	assert_eq "my-tool: placeholder - nothing implemented yet" "$OUT"
	run build/my-tool --version
	assert_eq "my-tool 0.1.0" "$OUT"
}

test_c_identifiers_use_the_snake_case_name() {
	install_on_path
	run repo-kickoff c-cli my-tool
	assert_status 0
	assert_file my-tool/include/my_tool.h
	assert_file my-tool/src/my_tool.c
	assert_contains "$(cat my-tool/include/my_tool.h)" "int my_tool_run("
	count=$(grep -rl '{{' my-tool | wc -l | tr -d ' ')
	assert_eq 0 "$count" "files still holding a placeholder"
}

test_with_googletest_installed_the_smoke_test_runs_the_unit_tests() {
	install_on_path
	"$REPO_ROOT/tests/ensure-googletest.sh" >/dev/null ||
		_fail "GoogleTest is needed for this test: run tests/ensure-googletest.sh"
	run repo-kickoff c-cli my-tool
	assert_status 0
	run my-tool/tests/smoke.sh
	assert_status 0
	assert_contains "$OUT" "smoke: running unit tests"
	assert_not_contains "$OUT" "unit tests skipped"
}
