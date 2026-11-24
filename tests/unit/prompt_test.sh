#!/usr/bin/env bash
# Unit tests for asking for a missing type and name. They pipe answers in
# through --interactive, against a fixture catalog with two types.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff

# A catalog with two types, alpha and beta, each making a README.
make_catalog() {
	local type
	for type in alpha beta; do
		mkdir -p "catalog/$type/template"
		echo "The $type type" >"catalog/$type/description"
		echo "# {{NAME}} ($type)" >"catalog/$type/template/README.md"
	done
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog
	export REPO_KICKOFF_TYPES
	mkdir work
	cd work || exit 1
}

# answers LINE...: write the answers, one per line, to $TEST_TMP/answers.
answers() {
	printf '%s\n' "$@" >"$TEST_TMP/answers"
}

test_choose_the_type_by_number_and_give_a_name() {
	make_catalog
	answers 2 greet
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	assert_contains "$ERR" "Known types:"
	assert_contains "$ERR" "  1) alpha  The alpha type"
	assert_contains "$ERR" "  2) beta   The beta type"
	assert_contains "$ERR" "Type (number or name): "
	assert_contains "$ERR" "Name of the new repository: "
	assert_eq "Created greet from the beta type." "$OUT" "only the result on stdout"
	assert_eq "# greet (beta)" "$(cat greet/README.md)"
}

test_choose_the_type_by_name() {
	make_catalog
	answers alpha greet
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	assert_eq "# greet (alpha)" "$(cat greet/README.md)"
}

test_invalid_choices_are_asked_again() {
	make_catalog
	answers 0 3 "" gamma Alpha ../catalog 1 greet
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	for bad in 0 3 "" gamma Alpha ../catalog; do
		assert_contains "$ERR" "Not a known type: '$bad'"
	done
	assert_eq "# greet (alpha)" "$(cat greet/README.md)"
}

test_invalid_names_are_asked_again() {
	make_catalog
	answers 1 "" Greet my_tool "my tool" greet
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	for bad in "" Greet my_tool "my tool"; do
		assert_contains "$ERR" "Not a valid name: '$bad'"
	done
	assert_dir greet
}

test_existing_name_is_asked_again() {
	make_catalog
	mkdir taken
	answers 1 taken greet
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	assert_contains "$ERR" "taken already exists"
	assert_dir greet
}

test_only_the_missing_name_is_asked_for() {
	make_catalog
	answers greet
	run "$KICKOFF" --interactive beta <"$TEST_TMP/answers"
	assert_status 0
	assert_not_contains "$ERR" "Known types:"
	assert_eq "# greet (beta)" "$(cat greet/README.md)"
}

test_prompts_respect_dest() {
	make_catalog
	mkdir -p projects/taken
	answers 1 taken greet
	run "$KICKOFF" --interactive --dest projects <"$TEST_TMP/answers"
	assert_status 0
	assert_contains "$ERR" "projects/taken already exists"
	assert_eq "Created projects/greet from the alpha type." "$OUT"
}

test_last_answer_without_a_newline_counts() {
	make_catalog
	printf '1\ngreet' >"$TEST_TMP/answers"
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 0
	assert_dir greet
}

test_running_out_of_answers_writes_nothing() {
	make_catalog
	answers 1
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 1
	assert_contains "$ERR" "no answer for the name"
	assert_eq "" "$(ls -A)"
	answers
	: >"$TEST_TMP/answers"
	run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 1
	assert_contains "$ERR" "no answer for the type"
}

test_without_a_terminal_missing_arguments_are_usage_errors() {
	make_catalog
	run "$KICKOFF" </dev/null
	assert_status 2
	assert_contains "$ERR" "missing <type>"
	assert_not_contains "$ERR" "Known types:"
	answers greet
	run "$KICKOFF" alpha <"$TEST_TMP/answers"
	assert_status 2
	assert_contains "$ERR" "missing <name>"
	assert_eq "" "$(ls -A)"
}

test_empty_catalog_is_an_error() {
	mkdir catalog
	answers 1 greet
	REPO_KICKOFF_TYPES=$TEST_TMP/catalog run "$KICKOFF" --interactive <"$TEST_TMP/answers"
	assert_status 1
	assert_contains "$ERR" "no types in $TEST_TMP/catalog"
}

test_help_mentions_interactive() {
	run "$KICKOFF" --help
	assert_contains "$OUT" "--interactive"
	assert_contains "$OUT" "At a terminal, a missing <type> or <name> is asked for."
}
