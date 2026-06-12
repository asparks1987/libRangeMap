# Beta Wrapper Contract

## Scope

Beta is executed on top of the alpha integer contract:

- canonical formula in `docs/spec.md`
- `[-1.0, 1.0]` default output range unless explicitly changed
- explicit error behavior for invalid ranges, unsupported types, unknown tokens, and missing metadata
- deterministic output for the same input + config

The project treats wrapper-path parity as the first Alpha v1 gate:

- 25 language runtime paths and quickstarts in-repo (counts ~50% to Alpha v1 completion).

Every wrapper language must also satisfy this minimum implementation checklist:

### Wrapper minimum contract

- install/use guidance
  - language-idiomatic install/use steps present in `wrappers/<language>/README.md`
- value-family policy coverage
  - supported families are declared and failures for unsupported families are explicit
- unknown/error behavior
  - `unsupported/unknown` must fail with explicit typed errors or documented errors
- edge-case behavior
  - empty containers, missing values, and malformed records must fail unless policy explicitly allows them
- reproducible spec behavior
  - mappers expose JSON round-trip for policy + ranges + metadata
- deterministic range math
  - canonical formula in `docs/spec.md` for numeric families
- family usage contract
  - wrappers that claim a family support must document at least one 2-line paste-ready usage snippet in the wrapper README for that family.

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
- Vocabulary tokens are JSON-serializable scalars, and booleans stay distinct from numeric tokens.
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

This matrix is machine-checked by `compliance/beta_readiness.json`.

Legend:

- `done`: implemented + verifier contract path exists
- `in progress`: implemented in subset or partially covered
- `planned`: contract-complete but implementation pending
- `not in-scope`: wrapper exists for alpha parity but beta family intentionally deferred

| # | Language | Integer | Float | Bool | Text | Bytes | Vocabulary | Sequences | Map/Object | Temporal | Image |
| -: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Python | done | done | done | done | done | done | done | done | done | done |
| 2 | C | done | done | done | done | done | done | done | done | done | done |
| 3 | Java | done | done | done | done | done | done | done | done | done | done |
| 4 | C++ | done | done | done | done | done | done | done | done | done | done |
| 5 | C# | done | done | done | done | done | done | done | done | done | done |
| 6 | JavaScript | done | done | done | done | done | done | done | done | done | done |
| 7 | Visual Basic | done | done | done | done | done | done | done | done | done | done |
| 8 | R | done | done | done | done | done | done | done | done | done | done |
| 9 | SQL | done | done | done | done | done | done | done | done | done | done |
| 10 | Delphi/Object Pascal | done | done | done | done | done | done | done | done | done | done |
| 11 | Fortran | done | done | done | done | done | done | done | done | done | done |
| 12 | Scratch | done | done | done | done | done | done | done | done | done | done |
| 13 | Perl | done | done | done | done | done | done | done | done | done | done |
| 14 | PHP | done | done | done | done | done | done | done | done | done | done |
| 15 | Rust | done | done | done | done | done | done | done | done | done | done |
| 16 | Go | done | done | done | done | done | done | done | done | done | done |
| 17 | Assembly language | done | done | done | done | done | done | done | done | done | done |
| 18 | Swift | done | done | done | done | done | done | done | done | done | done |
| 19 | Ada | done | done | done | done | done | done | done | done | done | done |
| 20 | MATLAB | done | done | done | done | done | done | done | done | done | done |
| 21 | Classic Visual Basic | done | done | done | done | done | done | done | done | done | done |
| 22 | PL/SQL | done | done | done | done | done | done | done | done | done | done |
| 23 | Ruby | done | done | done | done | done | done | done | done | done | done |
| 24 | Prolog | done | done | done | done | done | done | done | done | done | done |
| 25 | COBOL | done | done | done | done | done | done | done | done | done | done |

## Runtime smoke checks

Each language wrapper must keep a runnable `test.cmd` smoke checker where environment permits.

- The checker must return code `0` for pass, `2` for environment unavailable/skipped.
- No wrapper is required to force runtime installation in CI for unsupported environments.
- `tests/test_alpha_wrapper_runtime.py` is the canonical verifier registry.
- When a wrapper includes a repeated-call or nested-shape smoke proof, record that evidence in `compliance/beta_readiness.json` so the readiness gate stays machine-readable.

Observed smoke check path examples:

- `wrappers/c/test.cmd`
- `wrappers/java/test.cmd`
- `wrappers/rust/test.cmd`
- `wrappers/plsql/test.cmd`

## Family coverage with explicit extractor gates

Beta allows explicit extractor contracts for opaque runtime objects:

- file handles
- sockets
- processes
- threads
- closures/functions
- raw pointers without schema metadata

These values are excluded from implicit mapping; they must be rejected unless a user-defined extractor/schema contract is documented in docs and code.

## Release checkpoints

- Foundation + wrapper parity gate: satisfied when this matrix is actively implemented and verified incrementally.
- Beta milestone: satisfied when required families move from `planned` to `done` with verifier coverage.
- Production v1 milestone: satisfied when ordinary data-bearing values are covered near-universally (99%+ practical coverage) with explicit extractor gates for opaque runtime objects.
