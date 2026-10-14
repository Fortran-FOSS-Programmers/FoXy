# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

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



