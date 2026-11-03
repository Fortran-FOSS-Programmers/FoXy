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
- `path`: `/`-separated names; the first one matches at any depth (with `parent`: among its children), each next one is
  a direct child of the previous; every candidate is explored, so repeated parents are fine (`case/boundary` gives the
  four boundaries). If both `name` and `path` are passed, `path` is used.
- `namespaces`: see [Namespaces](./namespaces).

`find` stops at the first match of a name; the following path segments and `parent=` walk the children lists, so
`find(name=, parent=)` in a loop costs the number of children, not of tags. `children(id)` reads the children list of
the tag (its cost is the number of children); `children(0)`, the root tags, sweeps all the tags.

## Path selector

<<< @/examples/snippets/select_path.f90

<<< @/examples/output/select_path.ansi{ansi}

| Method | Returns |
|---|---|
| `select(expression, [namespaces=], [iostat=], [iomsg=])` | the IDs of the tags selected by `expression`, in document order |

`expression` is a small subset of XPath:

| Syntax | Selects |
|---|---|
| `a/b` | the `b` children of the `a` tags |
| `a//b` | the `b` descendants of the `a` tags, at any depth |
| `/a` | the root tags named `a` |
| `a` or `//a` | the `a` tags at any depth (as `find_all(path=)`) |
| `*` | any name |
| `name`, `{uri}local` | names matched as in `find_all` (with `namespaces=` for prefixes) |
| `[@k]` | the tags having the attribute `k` |
| `[@k="v"]` (or `'v'`) | the tags whose attribute `k` is `v` (decoded, as `attribute` returns it) |
| `[@k~="re"]` | the tags whose attribute `k` matches the [regular expression](./regex) `re`, anywhere |
| `[n]` | the `n`-th (from 1) among its siblings, counting the tags kept by the previous predicates |

- Predicates follow the step they filter, in order: `boundary[@type="wall"][1]` is the first wall of each parent,
  `boundary[1][@type="wall"]` the first boundary, if it is a wall. As in XPath, `//b[1]` is the first `b` child of each
  parent, not the first `b` of the document.
- Spaces are allowed around the predicate tokens, not inside names. A quoted value cannot hold its own quote.
- A malformed expression (or regular expression) selects nothing and returns `iostat=XML_MALFORMED`, `iomsg` saying
  what is wrong and at which column; without `iostat`, nothing is reported.
- `select` is not pure (it compiles the regular expressions); `find` and `find_all` are the pure lookups. Each step
  sweeps the tags once at most, so a selection costs O(steps × tags). `xml_index` selects the same way.

## The tree

<<< @/examples/snippets/solver_3-outline.f90

| Method | Returns |
|---|---|
| `tags_number()` | the number of tags |
| `children(id)` | the IDs of the direct children (`children(0)`: the root tags) |
| `parent(id)` | the parent ID, `0` for a root tag |
| `level(id)` | the depth, `1` for a root tag, `0` if the tag does not exist |
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
