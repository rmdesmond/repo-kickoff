# 0009: c-cli builds with CMake and treats GoogleTest as optional

Date: 2026-11-24
Status: superseded by 0010

## Context

The maintainer wants a `c-cli` type: a C command-line program built with CMake, with unit tests in GoogleTest. Every type's smoke test must run offline (lib/teach-prompt.md), and the integration tests run `--check-type` on every type in CI. GoogleTest is not installed on the maintainer's Mac, nor, by default, on CI's Ubuntu image, while cmake and C and C++ compilers are on both. Teaching gave Claude no way to receive requirements like these, so it would choose its own build system and test framework.

## Decision

- The template's CMake uses an installed GoogleTest when `find_package` finds one, and downloads it with `FetchContent` only when the developer opts in.
- Its smoke test builds and runs the program, and builds and runs the gtest tests only when GoogleTest is present, so `--check-type` passes offline without it.
- The type is taught by Claude, like `python-cli`, with the requirements passed through a new `--hint` option (T-019).
- For T-020, GoogleTest is installed on the maintainer's Mac with Homebrew, so the gtest tests are run at least once for real.

## Consequences

- CI checks that the type builds and runs, but not its gtest tests, unless GoogleTest is added to CI later.
- Developers get gtest tests by installing GoogleTest, or by opting in to the download.
- `--hint` is available for teaching any future type.
