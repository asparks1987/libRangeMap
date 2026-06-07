---
title: libRangeMap
---

# libRangeMap

## Deterministic normalization for multi-language AI pipelines

`libRangeMap` is a dependency-free, first-party SDK for mapping integer values into
machine-learning-friendly numeric ranges. The default output is always `[-1.0, 1.0]`.

Use the map below to compare across languages and paste the same line into your code.

---

### 2-Second Copy-Paste

```text
Input: value=50, input_range=[0,100], out_range=[-1.0,1.0]  ->  0.0
```

| # | Language | Exact line to run |
| -: | --- | --- |
| 1 | Python | `from librangemap import IntegerRangeMapper; mapped = IntegerRangeMapper(input_range=(0, 100)).map_value(50)` |
| 2 | C | `double mapped; lrm_map_integer(0, 100, -1.0, 1.0, 0, 50, &mapped);` |
| 3 | Java | `double mapped = new librangemap.IntegerRangeMapper(0, 100).mapValue(50);` |
| 4 | C++ | `double mapped = librangemap::IntegerRangeMapper(0, 100).map_value(50);` |
| 5 | C# | `double mapped = new LibRangeMap.IntegerRangeMapper(0, 100).MapValue(50);` |
| 6 | JavaScript | `const mapped = new IntegerRangeMapper([0, 100]).mapValue(50);` |
| 7 | Visual Basic | `Dim mapped As Double = New IntegerRangeMapper(0, 100).MapValue(50)` |
| 8 | R | `mapped <- map_integer_value(50, 0, 100)` |
| 9 | SQL | `SELECT libRangeMap_map_integer(50, 0, 100, -1.0, 1.0, FALSE);` |
| 10 | Delphi/Object Pascal | `mapped := MapIntegerValue(50, 0, 100, -1, 1, False);` |
| 11 | Fortran | `x = map_integer_value(50, 0, 100, -1.0d0, 1.0d0, .false.)` |
| 12 | Scratch | `mapped := map_integer_value(50, 0, 100, -1, 1, false)` |
| 13 | Perl | `my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);` |
| 14 | PHP | `$mapped = map_integer_value(50, 0, 100);` |
| 15 | Rust | `let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;` |
| 16 | Go | `mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)` |
| 17 | Assembly language | `librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);` |
| 18 | Swift | `let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)` |
| 19 | Ada | `mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);` |
| 20 | MATLAB | `mapped = librangemap(50, 0, 100);` |
| 21 | Classic Visual Basic | `mapped = MapIntegerValue(50, 0, 100, -1, 1, False)` |
| 22 | PL/SQL | `mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);` |
| 23 | Ruby | `mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)` |
| 24 | Prolog | `?- map_integer_value(50, 0, 100, -1.0, 1.0, false, Mapped).` |
| 25 | COBOL | `* use wrappers/cobol/librangemap.cob` |

---

### For Teams: this is what matters

#### Contract guarantee

`mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)`

- Deterministic output for same input and config.
- Explicit clipping rules (strict by default).
- JSON-serializable mapper specs.
- Unknown types and out-of-domain inputs fail clearly.

#### Alpha v1 progress

| Gate | Status |
| --- | --- |
| C core + C ABI | complete |
| Shared integer spec | complete |
| First-party language wrapper set | in-progress |
| 100% alpha readiness | pending |

The language-wrapper gate is the major Alpha v1 blocker today.

---

### Quick integration example

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
mapped = mapper.map_value(50)  # 0.0
```

```python
mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
print(mapper.map_value(150))  # 1.0
```

### Documentation

- [Specification](spec.md)
- [Quickstart](quickstart.md)
- [Architecture](architecture.md)
- [Alpha scope](alpha_scope.md)
- [Beta roadmap](beta_roadmap.md)
- [Compatibility](compatibility.md)
- [No dependencies policy](no_dependencies.md)

The complete repository including 25 language wrapper directories is available in the project source tree.
