#!/usr/bin/env bash
# Unit tests for the command line of bin/repo-kickoff: help, version, usage
# errors, and finding its own folder through symlinks.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

KICKOFF=$REPO_ROOT/bin/repo-kickoff

# The physical path of the repository, as the command resolves it.
real_root() {
	cd -P "$REPO_ROOT" && pwd
}

test_help_prints_usage_and_exits_0() {
	run "$KICKOFF" --help
	assert_status 0
	assert_contains "$OUT" "Usage: repo-kickoff [--dest DIR] [--interactive] [<type> [<name>]]"
	assert_eq "" "$ERR" "nothing on stderr"
	run "$KICKOFF" -h
	assert_status 0
	assert_contains "$OUT" "Usage: repo-kickoff [--dest DIR] [--interactive] [<type> [<name>]]"
}

test_version_prints_the_version_line() {
	expected=$(sed -n 's/^REPO_KICKOFF_VERSION=//p' "$KICKOFF")
	case $expected in
	[0-9]*.[0-9]*.[0-9]*) ;;
	*) _fail "no X.Y.Z version in bin/repo-kickoff: '$expected'" ;;
	esac
	run "$KICKOFF" --version
	assert_status 0
	assert_eq "repo-kickoff $expected" "$OUT"
}

test_unknown_option_is_a_usage_error() {
	run "$KICKOFF" --frobnicate
	assert_status 2
	assert_contains "$ERR" "unknown option: --frobnicate"
	assert_contains "$ERR" "Usage: repo-kickoff"
	assert_eq "" "$OUT" "nothing on stdout"
}

test_missing_arguments_are_a_usage_error() {
	run "$KICKOFF"
	assert_status 2
	assert_contains "$ERR" "missing <type>"
	run "$KICKOFF" bash-cli
	assert_status 2
	assert_contains "$ERR" "missing <name>"
}

test_extra_argument_is_a_usage_error() {
	run "$KICKOFF" bash-cli greet extra
	assert_status 2
	assert_contains "$ERR" "unexpected argument: extra"
}

test_double_dash_ends_options() {
	run "$KICKOFF" -- bash-cli
	assert_status 2
	assert_contains "$ERR" "missing <name>"
	run "$KICKOFF" -- --help
	assert_status 2
	assert_contains "$ERR" "missing <name>"
}

test_finds_its_folder_when_run_directly() {
	run "$KICKOFF" --help
	assert_contains "$OUT" "Types are read from: $(real_root)/types"
}

test_finds_its_folder_through_a_symlink() {
	mkdir onpath
	ln -s "$KICKOFF" onpath/repo-kickoff
	run onpath/repo-kickoff --help
	assert_status 0
	assert_contains "$OUT" "Types are read from: $(real_root)/types"
}

test_finds_its_folder_through_a_chain_of_relative_symlinks() {
	mkdir -p a/b onpath
	ln -s "$KICKOFF" a/b/first
	ln -s ../a/b/first onpath/second
	(cd onpath && ln -s second repo-kickoff)
	mkdir elsewhere
	cd elsewhere || exit 1
	PATH=$TEST_TMP/onpath:$PATH run repo-kickoff --help
	assert_status 0
	assert_contains "$OUT" "Types are read from: $(real_root)/types"
}
