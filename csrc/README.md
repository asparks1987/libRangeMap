# C Core

This directory holds the first-party C runtime core for libRangeMap.

The header defines a stable C ABI for integer range mapping:

- `lrm_integer_range_mapper_init`
- `lrm_integer_range_mapper_map_value`
- `lrm_integer_range_mapper_get_spec`

The Python reference currently remains the only exercised runtime path in this repository because the local environment does not expose a C compiler. The source here is the canonical backbone for the multi-language architecture and should be used by future first-party wrappers.

The C core must remain dependency-free and portable.
