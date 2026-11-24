#!/usr/bin/env bash
# Unit tests for name validation, --dest, and never leaving a partial
# repository behind. They use the fixture catalog through REPO_KICKOFF_TYPES.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff
export REPO_KICKOFF_TYPES=$REPO_ROOT/tests/fixtures/types

# The entries of the current folder, hidden ones included, one per line.
listing() {
	ls -A "${1:-.}"
}

test_valid_names_are_accepted() {
	for name in a greet my-tool tool2 x-1-y; do
		run "$KICKOFF" sample "$name"
		assert_status 0
		assert_dir "$name"
	done
}

test_invalid_names_are_usage_errors_that_write_nothing() {
	for name in Greet 2fast -dash my_tool 'my tool' a/b ../up . my.tool ÉCOLE 'tab	x'; do
		run "$KICKOFF" sample -- "$name"
		assert_status 2
		assert_contains "$ERR" "invalid name: $name"
		assert_eq "" "$(listing)" "nothing written for name '$name'"
	done
}

test_invalid_type_is_a_usage_error() {
	run "$KICKOFF" ../fixtures greet
	assert_status 2
	assert_contains "$ERR" "invalid type: ../fixtures"
	assert_eq "" "$(listing)"
}

test_dest_puts_the_repository_in_that_folder() {
	mkdir projects
	run "$KICKOFF" --dest projects sample greet
	assert_status 0
	assert_contains "$OUT" "Created projects/greet from the sample type."
	assert_file projects/greet/README.md
	assert_not_exists greet
}

test_dest_with_equals_and_trailing_slash() {
	mkdir projects
	run "$KICKOFF" --dest=projects/ sample greet
	assert_status 0
	assert_contains "$OUT" "Created projects/greet from the sample type."
	assert_file projects/greet/README.md
}

test_dest_can_be_an_absolute_path() {
	mkdir -p deep/projects
	mkdir elsewhere
	cd elsewhere || exit 1
	run "$KICKOFF" sample greet --dest "$TEST_TMP/deep/projects"
	assert_status 0
	assert_file "$TEST_TMP/deep/projects/greet/README.md"
	assert_eq "" "$(listing)"
}

test_missing_dest_folder_is_an_error() {
	run "$KICKOFF" --dest nowhere sample greet
	assert_status 1
	assert_contains "$ERR" "destination folder does not exist: nowhere"
	assert_eq "" "$(listing)"
}

test_dest_without_a_folder_is_a_usage_error() {
	run "$KICKOFF" sample greet --dest
	assert_status 2
	assert_contains "$ERR" "--dest needs a folder"
}

test_existing_destination_is_refused_and_untouched() {
	mkdir -p projects/greet
	echo mine >projects/greet/file
	run "$KICKOFF" --dest projects sample greet
	assert_status 1
	assert_contains "$ERR" "projects/greet already exists"
	assert_eq "file" "$(listing projects/greet)"
	assert_eq "greet" "$(listing projects)" "no staging folder left"
}

test_existing_file_or_symlink_is_refused() {
	echo mine >greet
	run "$KICKOFF" sample greet
	assert_status 1
	assert_eq mine "$(cat greet)"
	ln -s nowhere other
	run "$KICKOFF" sample other
	assert_status 1
	assert_contains "$ERR" "other already exists"
}

test_failure_part_way_leaves_nothing_behind() {
	# A type whose second file can't be read: generating fails part-way.
	mkdir -p catalog/broken/template
	echo "readable {{NAME}}" >catalog/broken/template/a.txt
	echo "unreadable" >catalog/broken/template/b.txt
	chmod 000 catalog/broken/template/b.txt
	if [ -r catalog/broken/template/b.txt ]; then
		chmod 644 catalog/broken/template/b.txt
		_fail "running as a user who can read mode-000 files; this test can't work"
	fi
	mkdir projects
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --dest projects broken greet
	chmod 644 catalog/broken/template/b.txt
	assert_status 1
	assert_eq "" "$(listing projects)" "no partial repository or staging folder"
}

test_success_leaves_no_staging_folder() {
	run "$KICKOFF" sample greet
	assert_status 0
	assert_eq "greet" "$(listing)"
}
