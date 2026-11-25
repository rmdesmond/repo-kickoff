#!/usr/bin/env bash
# Unit tests for tests/ensure-googletest.sh, with stubs in place of cmake,
# uname, id, sudo and apt-get, so nothing is installed for real.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

ENSURE=$REPO_ROOT/tests/ensure-googletest.sh

# Stubs in $TEST_TMP/stubs, first on PATH, each logging its call to
# $TEST_TMP/calls.log:
# - cmake succeeds when $TEST_TMP/gtest-installed exists
# - uname -s prints $FAKE_OS; id -u prints $FAKE_UID
# - sudo runs its arguments
# - apt-get install creates $TEST_TMP/gtest-installed, unless $FAKE_APT_BROKEN
setup() {
	mkdir stubs
	export STUB_DIR=$TEST_TMP
	export FAKE_OS=Linux FAKE_UID=1000
	cat >stubs/cmake <<'EOF'
#!/bin/sh
echo "cmake $*" >>"$STUB_DIR/calls.log"
[ -e "$STUB_DIR/gtest-installed" ]
EOF
	cat >stubs/uname <<'EOF'
#!/bin/sh
echo "$FAKE_OS"
EOF
	cat >stubs/id <<'EOF'
#!/bin/sh
echo "$FAKE_UID"
EOF
	cat >stubs/sudo <<'EOF'
#!/bin/sh
echo "sudo $*" >>"$STUB_DIR/calls.log"
exec "$@"
EOF
	cat >stubs/apt-get <<'EOF'
#!/bin/sh
echo "apt-get $*" >>"$STUB_DIR/calls.log"
case " $* " in
*" install "*) [ -n "${FAKE_APT_BROKEN:-}" ] || touch "$STUB_DIR/gtest-installed" ;;
esac
EOF
	chmod +x stubs/*
	PATH=$TEST_TMP/stubs:$PATH
	export PATH
	: >calls.log
}

test_installed_googletest_needs_nothing() {
	setup
	touch gtest-installed
	run "$ENSURE"
	assert_status 0
	assert_eq "ensure-googletest: GoogleTest is installed" "$OUT"
	assert_not_contains "$(cat calls.log)" "apt-get"
}

test_the_probe_asks_cmake_for_the_gtest_package() {
	setup
	touch gtest-installed
	run "$ENSURE"
	assert_status 0
	assert_contains "$(cat calls.log)" "cmake -S "
}

test_on_linux_it_installs_libgtest_dev_through_sudo() {
	setup
	run "$ENSURE"
	assert_status 0
	calls=$(cat calls.log)
	assert_contains "$calls" "sudo env DEBIAN_FRONTEND=noninteractive apt-get update -qq"
	assert_contains "$calls" "sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends libgtest-dev"
	assert_contains "$OUT" "installing libgtest-dev with apt-get"
	assert_contains "$OUT" "GoogleTest is installed"
}

test_as_root_it_installs_without_sudo() {
	setup
	export FAKE_UID=0
	run "$ENSURE"
	assert_status 0
	calls=$(cat calls.log)
	assert_contains "$calls" "apt-get install -y -qq --no-install-recommends libgtest-dev"
	assert_not_contains "$calls" "sudo"
}

test_it_fails_if_googletest_is_still_missing_after_apt() {
	setup
	export FAKE_APT_BROKEN=yes
	run "$ENSURE"
	assert_status 1
	assert_contains "$ERR" "libgtest-dev was installed, but CMake still can't find GoogleTest"
}

test_elsewhere_it_fails_naming_brew() {
	setup
	export FAKE_OS=Darwin
	run "$ENSURE"
	assert_status 1
	assert_contains "$ERR" "brew install googletest"
	assert_not_contains "$(cat calls.log)" "apt-get"
}
