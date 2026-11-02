# 8. Robust input and text

Case files are written by hand, and hands make mistakes. [`broken.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/broken.xml)
forgets an end tag:

<<< @/examples/files/broken.xml

<<< @/examples/snippets/solver_8.f90

- Parsing is tolerant: the document is built as far as possible, and `iostat=XML_MALFORMED` with `iomsg` reports the
  first problem and its line. Besides the tags structure, FoXy reports invalid names, duplicate attributes, text
  outside the root element, more root elements and an empty source.
- Stored text is the source text: `stringify` writes back what was read. The accessors decode it: references
  (`&amp;`, `&#233;`) become characters, CDATA sections are literal, comments are skipped, line ends are LF.
- `xml_escape` and `xml_unescape` convert text yourself; content set with `set_content` or `xml_tag(content=)` is not
  escaped (it may hold markup), so escape user data first.
- Mixed content (text around child tags) is kept: `content` returns the direct text of a tag, without its children.

## Running it

<<< @/examples/output/solver_8.ansi{ansi}

::: tip What you learned
Check `iostat`/`iomsg` of `parse`; read text through the accessors, escape what you write as content. Reference:
[Parsing](/guide/parsing).
:::

This is the end of the tutorial: the [cookbook](../cookbook) has short recipes for everyday tasks, the
[reference](/guide/features#feature-map) every method.
