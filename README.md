<a name="top"></a>

# FoXy

[![License](https://img.shields.io/badge/license-GNU%20GeneraL%20Public%20License%20v3,%20GPLv3-blue.svg)]()
[![License](https://img.shields.io/badge/license-BSD2-red.svg)]()
[![License](https://img.shields.io/badge/license-BSD3-red.svg)]()
[![License](https://img.shields.io/badge/license-MIT-red.svg)]()

### FoXy, Fortran XML parser for poor people

A KISS pure Fortran Library for parsing XML files

- FoXy is a pure Fortran (KISS) library for modern Fortran projects;
- FoXy is Fortran 2008+ standard compliant;
- FoXy is OOP designed;
- FoXy is a Free, Open Source Project.

#### Table of Contents

- [What is FoXy?](#what-is-foxy)
- [Aims](#Aims)
- [How to start?](#how-to-start)
- [Copyrights](#copyrights)

## What is FoXy?

Modern Fortran standards (2003+) have introduced support for a more
Modern Fortran standards (2003+) have introduced better support for strings manipulations. Exploiting such new Fortran capabilities, FoXy is aimed to provide an easy to use module library for parsing (and generating) [XML](https://en.wikipedia.org/wiki/XML) files.

## Aims

Other programming languages have many libraries for XML parsing, Fortran has less options, but some there are:

+ [xml-fortran](http://xml-fortran.sourceforge.net/) of Arjen Markus;
+ [xml-f90](http://lcdx00.wm.lc.ehu.es/~wdpgaara/xml/index.html) of Alberto Garcia;
+ [fox](https://github.com/andreww/fox) of Andrew Walker;
+ [tixi](https://github.com/andreww/fox) from DLR Simulation and Software Technology.

All of the above are great codes, but lack in some points that I would like to have:

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

## How to start?

I created this repository for our group, [Fortran F/OSS programmers group](https://github.com/Fortran-FOSS-Programmers) with the hope to collaborate with all of you, but before you stop reading this bad manifest let me to explain some details:

+ The name FoXy is just the first thing coming out... do not hate me only for this :-) we can easily change it;
+ I inserted my dirty, bad, incomplete, XML Fortran sources just to show you where I am: our project must not start with my sources, we are free to start from scratch;
+ the copyrights is cumbersome is know, feel free to change it.

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
