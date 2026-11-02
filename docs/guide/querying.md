---
title: Querying
---

# Querying

A parsed document is a flat array of tags in document order. A tag is known by its **ID**, `1` to `tags_number()`;
`0` stands for "no tag" (and, for `children` and `parent=`, for the document itself, whose children are the root tags).

## Finding tags

<<< @/examples/snippets/solver_1-content.f90

| Method | Returns |
|---|---|
| `find([name=], [path=], [parent=], [namespaces=])` | the ID of the first match, in document order, `0` if none |
| `find_all(...)` | the IDs of all the matches, in document order |

- `name`: the tags with that name, at any depth; with `parent`, only its direct children.
- `path`: `/`-separated names; the first one matches at any depth, each next one is a direct child of the previous;
  every candidate is explored, so repeated parents are fine (`case/boundary` gives the four boundaries).
- `namespaces`: see [Namespaces](./namespaces).

`find` stops at the first match of a name; the following path segments and `parent=` walk the children lists, so
looking up children in a loop costs the number of children, not of tags.

## The tree

<<< @/examples/snippets/solver_3-outline.f90

| Method | Returns |
|---|---|
| `tags_number()` | the number of tags |
| `children(id)` | the IDs of the direct children (`children(0)`: the root tags) |
| `parent(id)` | the parent ID, `0` for a root tag |
| `level(id)` | the depth, `1` for a root tag |
| `name(id)` | the name, `''` if the tag does not exist |

A plain loop over the IDs visits the tree depth first, in document order:

<<< @/examples/snippets/walk_tree.f90

## Text and attributes

| Method | Returns |
|---|---|
| `content(name)` | the text of the first tag named `name` |
| `content(id=)` | the text of tag `id` |
| `attribute(id, name)` | the value of an attribute, `''` if not defined |
| `attributes_number(id)` | the number of attributes |
| `attribute_name(id, a)` | the name of the `a`-th attribute, in source order |

`content` returns the **direct text** of a tag: its text and the tails of its children, the children's own text
excluded; references decoded, CDATA literal, comments and PIs removed, blanks at both ends removed. `content(name)` also
finds a tag set as a content string (e.g. `xml_tag(name='a', content='<b>1</b>')`).

<<< @/examples/snippets/list_attributes.f90

<<< @/examples/output/list_attributes.ansi{ansi}

Next: [Typed values](./values).
