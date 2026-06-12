# libRangeMap PL/SQL Runtime Path

This directory holds a PL/SQL procedure-oriented reference for Alpha v1 integer mapping.

Use it as a direct adaptation in Oracle environments for deterministic integer normalization.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```sql
mapped := libRangeMap_map_integer(50, 0, 100, -1, 1, FALSE);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.