# FoXy

>#### Fortran XML parser for poor people
>a KISS pure Fortran 2008+ OOP library for parsing and emitting [XML](https://en.wikipedia.org/wiki/XML) files and tags.

[![GitHub tag](https://img.shields.io/github/v/tag/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/tags)
[![GitHub issues](https://img.shields.io/github/issues/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/issues)
[![CI](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml/badge.svg)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://Fortran-FOSS-Programmers.github.io/FoXy/coverage.json)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

| 📄 **Parse XML**<br>From string or file into a linearised DOM with full hierarchy tracking; nested and repeated same-name tags supported | 🏗️ **Programmatic creation**<br>Build tags with attributes, text content, and nesting; emit to string or write atomically to a file unit | ✏️ **Flexible emission**<br>Self-closing tags, indentation control, partial emission — start tag, content, and end tag separately | 🔧 **Manipulation**<br>Edit parsed documents by tag ID: content, attributes; add and delete tags at any level |
|:---:|:---:|:---:|:---:|
| 🎯 **OOP design**<br>Four types — `xml_tag`, `xml_file`, `xml_index` and `xml_writer` — all functionality as type-bound procedures | 🔒 **Pure Fortran**<br>No C bindings, no wrappers — pure Fortran 2008+ with `implicit none` throughout | 🔓 **Multi-licensed**<br>GPL v3 · BSD 2/3-Clause · MIT | 📦 **Multiple build systems**<br>fpm, FoBiS.py, CMake |

>#### [Documentation](https://Fortran-FOSS-Programmers.github.io/FoXy/)
> For full (guide, API reference, examples, etc...) see the [FoXy website](https://Fortran-FOSS-Programmers.github.io/FoXy/).

---

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Fortran FOSS Programmers — [https://github.com/Fortran-FOSS-Programmers](https://github.com/Fortran-FOSS-Programmers)

Contributions are welcome — see the [Contributing](https://Fortran-FOSS-Programmers.github.io/FoXy/guide/contributing) page.

## Copyrights

This project is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

> Anyone interested in using, developing, or contributing to FoXy is welcome — pick the license that best fits your needs.

---

## Quick start

Read the settings of a case file as numbers:

```fortran
use foxy
type(xml_file) :: doc
real(R8P)      :: dt
integer(I4P)   :: steps

call doc%parse(filename='case.xml')
call doc%get_content(id=doc%find(path='case/time/dt'), value=dt)
call doc%get_content(id=doc%find(path='case/time/steps'), value=steps)
```

Learn the rest in the [tutorial](https://Fortran-FOSS-Programmers.github.io/FoXy/manual/tutorial/01-first-document),
or find a task in the [cookbook](https://Fortran-FOSS-Programmers.github.io/FoXy/manual/cookbook).

---

## Install

**fpm**: add FoXy to your `fpm.toml`.

```toml
[dependencies]
FoXy = { git = "https://github.com/Fortran-FOSS-Programmers/FoXy" }
```

**FoBiS**: clone, fetch the dependencies, build the library (`lib/libfoxy.a`, modules in `lib/mod`) or the tests.

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy && cd FoXy
fobis fetch
fobis build --mode foxy-static-gnu
fobis build --mode tests-gnu && bash scripts/run_tests.sh
```

**CMake**: fetch the dependencies first (`fobis fetch`), then `cmake -S . -B build && cmake --build build`.

See [Installation](https://Fortran-FOSS-Programmers.github.io/FoXy/guide/installation) for compilers and options.
