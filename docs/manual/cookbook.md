---
title: Cookbook
---

# Cookbook

Short answers to "how do I ...?". Each recipe is a complete program with its real output; the
[reference](/guide/features#feature-map) has the details. The files they read are in
[`docs/examples/files`](https://github.com/Fortran-FOSS-Programmers/FoXy/tree/master/docs/examples/files) (`case.xml` and
`coupled.xml` of the [tutorial](./index), `broken.xml`, `station-*.xml`), or are written by an earlier program:
`results.xml` by [chapter 5](./tutorial/05-writing) of the tutorial, `appended.xml` by *Write binary data inside a
document*.

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

### Report a bad or missing value

<<< @/examples/snippets/report_bad_value.f90

<<< @/examples/output/report_bad_value.ansi{ansi}

Tokens are checked before conversion: `,`, `/`, quotes and repeat counts (`2*5`) are rejected, not interpreted.

### Keep the spaces around attribute values

<<< @/examples/snippets/keep_attribute_spaces.f90

<<< @/examples/output/keep_attribute_spaces.ansi{ansi}

### Read text with markup around it

<<< @/examples/snippets/mixed_content.f90

<<< @/examples/output/mixed_content.ansi{ansi}

`content` returns the direct text: references decoded, CDATA literal, comments and child tags out.


### Read a UTF-16 or Latin-1 file

<<< @/examples/snippets/read_encodings.f90

<<< @/examples/output/read_encodings.ansi{ansi}

<<< @/examples/output/read_encodings-head.ansi{ansi}

Nothing to do: the encoding is detected (byte order mark, declaration) and the text converted to UTF-8; `save` writes
UTF-8 and declares it. The index reads the file bytes (its positions are file positions), so it refuses a UTF-16 file:
parse it with `xml_file` or a handler. See [Encodings](/guide/parsing#encodings).


## Finding

### Check that a tag exists

<<< @/examples/snippets/check_exists.f90

<<< @/examples/output/check_exists.ansi{ansi}

`find` returns `0` when there is no such tag, `select` an empty array, `attribute` an empty string; the accessors also
take `0` safely (`content(id=0)` is `''`, `get_content(id=0, ...)` returns `XML_NOT_FOUND`).

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

In a parsed document IDs follow the document order, so a plain loop visits the tree depth first; `children` and
recursion give the structure. A tag appended later with `add_tag(parent=)` gets the next free ID: after such edits,
walk with `children`.

### Select tags with a path expression

<<< @/examples/snippets/select_path.f90

<<< @/examples/output/select_path.ansi{ansi}

One call for what would be `find_all` plus loops: steps (`/` children, `//` descendants), `*`, attribute tests
(`[@k]`, `[@k="v"]`, `[@k~="re"]`) and positions among siblings (`[n]`). See [Querying](/guide/querying#path-selector).

### Filter tags with a regular expression

<<< @/examples/snippets/regex_filter.f90

<<< @/examples/output/regex_filter.ansi{ansi}

Compile the pattern once; `matching` takes the IDs of any query (`ids=`) and keeps those whose name, content or
attribute value matches. See [Regular expressions](/guide/regex).

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

### Insert a tag before or after another, rename a tag

<<< @/examples/snippets/insert_tags.f90

<<< @/examples/output/insert_tags.ansi{ansi}

An insertion takes the place of the sibling in the document order: the tags after it are renumbered.

### Change a value and save

<<< @/examples/snippets/edit_and_save.f90

<<< @/examples/output/edit_and_save.ansi{ansi}

### Set numbers, logicals and lists

<<< @/examples/snippets/set_numbers.f90

<<< @/examples/output/set_numbers.ansi{ansi}

`set_attribute` and `set_content` take numbers, logicals and lists as the writer does: integers with their digits,
reals with the shortest text that reads back exactly, unless `fmt=` formats them. See [Editing](/guide/editing).

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

`fmt=` formats a number attribute; without it, integers get their digits (a sign only if negative) and reals the
shortest text that reads back exactly.

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

### Stop a streaming parse early, and see its problems

<<< @/examples/snippets/stream_stop.f90

<<< @/examples/output/stream_stop.ansi{ansi}

`stop_parsing` ends the parse from a callback: no more callbacks, the rest of the file is not read. Override `problem`
to see each problem as it is met; `parse` also returns the first one in `iomsg`.

### Index a file and stop before its binary data

<<< @/examples/snippets/index_stop.f90

<<< @/examples/output/index_stop.ansi{ansi}

`stop_position()` is the first byte after the `>` of the start tag; there the writer's `flush` put a new line, so the
data start one byte later. What follows is not parsed, and the scan reads nothing beyond its current chunk (64 KiB by
default): read the binary data yourself from there.

### Read only the contents you need

<<< @/examples/snippets/index_content.f90

<<< @/examples/output/index_content.ansi{ansi}

`content`, `get_content` and `get_attribute` read from the file on demand; `text_range` and `content_range` give byte ranges.
