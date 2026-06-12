# libRangeMap COBOL Runtime Path

This directory contains a first-party COBOL reference routine for Alpha v1 integer, float, boolean, temporal, categorical-vocabulary, and sequence mapping.
Text and bytes are implemented as explicit scalar sequence extensions; map/object and image-like are implemented as fixed-schema families.
Map/object and image-like mapping are implemented as fixed-schema, shape-explicit extensions, and are currently tracked separately from the scalar reference path.

The routine is written to be portable and dependency-free, using a small linear-transform formula.


## Install/use

From this directory run:

```powershell
.\test.cmd
```

## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```cobol
* See wrappers\\cobol\\librangemap.cob for the reference integer routine contract
```

### Float

```cobol
* See wrappers\\cobol\\librangemap.cob for the float routine contract
```

### Boolean

```cobol
* See wrappers\\cobol\\librangemap.cob for the boolean routine contract
```

### Sequences

```cobol
* See wrappers\\cobol\\librangemap.cob for the sequence routine contract
```

### Categorical

```cobol
* Explicit vocabulary-based categorical mapping:
*   - INPUT RECORD:
*     - WS-CAT-IN (token bytes)
*     - WS-CAT-IN-LEN (token length)
*     - WS-CAT-VOCAB-SIZE (vocabulary count)
*     - WS-CAT-VOCAB (OCCURS array of vocabulary entries)
*     - WS-INPUT-MIN/WS-INPUT-MAX (index domain)
*     - WS-OUTPUT-MIN/WS-OUTPUT-MAX
*     - WS-CAT-ALLOW-EMPTY, WS-CLIP
*   - perform MAP-CATEGORICAL-VALUE-SECTION
```

```cobol
*     MOVE 3 TO WS-CAT-IN-LEN
*     MOVE "red" TO WS-CAT-IN
*     MOVE 3 TO WS-CAT-VOCAB-SIZE
*     MOVE "red"  TO WS-CAT-VOCAB(1)
*     MOVE "green" TO WS-CAT-VOCAB(2)
*     MOVE "blue" TO WS-CAT-VOCAB(3)
*     MOVE 0 TO WS-INPUT-MIN
*     MOVE 2 TO WS-INPUT-MAX
*     PERFORM MAP-CATEGORICAL-VALUE-SECTION
```

### Temporal

```cobol
* temporal section (seconds or milliseconds input policy):
*   - INPUT RECORD:
*     - WS-VALUE (numeric timestamp)
*     - WS-TEMPORAL-UNIT ('S' seconds or 'M' milliseconds)
*     - WS-INPUT-MIN/WS-INPUT-MAX (input domain)
*     - WS-OUTPUT-MIN/WS-OUTPUT-MAX
*     - WS-CLIP
*   - perform MAP-TEMPORAL-VALUE-SECTION
```

```cobol
*     MOVE 1700000000 TO WS-VALUE
*     MOVE 'S' TO WS-TEMPORAL-UNIT
*     MOVE 0 TO WS-INPUT-MIN
*     MOVE 2000000000 TO WS-INPUT-MAX
*     PERFORM MAP-TEMPORAL-VALUE-SECTION
```

### Text (codepoint policy)

```cobol
* text section (fixed-length codepoint policy):
*   - INPUT RECORD:
*     - WS-TEXT-LEN (1..256)
*     - WS-TEXT-IN (fixed-length text payload)
*     - WS-INPUT-MIN/WS-INPUT-MAX (input domain)
*     - WS-OUTPUT-MIN/WS-OUTPUT-MAX
*     - WS-TEXT-ALLOW-EMPTY, WS-TEXT-CLIP
*   - perform MAP-TEXT-VALUE-SECTION
```

```cobol
*     MOVE 12 TO WS-TEXT-LEN
*     PERFORM MAP-TEXT-VALUE-SECTION
```

### Bytes

```cobol
* bytes section (explicit byte-domain policy):
*   - INPUT RECORD:
*     - WS-BYTES-IN (raw byte payload)
*     - WS-BYTES-IN-LEN (payload count)
*     - WS-INPUT-MIN/WS-INPUT-MAX (input domain)
*     - WS-OUTPUT-MIN/WS-OUTPUT-MAX
*     - WS-BYTES-ALLOW-EMPTY, WS-BYTES-CLIP
*   - perform MAP-BYTES-VALUE-SECTION
```

```cobol
*     MOVE 3 TO WS-BYTES-IN-LEN
*     PERFORM MAP-BYTES-VALUE-SECTION
```

### Map/Object (schema-driven extension)

```cobol
* map-object section (schema-first entrypoint):
*   - INPUT RECORD:
*     - WS-OBJ-FIELD-COUNT (01..N)
*     - WS-OBJ-KEYS (OCCURS N)
*     - WS-OBJ-TYPE-CODES (I=integer, F=float, B=boolean, Y=bytes)
*       (nested/object/sequence are explicit failures until dedicated extension families are added)
*     - WS-INPUT-MIN / WS-INPUT-MAX / WS-OUTPUT-MIN / WS-OUTPUT-MAX
*     - WS-OBJ-IN-INT / WS-OBJ-IN-FLOAT / WS-OBJ-IN-FLOAT-MIN / WS-OBJ-IN-FLOAT-MAX
*     - WS-OBJ-IN-BOOL / WS-OBJ-IN-BYTES (field-aligned by index)
*   - set WS-OBJ-ALLOW-UNKNOWN and WS-OBJ-ALLOW-EMPTY flags
*   - perform MAP-OBJECT-VALUE-SECTION
```

```cobol
*     MOVE 2                   TO WS-OBJ-FIELD-COUNT
*     PERFORM MAP-OBJECT-VALUE-SECTION
```

```cobol
* Map-object return:
*   - WS-MAP-STATUS (OK, ERR-UNKNOWN-FIELD, ERR-MISSING-FIELD, ERR-SCHEMA, ERR-EMPTY, ERR-OUT-OF-RANGE, ERR-TYPE, ERR-NON-BYTE)
*   - WS-MAP-ERROR (exact reason code)
*   - WS-OBJ-OUT-VALUES mapped in schema order
*   - implicit coercion is forbidden; unknown field/type/missing-policy combinations are explicit errors
```

### Image-like (fixed-shape extension)

```cobol
* map-image section (fixed-shape byte/shape extension):
*   - INPUT RECORD:
*     - WS-IMG-BYTES-IN, WS-IMG-BYTES-COUNT
*     - WS-IMG-ROWS/WS-IMG-COLS/WS-IMG-CHANNELS
*     - WS-IMG-MODE (AUTO / RGB / RGBA)
*     - WS-IMG-ALLOW-EMPTY, WS-IMG-CLIP
*   - perform MAP-IMAGE-VALUE-SECTION
```

```cobol
*     MOVE 3                TO WS-IMG-CHANNELS
*     PERFORM MAP-IMAGE-VALUE-SECTION
```

```cobol
* Map-image return:
*   - WS-MAP-STATUS (OK, ERR-EMPTY, ERR-SCHEMA, ERR-IMAGE-SHAPE, ERR-NON-BYTE)
*   - WS-MAP-ERROR (e.g., IMAGE-BYTES-COUNT-MUST-NOT-BE-NEGATIVE)
*   - WS-IMG-OUT-VALUES, one mapped float per input byte/raster position
*   - malformed shape/bytes payloads and unknown modes are explicit failures
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Float and boolean behaviors follow the same explicit-contract style as integer mapping and reject non-finite or malformed values.
- Text and bytes section behavior is deterministic and explicit: malformed payload, empty input without allow-empty, and out-of-domain values fail explicitly unless clipping is enabled.
- Sequence behavior is documented as element-wise and shape-preserving, with empty sequences rejected unless an explicit allow-empty policy is added.
- Categorical behavior is explicit-vocabulary with unknown-token rejection and duplicate-token validation.
- Map/object and image-like extension sections are explicit-schema only: unknown fields/types are explicit failures; empty containers fail unless `allow_empty` is enabled; and all unknown contracts fail with an explicit status code and reason in `WS-MAP-STATUS`/`WS-MAP-ERROR`.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.

Current COBOL status:

- integer: done
- float: done
- boolean: done
- text: done
- bytes: done
- sequences: done
- maps_structs_objects: done
- categorical_vocab: done
- temporal: done
- image_like: done



