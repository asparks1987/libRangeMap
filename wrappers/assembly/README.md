# libRangeMap Assembly Language Runtime

This directory provides a first-party assembly reference implementation path for Alpha v1 ordinary data mapping.
It is intentionally low-level, dependency-free, and deterministic, with explicit ABI-level entrypoints for the beta mapper families.

Current scope:

- integer range mapping
- float range mapping
- boolean mapping
- text mapping
- byte mapping
- sequence mapping
- map/object mapping
- categorical mapping
- temporal epoch mapping
- raw image-like channel mapping
- strict range validation
- optional clipping
- canonical linear interpolation

Explicitly unsupported in this runtime path:

- opaque runtime values such as file handles, sockets, threads, processes, closures, or raw pointers without schema metadata
- unknown family selectors
- records/maps without an explicit schema and family mapper selector

Unsupported value families are rejected at the wrapper boundary.
This path does not silently coerce unknown inputs into integers, and it does not invent fallback values for malformed records or missing metadata.

The included `librangemap.asm` contains an Intel-syntax algorithm and explicit branch points for range validation and interpolation.

## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```asm
; map 50 from [0, 100] into [-1.0, 1.0] using the native integer contract
librangemap_map_integer(0, 100, -1.0, 1.0, 0, 50, mapped_ptr);
```

```asm
; map Unix timestamp 1609459200 from [0, 2000000] with strict mode in assembly temporal contract
librangemap_map_temporal(0.0, 2000000.0, -1.0, 1.0, 0, 1609459200.0, mapped_ptr);
```

```asm
; map boolean 1 through explicit false/true outputs
librangemap_map_boolean(1, -1.0, 1.0, mapped_ptr, status_ptr);
```

```asm
; map raw image bytes with explicit shape metadata
librangemap_map_image_raw(raw_ptr, 3, 1, 1, -1.0, 1.0, mapped_ptr, status_ptr);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API, where available, to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown or unsupported types, and malformed values fail explicitly.
- Text, categorical, map/object, sequence, and image-like entrypoints require explicit metadata and fail on unknown tokens, missing fields, unknown family selectors, or shape mismatches.
- Unsupported families must fail explicitly rather than converting through a fallback integer path.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

Assembly family behavior is represented as ABI-level contracts in `librangemap.asm`; platform-specific implementations must preserve those status paths and metadata requirements.
