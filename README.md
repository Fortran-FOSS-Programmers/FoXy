# FoXy

>#### Fortran XML parser for poor people
>a KISS pure Fortran 2008+ OOP library for parsing and emitting [XML](https://en.wikipedia.org/wiki/XML) files and tags.

[![GitHub tag](https://img.shields.io/github/v/tag/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/tags)
[![GitHub issues](https://img.shields.io/github/issues/Fortran-FOSS-Programmers/FoXy)](https://github.com/Fortran-FOSS-Programmers/FoXy/issues)
[![CI](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml/badge.svg)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/endpoint?url=https://Fortran-FOSS-Programmers.github.io/FoXy/coverage.json)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

| 📄 **Parse XML**<br>From string or file into a linearised DOM with full hierarchy tracking; nested and repeated same-name tags supported | 🏗️ **Programmatic creation**<br>Build tags with attributes, text content, and nesting; emit to string or write atomically to a file unit | ✏️ **Flexible emission**<br>Self-closing tags, indentation control, partial emission — start tag, content, and end tag separately | 🔧 **Manipulation**<br>Add and delete tags and attributes by name |
|:---:|:---:|:---:|:---:|
| 🎯 **OOP design**<br>Two clean types — `xml_tag` and `xml_file` — all functionality as type-bound procedures | 🔒 **Pure Fortran**<br>No C bindings, no wrappers — pure Fortran 2008+ with `implicit none` throughout | 🔓 **Multi-licensed**<br>GPL v3 · BSD 2/3-Clause · MIT | 📦 **Multiple build systems**<br>fpm, FoBiS.py, CMake |

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

Parse an XML string and query a tag's content:

```fortran
use foxy, only: xml_file
implicit none
type(xml_file)                :: xfile
character(len=:), allocatable :: val

call xfile%parse(string= &
  '<config>'//new_line('A')// &
  '  <dt unit="s">0.01</dt>'//new_line('A')// &
  '  <nstep>1000</nstep>'//new_line('A')// &
  '</config>')

val = xfile%content('dt')
print *, val   ! 0.01
```

Create and emit a tag programmatically:

```fortran
use foxy, only: xml_tag
implicit none
type(xml_tag) :: tag

tag = xml_tag(name='point', &
              attributes=reshape([['x','1'],['y','2'],['z','3']], [2,3]))
print *, tag%stringify()   ! <point x="1" y="2" z="3"/>
```

---

## Install

### FoBiS

**Standalone** — clone, fetch dependencies, and build:

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy && cd FoXy
FoBiS.py fetch                        # fetch PENF, StringiFor, BeFoR64, FACE
FoBiS.py build -mode tests-gnu && bash scripts/run_tests.sh
```

**As a project dependency** — declare FoXy in your `fobos` and run `fetch`:

```ini
[dependencies]
deps_dir = src/third_party
FoXy = https://github.com/Fortran-FOSS-Programmers/FoXy
```

```bash
FoBiS.py fetch           # fetch and build
FoBiS.py fetch --update  # re-fetch and rebuild
```

### fpm

Add to your `fpm.toml`:

```toml
[dependencies]
FoXy = { git = "https://github.com/Fortran-FOSS-Programmers/FoXy" }
```

```bash
fpm build
fpm test
```

### CMake

```bash
git clone https://github.com/Fortran-FOSS-Programmers/FoXy && cd FoXy
cmake -B build && cmake --build build
```
