<div align="center">

# libRangeMap

### First-party, dependency-free range mapping for AI-ready data.

`libRangeMap` is an open-source SDK for turning values into normalized floating-point numbers in the range **`[-1.0, 1.0]`**.

It is being designed for AI dataset preparation, feature normalization, training-data collection, embedded tooling, and cross-language data pipelines — without requiring users to install any runtime dependency beyond the language itself.

<br />

![Status](https://img.shields.io/badge/status-pre--alpha-orange)
![Core](https://img.shields.io/badge/core-dependency--free-brightgreen)
![Runtime](https://img.shields.io/badge/runtime-first--party-blue)
![Network](https://img.shields.io/badge/network-none-lightgrey)
![Output](https://img.shields.io/badge/default%20range--1%20to%201-purple)

<br />

**Small core. Deterministic math. No hidden dependencies. No telemetry. No magic.**

</div>

---

## What is libRangeMap?

`libRangeMap` is a range-mapping SDK.

At its core, it answers one simple question:

> Given a value inside a known input range, what is its equivalent value inside another range?

For AI and dataset work, the default target range is:

```text
[-1.0, 1.0]
```

That means values can be normalized into a consistent floating-point representation that is easy to store, compare, feed into training pipelines, or pass between systems.

### Simple example

```text
0 in range [0, 100]    -> -1.0
50 in range [0, 100]   ->  0.0
100 in range [0, 100]  ->  1.0
```

### Why this matters

AI data often arrives in many forms:

- integers,
- floats,
- characters,
- strings,
- bytes,
- sequences,
- nested structures,
- raw pixel values,
- custom objects,
- and eventually language-specific data containers.

`libRangeMap` aims to provide a tiny, auditable, first-party normalization layer that can turn supported inputs into predictable values between `-1.0` and `1.0`.

---

## Current project status

`libRangeMap` is currently **pre-alpha**.

The project is being rebuilt around a stricter vision:

| Area | Current Direction |
|---|---|
| Runtime dependencies | None |
| Source policy | 100% first-party implementation |
| Default output range | `[-1.0, 1.0]` |
| Alpha MVP | Integer range mapping |
| Beta goal | Input-type-agnostic SDK through explicit mapper contracts |
| Language goal | Language-agnostic spec with first-party implementations |
| Network behavior | None |
| Telemetry | None |

The first stable alpha target is intentionally small: **convert any finite integer inside a declared integer range into a float between `-1.0` and `1.0`.**

Once that core is correct, documented, serialized, and tested, the SDK can expand to more input types.

---

## Design principles

### 1. First-party only

The core SDK must be original project code.

No copied source.  
No vendored libraries.  
No pasted utility code from other repos.  
No runtime dependencies.

### 2. Dependency-free core

A user should not need to install NumPy, Pillow, pandas, PyTorch, TensorFlow, OpenCV, requests, pydantic, click, pytest, or any other package to use the core SDK.

The core should work with only the target language/runtime.

### 3. Deterministic output

The same input plus the same mapping spec must always produce the same output.

### 4. Explicit mapping rules

Unknown inputs should not become magic numbers.

Invalid ranges, unsupported types, out-of-range values, NaN, infinity, and unknown tokens should have clear, documented behavior.

### 5. Spec first, language second

The long-term goal is not only a Python package or a C++ header.

The long-term goal is a **language-agnostic mapping specification** that can be implemented in multiple languages while producing the same results.

### 6. Open-ended input support

Alpha starts with integers.

Beta expands toward floats, characters, strings, bytes, sequences, nested structures, raw pixels, and custom objects.

The project should remain open-ended so new data types can be added without rewriting the core.

---

## Core formula

The canonical linear range-mapping formula is:

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

Default output range:

```text
out_min = -1.0
out_max =  1.0
```

So the default normalized formula becomes:

```text
mapped = -1.0 + ((value - in_min) / (in_max - in_min)) * 2.0
```

---

## Alpha examples

These are the expected v1 alpha behaviors.

### Zero-based range

```text
0 in [0, 100]       -> -1.0
50 in [0, 100]      ->  0.0
100 in [0, 100]     ->  1.0
```

### Negative-to-positive range

```text
-10 in [-10, 10]    -> -1.0
0 in [-10, 10]      ->  0.0
10 in [-10, 10]     ->  1.0
```

### Non-zero positive range

```text
5 in [5, 15]        -> -1.0
10 in [5, 15]       ->  0.0
15 in [5, 15]       ->  1.0
```

---

## Target Python API

> The API below reflects the intended v1 alpha direction. The repository may still contain legacy files while the alpha implementation is being rebuilt.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100))

print(mapper.map_value(0))    # -1.0
print(mapper.map_value(50))   #  0.0
print(mapper.map_value(100))  #  1.0
```

### Strict mode

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)

mapper.map_value(101)  # raises OutOfRangeError
```

### Clipping mode

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)

print(mapper.map_value(-50))  # -1.0
print(mapper.map_value(150))  #  1.0
```

### Custom output range

`[-1.0, 1.0]` is the default, but other output ranges can be configured explicitly.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(
    input_range=(0, 100),
    output_range=(0.0, 1.0),
)

print(mapper.map_value(50))  # 0.5
```

---

## Saving and reloading mapper specs

A major goal of `libRangeMap` is reproducibility.

A mapper should be able to describe itself as metadata, then recreate the same transform later.

```python
from librangemap import IntegerRangeMapper

mapper = IntegerRangeMapper(input_range=(0, 255), clip=True)
mapper.save("pixel_range.json")

loaded = IntegerRangeMapper.load("pixel_range.json")

assert loaded.map_value(0) == -1.0
assert loaded.map_value(255) == 1.0
```

Example serialized spec:

```json
{
  "spec_version": "1.0-alpha",
  "mapper_type": "integer_range",
  "input_range": [0, 255],
  "output_range": [-1.0, 1.0],
  "clip": true
}
```

---

## Alpha v1 goal

`libRangeMap` reaches **v1 alpha** when a fresh developer can:

- clone the repo,
- read the spec,
- import/use the SDK with no third-party dependencies,
- create an integer range mapper,
- map finite integers into `[-1.0, 1.0]`,
- choose strict or clipping behavior,
- save and reload mapping specs,
- run correctness tests,
- and understand what is alpha, beta, and deferred.

### Alpha v1 is focused on integers

Alpha is intentionally narrow.

The first priority is to get the core math, error handling, serialization, docs, and test coverage correct before expanding to every possible data type.

---

## Beta v1 vision

`libRangeMap` reaches **v1 beta** when it becomes a practical SDK that can be imported into projects and used to map many supported data types into `[-1.0, 1.0]`.

The beta goal is input-type agnosticism through explicit mapping policies.

That means beta should support or provide extension points for:

| Category | Examples |
|---|---|
| Numeric | `int`, `float`, finite bounded values |
| Character | alphabet position, custom alphabets, Unicode codepoints |
| Text | strings, tokens, vocabulary policies |
| Binary | bytes, bytearray, memoryview-like buffers |
| Sequences | lists, tuples, nested structures |
| Raw pixels | grayscale, RGB, RGBA, flat buffers |
| Custom objects | schema-based field mapping, user-defined adapters |
| Cross-language | shared specs and compliance fixtures |

The important distinction:

> Beta does not magically understand every object in existence. Beta provides a universal mapping contract so any data type can be mapped once a mapper, schema, adapter, or range policy is declared.

---

## What libRangeMap does not do

`libRangeMap` is not:

- a machine-learning framework,
- a neural network library,
- a dataset hosting platform,
- an image decoder,
- a tokenizer,
- a semantic embedding model,
- a cloud service,
- an analytics SDK,
- or a wrapper around NumPy/pandas/PyTorch.

It is a small, deterministic mapping layer.

It helps normalize values.  
It does not decide what your data means.

---

## No-dependency promise

The core SDK must not require third-party runtime packages.

That means:

```text
✅ Standard library only
✅ First-party source only
✅ Offline by default
✅ No telemetry
✅ No hidden imports
✅ No automatic network calls
```

And:

```text
❌ No NumPy dependency
❌ No Pillow dependency
❌ No pandas dependency
❌ No PyTorch dependency
❌ No TensorFlow dependency
❌ No OpenCV dependency
❌ No requests dependency
```

Users who already use those tools can convert their data themselves and pass simple values, sequences, bytes, or raw decoded structures into `libRangeMap`.

The SDK itself should remain tiny and auditable.

---

## Installation

Pre-alpha local install target:

```bash
git clone https://github.com/asparks1987/libRangeMap.git
cd libRangeMap
python -m pip install .
```

Import target:

```python
import librangemap
```

Because the project is pre-alpha, package names and import paths may be cleaned up as part of the v1 alpha work.

---

## Testing

The project should prefer standard-library tests for the dependency-free alpha path.

Target command:

```bash
python -m unittest discover
```

Important alpha tests include:

- lower bound maps to `-1.0`,
- upper bound maps to `1.0`,
- midpoint maps to `0.0`,
- positive ranges,
- negative ranges,
- mixed ranges,
- non-zero ranges,
- large integer ranges,
- clipping behavior,
- strict out-of-range behavior,
- invalid range errors,
- non-integer rejection,
- bool rejection by default,
- serialization and reload,
- and dependency-free import.

---

## Roadmap

### Phase 1 — Alpha Core

- [ ] Clean repo hygiene.
- [ ] Remove generated artifacts from source control.
- [ ] Lock the spec.
- [ ] Implement integer range mapping.
- [ ] Default output to `[-1.0, 1.0]`.
- [ ] Add strict and clipping modes.
- [ ] Add clear errors.
- [ ] Add JSON-compatible mapper specs.
- [ ] Add tests.
- [ ] Update docs and examples.
- [ ] Validate local install/import.

### Phase 2 — Alpha Release

- [ ] Publish v1 alpha release notes.
- [ ] Add compliance examples.
- [ ] Add compatibility notes for legacy API behavior.
- [ ] Decide C++ support status.
- [ ] Add first language-agnostic compliance fixtures.

### Phase 3 — Beta Foundation

- [ ] Define mapper interface.
- [ ] Define adapter interface.
- [ ] Define schema-based mapping.
- [ ] Define custom mapper registration.
- [ ] Add batch transform rules.
- [ ] Add nested shape preservation.

### Phase 4 — Input-Type Expansion

- [ ] Float mapper.
- [ ] Character mapper.
- [ ] String mapper.
- [ ] Bytes/buffer mapper.
- [ ] Sequence mapper.
- [ ] Raw pixel/image-like mapper.
- [ ] Custom object mapper.

### Phase 5 — Cross-Language SDKs

- [ ] Stabilize language-agnostic spec.
- [ ] Add golden compliance fixtures.
- [ ] Align Python and C++ behavior.
- [ ] Add additional first-party implementations only when they can be tested and maintained.

---

## Repository layout target

```text
librangemap/
  __init__.py
  integer.py
  core.py
  errors.py
  spec.py
  serialization.py

tests/
  test_integer.py
  test_errors.py
  test_serialization.py
  test_dependency_free.py

docs/
  spec.md
  quickstart.md
  alpha_scope.md
  beta_roadmap.md
  no_dependencies.md

examples/
  map_integer.py
  map_negative_range.py
  map_with_clipping.py
  map_strict.py
  save_and_load_mapper.py

AGENTS.md
burndown.md
README.md
LICENSE
CHANGELOG.md
pyproject.toml
```

---

## Contributing

Contributions are welcome once the alpha foundation is in place.

The most important contribution rule:

> Do not add dependencies or copy third-party source into the core SDK.

Good contributions should:

- keep behavior deterministic,
- include tests,
- update docs when public behavior changes,
- preserve the no-dependency promise,
- avoid hidden network behavior,
- and keep APIs understandable for beginners.

---

## Security and privacy

`libRangeMap` should be safe for private and offline dataset workflows.

The core SDK should not:

- collect telemetry,
- phone home,
- upload data,
- download models,
- check for updates,
- log raw datasets by default,
- or require network access.

---

## Project philosophy

`libRangeMap` should be boring in the best possible way.

The math should be obvious.  
The output should be predictable.  
The code should be auditable.  
The package should be easy to install.  
The core should work without dependencies.  
The spec should be portable to any language.

That is the whole point.

---

<div align="center">

### Build the smallest correct core first.

Then make it universal.

</div>
