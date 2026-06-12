# libRangeMap Ada Wrapper

This directory contains a first-party Ada implementation path for Alpha v1 integer, float, boolean, text, sequences, categorical, bytes, temporal, image-like, and map/object mapping.

No external dependencies are required; this package uses only the Ada runtime and standard packages.

## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```ada
mapped : Long_Float := Map_Integer_Value(50, 0, 100, -1.0, 1.0, False);
```

### Float

```ada
mapped : Long_Float := Map_Float_Value(5.0, 0.0, 10.0);
```

### Boolean

```ada
mapped : Long_Float := Map_Boolean_Value(True);
```

### Text

```ada
mapped : Long_Float_Array := Map_Text_Value("Ada", Mode => Codepoint);
```

### Categorical

```ada
tokens : Categorical_Token_Array := (1 => To_Unbounded_String("red"), 2 => To_Unbounded_String("green"), 3 => To_Unbounded_String("blue"));
mapped : Long_Float := Map_Categorical_Value(To_Unbounded_String("green"), tokens, -1.0, 1.0);
```

### Temporal

```ada
mapped : Long_Float := Map_Temporal_Value(1_700_000_050_000, 1_700_000_000_000, 1_700_000_100_000, -1.0, 1.0, False);
```

### Image-like

```ada
mappedImage : Long_Float_Array_Array := Map_Image_Value((1 => (1 => 0, 2 => 127), 2 => (1 => 255)));
```

```ada
mappedBytes : Long_Float_Array := Map_Bytes_Value("AB", -1.0, 1.0, False);
```

```ada
seq : Long_Float_Array := Map_Integer_Sequence_Value((1 => 0, 2 => 50, 3 => 100), 0, 100, -1.0, 1.0, False);
```

### Map/Object

```ada
type Map_Object_Entry is record
   Name  : Unbounded_String;
   Field : Map_Object_Field_Value;
end record;

schema : constant Map_Object_Field_Spec_Array := (
   1 => (Name => To_Unbounded_String("age"), Allow_Missing => False, Missing_Value => 0.0, Family => Integer_Field,
         Integer_Spec => (Input_Min => 0, Input_Max => 120, Output_Min => -1.0, Output_Max => 1.0, Clip => False)),
   2 => (Name => To_Unbounded_String("active"), Allow_Missing => True, Missing_Value => 0.0, Family => Boolean_Field,
        Boolean_Spec => (False_Value => -1.0, True_Value => 1.0))
);

mapped : Long_Float_Array := Map_Object_Value(
   schema,
   (1 => (Name => To_Unbounded_String("active"), Field => (Has_Value => True, Family_Provided => Boolean_Field, Boolean_Value => True)),
    2 => (Name => To_Unbounded_String("age"), Field => (Has_Value => True, Family_Provided => Integer_Field, Integer_Value => 42))),
   Allow_Unknown => False
);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- `Map_Float_Value` accepts finite numeric scalars and rejects `NaN`/`Inf`; integer acceptance is explicit policy.
- `Map_Boolean_Value` accepts only `Boolean` values and never coerces other truthy/falsey inputs.
- `Map_Text_Value` maps strings deterministically as codepoint, byte, or alphabet-driven vectors, rejects empty text by default, and fails on unknown alphabet characters or duplicate alphabet entries.
- `Map_Categorical_Value` requires a non-empty unique token array, maps by stable token order, and rejects unknown tokens explicitly.
- `Map_Bytes_Value` accepts strings as bytes-like payloads, rejects empty payloads by default, and preserves order.
- `Map_Integer_Sequence_Value` maps typed integer arrays, preserves nested shape when nested arrays are composed, rejects empty arrays by default, and maps each element through the same explicit range policy.
- `Map_Image_Value` maps grayscale integer matrices deterministically, preserves shape, and rejects empty image input by default.
- `Map_Object_Value` maps only schema-listed fields using deterministic sorted schema-name output order, explicit unknown-field behavior, and missing-policy substitution.
- `Map_Temporal_Value` accepts Unix-millisecond `Long_Long_Integer` timestamps and applies the same explicit range/clipping policy as the scalar mappers.
- Maps, records, tagged types, and other custom runtime objects are not silently coerced; they must be projected through an explicit extractor before mapping.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
