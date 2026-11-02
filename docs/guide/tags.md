---
title: Single tags
---

# Single tags

An `xml_tag` is one element: a name, attributes, a content and its place in a document. It builds the tags you add to
an `xml_file`, and it parses or writes a tag on its own.

<<< @/examples/snippets/single_tag.f90

<<< @/examples/output/single_tag.ansi{ansi}

## Creating

```fortran
tag = xml_tag(name, [content=], [attribute=], [attributes=], [attributes_stream=], [is_self_closing=], [indent=], &
              [is_content_indented=], [sanitize_attributes_value=])
tag = xml_tag(name, content=inner_tag, ...)     ! a nested tag as content
```

Attributes are given as a stream, as in a start tag (`attributes_stream='kind="cg" tol="1e-6"'`), as one name/value pair
(`attribute=[name, value]`) or as a `[2, n]` array of pairs (`attributes=`). The elements of a Fortran character array
have one length: a short value in a pair is padded with blanks (`['unit', 's   ']` stores `"s   "`), so prefer the
stream, or `tag%set(attribute_name=, attribute_value=)`.

## Methods

| Method | Does |
|---|---|
| `parse(source, [tstart=], [tend=])` | parses the first tag of `source` (name, attributes, raw content up to its end tag); `tstart`, `tend` give its first and last character |
| `name()`, `get_attribute(name)`, `is_attribute_present(name)` | the name, an attribute value (normalized and decoded), its presence |
| `get_attributes_number()`, `get_attribute_name(a)` | list the attributes |
| `get_content(name, content)` | the raw content of the tag, or of the first nested tag `name` in it |
| `add_attributes(attribute= \| attributes= \| attributes_stream=)` | adds attributes, replacing the ones with the same name |
| `delete_attributes(name)`, `delete_content()` | removes attributes (one name or an array of names), the content |
| `set(...)` | sets any field; `attribute_name=`, `attribute_value=` add one attribute stored exactly |
| `stringify()`, `start_tag()`, `end_tag()`, `self_closing_tag()` | the tag as text, whole or in parts |
| `write(unit, [only_start=], [only_content=], [only_end=], ...)` | writes it to a unit |
| `free()` | resets it |

The full argument lists are in the [methods summary](./api-reference).

Next: [Methods summary](./api-reference).
