# Architecture

## Alpha v1 Direction

The recommended core architecture is:

```text
C core -> stable C ABI -> first-party language wrappers
```

The current Python implementation is a useful reference, but it should not remain the only runtime implementation if `libRangeMap` is going to claim language-agnostic Alpha v1 readiness.

## Why C Core

C is the smallest practical center for this SDK:

- stable ABI across many languages
- easy to call from C++
- easy to wrap from Python, Rust, Go, Java, C#, and JavaScript runtimes
- no required runtime dependencies
- simple enough to audit
- portable to embedded and systems projects
- avoids separate reimplementations drifting apart

C++ can still be supported, but it should sit on top of the C ABI or be maintained as a separate first-party wrapper. A C++ core would make direct bindings harder because C++ ABI stability varies by compiler and platform.

## Alpha v1 Runtime Goal

Alpha v1 reaches 100% only when:

- the integer range mapper exists in a first-party C core,
- the C ABI is documented,
- Python uses or mirrors the C core behavior,
- every declared Alpha language wrapper passes the shared compliance fixture,
- no wrapper adds runtime dependencies,
- and docs show how each supported language uses the same mapping contract.

## Alpha Language Targets

The Alpha language target set should stay small enough to finish, but broad enough to prove the architecture:

- C core
- C++ wrapper
- Python wrapper/reference
- JavaScript/TypeScript wrapper
- Rust wrapper
- Go wrapper
- C# wrapper
- Java/Kotlin wrapper

If this list proves too large for the first Alpha milestone, the README and burndown must explicitly narrow the Alpha language target set before claiming 100%.

## Wrapper Rules

Wrappers should be thin:

- validate language-native inputs clearly,
- call or match the C ABI behavior,
- expose idiomatic names for that language,
- serialize the same JSON-compatible specs,
- pass the same compliance fixtures,
- avoid third-party runtime dependencies,
- avoid copied or vendored third-party source.

## Non-Goals

Alpha wrappers should not add new data types. Float, text, bytes, sequences, pixels, custom objects, schemas, and adapter registries remain beta work.
