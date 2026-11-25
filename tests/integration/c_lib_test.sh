#!/usr/bin/env bash
# Integration tests: the c-lib type with a dashed name, through a symlink on
# PATH, built, installed and used the way its README says. Needs cmake, a C
# and C++ compiler, and GoogleTest (tests/ensure-googletest.sh).

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
	command -v cmake >/dev/null 2>&1 || _fail "cmake is needed for the c-lib tests"
}

test_a_generated_c_library_builds_tests_and_installs() {
	install_on_path
	run repo-kickoff c-lib my-lib
	assert_status 0
	assert_contains "$OUT" "Created my-lib from the c-lib type."
	cd my-lib || exit 1
	run cmake -S . -B build
	assert_status 0
	run cmake --build build
	assert_status 0
	assert_file build/libmy_lib.a
	run sh -c 'cd build && ctest --output-on-failure'
	assert_status 0
	assert_contains "$OUT" "Placeholder.NamesTheLibrary" "the gtest tests ran"
	assert_contains "$OUT" "100% tests passed"
	run cmake --install build --prefix "$TEST_TMP/prefix"
	assert_status 0
	assert_file "$TEST_TMP/prefix/include/my_lib.h"
	# GNUInstallDirs picks lib or lib64, depending on the platform.
	config=$(find "$TEST_TMP/prefix" -path '*/cmake/my-lib/my-libConfig.cmake')
	assert_contains "$config" "/cmake/my-lib/my-libConfig.cmake"
}

test_another_project_uses_it_with_add_subdirectory() {
	install_on_path
	run repo-kickoff c-lib my-lib
	assert_status 0
	mkdir app
	cat >app/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.14)
project(app LANGUAGES C)
add_subdirectory(../my-lib my-lib)
add_executable(app main.c)
target_link_libraries(app PRIVATE my_lib::my_lib)
EOF
	printf '#include <stdio.h>\n#include <my_lib.h>\nint main(void) { puts(my_lib_placeholder()); return 0; }\n' >app/main.c
	run cmake -S app -B app/build
	assert_status 0
	run cmake --build app/build
	assert_status 0
	run app/build/app
	assert_status 0
	assert_eq "my-lib: placeholder - nothing implemented yet" "$OUT"
	# The library's own tests are built only when it's the top-level project.
	assert_not_exists app/build/my-lib/my_lib_test
}

test_c_library_identifiers_use_the_snake_case_name() {
	install_on_path
	run repo-kickoff c-lib my-lib
	assert_status 0
	assert_file my-lib/include/my_lib.h
	assert_file my-lib/src/my_lib.c
	assert_file my-lib/cmake/my-libConfig.cmake.in
	assert_contains "$(cat my-lib/include/my_lib.h)" "const char *my_lib_placeholder(void);"
	count=$(grep -rl '{{' my-lib | wc -l | tr -d ' ')
	assert_eq 0 "$count" "files still holding a placeholder"
}
