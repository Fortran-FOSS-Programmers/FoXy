---
layout: home

hero:
  name: FoXy
  text: Fortran XML Parser
  tagline: A KISS pure Fortran library for parsing and emitting XML files and tags.
  actions:
    - theme: brand
      text: Guide
      link: /guide/
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: GitHub
      link: https://github.com/Fortran-FOSS-Programmers/FoXy

features:
  - icon: 📂
    title: Pure Fortran
    details: No C bindings, no wrappers. Pure Fortran 2008+ with object-oriented design.
  - icon: 🌲
    title: Linearised DOM
    details: Parses XML into a flat array-based DOM with full hierarchy tracking — nested and repeated tags supported.
  - icon: ✏️
    title: Emit & Parse
    details: Create tags programmatically, serialise to string or file, or parse from string or file.
  - icon: 🛠️
    title: Multi Build System
    details: Build with fpm (recommended), FoBiS.py, or CMake. Integrate into your fpm project with a single dependency entry.
  - icon: 🧪
    title: OOP / TDD Designed
    details: Two clean types — xml_tag and xml_file — expose all functionality as type-bound procedures, backed by 11 focused automated tests.
  - icon: 🆓
    title: Free & Open Source
    details: Multi-licensed — GPLv3 for FOSS projects, BSD 2/3-Clause or MIT for commercial use. Fortran 2008+ standard compliant.
---

## Quick start

Parse an XML string and query a tag's content:

```fortran
use foxy, only: xml_file
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
type(xml_tag) :: tag

tag = xml_tag(name='point', &
              attributes=reshape([['x','1'],['y','2'],['z','3']], [2,3]))
print *, tag%stringify()   ! <point x="1" y="2" z="3"/>
```

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Fortran FOSS Programmers - [https://github.com/Fortran-FOSS-Programmers](https://github.com/Fortran-FOSS-Programmers)

Contributions are welcome — see the [Contributing](/guide/contributing) page.

## Copyrights

FoXy is distributed under a multi-licensing system:

| Use case | License |
|----------|---------|
| FOSS projects | [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html) |
| Closed source / commercial | [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) |
| Closed source / commercial | [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause) |
| Closed source / commercial | [MIT](http://opensource.org/licenses/MIT) |

> Anyone interested in using, developing, or contributing to FoXy is welcome — pick the license that best fits your needs.
