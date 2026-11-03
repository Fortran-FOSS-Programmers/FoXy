# 2. Reading the case file

The case lives in a file, [`case.xml`](https://github.com/Fortran-FOSS-Programmers/FoXy/blob/master/docs/examples/files/case.xml):

<<< @/examples/files/case.xml

`solver` parses it and reads its settings as numbers, not as text.

<<< @/examples/snippets/solver_2.f90

- `parse(filename=)` reads the file in chunks (1 MiB by default): the file is never loaded whole, so it may be larger
  than the memory left. `iostat` is `0`, the runtime I/O error (the file cannot be read), or `XML_MALFORMED` (see
  [chapter 9](./09-robust)).
- `get_content(id, value)` converts the text of a tag into `value`: any integer kind, `real(R4P)`, `real(R8P)` or
  `logical` (`true`, `false`, `1`, `0`). With `values=`, an allocatable array, it reads a blank-separated list.
- `get_attribute(id, name, value)` does the same for an attribute.
- On error the value is left unchanged, so a default set before the call survives: `iostat` is `XML_NOT_FOUND` for a
  missing tag or attribute (ID `0` included), `XML_BAD_VALUE` for a text that is not a value of that type; `iomsg` says
  which one and where. Without `iostat`, errors are silent.

## Running it

<<< @/examples/output/solver_2.ansi{ansi}

::: tip What you learned
Read files with `parse(filename=)`, numbers and lists with `get_content`/`get_attribute`; a default plus `iostat` makes
a setting optional. Reference: [Typed values](/guide/values).
:::

Next: [3. Walking the tree](./03-walking).
