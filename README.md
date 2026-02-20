# FoXy

**Fortran XML parser for poor people** — a KISS pure Fortran 2008+ OOP library for parsing and emitting [XML](https://en.wikipedia.org/wiki/XML) files and tags.

[![CI](https://github.com/Fortran-FOSS-Programmers/FoXy/actions/workflows/ci.yml/badge.svg)](https://github.com/Fortran-FOSS-Programmers/FoXy/actions)
[![Coverage](https://img.shields.io/codecov/c/github/Fortran-FOSS-Programmers/FoXy.svg)](https://app.codecov.io/gh/Fortran-FOSS-Programmers/FoXy)
[![GitHub tag](https://img.shields.io/github/tag/Fortran-FOSS-Programmers/FoXy.svg)](https://github.com/Fortran-FOSS-Programmers/FoXy/releases)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

---

## Features

- Parse XML from a **string** or a **file** into a linearised DOM with full hierarchy tracking
- Nested tags and repeated tags with the same name supported
- Create tags programmatically with attributes, text content, and nesting
- Emit tags to string or write atomically to a file unit
- Self-closing tags, indentation, and partial emission (start / content / end separately)
- Add and delete tags and attributes by name
- OOP designed — two clean types (`xml_tag`, `xml_file`), all functionality as type-bound procedures
- No C bindings, no wrappers — pure Fortran 2008+ with `implicit none` throughout
- Multi build system: fpm, FoBiS.py, CMake

**[Documentation](https://Fortran-FOSS-Programmers.github.io/FoXy/)** | **[API Reference](https://Fortran-FOSS-Programmers.github.io/FoXy/api/)**

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

### fpm (recommended)

Add FoXy as a dependency in your `fpm.toml`:

```toml
[dependencies]
FoXy = { git = "https://github.com/Fortran-FOSS-Programmers/FoXy" }
```

### Clone and build with FoBiS.py

```sh
git clone --recursive https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
FoBiS.py build -mode tests-gnu && bash scripts/run_tests.sh
```

### Clone and build with CMake

```sh
git clone --recursive https://github.com/Fortran-FOSS-Programmers/FoXy.git
cd FoXy
mkdir build && cd build
cmake ..
make && make install
```

| Tool | Command |
|------|---------|
| fpm | `fpm build && fpm test` |
| FoBiS.py | `FoBiS.py build -mode tests-gnu` |
| CMake | `cmake .. && make` |
