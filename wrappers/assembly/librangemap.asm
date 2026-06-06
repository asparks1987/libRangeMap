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

segment .text
global librangemap_map_integer

librangemap_map_integer:
    ; Pseudocode-like layout (implementation target)
    ; if input_min >= input_max or output_min >= output_max -> error path
    ; if clip then clamp value
    ; else fail out-of-range
    ; return output_min + ((value - input_min) / (input_max - input_min)) * (output_max - output_min)
    ret
