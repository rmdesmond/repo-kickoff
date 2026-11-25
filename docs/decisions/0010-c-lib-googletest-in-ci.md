# 0010: c-lib requires GoogleTest for its tests, and CI installs it

Date: 2026-11-25
Status: accepted

## Context

A `c-lib` type was written with Claude, outside a teaching run, so it has no run log in `docs/runs/`. Its first draft used plain C tests with a small `CHECK` macro and no framework. The maintainer wants GoogleTest, as in `c-cli`. For `c-cli`, decision 0009 made GoogleTest optional because neither the maintainer's Mac nor CI's Ubuntu image had it, and as a result CI never runs `c-cli`'s gtest tests. GoogleTest is now installed on the maintainer's Mac with Homebrew. Each pipeline stage is one `run` command, which work-issue also runs locally, and the rendered pipeline has no separate setup step.

## Decision

- `c-lib`'s unit tests are GoogleTest. When the library is the top-level project, the tests are built and GoogleTest is required: an installed copy, or a `FetchContent` download the developer opts into. Without either, configuring fails and says how to get it or turn the tests off. When another project uses the library, the tests aren't built, so that project needs neither GoogleTest nor C++.
- `tests/ensure-googletest.sh` makes sure GoogleTest is there: it does nothing if GoogleTest is installed, installs `libgtest-dev` with `apt-get` on Linux, and otherwise fails with the `brew` command. The `integration` stage runs it before `tests/run.sh integration`.
- `c-lib` keeps `{{NAME_SNAKE}}` names, and its smoke test still never downloads.
- No teaching run or run log is required for a type that wasn't taught through repo-kickoff.

## Consequences

- `--check-type c-lib`, and so the integration tests, fail on a machine without GoogleTest, with the install command in the message.
- CI installs `libgtest-dev` on every integration run, which takes some time and needs the package archive to be reachable. The smoke tests themselves stay offline.
- `c-cli`'s gtest tests now run in CI too. Decision 0009 still stands: `c-cli` doesn't require GoogleTest.
