---
title: Installation
---

# Installation

FoXy supports three build systems. **fpm** is the recommended approach for new projects.

## Fortran Package Manager (fpm) — Recommended

Add FoXy as a dependency in your `fpm.toml`:

```toml
[dependencies]
FoXy = { git = "https://github.com/Fortran-FOSS-Programmers/FoXy" }
```

Then build and test:

```bash
fpm build
fpm test
```

## FoBiS (for development / contributing)

[FoBiS.py](https://github.com/szaghi/FoBiS) is the primary build tool used for development and CI.

Clone the repository and fetch the dependencies (declared in `fobos`, fetched into `src/third_party/`):

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
fobis fetch
```

Build and run tests:

```bash
# GNU, optimised
fobis build --mode tests-gnu && bash scripts/run_tests.sh

# GNU, debug (-std=f2018, runtime checks, backtraces)
fobis build --mode tests-gnu-debug && bash scripts/run_tests.sh

# Intel ifx (also tests-intel-debug)
fobis build --mode tests-intel && bash scripts/run_tests.sh

# NVIDIA nvfortran (also tests-nvidia-debug)
fobis build --mode tests-nvidia && bash scripts/run_tests.sh
```

Build artefacts go to `./exe/` (binaries, `exe/obj/`, `exe/mod/`). `fobis build --lmodes` lists all modes.

### Compilers

The test suite passes with gfortran 14+, ifx 2025.3 and nvfortran 26.5. Building FoXy with your own flags:

- **ifx** — compile with `-heap-arrays`: ifx puts large temporaries (function results, e.g. the content of a big
  tag) on the stack, which overflows on large documents.
- **nvfortran** — preprocess the `.F90` sources with `-Mpreprocess`.

## CMake

The CMake build uses the dependencies in `src/third_party/`: fetch them first.

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
fobis fetch
mkdir build && cd build
cmake ..
make
make install
```

CMake generates package config files for use with `find_package(FoXy)` in downstream projects.

## Dependencies

`fobis fetch` clones the dependencies into `src/third_party/` (tracking their default branches) and records the
fetched revisions in `src/third_party/fobos.lock`; `fobis fetch --update` updates them.

| Library | Purpose |
|---------|---------|
| PENF | Fortran precision/kind parameters (`I4P`, `R8P`, …) |
| StringiFor | String type used throughout parsing |
| BeFoR64 | Base64 encoding (used by StringiFor) |
| FACE | File-handle utilities |
