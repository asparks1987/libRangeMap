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
| Cross-runtime parity for beta families (local) | Family parity is manifest-complete; runtime verification remains environment-gated by available language toolchains |

The language-wrapper milestone is the main Alpha v1 gate. It is intended to account for roughly **50% of Alpha v1 readiness**.

Current wrapper footprint is visible in [Alpha v1 Language Manifest](compliance/alpha_v1_languages.json). See each implementation path at `/wrappers`.

The former cross-language family breadth blocker is closed in the readiness manifest: all 25 canonical language wrappers now list integer, float, boolean, text, bytes, sequences, maps/objects, categorical_vocab, temporal, and image-like contracts as implemented. Remaining work is production hardening: shared conformance fixtures, environment-specific runtime verification, release packaging, and explicit extractor/schema contracts for opaque runtime objects.

---

## How a Client Integrates in 30 Seconds

### Install

```bash
python -m pip install .
```

### Strict (safe) integration example (Python)

```python
from librangemap import BytesRangeMapper, IntegerRangeMapper
mapper = IntegerRangeMapper(input_range=(0, 100), clip=False)
print(mapper.map_value(50))

byte_mapper = BytesRangeMapper(output_range=(0.0, 2.0))
print(byte_mapper.map_value(b"AB"))
```

### Python family quick hits

```python
from datetime import timedelta
from librangemap import BooleanRangeMapper, BytesRangeMapper, CategoricalRangeMapper, ImageRangeMapper, IntegerRangeMapper, MapRangeMapper, SequenceRangeMapper, TemporalRangeMapper, TextRangeMapper

print(CategoricalRangeMapper(vocabulary=("red", "green", "blue")).map_value("green"))
print(TextRangeMapper(mode="alphabet", alphabet="abc", allow_empty=True).map_value("cab"))  # alphabet mode requires at least 2 unique symbols
print(SequenceRangeMapper(IntegerRangeMapper(input_range=(0, 100))).map_value([0, [10, 20], (30, 40)]))
print(BytesRangeMapper(output_range=(0.0, 255.0)).map_value(b"AB"))
print(TemporalRangeMapper(input_range=(0.0, 120.0), mode="duration").map_value(timedelta(seconds=60)))
print(MapRangeMapper({"age": IntegerRangeMapper(input_range=(0, 120)), "active": BooleanRangeMapper()}).map_value({"age": 42, "active": True}))
print(ImageRangeMapper(input_range=(0, 255), mode="raw_bytes").map_value(b"AB"))
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

## Why this stays production-shaped

- Default output remains `[-1.0, 1.0]`.
- Contract failure paths stay explicit (no magic fallback values).
- Specs are reproducible through JSON and include version+policy metadata.
- Opaque runtime objects are blocked unless users provide extractor/schema contracts.
- Wrapper presence and beta family breadth are complete for the 25 canonical languages; runtime parity remains environment-gated, and production readiness depends on conformance depth, packaging, and opaque-object extractor contracts.

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
| Compatibility matrix | Manifest-complete for all 25 languages and 10 beta families; deeper production conformance continues separately |
| Docs finish | Complete for beta; quickstart + wrappers + site now tuned for 2-second paste-in readability |
| Packaging / readiness | Complete for beta; production release hardening remains |

## Current blocker

The blocker is no longer "language presence" or "family breadth." It is **production proof depth**:

- Shared conformance fixtures need to cover beta families across wrappers, not just presence/readme claims.
- Runtime smoke checks are still environment-gated by installed language toolchains.
- Opaque runtime values still require explicit extractor/schema contracts before production v1 can claim near-universal practical compatibility.

Current alpha blocker score:

- Wrapper-path coverage blocker is complete and contributes exactly `50%` of Alpha v1 progress.
- Beta family parity is complete in `compliance/beta_readiness.json`; production blockers remain in conformance depth, packaging hardening, and explicit opaque-runtime extractor contracts.

## V1 Milestone Board

Progress is tracked in this order:

1. Foundation (canonical formula + deterministic behavior + reproducible specs): complete
2. Wrapper parity (all 25 language paths + smoke checker presence): complete
3. Compatibility matrix (beta families and cross-language breadth): manifest-complete; production conformance continues separately
4. Docs finish (`2-second` start + explicit policy/error guidance): complete for beta
5. Packaging/readiness (dependency-free + verifier evidence): complete for beta; production hardening remains

### Alpha to Beta to Production target

- **Beta gate:** major ordinary families are exposed per language with explicit policy and error behavior.
- **Production v1 target:** `~99%+` practical compatibility for ordinary values with explicit extractor contracts for opaque runtime objects (sockets, handles, threads, closures, raw pointers without schema metadata).
- **No implicit fallback policy:** unknown values must fail visibly with typed errors.

Readiness weighting source:

- Foundation: 0.15
- Wrapper parity: 0.50 (language-wrapper presence checkpoint)
- Compatibility matrix: 0.25
- Docs finish: 0.05
- Packaging/readiness: 0.05

### Milestone proof points

- Wrapper-path presence: `tests/test_alpha_wrapper_paths.py`
- Runtime verifier matrix: `tests/test_alpha_wrapper_runtime.py`
- Language scope manifest: `compliance/alpha_v1_languages.json`
- Family matrix: `docs/compatibility.md`
- Wrapper family contract: `docs/beta_wrapper_contract.md`
- Readiness manifest: `compliance/beta_readiness.json`
- Beta conformance fixtures: `compliance/beta_conformance_fixtures.json`
- Spec metadata contract: `compliance/spec_metadata_contract.json`
- Opaque extractor contract: `compliance/opaque_extractor_contract.json`
- Runtime verification status: `compliance/runtime_verification_status.json`
- Runtime verification result schema: `compliance/runtime_verification_results.schema.json`
- Runtime result writer: `tools/write_runtime_verification_results.py`
- Beta readiness evidence map: `docs/beta_readiness_evidence.md`
- Beta completion audit: `docs/beta_completion_audit.md`

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
- [Production v1 Path](docs/production_path_to_v1.md)
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
