# Tutorial: start two projects with repo-kickoff

In this tutorial you install repo-kickoff, start a bash tool called `greet` and a Python tool called `my-tool`, and see how a type the catalog didn't have, `python-cli`, was taught to repo-kickoff by Claude, so that you can now use it with no AI at all.

Paths are shortened: `~` is your home folder, and you work in it. Claude's replies, in the recorded step, vary in wording from run to run.

## Before you start

- macOS or Linux, with bash 3.2 or later and `git`
- for the `python-cli` type: `python3`, 3.8 or later
- only for teaching new types: [Claude Code](https://claude.com/claude-code), installed and signed in

## Install

repo-kickoff runs from a clone of its repository, because its catalog of types lives there. Clone it, and put a link to the command on your `PATH`:

```console
$ git clone -q git@github.com:rmdesmond/repo-kickoff.git
$ mkdir -p ~/.local/bin && ln -s "$PWD/repo-kickoff/bin/repo-kickoff" ~/.local/bin/repo-kickoff
```

See which types it knows:

```console
$ repo-kickoff --list
bash-cli    A command-line tool written as a single bash script
python-cli  A command-line tool written in Python, packaged with pyproject.toml
```

## Start a bash tool

Give a type and a name:

```console
$ repo-kickoff bash-cli greet
Created greet from the bash-cli type.
```

`greet/` holds the bare bones of a bash command: `bin/greet`, a README, a `.gitignore` and a smoke test. The command doesn't do anything yet; that's yours to write:

```console
$ greet/bin/greet
greet: placeholder - nothing implemented yet
$ greet/bin/greet --help
Usage: greet
       greet --help | --version

greet doesn't do anything yet: it prints a placeholder line.

Options:
  -h, --help   show this help and exit
  --version    show the version and exit
$ greet/tests/smoke.sh
smoke: ok
```

## Start a Python tool

The same, with the `python-cli` type:

```console
$ repo-kickoff python-cli my-tool
Created my-tool from the python-cli type.
$ cd my-tool
$ tests/smoke.sh
smoke: ok
$ PYTHONPATH=src python3 -m my_tool --version
my-tool 0.1.0
$ ls src
my_tool
```

The command and the project are named `my-tool`, and the Python package inside is `my_tool`, because a Python package name can't contain a dash. The type's template writes the package as `src/{{NAME_SNAKE}}/`, and repo-kickoff turns `{{NAME_SNAKE}}` into the name with underscores for dashes, just as it turns `{{NAME}}` into the name itself.

## How python-cli got there: teaching a type

`python-cli` wasn't always in the catalog. When repo-kickoff is asked for a type it doesn't know, it can ask Claude to add it. Claude writes only the type's folder, `types/python-cli/`. repo-kickoff checks the new type, removes it if it fails, and otherwise generates your repository from it. This is the run that added `python-cli`, with `--yes` to skip the question repo-kickoff asks at a terminal (`Ask the AI command to add it? [y/N]`):

```console
$ repo-kickoff --yes python-cli demo
repo-kickoff: asking the AI command to add the python-cli type: ~/repo-kickoff/lib/ai-claude.sh
I've added the `python-cli` type. The check now prints `ok: python-cli has a description and a template, and its smoke test passes`, and shellcheck reports nothing on `tests/smoke.sh`. The first check failed because of a wrong flag in the smoke test's unit-test step; I fixed that and reran it.
…
repo-kickoff: checking the new python-cli type
ok: python-cli has a description and a template, and its smoke test passes
Added the python-cli type to ~/repo-kickoff/types/python-cli.
Review it, then commit it to keep it: git -C ~/repo-kickoff add types/python-cli
Created demo from the python-cli type.
```

It took about eight minutes. The type was then reviewed and committed, which is why your clone has it. (Claude first named the package `app`, since repo-kickoff then had no `{{NAME_SNAKE}}`; the type was changed to use it afterwards.) Asking for `python-cli` again, as you did above, uses the catalog and never calls Claude.

To teach a type of your own, ask for it at a terminal and answer `y`, or add `--yes`. Then review `types/<type>/`, and commit it so that every clone gets it.

## More ways in

Create the repository somewhere else with `--dest`:

```console
$ mkdir projects && repo-kickoff --dest projects bash-cli hello
Created projects/hello from the bash-cli type.
```

Leave out the type or the name at a terminal, and repo-kickoff asks for it. `--interactive` asks even when the answers come from a pipe:

```console
$ printf "1\nnotes-tool\n" | repo-kickoff --interactive
Known types:
  1) bash-cli    A command-line tool written as a single bash script
  2) python-cli  A command-line tool written in Python, packaged with pyproject.toml
Type (number or name): Name of the new repository: Created notes-tool from the bash-cli type.
```

Check that a type is complete, by generating a sample repository and running its smoke test:

```console
$ repo-kickoff --check-type python-cli
ok: python-cli has a description and a template, and its smoke test passes
```

## When something goes wrong

**A name with capitals, underscores or spaces.** Names are lower-case letters, digits and dashes, starting with a letter. Nothing is written:

```console
$ repo-kickoff bash-cli My_Tool
repo-kickoff: invalid name: My_Tool (use lower-case letters, digits and dashes, starting with a letter)

Usage: repo-kickoff [--dest DIR] [--interactive] [--yes] [<type> [<name>]]
…
```

**The folder already exists.** repo-kickoff never overwrites anything. Pick another name, or another `--dest`:

```console
$ repo-kickoff bash-cli greet
repo-kickoff: greet already exists
```

**An unknown type in a script.** Without a terminal, repo-kickoff won't call the AI unless told to. Run it at a terminal to be asked, or add `--yes`:

```console
$ repo-kickoff rust-cli fast-tool </dev/null
repo-kickoff: unknown type: rust-cli
repo-kickoff: known types: bash-cli, python-cli
repo-kickoff: to have the AI command add it, run again with --yes (or at a terminal)
```

## See also

- [README.md](../README.md): every option, the catalog's layout, and adding a type by hand
- `repo-kickoff --help`

Outputs from runs of 73e0846 and 4046b53 (2026-11-24), and a recorded run from 2026-11-24.
