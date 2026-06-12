# libRangeMap Perl Wrapper

This directory contains a first-party Perl runtime path for Alpha v1 integer, float, boolean, text, sequences, bytes, categorical, temporal, and image-like mapping.

```powershell
C:\Strawberry\perl\bin\perl.exe .\verify.pl
```



## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```perl
my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);
```

```perl
my $mapped_float = map_float_value(value => 0.5, input_min => 0.0, input_max => 1.0);
```

```perl
my $mapped_bool = map_boolean_value(value => 1);
```

```perl
my $mapped_bytes = map_bytes_value(value => "\x00\x7F\xFF");
```

```perl
my $mapped_text = map_text_value(value => "abc", mode => "alphabet", alphabet => "abc");
```

```perl
my $mapped_categorical = map_categorical_value(value => "cat", vocabulary => ["cat", "dog"]);
```

```perl
my $mapped_object = map_object_value(
  value => {
    age => 30,
    active => 1,
    profile => {
      score => 75,
      tag => "vip",
    }
  },
  schema => {
    age => { family => "integer", input_min => 0, input_max => 120 },
    active => { family => "boolean" },
    profile => {
      family => "object",
      schema => {
        score => { family => "integer", input_min => 0, input_max => 100 },
        tag => { family => "categorical", vocabulary => ["new", "vip", "admin"] },
      },
    },
  },
);
```

```perl
my $mapped_temporal = map_temporal_value(value => 1700000050000, input_min => 1700000000000, input_max => 1700000100000);
```

```perl
my $mapped_image = map_image_value(value => "\x00\x7F\xFF");
```

```perl
my $sequence_mapped = map_integer_sequence_value(values => [0, 50, 100], input_min => 0, input_max => 100);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float mapping rejects non-numeric values, invalid ranges, and out-of-range values unless clipping is enabled.
- Boolean mapping requires explicit boolean-like input and explicit false/true policy values.
- Sequence mapping accepts array references, preserves nested shape when nested arrays are composed, rejects empty sequences by default, and maps each element through the same explicit range policy.
- Bytes mapping accepts strings or arrays of integers, rejects empty payloads by default, and preserves order.
- Text mapping supports `codepoint`, UTF-8 `byte`, and explicit `alphabet` modes, rejects unknown alphabet tokens, and rejects codepoints above 255 unless clipping is enabled.
- Categorical mapping accepts only non-reference string tokens from an explicit vocabulary and rejects unknown or duplicate tokens.
- Map/object mapping requires explicit schema hashes, deterministic sorted-field output keys by schema key, explicit unknown/missing-field failures, and explicit nested object/sequence mapping via nested policies.
- Temporal mapping accepts Unix-millisecond integers and applies the same explicit range/clipping policy as integer mapping.
- Image-like mapping accepts raw byte buffers or nested array references and preserves shape recursively.
- The bundled self-check also exercises repeated integer mapping on the canonical path plus float, boolean, sequence, bytes, text, categorical, temporal, and image-like mapping.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
