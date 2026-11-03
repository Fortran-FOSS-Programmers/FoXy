---
title: Writing
---

# Writing

`xml_writer` writes a document sequentially, element by element, to a file, a unit or memory: it keeps only the stack
of the open elements, so a document may be any size.

<<< @/examples/snippets/solver_5-writer.f90

| Method | Does |
|---|---|
| `open([filename=], [unit=], [indent=])` | a file (created or replaced, closed by `close`), a unit open for stream unformatted access (left open), or memory if neither; `indent` spaces per level (default 2, `0`: no layout) |
| `declaration([version=], [encoding=])` | `<?xml version="1.0"?>`, only as the first thing; `encoding` must name UTF-8 (the writer writes UTF-8) |
| `start(name)` | opens an element; its start tag stays pending for attributes until its first content |
| `attribute(name, value \| values, [fmt=])` | character (escaped, tab, new line and CR as references, so it reads back exactly), integer (`I1P`…`I8P`), real (`R4P`, `R8P`), logical (`true`/`false`) value, or a rank-1 list of numbers (separated by a space); reals are written with the shortest text that reads back exactly (`0.1`), unless `fmt` formats them |
| `text(string)` | escaped character data; the element is written inline (`<a>text</a>`) |
| `text(value \| values, [fmt=])` | a number, a logical or a rank-1 list of numbers, as `attribute` |
| `raw(string, [is_block=])` | characters as they are (numbers, base64), in pieces with many calls; `is_block=.true.` on their own indented line |
| `cdata(string)`, `comment(string)`, `pi(target, [string])` | the other markup (`]]>` split across CDATA sections; a comment cannot hold `--` nor end with `-`; a PI target is an XML name other than `xml`, its string cannot hold `?>`) |
| `end([name])` | closes the innermost element (self-closing if empty); `name` is checked |
| `flush()` | completes the pending start tag, to write to the unit yourself (e.g. binary data) |
| `close()` | closes the open elements and the writer |
| `string()` | the content of a memory target |

Every subroutine takes optional `iostat` and `iomsg` (`string()` is a function, without them).

## Errors

Errors are sticky: the first one (an I/O error, or a misuse as `XML_MALFORMED`) is kept, every following call does
nothing, and `close` returns it. Called without `iostat`, `close` stops the program on an error never returned through
an `iostat`, so no error is lost.

<<< @/examples/snippets/writer_errors.f90

<<< @/examples/output/writer_errors.ansi{ansi}

Names, attributes and text are always written well-formed: names must be XML names, a duplicate attribute is a misuse,
`&`, `<`, `>`, `"` and `'` are escaped in text and attribute values (so `]]>` cannot appear), and tab, new line and
carriage return are written as references in attribute values, so that they read back exactly. The document is checked
as a whole too: a second root element is a misuse, `close` fails if no root element was written, and a PI target must
be an XML name other than `xml` (the declaration is written by `declaration`).

## Binary data

<<< @/examples/snippets/binary_appended.f90

VTK files can append raw binary data after an `<AppendedData encoding="raw">` start tag. `flush()` completes the
pending start tag, then you write the bytes to the unit yourself; what follows is no longer XML text, so read such a
file back with the [index](./index-files#stopping-before-raw-data) stopped before the data.

## Writing a single tag

An `xml_tag` writes itself: `stringify()` returns the whole tag, `start_tag()`, `end_tag()` and `self_closing_tag()`
its parts, and `write(unit, ...)` writes it to a unit (with `only_start=`, `only_content=`, `only_end=` to write a large
element in parts; `form='UNFORMATTED'` by default, so the unit must be open for stream access, or pass
`form='formatted'`). An `xml_tag` escapes nothing: its content and attribute values are written as stored. See
[Single tags](./tags).

Next: [The index](./index-files).
