---
title: Contributing
---

# Contributing

This is a FOSS project — anyone interested in using, developing, or contributing
is welcome. The project follows a KISS (Keep It Simple and Stupid) philosophy.

## Reporting Issues

- Open a ticket on the repository **GitHub Issues** page
- Clearly describe the problem, including steps to reproduce for bugs
- Note the earliest version you know has the issue

## Pull Requests

1. Fork the repository on GitHub
2. Create a topic branch from `master`:
   ```bash
   git checkout -b fix/master/my_contribution master
   ```
3. Test your changes: `fobis build --mode tests-gnu && bash scripts/run_tests.sh` (and `bash scripts/docs_examples.sh`
   if you touched the documentation examples: commit the files it regenerates)
4. Check for unnecessary whitespace: `git diff --check`
5. Submit a pull request with a clear commit message

## Fortran Coding Style

- **Clarity over brevity**: `real :: gas_ideal_air` is better than `real :: gia`
- Single-character variable names only for loop counters
- Name all constants
- `implicit none` in every module and program
- Declare `intent` for all procedure arguments, ordered: pass arg → `inout` → `in` → `out` → optional
- Indent as the surrounding code (the sources use 3 spaces), never tabs
- No trailing whitespace; blank lines must contain no spaces
- Use `>, <, ==` instead of `.gt., .lt., .eq.`
- Avoid Windows-style CRLF line endings

### Recommended git whitespace settings

```ini
[color]
  ui = true
[color "diff"]
  whitespace = red reverse
[core]
  whitespace = fix,-indent-with-non-tab,trailing-space,cr-at-eol
```

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) so that `CHANGELOG.md` is generated automatically from the git log:

| Prefix | Purpose | Changelog section |
|--------|---------|-------------------|
| `feat:` | New feature or capability | Added |
| `fix:` | Bug fix | Fixed |
| `perf:` | Performance improvement | Performance |
| `refactor:` | Code restructuring | Changed |
| `docs:` | Documentation only | Documentation |
| `test:`, `build:`, `ci:`, `chore:` | Tests, build system, CI, maintenance | not listed |

Append `!` for breaking changes (`feat!:`, `fix!:`) and explain them in a `BREAKING CHANGE:` footer. Reference issues
with `#123`: they are auto-linked.

```
feat(tree): select tags with a path expression
fix(values): report a field of asterisks as a value that does not fit
feat(parser)!: report malformed references
```

---

## Creating a release

Releases are made by `scripts/release.sh` and GitHub Actions. Install [git-cliff](https://git-cliff.org/) once
(`cargo install git-cliff`, or a binary from its releases), then:

```bash
scripts/release.sh --patch   # v1.2.3 → v1.2.4
scripts/release.sh --minor   # v1.2.3 → v1.3.0
scripts/release.sh --major   # v1.2.3 → v2.0.0
scripts/release.sh v2.1.0    # explicit version
```

`release.sh` checks the branch, the remote, a clean tree and the tag, then:

1. regenerates `CHANGELOG.md` from the git log with git-cliff;
2. updates `VERSION` and the version in `fpm.toml`;
3. commits them as `chore(release): vX.Y.Z` and creates an annotated tag;
4. pushes the commit and the tag.

Pushing the tag triggers the release workflow, which packages the tarball `FoXy-vX.Y.Z.tar.gz` and publishes a GitHub
release with the changelog section as release notes. The tests and the documentation run on every push to `master`
(the CI and Docs workflows), not on the tag. Update the [Upgrading](./upgrading) page before a release that changes
behaviour.
