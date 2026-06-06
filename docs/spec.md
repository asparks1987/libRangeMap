# libRangeMap Alpha Specification

Spec version: `1.0-alpha`

## Purpose

`libRangeMap` defines deterministic mappers that convert supported input values from an explicit input range or mapping policy into floating-point output values. The alpha specification covers finite integer range mapping only.

The default output range is `[-1.0, 1.0]`.

## Terms

- `value`: one input item to map.
- `input range`: an ordered pair `[in_min, in_max]` declaring valid input bounds.
- `output range`: an ordered pair `[out_min, out_max]` declaring output bounds.
- `mapper`: an object or function implementing this spec.
- `mapping spec`: serializable metadata needed to reproduce a mapper.
- `transform`: the act of mapping one supported value.
- `inverse transform`: a future operation for mapping output back to input when safe.
- `clipping`: clamping out-of-range input to the nearest input bound before mapping.
- `strict mode`: raising an error for out-of-range input.
- `finite numeric value`: a number that is not NaN and not positive or negative infinity.

## Formula

```text
mapped = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```

Alpha defaults:

```text
out_min = -1.0
out_max = 1.0
```

## Integer Mapping

Alpha integer mapping requires:

- `in_min < in_max`
- `out_min < out_max`
- input values are integers
- booleans are rejected even in languages where booleans behave like integers
- output is a floating-point value
- no hidden global state

Lower input bound maps to `out_min`. Upper input bound maps to `out_max`. Exact midpoints map to `0.0` for the default output range where mathematically exact.

## Out-Of-Range Behavior

If `clip` is `false`, values below `in_min` or above `in_max` must raise an out-of-range error.

If `clip` is `true`, values below `in_min` map as `in_min`, and values above `in_max` map as `in_max`.

## Invalid Values And Ranges

Equal or reversed ranges are invalid. NaN and infinity are invalid wherever numeric range values are accepted. Non-integer input values are invalid for the alpha integer mapper.

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

Future mappers for floats, characters, strings, bytes, sequences, pixels, and custom objects must declare explicit mapping policies. Unknown values must not map to arbitrary magic values.
