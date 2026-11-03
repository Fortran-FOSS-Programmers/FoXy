# 6. Large outputs: the index

To post-process its results, `solver` does not parse `results.xml` into a DOM: it indexes it. An `xml_index` holds the
tags and their attributes, but no content: the memory it needs does not depend on the data in the file.

<<< @/examples/snippets/solver_6.f90

- `scan` reads the file in chunks and records every tag: name, attributes, hierarchy and byte positions.
- The queries are the ones of `xml_file`: `find`, `find_all`, `children`, `attribute`, `get_attribute`, ...
- `content(id)` and `get_content(id, ...)` read the content of one tag from the file, when you need it.
- `content_range` gives the bytes between the start and the end tag of a tag (its children included), `text_range` only
  its direct text, up to its first child: read them yourself, e.g. a binary block.
- `scan(stop_at=)` stops after the first start tag with that name: what follows (e.g. the raw appended data of a VTK
  file) is not parsed, and nothing is read beyond the current chunk (64 KiB by default). `stop_position()` is the
  first byte after that start tag.
- The index reads the file bytes (its positions are file positions): a UTF-16 or UTF-32 file is refused; parse those
  with `xml_file` or a handler, which convert them.

## Running it

<<< @/examples/output/solver_6.ansi{ansi}

::: tip What you learned
Index large files with `xml_index` and read only the contents you need. Reference: [The index](/guide/index-files).
:::

Next: [7. Your own handler](./07-handler).
