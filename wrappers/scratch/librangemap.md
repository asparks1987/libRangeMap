# libRangeMap Scratch Spec

- Inputs:
  - `value`
  - `inputMin`
  - `inputMax`
  - `outputMin` (default `-1`)
  - `outputMax` (default `1`)
  - `clip` (true/false)
  - `timestamp_mode`/`time_unit` for temporal mapping (`epoch_seconds` and `seconds` by default)
- Float inputs:
  - require finite numbers
  - clamp only when `clip = true`
- Temporal inputs:
  - accept explicit numeric epoch values (e.g., Unix seconds/milliseconds as documented by contract)
  - share the same strict/clipping behavior as float mapping with `inputMin < inputMax` and `outputMin < outputMax`
- Boolean inputs:
  - map `false`/`true` via explicit `falseValue`/`trueValue`
  - require explicit policy values within the output range
- Text inputs:
  - accept Scratch strings through explicit `codepoint`, `byte`, or `alphabet` policy
  - reject empty strings unless `allow_empty_text = true`
  - alphabet policy requires a non-empty unique alphabet string
  - unknown alphabet characters must broadcast `"unknown_text_token"` and halt
- Byte inputs:
  - accept explicit lists of integer byte values from `0` to `255`
  - preserve list order
  - reject empty byte lists unless `allow_empty_bytes = true`
- Categorical inputs:
  - use an explicit vocabulary list
  - tokens must be unique, non-empty, and unknown values must raise `"unknown_token"`
- Sequence inputs:
  - use arrays/lists of supported values
  - preserve order and nested shape recursively
  - empty sequences must raise `"invalid_sequence"`
- Map/object inputs:
  - use an explicit schema list containing field name, family, ranges, and policy metadata
  - process fields in sorted schema-name order so unordered Scratch variable/list exports are deterministic
  - reject unknown fields unless `allow_unknown_fields = true`
  - reject missing fields unless the schema defines `allow_missing = true` plus a finite `missing_value`
- Image-like inputs:
  - use raw channel lists plus explicit `width`, `height`, and `channels`
  - grayscale uses `channels = 1`; RGB uses `channels = 3`; RGBA uses `channels = 4`
  - require `length(raw_channels) = width * height * channels`
  - map each channel as a byte value from `0` to `255`
- Guard rails:
  - require `inputMin < inputMax`
  - require `outputMin < outputMax`
  - if not clipping and value is outside bounds, report `"out_of_range"` and halt
- If boolean policy values are invalid, report `"invalid_boolean_policy"` and halt
- If categorical vocabulary is empty or duplicate, report `"invalid_categorical_vocabulary"` and halt
- If text policy metadata is invalid, report `"invalid_text_policy"` and halt
- If map/object schema metadata is invalid, report `"invalid_object_schema"` and halt
- If raw image shape metadata is invalid, report `"invalid_image_shape"` and halt
- Formula:

```
mapped = outputMin + ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
```

Expected examples:

`[0,100]`, value `0` -> `-1`
`[0,100]`, value `50` -> `0`
`[0,100]`, value `100` -> `1`

`falseValue = -1`, `trueValue = 1` -> `false => -1`, `true => 1`

Planned categorical example:

`vocabulary = ["cat","dog"]`, value `"dog"` -> `1`

Text examples:

`mode = "alphabet"`, `alphabet = "abc"`, value `"b"` -> `[0]`
`mode = "byte"`, value `"A"` -> approximately `[-0.4901960784]`

Sequence example:

`values = [0,50,100]` -> `[-1,0,1]`

Map/object example:

`schema = [{"name":"age","family":"integer","inputMin":0,"inputMax":100},{"name":"active","family":"boolean"}]`
`value = {"active":true,"age":0}` -> `[1,-1]` in sorted schema-name order (`active`, then `age`)

Image-like example:

`raw_channels = [0,127,255]`, `width = 3`, `height = 1`, `channels = 1` -> `[-1,-0.0039215686,1]`

Temporal example (seconds since epoch):

`[0,2000000]`, value `1000000` -> `-1.0`
