---
title: Typed values
---

# Typed values

`get_content` and `get_attribute` (of `xml_file` and `xml_index`) convert text into numbers and logicals.

<<< @/examples/snippets/solver_2-typed.f90

| Call | Converts |
|---|---|
| `get_content(id, value, [iostat=], [iomsg=])` | the content of tag `id` (as `content(id=)`) |
| `get_attribute(id, name, value, [iostat=], [iomsg=])` | attribute `name` of tag `id` |

`value` is an integer (`I1P`, `I2P`, `I4P`, `I8P`), a real (`R4P`, `R8P`) or a logical (`true`, `false`, `1`, `0`).
With `values=` instead, an allocatable rank-1 integer or real array, the text is a blank-separated list
(`"0 10 0 10 0 0"`) and the array gets its size.

## Errors

<<< @/examples/snippets/solver_2-errors.f90

| `iostat` | Meaning |
|---|---|
| `0` | converted |
| `XML_NOT_FOUND` | the tag (`id` out of range, `0` included) or the attribute does not exist |
| `XML_BAD_VALUE` | not a value of that type: a character not allowed, a token not converted (e.g. out of range), not exactly one token for a scalar; `iomsg` quotes the token and names the tag or attribute |
| other | `xml_index%get_content` only: the I/O error reading the file |

On error the scalar keeps its value and the list is empty: a default set before the call survives. Without `iostat`
errors are silent.

The tokens are checked against the characters of the type before conversion (integers: digits and signs; reals: also
`.`, the exponent letters `eEdD`, `NaN`, `Inf`, `Infinity`): separators such as `,` or `/`, quotes and repeat counts
(`2*5`) are rejected, never interpreted by list-directed input. A real out of range reads as an infinity. An integer out
of range for `I1P`–`I4P` is always `XML_BAD_VALUE`; for `I8P` the check is the compiler's (nvfortran misses some).

Next: [Editing](./editing).
