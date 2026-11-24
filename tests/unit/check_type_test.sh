#!/usr/bin/env bash
# Unit tests for --check-type, against complete and broken fixture types
# built in a catalog in $TEST_TMP.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff

# good_type TYPE: a complete type whose smoke test checks its README names
# the repository.
good_type() {
	local dir=catalog/$1
	mkdir -p "$dir/template/tests"
	echo "A good type" >"$dir/description"
	echo "# {{NAME}}" >"$dir/template/README.md"
	cat >"$dir/template/tests/smoke.sh" <<'EOF'
#!/bin/sh
grep -q '^# kickoff-check$' README.md || { echo "README.md is wrong"; exit 1; }
echo "smoke: ok"
EOF
	chmod +x "$dir/template/tests/smoke.sh"
}

# check TYPE: run --check-type against the catalog in $TEST_TMP.
check() {
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --check-type "$1"
}

# Nothing may be left behind in the temporary folder repo-kickoff uses.
use_private_tmpdir() {
	mkdir private-tmp
	TMPDIR=$TEST_TMP/private-tmp
	export TMPDIR
}

test_complete_type_passes() {
	good_type good
	use_private_tmpdir
	check good
	assert_status 0
	assert_eq "ok: good has a description and a template, and its smoke test passes" "$OUT"
	assert_eq "" "$ERR"
	assert_eq "" "$(ls -A private-tmp)" "nothing left behind"
}

test_check_type_with_equals() {
	good_type good
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --check-type=good
	assert_status 0
}

test_no_description() {
	good_type t
	rm catalog/t/description
	check t
	assert_status 1
	assert_contains "$ERR" "t: no description file"
	assert_contains "$ERR" "t: 1 problem(s) found"
}

test_empty_description() {
	good_type t
	: >catalog/t/description
	check t
	assert_status 1
	assert_contains "$ERR" "t: the description's first line is empty"
}

test_no_template() {
	good_type t
	rm -r catalog/t/template
	check t
	assert_status 1
	assert_contains "$ERR" "t: no template folder"
}

test_no_smoke_test() {
	good_type t
	rm catalog/t/template/tests/smoke.sh
	check t
	assert_status 1
	assert_contains "$ERR" "t: no template/tests/smoke.sh"
}

test_smoke_test_not_executable() {
	good_type t
	chmod -x catalog/t/template/tests/smoke.sh
	check t
	assert_status 1
	assert_contains "$ERR" "t: template/tests/smoke.sh is not executable"
}

test_failing_smoke_test_is_reported_with_its_output() {
	good_type t
	echo "# not the name" >catalog/t/template/README.md
	use_private_tmpdir
	check t
	assert_status 1
	assert_contains "$ERR" "t: the smoke test failed in a generated repository; its output:"
	assert_contains "$ERR" "    README.md is wrong"
	assert_eq "" "$OUT"
	assert_eq "" "$(ls -A private-tmp)" "nothing left behind"
}

test_every_problem_is_reported() {
	good_type t
	rm catalog/t/description catalog/t/template/tests/smoke.sh
	check t
	assert_status 1
	assert_contains "$ERR" "t: no description file"
	assert_contains "$ERR" "t: no template/tests/smoke.sh"
	assert_contains "$ERR" "t: 2 problem(s) found"
}

test_unknown_and_invalid_types() {
	good_type good
	check nope
	assert_status 1
	assert_contains "$ERR" "unknown type: nope"
	check ../catalog
	assert_status 2
	assert_contains "$ERR" "invalid type: ../catalog"
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --check-type
	assert_status 2
	assert_contains "$ERR" "--check-type needs a type"
}

test_check_writes_nothing_in_the_current_folder() {
	good_type good
	mkdir work
	cd work || exit 1
	check good
	assert_status 0
	assert_eq "" "$(ls -A)"
}
