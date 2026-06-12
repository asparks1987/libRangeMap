# Compatibility Matrix

## V1 Readiness as Gates

We score readiness in five gates:

1) **Foundation** (formula + canonical behavior + reproducible spec): done  
2) **Wrapper-path parity** (all 25 language directories/quickstarts + contract + smoke hooks): done  
3) **Compatibility breadth** (families beyond integer): in progress  
4) **Docs finish** (copy-ready lines + explicit failure and policy guidance): in progress  
5) **Production readiness** (99%+ ordinary typed values, ordered by explicit extractor policy): target

The current Alpha v1 blocker is Gate 2 completion value, so it is scored as **~50%** to Alpha readiness by design.

## Alpha v1 Foundation

`libRangeMap` has a dependency-free integer mapping foundation that is consistent across the spec and Python reference:

- Canonical formula and JSON spec shape are documented in the spec.
- Integer range mapping behavior is implemented and tested in core.
- Default output range is `[-1.0, 1.0]`.
- `from librangemap import IntegerRangeMapper` is the canonical Python entrypoint.

The 25-language wrapper paths and canonical quickstarts are present in-tree.
Runtime smoke verification is environment-gated:

- **25** wrapper entries are exercised by the local verifier matrix in this repository.
- `verified` and `skipped` states are environment-driven and expected when native toolchains are unavailable.

For reproducibility, wrapper runtime status is tracked by the test matrix in
`tests/test_alpha_wrapper_runtime.py` and treated as a blocker only for runtime parity, not for path existence.

## Beta Mapper Families (Ordered by Beta Readiness)

| Family | Current Status | Required for Beta | Alpha Scope Relation |
| --- | --- | --- | --- |
| Integer ranges | Implemented | Complete | Core alpha deliverable |
| Floating-point ranges | In progress | Partially implemented | Explicit bounds + clipping contract |
| Booleans | In progress | Partially implemented | Explicit binary policy |
| Missing / optional | Planned | Planned | Explicit missing-value policy |
| Characters / text | In progress | Partially implemented | Explicit codepoint, alphabet, or byte policies |
| Bytes / buffers | Planned | Planned | Raw byte normalization policy |
| Categorical / enums / symbols | Planned | Planned | Vocabulary mapping policy |
| Date / time / duration | Planned | Planned | Explicit epoch or policy-based mapping |
| Sequences / nested sequences | Partially implemented | Planned | Recursive mapping with stable shape |
| Sets / unordered collections | Planned | Planned | Deterministic ordering contract |
| Maps / records / structs / objects | Planned | Planned | Schema-based field mapping |
| Image-like data | Planned | Planned | Pixel tuples and raw buffers |

## Alpha-to-Production Path

Beta v1 requires practical ordinary-data compatibility across all 25 languages for the families above.

Production v1 target is practical near-universal ordinary-type support:

> 99%+ of ordinary, serializable, data-bearing values should map deterministically into `[-1.0, 1.0]`.

Opaque runtime objects remain explicitly unsupported without extractor/schema contracts:

- file handles
- sockets
- threads
- processes
- closures/functions
- raw pointers without metadata
- open DB cursors or cursors with external environment state

## Compatibility Evidence

`compliance/alpha_v1_languages.json` is the language manifest for alpha-scope targets.

Runtime-level parity is validated by wrapper local verifiers (`test.cmd`) and tracked in the beta wrapper contract table:

- all 25 language wrapper paths and quickstart files are present in-repo.
- runtime checks are marked `verified` or `skipped` depending on local toolchain availability.
- all 25 languages are accounted for by verifier status (`verified + skipped`).
- long-tail compatibility hardening continues through the beta family plan.

## Current blockers

1. Family breadth: text, bytes, maps, and image mappers are only partially or not implemented in all languages; float/boolean are now implemented in more runtimes but still expanding across the canon set; sequences remain implemented in Python, Java, and JavaScript only.
2. Explicit extractor contracts: opaque/runtime-only objects remain outside supported primitives.
3. Cross-language fixture parity: shared fixture extensions for beta families are still being built.

## Beta v1 as Production-Resembling Scope

Beta is successful when every canon language exposes deterministic ordinary-type mappers for:

- numbers and booleans with explicit clipping/missing policies,
- strings and text characters via explicit character/byte/vocabulary policies,
- byte containers with explicit empty/error policy,
- nested sequences and map/object shapes with shape/schema governance,
- image-like pixel data for common grayscale/RGB/RGBA forms.

The final production target remains **99%+ practical compatibility** with explicit extractor contracts for opaque/runtime-only values (sockets, threads, handles, processes, functions, untyped pointers).

## Proof grid: family coverage by language

Status values:
- `done`: implementation and local verification path exist in-repo.
- `planned`: contract-only or no implementation yet.

| # | Language | Integer | Float | Boolean | Text | Bytes | Sequences | Maps/Object | Images |
| -: | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Python | done | done | done | done | planned | done | planned | planned |
| 2 | C | done | done | done | planned | planned | planned | planned | planned |
| 3 | Java | done | done | done | done | planned | done | planned | planned |
| 4 | C++ | done | done | done | planned | planned | planned | planned | planned |
| 5 | C# | done | done | done | planned | planned | planned | planned | planned |
| 6 | JavaScript | done | done | done | done | planned | done | planned | planned |
| 7 | Visual Basic | done | planned | planned | planned | planned | planned | planned | planned |
| 8 | R | done | done | done | planned | planned | planned | planned | planned |
| 9 | SQL | done | planned | planned | planned | planned | planned | planned | planned |
| 10 | Delphi/Object Pascal | done | planned | planned | planned | planned | planned | planned | planned |
| 11 | Fortran | done | planned | planned | planned | planned | planned | planned | planned |
| 12 | Scratch | done | planned | planned | planned | planned | planned | planned | planned |
| 13 | Perl | done | planned | planned | planned | planned | planned | planned | planned |
| 14 | PHP | done | done | done | planned | planned | planned | planned | planned |
| 15 | Rust | done | planned | planned | planned | planned | planned | planned | planned |
| 16 | Go | done | planned | planned | planned | planned | planned | planned | planned |
| 17 | Assembly language | done | planned | planned | planned | planned | planned | planned | planned |
| 18 | Swift | done | planned | planned | planned | planned | planned | planned | planned |
| 19 | Ada | done | planned | planned | planned | planned | planned | planned | planned |
| 20 | MATLAB | done | planned | planned | planned | planned | planned | planned | planned |
| 21 | Classic VB | done | planned | planned | planned | planned | planned | planned | planned |
| 22 | PL/SQL | done | planned | planned | planned | planned | planned | planned | planned |
| 23 | Ruby | done | planned | planned | planned | planned | planned | planned | planned |
| 24 | Prolog | done | planned | planned | planned | planned | planned | planned | planned |
| 25 | COBOL | done | planned | planned | planned | planned | planned | planned | planned |

## Evidence references (current)

- Python core: `librangemap/integer.py`, `librangemap/float.py`, `librangemap/boolean.py`, `librangemap/sequence.py`, `librangemap/text.py`, `tests/test_integer.py`, `tests/test_float.py`, `tests/test_boolean.py`, `tests/test_sequence.py`, `tests/test_text.py`.
- JavaScript: `wrappers/javascript/index.js`, `wrappers/javascript/test.js`, `wrappers/javascript/README.md`.
- C#: `wrappers/csharp/LibRangeMap/IntegerRangeMapper.cs`, `wrappers/csharp/LibRangeMap/FloatRangeMapper.cs`, `wrappers/csharp/LibRangeMap/BooleanRangeMapper.cs`, `wrappers/csharp/Verify/Program.cs`, `wrappers/csharp/README.md`.
- Java: `wrappers/java/src/librangemap/IntegerRangeMapper.java`, `wrappers/java/src/librangemap/FloatRangeMapper.java`, `wrappers/java/src/librangemap/BooleanRangeMapper.java`, `wrappers/java/src/librangemap/TextRangeMapper.java`, `wrappers/java/src/librangemap/Verify.java`, `wrappers/java/README.md`.
- R: `wrappers/r/librangemap.R`, `wrappers/r/README.md`.
- PHP: `wrappers/php/LibrangeMap.php`, `wrappers/php/README.md`.
- All 25 wrapper paths/quickstarts: manifest in [compliance/alpha_v1_languages.json](../compliance/alpha_v1_languages.json) and path list in `test_alpha_wrapper_runtime.py`.
