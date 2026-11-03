# 6. Large outputs: the index

To post-process its results, `solver` does not parse `results.xml` into a DOM: it indexes it. An `xml_index` holds the
tags and their attributes, but no content: the memory it needs does not depend on the data in the file.

<<< @/examples/snippets/solver_6.f90

- `scan` reads the file in chunks and records every tag: name, attributes, hierarchy and byte positions.
- The queries are the ones of `xml_file`: `find`, `find_all`, `children`, `attribute`, `get_attribute`, ...
- `content(id)` and `get_content(id, ...)` read the content of one tag from the file, when you need it.
- `text_range` and `content_range` give the byte range of a content, to read it yourself (e.g. a binary block).
- `scan(stop_at=)` stops after the first start tag with that name: everything after it (e.g. the raw appended data of a
  VTK file) is never read.

## Running it

<<< @/examples/output/solver_6.ansi{ansi}

::: tip What you learned
Index large files with `xml_index` and read only the contents you need. Reference: [The index](/guide/index-files).
:::

Next: [7. Your own handler](./07-handler).
