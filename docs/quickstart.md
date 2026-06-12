# Quickstart

## Install

```bash
python -m pip install .
```

## 2-Second Start

Default range is `[-1.0, 1.0]`; input defaults for examples use integer domain `[0, 100]`.
Each language path has a matching one-liner.

## 2-Second Client Quickstart

| Language | Exact call |
| --- | --- |
| Python | `from librangemap import IntegerRangeMapper; mapped = IntegerRangeMapper(input_range=(0, 100)).map_value(50)` |
| C | `double mapped; lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);` |
| Java | `double mapped = new librangemap.IntegerRangeMapper(0, 100).mapValue(50);` |
| C++ | `double mapped = librangemap::IntegerRangeMapper(0, 100).map_value(50);` |
| C# | `double mapped = new LibRangeMap.IntegerRangeMapper(0, 100).MapValue(50);` |
| JavaScript | `const mapped = new IntegerRangeMapper([0, 100]).mapValue(50);` |
| Visual Basic | `Dim mapped As Double = New IntegerRangeMapper(0, 100).MapValue(50)` |
| R | `mapped <- map_integer_value(50, 0, 100)` |
| SQL | `SELECT libRangeMap_map_integer(50, 0, 100, -1.0, 1.0, FALSE);` |
| Delphi/Object Pascal | `mapped := MapIntegerValue(50, 0, 100, -1, 1, False);` |
| Fortran | `x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.)` |
| Scratch | `mapped := map_integer_value(50, 0, 100, -1, 1, false)` *(block contract in `wrappers/scratch/librangemap.md`)* |
| Perl | `my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);` |
| PHP | `$mapped = map_integer_value(50, 0, 100);` |
| Rust | `let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;` |
| Go | `mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)` |
| Assembly language | `librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);` *(ABI contract)* |
| Swift | `let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)` |
| Ada | `mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);` |
| MATLAB | `mapped = librangemap(50, 0, 100);` |
| Classic Visual Basic | `mapped = MapIntegerValue(50, 0, 100, -1, 1, False)` |
| PL/SQL | `mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);` |
| Ruby | `mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)` |
| Prolog | `?- map_integer_value(50, 0, 100, -1.0, 1.0, false, Mapped).` |
| COBOL | `MOVE 50 TO WS-VALUE`<br/>`MOVE 0 TO WS-INPUT-MIN`<br/>`MOVE 100 TO WS-INPUT-MAX`<br/>`MOVE -1.0 TO WS-OUTPUT-MIN`<br/>`MOVE 1.0 TO WS-OUTPUT-MAX`<br/>`CALL "LIBRANGEMAP" USING WS-VALUE WS-INPUT-MIN WS-INPUT-MAX WS-OUTPUT-MIN WS-OUTPUT-MAX WS-CLIP RETURNING WS-OUTPUT-SPAN.` |

See `wrappers/<language>/README.md` for exact import / namespace / module loading steps.

### Readability goal

`2-Second Start` means you can paste one line and get a deterministic mapped float.

## Behavior check (strict + clip)

Strict mode is default. To clip out-of-range values:

```python
mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
assert mapper.map_value(150) == 1.0
```

Strict mode failure:

```python
mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
mapper.map_value(101)  # raises OutOfRangeError
```

## Implemented family shortcuts (practical)

```python
from datetime import timedelta

from librangemap import (
    BooleanRangeMapper,
    BytesRangeMapper,
    CategoricalRangeMapper,
    ImageRangeMapper,
    FloatRangeMapper,
    IntegerRangeMapper,
    MapRangeMapper,
    SequenceRangeMapper,
    TextRangeMapper,
    TemporalRangeMapper,
)

IntegerRangeMapper(input_range=(0, 100)).map_value(50)
FloatRangeMapper(input_range=(0.0, 1.0)).map_value(0.5)
BooleanRangeMapper().map_value(True)
TextRangeMapper(mode="alphabet", alphabet="abc", allow_empty=True).map_value("cab")  # alphabet mode requires at least 2 unique symbols
SequenceRangeMapper(IntegerRangeMapper(input_range=(0, 100))).map_value([0, [10, 20], (30, 40)])
BytesRangeMapper(output_range=(0.0, 255.0)).map_value(b"AB")
MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 120), clip=True), "is_member": BooleanRangeMapper()}).map_value(
    {"age": 30, "is_member": True}
)
TemporalRangeMapper(input_range=(0.0, 120.0), mode="duration").map_value(timedelta(seconds=60))
ImageRangeMapper(input_range=(0, 255), mode="raw_bytes").map_value(b"AB")
```

## Compatibility status and next step

The former beta blocker, **family breadth**, is closed in the manifest: all 25 language wrappers now expose the beta families listed in the compatibility matrix. Production readiness still depends on shared conformance fixtures, environment-specific runtime verification, packaging hardening, and explicit extractor/schema contracts for opaque runtime objects.

For non-integer families, follow the family status and required policies in:

- [Beta Wrapper Contract](beta_wrapper_contract.md)
- [Compatibility Matrix](compatibility.md)

## Formula

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```
