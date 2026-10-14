---
title: Features
---

# Features

## Input (Parsing)

- [x] Parse XML from a **string** or a **file**
- [x] Build a linearised DOM with full hierarchy tracking
  - [x] Nested tags supported
  - [x] Repeated tags with the same name supported
- [x] Single-pass, quotes-aware tokenizer, linear in the document size
  - [x] Any blank (space, tab, new line) inside tags, single or double quoted attribute values
  - [x] `<`, `>` and the other quote kind allowed inside attribute values
  - [x] Comments, processing instructions and DOCTYPE skipped, the text around them kept
  - [x] CDATA sections read literally
  - [x] Mixed content: text before, between and after child tags
- [x] Character references decoded on read (`&lt;` `&gt;` `&amp;` `&quot;` `&apos;`, `&#N;`, `&#xH;`)
- [x] DOM queries by name, `/`-separated path or parent, tags and attributes read by ID

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
- [x] Parser performance profiling (`benchmarks/`, `fobis build --mode benchmark-gnu`)
- [ ] Keep comments, processing instructions and DOCTYPE when writing
- [ ] Report malformed input to the caller

## XML Syntax Supported

FoXy handles standard XML element syntax. Tags are case-sensitive and attributes are optional:

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
- Comments, processing instructions and DOCTYPE are skipped: `stringify()` does not write them back
- Entities defined by a DTD (e.g. `&nbsp;`) are not expanded, only the predefined and numeric references
- Malformed input is tolerated, not reported: an end tag closes up to its matching start tag, a stray one is ignored
- Attribute values are not whitespace-normalized
:::
