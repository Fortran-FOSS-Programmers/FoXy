---
title: Features
---

# Features

## Input (Parsing)

- [x] Parse XML from a **string** or a **file**
- [x] Build a linearised DOM with full hierarchy tracking
  - [x] Nested tags supported
  - [x] Repeated tags with the same name supported
- [ ] Lazy DOM queries (in progress)

## Output (Emitting)

- [x] Write a tag **atomically** to a file unit or string
- [x] Formatted (`fmt='(A)'`) and unformatted (stream) output

## Input / Output (Tag construction)

- [x] Create tags programmatically:
  - [x] Start tag with name and attributes: `<tag_name att="val">`
  - [x] Self-closing tag: `<tag_name att="val"/>`
  - [x] Nested tag as content
  - [x] Text content
  - [x] End tag: `</tag_name>`
- [x] DOM hierarchy tracking per tag:
  - [x] Unique tag ID
  - [x] Parent tag ID
  - [x] Children tag IDs
  - [x] Nesting level
- [x] Configurable indentation
- [x] Add / delete attributes by name
- [x] Delete tag content
- [x] Add / delete tags from the DOM

## Roadmap

- [ ] Lazy (on-demand) DOM queries
- [ ] Parser performance profiling

## XML Syntax Supported

FoXy handles standard XML element syntax. Tags are case-sensitive, attributes are optional, and the attribute format is strict:

```xml
<!-- Self-closing tag -->
<Tag att1="val1" att2="val2"/>

<!-- Tag with content -->
<Tag att1="val1" att2="val2">content text</Tag>

<!-- Nested tags -->
<parent>
  <child level="1">text</child>
  <child level="1">
    <grandchild level="2">deep</grandchild>
  </child>
</parent>
```

::: warning Limitations
- Attribute values must not contain `<` or `>`
- XML comments (`<!-- -->`) and processing instructions (`<?...?>`) are skipped during parsing
:::
