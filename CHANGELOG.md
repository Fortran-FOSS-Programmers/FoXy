# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.5.0] — 2026-10-15
### Added
- **dom**: Keep mixed content and read CDATA sections literally ⚠ BREAKING CHANGE

- **parser**: Report malformed input and file errors through iostat/iomsg

- **parser**: Keep the prolog and write it back in stringify

- **dom**: Save the document to a file with xml_file%save

- **parser**: Keep comments and PIs inside the document

- **parser**: Optionally keep leading/trailing spaces of attribute values

- **index**: Scan files and read tag content on demand

- **writer**: Stream XML to a file, a unit or memory

- **writer**: Flush the pending start tag for direct writes to the unit

- **values**: Read attributes and contents as numbers and logicals

- **dom**: Add tags under a parent with add_tag(parent=, id=)

- **tree**: Resolve namespaces and find tags by namespace


### Changed
- **dom**: Share tree queries between DOM and index

- **parser**: Drive the tokenizer through a resumable feed and a builder

- **tokenizer**: Make the tokenizer and the builders pure

- **tag**: Parse single tags and attribute streams with the tokenizer ⚠ BREAKING CHANGE


### Documentation
- **guide**: Document the tokenizer, mixed content, CDATA and references

- **guide**: Document error reporting, the prolog and xml_file%save

- **guide**: Document xml_index, chunked parsing and tag accessors

- **guide**: Document the streaming writer

- **guide**: Document typed values for attributes and contents

- **guide**: Document single-tag parsing and nested add_tag

- **guide**: Document compiler support and the fobis fetch setup

- **guide**: Document namespace resolution and queries


### Fixed
- **parser**: Replace string-search parsing with a single-pass tokenizer

- **parser**: Stop reading past the source end in xml_tag tag search

- **dom**: Normalize literal blanks in attribute values on read

- **parser**: Support sources larger than 2 GiB ⚠ BREAKING CHANGE

- **portability**: Make FoXy work with ifx and nvfortran


### Performance
- **parser**: Parse files in chunks instead of loading them whole


## [0.4.0] — 2026-10-14
### Fixed
- **dom**: Decode character references in content and attribute values ⚠ BREAKING CHANGE


### Performance
- **bench**: Add parse/stringify/lookup benchmark with fobos modes

- **dom**: Make parse, stringify and lookups linear in the tag count


## [0.3.0] — 2026-10-14
### Added
- **dom**: Find tags by name, path or parent and read them by ID


### Fixed
- **docs**: Untrack package-lock and pin esbuild for lock-free vite build

- **docs**: Set vite build target to es2022 for version-robust doc builds

- **ci**: Run install smoke test from the release workflow

- **build**: Exclude third-party docs/ and scripts/ sources from builds

- **parser**: Match nested same-name end tags in source order

- **parser**: Stop self-closing tags inheriting the previous tag content

- **dom**: Keep tag IDs consistent across delete_tag and add_tag


## [0.2.8] — 2026-03-02
### Fixed
- **install**: Run FoBiS.py fetch after wget tarball extraction


## [0.2.6] — 2026-03-02
### Fixed
- **install**: Derive extracted dir from tarball name to avoid broken pipe


## [0.2.5] — 2026-03-02
### Added
- **install**: Add general-purpose install script


## [0.2.2] — 2026-03-02
### Documentation
- Refactor README style and update install instructions


## [0.2.1] — 2026-02-20
### Documentation
- Add VitePress site and overhaul project infrastructure


## [0.2.0] — 2025-06-25
### Fixed
- Fix parse support of nested and repeated tags



