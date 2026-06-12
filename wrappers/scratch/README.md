# libRangeMap Scratch Runtime Path

This directory defines the Alpha v1 mapping contract for Scratch integration.

Scratch does not provide a built-in native numeric exception model, so this implementation uses explicit branching blocks:

- compare input against `input_min` and `input_max`
- if `clip = true`, clamp to bounds before mapping
- if `clip = false`, route out-of-range values to an explicit `error` broadcast
- apply the linear formula using base math blocks in the editor

Use `librangemap.md` as the canonical block-level mapping spec for Scratch extension authorship.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```text
mapped := map_integer_value(50, 0, 100, -1, 1, false)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.