# Quickstart

## Install

```bash
python -m pip install .
```

## 2-Second Start

Default range is `[-1.0, 1.0]`; input domain defaults to integers in `[0,100]`.
This is the canonical integer line that every supported language follows.

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
| COBOL | `* use WRAPPER signature in wrappers\\cobol\\librangemap.cob` |

See `wrappers/<language>/README.md` for exact import / namespace / module load instructions per language.

### Beta readiness

For next families beyond integer mapping (floats, booleans, text, bytes, sequences, maps, images), use:

- the required policy in each language wrapper README
- family readiness and execution gates in [Beta Wrapper Contract](beta_wrapper_contract.md)

## Implemented family shortcuts now

### Python

```python
from librangemap import IntegerRangeMapper, FloatRangeMapper, BooleanRangeMapper, TextRangeMapper, SequenceRangeMapper

IntegerRangeMapper(input_range=(0, 100)).map_value(50)
FloatRangeMapper(input_range=(0.0, 1.0)).map_value(0.5)
BooleanRangeMapper().map_value(True)
TextRangeMapper(mode="alphabet", alphabet="abc", allow_empty=True).map_value("cab")

SequenceRangeMapper(IntegerRangeMapper(input_range=(0, 100))).map_value([0, [10, 20], (30, 40)])
```

### C and C++

```c
double mapped_c;
lrm_map_float(0.0, 1.0, -1.0, 1.0, 0, 0.5, &mapped_c);   // C
```

```cpp
double mapped_cpp = librangemap::FloatRangeMapper(0.0, 1.0).map_value(0.5);
librangemap::BooleanRangeMapper bool_mapper;
double mapped_bool_cpp = bool_mapper.map_value(false);
```

### Java

```java
import librangemap.IntegerRangeMapper;
import librangemap.SequenceRangeMapper;
import librangemap.TextRangeMapper;

new IntegerRangeMapper(0, 100).mapValue(50);
new TextRangeMapper().map("A");
new SequenceRangeMapper(new IntegerRangeMapper(0, 100))
    .mapValue(new int[]{0, 25, 50, 75, 100});
```

### JavaScript

```js
const { IntegerRangeMapper, FloatRangeMapper, BooleanRangeMapper, TextRangeMapper, SequenceRangeMapper } = require("../wrappers/javascript");

new IntegerRangeMapper([0, 100]).mapValue(50);
new FloatRangeMapper([0.0, 1.0]).mapValue(0.5);
new BooleanRangeMapper().mapValue(true);
new TextRangeMapper([-1.0, 1.0], "codepoint", { allowEmpty: true }).mapValue("ab");
new SequenceRangeMapper(new IntegerRangeMapper([0, 100])).mapValue([0, [25, 50, [75, 100]]]);
```

### C Sharp

```csharp
var mapper = new LibRangeMap.FloatRangeMapper(0.0, 1.0);
var boolMapper = new LibRangeMap.BooleanRangeMapper();
var mapped = mapper.MapValue(0.5);
var mappedBool = boolMapper.MapValue(true);
```

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

## Language scope and current blocker

Alpha language scope is fixed to the 25 canonical targets (Python, C, Java, C++, C#, JavaScript, Visual Basic, R, SQL, Delphi/Object Pascal, Fortran, Scratch, Perl, PHP, Rust, Go, Assembly language, Swift, Ada, MATLAB, Classic VB, PL/SQL, Ruby, Prolog, COBOL).  

`Wrapper-path coverage (all 25)` is the Alpha parity gate and remains the primary gate for v1 readiness.
The remaining active blocker is **family depth**: sequence, text/bytes, map/object, and image families are in progressive rollout by language, while float/boolean support is still incomplete beyond the currently implemented language set.

## Formula

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```
