#!/usr/bin/env bash
# Integration tests: teach a type, then reuse it. repo-kickoff runs through a
# symlink on PATH, against a copy of the real catalog, with a fake AI that
# records each call.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

# A symlink to bin/repo-kickoff on PATH, a copy of the real catalog, and the
# fake AI logging each call to $TEST_TMP/ai.log. Work happens in work/.
setup() {
	mkdir onpath work
	ln -s "$REPO_ROOT/bin/repo-kickoff" onpath/repo-kickoff
	cp -R "$REPO_ROOT/types" catalog
	PATH=$TEST_TMP/onpath:$PATH
	export PATH
	export REPO_KICKOFF_TYPES=$TEST_TMP/catalog
	export REPO_KICKOFF_AI=$REPO_ROOT/tests/fixtures/fake-ai.sh
	export FAKE_AI_LOG=$TEST_TMP/ai.log
	cd work || exit 1
}

ai_calls() {
	if [ -f "$FAKE_AI_LOG" ]; then
		wc -l <"$FAKE_AI_LOG" | tr -d ' '
	else
		echo 0
	fi
}

test_teach_a_type_then_reuse_it_without_the_ai() {
	setup
	run repo-kickoff --yes fake-cli first
	assert_status 0
	assert_eq 1 "$(ai_calls)" "the first request calls the AI"
	assert_contains "$OUT" "Added the fake-cli type"
	assert_contains "$OUT" "Created first from the fake-cli type."
	run first/tests/smoke.sh
	assert_status 0

	run repo-kickoff fake-cli second </dev/null
	assert_status 0
	assert_eq 1 "$(ai_calls)" "the second request doesn't call the AI"
	assert_eq "Created second from the fake-cli type." "$OUT"
	assert_eq "" "$ERR"
	run second/tests/smoke.sh
	assert_status 0
}

test_a_taught_type_joins_the_catalog() {
	setup
	run repo-kickoff --yes fake-cli first
	assert_status 0
	run repo-kickoff --list
	assert_contains "$OUT" "bash-cli"
	assert_contains "$OUT" "A fake-cli type written by the fake AI"
	run repo-kickoff --check-type fake-cli
	assert_status 0
	assert_eq 1 "$(ai_calls)"
}

test_a_failed_teaching_is_retried_next_time() {
	setup
	FAKE_AI_MODE=broken run repo-kickoff --yes fake-cli first
	assert_status 1
	assert_not_exists "$TEST_TMP/catalog/fake-cli"
	run repo-kickoff --yes fake-cli first
	assert_status 0
	assert_eq 2 "$(ai_calls)" "the AI is asked again after a failed attempt"
	assert_dir first
}
