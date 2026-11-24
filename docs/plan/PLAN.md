# Plan: repo-kickoff

Status: accepted 2026-11-24

repo-kickoff creates the starting skeleton of a new repository from a known project type: a bash CLI, a Python CLI, a C CLI, a C++ library, a PDF generator and so on. You run `repo-kickoff` with a type and a name, as arguments or answered at prompts, and it assembles the target repository from reusable components kept in its own catalog, with no AI involved. When asked for a type it doesn't know, it asks Claude (`claude -p`) to add that type to the catalog, checks the result, and then generates the target repository from it the same AI-free way. From then on the type is created without the AI. Taught types are written into your local clone of repo-kickoff, for you to review and commit.

## Scope

In:
- the `repo-kickoff` command (bash 3.2 or later, macOS and Linux), run with arguments (`repo-kickoff <type> <name> [--dest DIR]`) or with prompts for whatever is missing
- a catalog of types: one folder per type, holding template files with `{{NAME}}` placeholders
- `--list`, to show the known types
- the first type, `bash-cli`: a script that takes its name and prints a placeholder line to stdout, with `--help` and `--version`
- a type checker, which confirms a type is complete and that a repository generated from it passes its own smoke test
- unknown types taught through `claude -p`: teach first, check, then generate, with the AI command swappable so tests use a fake AI
- tests for all of the above, including the AI path through a fake AI

Out:
- creating the GitHub repository or running the i2r setup for a generated repository: repo-kickoff writes local files only
- changing the i2r skills to use repo-kickoff
- types beyond `bash-cli` in the first release, apart from those taught through the AI path
- Windows

## Constraints

- **Language:** bash, compatible with bash 3.2 (macOS's default) and bash 4 and 5 (Linux). No associative arrays, `${var,,}`, `mapfile` or other bash 4 features.
- **Tools:** only POSIX tools that behave the same on BSD (macOS) and GNU (Linux): no `sed -i`, no `readlink -f`. No Python, Node or other runtime.
- **Templates:** plain `{{NAME}}` placeholders, replaced with `sed`. No template engine.
- **AI:** `claude` is needed only to teach an unknown type. Known types work without it and without a network.
- **Lint:** `shellcheck`.
- **Tests:** a plain bash test runner, `tests/run.sh`, not `bats`. CI runs on Linux; work-issue runs the same commands locally on macOS.
- **Deadline:** none.

## Assumptions

None. Every choice above was confirmed by the user.

## Release target

Target: none - repo-kickoff is used from a git clone: clone the repository and symlink `bin/repo-kickoff` onto your `PATH`. Taught types are written into that clone, so the clone is the installation. Releases are tags with notes, with no packaged archive (decision 0002).

## Verification strategy

Test levels: unit (single behaviours of `repo-kickoff`, run against fixture catalogs in temporary folders) and integration (the command run end to end through a symlink on `PATH`, generating repositories and running their smoke tests). Automated tests always use a fake AI. The real `claude` is exercised by hand, in T-015.

| Stage | Enabled | Run command, or reason if disabled |
|---|---|---|
| lint | yes | `git ls-files -z 'bin/*' '*.sh' \| xargs -0 -r shellcheck` |
| build | no | bash scripts; nothing to compile |
| unit | from T-001 | `tests/run.sh unit` |
| integration | from T-005 | `tests/run.sh integration` |

Extra stages: none

## M1: Walking skeleton

`repo-kickoff bash-cli <name>` generates a working repository from the catalog, given its arguments.

### T-001: Add the bash test runner
Depends on: none
Done when:
- [x] `tests/run.sh unit` and `tests/run.sh integration` run every `tests/<level>/*_test.sh` file and print a pass and fail count
- [x] `tests/lib.sh` provides assert helpers (equal, contains, file exists, exit status) and a per-test temporary folder that is removed afterwards
- [x] The runner exits non-zero when any test fails, and exits 0 when a level has no tests
- [x] Runs on bash 3.2 and bash 5
- [x] A self-test in `tests/unit/` proves a failing assertion is reported as a failure
- [x] Enable the `unit` stage with `run: tests/run.sh unit`, and render the pipeline again

### T-002: Add the repo-kickoff command skeleton
Depends on: T-001
Done when:
- [x] `bin/repo-kickoff --help` prints usage and exits 0
- [x] `bin/repo-kickoff --version` prints `repo-kickoff <version>` from a `REPO_KICKOFF_VERSION=0.0.0` line
- [x] Unknown options and missing arguments print usage to stderr and exit 2
- [x] The command finds its own folder through one or more symlinks without `readlink -f`
- [x] `.project/config.yml` lists `"bin/repo-kickoff:REPO_KICKOFF_VERSION="` under `release.version_files`
- [x] Unit tests cover `--help`, `--version`, usage errors and running through a symlink

### T-003: Generate a repo from a catalog type
Depends on: T-002
Done when:
- [x] `repo-kickoff <type> <name>` copies `types/<type>/template/` to `./<name>`
- [x] `{{NAME}}` is replaced in file contents and in file and folder names
- [x] Executable bits are kept
- [x] An unknown type prints an error naming the known types and exits 1
- [x] The catalog folder can be overridden with `REPO_KICKOFF_TYPES`, for tests
- [x] Unit tests use a fixture type under `tests/fixtures/types/`

### T-004: Add the bash-cli type
Depends on: T-003
Done when:
- [ ] `types/bash-cli/description` holds a one-line summary
- [ ] The generated `bin/<name>` prints a placeholder line naming itself to stdout and exits 0, and supports `--help` and `--version`
- [ ] The template also generates `README.md`, `.gitignore` and `tests/smoke.sh`
- [ ] The generated `tests/smoke.sh` exits 0 when the command works
- [ ] Every generated shell file passes `shellcheck`
- [ ] Unit tests generate a `bash-cli` repo in a temporary folder and run its command and smoke test

### T-005: Integration test: symlinked command generates bash-cli
Depends on: T-004
Done when:
- [ ] A test symlinks `bin/repo-kickoff` into a temporary folder on `PATH` and runs it from an unrelated directory
- [ ] The generated repository's command runs and its `tests/smoke.sh` passes
- [ ] Enable the `integration` stage with `run: tests/run.sh integration`, and render the pipeline again

## M2: Usable tool

Release: v0.1.0

repo-kickoff is ready for everyday use with known types: it prompts for what's missing, lists types, checks its input, and can check that a type is complete.

### T-006: Validate names and destination
Depends on: T-003
Done when:
- [ ] Names must match `[a-z][a-z0-9-]*`; anything else is an error that exits 2
- [ ] `--dest DIR` puts the new repository in `DIR/<name>`; the default is the current directory
- [ ] An existing destination is refused, and nothing is written
- [ ] The repository is built in a temporary folder and moved into place, so a failure never leaves a partial repository
- [ ] Unit tests cover invalid names, `--dest`, an existing destination and a failure part-way through

### T-007: Add --list
Depends on: T-004
Done when:
- [ ] `repo-kickoff --list` prints each type and its description, sorted by type
- [ ] A type folder with no description is listed with `(no description)`
- [ ] Unit tests use a fixture catalog

### T-008: Prompt for missing type and name
Depends on: T-006, T-007
Done when:
- [ ] At a terminal, a missing type shows a numbered list of types to choose from, and a missing name is asked for
- [ ] An invalid choice or name is asked for again
- [ ] Without a terminal, missing arguments are a usage error that exits 2, never a hang
- [ ] `--interactive` asks even without a terminal, reading answers from stdin
- [ ] Unit tests pipe answers through `--interactive`, including invalid ones

### T-009: Add the type checker
Depends on: T-004
Done when:
- [ ] `repo-kickoff --check-type <type>` checks that the type has a description and a template containing `tests/smoke.sh`
- [ ] It generates a sample repository in a temporary folder and runs its `tests/smoke.sh`
- [ ] It reports every problem found, exits 1 if there are any, and leaves nothing behind
- [ ] Unit tests cover a complete fixture type and broken ones: no description, no template, no smoke test, a failing smoke test

### T-010: Write the README
Depends on: T-008, T-009
Done when:
- [ ] `README.md` covers installing from a clone with a symlink, usage with arguments and prompts, `--list`, `--check-type`, and the catalog layout
- [ ] It explains how to add a type by hand and check it
- [ ] Every command shown in it was run and its output copied from the run

### T-011: Integration test: everyday use
Depends on: T-008, T-009
Done when:
- [ ] Every type in `types/` passes `--check-type`
- [ ] A piped `--interactive` session generates a `bash-cli` repository whose smoke test passes
- [ ] An invalid name and an existing destination each leave the file system unchanged

## M3: Teach unknown types

Release: v0.2.0

When asked for a type it doesn't know, repo-kickoff has Claude add it to the catalog, checks it, and generates the repository; the next request for that type needs no AI.

### T-012: Add the swappable AI command
Depends on: T-009
Done when:
- [ ] The AI command comes from `REPO_KICKOFF_AI`; the default runs `claude -p` with `--permission-mode acceptEdits`, `--add-dir` set to the catalog, and a limited tool list
- [ ] A prompt file describes the type contract (description, template, `{{NAME}}`, `tests/smoke.sh`) and tells the AI to write only `types/<type>/`
- [ ] If the default is used and `claude` isn't installed, repo-kickoff says so, exits 1 and writes nothing
- [ ] Unit tests use a fake AI script and check it receives the type name, the catalog folder and the prompt

### T-013: Teach an unknown type
Depends on: T-012
Done when:
- [ ] An unknown type asks for confirmation before calling the AI; `--yes` skips the question; without a terminal and without `--yes`, it refuses and exits 1
- [ ] After the AI runs, the type checker runs on the new type
- [ ] If the AI fails or the check fails, the partial `types/<type>/` is removed and the problems are shown
- [ ] If the check passes, the target repository is generated from the new type, and repo-kickoff reminds you to review and commit `types/<type>/`
- [ ] If the catalog is in a git working copy, changes the AI made outside `types/<type>/` are reported as a warning
- [ ] The README explains teaching a type
- [ ] Unit tests use fake AIs that write a good type, write a broken type, and exit non-zero

### T-014: Integration test: teach, then reuse
Depends on: T-013
Done when:
- [ ] A fake AI, which records each call, teaches a new type, and the target repository is generated
- [ ] A second request for the same type generates a repository without calling the AI

### T-015: Teach python-cli with the real Claude
Depends on: T-013
Done when:
- [ ] `repo-kickoff python-cli demo` run by hand on macOS with the real `claude` teaches the `python-cli` type and generates `demo`
- [ ] The prompt file is adjusted for anything the run showed
- [ ] The taught `types/python-cli/` is committed and passes `--check-type` in CI
