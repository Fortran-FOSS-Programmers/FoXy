---
title: Editing
---

# Editing

## Building a document

<<< @/examples/snippets/build_document.f90

<<< @/examples/output/build_document.ansi{ansi}

`add_tag(tag, [parent=], [id=])` appends an `xml_tag` as the last child of `parent` (one level deeper, indented two
more spaces), or as a root tag without `parent`; `id` returns its ID (`0` if `parent` is not a tag). Tags are appended,
so the IDs of a built document follow the insertion order. With `before=` (or `after=`) the tag is inserted right before
(after) a sibling, after its whole subtree for `after`: it takes that place in the document order and the following
IDs are renumbered. See [Single tags](./tags) for `xml_tag`.

## Editing by ID

<<< @/examples/snippets/solver_4-edit.f90

| Method | Does |
|---|---|
| `set_content(id, content, [iostat=], [iomsg=])` | replaces the whole content of a tag with text: its children (with their subtrees) are deleted; a self-closing tag gets an end tag |
| `set_content(id, value \| values, [fmt=], [iostat=], [iomsg=])` | the same with a number (`I1P`…`I8P`, `R4P`, `R8P`), a logical (`true`/`false`) or a rank-1 list (values separated by a space); reals are written with the shortest text that reads back exactly (StringiFor `shortest`), unless `fmt` formats them |
| `set_attribute(id, name, value \| values, [fmt=], [iostat=], [iomsg=])` | adds the attribute (last) or replaces its value: text, a number, a logical or a list, as `set_content` |
| `delete_attribute(id, name, [iostat=], [iomsg=])` | deletes an attribute |
| `delete_tag([name=], [id=])` | deletes the first tag named `name`, or tag `id`, with its subtree |
| `set_name(id, name, [iostat=], [iomsg=])` | renames a tag; `XML_MALFORMED` if `name` is not an XML name |
| `free()` | empties the document |

`iostat` is `XML_NOT_FOUND` for a tag or attribute that does not exist and `XML_MALFORMED` for an invalid attribute
name; without it, errors are silent. A deletion (`delete_tag`, `set_content` on a tag with children) renumbers the
following tags: look IDs up again after it.

::: warning Escaping
`set_attribute` escapes the value: `attribute()` returns it as you passed it. `set_content` and `xml_tag(content=)`
store the content as it is, since it may hold markup (a nested tag): escape text that is not markup with `xml_escape`.
:::

<<< @/examples/snippets/escape_text.f90

<<< @/examples/output/escape_text.ansi{ansi}

## Saving

<<< @/examples/snippets/solver_4-save.f90

| Method | Does |
|---|---|
| `stringify([linearize=])` | the document as a string: the prolog, then the tags laid out (mixed content kept inline); `linearize=.true.` lists the tags one by one, for debugging |
| `save(filename, [is_declared=], [iostat=], [iomsg=])` | writes the prolog, `stringify()` and a final new line to a file |

With `is_declared=.true.`, `save` writes `<?xml version="1.0"?>` first, unless the prolog already starts with a
declaration. `iostat` is the I/O error, or `XML_MALFORMED` for a document with more root tags (written anyway: XML
allows one root, other readers reject it). Without `iostat`, an I/O error stops the program.

Next: [Writing](./writing).
