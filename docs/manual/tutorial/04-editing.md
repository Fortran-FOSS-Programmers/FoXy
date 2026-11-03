# 4. Editing and saving

For a restart, `solver` changes its case: a longer run with a finer time step, no output frequency, no notes, and a new
`restart` section. Then it saves the result.

<<< @/examples/snippets/solver_4.f90

Every edit takes a tag ID. Contents and attributes:

- `set_content(id, value=)` replaces the whole content of a tag (its children included) with a number, a logical or a
  list (`values=`): integers with their digits, reals with the shortest text that reads back exactly (`0.5`, not
  `5.000000000000000E-001`), or as `fmt=` formats them. `set_content(id, content=)` takes text, stored as it is:
  escape text that comes from users with `xml_escape` (see [chapter 9](./09-robust)).
- `set_attribute(id, name, value)` adds or replaces an attribute: text (escaped for you), a number, a logical, or a list
  (`values=`); `delete_attribute(id, name)` removes one.

The structure:

- `xml_tag(name=, content=, attributes_stream=, is_self_closing=)` makes a single tag, not yet in a document; `add_tag`
  puts a copy of it into the document and returns its ID, so the new tag can get children of its own.
- `add_tag(tag, parent=)` appends it as the last child of `parent` (a root tag without `parent`); `add_tag(tag, after=)`
  (or `before=`) inserts it next to a sibling: here `restart` goes right after `time`.
- `delete_tag(name=)` or `delete_tag(id=)` removes a tag with its subtree.
- `set_name(id, name)` renames a tag (the new name must be an XML name).
- IDs change with the structure: a deletion, or an insertion with `before=`/`after=`, renumbers the tags after it, so
  that IDs keep the document order; an append with `parent=` takes the next free ID (the new tag may then come before
  tags with smaller IDs). Find IDs again after a structural edit.

Then `save` writes the document: the prolog kept from the source (declaration and comments), the tags, a final new
line.

## Running it

<<< @/examples/output/solver_4.ansi{ansi}

<<< @/examples/output/solver_4_cat.ansi{ansi}

::: tip What you learned
Edit by ID: contents and attributes (`set_content`, `set_attribute`, `delete_attribute`), the structure (`add_tag`
with `parent=`, `before=` or `after=`, `delete_tag`, `set_name`); find IDs again after a structural edit; then `save`.
Reference: [Editing](/guide/editing).
:::

Next: [5. Writing the results](./05-writing).
