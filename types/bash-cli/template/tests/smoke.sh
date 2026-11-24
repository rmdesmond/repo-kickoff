#!/usr/bin/env bash
# Smoke test for {{NAME}}: the command runs, prints its placeholder line, and
# answers --help and --version. Run from anywhere: tests/smoke.sh

set -eu

cd "$(dirname "$0")/.."

fail() {
	echo "smoke: FAIL: $*" >&2
	exit 1
}

cmd="bin/{{NAME}}"

out=$("$cmd") || fail "$cmd exited non-zero"
[ "$out" = "{{NAME}}: placeholder - nothing implemented yet" ] ||
	fail "unexpected output: $out"

"$cmd" --help >/dev/null || fail "--help exited non-zero"

version=$("$cmd" --version) || fail "--version exited non-zero"
case $version in
"{{NAME}} "[0-9]*) ;;
*) fail "unexpected --version output: $version" ;;
esac

echo "smoke: ok"
