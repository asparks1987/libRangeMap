# libRangeMap 0.1.0-alpha Python Reference Notes

Date: 2026-06-06

This alpha rebuild establishes `librangemap` as a dependency-free Python reference implementation for the language-neutral range-mapping spec.

It does not complete full project Alpha v1 readiness under the stricter canon that `libRangeMap` must be language-agnostic in practice. The intended Alpha architecture is now a first-party C core with a stable C ABI and thin wrappers for every declared Alpha language target.

## Added

- `IntegerRangeMapper`
- default output range `[-1.0, 1.0]`
- strict out-of-range behavior by default
- explicit clipping mode
- JSON-compatible mapper specs
- save/load helpers
- custom exception types
- standard-library `unittest` coverage
- docs, examples, compatibility notes, and no-dependency guidance
- language-neutral alpha compliance fixture

## Changed

- The canonical Python import is now `from librangemap import IntegerRangeMapper`.
- The legacy default output range `[0.0, 1.0]` is now available only as an explicit custom output range.
- The legacy flat `libRangeMap.py` module now delegates integer mapping to the alpha implementation.

## Deferred

- Character, string, bytes, sequence, pixel, and custom object mappers.
- first-party C core and stable C ABI for full Alpha v1 readiness.
- first-party wrappers for every declared Alpha language target.
- Multi-language package releases.
