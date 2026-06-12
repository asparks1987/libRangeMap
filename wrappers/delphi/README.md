# libRangeMap Delphi/Object Pascal Wrapper

This directory contains a first-party Delphi/Object Pascal implementation of the Alpha v1 integer, float, boolean, text, sequences, bytes, categorical, temporal, and image-like mappers.

It is a dependency-free reference implementation that follows the shared mapping contract:

- validates input bounds and output bounds
- strict mode by default, optional clipping mode
- deterministic output in `[output_min, output_max]` with finite inputs
- explicit boolean true/false policy values
- explicit categorical vocabulary tokens with duplicate and unknown-token failure behavior


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```pascal
mapped := MapIntegerValue(50, 0, 100, -1, 1, False);
```

```pascal
mappedFloat := MapFloatValue(0.5, 0.0, 1.0, -1, 1, False);
```

```pascal
mappedBool := MapBooleanValue(True, -1, 1, -1, 1);
```

```pascal
mappedText := MapTextValue('cab', -1, 1, 'alphabet', 'abc', False, False);
```

```pascal
mappedTime := MapTemporalValue(0, -10, 10, -1, 1, False);
```

```pascal
mappedBytes := MapBytesValue(TBytes.Create(0, 255), -1, 1, False);
```

```pascal
mappedCategory := MapCategoricalValue('cat', TArray<string>.Create('cat', 'dog'));
```

```pascal
mappedSeq := MapIntegerSequenceValue(TArray<Integer>.Create(0, 50, 100), 0, 100, -1, 1, False);
```

```pascal
mappedImage := MapImageRawValue(TBytes.Create(0, 127, 255), 3, 1, 1, -1, 1, False, False);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float mapping rejects non-finite values and preserves the clipping contract.
- Boolean mapping uses explicit false/true policy values and rejects invalid metadata.
- Text mapping accepts explicit `codepoint` or `alphabet` mode, rejects unknown characters explicitly, and requires at least two unique alphabet characters.
- Bytes mapping accepts `TBytes`, rejects empty payloads by default, and preserves order.
- Image-like mapping accepts raw `TBytes` grayscale/RGB/RGBA-style channel payloads with explicit width, height, and channel metadata; malformed shape/length combinations fail explicitly.
- Sequence mapping accepts typed integer arrays, preserves nested shape for nested arrays, rejects empty arrays by default, and maps each element through the same explicit range policy.
- Categorical mapping accepts a non-empty explicit vocabulary and rejects unknown or duplicate tokens.
- Temporal mapping accepts explicit `TDateTime` values and preserves the clipping contract.
- The bundled unit self-check also exercises repeated integer, float, boolean, text, sequence, bytes, categorical, temporal, and image-like mapping on the canonical path.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
