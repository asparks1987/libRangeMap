# Compatibility matrix

This page mirrors the alpha/beta readiness manifest in `compliance/beta_readiness.json`.
Statuses below are normalized to `done` when a family is implemented and `planned` when it is still in scope.

## Family coverage summary

| Family | Coverage |
| --- | --- |
| integer | 25/25 |
| float | 25/25 |
| boolean | 25/25 |
| text | 25/25 |
| bytes | 25/25 |
| sequences | 25/25 |
| maps_structs_objects | 25/25 |
| categorical_vocab | 25/25 |
| image_like | 25/25 |
| temporal | 25/25 |

## Language matrix

| Order | Language | integer | float | boolean | text | bytes | sequences | maps_structs_objects | categorical_vocab | temporal | image_like |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Python | done | done | done | done | done | done | done | done | done | done |
| 2 | C | done | done | done | done | done | done | done | done | done | done |
| 3 | Java | done | done | done | done | done | done | done | done | done | done |
| 4 | C++ | done | done | done | done | done | done | done | done | done | done |
| 5 | C# | done | done | done | done | done | done | done | done | done | done |
| 6 | JavaScript | done | done | done | done | done | done | done | done | done | done |
| 7 | Visual Basic | done | done | done | done | done | done | done | done | done | done |
| 8 | R | done | done | done | done | done | done | done | done | done | done |
| 9 | SQL | done | done | done | done | done | done | done | done | done | done |
| 10 | Delphi/Object Pascal | done | done | done | done | done | done | done | done | done | done |
| 11 | Fortran | done | done | done | done | done | done | done | done | done | done |
| 12 | Scratch | done | done | done | done | done | done | done | done | done | done |
| 13 | Perl | done | done | done | done | done | done | done | done | done | done |
| 14 | PHP | done | done | done | done | done | done | done | done | done | done |
| 15 | Rust | done | done | done | done | done | done | done | done | done | done |
| 16 | Go | done | done | done | done | done | done | done | done | done | done |
| 17 | Assembly language | done | done | done | done | done | done | done | done | done | done |
| 18 | Swift | done | done | done | done | done | done | done | done | done | done |
| 19 | Ada | done | done | done | done | done | done | done | done | done | done |
| 20 | MATLAB | done | done | done | done | done | done | done | done | done | done |
| 21 | Classic Visual Basic | done | done | done | done | done | done | done | done | done | done |
| 22 | PL/SQL | done | done | done | done | done | done | done | done | done | done |
| 23 | Ruby | done | done | done | done | done | done | done | done | done | done |
| 24 | Prolog | done | done | done | done | done | done | done | done | done | done |
| 25 | COBOL | done | done | done | done | done | done | done | done | done | done |

## Notes

- The matrix is intentionally conservative: `planned` means the language wrapper still needs that family path for beta readiness.
- The wrapper-family parity blocker is closed across the 25-language Alpha v1 matrix; Assembly now has explicit ABI-level contracts for every beta family.
- C temporal is now implemented via explicit timestamp-mode helper coverage; remaining temporal gaps are in map/object-heavy runtimes.
- Delphi/Object Pascal and PL/SQL now map raw image-like payloads with explicit shape metadata.
- Ruby is now `done` for both `map/object` and `image_like`; Prolog is now `done` for both.
- COBOL map/object and image-like are now implemented as fixed-schema/shape-validated extensions with explicit schema, shape, and empty-policy behavior.
- Text-family completion is now available in all 25 languages, including Perl.
- Image-like completion is now available in all 25 languages, including Visual Basic.
