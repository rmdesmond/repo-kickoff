#!/usr/bin/env bash
# Integration tests: the python-cli type with a dashed name, through a
# symlink on PATH. The package is the name in snake_case. Needs python3.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

unset REPO_KICKOFF_TYPES

# Put a symlink to bin/repo-kickoff on PATH, and work in $TEST_TMP/work.
install_on_path() {
	mkdir onpath work
	ln -s "$REPO_ROOT/bin/repo-kickoff" onpath/repo-kickoff
	PATH=$TEST_TMP/onpath:$PATH
	export PATH
	cd work || exit 1
	command -v python3 >/dev/null 2>&1 || _fail "python3 is needed for the python-cli tests"
}

test_a_dashed_name_gives_a_snake_case_package() {
	install_on_path
	run repo-kickoff python-cli my-tool
	assert_status 0
	assert_contains "$OUT" "Created my-tool from the python-cli type."
	assert_file my-tool/src/my_tool/__init__.py
	assert_file my-tool/src/my_tool/cli.py
	assert_not_exists my-tool/src/app
	count=$(find my-tool -name '*{{*' | wc -l | tr -d ' ')
	assert_eq 0 "$count" "paths still holding a placeholder"
	assert_not_contains "$(cat my-tool/pyproject.toml)" "{{" "pyproject.toml has no placeholder left"
}

test_the_package_runs_as_a_module_and_its_smoke_test_passes() {
	install_on_path
	run repo-kickoff python-cli my-tool
	assert_status 0
	cd my-tool || exit 1
	PYTHONPATH=src PYTHONDONTWRITEBYTECODE=1 run python3 -m my_tool --version
	assert_status 0
	assert_eq "my-tool 0.1.0" "$OUT"
	PYTHONPATH=src PYTHONDONTWRITEBYTECODE=1 run python3 -m my_tool
	assert_eq "my-tool: placeholder - nothing implemented yet" "$OUT"
	run tests/smoke.sh
	assert_status 0
	assert_eq "smoke: ok" "$OUT"
}
