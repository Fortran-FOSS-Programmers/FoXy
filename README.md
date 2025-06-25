<a name="top"></a>

# FoXy

[![License](https://img.shields.io/badge/license-GNU%20GeneraL%20Public%20License%20v3,%20GPLv3-blue.svg)]()
[![License](https://img.shields.io/badge/license-BSD2-red.svg)]()
[![License](https://img.shields.io/badge/license-BSD3-red.svg)]()
[![License](https://img.shields.io/badge/license-MIT-red.svg)]()

[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)]()
[![Build Status](https://travis-ci.org/Fortran-FOSS-Programmers/FoXy.svg?branch=master)](https://travis-ci.org/Fortran-FOSS-Programmers/FoXy)
[![Coverage Status](https://img.shields.io/codecov/c/github/Fortran-FOSS-Programmers/FoXy.svg)](http://codecov.io/github/Fortran-FOSS-Programmers/FoXy?branch=master)

### FoXy, Fortran XML parser for poor people

A KISS pure Fortran Library for parsing XML files

- FoXy is a pure Fortran (KISS) library for modern Fortran projects;
- FoXy is Fortran 2008+ standard compliant;
- FoXy is OOP designed;
- FoXy is a Free, Open Source Project.

#### Compiler Support

[![Compiler](https://img.shields.io/badge/GNU-v14.2.0+-brightgreen.svg)]()
[![Compiler](https://img.shields.io/badge/Intel-v16.x+-brightgreen.svg)]()
[![Compiler](https://img.shields.io/badge/IBM%20XL-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/g95-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/NAG-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/PGI-not%20tested-yellow.svg)]()

---

[What is FoXy?](#what-is-foxy) | [Aims](#Aims) | [Status](#status) | [Documentation](#documentation) | [Copyrights](#copyrights)

---

## What is FoXy?

Modern Fortran standards (2003+) have introduced better support for strings manipulations. Exploiting such new Fortran capabilities, FoXy is aimed to provide an easy to use module library to parse and emit [XML](https://en.wikipedia.org/wiki/XML) files and or tags.

## Aims

Other programming languages have many libraries for XML parsing, Fortran has less options, but some there are:

+ [xml-fortran](http://xml-fortran.sourceforge.net/) of Arjen Markus;
+ [xml-f90](https://github.com/rscircus/xmlf90) of Alberto Garcia;
+ [fox](https://github.com/andreww/fox) of Andrew Walker that is an improved fork of [xml-f90](https://github.com/rscircus/xmlf90) of Alberto Garcia;
+ [tixi](https://github.com/DLR-SC/tixi) from DLR Simulation and Software Technology (C-binding).

All of the above are great codes, but lack in some points that we would like to have:

+ actively maintained;
+ designed for modern Fortran:
  + OOP designed;
  + exploiting new features of Fortran (e.g. deferred length allocatable characters);
  + recreate a pure Fortran representation of the XML data (e.g. tree structure exploiting);
+ parallel architectures supported (threads/processes safety ensured);
+ extensively tested (strong unit-test regression);
+ comprehensively documented;
+ pure Fortran:
  + no wrapper;
  + no bindings, no `ISO_C_BINDING`;
+ be FOSS.

In some sense or other, the afore-mentioned Fortran libraries miss somethings.

Go to [Top](#top)

## Status

[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)]()
[![Build Status](https://travis-ci.org/Fortran-FOSS-Programmers/FoXy.svg?branch=master)](https://travis-ci.org/Fortran-FOSS-Programmers/FoXy)
[![Coverage Status](https://img.shields.io/codecov/c/github/Fortran-FOSS-Programmers/FoXy.svg)](http://codecov.io/github/Fortran-FOSS-Programmers/FoXy?branch=master)

### Features

+ [ ] Input:
  + [ ] parse input file/string:
    + [x] create linearized DOM (nested and repeated tags supported)
    + [ ] lazy inquire tag into DOM;
+ [x] Output:
    + [x] write tag (*atomically*) on file/string;
+ [x] Input/Output:
    + [x] create tag structure:
      + [x] start tag with name and attributes;
      + [x] self closing tag;
      + [x] nested tag;
      + [x] tag content;
      + [x] end tag;
      + [x] tag DOM hierarchy (tag ID, parent ID, children IDs, level);
      + [x] tag indent;
    + [x] add tag to DOM;
    + [x] delete tag from DOM;

### Doing

+ lazy inquire tag into DOM.

### Todo

+ profile the parser:
  + almost surely there are performance penalties;

Go to [Top](#top)

## Documentation

Besides this README file the FoXy documentation is contained into its own [wiki](https://github.com/Fortran-FOSS-Programmers/FoXy/wiki). Detailed documentation of the API is contained into the [GitHub Pages](http://Fortran-FOSS-Programmers.github.io/FoXy/index.html) that can also be created locally by means of [ford tool](https://github.com/cmacmackin/ford).

Go to [Top](#top)

## Copyrights

FoXy is an open source project, it is distributed under a multi-licensing system:

+ for FOSS projects:
  - [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html);
+ for closed source/commercial projects:
  - [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause);
  - [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause);
  - [MIT](http://opensource.org/licenses/MIT).

Anyone is interest to use, to develop or to contribute to FoXy is welcome, feel free to select the license that best matches your soul!

Go to [Top](#top)
