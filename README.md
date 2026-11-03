<div align="center">

<img src="docs/public/logo.svg" alt="FoXy logo: a low-poly arctic fox whose eyes and white blaze read &lt;/&gt;" width="112">

# FoXy
#### Fortran XML for poor people

[![GitHub tag](https://img.shields.io/github/v/tag/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/tags)
[![GitHub issues](https://img.shields.io/github/issues/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/issues)
[![CI](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml/badge.svg)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://Fortran-FOSS-Programmers.github.io/FoXy/coverage.json)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

> Read, query, edit and write XML from modern Fortran: a DOM for documents, an index for huge files, a streaming parser
> with your own callbacks, a writer for any size. Pure Fortran 2008, one module: `use foxy`.

</div>

| 📄 **Parse**<br>Strings and files, read in chunks (over 2 GiB too); UTF-8, UTF-16, UTF-32, Latin-1; tolerant, the first problem with its line | 🔎 **Query**<br>By name, path or parent; path expressions (`select`); regular expressions on names, contents, attributes | 🔢 **Typed values**<br>Contents and attributes read and written as integers, reals, logicals, lists, with an error status | ✏️ **Edit and save**<br>Change contents, attributes and names by tag ID; insert and delete tags; the prolog kept |
|:---:|:---:|:---:|:---:|
| 🖋️ **Write any size**<br>`xml_writer`, element by element, to a file, a unit or memory; only well-formed XML | 🗂️ **Huge files**<br>`xml_index`: the tags without their content, contents read on demand | 📡 **Streaming parser**<br>`xml_handler`: your callbacks in source order, nothing stored | 🆓 **Free and portable**<br>Pure Fortran 2008, no C; gfortran, ifx, nvfortran; fpm, FoBiS, CMake; GPLv3, BSD, MIT |

<p align="center"><img src="docs/examples/images/tour.svg" alt="a terminal session of fx, a tool built on FoXy: the tree of a case file, a value read as a number, a path expression, a regular expression, a malformed file and a UTF-16 file streamed through a handler"></p>

>#### [Documentation](https://Fortran-FOSS-Programmers.github.io/FoXy/)
> The [tutorial](https://Fortran-FOSS-Programmers.github.io/FoXy/manual/tutorial/01-first-document), the
> [cookbook](https://Fortran-FOSS-Programmers.github.io/FoXy/manual/cookbook) and the
> [reference](https://Fortran-FOSS-Programmers.github.io/FoXy/guide/features) are on the
> [FoXy website](https://Fortran-FOSS-Programmers.github.io/FoXy/).

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

Then link your program to it:

```bash
gfortran -I lib/mod my_program.f90 lib/libfoxy.a -o my_program
```

**CMake**: fetch the dependencies first (`fobis fetch`), then `cmake -S . -B build && cmake --build build`.

See [Installation](https://Fortran-FOSS-Programmers.github.io/FoXy/guide/installation) for compilers and options.

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
