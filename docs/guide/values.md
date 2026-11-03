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

Each token is converted by StringiFor (`string%read_number`): correctly rounded, with exact range checks and without
a `read` statement, so the results are the same with every compiler.

- **Integers** are digits with an optional sign, as XML integers: `1e3`, `1.0` and `0x1F` are `XML_BAD_VALUE`. A value
  out of the range of the kind is `XML_BAD_VALUE`, for every kind.
- **Reals** are decimal numbers with an optional exponent (`e`, `E`, `d`, `D`), `Inf`, `Infinity` and `NaN` (any case,
  with an optional sign; `NaN(...)` too). A real too large reads as an infinity, one too small as zero (or a subnormal).
- Separators such as `,` or `/`, quotes, repeat counts (`2*5`) and Fortran's exponent without a letter (`1+3`) are
  rejected, never interpreted.

Next: [Editing](./editing).
