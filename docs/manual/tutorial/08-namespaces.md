# 8. Namespaces

A coupled run mixes two solvers in one file, each vocabulary in its namespace,
[`coupled.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/coupled.xml):

<<< @/examples/files/coupled.xml

<<< @/examples/snippets/solver_8.f90

- Names are stored as written (`th:dt`); `prefix`, `local_name` and `namespace` split and resolve them, on demand: the
  namespace is the one declared by the nearest `xmlns:prefix` (or `xmlns`, for an unprefixed name) up the tree.
- In `find` and `find_all`, `{uri}local` (Clark notation) matches a local name in a namespace, whatever the prefix the
  file uses.
- With `namespaces=`, declared as in XML, every name of the query uses your prefixes: the file may use others.
- Without either, names match literally: `dt` is only the unprefixed `dt`.

## Running it

<<< @/examples/output/solver_8.ansi{ansi}

::: tip What you learned
Match names by namespace with `{uri}local` or a `namespaces=` map; `namespace(id)` tells where a tag belongs.
Reference: [Namespaces](/guide/namespaces).
:::

Next: [9. Robust input and text](./09-robust).
