---
title: Installation
---

# Installation

FoXy builds with fpm, FoBiS or CMake. All you need is a Fortran 2008 compiler: gfortran 14 or newer, ifx 2025 or
nvfortran 26 are tested.

## fpm

Add FoXy to the dependencies of your `fpm.toml`; fpm fetches it, and its dependencies, when you build:

```toml
[dependencies]
FoXy = { git = "https://github.com/Fortran-FOSS-Programmers/FoXy" }
```

## FoBiS

[FoBiS](https://github.com/szaghi/FoBiS) is the build tool of FoXy's development. Clone the repository and fetch the
dependencies (declared in `fobos`, cloned into `src/third_party/`):

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy
cd FoXy
fobis fetch
```

Build the library, `lib/libfoxy.a` with its modules in `lib/mod`, and link your program to it:

```bash
fobis build --mode foxy-static-gnu
gfortran -I lib/mod my_program.f90 lib/libfoxy.a -o my_program
```

The library holds the dependencies too: one archive, one module directory.

To run the tests (each test is a program in `src/tests`, built in `exe/`):

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh          # also tests-gnu-debug
fobis build --mode tests-intel && bash scripts/run_tests.sh        # ifx, also tests-intel-debug
fobis build --mode tests-nvidia && bash scripts/run_tests.sh       # nvfortran, also tests-nvidia-debug
```

`fobis build --lmodes` lists every mode.

## CMake

CMake uses the dependencies in `src/third_party/`: fetch them first.

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy
cd FoXy
fobis fetch
cmake -S . -B build
cmake --build build
cmake --install build
```

CMake installs package config files: `find_package(FoXy)` finds it in your project.

## Compilers

With your own flags:

- **ifx**: compile with `-heap-arrays`; ifx puts large temporaries (e.g. the content of a big tag) on the stack, which
  overflows on large documents.
- **nvfortran**: preprocess with `-Mpreprocess` and define `_NVF` (`-D_NVF`), which turns on StringiFor's nvfortran
  workarounds.

## Dependencies

| Library | Purpose |
|---|---|
| [PENF](https://github.com/szaghi/PENF) | portable kinds (`I1P`…`I8P`, `R4P`, `R8P`), number to string |
| [StringiFor](https://github.com/szaghi/StringiFor) | the string type used by the parser |
| [BeFoR64](https://github.com/szaghi/BeFoR64) | base64, used by StringiFor |
| [FACE](https://github.com/szaghi/FACE) | ANSI colours, used by StringiFor |

`fobis fetch` clones them at their default branches and records the revisions in `src/third_party/fobos.lock`;
`fobis fetch --update` updates them.

Next: [the tutorial](/manual/).
