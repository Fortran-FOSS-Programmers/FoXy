# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FoXy is a pure Fortran (F2008+) library for parsing and emitting XML. It is object-oriented and uses conventional commits + git-cliff for changelog management.

## Build Commands

FoBiS is the primary build tool (configured in `fobos`). CMake and fpm are also supported.

```bash
# Build tests (GNU, optimized)
FoBiS.py build -mode tests-gnu

# Build tests (GNU, with debug checks and backtraces)
FoBiS.py build -mode tests-gnu-debug

# Clean build artifacts
FoBiS.py clean -mode tests-gnu

# Build with fpm (alternative)
fpm build
```

Build output goes to `./exe/` (binaries), `./obj/`, and `./mod/`.

## Running Tests

```bash
# Build then run all tests
FoBiS.py build -mode tests-gnu && bash scripts/run_tests.sh

# Run all tests with fpm
fpm test
```

`scripts/run_tests.sh` finds executables in `./exe/`, runs each, and checks output for the pattern `"Are all tests passed? T/F"`. Exit code 0 = all passed.

Each test file in `src/tests/foxy_test_*.f90` covers a single concern (tag creation, parsing, attribute manipulation, file I/O, etc.).

## Code Style

From `CONTRIBUTING.md`:
- 2-space indentation, no tabs
- No trailing whitespace, Unix line endings
- `implicit none` everywhere
- Named intent declarations on all procedure arguments
- Named constants, no magic numbers
- Descriptive variable names (avoid abbreviations)
- Conventional commits: `feat:`, `fix:`, `perf:`, `refactor:`, `docs:`, `test:`, `build:`, `ci:`, `chore:`. Append `!` for breaking changes.

## Architecture

Three source modules, all in `src/lib/`:

```
foxy.f90          ← thin re-export wrapper (use this in user code)
foxy_xml_file.f90 ← xml_file type: array-based DOM container
foxy_xml_tag.F90  ← xml_tag type: single element (note .F90 = preprocessed)
```

**`xml_tag`** stores a single XML element: name, text content, `attribute(:,:)` (2-column array of name/value pairs), indentation level, self-closing flag, and hierarchy IDs (`id`, `parent_id`, `child_id(:)`). Key methods: `parse()`, `stringify()`, `add_attributes()`, `delete_attributes()`, `delete_content()`, `start_tag()`, `end_tag()`, `self_closing_tag()`.

**`xml_file`** holds a flat `tag(:)` array (linearised DOM, not a tree pointer structure) and a count `nt`. Key methods: `parse()`, `stringify()`, `add_tag()`, `delete_tag()`, `content()`.

Third-party dependencies are git submodules in `src/third_party/`:
- **PENF** – Fortran precision/kind parameters (I1P, I4P, R4P, R8P, …)
- **StringiFor** – string type used throughout parsing
- **BeFoR64** – Base64 (used by StringiFor)
- **FACE** – file-handle utilities

When initialising a fresh clone: `git submodule update --init --recursive`.

## CI/CD

`.github/workflows/ci.yml` runs on every push:
1. Installs gfortran 14, Graphviz, FORD, FoBiS.py
2. Builds with `FoBiS.py rule -ex makecoverage` and runs `scripts/run_tests.sh`
3. Uploads coverage to Codecov, builds and deploys VitePress + FORD docs to GitHub Pages
4. On a version tag, creates a tarball release via `FoBiS.py rule -ex maketar`

## Releases

```bash
# Bump version, generate CHANGELOG.md, commit + tag + push
scripts/bump.sh patch   # 0.0.8 → 0.0.9
scripts/bump.sh minor   # 0.0.8 → 0.1.0
scripts/bump.sh v2.1.0  # explicit version
```
