# Architecture

## Alpha v1 Direction

The recommended core architecture is:

```text
C core -> stable C ABI -> first-party language wrappers
```

The current Python implementation is a useful reference, source installs now compile the first-party C core, and first-party Go, C#, Java, and JavaScript runtime paths now exercise the shared ABI or matching contract. The project still needs the remaining canon wrappers before it can claim language-agnostic Alpha v1 readiness.

## Why C Core

C is the smallest practical center for this SDK:

- stable ABI across many languages
- easy to call from C++
- easy to wrap from the full Alpha v1 language target set
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
- all 25 Alpha v1 language targets pass the shared compliance fixture,
- no wrapper adds runtime dependencies,
- and docs show how each supported language uses the same mapping contract.

## Alpha Language Targets

The Alpha v1 language target set is canonically fixed to these 25 programming languages in numerical order:

| # | Language |
| ---: | --- |
| 1 | Python |
| 2 | C |
| 3 | Java |
| 4 | C++ |
| 5 | C# |
| 6 | JavaScript |
| 7 | Visual Basic |
| 8 | R |
| 9 | SQL |
| 10 | Delphi/Object Pascal |
| 11 | Fortran |
| 12 | Scratch |
| 13 | Perl |
| 14 | PHP |
| 15 | Rust |
| 16 | Go |
| 17 | Assembly language |
| 18 | Swift |
| 19 | Ada |
| 20 | MATLAB |
| 21 | Classic Visual Basic |
| 22 | PL/SQL |
| 23 | Ruby |
| 24 | Prolog |
| 25 | COBOL |

Every language target needs a first-party runtime, wrapper, or implementation path that passes the shared Alpha integer compliance fixture before Alpha v1 can claim 100%.

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
