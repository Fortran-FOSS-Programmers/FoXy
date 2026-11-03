---
title: Parsing
---

# Parsing

## Strings and files

<<< @/examples/snippets/solver_2-parse.f90

`parse(string=)` or `parse(filename=)` replaces the content of an `xml_file` with the parsed document.

| Argument | Meaning |
|---|---|
| `string` / `filename` | the source: one of them |
| `iostat`, `iomsg` | `0`; the runtime I/O error of a file that cannot be read; `XML_MALFORMED` with the first problem in `iomsg` (`line N: ...`) |
| `chunk_size` | characters read from a file at a time (`integer(I8P)`, default 1 MiB): the file is never loaded whole |
| `sanitize_attributes_value` | `.true.` (default) trims the spaces around attribute values; `.false.` keeps them, as XML requires |

Without `iostat`, problems are not reported. Positions are 64-bit: sources over 2 GiB are fine.

## Malformed input

Parsing is tolerant: the document is built as far as possible and only the first problem is reported.

<<< @/examples/snippets/check_wellformed.f90

<<< @/examples/output/check_wellformed.ansi{ansi}

| Problem | Example |
|---|---|
| an end tag closing inner open tags, or matching no open tag | `<a><b></a>`, `<a></x></a>` |
| an unclosed tag, an unterminated comment, CDATA, PI or start tag | `<a><b>` |
| a `<` not starting a tag, an unquoted or missing attribute value | `<a>1 < 2</a>`, `<a k=1/>` |
| an invalid tag or attribute name, a duplicate attribute | `<1a/>`, `<a x="1" x="2"/>` |
| text outside the root element (blanks and a UTF-8 byte order mark excepted) | `<a/>junk` |
| more root elements, or none (an empty source included) | `<a/><b/>`, `''` |
| ill-formed UTF-8 (Unicode Table 3-7: an overlong form, a surrogate, a value above U+10FFFF, a truncated sequence, a stray continuation byte), anywhere in the source | `<a>`, byte `0xFF`, `</a>` |

Problems are reported in the order they are met in the source: the first one is the earliest, also for UTF-8, which is
checked once per chunk, a sequence split by two chunks included. An end tag closes up to its matching start tag (inner
open tags are closed); a stray end tag is ignored; an
unterminated comment, CDATA section or PI is kept as text up to the end of the source.

## What is kept

The stored text is the source text, so `stringify` and `save` write back what was read:

- the **prolog** (XML declaration, DOCTYPE, comments and PIs before the root) is kept verbatim and written first;
- **comments and PIs** inside the document stay in the text of the tag that holds them (after the root: in its tail);
- **CDATA sections** are kept as they are;
- **mixed content**: the text before the first child of a tag, and the text after each tag (its tail), is kept.

The accessors return values, not source text: references decoded, CDATA literal, comments and PIs removed, blanks at the
ends removed, and line ends normalized (CR LF and CR read as LF, XML 1.0 2.11). Attribute values also have each literal
tab, new line and CR read as a space (XML 1.0 3.3.3).

<<< @/examples/snippets/mixed_content.f90

<<< @/examples/output/mixed_content.ansi{ansi}

## Character references

<<< @/examples/snippets/solver_8-text.f90

`xml_unescape` decodes `&lt;` `&gt;` `&amp;` `&quot;` `&apos;` and the numeric references `&#N;` and `&#xH;` (as
UTF-8, any number of digits); malformed references (`&nbsp;`, defined by a DTD, a bare `&`, `&#0;`, a surrogate) are
left as they are. `xml_escape(string, [attribute=])` replaces `&`, `<`, `>`, `"` and `'` with references; with
`attribute=.true.` also tab, new line and carriage return (`&#9;`, `&#10;`, `&#13;`), so that an attribute value reads
back exactly: a parser reads them as spaces otherwise. Both are StringiFor's (`string%escape_xml`,
`string%unescape_xml`).

Next: [Querying](./querying).
