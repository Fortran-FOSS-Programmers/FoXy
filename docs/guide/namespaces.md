---
title: Namespaces
---

# Namespaces

Names are stored as written; their namespaces (Namespaces in XML 1.0) are resolved on demand, nothing is stored and
parsing is unchanged. The namespace of a tag is declared by the nearest `xmlns:prefix` attribute (`xmlns` for an
unprefixed name) on the tag or on its ancestors.

<<< @/examples/snippets/solver_8-resolve.f90

| Method | Returns |
|---|---|
| `prefix(id)` | the name prefix, `''` if none |
| `local_name(id)` | the name without prefix |
| `namespace(id)` | the namespace URI, `''` for no namespace or an undeclared prefix |

The `xml` prefix is bound to `http://www.w3.org/XML/1998/namespace`; `xmlns=""` undeclares the default namespace.
Since a prefix cannot be declared empty, `prefix(id)/=''` with `namespace(id)==''` means an undeclared prefix (not
reported by `parse`).

## Queries

<<< @/examples/snippets/solver_8-queries.f90

| Name in `find`/`find_all` (and each `path` segment) | Matches |
|---|---|
| `p:local`, `local` | tags with this exact name (prefix included), whatever their namespace |
| `{uri}local` | tags with local name `local` in namespace `uri`, whatever their prefix; `{}local`: in no namespace |
| `p:local` with `namespaces=` | tags with local name `local` in the namespace that `namespaces` declares for `p` (the file's prefixes do not matter); an undeclared prefix matches nothing |
| `local` with `namespaces=` | tags with local name `local` in the default namespace of `namespaces` (`xmlns="uri"`), in no namespace if it has none |

A `/` inside braces is not a path separator, so `{uri}` may hold a URL. Attribute names are always matched literally.

Next: [Single tags](./tags).
