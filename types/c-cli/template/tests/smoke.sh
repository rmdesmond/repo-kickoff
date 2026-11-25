#!/usr/bin/env bash
# Smoke test for {{NAME}}: configures and builds the project in a temporary
# build folder, checks the program's placeholder line, --help and --version,
# and runs the unit tests with ctest when GoogleTest was found.
# It never downloads anything. Run from anywhere: tests/smoke.sh

set -eu

cd "$(dirname "$0")/.."

fail() {
	echo "smoke: FAIL: $*" >&2
	exit 1
}

command -v cmake >/dev/null 2>&1 ||
	fail "cmake not found: install CMake 3.14 or later (brew install cmake, or apt install cmake)"
command -v ctest >/dev/null 2>&1 ||
	fail "ctest not found: it comes with CMake; check your CMake installation"

build=$(mktemp -d "${TMPDIR:-/tmp}/{{NAME}}-smoke.XXXXXX") ||
	fail "could not create a temporary build folder"
trap 'rm -rf "$build"' EXIT

echo "smoke: configuring in $build"
cmake -S . -B "$build" \
	-DCMAKE_BUILD_TYPE=Debug \
	"-D{{NAME_SNAKE}}_FETCH_GOOGLETEST=OFF" \
	-DFETCHCONTENT_FULLY_DISCONNECTED=ON >"$build/configure.log" 2>&1 || {
	cat "$build/configure.log" >&2
	fail "cmake configure failed (is a C compiler installed?)"
}

echo "smoke: building"
cmake --build "$build" >"$build/build.log" 2>&1 || {
	cat "$build/build.log" >&2
	fail "build failed"
}

cmd="$build/{{NAME}}"
[ -x "$cmd" ] || fail "the build did not produce $cmd"

out=$("$cmd") || fail "{{NAME}} exited non-zero"
[ "$out" = "{{NAME}}: placeholder - nothing implemented yet" ] ||
	fail "unexpected output: $out"

help=$("$cmd" --help) || fail "--help exited non-zero"
case $help in
"Usage: {{NAME}}"*) ;;
*) fail "unexpected --help output: $help" ;;
esac

version=$("$cmd" --version) || fail "--version exited non-zero"
case $version in
"{{NAME}} "[0-9]*) ;;
*) fail "unexpected --version output: $version" ;;
esac

if "$cmd" --no-such-option >/dev/null 2>&1; then
	fail "an unknown option should exit non-zero"
fi

if grep -q '^{{NAME_SNAKE}}_TESTS_ENABLED:INTERNAL=ON$' "$build/CMakeCache.txt"; then
	echo "smoke: running unit tests"
	(cd "$build" && ctest --output-on-failure) || fail "unit tests failed"
else
	echo "smoke: unit tests skipped: GoogleTest not found (see README.md)"
fi

echo "smoke: ok"
