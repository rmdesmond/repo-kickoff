#!/usr/bin/env bash
# Unit tests for generating a repository from a catalog type. They use the
# fixture catalog in tests/fixtures/types, through REPO_KICKOFF_TYPES.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff
export REPO_KICKOFF_TYPES=$REPO_ROOT/tests/fixtures/types

test_copies_the_template_to_a_folder_named_after_the_repo() {
	run "$KICKOFF" sample greet
	assert_status 0
	assert_contains "$OUT" "Created greet from the sample type."
	assert_file greet/README.md
	assert_file greet/.hidden
	assert_file greet/bin/greet
	assert_file greet/greet-docs/greet/guide.md
	count=$(find greet -type f | wc -l | tr -d ' ')
	assert_eq 4 "$count" "number of files generated"
}

test_replaces_the_name_in_file_contents() {
	run "$KICKOFF" sample greet
	assert_status 0
	assert_eq "# greet

greet is made by greet.
Keep this: {NAME} and {{OTHER}}." "$(cat greet/README.md)"
	assert_eq "hidden greet" "$(cat greet/.hidden)"
	assert_eq "guide for greet" "$(cat greet/greet-docs/greet/guide.md)"
}

test_replaces_the_name_in_file_and_folder_names() {
	run "$KICKOFF" sample greet
	assert_status 0
	assert_dir greet/greet-docs/greet
	assert_not_exists "greet/{{NAME}}-docs"
	assert_not_exists "greet/bin/{{NAME}}"
}

test_keeps_executable_bits() {
	run "$KICKOFF" sample greet
	assert_status 0
	assert_executable greet/bin/greet
	[ ! -x greet/README.md ] || _fail "README.md should not be executable"
	run greet/bin/greet
	assert_eq "greet runs" "$OUT"
}

test_unknown_type_names_the_known_types() {
	run "$KICKOFF" no-such-type greet
	assert_status 1
	assert_contains "$ERR" "unknown type: no-such-type"
	assert_contains "$ERR" "known types: sample"
	assert_not_exists greet
}

test_unknown_type_with_an_empty_catalog() {
	mkdir empty
	REPO_KICKOFF_TYPES=$TEST_TMP/empty run "$KICKOFF" sample greet
	assert_status 1
	assert_contains "$ERR" "known types: (none)"
}

test_type_without_a_template_is_an_error() {
	mkdir -p catalog/broken
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" broken greet
	assert_status 1
	assert_contains "$ERR" "type broken has no template folder"
	assert_not_exists greet
}

test_existing_destination_is_left_alone() {
	mkdir greet
	echo mine >greet/file
	run "$KICKOFF" sample greet
	assert_status 1
	assert_contains "$ERR" "greet already exists"
	assert_eq mine "$(cat greet/file)"
	assert_not_exists greet/README.md
}

test_catalog_can_be_overridden() {
	run "$KICKOFF" --help
	assert_contains "$OUT" "Types are read from: $REPO_KICKOFF_TYPES"
}

# A catalog type "snake" in $TEST_TMP/catalog, whose template uses
# {{NAME_SNAKE}} as well as {{NAME}}.
make_snake_type() {
	local t=catalog/snake/template
	mkdir -p "$t/src/{{NAME_SNAKE}}" "$t/tests"
	echo "A type using NAME_SNAKE" >catalog/snake/description
	printf 'package {{NAME_SNAKE}}\n' >"$t/src/{{NAME_SNAKE}}/{{NAME_SNAKE}}.txt"
	printf '{{NAME}} imports {{NAME_SNAKE}}; {{NAME_SNAKE}} is {{NAME}}\n' >"$t/both.txt"
	printf '#!/bin/sh\nexit 0\n' >"$t/tests/smoke.sh"
	chmod +x "$t/tests/smoke.sh"
}

test_replaces_the_snake_name_in_file_contents() {
	make_snake_type
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" snake my-cool-tool
	assert_status 0
	assert_eq "package my_cool_tool" "$(cat my-cool-tool/src/my_cool_tool/my_cool_tool.txt)"
}

test_replaces_the_snake_name_in_file_and_folder_names() {
	make_snake_type
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" snake my-tool
	assert_status 0
	assert_dir my-tool/src/my_tool
	assert_file my-tool/src/my_tool/my_tool.txt
	assert_not_exists "my-tool/src/{{NAME_SNAKE}}"
	count=$(find my-tool -name '*{{*' | wc -l | tr -d ' ')
	assert_eq 0 "$count" "paths still holding a placeholder"
}

test_snake_name_of_a_name_without_dashes_is_the_name() {
	make_snake_type
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" snake greet2
	assert_status 0
	assert_eq "package greet2" "$(cat greet2/src/greet2/greet2.txt)"
}

test_replaces_both_placeholders_in_one_file() {
	make_snake_type
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" snake my-tool
	assert_status 0
	assert_eq "my-tool imports my_tool; my_tool is my-tool" "$(cat my-tool/both.txt)"
}
