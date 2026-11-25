#!/usr/bin/env bash
# Make sure GoogleTest is installed, so that the C and C++ types' unit tests
# build and run (decision 0010). The integration stage runs it before
# tests/run.sh integration.
#
# - GoogleTest already installed: does nothing, and exits 0.
# - Linux with apt-get: installs libgtest-dev, through sudo when not root.
# - Anywhere else: exits 1, saying how to install it.
#
# "Installed" means CMake's find_package(GTest) finds it, as the types' own
# CMakeLists.txt files do.

set -eu

say() {
	printf 'ensure-googletest: %s\n' "$*"
}

fail() {
	printf 'ensure-googletest: %s\n' "$*" >&2
	exit 1
}

# Succeeds when find_package(GTest) finds GoogleTest, in a throwaway project.
has_googletest() {
	local probe status=0
	probe=$(mktemp -d "${TMPDIR:-/tmp}/ensure-googletest.XXXXXX")
	cat >"$probe/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.14)
project(ensure_googletest_probe CXX)
find_package(GTest REQUIRED)
EOF
	cmake -S "$probe" -B "$probe/build" >"$probe/log" 2>&1 || status=$?
	rm -rf "$probe"
	return "$status"
}

# Run a command as root: directly when we are root, else through sudo.
as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		command -v sudo >/dev/null 2>&1 ||
			fail "installing GoogleTest needs root, and sudo isn't available"
		sudo "$@"
	fi
}

command -v cmake >/dev/null 2>&1 ||
	fail "cmake not found: install CMake 3.14 or later"

if has_googletest; then
	say "GoogleTest is installed"
	exit 0
fi

case $(uname -s) in
Linux)
	command -v apt-get >/dev/null 2>&1 ||
		fail "GoogleTest not found, and apt-get isn't available: install GoogleTest with your system's package manager"
	say "GoogleTest not found: installing libgtest-dev with apt-get"
	as_root env DEBIAN_FRONTEND=noninteractive apt-get update -qq
	as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends libgtest-dev
	has_googletest ||
		fail "libgtest-dev was installed, but CMake still can't find GoogleTest"
	say "GoogleTest is installed"
	;;
*)
	fail "GoogleTest not found: install it with brew install googletest (macOS), or your system's package manager"
	;;
esac
