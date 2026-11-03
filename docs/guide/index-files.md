---
title: The index
---

# The index

An `xml_index` holds the tags of a file (name, attributes, hierarchy, byte positions) but not their content, which is
read from the file when you ask for it: the memory used does not depend on the data held in the file.

<<< @/examples/snippets/solver_6-scan.f90

| Method | Does |
|---|---|
| `scan(filename, [stop_at=], [chunk_size=], [iostat=], [iomsg=], [sanitize_attributes_value=])` | indexes a file read in chunks (default 64 KiB); with `stop_at`, stops after the start tag of the first tag with that name; errors as `xml_file%parse` |
| `find`, `find_all`, `children`, `attribute`, `attributes_number`, `attribute_name`, `tags_number`, `name`, `parent`, `level`, `prefix`, `local_name`, `namespace` | the queries of `xml_file` |
| `content(id, [iostat=], [iomsg=])` | reads the content of a tag from the file, as `xml_file%content(id=)`; `''` for a self-closing or unclosed tag |
| `get_content`, `get_attribute` | the [typed values](./values); `get_content` reads from the file |
| `text_range(id, first, last)` | the byte range of the text of a tag (up to its first child); `last < first` if empty |
| `content_range(id, first, last)` | the byte range of the whole content (children included) |
| `stop_position()` | the byte after the `stop_at` start tag, `0` if the scan did not stop |
| `free()` | empties the index |

::: tip Encodings
The index reads the file bytes (its positions are file positions): a UTF-16 or UTF-32 file is refused with
`XML_MALFORMED`, a single byte encoding (`ISO-8859-1`, ...) is read as UTF-8. Parse such files with `xml_file` or
`xml_handler`, which convert them: see [Encodings](./parsing#encodings).
:::

## Stopping before raw data

<<< @/examples/snippets/index_stop.f90

<<< @/examples/output/index_stop.ansi{ansi}

A VTK file with appended raw data is the typical case: the XML header is indexed, the binary data after
`<AppendedData encoding="raw">` is never read by the scan, and `stop_position()` tells where it starts.

Next: [Streaming parser](./events).
