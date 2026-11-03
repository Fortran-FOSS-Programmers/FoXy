---
title: Methods summary
---

# Methods summary

Every type-bound procedure, with its arguments. The `foxy` module exports the five types, the PENF kinds, the error
codes, the escaping and conversion functions, and StringiFor's regular expressions:

```fortran
use foxy, only: xml_file, xml_index, xml_handler, xml_attribute, xml_writer, xml_tag
use foxy, only: I1P, I2P, I4P, I8P, R4P, R8P                 ! PENF kinds
use foxy, only: XML_MALFORMED, XML_NOT_FOUND, XML_BAD_VALUE  ! iostat values
use foxy, only: xml_escape, xml_unescape, to_value, to_values
use foxy, only: regex, regex_match                           ! StringiFor
```

## `xml_tag` — single XML element

Defined in `src/lib/foxy_xml_tag.F90`.

### Constructor

```fortran
! a tag with text content
tag = xml_tag(name, [content=], [attribute=], [attributes=], [attributes_stream=], [sanitize_attributes_value=], &
              [is_self_closing=], [indent=], [is_content_indented=], [id=], [level=], [parent_id=], [pos=])
! a nested tag as content (no is_self_closing)
tag = xml_tag(name, content=inner_tag, [attribute=], [attributes=], [attributes_stream=], &
              [sanitize_attributes_value=], [indent=], [is_content_indented=], [id=], [level=], [parent_id=], [pos=])
```

### Key methods

| Method | Description |
|--------|-------------|
| `tag%set(...)` | Set any tag field after construction; `attribute_name=`/`attribute_value=` add one attribute with the value stored exactly (no padding as with the `attribute=` pair) |
| `tag%parse(source, [tstart=], [tend=])` | Parse the first tag of `source` with the document tokenizer: name, attributes (single or double quoted, `<`, `>`, `=` allowed in values), content raw up to the matching end tag (to the source end if unclosed); `tstart`/`tend` (`integer(I8P)`) its first and last character, `0` if there is no tag; `pos` is set |
| `tag%name()` | Return tag name as `character(:)` |
| `tag%stringify([is_indented], [is_content_indented], [only_start], [only_content], [only_end], [linearize])` | Serialise to string: `is_indented` puts the tag's own `indent` spaces before its start and end tags, `is_content_indented` puts the content on its own line, two more spaces in |
| `tag%start_tag([is_indented])` | Return `<name...>` |
| `tag%end_tag([is_indented])` | Return `</name>` |
| `tag%self_closing_tag([is_indented])` | Return `<name.../>` |
| `tag%attributes()` | Return all attributes as `att1="v1" att2="v2"` string, `''` if the tag has none |
| `tag%add_attributes(attribute=[name,val], [sanitize_value=])` | Add or update one attribute |
| `tag%add_attributes(attributes=matrix, [sanitize_values=])` | Add or update multiple attributes (note the plural `sanitize_values`) |
| `tag%add_attributes(attributes_stream=string, [sanitize_values=])` | Add or update the attributes of a stream as in a start tag, e.g. `x="1" y='a > b'` (values stored as written) |
| `tag%delete_attributes(name)` | Delete one attribute |
| `tag%delete_attributes(name=array)` | Delete multiple attributes |
| `tag%delete_content()` | Clear text content |
| `tag%is_attribute_present(name)` | Logical: attribute exists? |
| `tag%is_parsed()` | Logical: tag name is allocated? |
| `tag%get_content(name, content)` | Retrieve the content (raw) of self or of the first nested tag `name` in its content string (tags in CDATA, comments and PIs ignored); unallocated if none |
| `tag%get_attributes_number()` / `tag%get_attribute_name(a)` | Return the number of attributes / the name of the `a`-th one (source order, `''` if none) |
| `tag%get_attribute(name)` | Return the value of attribute `name` (literal tabs, new lines and CRs as spaces, character references decoded), `''` if not defined |
| `tag%get_level()` / `tag%get_indent()` / `tag%get_pos()` | Return the level (1 for a root tag), the indentation and the source positions (start `<`, start tag `>`, end tag `<`: `-1` if self-closing, `0` if unclosed) |
| `tag%get_id()` / `tag%get_parent_id()` | Return the tag ID / its parent ID (`0` for a root tag) |
| `tag%get_tail()` | Return the text after the end tag (mixed content), `''` if none |
| `tag%write(unit, [form], [is_indented], [is_content_indented], [only_start], [only_content], [only_end], [end_record], [iostat], [iomsg])` | Write to file unit; `form` is `'UNFORMATTED'` (default: a stream unit) or `'FORMATTED'`, in any case (another one writes nothing, `iostat=XML_BAD_VALUE`) |
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
| `xfile%parse([string=], [filename=], [iostat=], [iomsg=], [sanitize_attributes_value=], [chunk_size=])` | Parse XML from string or file (read in chunks of `chunk_size` characters, default 1 MiB, never loaded whole); clears previous data. `iostat`: `0`, the runtime I/O error code, or `XML_MALFORMED` (first problem in `iomsg`, as `line N: ...`); the document is built anyway. Attribute values are trimmed of leading/trailing spaces unless `sanitize_attributes_value=.false.`. UTF-16, UTF-32, ISO-8859-1, windows-1252 and US-ASCII sources are converted to UTF-8 (byte order mark, then the declared `encoding`); another declared encoding is a problem. See [encodings](./parsing#encodings) |
| `xfile%stringify([linearize])` | Serialise full DOM to string, prolog first |
| `xfile%save(filename, [is_declared=], [iostat=], [iomsg=])` | Write prolog plus `stringify()` and a final new line to a file; `is_declared=.true.` adds `<?xml version="1.0"?>` if the prolog has none; without `iostat` an I/O error stops the program; a document with more root tags is written and returns `XML_MALFORMED` |
| `xfile%content(name)` | Return the direct text of the first tag named `name` (text plus children tails), without leading/trailing blanks, references decoded, CDATA literal |
| `xfile%content(id=)` | Return the direct text of the tag with ID `id`, as `content(name)` |
| `xfile%find([name=], [path=], [parent=], [namespaces=])` | Return the ID of the first matching tag, `0` if none |
| `xfile%find_all([name=], [path=], [parent=], [namespaces=])` | Return the IDs of all matching tags, in document order. Names match literally, except `{uri}local` (Clark notation: local name in namespace `uri`, any prefix) and, with `namespaces=` (declarations as in XML, `'xmlns="uri1" xmlns:p="uri2"'`), every name, its prefix resolved by them. See [namespaces](#namespaces) |
| `xfile%select(expression, [namespaces=], [iostat=], [iomsg=])` | Return the IDs (document order) selected by a path expression, an XPath subset: `/` children, `//` descendants, `*`, `[@k]`, `[@k="v"]`, `[@k~="re"]`, `[n]` (among siblings); a leading `/` anchors to the roots. Malformed: no IDs, `iostat=XML_MALFORMED`, `iomsg` with the column. Not pure. See [querying](./querying#path-selector) |
| `xfile%matching(re, [ids=], [on=], [attribute=], [whole=])` | Return the IDs (of `ids`, or all) whose name (`on='name'`, default), content (`on='content'`) or attribute value (`attribute=`) matches the compiled StringiFor `regex` `re`, a part or the whole (`whole=.true.`); also `idx%matching` (names, attributes) |
| `xfile%children(id)` | Return the IDs of the direct children of tag `id` (`0`: root tags) |
| `xfile%tags_number()` | Return the number of tags: IDs are `1` to `tags_number()` |
| `xfile%attributes_number(id)` / `xfile%attribute_name(id, a)` | Return the number of attributes of tag `id` (`0` if it does not exist) / the name of the `a`-th one, in source order (`''` if none): list the attributes without knowing their names |
| `xfile%attribute(id, name)` | Return the value of attribute `name` of tag `id`, as `get_attribute`, `''` if not defined |
| `xfile%get_attribute(id, name, value, [iostat=], [iomsg=])` | Get attribute `name` of tag `id` as a number or a logical: `value` integer (`I1P`…`I8P`), real (`R4P`, `R8P`) or logical (`true`/`false`/`1`/`0`), unchanged on error; or `values=`, an allocatable rank-1 integer or real array, the blank-separated list (`"0 10 0 10 0 0"`), empty on error. See [typed values](#typed-values) |
| `xfile%get_content(id, value, [iostat=], [iomsg=])` | Get the content of tag `id` (as `content(id=)`) as a number, a logical or (`values=`) a list, as `get_attribute` |
| `xfile%name(id)` / `xfile%parent(id)` / `xfile%level(id)` | Return the name (`''`), parent ID and level (1 for a root tag) of tag `id` (`0` if it does not exist) |
| `xfile%prefix(id)` / `xfile%local_name(id)` / `xfile%namespace(id)` | Return the name prefix (`''` if none), the local name and the namespace of tag `id` (`''` if it does not exist). See [namespaces](#namespaces) |
| `xfile%add_tag(tag, [parent=], [id=], [before=], [after=])` | Append a tag as a root tag or as the last child of tag `parent` (one level deeper, indented 2 more spaces), or insert it right before / after (and its subtree) the sibling `before` / `after`, the following IDs renumbered; `id` returns its ID (`0` if not added: an ID that is not a tag, a sibling that is not a child of `parent`, both `before` and `after`) |
| `xfile%set_name(id, name, [iostat=], [iomsg=])` | Rename tag `id`; `XML_NOT_FOUND`, `XML_MALFORMED` (not an XML name) |
| `xfile%set_attribute(id, name, value \| values, [fmt=], [iostat=], [iomsg=])` | Add (last) or replace attribute `name` of tag `id`: text, a number (`I1P`…`I8P`, `R4P`, `R8P`), a logical or a rank-1 list (as `set_content`); a text `value` is escaped, `attribute()` returns it as passed. `iostat`: `XML_NOT_FOUND` (no tag `id`), `XML_MALFORMED` (`name` not an XML name) |
| `xfile%delete_attribute(id, name, [iostat=], [iomsg=])` | Delete attribute `name` of tag `id`; `XML_NOT_FOUND` if the tag or the attribute does not exist |
| `xfile%set_content(id, value \| values, [fmt=], [iostat=], [iomsg=])` | Set the content of tag `id` to a number, a logical or a list (separated by a space), replacing its children; reals are written with the shortest text that reads back exactly (`0.1`), unless `fmt` formats them; `XML_BAD_VALUE` if `fmt` cannot write the value |
| `xfile%set_content(id, content, [iostat=], [iomsg=])` | Replace the whole content of tag `id`: its children (with their subtrees) are deleted, `content` is stored as it is (it may hold markup: escape user data with `xml_escape`), a self-closing tag gets an end tag; the following IDs are renumbered; `XML_NOT_FOUND` if no tag `id` |
| `xfile%delete_tag([name=], [id=])` | Remove the first tag named `name`, or the tag with ID `id`, with its whole subtree; the following IDs are renumbered |
| `xfile%free()` | Deallocate all data |

`XML_MALFORMED` (`9001`) is a public constant of `foxy_xml_file`, re-exported by `foxy`.

### Namespaces

Namespaces (Namespaces in XML 1.0) are resolved on demand, nothing is stored and parsing is unchanged: the namespace
of a tag is the value of the nearest declaration of its prefix, `xmlns:prefix` (`xmlns` for an unprefixed name), on
the tag or on its ancestors. The `xml` prefix is bound to `http://www.w3.org/XML/1998/namespace`; `xmlns=""` undeclares
the default namespace. `namespace(id)` is `''` for a tag in no namespace and for a prefix not declared: since a prefix
cannot be declared empty, a tag with `prefix(id)/=''` and `namespace(id)==''` has its prefix not declared. Undeclared
prefixes are not reported by `parse`.

| Name in `find`/`find_all` (and each `path` segment) | Matches |
|----------|---------|
| `p:local`, `local` | Tags with this exact name (prefix included), whatever their namespace |
| `{uri}local` | Tags with local name `local` in namespace `uri`, whatever their prefix; `{}local`: in no namespace |
| `p:local` with `namespaces=` | Tags with local name `local` in the namespace that `namespaces` declares for `p` (the document prefixes do not matter); a prefix not declared matches nothing |
| `local` with `namespaces=` | Tags with local name `local` in the default namespace of `namespaces` (`xmlns="uri"`), in no namespace if it has none |

A `/` inside braces is not a path separator, so `{uri}` may hold a URL. Attribute names are always matched literally.

### Typed values

`get_attribute` and `get_content` (of `xml_file` and `xml_index`) convert a text holding blank-separated (space, tab,
new line) tokens. The `iostat` values, public constants of `foxy_xml_values` re-exported by `foxy`, are:

| `iostat` | Meaning |
|----------|---------|
| `0` | Converted |
| `XML_NOT_FOUND` (`9002`) | The tag (`id` out of range) or the attribute does not exist |
| `XML_BAD_VALUE` (`9003`) | Not a value of the requested type: a character not allowed in a token, a token not converted (e.g. out of range for the integer kind), or not exactly one token for a scalar; `iomsg` quotes the token and names the attribute or tag |
| other | `xml_index%get_content` only: the runtime I/O error reading the file |

Each token is converted by StringiFor (`string%read_number`), the same way with every compiler: integers are digits with
an optional sign (out of range for the kind: `XML_BAD_VALUE`), reals are decimal numbers with an optional exponent,
`Inf`, `Infinity` or `NaN`. See [Typed values](./values) for the rules. Without `iostat`, errors are silent: the scalar
keeps its value (a default), the list is empty.

---

## `xml_index` — index of a file, content on demand

Defined in `src/lib/foxy_xml_index.f90`. Holds the tags of a file (name, attributes, hierarchy, positions in the file)
without their content, which is read from the file on demand: the memory used does not depend on the data held in the
file. Positions are 1-based byte offsets (`integer(I8P)`).

| Method | Description |
|--------|-------------|
| `idx%scan(filename, [stop_at=], [chunk_size=], [iostat=], [iomsg=], [sanitize_attributes_value=])` | Index a file, read in chunks (default 64 KiB); with `stop_at` the scan stops after the start tag of the first tag with that name (e.g. `AppendedData`, before raw binary data); errors as `xfile%parse` |
| `idx%find(...)`, `idx%find_all(...)`, `idx%select(...)`, `idx%matching(...)` (names, attributes), `idx%children(id)`, `idx%attribute(id, name)`, `idx%tags_number()`, `idx%attributes_number(id)`, `idx%attribute_name(id, a)`, `idx%name(id)`, `idx%parent(id)`, `idx%level(id)`, `idx%prefix(id)`, `idx%local_name(id)`, `idx%namespace(id)` | The `xml_file` queries, same arguments and results |
| `idx%get_attribute(...)`, `idx%get_content(...)` | The `xml_file` [typed values](#typed-values); `get_content` reads the content from the file |
| `idx%content(id, [iostat=], [iomsg=])` | Read the content of tag `id` from the file, as `xfile%content(id=)`; `''` for a self-closing or unclosed tag |
| `idx%text_range(id, first, last)` | Byte range of the text of tag `id` (up to its first child); `last < first` if empty |
| `idx%content_range(id, first, last)` | Byte range of the whole content of tag `id` (children included) |
| `idx%stop_position()` | Byte position after the `stop_at` start tag, `0` if the scan did not stop |
| `idx%free()` | Deallocate all data |

---

## `xml_handler` — streaming parser

Defined in `src/lib/foxy_xml_events.f90`. Extend it and override the callbacks you need (each one does nothing by
default); see [Streaming parser](./events).

| Method | Description |
|---|---|
| `h%start_element(name, attributes)` | Callback: a start tag; `attributes(:)` of `type(xml_attribute)` (`name`, `value`: normalized, decoded) |
| `h%end_element(name)` | Callback: an end tag (also after a self-closing start tag) |
| `h%characters(text)` | Callback: character data, decoded, maybe in pieces (never splitting a reference or a character) |
| `h%cdata(text)`, `h%comment(text)`, `h%doctype(text)` | Callbacks: CDATA content (literal), comment content, DOCTYPE as in the source |
| `h%processing_instruction(target, data)` | Callback: a PI |
| `h%problem(message)` | Callback: a problem, `line N: ...` |
| `h%parse([string=], [filename=], [chunk_size=], [sanitize_attributes_value=], [iostat=], [iomsg=])` | Parse, calling the callbacks in source order; errors as `xfile%parse` |
| `h%stop_parsing()` | No more callbacks: `parse` returns |
| `h%level`, `h%pos` | During a callback: depth of the current element, byte position of the event |
| `to_value(text, value, iostat, iomsg)`, `to_values(text, values, iostat, iomsg)` | The typed conversion (as `get_content`), for handlers: `iomsg` is `character(len=:), allocatable` |

---

## `xml_writer` — streaming writer

Defined in `src/lib/foxy_xml_writer.f90`. Writes a document sequentially, with bounded memory, to a file, a unit or
memory. Every subroutine takes optional `iostat`/`iomsg` (`string()` is a function, without them): errors are sticky
(the first one is kept, the following calls do nothing) and `close` always reports them; without `iostat`, `close`
stops the program on an error never returned through an `iostat`. A misuse is `XML_MALFORMED`. Names, attributes and
text are always well-formed: element and attribute names must be XML names, a duplicate attribute is a misuse, `]]>` in
text and attribute values is written `]]&gt;`. The document is checked as a whole: a second root element is a misuse,
`close` fails if no root element was written, a PI target must be an XML name other than `xml`.

| Method | Description |
|--------|-------------|
| `w%open([filename=], [unit=], [indent=], [iostat=], [iomsg=])` | Open on a file (created/replaced, closed by `close`), on a unit open for stream unformatted access (left open), or on memory if neither is passed; `indent` spaces per level (default 2, `0` for compact output) |
| `w%declaration([version=], [encoding=])` | Write `<?xml version="1.0"?>`; only as the first thing; `encoding` must name UTF-8 (the writer writes UTF-8) |
| `w%start(name)` | Open an element; its start tag stays pending for attributes until its first content |
| `w%attribute(name, value \| values, [fmt=])` | Add an attribute: `value` character (escaped, tab, new line and CR as references), integer (`I1P`…`I8P`), real (`R4P`, `R8P`), logical (`true`/`false`) or a rank-1 list of numbers; reals are written with the shortest text that reads back exactly unless `fmt` formats them |
| `w%text(value \| values, [fmt=])` | A number, a logical or a rank-1 list of numbers (separated by a space), as `attribute` |
| `w%text(string)` | Escaped character data; the element is written inline |
| `w%raw(string, [is_block=])` | Characters as they are (data, base64); in pieces with many calls; `is_block=.true.` on its own indented line |
| `w%cdata(string)`, `w%comment(string)`, `w%pi(target, [string])` | CDATA section (`]]>` split), comment (no `--`), processing instruction |
| `w%end([name])` | Close the innermost element (self-closing if empty); `name` is checked against it |
| `w%flush()` | Complete the pending start tag (a new line follows) to write directly to the unit, e.g. binary data; the end tag then goes on its own line |
| `w%close([iostat=], [iomsg=])` | Close all the open elements and the writer; without `iostat`, an error not yet reported stops the program |
| `w%string()` | Content of the memory target |

---

## Character references

Defined in `src/lib/foxy_xml_entities.f90`, re-exported by `foxy`.

| Function | Description |
|----------|-------------|
| `xml_unescape(string)` | Decode `&lt;` `&gt;` `&amp;` `&quot;` `&apos;`, `&#N;` and `&#xH;` (as UTF-8); unknown or invalid references are left verbatim |
| `xml_escape(string, [attribute=])` | Replace `&`, `<`, `>`, `"` and `'` with their references, for use as content or attribute value; `attribute=.true.` also tab, new line and CR (the value reads back exactly) |

Stored tags keep the source text: `stringify()` reproduces references as parsed, while `content()`, `attribute()` and
`get_attribute()` return decoded values. Content set programmatically may contain markup (e.g. a nested tag), so it is
**not** escaped on output: escape user data with `xml_escape` before setting it.

---

For full argument lists and call graphs see the [detailed API pages](/api/).
