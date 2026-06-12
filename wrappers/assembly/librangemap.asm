; libRangeMap Assembly (x86-64, NASM syntax) reference for Alpha v1
; Contract:
;   value, input_min, input_max are 64-bit integers in registers
;   output range uses double precision values in XMM registers.
;
; The implementation below is intentionally small and illustrative.
; A platform-specific build uses:
;   - prologue/epilogue per caller ABI
;   - range checks
;   - division in integer->floating conversion
;   - linear interpolation
; Planned categorical extension:
;   - explicit vocabulary lookup at the wrapper layer
;   - duplicate and unknown token rejection
; Beta family contract:
;   - scalar, text, bytes, sequence, map/object, categorical, temporal, and raw image-like
;     payloads are exposed as explicit wrapper-layer entrypoints.
;   - unsupported opaque runtime values must route to explicit error status.
;   - no family silently falls back to integer mapping.

segment .text
global librangemap_map_integer
global librangemap_map_float
global librangemap_map_boolean
global librangemap_map_text
global librangemap_map_bytes
global librangemap_map_sequence
global librangemap_map_object
global librangemap_map_categorical
global librangemap_map_temporal
global librangemap_map_image_raw

librangemap_map_integer:
    ; Pseudocode-like layout (implementation target)
    ; if input_min >= input_max or output_min >= output_max -> error path
    ; if clip then clamp value
    ; else fail out-of-range
    ; return output_min + ((value - input_min) / (input_max - input_min)) * (output_max - output_min)
    ret

librangemap_map_float:
    ; ABI contract:
    ;   value, input_min, input_max, output_min, output_max are IEEE-754 doubles.
    ;   clip is an explicit boolean/integer flag.
    ;   result and status are written to caller-provided output slots.
    ; Required branch behavior:
    ;   - reject NaN/Inf inputs and endpoints with invalid_float status
    ;   - reject input_min >= input_max and output_min >= output_max
    ;   - clamp only when clip is enabled
    ;   - strict out-of-range values route to out_of_range status
    ; Formula:
    ;   output_min + ((value - input_min) / (input_max - input_min)) * (output_max - output_min)
    ret

librangemap_map_boolean:
    ; ABI contract:
    ;   value is 0 or 1 only; false_value and true_value are explicit doubles.
    ; Required branch behavior:
    ;   - reject any value other than 0 or 1 with invalid_boolean status
    ;   - reject non-finite or equal false/true outputs
    ;   - return false_value for 0 and true_value for 1
    ret

librangemap_map_text:
    ; ABI contract:
    ;   caller passes pointer + length, mode, optional alphabet pointer + length,
    ;   output buffer pointer, and status pointer.
    ; Supported modes:
    ;   - codepoint/byte: map each byte/code unit from [0,255] unless a wider
    ;     platform-specific codepoint extractor is supplied by the caller.
    ;   - alphabet: lookup each character in an explicit unique alphabet.
    ; Required branch behavior:
    ;   - reject empty input unless allow_empty_text flag is set
    ;   - reject duplicate alphabet entries
    ;   - reject unknown alphabet characters with unknown_text_token status
    ;   - preserve input order in the output buffer
    ret

librangemap_map_bytes:
    ; ABI contract:
    ;   caller passes pointer + length for bytes plus output buffer pointer.
    ; Required branch behavior:
    ;   - reject empty input unless allow_empty_bytes flag is set
    ;   - each byte maps from [0,255] into [output_min, output_max]
    ;   - preserve byte order
    ;   - no decoding or text coercion happens in this family
    ret

librangemap_map_sequence:
    ; ABI contract:
    ;   caller passes contiguous element storage, element count, element family
    ;   mapper pointer/selector, output buffer, and status pointer.
    ; Required branch behavior:
    ;   - reject empty input unless allow_empty_sequence flag is set
    ;   - map each element through the explicit configured family mapper
    ;   - preserve order and nested shape metadata supplied by caller
    ;   - reject unknown element mapper selectors with unsupported_family status
    ret

librangemap_map_object:
    ; ABI contract:
    ;   caller passes schema pointer, schema field count, input field pointer,
    ;   input field count, output buffer, and status pointer.
    ; Required branch behavior:
    ;   - schema field names must be non-empty and unique
    ;   - process output in sorted schema-name order for deterministic results
    ;   - reject unknown input fields unless allow_unknown_fields flag is set
    ;   - reject missing required fields unless allow_missing + missing_value exist
    ;   - dispatch each field through its explicit family mapper selector
    ret

librangemap_map_categorical:
    ; ABI contract:
    ;   caller passes token pointer table, token count, selected token pointer,
    ;   output range, result pointer, and status pointer.
    ; Required branch behavior:
    ;   - reject empty vocabulary
    ;   - reject duplicate or empty tokens
    ;   - reject unknown token with unknown_token status
    ;   - map by stable vocabulary index into [output_min, output_max]
    ret

; temporal mapping intentionally mirrors numeric float mapping but is driven by explicit
; epoch inputs supplied as doubles in a documented unit (e.g., unix seconds).
; Signature:
;   librangemap_map_temporal(value, input_min, input_max,
;                           output_min, output_max, clip, out_ptr)
librangemap_map_temporal:
    ; Planned assembly implementation:
    ; - validate finite input and mapping inputs (input_min < input_max, output_min < output_max)
    ; - if clip enabled, clamp value into [input_min, input_max]
    ; - if strict and out of range, route explicit out_of_range failure
    ; - apply output_min + ((value - input_min) / (input_max - input_min)) * (output_max - output_min)
    ret

librangemap_map_image_raw:
    ; ABI contract:
    ;   caller passes raw channel pointer + length plus width, height, channels,
    ;   output buffer, and status pointer.
    ; Required branch behavior:
    ;   - width, height, and channels must be positive integers
    ;   - payload length must equal width * height * channels
    ;   - channel values map as bytes from [0,255] into [output_min, output_max]
    ;   - preserve raw channel order; no image file decoding is implied
    ret
