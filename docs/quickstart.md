# Quickstart

## Install

```bash
python -m pip install .
```

## 2-Second Start

Default range is `[-1.0, 1.0]`; input domain defaults to integers in `[0,100]`.

Use the matching one-liner for your language:

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
| Scratch | `mapped := map_integer_value(50, 0, 100, -1, 1, false)` *(pseudo: mirror `librangemap.md` blocks)* |
| Perl | `my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);` |
| PHP | `$mapped = map_integer_value(50, 0, 100);` |
| Rust | `let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;` |
| Go | `mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)` |
| Assembly language | `librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);` *(pseudo call contract)* |
| Swift | `let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)` |
| Ada | `mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);` |
| MATLAB | `mapped = librangemap(50, 0, 100);` |
| Classic Visual Basic | `mapped = MapIntegerValue(50, 0, 100, -1, 1, False)` |
| PL/SQL | `mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);` |
| Ruby | `mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)` |
| Prolog | `?- map_integer_value(50, 0, 100, -1.0, 1.0, false, Mapped).` |
| COBOL | `* use WRAPPER signature in wrappers\\cobol\\librangemap.cob` |

See `wrappers/<language>/README.md` for exact import / namespace / module load instructions per language.

## Behavior check

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

## Formula

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```
