#!/usr/bin/env bash
# A fake AI command for tests, used through REPO_KICKOFF_AI in place of
# Claude. Called as: fake-ai.sh TYPE CATALOG PROMPT_FILE
#
# FAKE_AI_LOG   if set, each call appends "call TYPE CATALOG" to this file,
#               and the prompt is copied to "$FAKE_AI_LOG.prompt"
# FAKE_AI_MODE  what to do:
#   good     (default) write a complete type whose smoke test passes
#   broken   write a type whose smoke test fails
#   fail     write part of a type, then exit 3
#   nothing  write nothing and exit 0
#   outside  write a complete type, and also a file outside it in the catalog

set -eu

type=$1
catalog=$2
prompt=$3

if [ -n "${FAKE_AI_LOG:-}" ]; then
	echo "call $type $catalog" >>"$FAKE_AI_LOG"
	cp "$prompt" "$FAKE_AI_LOG.prompt"
fi

dir=$catalog/$type

write_type() {
	mkdir -p "$dir/template/tests"
	echo "A $type type written by the fake AI" >"$dir/description"
	echo "# {{NAME}}" >"$dir/template/README.md"
	cat >"$dir/template/tests/smoke.sh" <<'EOF'
#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
grep -qx "# $(basename "$PWD")" README.md || { echo "README.md is not titled with the name"; exit 1; }
echo "smoke: ok"
EOF
	chmod +x "$dir/template/tests/smoke.sh"
}

case ${FAKE_AI_MODE:-good} in
good)
	write_type
	;;
broken)
	write_type
	echo "# not the name" >"$dir/template/README.md"
	;;
fail)
	mkdir -p "$dir/template"
	echo "half a type" >"$dir/description"
	echo "fake-ai: giving up" >&2
	exit 3
	;;
nothing) ;;
outside)
	write_type
	echo "stray" >"$catalog/stray.txt"
	;;
*)
	echo "fake-ai: unknown FAKE_AI_MODE: $FAKE_AI_MODE" >&2
	exit 2
	;;
esac
echo "fake-ai: done ($type)"
