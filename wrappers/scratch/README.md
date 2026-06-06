# libRangeMap Scratch Runtime Path

This directory defines the Alpha v1 mapping contract for Scratch integration.

Scratch does not provide a built-in native numeric exception model, so this implementation uses explicit branching blocks:

- compare input against `input_min` and `input_max`
- if `clip = true`, clamp to bounds before mapping
- if `clip = false`, route out-of-range values to an explicit `error` broadcast
- apply the linear formula using base math blocks in the editor

Use `librangemap.md` as the canonical block-level mapping spec for Scratch extension authorship.
