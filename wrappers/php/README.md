# libRangeMap PHP Runtime Path

This directory provides a first-party PHP reference path for Alpha v1 integer,
float, boolean, text, bytes, sequence, categorical, image-like, and map/object mapping.

The implementation is deterministic, dependency-free, and follows the core output
contract:
`[-1.0, 1.0]` by default for `map_integer_value`, `map_float_value`,
`map_boolean_value`, `map_text_value`, `map_bytes_value`, `map_sequence_value`,
`map_categorical_value`, `map_image_value`, and `map_object_value`.
Temporal families map via explicit UTC epoch seconds or `DateTimeInterface` values in this language wrapper.

## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical entrypoints for this runtime:

```php
$mapped = map_integer_value(50, 0, 100);
$clipped = map_integer_value(150, 0, 100, -1.0, 1.0, true);
```

```php
$mapped_float = map_float_value(0.5, 0.0, 1.0);
$mapped_bool = map_boolean_value(true);
```

```php
$mapped_text = map_text_value("ab", -1.0, 1.0, "alphabet", false, true, "abc");
$mapped_bytes = map_bytes_value("\0\xff", -1.0, 1.0, true);
$mapped_bytes_array = map_bytes_value([0, 255], -1.0, 1.0, false, true);
```

```php
$mapped_image = map_image_value("\x00\x80\xff", -1.0, 1.0, true);
$mapped_image_nested = map_image_value([[0, 128, 255], [64, 192, 32]]);
```

```php
$mapped_seq = map_sequence_value([0, [25, 50], 100], fn($value) => map_integer_value($value, 0, 100));
$mapped_seq_empty = map_sequence_value([], fn($value) => map_integer_value($value, 0, 100), true);
```

```php
$mapped_cat = map_categorical_value("dog", ["dog", "cat", "fox"]);
$mapped_cat_idx = map_categorical_value(1, [10, 20, 30], -1.0, 1.0);
```

```php
$mapped_obj = map_object_value(
    ["age" => 25, "active" => true],
    ["age" => fn(int $value) => map_integer_value($value, 0, 120), "active" => fn(bool $value) => map_boolean_value($value)]
);
```

```php
$mapped_time = map_temporal_value(new DateTimeImmutable("@0"), -10.0, 10.0);
```

### Failure contract

- Out-of-range values in strict mode are explicit `InvalidArgumentException` failures.
- Enable clipping in the runtime API (when `clip = true`) to clamp instead of failing.
- Invalid ranges, unsupported/non-integer types, and malformed values fail explicitly.
- `map_temporal_value` accepts `DateTimeInterface` or numeric timestamps against explicit epoch-based ranges and rejects non-temporal values.
- `map_bytes_value` accepts a raw string or an array of integers in [0, 255].
- Byte mapping rejects non-integer array items and out-of-range byte values explicitly.
- Empty bytes values are invalid unless `allow_empty=true`.
- `map_image_value` accepts raw byte strings or nested lists of numeric pixel values.
- Image mapping preserves list shape recursively and rejects associative arrays and unknown types explicitly.
- Empty image values are invalid unless `allow_empty=true`.
- `map_text_value` supports explicit modes:
  - `"codepoint"`: UTF-8 codepoint normalization,
  - `"byte"`: raw byte normalization,
  - `"alphabet"`: configured character alphabet normalization.
- Text mapping rejects unknown alphabet symbols, invalid UTF-8, and empty strings
  unless `allow_empty=true`.
- `map_sequence_value` maps nested arrays recursively and preserves container shape.
- Sequence mapping requires an element-mapper callable and rejects non-numeric mapped
  outputs.
- Empty sequences fail explicitly unless `allow_empty=true`.
- `map_categorical_value` maps only configured vocabulary values, including string
  categories and integer labels, and fails on unknown categories with explicit
  typed errors.
- `map_object_value` requires an explicit field schema and an explicit mapper for
  each field.
- Map/object mapping rejects missing required fields, unknown extra fields (unless
  explicitly allowed), and non-callable schema entries.
- The bundled smoke script exercises bytes, image, temporal, categorical repeated mapping, explicit
  missing-field rejection, nested object-and-sequence composition, nested
  missing-field rejection, and repeated-call determinism in addition to the scalar cases.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
