# repo-kickoff

Generate starter repositories from a catalog of project types, teaching new types with Claude

Status: early development. See [the plan](docs/plan/PLAN.md).

`repo-kickoff bash-cli greet` creates a `greet/` folder holding the bare bones of a bash command-line tool: the command, a README, a `.gitignore` and a smoke test. Each kind of project is a **type** in repo-kickoff's catalog, a folder of template files. repo-kickoff needs only bash (3.2 or later, so macOS's own bash works) and the usual POSIX tools, on macOS or Linux.

## Install

repo-kickoff runs from a clone of this repository. Its catalog of types lives in the clone, so types you add are there to commit ([decision 0002](docs/decisions/0002-used-from-a-clone.md)).

```sh
git clone git@github.com:rmdesmond/repo-kickoff.git
ln -s "$PWD/repo-kickoff/bin/repo-kickoff" ~/.local/bin/repo-kickoff   # any folder on your PATH
```

```console
$ repo-kickoff --version
repo-kickoff 0.3.0
```

To update, `git pull` in the clone.

## Usage

For a worked example from install to teaching a type, see [the tutorial](docs/tutorial.md).

Give a type and a name:

```console
$ repo-kickoff bash-cli greet
Created greet from the bash-cli type.
$ greet/bin/greet
greet: placeholder - nothing implemented yet
$ greet/tests/smoke.sh
smoke: ok
```

`--dest` creates the repository somewhere other than the current folder:

```console
$ repo-kickoff --dest projects bash-cli hello
Created projects/hello from the bash-cli type.
```

Names (and types) are lower-case letters, digits and dashes, starting with a letter. repo-kickoff never overwrites anything: it refuses an existing destination, and builds the repository in a staging folder before moving it into place, so a failure never leaves half a repository behind.

```console
$ repo-kickoff bash-cli Greet
repo-kickoff: invalid name: Greet (use lower-case letters, digits and dashes, starting with a letter)
...
$ repo-kickoff bash-cli greet
repo-kickoff: greet already exists
```

### Prompts

At a terminal, leave out the type, the name or both, and repo-kickoff asks for them. Choose a type by its number or its name; an invalid answer is asked for again. Without a terminal (in a script, say), missing arguments are an error instead, so nothing waits for an answer. `--interactive` asks anyway and reads the answers from standard input:

```console
$ printf '1\nmy-tool\n' | repo-kickoff --interactive
Known types:
  1) bash-cli  A command-line tool written as a single bash script
Type (number or name): Name of the new repository: Created my-tool from the bash-cli type.
```

The prompts go to standard error, so standard output holds only the `Created` line.

### List the types

```console
$ repo-kickoff --list
bash-cli  A command-line tool written as a single bash script
```

### Check a type

`--check-type` checks that a type is complete, by generating a sample repository in a temporary folder and running its smoke test. It reports every problem it finds and exits 1, or exits 0:

```console
$ repo-kickoff --check-type bash-cli
ok: bash-cli has a description and a template, and its smoke test passes
```

`repo-kickoff --help` shows every option.

## Teach a new type

Ask for a type the catalog doesn't have, and repo-kickoff can have Claude add it ([decision 0003](docs/decisions/0003-teach-types-with-claude.md)). At a terminal, it asks first:

```
The catalog has no python-cli type. Ask the AI command to add it? [y/N]
```

On a yes, it asks for the name if it's missing, then:

1. runs Claude Code (`claude -p`) with a prompt that describes what a type is, from `lib/teach-prompt.md`. Claude may edit files only in the catalog, and run only a short list of commands, among them `repo-kickoff --check-type`.
2. checks the new type with `--check-type`. If Claude fails, or the type fails its check, repo-kickoff removes the half-made type and shows the problems.
3. generates your repository from the new type, the same way it does for every type, and reminds you to review and commit `types/<type>/`.

From then on the type is in your clone's catalog, and asking for it again needs no AI. Commit it, and every clone gets it.

Without a terminal, repo-kickoff won't call the AI unless told to with `--yes`:

```console
$ repo-kickoff python-cli mytool
repo-kickoff: unknown type: python-cli
repo-kickoff: known types: bash-cli
repo-kickoff: to have the AI command add it, run again with --yes (or at a terminal)
$ repo-kickoff --yes python-cli mytool
```

`repo-kickoff --teach <type>` adds and checks a type without generating a repository.

Left to itself, Claude makes the choices a type needs: the build system, the test framework, the layout. To make them yourself, add `--hint` with your requirements. repo-kickoff adds them to the prompt under *Requirements from the user*:

```sh
repo-kickoff --yes --hint "Build with CMake. Unit tests use GoogleTest." c-cli my-tool
repo-kickoff --teach rust-cli --hint "Use clap for arguments."
```

The rules in the prompt still win over a hint: a smoke test never downloads anything, for example. `--hint` is only for teaching: with a type the catalog has, `--list` or `--check-type`, it's a usage error.

Teaching needs [Claude Code](https://claude.com/claude-code) installed and signed in; it runs on your account. Known types never need it. If the catalog is in a git working copy, repo-kickoff warns about anything Claude changed outside the new type's folder.

To use another AI command, set `REPO_KICKOFF_AI` to an executable. repo-kickoff runs it as `<command> <type> <catalog> <prompt-file>`, and it must write `<catalog>/<type>/`. The tests use a fake one, `tests/fixtures/fake-ai.sh`.

## The catalog

Each type is a folder in `types/`:

```
types/<type>/
  description          one line, shown by --list
  template/            copied to the new repository
    tests/smoke.sh     required: exits 0 when the generated repository works
    ...                any other files and folders
```

When generating, repo-kickoff copies `template/` to `<name>/`, replacing two placeholders in every file's contents and in file and folder names:

| Placeholder | Replaced with | For `my-tool` |
|---|---|---|
| `{{NAME}}` | the repository's name | `my-tool` |
| `{{NAME_SNAKE}}` | the name in snake_case: its dashes turned into underscores | `my_tool` |

So `template/bin/{{NAME}}` becomes `my-tool/bin/my-tool`, and `template/src/{{NAME_SNAKE}}/` becomes `my-tool/src/my_tool/`. Use `{{NAME}}` for what people see (the command, the project, the README's title), and `{{NAME_SNAKE}}` where a language needs an identifier, which can't contain a dash: a Python package, a C function prefix ([decision 0008](docs/decisions/0008-name-snake-placeholder.md)). Names start with a letter, so `{{NAME_SNAKE}}` is a valid identifier, unless the name is one of the language's keywords (`class`, say), which repo-kickoff doesn't check.

Executable files stay executable. Nothing else in a template is special.

### Add a type by hand

Make the folder, a description and a template. `--check-type` says what's missing:

```console
$ mkdir -p types/notes/template/tests
$ echo "A folder of Markdown notes" > types/notes/description
$ printf '# {{NAME}}\n\nNotes about {{NAME}}.\n' > types/notes/template/README.md
$ repo-kickoff --check-type notes
repo-kickoff: notes: no template/tests/smoke.sh
repo-kickoff: notes: 1 problem(s) found
```

Every type needs `template/tests/smoke.sh`: an executable script that exits 0 when a repository generated from the type works. repo-kickoff runs it from the generated repository's root. Here it checks the README is titled with the repository's name:

```sh
#!/bin/sh
# Smoke test: the README is titled with the repository name.
cd "$(dirname "$0")/.."
name=$(basename "$PWD")
grep -qx "# $name" README.md
```

```console
$ chmod +x types/notes/template/tests/smoke.sh
$ repo-kickoff --check-type notes
ok: notes has a description and a template, and its smoke test passes
```

Then commit `types/notes/`. The integration tests check that every type in the catalog passes `--check-type`.

## Development

```sh
tests/run.sh unit          # unit tests
tests/run.sh integration   # integration tests
git ls-files -z 'bin/*' '*.sh' | xargs -0 -r shellcheck   # lint
```

The pipeline runs the same commands (`.project/config.yml`). Work follows [the plan](docs/plan/PLAN.md), and choices are recorded in [docs/decisions](docs/decisions/).

## Licence

[MIT](LICENSE)
