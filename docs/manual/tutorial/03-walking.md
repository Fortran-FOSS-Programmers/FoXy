# 3. Walking the tree

Before running, `solver` prints the whole case: every tag, its attributes and its text, indented by depth, and then its
boundaries. Nothing here knows the names in advance.

<<< @/examples/snippets/solver_3.f90

- `tags_number()` is the number of tags: the IDs go from `1` to `tags_number()`.
- `children(id)` returns the IDs of the direct children of a tag (`children(0)`: the root tags); `name(id)` its name.
- `attributes_number(id)` and `attribute_name(id, a)` list the attributes of a tag, in source order.
- `find_all` returns every match, in document order: here the four `boundary` tags under `case`.
- `matching` keeps the tags whose name, content or attribute matches a regular expression: here the boundaries whose
  `type` is a wall or an outflow. The regex (`type(regex)`, StringiFor's engine) is compiled once.

## Running it

<<< @/examples/output/solver_3.ansi{ansi}

The text of `notes` shows two more things that `content` does for you: `&amp;` is decoded, and the `<![CDATA[...]]>`
section is taken literally (its `<` is text, not a tag).

::: tip What you learned
`children` and `name` walk the tree, `attributes_number` and `attribute_name` list attributes, `find_all` collects
repeated tags. Reference: [Querying](/guide/querying).
:::

Next: [4. Editing and saving](./04-editing).
