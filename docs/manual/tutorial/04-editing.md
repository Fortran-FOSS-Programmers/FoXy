# 4. Editing and saving

For a restart, `solver` changes its case: a longer run with a finer time step, no output frequency, no notes, and a new
`restart` section. Then it saves the result.

<<< @/examples/snippets/solver_4.f90

- Every edit takes a tag ID. `set_content(id, value=)` replaces the whole content of a tag (its children included)
  with a number, a logical or a list (`values=`): integers with their digits, reals with the shortest text that reads
  back exactly (`0.5`, not `5.000000000000000E-001`), or as `fmt=` formats them. `set_content(id, content=)` takes
  text, stored as it is: escape text that comes from users with `xml_escape` (see [chapter 9](./09-robust)).
- `set_attribute(id, name, value)` adds or replaces an attribute (its value escaped for you); `delete_attribute`
  removes one.
- `delete_tag(name=)` or `delete_tag(id=)` removes a tag with its subtree. The following tags are renumbered: find IDs
  again after a deletion.
- `add_tag(tag, parent=, id=)` appends an `xml_tag` as the last child of `parent` (a root tag without `parent`) and
  returns its ID, so the new tag can get children of its own.
- `save` writes the document: the prolog kept from the source (declaration and comments), the tags, a final new line.

## Running it

<<< @/examples/output/solver_4.ansi{ansi}

<<< @/examples/output/solver_4_cat.ansi{ansi}

::: tip What you learned
Edit by ID (`set_content`, `set_attribute`, `delete_attribute`, `delete_tag`, `add_tag`), then `save`. Reference:
[Editing](/guide/editing).
:::

Next: [5. Writing the results](./05-writing).
