#!/usr/bin/env bash
# Integration tests: everyday use of repo-kickoff through a symlink on PATH,
# against the real catalog.

# shellcheck source=tests/lib.sh
. "$TESTS_DIR/lib.sh"

unset REPO_KICKOFF_TYPES

# Put a symlink to bin/repo-kickoff on PATH, and work in $TEST_TMP/work.
setup() {
	mkdir onpath work
	ln -s "$REPO_ROOT/bin/repo-kickoff" onpath/repo-kickoff
	PATH=$TEST_TMP/onpath:$PATH
	export PATH
	cd work || exit 1
}

# Every path under the current folder, hidden ones included, with its type
# and contents' checksum: a snapshot of the file system to compare against.
snapshot() {
	find . -print | LC_ALL=C sort | while IFS= read -r path; do
		if [ -f "$path" ]; then
			printf '%s file %s\n' "$path" "$(cksum <"$path")"
		elif [ -L "$path" ]; then
			printf '%s link\n' "$path"
		else
			printf '%s dir\n' "$path"
		fi
	done
}

test_every_type_in_the_catalog_passes_check_type() {
	setup
	count=0
	for dir in "$REPO_ROOT"/types/*/; do
		type=$(basename "$dir")
		run repo-kickoff --check-type "$type"
		[ "$STATUS" -eq 0 ] || _fail "type $type fails --check-type:" "$ERR"
		assert_contains "$OUT" "ok: $type"
		count=$((count + 1))
	done
	[ "$count" -gt 0 ] || _fail "the catalog has no types"
	assert_eq "" "$(ls -A)" "checking wrote nothing in the current folder"
}

test_piped_interactive_session_generates_bash_cli() {
	setup
	position=$(repo-kickoff --list | awk '$1 == "bash-cli" { print NR }')
	[ -n "$position" ] || _fail "bash-cli is not in --list"
	printf '%s\n' nope "$position" Not_Valid greet >"$TEST_TMP/answers"
	run repo-kickoff --interactive <"$TEST_TMP/answers"
	assert_status 0
	assert_contains "$ERR" "Not a known type: 'nope'"
	assert_contains "$ERR" "Not a valid name: 'Not_Valid'"
	assert_eq "Created greet from the bash-cli type." "$OUT"
	run greet/tests/smoke.sh
	assert_status 0
	assert_eq "smoke: ok" "$OUT"
}

test_invalid_name_leaves_the_file_system_unchanged() {
	setup
	mkdir projects
	echo keep >projects/existing.txt
	before=$(snapshot)
	run repo-kickoff --dest projects bash-cli Bad_Name
	assert_status 2
	assert_eq "$before" "$(snapshot)" "file system after an invalid name"
}

test_existing_destination_leaves_the_file_system_unchanged() {
	setup
	mkdir -p projects/greet
	echo mine >projects/greet/notes.txt
	before=$(snapshot)
	run repo-kickoff --dest projects bash-cli greet
	assert_status 1
	assert_contains "$ERR" "projects/greet already exists"
	assert_eq "$before" "$(snapshot)" "file system after an existing destination"
}
