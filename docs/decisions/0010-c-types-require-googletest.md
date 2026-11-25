# 0010: The C types require GoogleTest for their tests, and CI installs it

Date: 2026-11-25
Status: accepted

Supersedes 0009's choice to make GoogleTest optional. The rest of 0009 still holds: `c-cli` builds with CMake, and was taught with `--hint`.

## Context

A `c-lib` type was written with Claude, outside a teaching run, so it has no run log in `docs/runs/`. Its first draft used plain C tests with a small `CHECK` macro and no framework. The maintainer wants GoogleTest in both C types. For `c-cli`, decision 0009 made GoogleTest optional because neither the maintainer's Mac nor CI's Ubuntu image had it. As a result, CI never runs `c-cli`'s gtest tests, and a generated repository can quietly build with no unit tests at all. GoogleTest is now installed on the maintainer's Mac with Homebrew. Each pipeline stage is one `run` command, which work-issue also runs locally, and the rendered pipeline has no separate setup step.

## Decision

- The unit tests of `c-cli` and `c-lib` are GoogleTest, and GoogleTest is required to build them: an installed copy, or a `FetchContent` download the developer opts into. Without either, configuring fails, and says how to get GoogleTest or how to turn the tests off with `-D<name>_BUILD_TESTS=OFF`.
- `c-lib` builds its tests only when it's the top-level project. When another project uses the library, its tests aren't built, so that project needs neither GoogleTest nor C++.
- The smoke tests always run the gtest tests with `ctest`, and still never download.
- `tests/ensure-googletest.sh` makes sure GoogleTest is there: it does nothing if GoogleTest is installed, installs `libgtest-dev` with `apt-get` on Linux, and otherwise fails with the `brew` command. The `integration` stage runs it before `tests/run.sh integration`.
- No teaching run or run log is required for a type that wasn't taught through repo-kickoff.

## Consequences

- On a machine without GoogleTest, `--check-type` fails for both C types, and so do the integration tests. The message gives the install command.
- CI installs `libgtest-dev` on every integration run, which takes some time and needs the package archive to be reachable. The smoke tests themselves stay offline.
- Repositories generated from `c-cli` before this change still treat GoogleTest as optional. Changing them is out of scope.
