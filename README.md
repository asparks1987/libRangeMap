# libRangeMap

First-party, dependency-free range mapping for AI-ready data.

`libRangeMap` is a tiny SDK for turning supported values into normalized floating-point numbers. The Alpha v1 focus is intentionally small: finite integer range mapping with a default output range of `[-1.0, 1.0]`.

## Why This Exists

AI and dataset tooling often needs deterministic normalization that is easy to audit, reproduce, and port between languages. `libRangeMap` provides the mapping contract and a Python reference implementation without runtime dependencies, telemetry, network calls, or third-party source.

## Alpha v1 Scope

Alpha v1 supports:

- finite integer input ranges
- default output range `[-1.0, 1.0]`
- explicit custom output ranges such as `[0.0, 1.0]`
- strict out-of-range errors
- explicit clipping mode
- JSON-compatible mapper specs
- save and reload
- standard-library tests

Deferred until beta:

- floats
- characters and strings
- bytes and buffers
- sequences and nested structures
- raw pixel/image-like mappers
- custom object adapters
- additional language implementations

## Install

```bash
python -m pip install .
```

## Quickstart

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100))

print(mapper.map_value(0))    # -1.0
print(mapper.map_value(50))   #  0.0
print(mapper.map_value(100))  #  1.0
```

The canonical formula is:

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

The default output range is:

```text
out_min = -1.0
out_max =  1.0
```

## Strict Mode

Strict mode is the default. Values outside the input range raise `OutOfRangeError`.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
mapper.map_value(101)  # raises OutOfRangeError
```

## Clipping Mode

Enable clipping explicitly to clamp out-of-range values to the nearest bound.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)

print(mapper.map_value(-50))  # -1.0
print(mapper.map_value(150))  #  1.0
```

## Custom Output Range

`[-1.0, 1.0]` is the default. `[0.0, 1.0]` is available only when explicitly configured.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), output_range=(0.0, 1.0))

print(mapper.map_value(50))  # 0.5
```

## Save And Reload

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 255), clip=True)
mapper.save("pixel_range.json")

loaded = IntegerRangeMapper.load("pixel_range.json")

assert loaded.map_value(0) == -1.0
assert loaded.map_value(255) == 1.0
```

Example mapper spec:

```json
{
  "spec_version": "1.0-alpha",
  "implementation_version": "0.1.0-alpha",
  "mapper_type": "integer_range",
  "input_range": [0, 255],
  "output_range": [-1.0, 1.0],
  "clip": true
}
```

## Run Tests

```bash
python -m unittest discover
```

The tests use only the Python standard library.

## Project Rules

- Core SDK code is 100% first-party.
- No runtime dependencies are allowed.
- Do not copy, vendor, paste, or adapt third-party source.
- Unknown or unsupported values must fail clearly.
- Mapping specs should be inspectable and reproducible.
- Generated artifacts such as `dist/`, `build/`, and `*.egg-info/` are not source.

## Compatibility Notes

The original experiment exposed a flat `libRangeMap.py` module with `RangeMapper` and character mapping. The canonical Alpha v1 import is:

```python
from librangemap import IntegerRangeMapper
```

The historical `[0.0, 1.0]` default is now legacy behavior. Alpha v1 defaults to `[-1.0, 1.0]`.

Character mapping is deferred because the old unknown-character fallback produced a magic value. Future character/text support will use explicit policies.

## More Docs

- [Specification](docs/spec.md)
- [Quickstart](docs/quickstart.md)
- [Alpha scope](docs/alpha_scope.md)
- [Beta roadmap](docs/beta_roadmap.md)
- [Compatibility notes](docs/compatibility.md)
- [No dependencies](docs/no_dependencies.md)
- [Alpha release notes](docs/release_notes_v0.1.0-alpha.md)
- [Integer alpha compliance fixture](compliance/integer_alpha.json)
