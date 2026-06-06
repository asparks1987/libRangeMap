# AGENTS.md

## Project identity

This project is `libRangeMap`.

`libRangeMap` is a 100% first-party, dependency-free range-mapping SDK for AI dataset preparation, feature normalization, and training-data collection.

The core idea:

Any supported input value can be deterministically mapped into a floating-point value in the range `[-1.0, 1.0]`.

Examples:
- An integer in a known range maps to a float in `[-1, 1]`.
- A float in a known range maps to a float in `[-1, 1]`.
- A character maps from an alphabet, codepoint, byte, or custom range policy into `[-1, 1]`.
- A string maps by character, byte, token, or configured vocabulary policy.
- A sequence maps element-by-element.
- A nested sequence maps recursively while preserving shape.
- Image-like data maps from raw bytes, RGB/RGBA tuples, grayscale values, or nested pixel arrays without requiring external image libraries.

## First-party and dependency-free rule

This is the most important project rule.

The core SDK must not depend on any third-party package.

Do not add runtime dependencies such as:
- NumPy
- Pillow
- pandas
- PyTorch
- TensorFlow
- scikit-learn
- OpenCV
- requests
- pydantic
- click
- typer
- rich
- pytest
- ruff
- mypy
- or any other external package

Do not copy, vendor, paste, or adapt source code from another repository or third-party library.

Use only:
- original project code,
- the Python standard library,
- and project-owned tests/docs/examples.

The user must be able to install and use the SDK without importing or installing any dependency beyond Python itself.

If an integration with a third-party ecosystem is ever desired, it must be:
- outside the core package,
- clearly marked as optional,
- not required for the SDK to work,
- and not implemented by copying third-party code.

Prefer first-party protocols and duck-typed support over imports. For example, do not import NumPy to support arrays. Instead, support Python sequences, nested sequences, bytes, bytearray, memoryview, and simple objects only when they can be handled without importing external packages.

## Product goal

Build `libRangeMap` into a clean open-source SDK for converting many types of data into normalized floating-point representations for AI and ML dataset preparation.

The package should be:
- dependency-free,
- deterministic,
- small,
- easy to install,
- easy to audit,
- well tested,
- well documented,
- beginner-friendly,
- and useful in serious data pipelines.

The default output range is `[-1.0, 1.0]`.

Do not default to `[0.0, 1.0]` unless the user explicitly configures that output range.

## Core mapping contract

Every mapper must obey these rules:

1. Deterministic:
   - Same input plus same config always produces the same output.

2. Bounded:
   - Default normalized output must be inside `[-1.0, 1.0]`.
   - Clipping behavior must be explicit and documented.

3. Explainable:
   - Mapping configuration should be inspectable.
   - Users should be able to understand how each value was mapped.

4. Reproducible:
   - Fitted mappers must preserve fitted ranges, vocabularies, alphabets, and metadata.
   - Mapping specs should be serializable using standard-library formats such as JSON.

5. Type-aware:
   - Different input types need explicit policies.
   - Do not silently treat unknown types as numeric.
   - Do not silently map unknown characters or tokens to magic values.

6. Safe failure:
   - Invalid ranges, unsupported types, NaN/Inf, empty data, and unknown tokens must have clear behavior.
   - Prefer helpful exceptions over surprising output.

## Canonical formula

The generic linear mapping formula is:

```text
normalized = out_min + ((value - in_min) / (in_max - in_min)) * (out_max - out_min)
```
