# 0001: Write repo-kickoff in dependency-free bash 3.2

Date: 2026-11-24
Status: accepted

## Context

repo-kickoff must run on macOS and Linux. macOS ships bash 3.2, and its BSD tools differ from Linux's GNU tools. The tool should work without installing a runtime or a test framework.

## Decision

- Write repo-kickoff in bash compatible with 3.2: no associative arrays, `${var,,}`, `mapfile` or other bash 4 features.
- Use only POSIX tools that behave the same on BSD and GNU: no `sed -i`, no `readlink -f`.
- Templates use plain `{{NAME}}` placeholders replaced with `sed`, not a template engine.
- Tests use a plain bash runner, `tests/run.sh`, not `bats`. Lint with `shellcheck`.

## Consequences

- Nothing to install beyond bash, POSIX tools and, for development, `shellcheck`.
- Some bash idioms are off limits, and portable alternatives need care (resolving symlinks, in-place edits).
- CI runs on Linux; macOS is covered by running the same stage commands locally.
