#!/usr/bin/env bash
# Unit tests for the swappable AI command and --teach, with a fake AI in
# place of Claude.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff
FAKE_AI=$REPO_ROOT/tests/fixtures/fake-ai.sh

# An empty catalog in $TEST_TMP/catalog, the fake AI logging to
# $TEST_TMP/ai.log, and a private TMPDIR to check nothing is left behind.
setup() {
	mkdir catalog private-tmp
	export REPO_KICKOFF_TYPES=$TEST_TMP/catalog
	export REPO_KICKOFF_AI=$FAKE_AI
	export FAKE_AI_LOG=$TEST_TMP/ai.log
	export TMPDIR=$TEST_TMP/private-tmp
}

test_teach_calls_the_ai_with_the_type_and_the_catalog() {
	setup
	run "$KICKOFF" --teach python-cli
	assert_status 0
	assert_eq "call python-cli $(cd -P catalog && pwd)" "$(cat ai.log)"
	assert_file catalog/python-cli/description
	assert_contains "$OUT" "Added the python-cli type to $TEST_TMP/catalog/python-cli."
	assert_contains "$ERR" "asking the AI command to add the python-cli type: $FAKE_AI"
	assert_contains "$ERR" "fake-ai: done (python-cli)" "the AI's output is shown on stderr"
}

test_the_prompt_describes_the_type_contract() {
	setup
	run "$KICKOFF" --teach python-cli
	assert_status 0
	prompt=$(cat ai.log.prompt)
	catalog=$(cd -P catalog && pwd)
	assert_contains "$prompt" "new project type, \`python-cli\`"
	assert_contains "$prompt" "Write only inside this folder"
	assert_contains "$prompt" "    $catalog/python-cli"
	assert_contains "$prompt" "description          exactly one line"
	assert_contains "$prompt" "tests/smoke.sh     required, executable"
	assert_contains "$prompt" "replaces every \`{{NAME}}\` with the name"
	assert_contains "$prompt" "$REPO_ROOT/bin/repo-kickoff --check-type python-cli"
	assert_not_contains "$prompt" "{{TYPE}}"
	assert_not_contains "$prompt" "{{TYPE_DIR}}"
	assert_not_contains "$prompt" "{{KICKOFF}}"
	assert_not_contains "$prompt" "{{CATALOG}}"
	assert_eq "" "$(ls -A private-tmp)" "the prompt file is removed"
}

test_the_ai_gets_no_terminal_input() {
	setup
	cat >ai.sh <<'EOF'
#!/bin/sh
if read -r line; then echo "read: $line" >&2; exit 1; fi
mkdir -p "$2/$1"
EOF
	chmod +x ai.sh
	echo "an answer meant for repo-kickoff" >answers
	REPO_KICKOFF_AI=$TEST_TMP/ai.sh run "$KICKOFF" --teach t <answers
	assert_status 0
}

test_a_failing_ai_command_is_an_error() {
	setup
	FAKE_AI_MODE=fail run "$KICKOFF" --teach t
	assert_status 1
	assert_contains "$ERR" "fake-ai: giving up"
	assert_contains "$ERR" "the AI command failed (exit 3)"
}

test_an_ai_that_writes_nothing_is_an_error() {
	setup
	FAKE_AI_MODE=nothing run "$KICKOFF" --teach t
	assert_status 1
	assert_contains "$ERR" "the AI command did not write $TEST_TMP/catalog/t"
}

test_existing_and_invalid_types_are_refused_without_calling_the_ai() {
	setup
	mkdir catalog/taken
	run "$KICKOFF" --teach taken
	assert_status 1
	assert_contains "$ERR" "the catalog already has a taken type"
	run "$KICKOFF" --teach ../escape
	assert_status 2
	assert_contains "$ERR" "invalid type: ../escape"
	run "$KICKOFF" --teach
	assert_status 2
	assert_contains "$ERR" "--teach needs a type"
	assert_not_exists ai.log
}

test_default_ai_without_claude_says_so_and_writes_nothing() {
	setup
	unset REPO_KICKOFF_AI
	# A PATH with the tools repo-kickoff needs, but no claude.
	mkdir tools
	for tool in bash sh sed awk cat mktemp rm dirname basename readlink sort find mkdir mv chmod wc tr ls; do
		path=$(command -v "$tool") && ln -s "$path" "tools/$tool"
	done
	PATH=$TEST_TMP/tools run "$KICKOFF" --teach python-cli
	assert_status 1
	assert_contains "$ERR" "claude is not installed, so the python-cli type can't be taught"
	assert_eq "" "$(ls -A catalog)"
	assert_eq "" "$(ls -A private-tmp)"
}

test_default_ai_runs_claude_print_mode_with_limited_tools() {
	setup
	unset REPO_KICKOFF_AI
	# A stand-in claude on PATH that records its arguments.
	mkdir bin
	cat >bin/claude <<'EOF'
#!/bin/sh
pwd >"$FAKE_AI_LOG.cwd"
for arg in "$@"; do printf '%s\n' "$arg"; done >"$FAKE_AI_LOG.args"
mkdir -p "$REPO_KICKOFF_TYPES/python-cli"
EOF
	chmod +x bin/claude
	PATH=$TEST_TMP/bin:$PATH run "$KICKOFF" --teach python-cli
	assert_status 0
	args=$(cat ai.log.args)
	catalog=$(cd -P catalog && pwd)
	assert_eq "-p" "$(sed -n 1p ai.log.args)"
	assert_contains "$(sed -n 2p ai.log.args)" "new project type, \`python-cli\`" "the prompt is the second argument"
	assert_contains "$args" "--permission-mode
acceptEdits"
	assert_contains "$args" "--add-dir
$catalog"
	assert_contains "$args" "--allowedTools"
	assert_contains "$args" "Bash($REPO_ROOT/bin/repo-kickoff --check-type:*)"
	assert_not_contains "$args" "WebFetch"
	assert_eq "$catalog" "$(cat ai.log.cwd)" "claude runs in the catalog folder"
}

test_help_documents_the_ai_command() {
	run "$KICKOFF" --help
	assert_contains "$OUT" "--teach <type>"
	assert_contains "$OUT" "REPO_KICKOFF_AI"
}
