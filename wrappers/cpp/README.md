# libRangeMap C++ Wrapper

This directory contains the first-party C++ wrapper family for libRangeMap.
Float, boolean, text, bytes, sequences, categorical, temporal, image-like, and object families are implemented in this
wrapper with explicit local range policy and strict failure behavior.

It depends only on the C++ standard library and the native `librangemap_core.dll` already built by the project.

## Install/use

```powershell
.\build.cmd
.\test.cmd
```

The build script uses the repository-owned Zig launcher to compile the wrapper and verifier.


## 2-line quickstart

Use the exact canonical one-liners for this runtime:

```cpp
double mapped = librangemap::IntegerRangeMapper(0, 100).map_value(50);
double float_mapped = librangemap::FloatRangeMapper(0.0, 1.0).map_value(0.5);
double bool_mapped = librangemap::BooleanRangeMapper().map_value(true);
```

```cpp
std::vector<double> text_mapped = librangemap::TextRangeMapper().map_value(std::string("Ada"));
```

```cpp
std::vector<double> bytes_mapped = librangemap::BytesRangeMapper().map(std::string("\x00\x7f", 2));
std::vector<double> bytes_array = librangemap::BytesRangeMapper(-1.0, 1.0, false, true).map_value(std::vector<int>{0, 255});
```

```cpp
auto sequence_mapper = librangemap::create_sequence_mapper([](const auto& item) {
    return librangemap::IntegerRangeMapper(0, 100).map_value(item);
});
std::vector<double> sequence_mapped = sequence_mapper.map_value(std::vector<std::int64_t>{0, 50, 100});
```

```cpp
double temporal_mapped = librangemap::TemporalRangeMapper(0.0, 100.0).map_value(50.0);
double temporal_clipped = librangemap::TemporalRangeMapper(0.0, 100.0, -1.0, 1.0, true).map_value(150.0);
```

```cpp
auto categorical = librangemap::CategoricalRangeMapper(std::vector<std::any>{std::string("cat"), std::int64_t(1), true});
double categorical_mapped = categorical.map_value(std::string("cat"));
```

```cpp
std::vector<double> image_mapped = librangemap::ImageRangeMapper().map(std::string("\x00\x80\xff", 3));
std::vector<std::vector<double>> image_nested = librangemap::ImageRangeMapper().map_value(std::vector<std::vector<int>>{{0, 128, 255}, {64, 192, 32}});
```

```cpp
std::vector<double> clipped = librangemap::BytesRangeMapper(-1.0, 1.0, true, true).map_value(std::vector<int>{-5, 255});
```

```cpp
librangemap::MapRangeMapper::ObjectSchema user_schema = {
    {"age", librangemap::IntegerRangeMapper(0, 120)},
    {"active", librangemap::BooleanRangeMapper()},
};
librangemap::MapRangeMapper user_mapper(user_schema, false, false);
auto user_payload = user_mapper.map(librangemap::MapRangeMapper::ObjectRecord{{"age", 34}, {"active", true}});
```

```cpp
librangemap::MapRangeMapper nested_mapper(
    librangemap::MapRangeMapper::ObjectSchema{
        {"user", std::make_shared<librangemap::MapRangeMapper>(user_schema)},
        {"score", librangemap::FloatRangeMapper(0.0, 100.0)},
    });
auto nested_payload = nested_mapper.map(librangemap::MapRangeMapper::ObjectRecord{
    {"user", librangemap::MapRangeMapper::ObjectRecord{{"age", 34}, {"active", true}}},
    {"score", 50.0}});
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `TextRangeMapper` accepts UTF-8 `std::string` values, maps them as codepoint, byte, or alphabet vectors, rejects empty input by default, and fails on unknown or duplicate alphabet tokens.`r`n- `BytesRangeMapper` accepts raw UTF-8 `std::string`, `std::vector<int>`, and `std::vector<unsigned char>`.
- Empty bytes inputs are invalid unless `allow_empty=true`.
- Byte values outside `0..255` fail in strict mode and clamp when `clip=true`.
- `SequenceRangeMapper` accepts typed vectors, preserves nested shape, rejects empty input by default, and fails explicitly when the element mapper does not support a value type.
- `TemporalRangeMapper` accepts numeric Unix-second timestamps or `std::chrono::system_clock::time_point` values.
- Temporal JSON specs include an explicit `input_unit` field for reproducible round-trips.
- `CategoricalRangeMapper` accepts explicit vocabularies of strings, booleans, characters, finite numbers, and null; unknown tokens fail explicitly and duplicate vocab entries are rejected.
- `ImageRangeMapper` accepts raw strings, flat numeric vectors, and nested numeric vectors representing grayscale or pixel channels.
- Image mapping preserves nested list shape for supported vector inputs and rejects unsupported types explicitly.
- Empty image inputs are invalid unless `allow_empty=true`.
- Object/map policies are explicit:
  - default is `allow_unknown=false` and `allow_empty=false`,
  - unknown keys fail,
  - missing keys fail unless `has_missing_value=true` with an explicit fallback,
  - unknown types for a field fail with typed errors.
- The bundled verifier exercises bytes repeated mapping, image mapping, nested map/object JSON
  round-trips, sequence mapping, explicit missing-field rejection, and repeated mapping to confirm
  deterministic composition in addition to the scalar smoke cases.
- The bundled verifier exercises nested map/object composition twice to confirm
  deterministic repeated-call behavior in addition to the scalar smoke cases.
- The bundled verifier also exercises repeated integer mapping on the canonical path.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.


