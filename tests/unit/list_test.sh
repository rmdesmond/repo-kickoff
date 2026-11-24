#!/usr/bin/env bash
# Unit tests for --list, against fixture catalogs.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff

# add_type TYPE [DESCRIPTION]: add a type to the catalog in $TEST_TMP/catalog.
add_type() {
	mkdir -p "catalog/$1/template"
	if [ $# -gt 1 ]; then
		printf '%s\n' "$2" >"catalog/$1/description"
	fi
}

test_lists_types_sorted_with_descriptions_lined_up() {
	add_type zeta "The last one"
	add_type alpha "The first one"
	add_type python-cli "A Python command-line tool"
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --list
	assert_status 0
	assert_eq "alpha       The first one
python-cli  A Python command-line tool
zeta        The last one" "$OUT"
	assert_eq "" "$ERR"
}

test_type_without_a_description() {
	add_type alpha "The first one"
	add_type bare
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --list
	assert_status 0
	assert_eq "alpha  The first one
bare   (no description)" "$OUT"
}

test_only_the_first_line_of_a_description_is_shown() {
	add_type alpha "Line one
Line two"
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --list
	assert_eq "alpha  Line one" "$OUT"
}

test_files_in_the_catalog_are_not_types() {
	add_type alpha "The first one"
	echo notes >catalog/README.md
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --list
	assert_eq "alpha  The first one" "$OUT"
}

test_empty_catalog() {
	mkdir catalog
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --list
	assert_status 0
	assert_eq "" "$OUT"
	assert_contains "$ERR" "no types in $TEST_TMP/catalog"
}

test_real_catalog_lists_bash_cli() {
	unset REPO_KICKOFF_TYPES
	run "$KICKOFF" --list
	assert_status 0
	line=$(printf '%s\n' "$OUT" | grep '^bash-cli ')
	assert_contains "$line" "A command-line tool written as a single bash script"
}

test_help_mentions_list() {
	run "$KICKOFF" --help
	assert_contains "$OUT" "repo-kickoff --list"
	assert_contains "$OUT" "--list       list the known types and exit"
}
