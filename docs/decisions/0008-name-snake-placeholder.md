# 0008: Add a {{NAME_SNAKE}} placeholder for identifiers

Date: 2026-11-24
Status: accepted

## Context

Repository names are kebab-case (`my-tool`), but many languages need identifiers without dashes: Python packages, C identifiers, Rust crates. With only `{{NAME}}`, the `python-cli` type taught in T-015 fell back on a fixed package name, `app`, which can clash with other packages. Names considered for the new placeholder: `{{NAME_PY}}` (names one language, though the need is wider), `{{NAME_NODASHES}}` (ambiguous: `mytool` or `my_tool`?), `{{NAME_UNDERSCORE}}`, and `{{NAME_SNAKE}}`.

## Decision

Add `{{NAME_SNAKE}}`: the name in snake_case, its dashes turned into underscores (`my-tool` → `my_tool`), replaced in file contents and in file and folder names, like `{{NAME}}`. Since names start with a letter and hold only `a-z`, `0-9` and `-`, the result is always a valid identifier in most languages. The name follows the usual names for naming styles (snake_case, kebab-case, PascalCase), leaving room for siblings such as `{{NAME_PASCAL}}` if a type needs one.

## Consequences

- Types use `{{NAME}}` for what people see (the command, the project, the README title) and `{{NAME_SNAKE}}` for identifiers. `python-cli` moves from `app` to `{{NAME_SNAKE}}`.
- A name that is a keyword in a type's language (`class`) still gives an unusable identifier; repo-kickoff doesn't check for that.
- Templates stay plain `sed` substitutions, with no template engine.
