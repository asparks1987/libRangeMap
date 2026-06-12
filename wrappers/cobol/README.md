# libRangeMap COBOL Runtime Path

This directory contains a first-party COBOL reference routine for Alpha v1 integer mapping.

The routine is written to be portable and dependency-free, using a small linear-transform formula.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```cobol
* See wrappers\\cobol\\librangemap.cob for the reference integer routine contract
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.