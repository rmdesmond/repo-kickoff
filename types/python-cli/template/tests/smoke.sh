#!/usr/bin/env bash
# Smoke test for {{NAME}}: the command runs from the source tree, prints its
# placeholder line, answers --help and --version, and the unit tests pass.
# Installs nothing. Run from anywhere: tests/smoke.sh

set -eu

cd "$(dirname "$0")/.."

fail() {
	echo "smoke: FAIL: $*" >&2
	exit 1
}

python=${PYTHON:-python3}
command -v "$python" >/dev/null 2>&1 ||
	fail "$python not found: install Python 3.8 or later, or set PYTHON"
"$python" -c 'import sys; sys.exit(sys.version_info < (3, 8))' ||
	fail "$python is older than Python 3.8"

PYTHONPATH="$PWD/src${PYTHONPATH:+:$PYTHONPATH}"
PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH PYTHONDONTWRITEBYTECODE

run() {
	"$python" -m app "$@"
}

out=$(run) || fail "python -m app exited non-zero"
[ "$out" = "{{NAME}}: placeholder - nothing implemented yet" ] ||
	fail "unexpected output: $out"

help=$(run --help) || fail "--help exited non-zero"
case $help in
"usage: {{NAME}}"*) ;;
*) fail "unexpected --help output: $help" ;;
esac

version=$(run --version) || fail "--version exited non-zero"
case $version in
"{{NAME}} "[0-9]*) ;;
*) fail "unexpected --version output: $version" ;;
esac

"$python" -m unittest discover -s tests >/dev/null 2>&1 ||
	fail "unit tests failed: run PYTHONPATH=src $python -m unittest discover -s tests"

echo "smoke: ok"
