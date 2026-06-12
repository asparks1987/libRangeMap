# libRangeMap Perl Wrapper

This directory contains a first-party Perl runtime path for Alpha v1 integer mapping.

```powershell
C:\Strawberry\perl\bin\perl.exe .\verify.pl
```



## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```perl
my $mapped = map_integer_value(value => 50, input_min => 0, input_max => 100);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.