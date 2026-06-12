# libRangeMap Alpha Specification

Spec version: `1.0-alpha`

## Language-Agnostic Mapping Contract

All wrappers and runtimes implement the same deterministic contract:

- deterministic for identical input + config
- bounded output in configured `output_range`
- explicit failure behavior for invalid ranges and unsupported inputs
- reproducible output by serializing the mapper spec
- no silent coercions, no magic fallback values

### Contract rules

- Supported values and ranges are validated before mapping.
- `NaN` and infinity are rejected for numeric contracts unless a language runtime explicitly permits them by policy.
- Unknown tokens/symbols/fields/objects fail with explicit typed errors.
- Mapping is never random and never reads global mutable defaults.

### Canonical linear formula

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

This formula is the only mapping behavior used unless a wrapper documents a different family policy contract (for example, byte, alphabet, or schema-based mapping).

Alpha focuses on integer support plus explicit extensions for floats, booleans, text, bytes, sequences, and map/object schema contracts.

The default output range is `[-1.0, 1.0]`.

## Terms

- `value`: one input item to map.
- `input range`: an ordered pair `[in_min, in_max]` declaring valid input bounds.
- `output range`: an ordered pair `[out_min, out_max]` declaring output bounds.
- `mapper`: an object or function implementing this contract.
- `mapping spec`: serializable metadata needed to reproduce a mapper.
- `transform`: the act of mapping one supported value.
- `inverse transform`: a future operation for mapping output back to input when safe.
- `clipping`: clamping out-of-range input to the nearest input bound before mapping.
- `strict mode`: raising an error for out-of-range input.
- `finite numeric value`: a number that is not NaN and not positive or negative infinity.

## Boundedness Rule (Alpha default output)

Default bounds apply to all mappers unless explicitly configured:

```text
out_min = -1.0
out_max = 1.0
```

The output must remain finite and within the configured range when `value` is finite and contract-valid.

## Integer Mapping

Alpha integer mapping requires:

- `in_min < in_max`
- `out_min < out_max`
- input values are integers
- booleans are rejected even in languages where booleans behave like integers
- output is a floating-point value
- no hidden global state

Lower input bound maps to `out_min`. Upper input bound maps to `out_max`. Exact midpoints map to `0.0` for the default output range where mathematically exact.

### Integer contract fields

- `mapper_type`: `integer_range`
- `input_range`: `[in_min, in_max]`
- `output_range`: `[out_min, out_max]`
- `clip`: strict (`false`) or clipping mode (`true`)
- `name` (optional): metadata label for auditing and traceability

Required spec keys are versioned with `spec_version`.
Mapper specs are serialized as strict JSON: non-finite values such as `NaN` and `Infinity` are rejected, and any configured `missing_value` must itself be JSON-serializable.
Duplicate JSON object keys are rejected during spec recovery so mapper metadata stays deterministic.

## Out-Of-Range Behavior

If `clip` is `false`, values below `in_min` or above `in_max` must raise an out-of-range error.

If `clip` is `true`, values below `in_min` map as `in_min`, and values above `in_max` map as `in_max`.

## Text Mapping

Text and string mappers must document policy explicitly (`codepoint`, `alphabet`, or `byte`).
Unknown characters/symbols must fail, and text mapping must be deterministic and shape-preserving on a per-symbol basis.

## Categorical/Token Mapping

- Mappers declare an explicit `vocabulary` or token list.
- token indices are mapped deterministically by position in the vocabulary.
- vocabulary tokens are JSON-serializable scalar values and are keyed type-aware so booleans do not collapse into numeric tokens.
- unknown token must fail with an explicit error.
- output range is bounded by configured `output_range`, and vocabularies are serialized into mapper specs.

## Bytes Mapping

Python's byte-family mapper uses the same deterministic model:

- accepted input: `bytes`, `bytearray`, `memoryview`
- explicit empty-policy via `allow_empty`
- each raw byte `0..255` maps through the canonical linear formula
- unsupported payload types fail with explicit typed errors

## Map/Record/Object Mapping

Map mapping is schema-driven and deterministic:

- each schema field must declare its own mapper policy,
- only schema-declared fields are emitted by default,
- unknown keys fail unless explicitly configured,
- missing required fields fail unless `missing_value` is configured,
- object inputs are mapped via readable attributes and mapping inputs via dictionary keys.
- property accessor failures are not swallowed; they propagate as explicit runtime errors.

### Map contract fields

- `mapper_type`: `map_range`
- `schema`: ordered field-to-mapper spec map
- `allow_unknown`: bool
- `allow_empty`: bool
- `missing_value` (optional): fallback for missing required fields
- `name` (optional)

Schema order is deterministic because mappings preserve insertion order; runtimes must preserve declared schema order for reproducibility.
Schema mappers used inside maps and sequences must support both `map_value()` and `to_dict()` so nested specs remain serializable and reproducible.

### Text contract fields

- `mapper_type`: `text_range`
- `mode`: `codepoint`, `alphabet`, or `byte`
- `alphabet` (required for alphabet mode): stable symbol list used for indexing, with at least two unique characters
- `input_range`: derived by mode
- `output_range`: `[out_min, out_max]`
- `allow_empty`: bool
- `clip`: bool
- `name` (optional)

## Invalid Values And Ranges

Equal or reversed ranges are invalid. NaN and infinity are invalid wherever numeric range values are accepted. Non-integer input values are invalid for the alpha integer mapper.

## Error Taxonomy (Alpha)

- `InvalidRangeError`: invalid range shape, order, or zero-length interval
- `UnsupportedTypeError`: unsupported input type, token, or family
- `OutOfRangeError`: valid type in strict mode outside declared input range
- `NotFiniteError`: `NaN`/infinity in numeric inputs
- `SerializationError`: malformed or incompatible mapper spec

## Reproducibility

Mapper specs must include enough metadata to reproduce exact behavior in another runtime:

- version (`spec_version`)
- mapper kind (`mapper_type`)
- fitted ranges (`input_range`, `output_range`)
- control flags (`clip`, family policy keys)
- optional human metadata (`name`, extraction notes)

## Serialization

Mapper specs must use JSON-compatible values.

```json
{
  "spec_version": "1.0-alpha",
  "implementation_version": "0.1.0-alpha",
  "mapper_type": "integer_range",
  "input_range": [0, 100],
  "output_range": [-1.0, 1.0],
  "clip": true,
  "name": "optional-name"
}
```

`name` is optional. Specs must not include raw user datasets.

## Compliance Tests

A conforming alpha implementation must prove:

- lower bound maps to `-1.0`
- upper bound maps to `1.0`
- midpoint maps to `0.0` when exact
- positive, negative, mixed, non-zero, and large ranges work
- strict mode raises for out-of-range values
- clipping mode clamps out-of-range values
- invalid ranges fail clearly
- non-integers and booleans are rejected
- mapper specs serialize and reload reproducibly

## Future Adapters

Future mappers for categories, temporal values, and richer object extractors must declare explicit mapping policies.

### Opaque extractor policy (production boundary)

Opaque runtime values are not ordinary data-bearing values and must not be mapped implicitly.
Examples include file handles, sockets, processes, threads, closures/functions, live database cursors, runtime locks, and raw pointers without metadata.

The default policy is **reject without explicit extractor**.
An extractor contract must declare:

- `contract_type`
- source runtime type
- extractor name
- output mapper family
- schema or metadata needed for safe extraction
- deterministic behavior statement
- explicit failure policy

Extractor output must be ordinary data already supported by a mapper family.
Raw pointers additionally require size, element type, safe-read bounds, ownership/lifetime, and byte order when relevant.
Extractor contracts must not add third-party runtime dependencies to the core SDK.

The machine-readable production boundary is tracked in `compliance/opaque_extractor_contract.json`.

### Temporal policy (current)

- `TemporalRangeMapper` maps accepted temporal values through a deterministic conversion policy.
- Accepted temporal types are datetime-like values, timedeltas, and explicit numeric timestamps depending on mode.
- Temporal family policies must define mode, epoch/base behavior, and naive datetime handling explicitly.
- Unknown or unsupported temporal values must fail with explicit errors.

Unknown values must not map to arbitrary magic values.

### Image-like policy (current)

- `ImageRangeMapper` supports explicit modes:
  - `grayscale` (numeric channels treated as scalar pixel intensities),
  - `rgb` (3-channel pixels),
  - `rgba` (4-channel pixels),
  - `raw_bytes` (bytes / bytearray / memoryview).
- For `rgb` and `rgba`, each deepest-level pixel must be an explicit channel tuple/list with exact channel count.
- For `raw_bytes`, input must be byte-like; shape is not inferred.
- Empty containers are invalid unless `allow_empty=True`.
- Scalar channel values are mapped through the declared input range (`input_range`) using the same canonical formula.
- Unknown or malformed structures fail explicitly with typed errors (no implicit coercion of containers).

## Beta to Production Transition

Beta and production readiness require explicit language-wrapper policies for:

- float and bool families
- nested sequence families
- bytes/buffers
- categories/tokens
- object schemas and map-like data
- image-like structures
- temporal values
- extractor contracts for opaque runtime objects (sockets, threads, file handles, closures, raw pointers without metadata)
