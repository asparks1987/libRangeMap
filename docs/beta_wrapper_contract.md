# Beta Wrapper Contract

## Scope

Beta is executed on top of the alpha integer contract:

- canonical formula in `docs/spec.md`
- `[-1.0, 1.0]` default output range unless explicitly changed
- explicit error behavior for invalid ranges, unsupported types, unknown tokens, and missing metadata
- deterministic output for the same input + config

The project treats wrapper-path parity as the first Alpha v1 gate:

- 25 language runtime paths and quickstarts in-repo (counts ~50% to Alpha v1 completion).

The contract below is the implementation order for all 25 canon languages:

1. floating-point ranges
2. booleans and missing-value
3. characters, strings, and bytes
4. vocabularies and categorical values
5. sequences and nested sequences
6. sets/maps/records/object schemas
7. date/time/duration
8. image-like pixel containers

## Language-agnostic runtime requirements

Every language wrapper must provide:

- install/use guidance in its wrapper README
- one-line "paste to start" example per supported mapper family
- explicit exceptions (or language-native equivalent) for:
  - unknown family (unsupported type)
  - unknown token/symbol
  - missing value without configured missing policy
  - out-of-range in strict mode
- explicit edge cases for empty containers, non-finite numbers, and malformed records
- reproducible spec serialization (at least: mapper class/type, ranges/policies, clipping and metadata)
- deterministic handling of `NaN` and `Inf` by policy (default: reject)

Unknown values must fail loudly. No wrapper may silently coerce unknown tokens, unknown objects, or implicit casts to integers.

## Value family policy summary

### Floating-point family
- Accept finite numeric values (integer accepted only when explicitly part of the float mapping policy).
- default output range is `[-1.0, 1.0]`; custom output ranges may be configured explicitly.
- Same clipping and strict behavior as integer family.
- Reject `NaN` and infinities.

### Boolean family
- Explicit policy must define false/true mapping (e.g. `0.0`/`1.0` by default).
- Reject unknown truthy/falsey inputs unless policy explicitly maps them.

### Text family
- `char` and `string` families must document one policy:
  - codepoint policy
  - explicit alphabet policy
  - byte policy
  - vocabulary policy
- Unknown character/symbol must raise, never map to a magic fallback.

### Byte family
- Bytes, byte arrays, buffers, and memoryview-like values map through a byte or sequence policy.
- Unknown/empty policy must be explicit; empty payload is invalid unless policy permits and documents behavior.

### Sequence family
- Sequence mapping is element-wise and shape-preserving.
- Nested containers recurse through the same policy graph.
- Container kinds must document handling for arrays, tuples, vectors, and list-like values.

### Categorical family
- Accept only configured vocabulary/token lists or enumerations.
- Unknown token must fail with an explicit typed error.

### Temporal family
- Date/time/duration and timestamp values must document normalization domain and epoch/base policy.
- Non-temporal or malformed values must fail explicitly.

### Structural family
- Maps/records/structs/classes are mapped using explicit field schemas.
- Schema keys must be deterministic and order-preserving where possible; unordered input must be sorted by documented order policy.

### Pixel/image family
- Map grayscale, RGB, and RGBA in explicit channel order.
- Raw bytes must document shape/stride assumptions or require a shape schema.

## Readiness matrix (beta families by language)

Legend: `done`, `in progress`, `planned`.

| # | Language | Integer | Float | Bool | Text | Bytes | Vocabulary | Sequences | Map/Object | Temporal | Image |
| -: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Python | done | done | done | done | planned | planned | done | planned | planned | planned |
| 2 | C | done | done | done | planned | planned | planned | planned | planned | planned | planned |
| 3 | Java | done | done | done | done | planned | planned | done | planned | planned | planned |
| 4 | C++ | done | done | done | planned | planned | planned | planned | planned | planned | planned |
| 5 | C# | done | done | done | planned | planned | planned | planned | planned | planned | planned |
| 6 | JavaScript | done | done | done | done | planned | planned | done | planned | planned | planned |
| 7 | Visual Basic | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 8 | R | done | done | done | planned | planned | planned | planned | planned | planned | planned |
| 9 | SQL | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 10 | Delphi/Object Pascal | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 11 | Fortran | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 12 | Scratch | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 13 | Perl | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 14 | PHP | done | done | done | planned | planned | planned | planned | planned | planned | planned |
| 15 | Rust | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 16 | Go | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 17 | Assembly | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 18 | Swift | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 19 | Ada | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 20 | MATLAB | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 21 | Classic VB | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 22 | PL/SQL | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 23 | Ruby | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 24 | Prolog | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |
| 25 | COBOL | done | planned | planned | planned | planned | planned | planned | planned | planned | planned |

## Release checkpoints

- Foundation + wrapper parity gate: satisfied when this matrix is actively implemented and verified incrementally.
- Beta milestone: satisfied when required families move from `planned` to `done` with verifier coverage.
- Production v1 milestone: satisfied when ordinary data-bearing values are covered near-universally (99%+ practical coverage) with explicit extractor gates for opaque runtime objects.
