# libRangeMap PHP Wrapper

This directory contains a dependency-free PHP runtime path for Alpha v1 mapping.

Use:

```powershell
"C:\Users\Aryns\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe" .\verify.php
```


## 2-line quickstart

Use the exact canonical entrypoints for supported families:

```php
$mapped = map_integer_value(50, 0, 100);
```

```php
$mappedFloat = map_float_value(0.5, 0.0, 1.0);
```

```php
$mappedBoolean = map_boolean_value(true);
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.
- Boolean mapping requires native `bool` input and explicit false/true policy values.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.
