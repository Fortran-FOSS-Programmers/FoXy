---
title: Streaming parser
---

# Streaming parser

The streaming parser reads a document once, from the start to the end, and calls a handler of yours for each event:
an element starts, some text, an element ends, ... Only the chunk being read is kept (with a comment or PI being read,
whole), so a file may be any size, and your handler decides what to keep.

<<< @/examples/snippets/stream_handler.f90

<<< @/examples/output/stream_handler.ansi{ansi}

## The handler

Extend `xml_handler` and override the callbacks you need: each one does nothing by default. The callbacks are ordinary
procedures: they may print, write files and keep any state in your type.

| Callback | Called for |
|---|---|
| `start_element(name, attributes)` | a start tag; `attributes` is an array of `xml_attribute` (`name`, `value`), in source order, values normalized and decoded as `xml_file%attribute` returns them |
| `end_element(name)` | an end tag, and right after the start of a self-closing tag |
| `characters(text)` | character data, decoded (references expanded, line ends as LF); the text between two tags may come in several pieces, never splitting a reference or a UTF-8 character; the blanks between tags (layout) are reported too |
| `cdata(text)` | the content of a CDATA section, literal but for its line ends, as LF (maybe in pieces) |
| `comment(text)` | a comment, without `<!--` and `-->` |
| `processing_instruction(target, data)` | a PI `<?target data?>`, the XML declaration included |
| `doctype(text)` | a `<!DOCTYPE ...>`, as in the source |
| `problem(message)` | a problem of malformed input, as `line N: ...`; parsing goes on |

During a callback, `self%level` is the depth of the current element (1 for the root) and `self%pos` the byte position
of the event in the source.

## Parsing

| Method | Does |
|---|---|
| `parse([string=], [filename=], [chunk_size=], [sanitize_attributes_value=], [iostat=], [iomsg=])` | reads the source in chunks (default 1 MiB) and calls the callbacks in source order; `iostat` is `0`, the I/O error of a file that cannot be read, or `XML_MALFORMED` with the first problem in `iomsg`, as `xml_file%parse` |
| `stop_parsing()` | called from a callback: no more callbacks, the rest of the source is not read, `parse` returns (with the problems met so far) |

Elements are balanced: an element closed implicitly by malformed input, or still open at the end of the source, gets
its `end_element` (unless you call `stop_parsing`: then no more callbacks come). Problems come in source order among the other events; a problem inside character data may come
between two pieces of that text.

::: tip Numbers in pieces
A number may be split between two `characters` calls (`0.3` then `33`): collect the text of an element and convert it in
`end_element`, as the example does, with `to_value` or `to_values` (the conversion of the typed accessors, see
[Typed values](./values)). Their `iostat` and `iomsg` are not optional, and `iomsg` is an allocatable string:
`call to_values(text, values, iostat, iomsg)`.
:::

## When to use it

| Need | Use |
|---|---|
| query, edit and save a document that fits in memory | `xml_file` |
| look up tags of a large file, read a few contents | `xml_index` |
| process every element of a file of any size once (sum, filter, convert) | `xml_handler` |

Names are given as written (prefix included): namespaces are not resolved by the streaming parser.

Next: [Namespaces](./namespaces).
