# Path to Production v1

## Objective

Reach practical interoperability for ordinary data-bearing values across all 25 canonical languages in configured output bounds, with explicit extractor contracts for opaque runtime types.

## Current state

- Core contract: canonical linear mapping, reproducible JSON specs, explicit failures, and dependency-free core are in place.
- Wrapper existence: all 25 language runtime paths and smoke checker scripts are present.
- Python reference coverage: the in-tree package already exposes bytes, categorical, temporal, image, map, and sequence mappers in addition to the scalar families.
- Python nested spec dispatch coverage: sequence and map recovery now explicitly reject unsupported nested mapper types in `tests/test_serialization.py`.
- Python serialization contract: JSON helpers reject non-finite literals, and `MapRangeMapper` now requires `missing_value` to be JSON-serializable.
- Python categorical contract: vocabulary tokens are JSON-serializable scalars, and `True`, `1`, and `1.0` stay distinct.
- Nested composite round-trip smoke coverage: Python, JavaScript, C++, C#, Java, and PHP now include explicit repeated-call checks on nested mapper graphs in their verifier/smoke paths; JavaScript, PHP, C++, C#, and Java also exercise bytes repeated mapping, with PHP additionally covering strict failure, explicit missing-field rejection, and nested missing-field rejection, C# additionally covering explicit missing-field rejection, empty-alphabet rejection, and temporal coverage, C++ additionally covering explicit missing-field rejection, Java additionally covering explicit missing-field rejection, JavaScript additionally covering nested missing-field rejection, and Ruby now covering map/object and image-like families in addition to deterministic nested checks for scalar families. C, Fortran, Perl, and Swift now also carry explicit repeated-canonical integer determinism checks in their wrapper verifiers or self-check paths, C now also includes byte-family, image-like raw byte, explicit schema-driven map/object coverage, and explicit timestamp-temporal coverage, and Swift now includes temporal coverage.
- JavaScript categorical contract coverage: `wrappers/javascript/test.js` now rejects empty categorical vocabularies in addition to duplicate and unknown tokens.
- JavaScript temporal and image-like contract coverage: `wrappers/javascript/index.js`, `wrappers/javascript/test.js`, and `wrappers/javascript/README.md` now cover Date, epoch-millisecond, ISO-8601 timestamp inputs, and nested pixel arrays deterministically.
- Java temporal/image-like contract coverage: `wrappers/java/src/librangemap/Verify.java`, `wrappers/java/src/librangemap/ImageRangeMapper.java`, and `wrappers/java/README.md` now cover temporal inputs and nested pixel arrays deterministically.
- C# temporal/categorical/image-like contract coverage: `wrappers/csharp/LibRangeMap/TemporalRangeMapper.cs`, `wrappers/csharp/LibRangeMap/CategoricalRangeMapper.cs`, `wrappers/csharp/LibRangeMap/ImageRangeMapper.cs`, `wrappers/csharp/Verify/Program.cs`, and `wrappers/csharp/README.md` now cover UTC Unix-millisecond temporal values, categorical vocabularies, raw byte arrays, and nested numeric pixel arrays deterministically.
- PHP image-like contract coverage: `wrappers/php/LibrangeMap.php` and `wrappers/php/README.md` now cover raw byte strings and nested numeric pixel containers deterministically.
- C++ temporal/categorical/sequence/image-like contract coverage: `wrappers/cpp/include/librangemap.hpp`, `wrappers/cpp/src/verify.cpp`, and `wrappers/cpp/README.md` now cover Unix-second timestamps, categorical vocabularies, typed sequence mapping, raw byte strings, nested numeric pixel arrays, and image fields inside object composition deterministically.
- Visual Basic float/boolean/categorical/object/image-like contract coverage: `wrappers/vb/LibRangeMap/FloatRangeMapper.vb`, `wrappers/vb/LibRangeMap/BooleanRangeMapper.vb`, `wrappers/vb/LibRangeMap/CategoricalRangeMapper.vb`, `wrappers/vb/LibRangeMap/ObjectRangeMapper.vb`, `wrappers/vb/LibRangeMap/ImageRangeMapper.vb`, `wrappers/vb/Verify/Program.vb`, and `wrappers/vb/README.md` now cover finite float inputs, explicit boolean mappings, categorical vocabularies, schema-driven object mapping, raw image-like byte payloads with shape metadata, and repeated-call deterministic checks.
- R bytes/categorical/image-like/object contract coverage: `wrappers/r/librangemap.R` and `wrappers/r/README.md` now cover raw vectors, strings, numeric byte vectors, categorical vocabularies, schema-driven object mapping, and recursive image-like buffers deterministically.
- Perl float/boolean/text/image-like contract coverage: `wrappers/perl/librangemap.pl` and `wrappers/perl/README.md` now cover finite float inputs, explicit boolean mappings, byte buffers, text codepoint/byte/alphabet policies, and recursive image-like mapping deterministically.
- SQL scalar/text/bytes/sequence contract coverage: `wrappers/sql/librangemap.sql` and `wrappers/sql/README.md` now cover finite float inputs, explicit boolean mappings, text mapping, bytea mapping, numeric array mapping, categorical vocabularies, image-like mappings, and direct self-checks deterministically.
- Delphi/Object Pascal float/boolean/categorical contract coverage: `wrappers/delphi/librangemap.pas` and `wrappers/delphi/README.md` now cover finite float inputs, explicit boolean mappings, categorical vocabularies, and direct self-checks deterministically.
- Fortran float/boolean/categorical/bytes contract coverage: `wrappers/fortran/librangemap.f90`, `wrappers/fortran/README.md`, and `wrappers/fortran/test.cmd` now cover finite float inputs, explicit boolean mappings, categorical vocabularies, byte-string mapping, and schema-driven map/object mapping with direct self-checks deterministically.
- Scratch full-family spec coverage: `wrappers/scratch/librangemap.md` and `wrappers/scratch/README.md` now describe the canonical mapping contract, deterministic guard rails, text, bytes, categorical vocabulary, recursive sequence, schema-driven map/object, temporal, and raw image-like channel contracts for the Scratch extension path.
- Assembly full-family ABI contract coverage: `wrappers/assembly/librangemap.asm` and `wrappers/assembly/README.md` now document explicit entrypoints and status/error contracts for integer, float, boolean, text, bytes, sequence, map/object, categorical, temporal, and raw image-like channel mapping without fallback coercion.
- Classic Visual Basic float/boolean contract coverage: `wrappers/vb6/Librangemap.bas` and `wrappers/vb6/README.md` now cover finite float inputs, explicit boolean mappings, and deterministic module-level self-check behavior.
- PL/SQL scalar/text/bytes/sequence/struct coverage: `wrappers/plsql/librangemap.sql` and `wrappers/plsql/README.md` now cover finite float inputs, explicit boolean mappings, text mapping, RAW byte mapping, numeric sequence mapping, and schema-directed object mapping via `libRangeMap_map_object`/`libRangeMap_map_object_value`.
- Go integer spec serialization coverage: `wrappers/go/librangemap/integer_windows_test.go` now rejects unsupported `mapper_type` values, unsupported `spec_version` values, and malformed JSON during recovery.
- Rust integer spec serialization coverage: `wrappers/rust/tests/integration.rs` now rejects unsupported `mapper_type` values during spec recovery.
- Beta compatibility families: manifest-complete across all 25 canonical language wrappers; production work now centers on conformance depth, runtime verification, packaging, and opaque-object extractor contracts.
- Beta completion audit: `docs/beta_completion_audit.md` records Beta v1 readiness as complete and preserves the production v1 boundary.

## Production-ready claim target

`libRangeMap` is production-ready when all of these are true:

- Ordinary scalar inputs (numbers, bools, text, bytes) map deterministically in each supported language.
- Ordered containers (arrays, tuples, vectors, sequences) preserve shape deterministically where applicable.
- Map/object-like structures are schema-driven with explicit missing/unknown behavior.
- Opaque runtime values (sockets, handles, threads, processes, closures, raw pointers) are rejected unless an explicit extractor/schema contract is provided.
- Wrapper smoke checks are verified in supported environments, with documented verified/skipped/failed results per language.
- Reproducible specs with `spec_version`, `mapper_type`, ranges, policy flags, and metadata round-trip exactly.
- Deterministic wrapper smoke evidence is now manifest-backed across all 25 Alpha v1 language wrappers. Family parity is closed for integer, float, boolean, text, bytes, sequences, map/object, categorical vocabulary, temporal, and image-like mapping, with remaining production work focused on deeper host-language ordinary type breadth, opaque extractor/schema contracts, serialization hardening, and cross-language conformance fixtures.

## Milestone scoring model (current objective checkpoint)

Readiness progresses in this fixed order:

1. Foundation
2. Wrapper parity
3. Compatibility matrix
4. Docs finish
5. Packaging / readiness

Weights toward Alpha v1 claim remain:

- Foundation: 0.15
- Wrapper parity: 0.50 (all 25 wrappers + smoke paths present)
- Compatibility matrix: 0.25
- Docs finish: 0.05
- Packaging / readiness: 0.05

Current score snapshot:

- Foundation: complete (0.15)
- Wrapper parity: complete (0.50)
- Compatibility matrix: manifest-complete for beta family parity (=0.25)
- Docs finish: complete (=0.05)
- Packaging / readiness: complete for beta (=0.05)

## Milestone proof grid (current gate status)

| Milestone | Gate status | Acceptance evidence |
| --- | --- | --- |
| Foundation | complete | Canonical formula, explicit failure classes, deterministic JSON specs in Python and shared docs. |
| Wrapper parity | complete | 25 wrapper artifacts and smoke paths present; README contract sections and runtime checks are enforced by tests. |
| Compatibility matrix | complete for beta parity | `compliance/beta_readiness.json` plus `docs/compatibility.md` reflect 25/25 coverage for every beta family; production conformance depth remains separate hardening work. |
| Docs finish | complete | `docs/quickstart.md`, wrapper READMEs, `docs/beta_wrapper_contract.md`, `docs/beta_readiness_evidence.md`, and `docs/beta_completion_audit.md` describe supported families and edge behavior. |
| Packaging/readiness | complete for beta | Core remains dependency-free with packaging metadata guards, and spec serialization/recovery is reproducible under tests and packaging constraints. |

## Explicit production blockers

1. **Conformance depth beyond family presence**
   - Family breadth parity is complete in the manifest, but production needs shared fixtures that prove behavior across languages for representative scalar, nested, schema, temporal, image-like, missing, unknown, strict, and clipping cases.
   - Long-tail ordinary host-language containers and records need stronger coverage notes before a 99%+ practical compatibility claim.

2. **No implicit fallback policy**
   - Unknown symbols, tokens, object families, and unsupported types must remain explicit errors everywhere.

3. **Opaque runtime contract coverage**
   - Apply `compliance/opaque_extractor_contract.json` before introducing wrappers for runtime objects that are not plain data.

4. **Wrapper parity is only half of the alpha target**
   - Language wrapper presence is the **50%** Alpha v1 gate and is complete.
   - Beta family parity is complete; production remains gated by fixture depth, runtime verification, release packaging, and opaque-object extractor/schema contracts.

## Packaging + docs requirements for this gate

To make production completion auditable:

- Keep `compliance/beta_readiness.json` as the canonical source for family/language status.
- Keep `compliance/runtime_verification_status.json` aligned with the runtime smoke matrix and toolchain gates.
- Record environment-specific runtime results using `compliance/runtime_verification_results.schema.json`.
- Use `tools/write_runtime_verification_results.py --output <path>` to generate verified/skipped/failed runtime evidence for a local or CI environment.
- Keep `tests/test_alpha_wrapper_runtime.py` as the runtime gate surface.
- Keep README/quickstart pages reflecting current quickstart entrypoints and blocker status.
- Keep per-wrapper readmes aligned with explicit failure and edge-case guidance for families they claim to support.

## Next 3-step path

1. Expand compatibility fixtures and cross-language checks so every beta family is covered with shared examples.
2. Record runtime verification as verified/skipped/failed per language based on available toolchains.
3. Harden JSON spec round-trips for fitted ranges, vocabularies, policies, metadata, and nested mapper graphs.
4. Apply the extractor/schema contract for opaque runtime objects and document any family-specific extractor examples before implementation.

## Evidence-first execution check

Use this sequence when hardening a beta-complete family toward production:

1. Add or expand verifier fixture coverage so language-agnostic behavior is testable from the same contract artifacts.
2. Update wrapper README language-specific policy and 2-line usage lines if the fixture exposes a doc gap.
3. Update:
   - `compliance/beta_readiness.json` (`implemented` or `planned`)
   - `docs/beta_wrapper_contract.md` (family status matrix)
   - `docs/compatibility.md` (family-by-language matrix)
4. Re-run relevant smoke checks and record result as `done` only when all supported environments verify or explicitly report skip.

## Source of truth

- [Beta Roadmap](beta_roadmap.md)
- [Beta Completion Audit](beta_completion_audit.md)
- [Beta Readiness Evidence](beta_readiness_evidence.md)
- [Compatibility Matrix](compatibility.md)
- [Beta Wrapper Contract](beta_wrapper_contract.md)
- [Beta Readiness Manifest](../compliance/beta_readiness.json)
- [Beta Conformance Fixtures](../compliance/beta_conformance_fixtures.json)
- [Spec Metadata Contract](../compliance/spec_metadata_contract.json)
- [Opaque Extractor Contract](../compliance/opaque_extractor_contract.json)
- [Runtime Verification Status](../compliance/runtime_verification_status.json)
- [Runtime Verification Results Schema](../compliance/runtime_verification_results.schema.json)
- [runtime result writer](../tools/write_runtime_verification_results.py)
- [wrapper runtime verifier](../tests/test_alpha_wrapper_runtime.py)
- [wrapper path/README contract + smoke script checks](../tests/test_alpha_wrapper_paths.py)






































