#!/usr/bin/env bash
# Self-tests for tests/run.sh and tests/lib.sh. Each test runs a copy of the
# runner over a scratch tests folder, so the real tests aren't involved.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

# Make a scratch tests folder holding copies of the runner and its helpers.
make_scratch_tests() {
	mkdir -p scratch/tests/unit scratch/tests/integration
	cp "$REPO_ROOT/tests/run.sh" "$REPO_ROOT/tests/lib.sh" scratch/tests/
}

# write_test LEVEL FILE BODY: write a test file into the scratch tests folder.
write_test() {
	# shellcheck disable=SC2016 # $TESTS_DIR expands when the test file runs
	printf '. "$TESTS_DIR/lib.sh"\n%s\n' "$3" >"scratch/tests/$1/$2"
}

test_passing_tests_are_counted() {
	make_scratch_tests
	write_test unit a_test.sh 'test_one() { assert_eq x x; }
test_two() { assert_contains "hello world" world; }'
	run bash scratch/tests/run.sh unit
	assert_status 0
	assert_contains "$OUT" "ok   unit/a_test.sh: test_one"
	assert_contains "$OUT" "ok   unit/a_test.sh: test_two"
	assert_contains "$OUT" "unit: 2 passed, 0 failed, in 1 file(s)"
}

test_failing_assertion_is_reported_as_a_failure() {
	make_scratch_tests
	write_test unit a_test.sh 'test_good() { assert_eq x x; }
test_bad() { assert_eq expected actual "the values"; }'
	run bash scratch/tests/run.sh unit
	assert_status 1
	assert_contains "$OUT" "FAIL unit/a_test.sh: test_bad"
	assert_contains "$OUT" "the values"
	assert_contains "$OUT" "expected: expected"
	assert_contains "$OUT" "ok   unit/a_test.sh: test_good"
	assert_contains "$OUT" "unit: 1 passed, 1 failed, in 1 file(s)"
}

test_failing_command_fails_the_test() {
	make_scratch_tests
	write_test unit a_test.sh 'test_bad() { false; echo not reached; }'
	run bash scratch/tests/run.sh unit
	assert_status 1
	assert_contains "$OUT" "FAIL unit/a_test.sh: test_bad"
	assert_not_contains "$OUT" "not reached"
}

test_broken_file_is_a_failure() {
	make_scratch_tests
	write_test unit a_test.sh 'test_x() { assert_eq x x; }
if then'
	run bash scratch/tests/run.sh unit
	assert_status 1
	assert_contains "$OUT" "FAIL unit/a_test.sh: could not run the file"
}

test_empty_level_passes() {
	make_scratch_tests
	run bash scratch/tests/run.sh integration
	assert_status 0
	assert_contains "$OUT" "integration: 0 passed, 0 failed, in 0 file(s)"
}

test_unknown_level_is_a_usage_error() {
	make_scratch_tests
	run bash scratch/tests/run.sh system
	assert_status 2
	assert_contains "$ERR" "usage: tests/run.sh unit|integration"
}

test_levels_are_kept_apart() {
	make_scratch_tests
	write_test unit a_test.sh 'test_unit_only() { :; }'
	write_test integration b_test.sh 'test_integration_only() { :; }'
	run bash scratch/tests/run.sh integration
	assert_status 0
	assert_contains "$OUT" "test_integration_only"
	assert_not_contains "$OUT" "test_unit_only"
}

test_each_test_gets_a_fresh_folder_that_is_removed() {
	make_scratch_tests
	record=$TEST_TMP/record
	write_test unit a_test.sh "test_a() { pwd >>'$record'; touch left-behind; }
test_b() { assert_not_exists left-behind; pwd >>'$record'; }"
	run bash scratch/tests/run.sh unit
	assert_status 0
	first=$(sed -n 1p "$record")
	second=$(sed -n 2p "$record")
	[ "$first" != "$second" ] || _fail "both tests ran in $first"
	assert_not_exists "$first"
	assert_not_exists "$second"
}

test_run_captures_output_and_status() {
	run sh -c 'echo out; echo err >&2; exit 3'
	assert_eq out "$OUT"
	assert_eq err "$ERR"
	assert_status 3
}

test_file_assertions() {
	mkdir folder
	touch plain
	printf '#!/bin/sh\n' >tool
	chmod +x tool
	assert_dir folder
	assert_file plain
	assert_executable tool
	assert_not_exists missing
	run bash -c ". '$REPO_ROOT/tests/lib.sh'; assert_executable plain"
	assert_status 1
	assert_contains "$ERR" "not an executable file: plain"
}
