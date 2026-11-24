# shellcheck shell=bash
# Test helpers. Every tests/<level>/*_test.sh file sources this file, then
# defines functions named test_*. tests/run.sh calls run_tests on each file.
#
# Each test function runs in its own subshell, with `set -e`, inside a fresh
# temporary folder ($TEST_TMP) that is removed afterwards. A test fails when
# an assertion fails or any command in it fails.

# The repository root, for tests that run the project's commands.
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export REPO_ROOT

# run CMD [ARG...]: run a command without failing the test, and keep its
# output in $OUT, its error output in $ERR and its exit status in $STATUS.
run() {
	STATUS=0
	"$@" >"$TEST_RUN/out" 2>"$TEST_RUN/err" || STATUS=$?
	OUT=$(cat "$TEST_RUN/out")
	ERR=$(cat "$TEST_RUN/err")
}

# Report a failed assertion and end the test.
_fail() {
	printf '    %s\n' "$@" >&2
	exit 1
}

# assert_eq EXPECTED ACTUAL [WHAT]
assert_eq() {
	[ "$1" = "$2" ] ||
		_fail "${3:-values differ}" "expected: $1" "actual:   $2"
}

# assert_contains HAYSTACK NEEDLE [WHAT]
assert_contains() {
	case $1 in
	*"$2"*) ;;
	*) _fail "${3:-text does not contain the expected part}" "expected to contain: $2" "actual: $1" ;;
	esac
}

# assert_not_contains HAYSTACK NEEDLE [WHAT]
assert_not_contains() {
	case $1 in
	*"$2"*) _fail "${3:-text contains an unexpected part}" "expected not to contain: $2" "actual: $1" ;;
	*) ;;
	esac
}

# assert_status EXPECTED: compare with $STATUS from the last `run`.
assert_status() {
	[ "$1" = "$STATUS" ] ||
		_fail "exit status differs" "expected: $1" "actual:   $STATUS" "stdout: $OUT" "stderr: $ERR"
}

# assert_file PATH: PATH exists and is a regular file.
assert_file() {
	[ -f "$1" ] || _fail "file missing: $1"
}

# assert_dir PATH: PATH exists and is a folder.
assert_dir() {
	[ -d "$1" ] || _fail "folder missing: $1"
}

# assert_executable PATH: PATH is an executable file.
assert_executable() {
	[ -f "$1" ] && [ -x "$1" ] || _fail "not an executable file: $1"
}

# assert_not_exists PATH: nothing exists at PATH.
assert_not_exists() {
	[ ! -e "$1" ] && [ ! -L "$1" ] || _fail "expected nothing at: $1"
}

# run_tests FILE: run every test_* function defined so far, and print one
# line per test: "ok   FILE: NAME" or "FAIL FILE: NAME", followed by the
# failing test's output. Returns 1 if any test failed.
run_tests() {
	local file=$1 name base status failed=0
	for name in $(declare -F | awk '$3 ~ /^test_/ { print $3 }'); do
		base=$(mktemp -d "${TMPDIR:-/tmp}/repo-kickoff-test.XXXXXX")
		mkdir "$base/tmp"
		# $TEST_TMP is the test's own folder; $TEST_RUN holds `run`'s output.
		export TEST_TMP=$base/tmp TEST_RUN=$base
		(
			cd "$TEST_TMP" || exit 1
			set -e
			"$name"
		) >"$base/log" 2>&1
		status=$?
		if [ "$status" -eq 0 ]; then
			printf 'ok   %s: %s\n' "$file" "$name"
		else
			printf 'FAIL %s: %s (exit %s)\n' "$file" "$name" "$status"
			sed 's/^/    /' "$base/log"
			failed=1
		fi
		rm -rf "$base"
	done
	return "$failed"
}
