---
layout: home

hero:
  name: FoXy
  text: Fortran XML for poor people
  image:
    src: /logo.svg
    alt: the FoXy logo, a low-poly arctic fox whose eyes and white blaze read </>
  tagline: "Read, edit and write XML from modern Fortran: a DOM for documents, an index for huge files, a streaming writer for any size. Pure Fortran 2008, one module."
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
    details: "One single-pass tokenizer, files read in chunks (over 2 GiB too); tolerant parsing, the first problem reported with its line."
    link: /guide/parsing
    linkText: Parsing
  - icon: 🔎
    title: Query by name, path, parent
    details: "Tags by name, path or parent, children, attributes listed or by name; text with references decoded and CDATA literal."
    link: /guide/querying
    linkText: Querying
  - icon: 🔢
    title: Numbers, not strings
    details: "Contents and attributes read as integers, reals, logicals or lists, with an error status for missing or bad values."
    link: /guide/values
    linkText: Typed values
  - icon: ✏️
    title: Edit and save
    details: "Build documents in code, change contents and attributes by ID, delete tags, save with the prolog kept."
    link: /guide/editing
    linkText: Editing
  - icon: 🖋️
    title: Stream any size
    details: "xml_writer writes element by element to a file, a unit or memory: layout, escaping, binary blocks, only well-formed XML."
    link: /guide/writing
    linkText: Writing
  - icon: 🗂️
    title: Huge files, little memory
    details: "xml_index keeps the tags without their content, reads contents on demand, stops before raw data."
    link: /guide/index-files
    linkText: The index
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

<<< @/examples/snippets/read_number.f90

<<< @/examples/output/read_number.ansi{ansi}

Start with the [tutorial](/manual/tutorial/01-first-document), or look up a task in the [cookbook](/manual/cookbook).
