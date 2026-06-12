# libRangeMap Go Wrapper

This first-party Go wrapper targets the shared C ABI from the root native core.

It keeps the wrapper dependency-free and uses only the Go standard library plus the native `librangemap_core.dll` that is already part of the project.

## Local validation

From this directory:

```powershell
$env:CC = "$PWD\\..\\..\\tools\\zigcc.cmd"
$env:PATH = "$PWD\\..\\..\\librangemap\\native;$env:PATH"
$env:CGO_ENABLED = "1"
go test ./...
```

The `test.cmd` helper performs the same setup for Windows shells and the Zig launcher auto-discovers the installed compiler.


## 2-line quickstart

Use the exact canonical integer entrypoint for this runtime:

```go
mapper, _ := NewDefaultIntegerRangeMapper(0, 100); mapped, _ := mapper.MapValue(50)
```

### Failure contract

- Out-of-range values in strict mode are explicit failures.
- Enable clipping in the runtime API (where available) to clamp instead of failing.
- Invalid ranges, `NaN`/`Inf`, unknown/unsupported types, and malformed values fail explicitly.

### Family status

See [`docs/quickstart.md`](../../docs/quickstart.md) for current 2-second language snippets and [`docs/beta_wrapper_contract.md`](../../docs/beta_wrapper_contract.md) for expected family policy behavior.