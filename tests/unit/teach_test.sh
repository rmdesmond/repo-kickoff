#!/usr/bin/env bash
# Unit tests for teaching an unknown type: asking first, checking what the AI
# wrote, removing a type that fails, and warning about changes elsewhere. A
# fake AI (tests/fixtures/fake-ai.sh) stands in for Claude.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff

# An empty catalog in $TEST_TMP/catalog, the fake AI logging its calls to
# $TEST_TMP/ai.log, and work done in $TEST_TMP/work.
setup() {
	mkdir catalog work private-tmp
	export REPO_KICKOFF_TYPES=$TEST_TMP/catalog
	export REPO_KICKOFF_AI=$REPO_ROOT/tests/fixtures/fake-ai.sh
	export FAKE_AI_LOG=$TEST_TMP/ai.log
	export TMPDIR=$TEST_TMP/private-tmp
	cd work || exit 1
}

# The number of times the fake AI was called.
ai_calls() {
	if [ -f "$FAKE_AI_LOG" ]; then
		wc -l <"$FAKE_AI_LOG" | tr -d ' '
	else
		echo 0
	fi
}

test_yes_teaches_the_type_then_generates_the_repository() {
	setup
	run "$KICKOFF" --yes fresh greet
	assert_status 0
	assert_eq 1 "$(ai_calls)"
	assert_contains "$OUT" "Added the fresh type to $TEST_TMP/catalog/fresh."
	assert_contains "$OUT" "Review it, then commit it to keep it: git -C $REPO_ROOT add "
	assert_contains "$OUT" "Created greet from the fresh type."
	assert_contains "$ERR" "checking the new fresh type"
	assert_file "$TEST_TMP/catalog/fresh/description"
	assert_eq "# greet" "$(cat greet/README.md)"
	assert_eq "" "$(ls -A "$TEST_TMP/private-tmp")" "nothing left in TMPDIR"
}

test_short_yes_option() {
	setup
	run "$KICKOFF" -y fresh greet
	assert_status 0
	assert_dir greet
}

test_asks_before_calling_the_ai() {
	setup
	printf 'y\n' >answers
	run "$KICKOFF" --interactive fresh greet <answers
	assert_status 0
	assert_contains "$ERR" "The catalog has no fresh type. Ask the AI command to add it? [y/N] "
	assert_eq 1 "$(ai_calls)"
	assert_dir greet
}

test_declining_writes_nothing() {
	for answer in n no "" maybe; do
		printf '%s\n' "$answer" >"$TEST_TMP/answers"
		rm -rf "$TEST_TMP/work" "$TEST_TMP/catalog" "$TEST_TMP/private-tmp"
		setup
		run "$KICKOFF" --interactive fresh greet <"$TEST_TMP/answers"
		assert_status 1
		assert_contains "$ERR" "not adding the fresh type"
		assert_eq 0 "$(ai_calls)" "the AI isn't called after '$answer'"
		assert_eq "" "$(ls -A "$TEST_TMP/catalog")"
		assert_eq "" "$(ls -A)"
		cd "$TEST_TMP" || exit 1
	done
}

test_without_a_terminal_or_yes_it_refuses() {
	setup
	run "$KICKOFF" fresh greet </dev/null
	assert_status 1
	assert_contains "$ERR" "unknown type: fresh"
	assert_contains "$ERR" "run again with --yes (or at a terminal)"
	assert_eq 0 "$(ai_calls)"
	assert_eq "" "$(ls -A "$TEST_TMP/catalog")"
}

test_the_name_is_asked_for_before_the_ai_runs() {
	setup
	printf 'y\n' >answers
	run "$KICKOFF" --interactive fresh <answers
	assert_status 1
	assert_contains "$ERR" "no answer for the name"
	assert_eq 0 "$(ai_calls)" "no AI call without a name"
	printf 'y\ngreet\n' >answers
	run "$KICKOFF" --interactive fresh <answers
	assert_status 0
	assert_dir greet
}

test_existing_destination_is_refused_before_the_ai_runs() {
	setup
	mkdir greet
	run "$KICKOFF" --yes fresh greet
	assert_status 1
	assert_contains "$ERR" "greet already exists"
	assert_eq 0 "$(ai_calls)"
}

test_a_type_that_fails_its_check_is_removed() {
	setup
	FAKE_AI_MODE=broken run "$KICKOFF" --yes fresh greet
	assert_status 1
	assert_contains "$ERR" "fresh: the smoke test failed in a generated repository"
	assert_contains "$ERR" "README.md is not titled with the name"
	assert_contains "$ERR" "the new fresh type failed its check, so it was removed: $TEST_TMP/catalog/fresh"
	assert_not_exists "$TEST_TMP/catalog/fresh"
	assert_not_exists greet
	assert_eq "" "$(ls -A "$TEST_TMP/private-tmp")" "nothing left in TMPDIR"
}

test_a_failing_ai_leaves_no_partial_type() {
	setup
	FAKE_AI_MODE=fail run "$KICKOFF" --yes fresh greet
	assert_status 1
	assert_contains "$ERR" "the AI command failed (exit 3)"
	assert_not_exists "$TEST_TMP/catalog/fresh"
	assert_not_exists greet
}

test_teach_option_checks_and_removes_a_failing_type() {
	setup
	FAKE_AI_MODE=broken run "$KICKOFF" --teach fresh
	assert_status 1
	assert_not_exists "$TEST_TMP/catalog/fresh"
	run "$KICKOFF" --teach fresh
	assert_status 0
	assert_contains "$OUT" "Added the fresh type"
	assert_dir "$TEST_TMP/catalog/fresh"
	assert_eq "" "$(ls -A)" "--teach generates no repository"
}

# A catalog at types/ inside a git working copy, like the real one.
git_catalog() {
	git init -q "$TEST_TMP/clone"
	mkdir "$TEST_TMP/clone/types"
	echo notes >"$TEST_TMP/clone/notes.txt"
	REPO_KICKOFF_TYPES=$TEST_TMP/clone/types
}

test_changes_outside_the_type_are_reported() {
	setup
	git_catalog
	FAKE_AI_MODE=outside run "$KICKOFF" --yes fresh greet
	assert_status 0
	assert_contains "$ERR" "warning: the AI command also changed types/stray.txt, outside types/fresh/"
	assert_not_contains "$ERR" "notes.txt" "a change that was there before isn't reported"
	assert_not_contains "$ERR" "types/fresh/description"
	assert_dir greet
}

test_no_warning_when_the_ai_stays_inside_the_type() {
	setup
	git_catalog
	run "$KICKOFF" --yes fresh greet
	assert_status 0
	assert_not_contains "$ERR" "warning"
}

test_hint_is_added_to_the_prompt() {
	setup
	run "$KICKOFF" --yes --hint "Build with CMake; test with GoogleTest." fresh greet
	assert_status 0
	assert_contains "$(cat "$FAKE_AI_LOG.prompt")" "## Requirements from the user"
	assert_contains "$(cat "$FAKE_AI_LOG.prompt")" "Build with CMake; test with GoogleTest."
	assert_dir greet
}

test_without_a_hint_the_prompt_has_no_requirements_section() {
	setup
	run "$KICKOFF" --yes fresh greet
	assert_status 0
	assert_not_contains "$(cat "$FAKE_AI_LOG.prompt")" "Requirements from the user"
}

test_hint_works_with_teach_and_an_equals_sign() {
	setup
	run "$KICKOFF" --teach fresh --hint="Use make."
	assert_status 0
	assert_contains "$(cat "$FAKE_AI_LOG.prompt")" "Use make."
}

test_hint_works_when_asked_at_a_terminal() {
	setup
	printf 'y\n' >answers
	run "$KICKOFF" --interactive --hint "Keep it small." fresh greet <answers
	assert_status 0
	assert_contains "$(cat "$FAKE_AI_LOG.prompt")" "Keep it small."
}

test_hint_keeps_several_lines() {
	setup
	run "$KICKOFF" --teach fresh --hint "first line
second line & a \\ backslash"
	assert_status 0
	assert_contains "$(cat "$FAKE_AI_LOG.prompt")" "first line
second line & a \\ backslash"
}

test_hint_without_teaching_is_a_usage_error() {
	setup
	"$KICKOFF" --teach known >/dev/null 2>&1
	rm -f "$FAKE_AI_LOG"
	run "$KICKOFF" --hint "x" known greet
	assert_status 2
	assert_contains "$ERR" "--hint is only for teaching a new type, and the catalog already has known"
	assert_not_exists greet
	run "$KICKOFF" --hint "x" --list
	assert_status 2
	assert_contains "$ERR" "not with --list"
	run "$KICKOFF" --hint "x" --check-type known
	assert_status 2
	assert_contains "$ERR" "not with --check-type"
	run "$KICKOFF" --hint
	assert_status 2
	assert_contains "$ERR" "--hint needs text"
	assert_eq 0 "$(ai_calls)"
}

test_hint_needs_the_type_when_prompting() {
	setup
	printf '1\ngreet\n' >answers
	run "$KICKOFF" --interactive --hint "x" <answers
	assert_status 2
	assert_contains "$ERR" "give the <type> to teach"
}
