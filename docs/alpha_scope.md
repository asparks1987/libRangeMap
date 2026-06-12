# Alpha Scope

Alpha v1 ships one stable primitive: integer range mapping.

The current Python reference exposes that primitive as `IntegerRangeMapper`. It maps finite integers from a declared integer range into a floating-point output range. The default output range is `[-1.0, 1.0]`.

Full Alpha v1 readiness is not complete until the integer mapping contract is language-agnostic in practice, not only specified.
The intended path is a first-party C core with a stable C ABI and thin wrappers for the 25-language Alpha v1 canon:

- Foundation is complete: contract, formula, and integer behavior.
- Wrapper paths and canonical snippets exist for all 25 canon languages in-repo.
- Integer-family smoke verification is complete for these language paths locally.
- Runtime parity across environments remains gated by each language/toolchain target in CI.

The C core and every wrapper must pass the shared compliance fixture before the project claims 100% Alpha v1 readiness.

In-progress / deferred:

- floats
- characters
- strings
- bytes and buffers
- nested sequence mappers (Python/JavaScript in progress)
- raw pixel/image-like mappers
- custom object schemas
- multi-language packages
