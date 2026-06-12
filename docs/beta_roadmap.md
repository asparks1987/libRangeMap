# Beta Roadmap

Beta expands the alpha integer mapper into a broader dependency-free mapping SDK.

## Final v1 Production Goal

Final v1 production should aim for practical universal compatibility:

> Convert as close to 100% of ordinary data-bearing types from every supported language into deterministic floating-point values in `[-1.0, 1.0]`, with zero SDK runtime dependencies.

The production target is effectively **99%+ compatibility** across the normal values users actually store, transmit, analyze, and train on in each supported language.

This includes built-in types, standard-library data containers, language-native records/classes/structs when fields are declared, and common data shapes used in AI/ML pipelines.

This does not mean guessing how to map obscure, opaque, executable, or environment-bound runtime objects that are not really data values. File handles, sockets, processes, threads, closures/functions, raw pointers without size/type metadata, live database cursors, and similar runtime resources require an explicit user-provided extractor or schema before they can be mapped.

## Beta v1 Finish Line

Beta v1 should closely resemble the final production shape. It should end with this product claim being true:

> The major ordinary data categories from every Alpha canon language runtime can be deterministically converted into floating-point values in `[-1.0, 1.0]` with zero SDK runtime dependencies.

Important wording:

- **Major ordinary data categories**, so Beta proves the production model without pretending every edge-case object is finished.
- **Explicit mapping policy**, not silent guessing.
- **All 25 Alpha canon languages**, not Python-only behavior.
- **Zero SDK runtime dependencies**, meaning standard language runtimes and standard libraries only.
- **Production-shaped APIs**, so Beta users are learning the final mental model.

This keeps Beta ambitious and useful while leaving the final long-tail compatibility hardening for production v1.

## Alpha and Beta Milestones

To keep status reviewable in one glance, we treat readiness in these milestones:

- **Foundation:** shared canonical formula, deterministic integer mapper, JSON spec, and explicit failure behavior.
- **Wrapper parity:** all 25 canon language wrappers and canonical quickstart lines exist; runtime parity is environment-gated (`verified`/`skipped` by toolchain availability).
- **Compatibility matrix:** manifest-backed beta family breadth is complete across all 25 canonical language wrappers for integer, float, boolean, text, bytes, sequences, map/object, categorical vocabulary, temporal, and image-like mapping. Production work now moves from presence/parity to conformance depth, runtime verification, packaging, and opaque-object extractor contracts.
- **Docs finish:** every section can tell users the exact paste-in line and failure policy in under 2 seconds.
- **Packaging & release readiness:** dependency policy, manifest visibility, and fixture-driven regressions are locked for the target milestone.

Current milestone score:

- Foundation: complete.
- Wrapper parity: complete for in-tree paths and readmes; runtime parity is environment-gated.
- Compatibility matrix: manifest-complete for beta family parity.
- Serialization contract: strict JSON helpers now reject non-finite numeric literals and require map fallback metadata to remain JSON-serializable.
- Compatibility matrix status detail: see [Beta Wrapper Contract](beta_wrapper_contract.md).
- Docs finish: complete for beta.
- Packaging & release readiness: complete for beta; production release hardening remains.

Readiness governance is also encoded in `compliance/beta_readiness.json`:

- Target compatibility: 99%+
- Explicit extractor policy for opaque runtime objects: handles, sockets, threads, processes, closures, raw pointers without metadata
- Gate weights: Foundation 0.15, Wrapper parity 0.50, Compatibility matrix 0.25, Docs finish 0.05, Packaging 0.05

## Required Beta Mapper Families

Beta v1 should cover these first-party mapper families:

- integer ranges
- floating-point ranges
- booleans through an explicit binary policy
- null, nil, None, missing, and optional values through an explicit missing-value policy
- characters by alphabet, codepoint, byte, or custom range policy
- strings by character, byte, token, or configured vocabulary policy
- bytes, bytearray-style values, and memory buffers where the language exposes them without external packages
- categorical values, enums, symbols, and tagged values through configured vocabularies
- date, time, timestamp, and duration values through explicit range or epoch policies
- sequences, arrays, tuples, lists, vectors, slices, and nested sequences while preserving shape
- sets and unordered collections only with an explicit deterministic ordering policy
- maps, dictionaries, hashes, records, structs, classes, and objects through explicit field schemas
- image-like data from raw bytes, grayscale values, RGB/RGBA tuples, or nested pixel arrays
- date/time/timestamp/duration values and temporal families require explicit epoch/base policies
- custom object schemas where fields are explicitly declared

Beta should prove recursive mapping across mixed structures, for example:

```text
record {
  age: integer range,
  country: vocabulary token,
  pixels: nested RGB tuples,
  events: sequence(timestamp range)
}
```

## Language-Agnostic Runtime Goal

Before Beta v1 can claim completion:

- Alpha must prove the cross-language architecture with a first-party C core.
- The C ABI must be documented and stable enough for wrappers.
- Every one of the 25 Alpha canon languages must expose the Beta mapper families or a clearly documented subset gate.
- Every mapper family must pass shared language-neutral compliance fixtures.
- Wrapper behavior must be deterministic and reproducible across languages.
- No wrapper may add third-party runtime dependencies.

## Production v1 Completion Gates

Final production v1 should not claim the full compatibility goal until:

- every supported language has documented coverage for its ordinary scalar types
- every supported language has documented coverage for its ordinary collection/container types
- every supported language supports explicit schema mapping for records, structs, classes, or objects where the language has them
- every mapper has strict, clipping, unknown, and missing-value behavior documented
- every mapper family has shared compliance fixtures
- every language wrapper passes the relevant compliance fixtures
- docs show the exact line users need for each core data family
- unsupported or extractor-required runtime objects are listed clearly

## Beta parity complete; production hardening work

- expand shared language-neutral compliance fixtures for every beta family
- verify wrappers in installed toolchain environments and record verified/skipped states
- harden JSON spec round-trips for fitted ranges, vocabularies, policies, and metadata
- define production extractor/schema contracts for opaque runtime objects
- keep per-language quickstart lines and wrapper README policy sections synchronized
- finalize release packaging while preserving the zero third-party runtime dependency rule

## Explicit Non-Goals

Beta v1 should not promise:

- automatic conversion of unknown arbitrary objects
- automatic mapping of opaque runtime resources such as file handles, sockets, threads, processes, closures, or untyped raw pointers
- imports from NumPy, Pillow, pandas, TensorFlow, PyTorch, OpenCV, or other third-party ecosystems
- silent fallback values for unknown characters, tokens, fields, or object types
- model-specific preprocessing behavior
- lossy flattening of nested structures unless the user explicitly asks for flattening

## See also

- [Production v1 Path](production_path_to_v1.md)
