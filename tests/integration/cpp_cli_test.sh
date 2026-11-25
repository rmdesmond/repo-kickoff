#!/usr/bin/env bash
# Integration tests: the cpp-cli type with a dashed name, through a symlink on
# PATH, built the way its README says. Needs cmake, a C++ compiler and
# GoogleTest (tests/ensure-googletest.sh).

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
	command -v cmake >/dev/null 2>&1 || _fail "cmake is needed for the cpp-cli tests"
}

test_a_generated_cpp_repository_builds_and_runs() {
	install_on_path
	run repo-kickoff cpp-cli my-tool
	assert_status 0
	assert_contains "$OUT" "Created my-tool from the cpp-cli type."
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
	assert_status 0
	assert_eq "my-tool 0.1.0" "$OUT"
}

test_its_gtest_tests_run_with_ctest_and_pass() {
	install_on_path
	run repo-kickoff cpp-cli my-tool
	assert_status 0
	cd my-tool || exit 1
	run cmake -S . -B build
	assert_status 0
	run cmake --build build
	assert_status 0
	run sh -c 'cd build && ctest --output-on-failure'
	assert_status 0
	assert_contains "$OUT" "Program.PrintsThePlaceholderLine" "the gtest tests ran"
	assert_contains "$OUT" "100% tests passed"
}

test_cpp_identifiers_use_the_snake_case_name() {
	install_on_path
	run repo-kickoff cpp-cli my-tool
	assert_status 0
	assert_file my-tool/include/my_tool/my_tool.hpp
	assert_file my-tool/src/my_tool.cpp
	assert_contains "$(cat my-tool/include/my_tool/my_tool.hpp)" "namespace my_tool {"
	assert_contains "$(cat my-tool/src/main.cpp)" "my_tool::run("
	count=$(grep -rl '{{' my-tool | wc -l | tr -d ' ')
	assert_eq 0 "$count" "files still holding a placeholder"
}
