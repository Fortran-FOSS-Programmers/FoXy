---
title: API Reference Overview
---

# API Reference Overview

FoXy exposes four public types and the PENF kind parameters through the `foxy` wrapper module.

```fortran
use foxy, only: xml_tag, xml_file, xml_index, xml_writer
use foxy, only: I1P, I2P, I4P, I8P, R4P, R8P  ! PENF kinds
use foxy, only: XML_MALFORMED, XML_NOT_FOUND, XML_BAD_VALUE  ! iostat values
```

## Module dependency graph

```mermaid
graph LR
  foxy["foxy"] --> foxy_xml_file["foxy_xml_file"]
  foxy["foxy"] --> foxy_xml_index["foxy_xml_index"]
  foxy["foxy"] --> foxy_xml_writer["foxy_xml_writer"]
  foxy_xml_writer["foxy_xml_writer"] --> foxy_xml_entities["foxy_xml_entities"]
  foxy["foxy"] --> foxy_xml_tag["foxy_xml_tag"]
  foxy["foxy"] --> foxy_xml_entities["foxy_xml_entities"]
  foxy_xml_index["foxy_xml_index"] --> foxy_xml_file["foxy_xml_file"]
  foxy_xml_index["foxy_xml_index"] --> foxy_xml_tokenizer["foxy_xml_tokenizer"]
  foxy_xml_index["foxy_xml_index"] --> foxy_xml_tree["foxy_xml_tree"]
  foxy_xml_file["foxy_xml_file"] --> foxy_xml_tokenizer["foxy_xml_tokenizer"]
  foxy_xml_file["foxy_xml_file"] --> foxy_xml_tree["foxy_xml_tree"]
  foxy_xml_file["foxy_xml_file"] --> foxy_xml_tag["foxy_xml_tag"]
  foxy_xml_file["foxy_xml_file"] --> foxy_xml_entities["foxy_xml_entities"]
  foxy_xml_tree["foxy_xml_tree"] --> foxy_xml_tag["foxy_xml_tag"]
  foxy_xml_tree["foxy_xml_tree"] --> foxy_xml_values["foxy_xml_values"]
  foxy_xml_file["foxy_xml_file"] --> foxy_xml_values["foxy_xml_values"]
  foxy_xml_index["foxy_xml_index"] --> foxy_xml_values["foxy_xml_values"]
  foxy_xml_values["foxy_xml_values"] --> foxy_xml_entities["foxy_xml_entities"]
  foxy_xml_tokenizer["foxy_xml_tokenizer"] --> penf["penf"]
  foxy_xml_tag["foxy_xml_tag"] --> foxy_xml_entities["foxy_xml_entities"]
  foxy_xml_entities["foxy_xml_entities"] --> penf["penf"]
  foxy_xml_tag["foxy_xml_tag"] --> penf["penf"]
  foxy_xml_tag["foxy_xml_tag"] --> stringifor["stringifor"]
```

---

## `xml_tag` — single XML element

Defined in `src/lib/foxy_xml_tag.F90`.

### Constructor

```fortran
! flat tag (scalar content)
tag = xml_tag(name, [content], [attribute], [attributes], [attributes_stream], &
              [indent], [is_content_indented], [is_self_closing], &
              [id], [level], [parent_id])

! nested tag (xml_tag content)
tag = xml_tag(name, content=inner_tag, ...)
```

### Key methods

| Method | Description |
|--------|-------------|
| `tag%set(...)` | Set any tag field after construction; `attribute_name=`/`attribute_value=` add one attribute with the value stored exactly (no padding as with the `attribute=` pair) |
| `tag%parse(source, [tstart=], [tend=])` | Parse the first tag of `source` with the document tokenizer: name, attributes (single or double quoted, `<`, `>`, `=` allowed in values), content raw up to the matching end tag (to the source end if unclosed); `tstart`/`tend` (`integer(I8P)`) its first and last character, `0` if there is no tag; `pos` is set |
| `tag%name()` | Return tag name as `character(:)` |
| `tag%stringify([is_indented], [is_content_indented], [only_start], [only_content], [only_end], [linearize])` | Serialise to string |
| `tag%start_tag([is_indented])` | Return `<name...>` |
| `tag%end_tag([is_indented])` | Return `</name>` |
| `tag%self_closing_tag([is_indented])` | Return `<name.../>` |
| `tag%attributes()` | Return all attributes as `att1="v1" att2="v2"` string |
| `tag%add_attributes(attribute=[name,val])` | Add or update one attribute |
| `tag%add_attributes(attributes=matrix)` | Add or update multiple attributes |
| `tag%add_attributes(attributes_stream=string, [sanitize_values=])` | Add or update the attributes of a stream as in a start tag, e.g. `x="1" y='a > b'` (values stored as written) |
| `tag%delete_attributes(name)` | Delete one attribute |
| `tag%delete_attributes(name=array)` | Delete multiple attributes |
| `tag%delete_content()` | Clear text content |
| `tag%is_attribute_present(name)` | Logical: attribute exists? |
| `tag%is_parsed()` | Logical: tag name is allocated? |
| `tag%get_content(name, content)` | Retrieve the content (raw) of self or of the first nested tag `name` in its content string (tags in CDATA, comments and PIs ignored); unallocated if none |
| `tag%get_attribute(name)` | Return the value of attribute `name` (literal tabs, new lines and CRs as spaces, character references decoded), `''` if not defined |
| `tag%get_level()` / `tag%get_indent()` / `tag%get_pos()` | Return the level (1 for a root tag), the indentation and the source positions (start `<`, start tag `>`, end tag `<`: `-1` if self-closing, `0` if unclosed) |
| `tag%get_id()` / `tag%get_parent_id()` | Return the tag ID / its parent ID (`0` for a root tag) |
| `tag%get_tail()` | Return the text after the end tag (mixed content), `''` if none |
| `tag%write(unit, [form], [is_indented], [is_content_indented], [only_start], [only_content], [only_end], [end_record])` | Write to file unit |
| `tag%free()` | Reset all fields |

### Fields (public)

| Field | Type | Description |
|-------|------|-------------|
| `children_number` | `integer(I4P)` | Count of direct children |
| `child_id(:)` | `integer(I4P), allocatable` | IDs of direct children |

---

## `xml_file` — DOM container

Defined in `src/lib/foxy_xml_file.f90`. Holds a flat `tag(:)` array with hierarchy links.

### Key methods

| Method | Description |
|--------|-------------|
| `xfile%parse([string=], [filename=], [iostat=], [iomsg=], [sanitize_attributes_value=], [chunk_size=])` | Parse XML from string or file (read in chunks of `chunk_size` characters, default 1 MiB, never loaded whole); clears previous data. `iostat`: `0`, the runtime I/O error code, or `XML_MALFORMED` (first problem in `iomsg`, as `line N: ...`); the document is built anyway. Attribute values are trimmed of leading/trailing spaces unless `sanitize_attributes_value=.false.` |
| `xfile%stringify([linearize])` | Serialise full DOM to string, prolog first |
| `xfile%save(filename, [is_declared=], [iostat=], [iomsg=])` | Write prolog plus `stringify()` and a final new line to a file; `is_declared=.true.` adds `<?xml version="1.0"?>` if the prolog has none; without `iostat` an I/O error stops the program |
| `xfile%content(name)` | Return the direct text of the first tag named `name` (text plus children tails), without leading/trailing blanks, references decoded, CDATA literal |
| `xfile%content(id=)` | Return the direct text of the tag with ID `id`, as `content(name)` |
| `xfile%find([name=], [path=], [parent=])` | Return the ID of the first matching tag, `0` if none |
| `xfile%find_all([name=], [path=], [parent=])` | Return the IDs of all matching tags, in document order |
| `xfile%children(id)` | Return the IDs of the direct children of tag `id` (`0`: root tags) |
| `xfile%attribute(id, name)` | Return the value of attribute `name` of tag `id`, as `get_attribute`, `''` if not defined |
| `xfile%get_attribute(id, name, value, [iostat=], [iomsg=])` | Get attribute `name` of tag `id` as a number or a logical: `value` integer (`I1P`…`I8P`), real (`R4P`, `R8P`) or logical (`true`/`false`/`1`/`0`), unchanged on error; or `values=`, an allocatable rank-1 integer or real array, the blank-separated list (`"0 10 0 10 0 0"`), empty on error. See [typed values](#typed-values) |
| `xfile%get_content(id, value, [iostat=], [iomsg=])` | Get the content of tag `id` (as `content(id=)`) as a number, a logical or (`values=`) a list, as `get_attribute` |
| `xfile%name(id)` / `xfile%parent(id)` / `xfile%level(id)` | Return the name (`''`), parent ID and level (1 for a root tag) of tag `id` (`0` if it does not exist) |
| `xfile%add_tag(tag, [parent=], [id=])` | Append a tag as a root tag or as the last child of tag `parent` (one level deeper, indented 2 more spaces); `id` returns its ID (its index; `0` if `parent` is not a tag). Built documents number tags in insertion order |
| `xfile%delete_tag(name)` | Remove first tag named `name` with its whole subtree; remaining IDs are renumbered |
| `xfile%free()` | Deallocate all data |

`XML_MALFORMED` (`9001`) is a public constant of `foxy_xml_file`, re-exported by `foxy`.

### Typed values

`get_attribute` and `get_content` (of `xml_file` and `xml_index`) convert a text holding blank-separated (space, tab,
new line) tokens. The `iostat` values, public constants of `foxy_xml_values` re-exported by `foxy`, are:

| `iostat` | Meaning |
|----------|---------|
| `0` | Converted |
| `XML_NOT_FOUND` (`9002`) | The tag (`id` out of range) or the attribute does not exist |
| `XML_BAD_VALUE` (`9003`) | Not a value of the requested type: a character not allowed in a token, a token not converted (e.g. out of range for the integer kind), or not exactly one token for a scalar; `iomsg` quotes the token and names the attribute or tag |
| other | `xml_index%get_content` only: the runtime I/O error reading the file |

The tokens are checked against the characters of the type (integers: digits and signs; reals: also `.`, exponent
letters `eEdD`, and `NaN`/`Inf`/`Infinity`), then converted by Fortran list-directed input: separators such as `,` or
`/` and repeat counts (`2*5`) are rejected, not interpreted. A real out of range reads as an infinity. An integer out
of range for `I1P`–`I4P` is always `XML_BAD_VALUE`; for `I8P` the check is the compiler runtime's: gfortran and ifx
report every overflow, nvfortran (26.5) misses some (`9223372036854775808` reads as `-9223372036854775808`). Without
`iostat`, errors are silent: the scalar keeps its value (a default), the list is empty.

---

## `xml_index` — index of a file, content on demand

Defined in `src/lib/foxy_xml_index.f90`. Holds the tags of a file (name, attributes, hierarchy, positions in the file)
without their content, which is read from the file on demand: the memory used does not depend on the data held in the
file. Positions are 1-based byte offsets (`integer(I8P)`).

| Method | Description |
|--------|-------------|
| `idx%scan(filename, [stop_at=], [chunk_size=], [iostat=], [iomsg=], [sanitize_attributes_value=])` | Index a file, read in chunks (default 64 KiB); with `stop_at` the scan stops after the start tag of the first tag with that name (e.g. `AppendedData`, before raw binary data); errors as `xfile%parse` |
| `idx%find(...)`, `idx%find_all(...)`, `idx%children(id)`, `idx%attribute(id, name)`, `idx%name(id)`, `idx%parent(id)`, `idx%level(id)` | The `xml_file` queries, same arguments and results |
| `idx%get_attribute(...)`, `idx%get_content(...)` | The `xml_file` [typed values](#typed-values); `get_content` reads the content from the file |
| `idx%content(id, [iostat=], [iomsg=])` | Read the content of tag `id` from the file, as `xfile%content(id=)`; `''` for a self-closing or unclosed tag |
| `idx%text_range(id, first, last)` | Byte range of the text of tag `id` (up to its first child); `last < first` if empty |
| `idx%content_range(id, first, last)` | Byte range of the whole content of tag `id` (children included) |
| `idx%stop_position()` | Byte position after the `stop_at` start tag, `0` if the scan did not stop |
| `idx%free()` | Deallocate all data |

---

## `xml_writer` — streaming writer

Defined in `src/lib/foxy_xml_writer.f90`. Writes a document sequentially, with bounded memory, to a file, a unit or
memory. Every method takes optional `iostat`/`iomsg`: errors are sticky (the first one is kept, the following calls do
nothing) and `close` always reports them; a misuse is `XML_MALFORMED`.

| Method | Description |
|--------|-------------|
| `w%open([filename=], [unit=], [indent=], [iostat=], [iomsg=])` | Open on a file (created/replaced, closed by `close`), on a unit open for stream unformatted access (left open), or on memory if neither is passed; `indent` spaces per level (default 2, `0` for compact output) |
| `w%declaration([version=], [encoding=])` | Write `<?xml version="1.0"?>`; only as the first thing |
| `w%start(name)` | Open an element; its start tag stays pending for attributes until its first content |
| `w%attribute(name, value, [fmt=])` | Add an attribute: `value` character (escaped), integer (`I1P`…`I8P`), real (`R4P`, `R8P`) or logical (`true`/`false`); `fmt` formats numbers |
| `w%text(string)` | Escaped character data; the element is written inline |
| `w%raw(string, [is_block=])` | Characters as they are (data, base64); in pieces with many calls; `is_block=.true.` on its own indented line |
| `w%cdata(string)`, `w%comment(string)`, `w%pi(target, [string])` | CDATA section (`]]>` split), comment (no `--`), processing instruction |
| `w%end([name])` | Close the innermost element (self-closing if empty); `name` is checked against it |
| `w%flush()` | Complete the pending start tag (a new line follows) to write directly to the unit, e.g. binary data; the end tag then goes on its own line |
| `w%close([iostat=], [iomsg=])` | Close all the open elements and the writer |
| `w%string()` | Content of the memory target |

---

## Character references

Defined in `src/lib/foxy_xml_entities.f90`, re-exported by `foxy`.

| Function | Description |
|----------|-------------|
| `xml_unescape(string)` | Decode `&lt;` `&gt;` `&amp;` `&quot;` `&apos;`, `&#N;` and `&#xH;` (as UTF-8); unknown or invalid references are left verbatim |
| `xml_escape(string)` | Replace `&`, `<` and `"` with their references, for use as content or attribute value |

Stored tags keep the source text: `stringify()` reproduces references as parsed, while `content()`, `attribute()` and
`get_attribute()` return decoded values. Content set programmatically may contain markup (e.g. a nested tag), so it is
**not** escaped on output: escape user data with `xml_escape` before setting it.

---

For full argument lists and call graphs see the [detailed API pages](/api/).
