---
title: Cookbook
---

# Cookbook

Short answers to "how do I ...?". Each recipe is a complete program with its real output; the
[reference](/guide/features#feature-map) has the details. The files they read are the ones of the
[tutorial](./index): [`case.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/case.xml)
and [`coupled.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/coupled.xml).

[[toc]]

## Reading

### Parse a string

<<< @/examples/snippets/parse_string.f90

<<< @/examples/output/parse_string.ansi{ansi}

`attribute(1, name)`: the root tag of a parsed document is the tag `1`.

### Parse a file, and stop on errors

<<< @/examples/snippets/parse_file.f90

<<< @/examples/output/parse_file.ansi{ansi}

The file is read in chunks, never loaded whole: `parse(..., chunk_size=)` sets their size.

### Check that a document is well-formed

<<< @/examples/snippets/check_wellformed.f90

<<< @/examples/output/check_wellformed.ansi{ansi}

`iostat` is `XML_MALFORMED` and `iomsg` holds the first problem, with its line; the document is built anyway.

### Read a number, an integer or a logical

<<< @/examples/snippets/read_number.f90

<<< @/examples/output/read_number.ansi{ansi}

Logicals are `true`, `false`, `1` or `0`; any integer kind (`I1P`…`I8P`), `R4P` and `R8P` work.

### Read a list of numbers

<<< @/examples/snippets/read_list.f90

<<< @/examples/output/read_list.ansi{ansi}

`values=` is an allocatable rank-1 array, allocated to the number of blank-separated tokens.

### Read an attribute, as text or as a number

<<< @/examples/snippets/read_attribute.f90

<<< @/examples/output/read_attribute.ansi{ansi}

### Use a default when a setting is missing

<<< @/examples/snippets/default_value.f90

<<< @/examples/output/default_value.ansi{ansi}

On error the value is not touched: set the default first, check `iostat` if you need to know.

### Report a value that is not a number

<<< @/examples/snippets/report_bad_value.f90

<<< @/examples/output/report_bad_value.ansi{ansi}

Tokens are checked before conversion: `,`, `/`, quotes and repeat counts (`2*5`) are rejected, not interpreted.

### Keep the spaces around attribute values

<<< @/examples/snippets/keep_attribute_spaces.f90

<<< @/examples/output/keep_attribute_spaces.ansi{ansi}

## Finding

### Loop over repeated tags

<<< @/examples/snippets/loop_repeated.f90

<<< @/examples/output/loop_repeated.ansi{ansi}

`find_all` returns the IDs in document order, `find` only the first one.

### Read the children of a tag

<<< @/examples/snippets/children.f90

<<< @/examples/output/children.ansi{ansi}

### List the attributes of a tag

<<< @/examples/snippets/list_attributes.f90

<<< @/examples/output/list_attributes.ansi{ansi}

### Visit every tag

<<< @/examples/snippets/walk_tree.f90

<<< @/examples/output/walk_tree.ansi{ansi}

IDs follow the document order, so a plain loop visits the tree depth first; `children` and recursion give the structure.

### Read text with markup around it

<<< @/examples/snippets/mixed_content.f90

<<< @/examples/output/mixed_content.ansi{ansi}

`content` returns the direct text: references decoded, CDATA literal, comments and child tags out.

### Match a namespace, whatever the prefix

<<< @/examples/snippets/namespaces_clark.f90

<<< @/examples/output/namespaces_clark.ansi{ansi}

`{uri}local` is the Clark notation: a local name in a namespace.

### Query with your own prefixes

<<< @/examples/snippets/namespaces_map.f90

<<< @/examples/output/namespaces_map.ansi{ansi}

The prefixes of `namespaces=` replace the ones of the file for this query only.

## Editing

### Build a document in code

<<< @/examples/snippets/build_document.f90

<<< @/examples/output/build_document.ansi{ansi}

Attributes go in as a stream (`attributes_stream=`) or as name/value pairs; `parent=` nests, `id=` returns the new ID.

### Change a value and save

<<< @/examples/snippets/edit_and_save.f90

<<< @/examples/output/edit_and_save.ansi{ansi}

### Delete tags

<<< @/examples/snippets/delete_tags.f90

<<< @/examples/output/delete_tags.ansi{ansi}

A deletion renumbers the following tags: look IDs up again after it.

### Save with an XML declaration

<<< @/examples/snippets/save_declaration.f90

<<< @/examples/output/save_declaration.ansi{ansi}

### Store user text safely

<<< @/examples/snippets/escape_text.f90

<<< @/examples/output/escape_text.ansi{ansi}

Contents are stored as given (they may hold markup): escape text that is not markup. `set_attribute` and the writer escape for you.

### Parse, build and edit a single tag

<<< @/examples/snippets/single_tag.f90

<<< @/examples/output/single_tag.ansi{ansi}

## Writing

### Stream a document to a file

<<< @/examples/snippets/writer_file.f90

<<< @/examples/output/writer_file.ansi{ansi}

<<< @/examples/output/writer_file_cat.ansi{ansi}

`fmt=` formats a number attribute; without it, integers have no sign when positive and reals full precision.

### Write numbers, logicals and lists

<<< @/examples/snippets/writer_numbers.f90

<<< @/examples/output/writer_numbers.ansi{ansi}

Without `fmt=`, integers are written with their digits and reals with the shortest text that reads back exactly
(`0.1`, `0.3333333333333333`); lists are separated by one space. The DOM does the same: `set_content(id, value=)`,
`set_attribute(id, name, values=)`.

### Write a document to memory

<<< @/examples/snippets/writer_memory.f90

<<< @/examples/output/writer_memory.ansi{ansi}

`open()` without a file or a unit writes to memory; `indent=0` writes no layout.

### Catch a writer misuse

<<< @/examples/snippets/writer_errors.f90

<<< @/examples/output/writer_errors.ansi{ansi}

The first error is kept and the following calls do nothing; `close(iostat=)` returns it. Without `iostat`, `close` stops the program on an error nobody saw.

### Write binary data inside a document

<<< @/examples/snippets/binary_appended.f90

<<< @/examples/output/binary_appended.ansi{ansi}

`flush` completes the pending start tag so that you can write to the unit yourself; the end tag follows on its own line.

## Large files

### Process a huge file in one pass

<<< @/examples/snippets/stream_handler.f90

<<< @/examples/output/stream_handler.ansi{ansi}

Only the callbacks you override are called; the file is read in chunks, never whole. See
[Streaming parser](/guide/events).

### Index a file and stop before its binary data

<<< @/examples/snippets/index_stop.f90

<<< @/examples/output/index_stop.ansi{ansi}

The bytes after `stop_position()` are never read: read the binary data yourself from there.

### Read only the contents you need

<<< @/examples/snippets/index_content.f90

<<< @/examples/output/index_content.ansi{ansi}

`content`, `get_content` and `get_attribute` read from the file on demand; `text_range` and `content_range` give byte ranges.
