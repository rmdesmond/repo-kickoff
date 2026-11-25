# Tutorial: start projects with repo-kickoff

In this tutorial you install repo-kickoff, start a bash tool called `greet`, a Python tool called `my-tool`, a C tool called `word-count`, a C library called `text-stats`, and a C++ tool and library, and see how types the catalog didn't have, such as `python-cli` and `c-cli`, were taught to repo-kickoff by Claude, so that you can now use them with no AI at all.

Paths are shortened: `~` is your home folder, and you work in it. Claude's replies, in the recorded step, vary in wording from run to run.

## Before you start

- macOS or Linux, with bash 3.2 or later and `git`
- for the `python-cli` type: `python3`, 3.8 or later
- for the `c-cli`, `c-lib`, `cpp-cli` and `cpp-lib` types: CMake 3.14 or later, a C and C++ compiler (Apple clang or gcc), and GoogleTest for their unit tests (`brew install googletest`, or `apt install libgtest-dev`)
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
c-cli       A command-line program in C11, built with CMake, with GoogleTest unit tests
c-lib       A C library, built with CMake, with GoogleTest unit tests and an installable CMake package
cpp-cli     A command-line program in C++17, built with CMake, with GoogleTest unit tests
cpp-lib     A C++17 library, built with CMake, with GoogleTest unit tests and an installable CMake package
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
$ cd ..
```

The command and the project are named `my-tool`, and the Python package inside is `my_tool`, because a Python package name can't contain a dash. The type's template writes the package as `src/{{NAME_SNAKE}}/`, and repo-kickoff turns `{{NAME_SNAKE}}` into the name with underscores for dashes, just as it turns `{{NAME}}` into the name itself.

## Start a C tool

The `c-cli` type gives a C program built with CMake:

```console
$ repo-kickoff c-cli word-count
Created word-count from the c-cli type.
$ cd word-count
$ cmake -S . -B build >/dev/null && cmake --build build >/dev/null
$ build/word-count
word-count: placeholder - nothing implemented yet
$ build/word-count --version
word-count 0.1.0
$ ls include src tests
include:
word_count.h

src:
main.c
word_count.c

tests:
smoke.sh
word_count_test.cpp
```

As with Python, the program is `word-count` and the C names are `word_count`: the header, the source file, and every function, such as `word_count_run()`. `main.c` only calls into `word_count.c`, so the GoogleTest tests in `tests/word_count_test.cpp` can call the same functions. The smoke test builds in a temporary folder, checks the program and runs them:

```console
$ tests/smoke.sh
smoke: configuring in …/word-count-smoke.VblxSE
smoke: building
smoke: running unit tests
…
100% tests passed, 0 tests failed out of 5
…
smoke: ok
$ cd ..
```

The unit tests need GoogleTest. Without it, configuring stops with `GoogleTest not found.` and the three ways out: install it, configure with `-Dword_count_FETCH_GOOGLETEST=ON` to have CMake download it, or build only the program with `-Dword_count_BUILD_TESTS=OFF`. Nothing is ever downloaded unless you ask.

## Start a C library

The `c-lib` type gives a C library that other CMake projects can use, whether it's installed or pulled into their build:

```console
$ repo-kickoff c-lib text-stats
Created text-stats from the c-lib type.
$ cd text-stats
$ ls include src tests cmake
cmake:
text-statsConfig.cmake.in

include:
text_stats.h

src:
text_stats.c

tests:
smoke.sh
text_stats_test.cpp
$ cmake -S . -B build >/dev/null && cmake --build build >/dev/null
$ (cd build && ctest)
…
1/2 Test #1: Version.StartsWithADigit .........   Passed    0.00 sec
…
2/2 Test #2: Placeholder.NamesTheLibrary ......   Passed    0.00 sec

100% tests passed, 0 tests failed out of 2
…
```

Every public name in `text_stats.h` starts with `text_stats_`, and the header wraps them in `extern "C"`, so C++ can use the library too. Installing it puts the header, the library and a CMake package under a prefix:

```console
$ cmake --install build --prefix ~/.local
-- Install configuration: ""
-- Installing: ~/.local/lib/libtext_stats.a
-- Installing: ~/.local/include/text_stats.h
-- Installing: ~/.local/lib/cmake/text-stats/text_statsTargets.cmake
-- Installing: ~/.local/lib/cmake/text-stats/text_statsTargets-noconfig.cmake
-- Installing: ~/.local/lib/cmake/text-stats/text-statsConfig.cmake
-- Installing: ~/.local/lib/cmake/text-stats/text-statsConfigVersion.cmake
```

Another project then uses it with `find_package(text-stats)` and links `text_stats::text_stats`. `text-stats/README.md` shows how. The smoke test does this whole round trip in a temporary folder. It builds the library and runs the tests, installs the library, then builds and runs a small program against the installed package:

```console
$ tests/smoke.sh
smoke: configuring in …/text-stats-smoke.TQtQkg/build
smoke: building
smoke: running unit tests
…
100% tests passed, 0 tests failed out of 2
…
smoke: installing into …/text-stats-smoke.TQtQkg/prefix
smoke: building a program against the installed package
smoke: ok
$ cd ..
```

The unit tests are built only when `text-stats` is the top-level project. A project that pulls it in with `add_subdirectory()` or `FetchContent` needs neither GoogleTest nor a C++ compiler.

## Start a C++ tool and a C++ library

`cpp-cli` and `cpp-lib` are the C++17 counterparts of the C types. They have the same layout ideas and the same GoogleTest tests, and the code lives in a namespace named after the project:

```console
$ repo-kickoff cpp-cli hello-cpp
Created hello-cpp from the cpp-cli type.
$ cd hello-cpp
$ ls include/hello_cpp src tests
include/hello_cpp:
hello_cpp.hpp

src:
hello_cpp.cpp
main.cpp

tests:
hello_cpp_test.cpp
smoke.sh
$ cmake -S . -B build >/dev/null && cmake --build build >/dev/null
$ build/hello-cpp
hello-cpp: placeholder - nothing implemented yet
$ build/hello-cpp --version
hello-cpp 0.1.0
$ (cd build && ctest)
…
100% tests passed, 0 tests failed out of 6
…
$ cd ..
```

The logic is in `namespace hello_cpp`, and `main.cpp` only calls `hello_cpp::run()`, so the tests call the same function. `cpp-lib` gives a library that installs a CMake package, as `c-lib` does. Its smoke test makes the same round trip:

```console
$ repo-kickoff cpp-lib geometry
Created geometry from the cpp-lib type.
$ cd geometry
$ ls include/geometry src tests cmake
cmake:
geometryConfig.cmake.in

include/geometry:
geometry.hpp

src:
geometry.cpp

tests:
geometry_test.cpp
smoke.sh
$ tests/smoke.sh
smoke: configuring in …/geometry-smoke.DDZQiV/build
smoke: building
smoke: running unit tests
…
100% tests passed, 0 tests failed out of 2
…
smoke: installing into …/geometry-smoke.DDZQiV/prefix
smoke: building a program against the installed package
smoke: ok
$ cd ..
```

Another project uses it with `find_package(geometry)` and links `geometry::geometry`, or pulls it in with `add_subdirectory()`. `geometry/README.md` shows both.

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

## Teaching with requirements: c-cli

Left to itself, Claude picks the build system, the test framework and the layout. `c-cli` was taught with requirements, given with `--hint`: CMake, GoogleTest, the logic in a small library so the tests can call it, and a smoke test that never downloads. repo-kickoff adds the hint to Claude's prompt:

```console
$ repo-kickoff --yes --hint "$(cat hint.txt)" c-cli demo
repo-kickoff: asking the AI command to add the c-cli type: ~/repo-kickoff/lib/ai-claude.sh
I wrote the `c-cli` type. `repo-kickoff --check-type c-cli` prints `ok: c-cli has a description and a template, and its smoke test passes`, and shellcheck finds nothing in `tests/smoke.sh`.

GoogleTest isn't installed on this Mac, so the check only covered the case without it: the program built, its output checks passed, and the smoke test reported the unit tests as skipped. The GoogleTest tests have never been compiled or run, so neither the test file nor the opt-in download is verified yet.
…
repo-kickoff: checking the new c-cli type
ok: c-cli has a description and a template, and its smoke test passes
Added the c-cli type to ~/repo-kickoff/types/c-cli.
Review it, then commit it to keep it: git -C ~/repo-kickoff add types/c-cli
Created demo from the c-cli type.
```

It took about three minutes. Claude's warning was right: built with GoogleTest, the tests didn't compile, because a helper's name clashed with one of GoogleTest's own. The fix was made in review, before the type was committed. Review is part of teaching: repo-kickoff checks what it can, and you check the rest.

`cpp-cli` and `cpp-lib` were taught the same way, each in under two minutes; their runs are in `docs/runs/`. `c-lib` came about differently: it was written with Claude in a chat, then reviewed and committed by hand, the same as adding a type yourself (see the README). Either way, the type ends up as a folder in `types/` that repo-kickoff checks with `--check-type`.

To teach a type of your own, ask for it at a terminal and answer `y`, or add `--yes`, with `--hint` for any requirements. Then review `types/<type>/`, and commit it so that every clone gets it.

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
  2) c-cli       A command-line program in C11, built with CMake, with GoogleTest unit tests
  3) c-lib       A C library, built with CMake, with GoogleTest unit tests and an installable CMake package
  4) cpp-cli     A command-line program in C++17, built with CMake, with GoogleTest unit tests
  5) cpp-lib     A C++17 library, built with CMake, with GoogleTest unit tests and an installable CMake package
  6) python-cli  A command-line tool written in Python, packaged with pyproject.toml
Type (number or name): Name of the new repository: Created notes-tool from the bash-cli type.
```

Check that a type is complete, by generating a sample repository and running its smoke test:

```console
$ repo-kickoff --check-type python-cli
ok: python-cli has a description and a template, and its smoke test passes
$ repo-kickoff --check-type c-cli
ok: c-cli has a description and a template, and its smoke test passes
$ repo-kickoff --check-type c-lib
ok: c-lib has a description and a template, and its smoke test passes
$ repo-kickoff --check-type cpp-cli
ok: cpp-cli has a description and a template, and its smoke test passes
$ repo-kickoff --check-type cpp-lib
ok: cpp-lib has a description and a template, and its smoke test passes
```

## When something goes wrong

**A name with capitals, underscores or spaces.** Names are lower-case letters, digits and dashes, starting with a letter. Nothing is written:

```console
$ repo-kickoff bash-cli My_Tool
repo-kickoff: invalid name: My_Tool (use lower-case letters, digits and dashes, starting with a letter)

Usage: repo-kickoff [--dest DIR] [--interactive] [--yes] [--hint TEXT] [<type> [<name>]]
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
repo-kickoff: known types: bash-cli, c-cli, c-lib, cpp-cli, cpp-lib, python-cli
repo-kickoff: to have the AI command add it, run again with --yes (or at a terminal)
```

## See also

- [README.md](../README.md): every option, the catalog's layout, and adding a type by hand
- `repo-kickoff --help`

Outputs from a run of 50c628a (2026-11-25, macOS, GoogleTest installed), and recorded teaching runs from 2026-11-24 and 2026-11-25 (docs/runs/).
