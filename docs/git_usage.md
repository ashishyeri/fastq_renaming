# Git usage

## Commit message format

Use a **prefix** followed by a colon and a space, then the summary. Use **lower case** for the whole message.

### Prefixes

| Prefix    | Use for                    |
|----------|----------------------------|
| `fix`    | Bug fixes                  |
| `feat`   | New features               |
| `perf`   | Performance improvements   |
| `docs`   | Documentation changes      |
| `style`  | Formatting (no logic change) |
| `refactor` | Code refactoring         |
| `test`   | Adding or updating tests   |
| `chore`  | Chore tasks (deps, config, tooling) |

Pick the **most relevant** prefix from the list above for each commit.

### Summary line

- One short line after the prefix (e.g. `feat: add illumina sample name convention`).
- If the change is not obvious, add a **list of changes** after the summary, as a body.

### Examples

```
fix: resolve merge step failing on single-file input
- handle single fastq in MERGE_FASTQ without zcat
- add non-zero size check for merged output
```

```
feat: add generic sample naming convention
- add getSampleIdGeneric in lib/sample_name.nf
- support params.sample_naming_convention = "generic"
```

```
docs: add git usage and commit message rules
- add docs/git_usage.md with prefixes and examples
- link from README
```

```
chore: add pytest to pyproject.toml
```

```
test: add sample name extraction tests
- add tests/test_sample_names.py for illumina, generic, first_token
```

When in doubt, use the prefix that best matches the **main** type of change in the commit; if several apply, pick the one that best describes the impact (e.g. a fix that also refactors → `fix`).
