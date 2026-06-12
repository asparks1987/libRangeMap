# libRangeMap JavaScript Wrapper

First-party Node runtime for `libRangeMap` with no third-party dependencies.

## What's implemented

- Integer range mapping (existing contract)
- Float range mapping (`FloatRangeMapper`)
- Boolean mapping (`BooleanRangeMapper`)
- Sequence mapping (`SequenceRangeMapper`) with nested array recursion and shape preservation.
- Text mapping (`TextRangeMapper`) by codepoint, alphabet policy, or UTF-8 bytes.

## Install / import

```js
const {
  IntegerRangeMapper,
  FloatRangeMapper,
  BooleanRangeMapper,
  SequenceRangeMapper,
  TextRangeMapper,
  DEFAULT_OUTPUT_RANGE,
} = require("./index");
```

## 2-line quickstarts

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

## Local validation

```powershell
node --test .\wrappers\javascript\test.js
```

## Compatibility contract

See the root docs for the full product-facing contract and family matrix:

- [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md)
- [`docs/beta_roadmap.md`](../../docs/beta_roadmap.md)

The implementation stays dependency-free and mirrors the repository-wide explicit error policy.
