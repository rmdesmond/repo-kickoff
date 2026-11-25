# 0011: C++ types: cpp-cli and cpp-lib, in C++17, taught by Claude

Date: 2026-11-25
Status: accepted

## Context

The maintainer wants C++ counterparts to `c-cli` and `c-lib`: a command-line program and a library. Type names may only use lower-case letters, digits and dashes, so `c++` can't appear in one. GoogleTest 1.15, the version `c-cli` downloads, needs at least C++14, and `c-cli`'s tests already build as C++17. Apple clang on macOS and gcc on CI's Ubuntu image both support C++17 fully.

## Decision

- The types are named `cpp-cli` and `cpp-lib`.
- Both use C++17, built with CMake.
- Both are taught by the real Claude through `repo-kickoff --yes --hint`, with the run logs saved in `docs/runs/`, as `c-cli` was. `cpp-cli` is taught first, so its run can improve the prompt before `cpp-lib`.
- Both require GoogleTest for their tests, as decision 0010 does for the C types. CI installs it.

## Consequences

- Two more teaching runs test the teaching path, and the prompt file can be adjusted after each.
- The types can't use C++20 features unless a later decision raises the standard.
