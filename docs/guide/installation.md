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

Clone the repository with submodules:

```bash
git clone --recursive https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
```

Build and run tests:

```bash
# GNU, optimised
FoBiS.py build -mode tests-gnu && bash scripts/run_tests.sh

# GNU, debug (array-bounds checking, backtraces)
FoBiS.py build -mode tests-gnu-debug && bash scripts/run_tests.sh

# Intel
FoBiS.py build -mode tests-intel && bash scripts/run_tests.sh
```

Build artefacts go to `./exe/` (binaries), `./obj/`, and `./mod/`.

## CMake

```bash
git clone --recursive https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
mkdir build && cd build
cmake ..
make
make install
```

CMake generates package config files for use with `find_package(FoXy)` in downstream projects.

## Updating Submodules

If you cloned without `--recursive`, initialise the third-party dependencies manually:

```bash
git submodule update --init --recursive
```

Third-party libraries (in `src/third_party/`):

| Library | Purpose |
|---------|---------|
| PENF | Fortran precision/kind parameters (`I4P`, `R8P`, …) |
| StringiFor | String type used throughout parsing |
| BeFoR64 | Base64 encoding (used by StringiFor) |
| FACE | File-handle utilities |
