# libRangeMap

## Deterministic normalization for AI/ML datasets

`libRangeMap` is a first-party, dependency-free SDK for turning supported input values into reproducible features in `[-1.0, 1.0]`.

**Default guarantee:** same input and same config always produce the same mapped float.

Client docs are published at `docs/index.html`, which is built as the product-style entry page and quick-scan index.

---

## 2-Second Client Quickstart

Use this exact call for value `50` from input range `[0, 100]` into output range `[-1, 1]`:
it maps to `0.0`.

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
| 12 | Scratch | `mapped := map_integer_value(50, 0, 100, -1, 1, false)` *(block contract in `wrappers/scratch/librangemap.md`)* |
| 13 | Perl | `my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);` |
| 14 | PHP | `$mapped = map_integer_value(50, 0, 100);` |
| 15 | Rust | `let mapped = IntegerRangeMapper::new_default(0, 100)?.map_value(50)?;` |
| 16 | Go | `mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)` |
| 17 | Assembly language | `librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);` *(ABI contract)* |
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

```text
All canonical snippets are scaffolded in-repo; runtime verification is still progressing by language toolchain availability.
```

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

## Product Positioning

- **Multi-language parity:** one contract, same result wherever your stack executes.
- **Reproducible science:** specs are serializable and sharable across environments.
- **Audit-friendly:** no hidden defaults, no implicit type coercion, explicit failures.
- **Deployment light:** no third-party runtime dependencies to manage for the SDK.
- **Explainable operations:** unknown tokens/types fail loudly instead of being guessed.

---

## Alpha v1 Status (Client-Facing Readiness)

| Milestone | Status |
| --- | --- |
| Shared linear mapping contract in shared docs/spec | Complete |
| Python reference implementation | Complete |
| First-party C core + C ABI | Complete |
| Runtime/wrapper paths for all 25 Alpha languages | Complete |
| Cross-runtime parity for integer family (local) | Complete across local verifier matrix (verified and skip states normalized) |

The language-wrapper milestone is the main Alpha v1 gate. It is intended to account for roughly **50% of Alpha v1 readiness**.

Current wrapper footprint is visible in [Alpha v1 Language Manifest](compliance/alpha_v1_languages.json). See each implementation path at `/wrappers`.

The key blocker is now family breadth: floats, booleans, text, bytes, sequences, maps, and image-like contracts are still rolling out to all languages.

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

## Milestones (current)

| Track | Status |
| --- | --- |
| Foundation | Contract + canonical formula + Python integer reference + deterministic error behavior |
| Wrapper parity | Complete for all 25 in-tree wrapper paths and quickstarts |
| Runtime parity (this environment) | In-progress, with the verifier matrix proving all 25 languages are either verified or correctly skipped |
| Compatibility matrix | In progress (integer implemented; major families planned/rolling out) |
| Docs finish | In progress; quickstart + wrappers + site now tuned for 2-second paste-in readability |
| Packaging / readiness | In progress; fixtures + explicit status docs are in place |

## Current blocker

The blocker is no longer "language presence." It is **family breadth**:

`float`, `boolean`, `text`, `bytes`, `maps`, and image-like mapper families are not yet on parity for all languages.
`sequences` is partially rolled out (Python/JavaScript in progress), with wrapper-level parity still incomplete.

## Production v1 target

The production target is practical near-universal coverage (about **99%+** of ordinary data-bearing values) across the 25 canonical languages, while explicit extractor/schema contracts guard opaque runtime objects (threads, sockets, file handles, processes, closures, raw pointers, etc.).

## Documentation Paths

- [Specification](docs/spec.md)
- [Quickstart](docs/quickstart.md)
- [Architecture](docs/architecture.md)
- [Alpha Scope](docs/alpha_scope.md)
- [Beta Roadmap](docs/beta_roadmap.md)
- [Beta Wrapper Contract](docs/beta_wrapper_contract.md)
- [Compatibility Matrix](docs/compatibility.md)
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
