#!/usr/bin/env bash
# The default AI command for repo-kickoff: asks Claude Code (`claude -p`) to
# add a type to the catalog. See docs/decisions/0003-teach-types-with-claude.md.
#
# Usage: ai-claude.sh TYPE CATALOG PROMPT_FILE
#
# Every AI command, this one or one named by REPO_KICKOFF_AI, takes these
# three arguments: the type to add, the catalog folder, and a file holding the
# prompt. It writes CATALOG/TYPE/ and exits 0, or exits non-zero on failure.

set -eu

if [ $# -ne 3 ]; then
	echo "usage: ai-claude.sh TYPE CATALOG PROMPT_FILE" >&2
	exit 2
fi
type=$1
catalog=$2
prompt=$3

if ! command -v claude >/dev/null 2>&1; then
	echo "repo-kickoff: claude is not installed, so the $type type can't be taught" >&2
	echo "repo-kickoff: install Claude Code (https://claude.com/claude-code), or add the type by hand" >&2
	exit 127
fi

kickoff=$(cd -P "$(dirname "$0")/.." && pwd)/bin/repo-kickoff

# Edits are accepted without asking, but only inside the catalog, and the only
# commands Claude may run are folder and mode changes, listing, shellcheck and
# repo-kickoff's own type checker.
cd "$catalog"
exec claude -p "$(cat "$prompt")" \
	--permission-mode acceptEdits \
	--add-dir "$catalog" \
	--allowedTools \
	"Read" "Write" "Edit" "Glob" "Grep" \
	"Bash(mkdir:*)" "Bash(chmod:*)" "Bash(ls:*)" "Bash(shellcheck:*)" \
	"Bash($kickoff --check-type:*)"
