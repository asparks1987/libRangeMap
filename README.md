# libRangeMap

First-party, dependency-free range mapping for AI-ready data.

`libRangeMap` is a tiny SDK for turning supported values into normalized floating-point numbers. The current Alpha v1 release focuses on one stable primitive: finite integer range mapping with a default output range of `[-1.0, 1.0]`.

## Current Status

Alpha v1 is ready for local use and validation.

| Area | Current State |
| --- | --- |
| Runtime dependencies | None |
| Python import | `from librangemap import IntegerRangeMapper` |
| Runtime version | `0.1.0-alpha` |
| Package version | `0.1.0a0` |
| Spec version | `1.0-alpha` |
| Default output range | `[-1.0, 1.0]` |
| Supported mapper | Integer range mapper |
| Test command | `python -m unittest discover` |
| C++ status | Legacy/deferred until beta |

The project has been cleaned so generated packaging outputs such as `dist/`, `build/`, and `*.egg-info/` are ignored and not treated as source.

## What Works Today

Alpha v1 supports:

- finite integer input ranges
- deterministic mapping into floating-point output
- default output range `[-1.0, 1.0]`
- explicit custom output ranges such as `[0.0, 1.0]`
- strict out-of-range errors by default
- explicit clipping mode
- clear validation errors for invalid ranges and unsupported values
- boolean rejection in integer mode
- JSON-compatible mapper specs
- save and reload from JSON files
- standard-library `unittest` coverage
- a language-neutral integer compliance fixture

Deferred until beta:

- float mapping
- character and string mapping
- bytes and buffer mapping
- sequence and nested structure mapping
- raw pixel/image-like mapping
- custom object adapters
- maintained C++ support
- additional first-party language implementations

## Install

From a local checkout:

```bash
python -m pip install .
```

The core SDK has no runtime dependencies beyond Python itself.

## Quickstart

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100))

print(mapper.map_value(0))    # -1.0
print(mapper.map_value(50))   #  0.0
print(mapper.map_value(100))  #  1.0
```

## Formula

The canonical formula is:

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

Alpha defaults:

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

Enable clipping explicitly to clamp out-of-range values to the nearest input bound before mapping.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)

print(mapper.map_value(-50))  # -1.0
print(mapper.map_value(150))  #  1.0
```

## Custom Output Range

`[-1.0, 1.0]` is the default. `[0.0, 1.0]` exists only when explicitly configured.

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

## Validation

Run the standard-library test suite:

```bash
python -m unittest discover
```

Validate local installation and import:

```bash
python -m pip install .
python -c "import librangemap; print(librangemap.__version__)"
```

Expected import output:

```text
0.1.0-alpha
```

Run examples:

```bash
python examples/map_integer.py
python examples/map_negative_range.py
python examples/map_with_clipping.py
python examples/map_strict.py
python examples/save_and_load_mapper.py
```

The save/load example writes `pixel_range.json`; that file is demonstration output and should not be committed.

## Project Layout

```text
librangemap/
  __init__.py
  core.py
  errors.py
  integer.py
  serialization.py
  spec.py

tests/
  test_compatibility.py
  test_compliance_fixture.py
  test_dependency_free.py
  test_errors.py
  test_integer.py
  test_serialization.py

docs/
  spec.md
  quickstart.md
  alpha_scope.md
  beta_roadmap.md
  compatibility.md
  no_dependencies.md
  release_notes_v0.1.0-alpha.md

examples/
  map_integer.py
  map_negative_range.py
  map_with_clipping.py
  map_strict.py
  save_and_load_mapper.py

compliance/
  integer_alpha.json

legacy/
  librangemap.h
```

## Compatibility Notes

The original experiment exposed a flat `libRangeMap.py` module with `RangeMapper` and `CharRangeMapper`.

The canonical Alpha v1 import is:

```python
from librangemap import IntegerRangeMapper
```

`RangeMapper` remains as a compatibility wrapper for integer-style ranges. It now follows the Alpha v1 default output range of `[-1.0, 1.0]`.

`CharRangeMapper` is intentionally unsupported in Alpha v1 because the old behavior mapped unknown characters to a magic fallback value. Future character and text support will use explicit policies.

The old C++ header is preserved under `legacy/` for reference only. It is not claimed as an Alpha v1 implementation.

## Project Rules

- Core SDK code is 100% first-party.
- No runtime dependencies are allowed.
- Do not copy, vendor, paste, or adapt third-party source.
- Unknown or unsupported values must fail clearly.
- Mapping specs should be inspectable and reproducible.
- Generated artifacts are not source.

## More Docs

- [Specification](docs/spec.md)
- [Quickstart](docs/quickstart.md)
- [Alpha scope](docs/alpha_scope.md)
- [Beta roadmap](docs/beta_roadmap.md)
- [Compatibility notes](docs/compatibility.md)
- [No dependencies](docs/no_dependencies.md)
- [Alpha release notes](docs/release_notes_v0.1.0-alpha.md)
- [Integer alpha compliance fixture](compliance/integer_alpha.json)
