#!/usr/bin/env bash
# Smoke test for {{NAME}}: configures and builds the library in a temporary
# folder, runs the GoogleTest unit tests with ctest, installs it into a temporary prefix,
# then builds a small program that finds the installed package with
# find_package({{NAME}}), links it, and checks what it prints.
# It never downloads anything, so GoogleTest must be installed. Run from
# anywhere: tests/smoke.sh

set -eu

cd "$(dirname "$0")/.."
src=$(pwd)

fail() {
	echo "smoke: FAIL: $*" >&2
	exit 1
}

command -v cmake >/dev/null 2>&1 ||
	fail "cmake not found: install CMake 3.14 or later (brew install cmake, or apt install cmake)"
command -v ctest >/dev/null 2>&1 ||
	fail "ctest not found: it comes with CMake; check your CMake installation"

work=$(mktemp -d "${TMPDIR:-/tmp}/{{NAME}}-smoke.XXXXXX") ||
	fail "could not create a temporary folder"
trap 'rm -rf "$work"' EXIT

build="$work/build"
prefix="$work/prefix"
consumer="$work/consumer"

# Runs a command quietly, showing its log only when it fails.
step() {
	name=$1
	shift
	"$@" >"$work/$name.log" 2>&1 || {
		cat "$work/$name.log" >&2
		fail "$name failed"
	}
}

echo "smoke: configuring in $build"
step configure cmake -S "$src" -B "$build" \
	-DCMAKE_BUILD_TYPE=Debug \
	"-DCMAKE_INSTALL_PREFIX=$prefix" \
	"-D{{NAME_SNAKE}}_BUILD_TESTS=ON" \
	"-D{{NAME_SNAKE}}_FETCH_GOOGLETEST=OFF" \
	-DFETCHCONTENT_FULLY_DISCONNECTED=ON

echo "smoke: building"
step build cmake --build "$build"

echo "smoke: running unit tests"
(cd "$build" && ctest --output-on-failure) || fail "unit tests failed"

echo "smoke: installing into $prefix"
step install cmake --install "$build"

[ -f "$prefix/include/{{NAME_SNAKE}}.h" ] ||
	fail "the install did not put {{NAME_SNAKE}}.h in $prefix/include"

echo "smoke: building a program against the installed package"
mkdir -p "$consumer"
cat >"$consumer/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.14)
project(consumer LANGUAGES C)
find_package({{NAME}} 0.1 REQUIRED)
add_executable(consumer main.c)
target_link_libraries(consumer PRIVATE {{NAME_SNAKE}}::{{NAME_SNAKE}})
EOF
cat >"$consumer/main.c" <<'EOF'
#include <stdio.h>

#include <{{NAME_SNAKE}}.h>

int main(void)
{
	printf("%s\n%s\n", {{NAME_SNAKE}}_placeholder(), {{NAME_SNAKE}}_version());
	return 0;
}
EOF
step consumer-configure cmake -S "$consumer" -B "$consumer/build" \
	"-DCMAKE_PREFIX_PATH=$prefix"
step consumer-build cmake --build "$consumer/build"

out=$("$consumer/build/consumer") || fail "the consumer program exited non-zero"
first=$(printf '%s\n' "$out" | sed -n 1p)
second=$(printf '%s\n' "$out" | sed -n 2p)
[ "$first" = "{{NAME}}: placeholder - nothing implemented yet" ] ||
	fail "unexpected placeholder line: $first"
case $second in
[0-9]*.[0-9]*.[0-9]*) ;;
*) fail "unexpected version: $second" ;;
esac

echo "smoke: ok"
