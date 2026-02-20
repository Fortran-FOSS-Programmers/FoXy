---
title: About FoXy
---

# About FoXy

FoXy is a KISS (Keep It Simple and Stupid) pure Fortran library for parsing and emitting [XML](https://en.wikipedia.org/wiki/XML) files and tags.

## What is FoXy?

Modern Fortran standards (2003+) introduced better support for string manipulation. Exploiting these capabilities, FoXy provides an easy-to-use module library to parse and emit XML, suitable for use in scientific and engineering codes written in modern Fortran.

- **Pure Fortran** — no C bindings, no `ISO_C_BINDING`, no wrappers
- **Fortran 2008+ standard compliant**
- **OOP designed** — two clean classes: `xml_tag` and `xml_file`
- **FOSS** — multi-licensed (GPL v3 for open-source, BSD 2/3-Clause and MIT for commercial use)

## Why FoXy?

Other Fortran XML libraries exist — [xml-fortran](http://xml-fortran.sourceforge.net/), [xmlf90](https://github.com/rscircus/xmlf90), [fox](https://github.com/andreww/fox), [tixi](https://github.com/DLR-SC/tixi) — but FoXy was created to fill gaps in:

- Active maintenance
- Modern Fortran design (OOP, deferred-length allocatable characters)
- Pure Fortran implementation (no C binding layer)
- Parallel architecture safety (thread/process safe)
- Comprehensive testing

## Compiler Support

| Compiler | Status |
|----------|--------|
| GNU gfortran ≥ 14.2.0 | Supported |
| Intel ifort ≥ 16.x | Supported |
| IBM XL Fortran | Not tested |
| g95 | Not tested |
| NAG Fortran | Not tested |
| PGI / NVIDIA | Not tested |

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)
- Fortran FOSS Programmers - [https://github.com/Fortran-FOSS-Programmers](https://github.com/Fortran-FOSS-Programmers)

Contributions are welcome — see the [Contributing](/guide/contributing) page.

## Copyrights

FoXy is distributed under a multi-licensing system:

- For FOSS projects: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- For closed-source / commercial projects:
  - [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause)
  - [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause)
  - [MIT](http://opensource.org/licenses/MIT)
