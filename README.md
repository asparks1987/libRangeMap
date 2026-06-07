# libRangeMap

## Deterministic normalization for AI-ready teams

**libRangeMap** is a first-party, dependency-free SDK that turns input values into deterministic floating-point features, with a shared contract designed for cross-language production pipelines.

If you are evaluating quickly: this is the one-line problem statement

> Same input and same config always produce identical values.

The client-facing docs site is now built from `/docs`; open [`docs/index.md`](docs/index.md) for the web-first entrypoint.

---

## At a Glance

- **Product:** Feature normalization SDK for AI and ML preparation
- **Default output range:** `[-1.0, 1.0]`
- **Default behavior:** explicit clipping + strict mode options
- **Dependency policy:** core + wrappers have no runtime dependencies beyond language runtimes
- **Contract model:** shared formula, shared spec, reproducible JSON artifacts
- **Current status:** Alpha v1 core contract is implemented; language coverage is the remaining alpha milestone

---

## 2-Second Client Quickstart

Use this exact line for value `50` from input range `[0, 100]` into default output range `[-1, 1]`.

```text
mapped = 0.0
```

### Copy-Paste Line by Language

| # | Language | One line to add |
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
| 12 | Scratch | `mapped := map_integer_value(50, 0, 100, -1, 1, false)` *(pseudo: mirror `librangemap.md`)* |
| 13 | Perl | `my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);` |
| 14 | PHP | `$mapped = map_integer_value(50, 0, 100);` |
| 15 | Rust | `let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;` |
| 16 | Go | `mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)` |
| 17 | Assembly language | `librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);` *(pseudo ABI call)* |
| 18 | Swift | `let mapped = IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue(50)` |
| 19 | Ada | `mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);` |
| 20 | MATLAB | `mapped = librangemap(50, 0, 100);` |
| 21 | Classic Visual Basic | `mapped = MapIntegerValue(50, 0, 100, -1, 1, False)` |
| 22 | PL/SQL | `mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);` |
| 23 | Ruby | `mapped = LibrangeMap::IntegerRangeMapper.new(0, 100).map_value(50)` |
| 24 | Prolog | `?- map_integer_value(50, 0, 100, -1.0, 1.0, false, Mapped).` |
| 25 | COBOL | `* use wrapper signature in wrappers\cobol\librangemap.cob` |

Each row maps directly to the same shared formula and output semantics.

For each language, the exact namespace/import and module loading steps are documented in
`wrappers/<language>/README.md`.

---

## Core Formula

All maps in Alpha v1 follow this equation:

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

Defaults:

- `in_min/in_max`: your declared integer input bounds
- `out_min = -1.0`
- `out_max = 1.0`

---

## Product Fit (Why teams use it)

- **Multi-language parity:** one contract, same result wherever your stack executes.
- **Reproducible science:** specs are serializable and sharable across environments.
- **Audit-friendly:** no hidden defaults, no implicit type coercion, explicit failures.
- **Deployment light:** no third-party runtime dependencies to manage for the SDK.
- **Explainable operations:** unknown tokens/types fail loudly instead of being guessed.

---

## Alpha v1 Status (Client-Facing Readiness)

| Milestone | Status |
| --- | --- |
| Shared linear mapping contract in shared docs/spec | ✅ |
| Python reference implementation | ✅ |
| First-party C core + C ABI | ✅ |
| Runtime/wrapper for all 25 Alpha languages | 🟡 In progress (24/25 language directories present; Python is the source-reference API) |
| All 25 languages passing one compliance fixture | 🟡 Pending (execution parity is tracked by language runtime availability) |

The language-wrapper milestone is the main Alpha v1 gate. It is intended to account for roughly **50% of Alpha v1 readiness**.

Current wrapper footprint is visible in [Alpha v1 Language Manifest](compliance/alpha_v1_languages.json).  See each implementation path at `/wrappers`.

---

## How a Client Integrates in 30 Seconds

### Install

```bash
python -m pip install .
```

### Strict (safe) integration example (Python)

```python
from librangemap import IntegerRangeMapper
mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
print(mapper.map_value(50))
```

### Clip explicitly when your stream may exceed bounds

```python
mapper = IntegerRangeMapper(input_range=(0, 100), clip=True)
print(mapper.map_value(150))
```

### Persist and share the exact mapping spec

```python
mapper = IntegerRangeMapper(input_range=(0, 255), clip=True)
mapper.save('pixel_range.json')

roundtrip = IntegerRangeMapper.load('pixel_range.json')
print(roundtrip.map_value(255))
```

---

## Quality Signals

- Explicit error classes for range validation and out-of-domain input.
- Stable JSON serializable specifications.
- Shared mapping fixture in `compliance/` to keep language implementations aligned.
- Deterministic behavior and bounded output under contract.
- No dependency footprint in the core package and wrappers.

---

## Documentation Paths

- [Specification](docs/spec.md)
- [Quickstart](docs/quickstart.md)
- [Architecture](docs/architecture.md)
- [Alpha Scope](docs/alpha_scope.md)
- [Beta Roadmap](docs/beta_roadmap.md)
- [Compatibility Notes](docs/compatibility.md)
- [No Dependencies Policy](docs/no_dependencies.md)
- [Release Notes](docs/release_notes_v0.1.0-alpha.md)
- [Test Fixtures](compliance/integer_alpha.json)

---

## Repository Layout

- `csrc/`: first-party C core and C API
- `wrappers/`: language runtimes and ABI integration paths
- `librangemap/`: Python reference package
- `compliance/`: Alpha fixtures and manifests
- `docs/`: contract and roadmap documentation
- `tests/`: tests and cross-runtime verification points
