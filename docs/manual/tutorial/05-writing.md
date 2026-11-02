# 5. Writing the results

The results of a solver can be large: `solver` does not build them in memory, it streams them with an `xml_writer`,
element by element.

<<< @/examples/snippets/solver_5.f90

- `open(filename=)` creates the file (`open(unit=)` writes to a unit you opened, `open()` to memory, read back with
  `string()`).
- `start(name)` opens an element; its start tag stays open for `attribute` calls until its first content. Attributes
  take characters (escaped), integers, reals (with an optional `fmt`) and logicals.
- `text` writes escaped character data, `raw` writes characters as they are (numbers, base64) and can be called many
  times for one element; `comment`, `cdata` and `pi` write the other markup.
- `end(name)` closes the innermost element (the name is checked), `close` closes all of them and the file.
- Errors are sticky: the first one is kept, the following calls do nothing, `close` returns it. A misuse (an invalid
  name, a duplicate attribute, `end` with nothing open) is `XML_MALFORMED`; without `iostat`, `close` stops the program
  on it, so no error is lost.

## Running it

<<< @/examples/output/solver_5.ansi{ansi}

<<< @/examples/output/solver_5_cat.ansi{ansi}

::: tip What you learned
`xml_writer` streams a document of any size, with layout, escaping and well-formedness checks. Reference:
[Writing](/guide/writing).
:::

Next: [6. Large outputs: the index](./06-index).
