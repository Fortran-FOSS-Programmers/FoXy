---
title: Regular expressions
---

# Regular expressions

FoXy filters tags with regular expressions, by their name, their content or the value of an attribute. The engine is
StringiFor's (`regex`, a Pike VM: linear time, the syntax and the results of Python `re`, without backreferences,
lookaround and octal escapes); `foxy` exports its `regex`
and `regex_match` types, so no other `use` is needed. The syntax is documented in StringiFor:
[Regular Expressions](https://szaghi.github.io/StringiFor/guide/regex).

<<< @/examples/snippets/regex_filter.f90

<<< @/examples/output/regex_filter.ansi{ansi}

## Filtering

| Method | Returns |
|---|---|
| `matching(re, [ids=], [on=], [attribute=], [whole=])` | the IDs of the tags (of `ids`, in their order, or all of them) whose text matches the compiled `re` |

- `on='name'` (the default) matches the name as written (prefix included), `on='content'` the content as
  `content(id=)` returns it (decoded, blanks at both ends removed), `on='attribute'` (or just `attribute=`) the value of
  that attribute, decoded; a tag without the attribute never matches.
- A part of the text matches (`search`), or the whole of it with `whole=.true.` (`fullmatch`).
- `re` is compiled once, with `call re%compile(pattern, iostat=, iomsg=)`; a regex not compiled (or whose pattern did
  not compile) matches nothing. `matching` is pure.
- `xml_index` filters names and attributes the same way (it holds no content: `on='content'` gives no IDs).
- An `on` other than `name`, `content` or `attribute` gives no IDs, and so does `on='attribute'` without `attribute=`.

`matching` takes the IDs of any query, so it chains with `find`/`find_all` (here: the boundaries, then those of a type),
and its result goes to any accessor.

Next: [Single tags](./tags).
