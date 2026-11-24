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

When repo-kickoff generates a repository named `<name>` from the type, it copies `template/` to `<name>/` and replaces every `{{NAME}}` with the name, in file contents and in file and folder names: `template/bin/{{NAME}}` becomes `greet/bin/greet`. Names are lower-case letters, digits and dashes, starting with a letter, so a name like `my-tool` can appear where the language needs something else (a Python package name can't contain `-`, for example): write the template so it works with dashed names. Executable files stay executable. Nothing else in a template is special: there are no other placeholders, no loops and no conditions.

## What the template must contain

The bare bones of a `{{TYPE}}` project, and no more:

- whatever a developer expects to find in a new project of this type (the usual layout, a build or package file if the type has one, a `.gitignore`, a `README.md` titled `# {{NAME}}`)
- a placeholder program or library that does nothing real. A command-line program prints one line naming itself, for example `{{NAME}}: placeholder - nothing implemented yet`, and supports `--help` and `--version`.
- `tests/smoke.sh`, executable, starting with `#!/usr/bin/env bash`. repo-kickoff runs it from the generated repository's root, with no network, on macOS and on Linux. It exits 0 only when the generated project works: it builds or runs the placeholder and checks its output. It must not install anything or download anything. Use only tools that are normally present for this type of project, and fail with a clear message if one is missing.

Keep shell scripts compatible with bash 3.2 and lint-clean under shellcheck, including before `{{NAME}}` is replaced (quote it: `cmd="bin/{{NAME}}"`).

## Check your work

When the files are written, run:

    {{KICKOFF}} --check-type {{TYPE}}

It generates a sample repository named `kickoff-check` in a temporary folder and runs its `tests/smoke.sh`. Fix any problem it reports and run it again, until it prints a line starting with `ok:`. Then reply with a short summary of the files you wrote.

For an example of a complete type, read the `bash-cli` type in the same catalog: {{CATALOG}}/bash-cli
