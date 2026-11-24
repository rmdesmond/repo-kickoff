#!/usr/bin/env bash
# Run one level of tests: tests/run.sh unit|integration
#
# Runs every tests/<level>/*_test.sh file in its own bash process, prints one
# line per test, then a count. Exits 1 if any test failed, and 0 when every
# test passed or the level has no tests.

set -u

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
export TESTS_DIR

level=${1:-}
case $level in
unit | integration) ;;
*)
	echo "usage: tests/run.sh unit|integration" >&2
	exit 2
	;;
esac

results=$(mktemp "${TMPDIR:-/tmp}/repo-kickoff-results.XXXXXX")
trap 'rm -f "$results"' EXIT

files=0
failed_files=0
for file in "$TESTS_DIR/$level"/*_test.sh; do
	[ -e "$file" ] || continue
	files=$((files + 1))
	name="$level/$(basename "$file")"
	bash -c '. "$1" && run_tests "$2"' run-tests "$file" "$name" >"$results" 2>&1
	status=$?
	cat "$results"
	if [ "$status" -ne 0 ] && ! grep -q '^FAIL ' "$results"; then
		# The file itself failed (a syntax error, a failing top-level command).
		printf 'FAIL %s: could not run the file (exit %s)\n' "$name" "$status"
		failed_files=$((failed_files + 1))
	fi
	passed_total=$((${passed_total:-0} + $(grep -c '^ok ' "$results")))
	failed_total=$((${failed_total:-0} + $(grep -c '^FAIL ' "$results")))
done

passed=${passed_total:-0}
failed=$((${failed_total:-0} + failed_files))
echo "$level: $passed passed, $failed failed, in $files file(s)"
[ "$failed" -eq 0 ]
