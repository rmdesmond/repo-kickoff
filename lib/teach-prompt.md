You are adding a new project type, `{{TYPE}}`, to the catalog of repo-kickoff, a tool that generates starter repositories. Write the type's files, then stop. Don't generate a repository from it: repo-kickoff does that after checking your work.

## Where to write

Write only inside this folder, which doesn't exist yet: create it.

    {{TYPE_DIR}}

Don't create, change or delete anything outside it.

## What a type is

    {{TYPE_DIR}}/
      description          exactly one line: what this type of project is
      template/            the starter repository, copied to <name>/
        tests/smoke.sh     required, executable: exits 0 when the generated repository works
        ...                every other file the bare-bones project needs

When repo-kickoff generates a repository named `<name>` from the type, it copies `template/` to `<name>/` and replaces every `{{NAME}}` with the name, in file contents and in file and folder names: `template/bin/{{NAME}}` becomes `greet/bin/greet`. Names are lower-case letters, digits and dashes, starting with a letter, so they can be dashed, like `my-tool`: write the template so it works with dashed names. Where the language needs an identifier, which can't contain a dash (a Python package, a C function or macro prefix, a crate or module name), use `{{NAME_SNAKE}}`: the name in snake_case, its dashes turned into underscores (`my-tool` becomes `my_tool`). It's replaced in file contents and in file and folder names too: `template/src/{{NAME_SNAKE}}/` becomes `my-tool/src/my_tool/`. Use `{{NAME}}` for what people see (the command, the project name, the README's title) and `{{NAME_SNAKE}}` for identifiers, never a fixed identifier such as `app`. Executable files stay executable. Nothing else in a template is special: there are no other placeholders, no loops and no conditions.

## What the template must contain

The bare bones of a `{{TYPE}}` project, and no more:

- whatever a developer expects to find in a new project of this type (the usual layout, a build or package file if the type has one, a `.gitignore`, a `README.md` titled `# {{NAME}}`)
- a placeholder program or library that does nothing real. A command-line program prints one line naming itself, for example `{{NAME}}: placeholder - nothing implemented yet`, and supports `--help` and `--version`.
- `tests/smoke.sh`, executable, starting with `#!/usr/bin/env bash`. repo-kickoff runs it from the generated repository's root, with no network, on macOS and on Linux. It exits 0 only when the generated project works: it builds or runs the placeholder and checks its output. It must not install anything or download anything. Use only tools that are normally present for this type of project, and fail with a clear message if one is missing.

If part of the project builds only with an optional tool or library (a test framework, say), and it isn't installed here, `--check-type` can't compile that part, so you can't see its mistakes. Keep that code short and plain, avoid names the framework itself uses (inside a GoogleTest `TEST`, a helper called `Run` resolves to `testing::Test::Run`, for example), and say in your reply that it hasn't been built.

Keep shell scripts compatible with bash 3.2 and lint-clean under shellcheck, including before `{{NAME}}` and `{{NAME_SNAKE}}` are replaced (quote them: `cmd="bin/{{NAME}}"`).

## Nobody can answer questions

You're running without a person to reply. Don't ask questions or leave decisions open: where there's a choice, make a reasonable one, and record it in the template's README if a developer would want to know.

## Check your work

When the files are written, run:

    {{KICKOFF}} --check-type {{TYPE}}

It generates a sample repository named `kickoff-check` in a temporary folder and runs its `tests/smoke.sh`. Fix any problem it reports and run it again, until it prints a line starting with `ok:`. Then reply with a short summary of the files you wrote.

The check only runs the smoke test. If a requirement isn't exercised by it (a shared build, say, or a second way of using a library), you can't check it here: say in your reply which requirements weren't checked, so that the person reviewing the type checks them.

For an example of a complete type, read the `bash-cli` type in the same catalog: {{CATALOG}}/bash-cli
