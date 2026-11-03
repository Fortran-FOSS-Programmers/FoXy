---
title: Upgrading
---

# Upgrading

What changes for a program written for an older FoXy. The calls of 0.5 still compile in 0.7: every change below is in
what a call returns or writes, not in its interface. One exception: `foxy` exports new names in 0.7 (`xml_handler`,
`xml_attribute`, `to_value`, `to_values`, `regex`, `regex_match`), so a program that does `use foxy` without `only:`
and declares one of these names itself must rename it, or use `only:`. Most of them make FoXy report, as `XML_MALFORMED`, input it used
to accept silently; the document is still built (parsing stays tolerant), so a program that ignores `iostat` sees no
difference.

The full list of changes is in the [Changelog](./changelog).

## From 0.7 to 0.8

### Behaviour changes

| What | 0.7 | 0.8 |
|---|---|---|
| `xml_writer`: a second root element | written | `XML_MALFORMED` (a document has one root element) |
| `xml_writer%close` with no root element written | `iostat=0`, an empty document | `XML_MALFORMED` |
| `xml_writer%pi` with a target that is not an XML name, or `xml` | written | `XML_MALFORMED` (write the declaration with `declaration`) |
| `xml_tag%attributes()` of a tag without attributes, `stringify(only_content=.true.)` of a tag without content | unallocated | `''` |
| `xml_tag%write` with a `form` other than `FORMATTED`/`UNFORMATTED` | nothing written, `iostat` undefined | nothing written, `XML_BAD_VALUE` |
| `xml_tag%write` without `iostat`: an error (a bad `form`, a failed write) | ignored | the program stops with the message, as Fortran I/O statements do |

`children(id)` of a tag reads its children list: a loop over the tags asking for their children is no longer quadratic.

## From 0.6 to 0.7

### Behaviour changes

| What | 0.6 | 0.7 |
|---|---|---|
| A source with ill-formed UTF-8 | `iostat=0` | `XML_MALFORMED`, `line N: invalid UTF-8 byte 0xNN` |
| A malformed reference (`R&D`, `&nbsp;`, `&#0;`) in text or an attribute | `iostat=0` | `XML_MALFORMED` |
| A name with characters outside the XML 1.0 ranges | accepted (ASCII rules) | reported by `parse`, refused by the writer and by `set_attribute` |
| `xml_escape(s)` | `&`, `<`, `"` (and the `>` of `]]>`) | `& < > " '` |
| Attribute values written by the writer and `set_attribute` | tab, LF, CR as they are | `&#9;` `&#10;` `&#13;`, so they read back unchanged |
| A real attribute written by `xml_writer%attribute` without `fmt=` | the full exponent form (`1.000000000000000E-001`) | the shortest text that reads back to the same value (`0.1`) |
| A value that does not fit its `fmt=` field (`100` under `(I2)`) | written as `**` | `XML_BAD_VALUE`, nothing written |
| A UTF-16, UTF-32, ISO-8859-1 or windows-1252 source | read as UTF-8: `XML_MALFORMED` and garbled text | converted to UTF-8 |
| UTF-8 bytes in a source that declares `encoding="ISO-8859-1"` | read as UTF-8 | read as ISO-8859-1, as XML 1.0 requires (the declaration wins) |
| A declared encoding that FoXy does not read (`Shift_JIS`, ...) | read as UTF-8, silently | `XML_MALFORMED`, `line 1: encoding "Shift_JIS" not supported` |
| `save` of a converted source | — | writes UTF-8 and declares `encoding="UTF-8"` |
| `xml_index%scan` of a UTF-16 or UTF-32 file | garbage tags | refused with `XML_MALFORMED` (the index reads file bytes); use `xml_file` or `xml_handler` |
| `xml_writer%declaration(encoding=)` other than UTF-8 | written | refused with `XML_MALFORMED` (the writer writes UTF-8) |

Byte-for-byte outputs: a program that writes real attributes without `fmt=`, or attribute values holding tabs or new lines, writes
different bytes in 0.7. The values read back the same. Pass `fmt=` to keep a fixed layout.

### New

- [Streaming parser](./events): `xml_handler`, your callbacks for start and end tags, text, comments, PIs and
  problems; the file is read in chunks and nothing is stored.
- [Path selector](./querying#path-selector): `select('//event[@type="x"]/origin[1]')`.
- [Regular expressions](./regex): `matching(re, ...)`, the StringiFor engine (`regex`, `regex_match` are exported by
  `foxy`).
- Typed writes: `set_content`/`set_attribute` with `value=`/`values=`, and `xml_writer%text`/`attribute` with numbers,
  logicals and lists.
- DOM: `add_tag(before=|after=)` inserts at a place, `set_name` renames.
- [Encodings](./parsing#encodings): UTF-16, UTF-32, ISO-8859-1, windows-1252 and US-ASCII sources.

### Requirements

StringiFor **1.12.0** or later (`to_utf8`, the encodings). FoBiS and fpm fetch the default branch: run
`fobis fetch --update`.

## From 0.5 to 0.6

### Behaviour changes

| What | 0.5 | 0.6 |
|---|---|---|
| A source with more than one root element | `iostat=0` | `XML_MALFORMED`; `save(iostat=)` of such a document too |
| Invalid names, duplicate attributes, non blank text outside the root | `iostat=0` | `XML_MALFORMED` |
| CR LF and lone CR in contents | kept | read as LF by the accessors (XML 1.0 2.11); the stored text is unchanged |
| The writer: an invalid name, a duplicate attribute | written | refused with `XML_MALFORMED` |
| `xml_writer%close` without `iostat` after an error never returned | the error was dropped | the program stops with the message |

### New

- [DOM editing](./editing) by tag ID: `set_content`, `set_attribute`, `delete_attribute`, `delete_tag(id=)`.
- `find` stops at the first match; paths and `parent=` walk the children lists (lookups much faster on large
  documents).

### Requirements

nvfortran builds need `-D_NVF` (the fobos nvidia modes define it).
