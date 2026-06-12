# libRangeMap JavaScript Wrapper

First-party Node runtime for `libRangeMap` with no third-party dependencies.

## What's implemented

- Integer range mapping (existing contract)
- Float range mapping (`FloatRangeMapper`)
- Boolean mapping (`BooleanRangeMapper`)
- Sequence mapping (`SequenceRangeMapper`) with nested array recursion and shape preservation.
- Text mapping (`TextRangeMapper`) by codepoint, alphabet policy, or UTF-8 bytes.
- Bytes mapping (`BytesRangeMapper`) for Buffer, `Uint8Array`, `ArrayBuffer`, and byte arrays.
- Temporal mapping (`TemporalRangeMapper`) for Date, epoch-millisecond, or ISO-8601 timestamp inputs.
- Image-like mapping (`ImageRangeMapper`) for nested grayscale or RGB/RGBA pixel arrays, plus raw byte buffers.
- Map/object mapping (`ObjectRangeMapper`) with explicit schemas for deterministic field-level conversion.
- Categorical/vocabulary mapping (`CategoricalRangeMapper`) by explicit token list.

## Install/use

```js
const {
  IntegerRangeMapper,
  FloatRangeMapper,
  BooleanRangeMapper,
  CategoricalRangeMapper,
  TemporalRangeMapper,
  ImageRangeMapper,
  SequenceRangeMapper,
  TextRangeMapper,
  BytesRangeMapper,
  ObjectRangeMapper,
  DEFAULT_OUTPUT_RANGE,
} = require("./index");
```

## 2-line quickstart

### Integer

```js
const mapped = new IntegerRangeMapper([0, 100]).mapValue(50);
```

### Float

```js
const mapped = new FloatRangeMapper([0.0, 1.0], DEFAULT_OUTPUT_RANGE).mapValue(0.5);
```

### Boolean

```js
const mapped = new BooleanRangeMapper().mapValue(true); // => 1.0
```

### Sequence

```js
const intMapper = new IntegerRangeMapper([0, 100]);
const seqMapper = new SequenceRangeMapper(intMapper, { allowEmpty: false });
const mapped = seqMapper.mapValue([0, [25, 50, [75, 100]]]); // => [-1.0, [-0.5, 0.0, [0.5, 1.0]]]
```

### Text

```js
const mapper = new TextRangeMapper([-1.0, 1.0], "codepoint");
const mapped = mapper.mapValue("abc");
```

### Categorical

```js
const mapper = new CategoricalRangeMapper(["cat", "dog", "fox"]);
const mapped = mapper.mapValue("dog");
```

### Bytes

```js
const mapper = new BytesRangeMapper(DEFAULT_OUTPUT_RANGE, false, false);
const mapped = mapper.mapValue(Buffer.from([0, 128, 255]));
```

### Temporal

```js
const mapper = new TemporalRangeMapper([0, 1000]);
const mapped = mapper.mapValue("1970-01-01T00:00:00.500Z");
```

### Image

```js
const mapper = new ImageRangeMapper();
const mapped = mapper.mapValue([[0, 128, 255], [64, 192, 32]]);
```

### Object map

```js
const mapper = new ObjectRangeMapper({
  age: new IntegerRangeMapper([0, 130]),
  active: new BooleanRangeMapper(),
}, { allowEmpty: true, missingValue: 0.0 });
const mapped = mapper.mapValue({ age: 42, active: false });
```

## Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (`clip = true`) to clamp instead of failing.
- Invalid ranges, non-finite outputs, unknown/unsupported types, and malformed values fail explicitly.
- Unknown object fields fail unless `allowUnknown=true`, and unknown tokens are not coerced.
- Categorical vocabularies must be non-empty and unique; unknown categorical tokens fail unless explicitly configured in the vocabulary.
- Temporal values accept `Date`, epoch-millisecond numbers, or ISO-8601 timestamp strings and reject invalid timestamps explicitly.
- Image-like values accept nested grayscale or pixel-channel arrays, plus raw byte buffers, and reject non-numeric pixels explicitly.
- The bundled smoke test exercises bytes, nested object-and-sequence composition,
  nested missing-field rejection, temporal mapping, image mapping, and repeated-call determinism
  in addition to the scalar family cases.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

## Smoke check

```powershell
node --test .\wrappers\javascript\test.js
```


