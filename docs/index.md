---
layout: home

hero:
  name: FoXy
  text: Fortran XML for poor people
  image:
    src: /logo.svg
    alt: the FoXy logo, a low-poly arctic fox whose eyes and white blaze read </>
  tagline: "Read, query, edit and write XML from modern Fortran: a DOM for documents, an index for huge files, a streaming parser with your own callbacks, a writer for any size. Pure Fortran 2008, one module: use foxy."
  actions:
    - theme: brand
      text: Tutorial
      link: /manual/tutorial/01-first-document
    - theme: alt
      text: Cookbook
      link: /manual/cookbook
    - theme: alt
      text: Reference
      link: /guide/features
    - theme: alt
      text: API
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/Fortran-FOSS-Programmers/FoXy

features:
  - icon: 📄
    title: Parse strings and files
    details: "One single-pass tokenizer; files read in chunks, over 2 GiB too; UTF-8, UTF-16, UTF-32 and Latin-1 sources. Tolerant: the first problem is reported with its line."
    link: /guide/parsing
    linkText: Parsing
  - icon: 🔎
    title: Find what you need
    details: "Tags by name, path or parent; path expressions as select('//boundary[@type=\"wall\"]'); regular expressions on names, contents and attributes."
    link: /guide/querying
    linkText: Querying
  - icon: 🔢
    title: Numbers, not strings
    details: "Contents and attributes read and written as integers, reals, logicals or lists, with an error status for a missing or bad value."
    link: /guide/values
    linkText: Typed values
  - icon: ✏️
    title: Edit and save
    details: "Build documents in code; change contents, attributes and names by tag ID; insert and delete tags; save with the prolog kept."
    link: /guide/editing
    linkText: Editing
  - icon: 🖋️
    title: Write any size
    details: "xml_writer writes element by element to a file, a unit or memory: layout, escaping, numbers, binary blocks, only well-formed XML."
    link: /guide/writing
    linkText: Writing
  - icon: 🗂️
    title: Huge files, little memory
    details: "xml_index keeps the tags without their content, reads contents on demand, stops before raw data."
    link: /guide/index-files
    linkText: The index
  - icon: 📡
    title: Stream with your callbacks
    details: "xml_handler calls your start, end and text callbacks in source order: nothing stored, any size, stop when you have what you need."
    link: /guide/events
    linkText: Streaming parser
  - icon: 🌐
    title: Namespaces
    details: "Prefix, local name and namespace of every tag; queries by {uri}local or with your own prefixes."
    link: /guide/namespaces
    linkText: Namespaces
  - icon: 🆓
    title: Free and portable
    details: "Pure Fortran 2008, no C; gfortran, ifx, nvfortran; fpm, FoBiS, CMake; GPLv3, BSD or MIT."
    link: /guide/installation
    linkText: Installation
---

## In a nutshell

Read the settings of a case file, [`case.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/case.xml)
(the input of the [tutorial](/manual/tutorial/02-reading)), as numbers:

<<< @/examples/snippets/read_number.f90

<<< @/examples/output/read_number.ansi{ansi}

Start with the [tutorial](/manual/tutorial/01-first-document), or look up a task in the [cookbook](/manual/cookbook).

## See it run

`fx`, a small command line tool built on FoXy, on the files of the tutorial: the outline of a case file, a value read as
a number, a path expression, a regular expression, a malformed file, and a UTF-16 file streamed through a handler.

<div class="fx-casts">
<img src="./examples/images/tour.svg" alt="a terminal session of fx, a tool built on FoXy: the tree of case.xml, case/time/dt read as a real, select of the wall boundaries, contents matching a regular expression, the problem of a malformed file with its line, and the events of a UTF-16 file">
</div>

The whole tool is one program: [`tour.f90`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/src/tour.f90).
