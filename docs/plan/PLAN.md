# Plan: repo-kickoff

Status: accepted 2026-11-25

repo-kickoff creates the starting skeleton of a new repository from a known project type: a bash CLI, a Python CLI, a C CLI, a C++ library, a PDF generator and so on. You run `repo-kickoff` with a type and a name, as arguments or answered at prompts, and it assembles the target repository from reusable components kept in its own catalog, with no AI involved. When asked for a type it doesn't know, it asks Claude (`claude -p`) to add that type to the catalog, checks the result, and then generates the target repository from it the same AI-free way. From then on the type is created without the AI. Taught types are written into your local clone of repo-kickoff, for you to review and commit.

## Scope

In:
- the `repo-kickoff` command (bash 3.2 or later, macOS and Linux), run with arguments (`repo-kickoff <type> <name> [--dest DIR]`) or with prompts for whatever is missing
- a catalog of types: one folder per type, holding template files with `{{NAME}}` placeholders, and `{{NAME_SNAKE}}` for the name in snake_case (`my-tool` → `my_tool`), for languages whose identifiers can't contain dashes
- `--list`, to show the known types
- the first type, `bash-cli`: a script that takes its name and prints a placeholder line to stdout, with `--help` and `--version`
- a type checker, which confirms a type is complete and that a repository generated from it passes its own smoke test
- unknown types taught through `claude -p`: teach first, check, then generate, with the AI command swappable so tests use a fake AI
- requirements passed to the AI when teaching a type (`--hint`)
- the `python-cli` type using `{{NAME_SNAKE}}` for its package name
- a `c-cli` type: a C command-line program built with CMake, with GoogleTest unit tests, taught by Claude
- a `c-lib` type: a C library built with CMake, with GoogleTest unit tests and an installable CMake package, written with Claude
- a `cpp-cli` type (a C++17 command-line program) and a `cpp-lib` type (a C++17 library with an installable CMake package), both built with CMake, with GoogleTest unit tests, taught by Claude
- GoogleTest required by the C and C++ types' unit tests, and installed in CI so those tests run there
- tests for all of the above, including the AI path through a fake AI

Out:
- creating the GitHub repository or running the i2r setup for a generated repository: repo-kickoff writes local files only
- changing the i2r skills to use repo-kickoff
- types beyond `bash-cli` in the first release, apart from those taught through the AI path
- Windows
- other derived name forms (`{{NAME_PASCAL}}`, upper case, …), and refusing names that are keywords in a type's language (a repository named `class` gets a Python package named `class`)
- changing repositories generated before a type changed

## Constraints

- **Language:** bash, compatible with bash 3.2 (macOS's default) and bash 4 and 5 (Linux). No associative arrays, `${var,,}`, `mapfile` or other bash 4 features.
- **Tools:** only POSIX tools that behave the same on BSD (macOS) and GNU (Linux): no `sed -i`, no `readlink -f`. No Python, Node or other runtime.
- **Templates:** plain `{{NAME}}` and `{{NAME_SNAKE}}` placeholders, replaced with `sed`. No template engine (decision 0008).
- **Types' own tools:** a type's smoke test may need its language's usual tools (`python3`; cmake and a C and C++ compiler), but never a network. GoogleTest is required by the `c-cli`, `c-lib`, `cpp-cli` and `cpp-lib` tests: an installed copy, or a download the developer opts into, and never a download in a smoke test. CI installs it (decision 0010, which supersedes 0009's optional GoogleTest). The C++ types use C++17 (decision 0011).
- **AI:** `claude` is needed only to teach an unknown type. Known types work without it and without a network.
- **Lint:** `shellcheck`.
- **Tests:** a plain bash test runner, `tests/run.sh`, not `bats`. CI runs on Linux; work-issue runs the same commands locally on macOS.
- **Deadline:** none.

## Assumptions

None. Every choice above was confirmed by the user.

## Release target

Target: none - repo-kickoff is used from a git clone: clone the repository and symlink `bin/repo-kickoff` onto your `PATH`. Taught types are written into that clone, so the clone is the installation. Releases are tags with notes, with no packaged archive (decision 0002).

## Verification strategy

Test levels: unit (single behaviours of `repo-kickoff`, run against fixture catalogs in temporary folders) and integration (the command run end to end through a symlink on `PATH`, generating repositories and running their smoke tests). Automated tests always use a fake AI. The real `claude` is exercised by hand, in T-015 and T-020.

| Stage | Enabled | Run command, or reason if disabled |
|---|---|---|
| lint | yes | `git ls-files -z 'bin/*' '*.sh' \| xargs -0 -r shellcheck` |
| build | no | bash scripts; nothing to compile |
| unit | from T-001 | `tests/run.sh unit` |
| integration | from T-005 | `tests/run.sh integration`; from T-022, `tests/ensure-googletest.sh && tests/run.sh integration` |

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
- [x] `types/bash-cli/description` holds a one-line summary
- [x] The generated `bin/<name>` prints a placeholder line naming itself to stdout and exits 0, and supports `--help` and `--version`
- [x] The template also generates `README.md`, `.gitignore` and `tests/smoke.sh`
- [x] The generated `tests/smoke.sh` exits 0 when the command works
- [x] Every generated shell file passes `shellcheck`
- [x] Unit tests generate a `bash-cli` repo in a temporary folder and run its command and smoke test

### T-005: Integration test: symlinked command generates bash-cli
Depends on: T-004
Done when:
- [x] A test symlinks `bin/repo-kickoff` into a temporary folder on `PATH` and runs it from an unrelated directory
- [x] The generated repository's command runs and its `tests/smoke.sh` passes
- [x] Enable the `integration` stage with `run: tests/run.sh integration`, and render the pipeline again

## M2: Usable tool

Release: v0.1.0

repo-kickoff is ready for everyday use with known types: it prompts for what's missing, lists types, checks its input, and can check that a type is complete.

### T-006: Validate names and destination
Depends on: T-003
Done when:
- [x] Names must match `[a-z][a-z0-9-]*`; anything else is an error that exits 2
- [x] `--dest DIR` puts the new repository in `DIR/<name>`; the default is the current directory
- [x] An existing destination is refused, and nothing is written
- [x] The repository is built in a temporary folder and moved into place, so a failure never leaves a partial repository
- [x] Unit tests cover invalid names, `--dest`, an existing destination and a failure part-way through

### T-007: Add --list
Depends on: T-004
Done when:
- [x] `repo-kickoff --list` prints each type and its description, sorted by type
- [x] A type folder with no description is listed with `(no description)`
- [x] Unit tests use a fixture catalog

### T-008: Prompt for missing type and name
Depends on: T-006, T-007
Done when:
- [x] At a terminal, a missing type shows a numbered list of types to choose from, and a missing name is asked for
- [x] An invalid choice or name is asked for again
- [x] Without a terminal, missing arguments are a usage error that exits 2, never a hang
- [x] `--interactive` asks even without a terminal, reading answers from stdin
- [x] Unit tests pipe answers through `--interactive`, including invalid ones

### T-009: Add the type checker
Depends on: T-004
Done when:
- [x] `repo-kickoff --check-type <type>` checks that the type has a description and a template containing `tests/smoke.sh`
- [x] It generates a sample repository in a temporary folder and runs its `tests/smoke.sh`
- [x] It reports every problem found, exits 1 if there are any, and leaves nothing behind
- [x] Unit tests cover a complete fixture type and broken ones: no description, no template, no smoke test, a failing smoke test

### T-010: Write the README
Depends on: T-008, T-009
Done when:
- [x] `README.md` covers installing from a clone with a symlink, usage with arguments and prompts, `--list`, `--check-type`, and the catalog layout
- [x] It explains how to add a type by hand and check it
- [x] Every command shown in it was run and its output copied from the run

### T-011: Integration test: everyday use
Depends on: T-008, T-009
Done when:
- [x] Every type in `types/` passes `--check-type`
- [x] A piped `--interactive` session generates a `bash-cli` repository whose smoke test passes
- [x] An invalid name and an existing destination each leave the file system unchanged

## M3: Teach unknown types

Release: v0.2.0

When asked for a type it doesn't know, repo-kickoff has Claude add it to the catalog, checks it, and generates the repository; the next request for that type needs no AI.

### T-012: Add the swappable AI command
Depends on: T-009
Done when:
- [x] The AI command comes from `REPO_KICKOFF_AI`; the default runs `claude -p` with `--permission-mode acceptEdits`, `--add-dir` set to the catalog, and a limited tool list
- [x] A prompt file describes the type contract (description, template, `{{NAME}}`, `tests/smoke.sh`) and tells the AI to write only `types/<type>/`
- [x] If the default is used and `claude` isn't installed, repo-kickoff says so, exits 1 and writes nothing
- [x] Unit tests use a fake AI script and check it receives the type name, the catalog folder and the prompt

### T-013: Teach an unknown type
Depends on: T-012
Done when:
- [x] An unknown type asks for confirmation before calling the AI; `--yes` skips the question; without a terminal and without `--yes`, it refuses and exits 1
- [x] After the AI runs, the type checker runs on the new type
- [x] If the AI fails or the check fails, the partial `types/<type>/` is removed and the problems are shown
- [x] If the check passes, the target repository is generated from the new type, and repo-kickoff reminds you to review and commit `types/<type>/`
- [x] If the catalog is in a git working copy, changes the AI made outside `types/<type>/` are reported as a warning
- [x] The README explains teaching a type
- [x] Unit tests use fake AIs that write a good type, write a broken type, and exit non-zero

### T-014: Integration test: teach, then reuse
Depends on: T-013
Done when:
- [x] A fake AI, which records each call, teaches a new type, and the target repository is generated
- [x] A second request for the same type generates a repository without calling the AI

### T-015: Teach python-cli with the real Claude
Depends on: T-013
Done when:
- [x] `repo-kickoff python-cli demo` run by hand on macOS with the real `claude` teaches the `python-cli` type and generates `demo`
- [x] The prompt file is adjusted for anything the run showed
- [x] The taught `types/python-cli/` is committed and passes `--check-type` in CI

## M4: Snake-case names

Release: v0.3.0

Types can use `{{NAME_SNAKE}}` wherever a language needs an identifier, and `python-cli` does: `repo-kickoff python-cli my-tool` gives a `my_tool` package.

### T-016: Add the {{NAME_SNAKE}} placeholder
Depends on: none
Done when:
- [x] The generator replaces `{{NAME_SNAKE}}` with the name, dashes turned into underscores, in file contents and in file and folder names, alongside `{{NAME}}`
- [x] The README's catalog section describes it
- [x] `lib/teach-prompt.md` describes it, in place of the advice to use a fixed identifier
- [x] Unit tests cover contents, file and folder names, a name with no dashes, and both placeholders in one file

### T-017: Use {{NAME_SNAKE}} in the python-cli type
Depends on: T-016
Done when:
- [x] The package is `src/{{NAME_SNAKE}}/`, and no `app` package remains
- [x] `pyproject.toml`, `__main__.py`, the unit tests, `tests/smoke.sh` (`python3 -m {{NAME_SNAKE}}`) and the template's README use it, and the README's paragraph on renaming the package is gone
- [x] `repo-kickoff --check-type python-cli` passes, and the template's shell files pass shellcheck

### T-018: Integration test: a dashed Python name
Depends on: T-017
Done when:
- [x] Through the symlink on `PATH`, `repo-kickoff python-cli my-tool` creates `my-tool/src/my_tool/` and no `app` folder
- [x] In it, `PYTHONPATH=src python3 -m my_tool --version` prints `my-tool 0.1.0`, and `tests/smoke.sh` passes

## M5: A C command-line type

Release: v0.4.0

`repo-kickoff c-cli <name>` gives a C program built with CMake, with GoogleTest unit tests, and teaching can be given the user's requirements.

### T-019: Pass requirements when teaching a type
Depends on: T-016
Done when:
- [x] `--hint TEXT` adds the text to the prompt under *Requirements from the user*, for teaching through `--yes`, `--teach` or the question at a terminal; without `--hint`, the section is left out
- [x] `--hint` without teaching (a known type, `--list`, `--check-type`) is a usage error
- [x] The README explains it
- [x] Unit tests check the fake AI's prompt holds the hint, and has no such section without one

### T-020: Teach c-cli with the real Claude
Depends on: T-019
Done when:
- [x] `repo-kickoff --yes --hint "..." c-cli demo`, run by hand on macOS with the real `claude`, teaches the `c-cli` type: CMake, a C program printing its placeholder line with `--help` and `--version`, GoogleTest unit tests, `{{NAME_SNAKE}}` for C identifiers
- [x] Its CMake uses an installed GoogleTest when found, and downloads it with `FetchContent` only when the developer opts in; its smoke test builds and runs the program, and runs the gtest tests only when GoogleTest is present
- [x] `--check-type c-cli` passes on macOS without GoogleTest, and with it after `brew install googletest`, where `ctest` runs the gtest tests and they pass
- [x] The prompt file is adjusted for anything the run showed
- [x] The run's log is saved in `docs/runs/`
- [x] The reviewed `types/c-cli/` is committed and passes `--check-type` in CI

### T-021: Integration test: build a generated C repository
Depends on: T-020
Done when:
- [x] Through the symlink on `PATH`, `repo-kickoff c-cli my-tool` creates a repository that builds with `cmake -S . -B build && cmake --build build`
- [x] The built program prints `my-tool: placeholder - nothing implemented yet`

## M6: A C library type, and GoogleTest for both C types

Release: v0.5.0

`repo-kickoff c-lib <name>` gives a C library built with CMake, with GoogleTest unit tests and a CMake package that other projects find with `find_package`, and both C types require GoogleTest for their unit tests, which CI runs.

### T-022: Install GoogleTest for the integration stage
Depends on: none
Done when:
- [x] `tests/ensure-googletest.sh` exits 0 when GoogleTest is installed; on Linux without it, installs `libgtest-dev` with `apt-get` (through `sudo` when not root); elsewhere it exits 1 naming `brew install googletest`
- [x] The `integration` stage's `run` is `tests/ensure-googletest.sh && tests/run.sh integration`, and the pipeline is rendered again
- [x] In CI, `c-cli`'s smoke test runs its gtest tests, not the "skipped" path
- [x] Unit tests cover the installed, installed-by-apt and not-found paths, with `apt-get` and `sudo` replaced by stubs

### T-023: Add the c-lib type
Depends on: T-022
Done when:
- [x] `types/c-lib/`, written with Claude and reviewed, has a one-line description and a template: a C11 library built with CMake, static by default and shared with `-DBUILD_SHARED_LIBS=ON`; a public header `include/{{NAME_SNAKE}}.h` with `{{NAME_SNAKE}}_` names and an `extern "C"` block; and a README and `.gitignore`
- [x] Its unit tests are GoogleTest (`tests/{{NAME_SNAKE}}_test.cpp`), run by `ctest`; they're built when it's the top-level project, from an installed GoogleTest, or downloaded with `FetchContent` only when the developer opts in; with neither, configuring fails with a message saying how to get it or turn the tests off
- [x] Used from another project (`add_subdirectory`, `FetchContent`), its tests aren't built, so that project doesn't need GoogleTest or C++
- [x] `cmake --install` installs the header, the library and a CMake package, so another project uses `find_package(<name>)` and links `{{NAME_SNAKE}}::{{NAME_SNAKE}}`
- [x] Its `tests/smoke.sh` never downloads: it builds, runs the gtest tests with `ctest`, installs into a temporary prefix, and builds and runs a program against the installed package
- [x] `repo-kickoff --check-type c-lib` passes on macOS with GoogleTest from Homebrew, and in CI; the template's shell files pass shellcheck
- [x] The tutorial's catalog listings include `c-lib`

### T-024: Integration test: build, install and use a generated C library
Depends on: T-023
Done when:
- [ ] Through the symlink on `PATH`, `repo-kickoff c-lib my-lib` creates a repository that builds with `cmake -S . -B build && cmake --build build`, whose gtest tests pass with `ctest`, and which installs a `my-lib` CMake package
- [ ] A program built against it with `add_subdirectory` prints `my-lib: placeholder - nothing implemented yet`, without building the library's tests
- [ ] The repository has `include/my_lib.h` and `src/my_lib.c`, and no file still holds a `{{` placeholder

### T-025: Require GoogleTest in the c-cli type
Depends on: T-022
Done when:
- [ ] `c-cli`'s CMake builds the gtest tests by default, from an installed GoogleTest or a `FetchContent` download only when the developer opts in; with neither, or with no C++ compiler, configuring fails with a message saying how to get GoogleTest or turn the tests off with `-D{{NAME_SNAKE}}_BUILD_TESTS=OFF`
- [ ] Its `tests/smoke.sh` always runs the gtest tests with `ctest`, still never downloads, and has no "skipped" path
- [ ] The template's README, and the tutorial's requirements for `c-cli`, say GoogleTest is required
- [ ] `tests/integration/c_cli_test.sh` checks that a generated `my-tool` runs its gtest tests with `ctest` and they pass
- [ ] `repo-kickoff --check-type c-cli` passes on macOS with GoogleTest from Homebrew, and in CI; the template's shell files pass shellcheck

## M7: C++ types

Release: v0.6.0

`repo-kickoff cpp-cli <name>` gives a C++17 command-line program and `repo-kickoff cpp-lib <name>` a C++17 library with an installable CMake package, both built with CMake and tested with GoogleTest in CI.

### T-026: Teach cpp-cli with the real Claude
Depends on: T-022
Done when:
- [ ] `repo-kickoff --yes --hint "..." cpp-cli demo`, run by hand on macOS with the real `claude`, teaches the `cpp-cli` type: CMake, C++17, a program printing its placeholder line with `--help` and `--version`, its logic in a small library the tests call, and `{{NAME_SNAKE}}` for the namespace and other identifiers
- [ ] GoogleTest is required to build the tests: an installed copy, or a `FetchContent` download only when the developer opts in; with neither, configuring fails with a message saying how to get it or turn the tests off with `-D{{NAME_SNAKE}}_BUILD_TESTS=OFF`
- [ ] Its `tests/smoke.sh` never downloads: it builds and runs the program, and runs the gtest tests with `ctest`
- [ ] `repo-kickoff --check-type cpp-cli` passes on macOS with GoogleTest from Homebrew, and in CI; the template's shell files pass shellcheck
- [ ] The prompt file is adjusted for anything the run showed
- [ ] The run's log is saved in `docs/runs/`
- [ ] The reviewed `types/cpp-cli/` is committed, and the tutorial's catalog listings include it

### T-027: Integration test: build a generated C++ repository
Depends on: T-026
Done when:
- [ ] Through the symlink on `PATH`, `repo-kickoff cpp-cli my-tool` creates a repository that builds with `cmake -S . -B build && cmake --build build`
- [ ] The built program prints `my-tool: placeholder - nothing implemented yet`, and `--version` prints `my-tool 0.1.0`
- [ ] Its gtest tests run with `ctest` and pass
- [ ] Its C++ identifiers use `my_tool`, and no file still holds a `{{` placeholder

### T-028: Teach cpp-lib with the real Claude
Depends on: T-026
Done when:
- [ ] `repo-kickoff --yes --hint "..." cpp-lib demo`, run by hand on macOS with the real `claude`, teaches the `cpp-lib` type: CMake, a C++17 library, static by default and shared with `-DBUILD_SHARED_LIBS=ON`, its public header under `include/` with everything in namespace `{{NAME_SNAKE}}`
- [ ] GoogleTest is required to build the tests: an installed copy, or a `FetchContent` download only when the developer opts in; with neither, configuring fails with a message saying how to get it or turn the tests off with `-D{{NAME_SNAKE}}_BUILD_TESTS=OFF`; the tests are built only when it's the top-level project, so a project using it through `add_subdirectory` or `FetchContent` doesn't need GoogleTest
- [ ] `cmake --install` installs the headers, the library and a CMake package, so another project uses `find_package(<name>)` and links `{{NAME_SNAKE}}::{{NAME_SNAKE}}`
- [ ] Its `tests/smoke.sh` never downloads: it builds, runs the gtest tests with `ctest`, installs into a temporary prefix, and builds and runs a program against the installed package
- [ ] `repo-kickoff --check-type cpp-lib` passes on macOS with GoogleTest from Homebrew, and in CI; the template's shell files pass shellcheck
- [ ] The prompt file is adjusted for anything the run showed
- [ ] The run's log is saved in `docs/runs/`
- [ ] The reviewed `types/cpp-lib/` is committed, and the tutorial's catalog listings include it

### T-029: Integration test: build, install and use a generated C++ library
Depends on: T-028
Done when:
- [ ] Through the symlink on `PATH`, `repo-kickoff cpp-lib my-lib` creates a repository that builds with `cmake -S . -B build && cmake --build build`, whose gtest tests pass with `ctest`, and which installs a `my-lib` CMake package
- [ ] A program built against it with `add_subdirectory` prints `my-lib: placeholder - nothing implemented yet`, without building the library's tests
- [ ] Its C++ identifiers use `my_lib`, and no file still holds a `{{` placeholder
