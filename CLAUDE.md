# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FoXy is a pure Fortran (F2008+) library for parsing and emitting XML. It is object-oriented and uses conventional commits + git-cliff for changelog management.

## Dependencies

Dependencies are fetched by FoBiS (not git submodules) into `src/third_party/`, as declared in the `[dependencies]`
section of `fobos` and pinned in `src/third_party/fobos.lock`:

- **PENF** – Fortran precision/kind parameters (I1P, I4P, R4P, R8P, …)
- **StringiFor** – string type used throughout parsing
- **BeFoR64** – Base64 (used by StringiFor)
- **FACE** – file-handle utilities

```bash
fobis fetch   # on a fresh clone, before the first build
```

No dependency version is pinned anywhere: `fobos` and `fpm.toml` both track the default branch of each dependency, and
`fobos.lock` is local only (ignored by `src/third_party/.gitignore`). Do not add `rev`/`tag`/`branch` pins.

## Build Commands

FoBiS is the primary build tool (configured in `fobos`). CMake and fpm are also supported.

```bash
fobis build --mode tests-gnu         # GNU, optimized
fobis build --mode tests-gnu-debug   # GNU, -std=f2018, runtime checks, backtraces
fobis clean --mode tests-gnu
fobis build --lmodes                 # list modes (also tests-intel, tests-intel-debug)
fobis rule --ls                      # list rules (makecoverage, makecoverage-analysis, makedoc, ...)
```

Build output goes to `./exe/` (binaries, plus `exe/obj/` and `exe/mod/`).

## Running Tests

```bash
fobis build --mode tests-gnu && bash scripts/run_tests.sh
fobis rule --ex makecoverage                     # debug + coverage build, tests, gcov
```

`scripts/run_tests.sh` is repo-agnostic (shared across the FoBiS repos): it runs every executable in `./exe/` and
judges **PASS/FAIL by exit status only** (plus an optional `<name>.result` expected-output file). Every test in
`src/tests/foxy_test_*.f90` must therefore end with:

```fortran
print "(A,L1)", new_line('a')//'Are all tests passed? ', all(test_passed)
if (.not.all(test_passed)) error stop 1
```

A test that only prints `F` is reported as PASS. Each test file covers a single concern (tag creation, parsing,
attribute manipulation, file I/O, etc.). CMake globs `src/tests/*.f90`, so new tests need no registration.

## Code Style

From `CONTRIBUTING.md`:
- 2-space indentation, no tabs (existing sources use 3 spaces: match the surrounding code)
- No trailing whitespace, Unix line endings
- `implicit none` everywhere
- Named intent declarations on all procedure arguments
- Named constants, no magic numbers
- Descriptive variable names (avoid abbreviations)
- Conventional commits: `feat:`, `fix:`, `perf:`, `refactor:`, `docs:`, `test:`, `build:`, `ci:`, `chore:`. Append `!` for breaking changes.

## Architecture

Four source modules, all in `src/lib/`:

```
foxy.f90          ← thin re-export wrapper (use this in user code)
foxy_xml_file.f90 ← xml_file type: array-based DOM container
foxy_xml_tag.F90  ← xml_tag type: single element (note .F90 = preprocessed)
foxy_xml_entities.f90 ← xml_escape/xml_unescape: character references
```

**`xml_tag`** stores a single XML element: name, text content, `attribute(:,:)` (2-row array of name/value pairs),
source positions `pos(3)` (start, content, end), indentation, self-closing flag, and hierarchy IDs (`id`, `parent_id`,
`child_id(:)`). Key methods: `parse()`, `stringify()`, `add_attributes()`, `delete_attributes()`, `delete_content()`,
`start_tag()`, `end_tag()`, `self_closing_tag()`.

**`xml_file`** holds a flat `tag(:)` array (linearised DOM, not a tree of pointers) and a count `nt`. Key methods:
`parse()`, `stringify()`, `add_tag()`, `delete_tag()`, `content()`.

There are **two parsers**:
- `xml_file%parse_from_string` — the document parser: a single-pass, quotes-aware tokenizer (start/end/self-closing
  tags, CDATA kept as raw text, comments/PIs/DOCTYPE skipped) with a stack of open tags; children lists are built once
  at the end (`build_children`).
- `xml_tag%parse`/`search` — the older single-tag parser, still used by `xml_tag%get_content` (and so by
  `xml_file%content`) to look up nested tags by name.

Stored text is the source text (so `stringify` round-trips); the read accessors (`content`, `attribute`, `get_attribute`)
strip layout blanks and decode character references. Content may hold markup (nested tag as string), so it is never
escaped on output: user data must go through `xml_escape`.

Known parser limits: a tag's content is only the text before its first child (mixed content is lost); CDATA is kept as raw text (not decoded by the accessors yet); comments, PIs and DOCTYPE are dropped.

Performance: parse and `stringify` are O(n) in the number of tags, lookups O(n) per path segment (tags array and stringify buffer grow
geometrically, children lists are built once after parsing). Check any change on large inputs with the benchmark:
`fobis build --mode benchmark-gnu && exe/benchmarks/foxy_benchmark_parse quakeml 100000` (also `flat`, `deep`;
`benchmark-gnu-profile` builds it with `-pg` for gprof).

## CI/CD

GitHub Actions, built on two local composite actions (`.github/actions/setup-build-env`,
`.github/actions/run-coverage-analysis`) shared in form across the FoBiS repos:

- `ci.yml` — every branch push/PR: setup, `fetch`, tests with coverage (`rule --ex makecoverage-analysis`)
- `docs.yml` — coverage + API docs (`formal`, via `rule-makedoc`) + VitePress site, deployed to GitHub Pages; it
  overwrites `docs/public/coverage.json` with the coverage badge
- `release.yml` — on a `vX.Y.Z` tag: tarball + GitHub release with notes extracted from `CHANGELOG.md`
- `install.yml` — install smoke test (`scripts/install.sh`)

Running `fobis rule --ex makecoverage` locally also rewrites `docs/public/coverage.json`: do not commit that change.

## Releases

```bash
scripts/release.sh --patch    # or --minor, --major, vX.Y.Z
```

Pre-flight checks, git-cliff `CHANGELOG.md`, bumps `VERSION` and the `fpm.toml` version, commits, creates an annotated
tag and pushes (which triggers `release.yml`). `scripts/bump.sh` is the older equivalent.
